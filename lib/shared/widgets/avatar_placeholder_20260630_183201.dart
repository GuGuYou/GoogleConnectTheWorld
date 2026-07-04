import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../data/preset_avatars.dart';

/// 头像组件：优先渲染预设图片（DiceBear），外加霓虹渐变描边 + 发光 + 在线点。
/// 兼容旧用法：传入 seed 时会稳定映射到一张预设头像；
/// 也可直接传入 assets 路径作为 seed。加载失败时回退到渐变首字母。
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
    final imagePath = PresetAvatars.isPreset(seed) ? seed : PresetAvatars.fromSeed(seed);
    final border = (size * 0.035).clamp(1.5, 4.0);

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
          padding: EdgeInsets.all(border),
          child: ClipOval(
            child: Image.asset(
              imagePath,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(colors),
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
                boxShadow: [BoxShadow(color: AppColors.neonGreen.withValues(alpha: 0.7), blurRadius: 6)],
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback(List<Color> colors) {
    final initial = label.isNotEmpty ? label.characters.first.toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.bold),
      ),
    );
  }
}
