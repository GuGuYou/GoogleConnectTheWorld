import 'package:flutter/material.dart';

/// Travel 风明亮通透色板（参考旅行类 App UI：浅色背景、暖珊瑚主色、海岸青辅助、柔和阴影）。
/// 说明：为最小改动复用全局，沿用原有令牌命名（neonXxx 等），仅替换其色值。
class AppColors {
  AppColors._();

  // 背景：明亮通透
  static const Color bg0 = Color(0xFFEFF2F9); // 页面底色（冷调浅白）
  static const Color bg1 = Color(0xFFFFFFFF); // 卡片
  static const Color bg2 = Color(0xFFF1F4FA); // 抬升表面 / chip 填充
  static const Color surface = Color(0xFFFFFFFF);

  // 主色（语义沿用旧名）：落日珊瑚 + 海岸青 + 天空蓝 + 暖琥珀 + 薄荷
  static const Color neonPink = Color(0xFFFF7A66); // 珊瑚（主 CTA）
  static const Color neonPurple = Color(0xFF6C8CFF); // 天空蓝（次要）
  static const Color neonCyan = Color(0xFF12B5C9); // 海岸青
  static const Color neonYellow = Color(0xFFFFB23E); // 琥珀
  static const Color neonGreen = Color(0xFF24C281); // 薄荷

  // 文字
  static const Color textPrimary = Color(0xFF1B2440);
  static const Color textSecondary = Color(0xFF5C6680);
  static const Color textMuted = Color(0xFF98A1B6);

  static const Color divider = Color(0x141B2440);
  static const Color glassBorder = Color(0x12101840);

  // 主渐变（珊瑚 → 粉 → 天空蓝）
  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFFFF8A5B), neonPink, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 主按钮渐变（珊瑚 → 暖粉）
  static const LinearGradient pinkPurple = LinearGradient(
    colors: [Color(0xFFFF8A5B), Color(0xFFFF5E8A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // 次级渐变（海岸青 → 天空蓝）
  static const LinearGradient cyanPurple = LinearGradient(
    colors: [neonCyan, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 背景光晕：明亮柔和
  static const RadialGradient bgGlow = RadialGradient(
    colors: [Color(0xFFFFFFFF), bg0],
    center: Alignment.topCenter,
    radius: 1.3,
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
