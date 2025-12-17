// lib/features/home/presentation/components/delivery_status_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../application/providers/delivery_status_provider.dart';
import '../../application/states/delivery_status_state.dart';

/// A delivery status bar widget that displays order tracking status.
///
/// Shows:
/// - Estimated time badge (green pill)
/// - Status text
/// - Navigation arrow
///
/// UI matches the provided design with green accent color.
class DeliveryStatusBar extends ConsumerWidget {
  const DeliveryStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryStatus = ref.watch(deliveryStatusProvider);

    return deliveryStatus.map(
      hidden: (_) => const SizedBox.shrink(),
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
    );
  }

  Widget _buildStatusBar(
    BuildContext context,
    WidgetRef ref, {
    required DeliveryStage stage,
    required bool isCompleted,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                // Time badge
                _buildTimeBadge(stage, isCompleted),
                SizedBox(width: 12.w),

                // Status text
                Expanded(child: _buildStatusText(stage)),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.sp,
                  color: const Color(0xFF016064),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBadge(DeliveryStage stage, bool isCompleted) {
    final isDelivered = stage == DeliveryStage.orderCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDelivered
            ? const Color(0xFF4CAF50) // Bright green for delivered
            : const Color(0xFF016064), // Teal for in-progress
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        stage.estimatedTime,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
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
          _getSubtitle(stage),
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF666666)),
        ),
      ],
    );
  }

  String _getSubtitle(DeliveryStage stage) {
    switch (stage) {
      case DeliveryStage.orderGettingPacked:
        return 'Your order is being prepared';
      case DeliveryStage.orderPacked:
        return 'Ready for pickup by delivery partner';
      case DeliveryStage.outForDelivery:
        return 'On the way to your location';
      case DeliveryStage.orderCompleted:
        return 'Thank you for ordering!';
    }
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
