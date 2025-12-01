import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/product_variant.dart';

/// Product reviews section with stagger animation
class ProductReviews extends StatefulWidget {
  const ProductReviews({super.key, required this.reviews});

  final List<ProductVariantReview>? reviews;

  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    final reviewCount = widget.reviews?.length ?? 0;
    _controllers = List.generate(
      reviewCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    // Stagger animation - each card animates with delay
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted && i < _controllers.length) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(ProductReviews oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reviews?.length != oldWidget.reviews?.length) {
      for (var controller in _controllers) {
        controller.dispose();
      }
      _initializeAnimations();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reviews == null || widget.reviews!.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: AppText(
            text: 'No reviews yet',
            fontSize: 14.sp,
            color: AppColors.grey,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: 'Customer Reviews',
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.green100,
        ),
        AppSpacing.h12,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.reviews!.length,
          separatorBuilder: (_, _) =>
              Divider(height: 16.h, thickness: 1, color: AppColors.green10),
          itemBuilder: (context, index) {
            return _AnimatedReviewCard(
              review: widget.reviews![index],
              animation: _controllers[index],
            );
          },
        ),
      ],
    );
  }
}

/// Animated review card with slide and fade effect
class _AnimatedReviewCard extends StatelessWidget {
  const _AnimatedReviewCard({required this.review, required this.animation});

  final ProductVariantReview review;
  final AnimationController animation;

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

    final fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: _ReviewCard(review: review),
      ),
    );
  }
}

/// Individual review card
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ProductVariantReview review;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: User name and rating
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              text: review.userName,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.green100,
            ),
            _buildRatingStars(review.rating),
          ],
        ),
        AppSpacing.h4,
        // Comment
        AppText(
          text: review.comment,
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.grey,
          maxLines: 3,
        ),
        AppSpacing.h8,
        // Footer: Date and helpful count
        Row(
          children: [
            AppText(
              text: _formatDate(review.createdAt),
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.grey,
            ),
            if (review.helpfulCount != null) ...[
              AppSpacing.w12,
              Icon(Icons.thumb_up, size: 12.sp, color: AppColors.green),
              AppSpacing.w4,
              AppText(
                text: '${review.helpfulCount}',
                fontSize: 10.sp,
                color: AppColors.green,
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Build rating stars
  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
              ? Icons.star_half
              : Icons.star_outline,
          color: Colors.amber,
          size: 14.sp,
        ),
      ),
    );
  }

  /// Format date to relative format
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
