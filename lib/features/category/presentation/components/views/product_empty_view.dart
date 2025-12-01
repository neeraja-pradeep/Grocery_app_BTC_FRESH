import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';

class ProductEmptyView extends StatelessWidget {
  const ProductEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 32),
          AppSpacing.h12,
          AppText(
            text: 'No products available in this category yet.',
            fontSize: 15.sp,
            textAlign: TextAlign.center,
          ),
          AppSpacing.h8,
          AppText(
            text: 'Please check back later.',
            fontSize: 12.sp,
            textAlign: TextAlign.center,
            color: AppColors.grey,
          ),
        ],
      ),
    );
  }
}
