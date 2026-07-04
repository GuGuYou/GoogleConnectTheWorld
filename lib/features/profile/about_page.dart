import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(ref.tr('setting_about'))),
      body: NeonBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.neonGradient,
                    boxShadow: [BoxShadow(color: AppColors.neonPurple.withValues(alpha: 0.5), blurRadius: 30)],
                  ),
                  child: const Icon(Icons.hub, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),
                GradientText(ref.tr('about_title'), style: AppTextStyles.h1),
                const SizedBox(height: 8),
                Text('v0.1.0  ·  Prototype', style: AppTextStyles.caption),
                const SizedBox(height: 20),
                Text(ref.tr('about_desc'), textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(height: 1.7)),
                const SizedBox(height: 40),
                Text('Made with Flutter · Cyber Neon', style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
