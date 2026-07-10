import 'package:flutter/material.dart';

import 'app_colors.dart';

/// TikTok Sans (variable) is the Figma redesign's display/brand font.
/// It has no CJK glyphs, so Chinese falls back to the system font.
///
/// The `wght` axis is driven by [TextStyle.fontWeight] (Flutter maps it to
/// the variable axis), so `style.copyWith(fontWeight: …)` at call sites keeps
/// working — no manual `fontVariations` that copyWith would fail to update.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'TikTok Sans';

  static TextStyle tt({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    // No explicit fontFamilyFallback: TikTok Sans has no CJK glyphs, and the
    // engine's automatic fallback covers Chinese. Naming unavailable families
    // (e.g. PingFang SC on web) breaks that chain and renders tofu.
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: weight,
    );
  }

  static TextStyle display(BuildContext context) =>
      tt(size: 36, weight: FontWeight.w700, height: 1.1);

  static TextStyle h1 = tt(size: 26, weight: FontWeight.w700);

  static TextStyle h2 = tt(size: 24, weight: FontWeight.w700);

  static TextStyle title = tt(size: 16, weight: FontWeight.w700);

  static TextStyle body =
      tt(size: 14, weight: FontWeight.w500, color: AppColors.textMuted, height: 1.45);

  static TextStyle bodyStrong = tt(size: 14, weight: FontWeight.w700);

  static TextStyle caption =
      tt(size: 12, weight: FontWeight.w600, color: AppColors.textMuted);

  static TextStyle number =
      tt(size: 20, weight: FontWeight.w700, color: AppColors.neonYellow);

  static TextStyle button = tt(
    size: 18,
    weight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.ctaText,
  );
}
