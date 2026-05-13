import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_text.dart';

/// Delivery tracking placeholder — feature not yet available.
class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 56.sp,
              color: AppColors.grey.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            AppText(
              text: 'Delivery tracking coming soon',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
