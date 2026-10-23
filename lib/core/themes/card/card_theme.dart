import 'package:flutter/material.dart';

import 'package:laci/core/style/app_colors.dart';

class LaciCardTheme {
  LaciCardTheme._();

  static CardThemeData get lightCardTheme => CardThemeData(
    color: AppColors.surface,
    elevation: 3,
    shadowColor: AppColors.primary.withValues(alpha: 0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(48),
      side: BorderSide(color: Colors.transparent),
    ),
  );

  static CardThemeData get darkCardTheme => CardThemeData(
    color: const Color(0xFF1E293B),
    elevation: 3,
    shadowColor: Colors.black.withValues(alpha: 0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(48),
      side: BorderSide(color: Colors.transparent),
    ),
  );
}
