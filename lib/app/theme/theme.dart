// lib/app/theme/theme.dart

import 'package:flutter/material.dart';
import 'colors.dart';

/// Application theme configuration
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      primaryColor: AppColors.primaryGreenDark,
      scaffoldBackgroundColor: AppColors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreenDark,
        foregroundColor: AppColors.headerDarkText,
      ),
    );
  }
}
