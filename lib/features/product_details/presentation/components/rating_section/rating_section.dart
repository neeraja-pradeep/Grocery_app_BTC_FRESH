import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../category/presentation/components/widgets/review_bottom_sheet.dart';

/// Rating and Review Section Component
///
/// Displays product rating with:
/// - 5-star visual indicator
/// - Numerical rating (e.g., 4.5)
/// - Review count (e.g., "120 reviews")
/// - Expandable rating submission UI (only if user has ordered this product)
/// - Clean bordered design with spacing above and below
class RatingSection extends StatefulWidget {
  const RatingSection({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.orderId,
    this.deliveryDate,
    this.onRatingSubmit,
    this.allowExpansion = true,
  });

  final double rating;
  final int? reviewCount;
  final int? orderId; // Order ID if user has ordered this product
  final void Function(int rating, int orderId)? onRatingSubmit;
  final String?
  deliveryDate; // Delivery date to show in bottom sheet (null for post-payment rating)
  final bool
  allowExpansion; // Whether to allow expansion (false for guest mode)

  @override
  State<RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<RatingSection> {
  bool _isExpanded = false;
  int _userRating = 0;

  void _toggleExpanded() {
    // Don't allow expansion if disabled (guest mode)
    if (!widget.allowExpansion) return;

    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<void> _showReviewBottomSheet() async {
    // Only show bottom sheet if user has ordered this product
    if (widget.orderId == null) return;

    final rating = await ReviewBottomSheet.show(
      context,
      orderTitle: 'Rate this product',
      // Show delivery date if available (completed orders), otherwise generic text
      orderSubtitle: widget.deliveryDate != null
          ? 'Delivered on ${widget.deliveryDate}'
          : 'Share your experience',
    );

    if (rating != null && mounted && widget.orderId != null) {
      setState(() {
        _userRating = rating;
      });
      widget.onRatingSubmit?.call(rating, widget.orderId!);
    }
  }

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
      child: Column(
        children: [
          // Main rating row with expand arrow
          GestureDetector(
            onTap: _toggleExpanded,
            child: Row(
              children: [
                AppText(
                  text: 'Review',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
                const Spacer(),
                _RatingStars(rating: widget.rating),
                AppSpacing.w8,
                AppText(
                  text: widget.rating.toStringAsFixed(1),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
                if (widget.reviewCount != null) ...[
                  AppSpacing.w12,
                  AppText(
                    text: '(${widget.reviewCount} reviews)',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                  ),
                ],
                // Dropdown arrow - only show if expansion is allowed
                if (widget.allowExpansion) ...[
                  AppSpacing.w8,
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.grey,
                      size: 20.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Expandable rating submission UI
          if (_isExpanded) ...[
            AppSpacing.h16,
            // Only show rating option if user has ordered this product
            if (widget.orderId != null)
              GestureDetector(
                onTap: _showReviewBottomSheet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // User rating stars (display only - tapping opens bottom sheet)
                        _UserRatingStars(
                          rating: _userRating,
                          onRatingChanged: (_) => _showReviewBottomSheet(),
                        ),
                      ],
                    ),
                    AppSpacing.h8,
                    // Rate your previous order text with delivery date
                    AppText(
                      text: widget.deliveryDate != null
                          ? 'Rate your previous order\nDelivered on ${widget.deliveryDate}'
                          : 'Rate your previous order',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey,
                      maxLines: 2,
                    ),
                  ],
                ),
              )
            else
              AppText(
                text: 'No completed orders',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.grey.withValues(alpha: 0.7),
              ),
          ],
        ],
      ),
    );
  }
}

/// Rating stars visual widget (display only)
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

/// User rating stars widget (interactive)
/// Allows user to select a rating by tapping stars
class _UserRatingStars extends StatelessWidget {
  const _UserRatingStars({required this.rating, required this.onRatingChanged});

  final int rating;
  final void Function(int rating) onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = starIndex <= rating;
        return GestureDetector(
          onTap: () => onRatingChanged(starIndex),
          child: Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              color: isSelected ? const Color(0xFFFFB800) : AppColors.grey,
              size: 24.sp,
            ),
          ),
        );
      }),
    );
  }
}
