import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Figma spec fonts are TikTok Display / TikTok Sans Display (display) and
/// PingFang SC (body) — neither ships via google_fonts, so we substitute
/// Rubik (display) and Inter (body); CJK falls back to the system font.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle display(BuildContext context) => GoogleFonts.rubik(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  static TextStyle h1 = GoogleFonts.rubik(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle h2 = GoogleFonts.rubik(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle title = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.45,
  );

  static TextStyle bodyStrong = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static TextStyle number = GoogleFonts.rubik(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.neonYellow,
  );

  static TextStyle button = GoogleFonts.rubik(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.ctaText,
  );
}
