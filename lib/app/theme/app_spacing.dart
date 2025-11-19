import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralised spacing tokens to keep layout gaps consistent.
class AppSpacing {
  const AppSpacing._();

  /// Common vertical gaps.
  static SizedBox get h4 => SizedBox(height: 4.h);
  static SizedBox get h8 => SizedBox(height: 8.h);
  static SizedBox get h10 => SizedBox(height: 10.h);
  static SizedBox get h12 => SizedBox(height: 12.h);
  static SizedBox get h16 => SizedBox(height: 16.h);
  static SizedBox get h24 => SizedBox(height: 24.h);
  static SizedBox get h32 => SizedBox(height: 32.h);
  static SizedBox get h40 => SizedBox(height: 40.h);
  static SizedBox get h48 => SizedBox(height: 48.h);
  static SizedBox get h50 => SizedBox(height: 50.h);

  /// Common horizontal gaps.
  static SizedBox get w4 => SizedBox(width: 4.w);
  static SizedBox get w8 => SizedBox(width: 8.w);
  static SizedBox get w12 => SizedBox(width: 12.w);
  static SizedBox get w16 => SizedBox(width: 16.w);
  static SizedBox get w24 => SizedBox(width: 24.w);

  /// Custom gap helpers.
  static SizedBox verticalGap(double value) => SizedBox(height: value.h);
  static SizedBox horizontalGap(double value) => SizedBox(width: value.w);

  /// Numeric helpers for padding/insets.
  static double horizontal(double value) => value.w;
  static double vertical(double value) => value.h;
}
