import 'package:flutter/material.dart';

/// Honeycomb-inspired dark palette, aligned to the 202607 Figma redesign
/// (tools/figma_extract/out/specs/spec_summary.md).
/// Keeps legacy token names to minimize app-wide changes.
class AppColors {
  AppColors._();

  static const Color bg0 = Color(0xFF050605);
  static const Color bg1 = Color(0xFF100E0C);
  static const Color bg2 = Color(0xFF211907);
  static const Color surface = Color(0xFF1D1909);

  // Legacy accent names → Figma golds.
  static const Color neonPink = Color(0xFFFFC000); // primary accent
  static const Color neonPurple = Color(0xFFFF8C00); // glow orange
  static const Color neonCyan = Color(0xFFF5CA4B); // sparkle gold
  static const Color neonYellow = Color(0xFFFDD570); // gold text/icons
  static const Color neonGreen = Color(0xFFFFAF3A); // CTA fill

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9F8645);
  static const Color textMuted = Color(0xFF8D8165);

  static const Color divider = Color(0xFF271E13);
  static const Color glassBorder = Color(0x26FDD570);

  // Figma-semantic tokens introduced by the redesign.
  static const Color cardSurface = Color(0x991D1909); // #1D1909 @ 60%
  static const Color chipSurface = Color(0xFF110F05);
  static const Color hexFill = Color(0xFF141212);
  static const Color inputFill = Color(0xFF151410);
  static const Color inputHint = Color(0xFF83591F);
  static const Color ctaText = Color(0xFF000000);
  static const Color iconGold = Color(0xFFE3C67A);
  static const Color navBg = Color(0xFF000000);
  static const Color glowOrange = Color(0xFFFF8C00);

  /// Title gradient: white → warm gold (Figma headline fill).
  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4C842)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// CTA fill — the redesign uses a flat #FFAF3A pill.
  static const LinearGradient pinkPurple = LinearGradient(
    colors: [Color(0xFFFFAF3A), Color(0xFFFFAF3A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Selected honeycomb cell gradient.
  static const LinearGradient cyanPurple = LinearGradient(
    colors: [Color(0xFFFFC000), Color(0xFFEF5200)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gold icon gradient used inside honeycomb cells.
  static const LinearGradient hexIcon = LinearGradient(
    colors: [Color(0xFFFDD570), Color(0xFFD68D1F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient bgGlow = RadialGradient(
    colors: [Color(0xFF2E1A00), Color(0xFF050605)],
    center: Alignment.topCenter,
    radius: 1.35,
  );

  static const Map<String, Color> categoryColors = {
    'game': Color(0xFFFDD570),
    'anime': Color(0xFFFFC000),
    'drama': Color(0xFFF5CA4B),
    'comic': neonYellow,
    'music': Color(0xFFFFAF3A),
  };
}
