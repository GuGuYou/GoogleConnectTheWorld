import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// 文字样式令牌：Rajdhani（标题/数字）+ Noto Sans SC（正文）
class AppTextStyles {
  AppTextStyles._();

  static TextStyle display(BuildContext context) => GoogleFonts.rajdhani(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.2,
        height: 1.05,
      );

  static TextStyle h1 = GoogleFonts.rajdhani(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle h2 = GoogleFonts.rajdhani(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle title = GoogleFonts.notoSansSc(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.notoSansSc(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle bodyStrong = GoogleFonts.notoSansSc(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle caption = GoogleFonts.notoSansSc(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static TextStyle number = GoogleFonts.rajdhani(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.neonCyan,
  );

  static TextStyle button = GoogleFonts.rajdhani(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: Colors.white,
  );
}
