import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/theme/colors.dart';

/// Global snackbar utility for consistent, elegant notifications
///
/// Usage:
/// ```dart
/// AppSnackbar.success(context, 'Item added to cart');
/// AppSnackbar.warning(context, 'Low stock available');
/// AppSnackbar.error(context, 'Failed to add item');
/// AppSnackbar.info(context, 'Syncing data...');
/// ```
class AppSnackbar {
  AppSnackbar._();

  /// Show success message (green)
  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      accentColor: AppColors.green100,
    );
  }

  /// Show warning message (orange/amber)
  static void warning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      accentColor: const Color(0xFFE67E22),
      duration: const Duration(seconds: 3),
    );
  }

  /// Show error message (red)
  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline,
      accentColor: const Color(0xFFE74C3C),
      duration: const Duration(seconds: 3),
    );
  }

  /// Show info message (blue)
  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline,
      accentColor: const Color(0xFF3498DB),
    );
  }

  /// Internal show method
  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color accentColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Dismiss any existing snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: accentColor, size: 22.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        padding: EdgeInsets.zero,
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}
