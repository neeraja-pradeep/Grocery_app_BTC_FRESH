import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';

/// Rating and Review Section Component
///
/// Displays product rating with:
/// - 5-star visual indicator
/// - Numerical rating (e.g., 4.5)
/// - Review count (e.g., "120 reviews")
/// - Clean bordered design with spacing above and below
class RatingSection extends StatelessWidget {
  const RatingSection({
    super.key,
    required this.rating,
    required this.reviewCount,
  });

  final double rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          AppText(
            text: 'Review',
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
          const Spacer(),
          _RatingStars(rating: rating),
          AppSpacing.w8,
          AppText(
            text: rating.toStringAsFixed(1),
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.green,
          ),
          if (reviewCount != null) ...[
            AppSpacing.w12,
            AppText(
              text: '($reviewCount reviews)',
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
          ],
        ],
      ),
    );
  }
}

/// Rating stars visual widget
/// Displays 0-5 full, half, or empty stars based on rating value
class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
              ? Icons.star_half
              : Icons.star_outline,
          color: Colors.deepOrangeAccent,
          size: 16.sp,
        ),
      ),
    );
  }
}
