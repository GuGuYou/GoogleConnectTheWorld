import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 头像占位：基于 seed 生成稳定的渐变色块 + 首字母，无需网络图
class AvatarPlaceholder extends StatelessWidget {
  final String seed;
  final String label;
  final double size;
  final bool online;
  final bool glow;

  const AvatarPlaceholder({
    super.key,
    required this.seed,
    required this.label,
    this.size = 48,
    this.online = false,
    this.glow = false,
  });

  static const _palettes = [
    [AppColors.neonPink, AppColors.neonPurple],
    [AppColors.neonCyan, AppColors.neonPurple],
    [AppColors.neonPurple, AppColors.neonPink],
    [AppColors.neonCyan, AppColors.neonGreen],
    [AppColors.neonYellow, AppColors.neonPink],
    [AppColors.neonGreen, AppColors.neonCyan],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = seed.hashCode.abs() % _palettes.length;
    final colors = _palettes[idx];
    final initial = label.isNotEmpty ? label.characters.first.toUpperCase() : '?';
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: glow
                ? [BoxShadow(color: colors.first.withValues(alpha: 0.6), blurRadius: 16)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: AppColors.neonGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bg0, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
