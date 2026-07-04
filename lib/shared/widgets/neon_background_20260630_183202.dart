import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 全屏明亮通透背景：浅色渐变 + 角落柔和色斑（低透明度），让白色卡片自然浮起。
class NeonBackground extends StatelessWidget {
  final Widget child;
  const NeonBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGlow),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -70,
            child: _blob(AppColors.neonPink.withValues(alpha: 0.16), 260),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: _blob(AppColors.neonCyan.withValues(alpha: 0.14), 240),
          ),
          Positioned(
            top: 220,
            left: -50,
            child: _blob(AppColors.neonPurple.withValues(alpha: 0.12), 200),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
