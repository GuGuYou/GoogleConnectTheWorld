import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle display(BuildContext context) => GoogleFonts.baloo2(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.05,
      );

  static TextStyle h1 = GoogleFonts.baloo2(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle h2 = GoogleFonts.baloo2(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle title = GoogleFonts.nunito(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle bodyStrong = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle caption = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static TextStyle number = GoogleFonts.baloo2(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.neonPink,
  );

  static TextStyle button = GoogleFonts.baloo2(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
    color: Colors.white,
  );
}
