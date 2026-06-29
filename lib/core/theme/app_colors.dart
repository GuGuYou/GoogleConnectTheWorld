import 'package:flutter/material.dart';

/// Cyber Neon 赛博霓虹色板
class AppColors {
  AppColors._();

  // 背景：深紫黑渐变
  static const Color bg0 = Color(0xFF0A0613); // 最深背景
  static const Color bg1 = Color(0xFF120A24); // 卡片底
  static const Color bg2 = Color(0xFF1B1038); // 抬升表面
  static const Color surface = Color(0xFF1F1442);

  // 霓虹主色
  static const Color neonPink = Color(0xFFFF2E97);
  static const Color neonPurple = Color(0xFF9D4EFF);
  static const Color neonCyan = Color(0xFF21E6FF);
  static const Color neonYellow = Color(0xFFFFD53E);
  static const Color neonGreen = Color(0xFF3DFFB0);

  // 文字
  static const Color textPrimary = Color(0xFFF2EEFF);
  static const Color textSecondary = Color(0xFFAFA4D6);
  static const Color textMuted = Color(0xFF6E6491);

  static const Color divider = Color(0x22FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // 主渐变（粉 → 紫 → 青）
  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonPink, neonPurple, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkPurple = LinearGradient(
    colors: [neonPink, neonPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cyanPurple = LinearGradient(
    colors: [neonCyan, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient bgGlow = RadialGradient(
    colors: [Color(0xFF2A1659), bg0],
    center: Alignment.topCenter,
    radius: 1.2,
  );

  /// 兴趣分类颜色映射
  static const Map<String, Color> categoryColors = {
    'game': neonCyan,
    'anime': neonPink,
    'drama': neonPurple,
    'comic': neonYellow,
    'music': neonGreen,
  };
}
