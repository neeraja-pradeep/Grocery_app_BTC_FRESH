// lib/features/home/presentation/components/delivery_status_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../application/providers/delivery_status_provider.dart';
import '../../application/states/delivery_status_state.dart';
import '../../domain/entities/delivery.dart';

/// A delivery status bar widget that displays order tracking status from backend.
///
/// Shows:
/// - Loading state while fetching delivery info
/// - Active status with estimated time badge
/// - Completed status with success indicator
/// - Failed status with failure reason
///
/// All status values come from the backend API controlled by admin.
class DeliveryStatusBar extends ConsumerStatefulWidget {
  const DeliveryStatusBar({super.key});

  @override
  ConsumerState<DeliveryStatusBar> createState() => _DeliveryStatusBarState();
}

class _DeliveryStatusBarState extends ConsumerState<DeliveryStatusBar> {
  @override
  void initState() {
    super.initState();
    // Set context after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(deliveryStatusProvider.notifier).setContext(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryStatusProvider);

    return deliveryState.map(
      hidden: (_) => const SizedBox.shrink(),
      loading: (state) => _buildLoadingBar(context, state.orderId),
      active: (state) => _buildActiveBar(context, ref, state),
      completed: (state) => _buildCompletedBar(context, ref, state),
      failed: (state) => _buildFailedBar(context, ref, state),
      error: (state) => _buildErrorBar(context, ref, state),
    );
  }

  /// Build loading state bar
  Widget _buildLoadingBar(BuildContext context, int orderId) {
    return _buildContainer(
      child: Row(
        children: [
          // Loading indicator
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8BC34A), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: SizedBox(
              width: 20.w,
              height: 20.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Waiting for store to accept your order',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Order #$orderId',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build active delivery status bar
  Widget _buildActiveBar(
    BuildContext context,
    WidgetRef ref,
    DeliveryStatusActive state,
  ) {
    final status = state.status;

    // Special handling for pending and assigned statuses
    if (status == DeliveryApiStatus.pending) {
      return _buildPendingBar(context, ref, state);
    } else if (status == DeliveryApiStatus.assigned) {
      return _buildAssignedBar(context, ref, state);
    }

    // Regular active status for other states
    return _buildContainer(
      onTap: () {
        // Navigate to order tracking screen
        // For now, just refresh the status
        ref.read(deliveryStatusProvider.notifier).refresh();
      },
      child: Row(
        children: [
          // Time badge with gradient
          _buildTimeBadge(status),
          SizedBox(width: 12.w),
          // Status text
          Expanded(child: _buildStatusText(status)),
          // Arrow button
          _buildArrowButton(),
        ],
      ),
    );
  }

  /// Build pending status bar (waiting for store to accept)
  Widget _buildPendingBar(
    BuildContext context,
    WidgetRef ref,
    DeliveryStatusActive state,
  ) {
    return _buildContainer(
      backgroundColor: const Color(0xFFFFF9E6), // Light amber background
      borderColor: const Color(0xFFFFE082), // Amber border
      onTap: () {
        ref.read(deliveryStatusProvider.notifier).refresh();
      },
      child: Row(
        children: [
          // Pending icon with animation
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFB74D),
                  Color(0xFFFFA726),
                ], // Orange gradient
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: SizedBox(
              width: 20.w,
              height: 20.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Waiting for store to accept',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF57C00), // Dark orange
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Your order is being reviewed by the store',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          // Estimated time badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              '~40 min',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build assigned status bar (order accepted by store)
  Widget _buildAssignedBar(
    BuildContext context,
    WidgetRef ref,
    DeliveryStatusActive state,
  ) {
    return _buildContainer(
      backgroundColor: const Color(0xFFE8F5E9), // Light green background
      borderColor: const Color(0xFF81C784), // Light green border
      onTap: () {
        ref.read(deliveryStatusProvider.notifier).refresh();
      },
      child: Row(
        children: [
          // Success check icon
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF66BB6A),
                  Color(0xFF4CAF50),
                ], // Green gradient
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order Accepted!',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E7D32), // Dark green
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Your order is being prepared',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          // Estimated time badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              '~40 min',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build completed delivery status bar
  Widget _buildCompletedBar(
    BuildContext context,
    WidgetRef ref,
    DeliveryStatusCompleted state,
  ) {
    final delivery = state.delivery;

    return _buildContainer(
      onTap: () {
        // Dismiss the bar
        ref.read(deliveryStatusProvider.notifier).hide();
      },
      child: Row(
        children: [
          // Success badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.check_circle, color: Colors.white, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order delivered!',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  delivery.notes ?? 'Thank you for your order',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF888888),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Close button
          _buildCloseButton(ref),
        ],
      ),
    );
  }

  /// Build failed delivery status bar
  Widget _buildFailedBar(
    BuildContext context,
    WidgetRef ref,
    DeliveryStatusFailed state,
  ) {
    final failureReason =
        state.failureReason ?? 'Delivery could not be completed';

    return _buildContainer(
      backgroundColor: const Color(0xFFFFF3F3),
      borderColor: const Color(0xFFFFCDD2),
      onTap: () {
        // Show detailed failure info or navigate to order details
      },
      child: Row(
        children: [
          // Failure badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE57373), Color(0xFFD32F2F)],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.error_outline, color: Colors.white, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delivery failed',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD32F2F),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  failureReason,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF888888),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Dismiss button
          GestureDetector(
            onTap: () =>
                ref.read(deliveryStatusProvider.notifier).dismissFailure(),
            child: Container(
              width: 32.w,
              height: 32.h,
              decoration: const BoxDecoration(
                color: Color(0xFFD32F2F),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 16.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state bar
  Widget _buildErrorBar(
    BuildContext context,
    WidgetRef ref,
    DeliveryStatusError state,
  ) {
    return _buildContainer(
      backgroundColor: const Color(0xFFFFF8E1),
      borderColor: const Color(0xFFFFE082),
      onTap: () {
        // Retry fetching status
        ref.read(deliveryStatusProvider.notifier).refresh();
      },
      child: Row(
        children: [
          // Warning icon
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA000),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          // Error text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Unable to fetch status',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Tap to retry',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          // Retry button
          Icon(Icons.refresh, size: 24.sp, color: const Color(0xFFFFA000)),
        ],
      ),
    );
  }

  /// Build container with common styling
  Widget _buildContainer({
    required Widget child,
    VoidCallback? onTap,
    Color backgroundColor = Colors.white,
    Color borderColor = const Color(0xFFE0E0E0),
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Build time badge with gradient
  Widget _buildTimeBadge(DeliveryApiStatus status) {
    final isDelivered = status == DeliveryApiStatus.delivered;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDelivered
              ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
              : [const Color(0xFF8BC34A), const Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDelivered) ...[
            Text(
              '10',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            Text(
              'mins',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ] else
            Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
        ],
      ),
    );
  }

  /// Build status text
  Widget _buildStatusText(DeliveryApiStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          status.displayText,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Delivery person will contact you soon..',
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF888888)),
        ),
      ],
    );
  }

  /// Build arrow button
  Widget _buildArrowButton() {
    return Container(
      width: 32.w,
      height: 32.h,
      decoration: const BoxDecoration(
        color: Color(0xFF016064),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14.sp,
        color: Colors.white,
      ),
    );
  }

  /// Build close button
  Widget _buildCloseButton(WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(deliveryStatusProvider.notifier).hide(),
      child: Container(
        width: 32.w,
        height: 32.h,
        decoration: const BoxDecoration(
          color: Color(0xFF4CAF50),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close, size: 16.sp, color: Colors.white),
      ),
    );
  }
}
