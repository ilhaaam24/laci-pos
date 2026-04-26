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
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppAppBarTheme.lightAppBarTheme,
      inputDecorationTheme: InputTheme.lightInputDecorationTheme,
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
        surface: Color(0xFF0F172A),
        onSurface: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
      ),
      appBarTheme: AppAppBarTheme.darkAppBarTheme,
      textButtonTheme: LaciButtonTheme.lightTextButtonTheme,
      floatingActionButtonTheme: LaciButtonTheme.lightFloatingActionButtonTheme,
      cardTheme: LaciCardTheme.lightCardTheme,
      useMaterial3: true,
    );
  }
}
