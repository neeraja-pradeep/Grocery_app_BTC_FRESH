// lib/features/home/presentation/components/delivery_status_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../application/providers/delivery_status_provider.dart';
import '../../application/states/delivery_status_state.dart';

/// A delivery status bar widget that displays order tracking status.
///
/// Shows:
/// - Estimated time badge (green gradient pill with time)
/// - Status text (bold title + subtitle)
/// - Navigation arrow (teal circle with arrow)
///
/// UI matches the Figma design.
class DeliveryStatusBar extends ConsumerWidget {
  const DeliveryStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryStatus = ref.watch(deliveryStatusProvider);

    // Parent widget handles visibility, so we can directly render based on state
    return deliveryStatus.maybeMap(
      active: (activeState) => _buildStatusBar(
        context,
        ref,
        stage: activeState.stage,
        isCompleted: false,
      ),
      completed: (completedState) => _buildStatusBar(
        context,
        ref,
        stage: DeliveryStage.orderCompleted,
        isCompleted: true,
      ),
      // Fallback to empty in case parent doesn't filter correctly
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildStatusBar(
    BuildContext context,
    WidgetRef ref, {
    required DeliveryStage stage,
    required bool isCompleted,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
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
          onTap: () {
            // Navigate to order details or tracking screen
            // For now, just advance to next stage for demo
            ref.read(deliveryStatusProvider.notifier).advanceToNextStage();
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                // Time badge with gradient
                _buildTimeBadge(stage),
                SizedBox(width: 12.w),

                // Status text
                Expanded(child: _buildStatusText(stage)),

                // Arrow button
                _buildArrowButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBadge(DeliveryStage stage) {
    final isDelivered = stage == DeliveryStage.orderCompleted;

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
          Text(
            isDelivered ? '' : '10',
            style: TextStyle(
              color: Colors.white,
              fontSize: isDelivered ? 10.sp : 16.sp,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          if (!isDelivered)
            Text(
              'mins',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          if (isDelivered)
            Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
        ],
      ),
    );
  }

  Widget _buildStatusText(DeliveryStage stage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stage.displayText,
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
}

/// A compact version for tight spaces
class DeliveryStatusBarCompact extends ConsumerWidget {
  const DeliveryStatusBarCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryStatus = ref.watch(deliveryStatusProvider);

    return deliveryStatus.map(
      hidden: (_) => const SizedBox.shrink(),
      active: (activeState) => _buildCompactBar(activeState.stage),
      completed: (_) => _buildCompactBar(DeliveryStage.orderCompleted),
    );
  }

  Widget _buildCompactBar(DeliveryStage stage) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF016064),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              stage.estimatedTime,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            stage.displayText,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(width: 4.w),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12.sp,
            color: const Color(0xFF016064),
          ),
        ],
      ),
    );
  }
}
