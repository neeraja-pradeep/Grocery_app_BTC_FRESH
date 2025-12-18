import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/button_styles.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../category/presentation/components/widgets/review_bottom_sheet.dart';
import '../../../home/application/providers/delivery_status_provider.dart';
import '../../../orders/application/providers/orders_provider.dart';
import '../../../orders/infrastructure/data_sources/orders_api.dart';

class ConfirmOrderScreen extends ConsumerStatefulWidget {
  const ConfirmOrderScreen({super.key});

  @override
  ConsumerState<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends ConsumerState<ConfirmOrderScreen> {
  bool _hasShownRatingSheet = false;

  @override
  void initState() {
    super.initState();
    // Start delivery tracking when order is confirmed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDeliveryTracking();
    });
  }

  void _startDeliveryTracking() {
    // Generate a unique order ID for tracking (in production this would come from payment response)
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    ref.read(deliveryStatusProvider.notifier).startDeliveryTracking(orderId);
    Logger.info('Delivery tracking started for order: $orderId');
  }

  Future<void> _handleBackNavigation() async {
    // Only show rating sheet once
    if (_hasShownRatingSheet) {
      if (mounted) {
        context.go('/home');
      }
      return;
    }

    _hasShownRatingSheet = true;

    // Fetch the latest order to get the order ID
    try {
      await ref.read(ordersProvider.notifier).fetchCompletedOrders();
      final ordersState = ref.read(ordersProvider);

      // Get the most recent order (first in the list)
      if (ordersState.completedOrders.isNotEmpty) {
        final latestOrder = ordersState.completedOrders.first;

        // Show rating bottom sheet
        if (mounted) {
          final rating = await ReviewBottomSheet.show(
            context,
            orderTitle: 'Rate Your Order',
            orderSubtitle: 'Order #${latestOrder.id}',
          );

          // If user provided a rating, submit it
          if (rating != null && rating > 0 && mounted) {
            try {
              await ref
                  .read(ordersApiProvider)
                  .submitOrderRating(orderId: latestOrder.id, stars: rating);

              if (mounted) {
                AppSnackbar.success(context, 'Thank you for your rating!');
              }
            } catch (e) {
              Logger.error('Failed to submit rating: $e', error: e);
              if (mounted) {
                AppSnackbar.error(context, 'Failed to submit rating');
              }
            }
          }
        }
      }
    } catch (e) {
      Logger.error('Failed to fetch latest order for rating: $e', error: e);
    }

    // Navigate to home after showing rating sheet (or if it failed)
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.0.w),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 140.h),
                  AppText(
                    text: 'Order Success!',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),

                  SizedBox(height: 16.h),

                  // Description
                  AppText(
                    text:
                        'Your order is on the way. We\'ll keep you posted every step of the journey, so you\'ll know exactly when to get excited for your needs.',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightGrey,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                  ),
                  SizedBox(height: 60.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/success.png',
                        width: 269.w,
                        height: 240.h,
                      ),
                      SizedBox(width: 40.w),
                    ],
                  ),

                  const Spacer(),

                  // Back to Home Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleBackNavigation,
                      style: ButtonStyles.greyButton,
                      child: AppText(
                        text: 'Back',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
