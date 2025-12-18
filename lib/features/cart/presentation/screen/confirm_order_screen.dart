import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/button_styles.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../home/application/providers/delivery_status_provider.dart';
import '../../../orders/application/providers/orders_provider.dart';

class ConfirmOrderScreen extends ConsumerStatefulWidget {
  const ConfirmOrderScreen({super.key});

  @override
  ConsumerState<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends ConsumerState<ConfirmOrderScreen> {
  int? _latestOrderId;

  @override
  void initState() {
    super.initState();
    // Fetch latest order and start delivery tracking when order is confirmed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLatestOrderAndStartTracking();
    });
  }

  /// Fetch the latest order from API and start delivery tracking
  Future<void> _fetchLatestOrderAndStartTracking() async {
    try {
      // Fetch active/pending orders to get the most recent one
      await ref.read(ordersProvider.notifier).fetchActiveOrders();
      final ordersState = ref.read(ordersProvider);

      // Get the most recent active order
      if (ordersState.activeOrders.isNotEmpty) {
        final latestOrder = ordersState.activeOrders.first;
        _latestOrderId = latestOrder.id;

        // Start delivery tracking with the real order ID
        ref
            .read(deliveryStatusProvider.notifier)
            .startDeliveryTracking(latestOrder.id);
        Logger.info('Delivery tracking started for order: ${latestOrder.id}');
      } else {
        // Fallback: Try fetching pending orders
        await ref.read(ordersProvider.notifier).fetchPendingOrders();
        final pendingState = ref.read(ordersProvider);

        if (pendingState.pendingOrders.isNotEmpty) {
          final latestOrder = pendingState.pendingOrders.first;
          _latestOrderId = latestOrder.id;

          ref
              .read(deliveryStatusProvider.notifier)
              .startDeliveryTracking(latestOrder.id);
          Logger.info(
            'Delivery tracking started for pending order: ${latestOrder.id}',
          );
        } else {
          Logger.warning('No active or pending orders found for tracking');
        }
      }
    } catch (e) {
      Logger.error('Failed to fetch latest order for tracking: $e', error: e);
    }
  }

  Future<void> _handleBackNavigation() async {
    // Navigate directly to home without showing rating sheet
    // Rating will be shown only when delivery status becomes "delivered"
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
