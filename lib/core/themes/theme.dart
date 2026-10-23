import 'package:flutter/material.dart';
import 'package:laci/core/style/app_colors.dart';
import 'package:laci/core/themes/button/button_theme.dart';
import 'package:laci/core/themes/card/card_theme.dart';
import 'package:laci/core/themes/input/input_theme.dart';
import 'appbar/appbar_theme.dart';

class AppThemeLegacy {
  AppThemeLegacy._();

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.white,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.white,
        outline: Color(0xFFE2E8F0),
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppAppBarTheme.lightAppBarTheme,
      inputDecorationTheme: InputTheme.lightInputDecorationTheme,
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerColor: const Color(0xFFE2E8F0),
      textButtonTheme: LaciButtonTheme.lightTextButtonTheme,
      floatingActionButtonTheme: LaciButtonTheme.lightFloatingActionButtonTheme,
      cardTheme: LaciCardTheme.lightCardTheme,
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.white,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.white,
        surface: Color(0xFF1E293B),
        onSurface: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
        outline: Color(0xFF334155),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: AppAppBarTheme.darkAppBarTheme,
      inputDecorationTheme: InputTheme.darkInputDecorationTheme,
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E293B),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerColor: const Color(0xFF334155),
      textButtonTheme: LaciButtonTheme.lightTextButtonTheme,
      floatingActionButtonTheme: LaciButtonTheme.lightFloatingActionButtonTheme,
      cardTheme: LaciCardTheme.darkCardTheme,
      useMaterial3: true,
    );
  }
}
