import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final logged = ref.read(authProvider);
      context.go(logged ? '/discover' : '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 旋转霓虹圆环（自绘替代 Lottie）
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(colors: [
                        AppColors.neonPink,
                        AppColors.neonPurple,
                        AppColors.neonCyan,
                        AppColors.neonPink,
                      ]),
                      boxShadow: [
                        BoxShadow(color: AppColors.neonPurple.withValues(alpha: 0.6), blurRadius: 40),
                      ],
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 3000.ms),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bg0,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.hub, size: 56, color: AppColors.neonCyan),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              GradientText(
                ref.tr('app_name'),
                style: AppTextStyles.display(context),
              ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.3),
              const SizedBox(height: 10),
              Text(
                ref.tr('splash_sub'),
                style: AppTextStyles.body.copyWith(letterSpacing: 2),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 60),
              Text(ref.tr('splash_loading'), style: AppTextStyles.caption)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: 900.ms)
                  .then()
                  .fadeOut(duration: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}
