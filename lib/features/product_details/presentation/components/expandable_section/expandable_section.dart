import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';

/// Expandable section component with optional badge
class ExpandableSection extends StatelessWidget {
  const ExpandableSection({
    super.key,
    required this.title,
    this.isExpanded,
    required this.onToggle,
    required this.child,
    this.badge,
  });

  final String title;
  final bool? isExpanded;
  final VoidCallback onToggle;
  final Widget child;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.grey.withValues(alpha: 0.15),
              width: 1.h,
            ),
            top: BorderSide(
              color: AppColors.grey.withValues(alpha: 0.15),
              width: 1.h,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      AppText(
                        text: title,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                      if (badge != null) ...[
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: AppText(
                            text: badge!,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isExpanded != null)
                  Icon(
                    isExpanded!
                        ? Icons.expand_more
                        : Icons.chevron_right_outlined,
                    color: AppColors.black,
                    size: 22.sp,
                  ),
              ],
            ),
            if (isExpanded ?? false) ...[AppSpacing.h10, child],
          ],
        ),
      ),
    );
  }
}
