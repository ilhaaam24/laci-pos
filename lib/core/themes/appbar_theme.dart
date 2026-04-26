import 'package:flutter/material.dart';
import 'package:laci/core/style/app_colors.dart';

class AppbarTheme {
  static const lightAppBarTheme = AppBarThemeData(
    backgroundColor: AppColors.surface,
    foregroundColor: Colors.black,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: AppColors.primary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
  static const darkAppBarTheme = AppBarThemeData(
    backgroundColor: AppColors.darkBackground,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: AppColors.primary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
}
