import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 全屏赛博霓虹背景：深紫底 + 顶部光晕 + 角落霓虹光斑
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
            top: -120,
            right: -80,
            child: _blob(AppColors.neonPink.withValues(alpha: 0.30), 260),
          ),
          Positioned(
            bottom: -100,
            left: -90,
            child: _blob(AppColors.neonCyan.withValues(alpha: 0.22), 240),
          ),
          Positioned(
            top: 240,
            left: -60,
            child: _blob(AppColors.neonPurple.withValues(alpha: 0.20), 200),
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
