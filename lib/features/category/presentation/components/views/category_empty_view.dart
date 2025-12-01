import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';

class CategoryEmptyView extends StatelessWidget {
  const CategoryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_outlined, size: 32),
          AppSpacing.h12,
          AppText(
            text: 'No categories available yet.',
            fontSize: 15.sp,
            textAlign: TextAlign.center,
          ),
          AppSpacing.h8,
          AppText(
            text: 'Pull to refresh or try again later.',
            fontSize: 12.sp,
            textAlign: TextAlign.center,
            color: AppColors.grey,
          ),
        ],
      ),
    );
  }
}
