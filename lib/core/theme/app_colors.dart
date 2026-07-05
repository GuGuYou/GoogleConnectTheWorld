import 'package:flutter/material.dart';

/// Google/Duolingo-inspired light palette from latest web preview.
/// Keeps legacy token names to minimize app-wide changes.
class AppColors {
  AppColors._();

  static const Color bg0 = Color(0xFFE8F0FE);
  static const Color bg1 = Color(0xFFFFFFFF);
  static const Color bg2 = Color(0xFFF7F7F7);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color neonPink = Color(0xFF4285F4);
  static const Color neonPurple = Color(0xFF1A73E8);
  static const Color neonCyan = Color(0xFF4285F4);
  static const Color neonYellow = Color(0xFFFBBC05);
  static const Color neonGreen = Color(0xFF34A853);

  static const Color textPrimary = Color(0xFF4B4B4B);
  static const Color textSecondary = Color(0xFF777777);
  static const Color textMuted = Color(0xFFAFAFAF);

  static const Color divider = Color(0xFFE5E5E5);
  static const Color glassBorder = Color(0xFFE5E5E5);

  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkPurple = LinearGradient(
    colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cyanPurple = LinearGradient(
    colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient bgGlow = RadialGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE8F0FE)],
    center: Alignment.topCenter,
    radius: 1.35,
  );

  static const Map<String, Color> categoryColors = {
    'game': neonCyan,
    'anime': Color(0xFFEA4335),
    'drama': neonPurple,
    'comic': neonYellow,
    'music': neonGreen,
  };
}
