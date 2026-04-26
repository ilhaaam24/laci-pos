import 'package:flutter/material.dart';
import 'package:laci/core/style/app_colors.dart';

class InputTheme {
  InputTheme._();

  static InputDecorationTheme get lightInputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      
      hintStyle: const TextStyle(
        color: AppColors.textInput,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: const TextStyle(
        color: AppColors.textInput,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(color: AppColors.primary),
      errorStyle: const TextStyle(color: AppColors.error),
      prefixIconColor: AppColors.textInput,
      suffixIconColor: AppColors.textInput,
    );
  }

  // ============ DARK THEME ============
}
