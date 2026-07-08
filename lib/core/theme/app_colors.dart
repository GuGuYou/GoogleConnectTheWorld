import 'package:flutter/material.dart';

/// Honeycomb-inspired dark palette.
/// Keeps legacy token names to minimize app-wide changes.
class AppColors {
  AppColors._();

  static const Color bg0 = Color(0xFF070807);
  static const Color bg1 = Color(0xFF111006);
  static const Color bg2 = Color(0xFF221C08);
  static const Color surface = Color(0xFF171308);

  static const Color neonPink = Color(0xFFFFC21A);
  static const Color neonPurple = Color(0xFFFF8F1F);
  static const Color neonCyan = Color(0xFF9EF1E5);
  static const Color neonYellow = Color(0xFFFFD84A);
  static const Color neonGreen = Color(0xFFFFB000);

  static const Color textPrimary = Color(0xFFFFF7D6);
  static const Color textSecondary = Color(0xFFD8C77A);
  static const Color textMuted = Color(0xFF8F7F46);

  static const Color divider = Color(0xFF3B310E);
  static const Color glassBorder = Color(0x66FFD84A);

  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFFA9FFF4), Color(0xFFFFD84A), Color(0xFFFFA51F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkPurple = LinearGradient(
    colors: [Color(0xFFFFE16B), Color(0xFFFFB000)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cyanPurple = LinearGradient(
    colors: [Color(0xFFFFF3A0), Color(0xFFFFB000), Color(0xFFFF7A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient bgGlow = RadialGradient(
    colors: [Color(0xFF4D3900), Color(0xFF070807)],
    center: Alignment.topCenter,
    radius: 1.35,
  );

  static const Map<String, Color> categoryColors = {
    'game': Color(0xFFFFD84A),
    'anime': Color(0xFFFFB000),
    'drama': Color(0xFFFFE16B),
    'comic': neonYellow,
    'music': Color(0xFFFFC21A),
  };
}
