import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';

/// Review bottom sheet component for rating orders
class ReviewBottomSheet extends StatefulWidget {
  const ReviewBottomSheet({
    super.key,
    this.orderTitle = 'Rate Your Order',
    this.orderSubtitle = 'Delivered on Thu, 16 Oct',
    this.onSubmit,
  });

  final String orderTitle;
  final String orderSubtitle;
  final void Function(int rating)? onSubmit;

  /// Shows the review bottom sheet
  static Future<int?> show(
    BuildContext context, {
    String orderTitle = 'Rate Your Order',
    String orderSubtitle = 'Delivered on Thu, 16 Oct',
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewBottomSheet(
        orderTitle: orderTitle,
        orderSubtitle: orderSubtitle,
        onSubmit: (rating) => Navigator.pop(context, rating),
      ),
    );
  }

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  int _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 408.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFC9F4AA), // rgba(201, 244, 170, 1)
            Color(0xFFFFFFFF), // rgba(255, 255, 255, 1)
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 32.h),
          // Review SVG image
          _buildReviewImage(),
          SizedBox(height: 20.h),
          // Title
          _buildTitle(),
          SizedBox(height: 24.h),
          // Rating container
          _buildRatingContainer(),
          SizedBox(height: 24.h),

          // Submit button
          _buildSubmitButton(),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildReviewImage() {
    return Image.asset('assets/images/review.png', width: 80.h, height: 80.h);
  }

  Widget _buildTitle() {
    return AppText(
      text: 'How Was Your Experience',
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.green100,
    );
  }

  Widget _buildRatingContainer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Order image placeholder
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.green60.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          SizedBox(width: 12.w),
          // Order info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: widget.orderTitle,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.green100,
                ),
                SizedBox(height: 4.h),
                AppText(
                  text: widget.orderSubtitle,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey,
                ),
                SizedBox(height: 8.h),
                // Star rating
                _buildStarRating(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      children: List.generate(5, (index) {
        final isSelected = index < _selectedRating;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = index + 1;
            });
          },
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

  Widget _buildSubmitButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: GestureDetector(
        onTap: () {
          if (widget.onSubmit != null && _selectedRating > 0) {
            widget.onSubmit?.call(_selectedRating);
          } else {
            // If no onSubmit callback or no rating selected, just close
            Navigator.pop(
              context,
              _selectedRating > 0 ? _selectedRating : null,
            );
          }
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: const Color(0xFF8BC34A),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: AppText(
              text: 'Submit',
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
