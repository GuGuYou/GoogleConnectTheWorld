import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ObData(Icons.location_searching, ref.tr('ob1_title'), ref.tr('ob1_desc'), AppColors.neonCyan),
      _ObData(Icons.tag, ref.tr('ob2_title'), ref.tr('ob2_desc'), AppColors.neonPink),
      _ObData(Icons.groups, ref.tr('ob3_title'), ref.tr('ob3_desc'), AppColors.neonPurple),
    ];

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(ref.tr('skip'), style: AppTextStyles.body),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (c, i) => _ObView(data: pages[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _index == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: _index == i ? AppColors.pinkPurple : null,
                        color: _index == i ? null : AppColors.textMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: NeonButton(
                  label: _index == pages.length - 1 ? ref.tr('ob_start') : ref.tr('next'),
                  icon: _index == pages.length - 1 ? Icons.rocket_launch : Icons.arrow_forward,
                  onPressed: () {
                    if (_index == pages.length - 1) {
                      context.go('/login');
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ObData {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  _ObData(this.icon, this.title, this.desc, this.color);
}

class _ObView extends StatelessWidget {
  final _ObData data;
  const _ObView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [data.color.withValues(alpha: 0.35), Colors.transparent]),
            ),
            alignment: Alignment.center,
            child: Icon(data.icon, size: 92, color: data.color)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.92, end: 1.05, duration: 1600.ms),
          ),
          const SizedBox(height: 48),
          GradientText(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: 16),
          Text(
            data.desc,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(height: 1.6),
          ),
        ],
      ).animate(key: ValueKey(data.title)).fadeIn(duration: 400.ms),
    );
  }
}
