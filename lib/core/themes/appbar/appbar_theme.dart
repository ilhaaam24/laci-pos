import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laci/core/style/app_colors.dart';

/// AppBar Theme for Laci POS
/// Supports Light and Dark mode with brand colors
class AppAppBarTheme {
  AppAppBarTheme._();

  // ============================================================
  // LIGHT APP BAR THEME
  // ============================================================

  static const AppBarTheme lightAppBarTheme = AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.primary,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.primary),
    actionsIconTheme: IconThemeData(color: AppColors.primary),
    titleTextStyle: TextStyle(
      color: AppColors.primary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  );

  // ============================================================
  // DARK APP BAR THEME
  // ============================================================

  static const AppBarTheme darkAppBarTheme = AppBarTheme(
    backgroundColor: Color(0xFF1E293B), // Slate 800
    foregroundColor: AppColors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.white),
    actionsIconTheme: IconThemeData(color: AppColors.white),
    titleTextStyle: TextStyle(
      color: AppColors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  );

  // ============================================================
  // TRANSPARENT APP BAR
  // ============================================================

  static const AppBarTheme transparentAppBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.white,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.white),
    actionsIconTheme: IconThemeData(color: AppColors.white),
  );
}
