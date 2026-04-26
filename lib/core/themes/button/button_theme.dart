import 'package:flutter/material.dart';

import '../../style/app_colors.dart';

class LaciButtonTheme {
  LaciButtonTheme._();

  static TextButtonThemeData get lightTextButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
      ),
    );
  }

  static FloatingActionButtonThemeData get lightFloatingActionButtonTheme {
    return FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    );
  }
}
