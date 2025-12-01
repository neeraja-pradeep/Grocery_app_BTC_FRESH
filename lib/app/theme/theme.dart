import 'package:flutter/material.dart';

import 'colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.green,
          surface: AppColors.white,
          surfaceTint: Colors.transparent,
          onSurfaceVariant: const Color(0xFFE2E2E2),
        ),
    scaffoldBackgroundColor: AppColors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: Typography.blackMountainView,
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: Typography.whiteMountainView,
  );

  // Alternative light theme using feature branch colors
  static ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.green,
    primaryColor: AppColors.primaryGreenDark,
    scaffoldBackgroundColor: AppColors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryGreenDark,
      foregroundColor: AppColors.headerDarkText,
    ),
  );
}
