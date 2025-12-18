// lib/features/home/application/providers/delivery_status_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../../category/presentation/components/widgets/review_bottom_sheet.dart';
import '../../domain/entities/delivery.dart';
import '../../infrastructure/data_sources/remote/delivery_api.dart';
import '../states/delivery_status_state.dart';

/// Provider for managing delivery status on the home screen.
///
/// Features:
/// - Fetches real delivery status from backend API
/// - Polls for status updates every 30 seconds
/// - Handles all delivery states: active, completed, failed
/// - Shows status bar after successful order payment
/// - Shows feedback popup when delivery is completed
class DeliveryStatusNotifier extends StateNotifier<DeliveryStatusState> {
  final DeliveryApi _deliveryApi;
  Timer? _pollingTimer;
  BuildContext? _context;
  bool _feedbackShown = false;
  static const Duration _pollingInterval = Duration(seconds: 30);
  static const Duration _completedHideDelay = Duration(seconds: 10);

  DeliveryStatusNotifier(this._deliveryApi)
    : super(const DeliveryStatusState.hidden());

  /// Set the BuildContext for showing feedback popup
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Start tracking delivery after successful payment
  /// [orderId] - The order ID from the payment response
  void startDeliveryTracking(int orderId) {
    Logger.info('Starting delivery tracking for order: $orderId');

    // Reset feedback flag for new order
    _feedbackShown = false;

    // Cancel any existing polling
    _pollingTimer?.cancel();

    // Set loading state
    state = DeliveryStatusState.loading(orderId: orderId);

    // Fetch initial status
    _fetchDeliveryStatus(orderId);

    // Start polling for updates
    _startPolling(orderId);
  }

  /// Fetch delivery status from API
  Future<void> _fetchDeliveryStatus(int orderId) async {
    try {
      final delivery = await _deliveryApi.getDeliveryStatus(orderId);

      if (!mounted) return;

      if (delivery == null) {
        // Delivery not yet assigned by admin - show loading/pending state
        state = DeliveryStatusState.loading(orderId: orderId);
        Logger.info('Delivery not yet assigned for order: $orderId');
        return;
      }

      // Update state based on delivery status
      _updateStateFromDelivery(orderId, delivery);
    } catch (e) {
      Logger.error('Error fetching delivery status: $e', error: e);
      if (!mounted) return;

      state = DeliveryStatusState.error(
        orderId: orderId,
        message: 'Unable to fetch delivery status',
      );
    }
  }

  /// Update state based on delivery entity from API
  void _updateStateFromDelivery(int orderId, DeliveryEntity delivery) {
    switch (delivery.status) {
      case DeliveryApiStatus.delivered:
        state = DeliveryStatusState.completed(
          orderId: orderId,
          delivery: delivery,
        );
        // Stop polling and auto-hide after delay
        _stopPolling();
        _scheduleAutoHide();
        // Show feedback popup (only once per delivery)
        _showFeedbackPopup();
        Logger.info('Delivery completed for order: $orderId');
        break;

      case DeliveryApiStatus.failed:
        state = DeliveryStatusState.failed(
          orderId: orderId,
          delivery: delivery,
          failureReason: delivery.notes,
        );
        // Stop polling on failure
        _stopPolling();
        Logger.info(
          'Delivery failed for order: $orderId, reason: ${delivery.notes}',
        );
        break;

      default:
        // Active states: assigned, at_pickup, picked_up, out_for_delivery
        state = DeliveryStatusState.active(
          orderId: orderId,
          status: delivery.status,
          delivery: delivery,
        );
        Logger.info(
          'Delivery status update for order: $orderId - ${delivery.status.name}',
        );
    }
  }

  /// Show feedback popup when delivery is completed
  void _showFeedbackPopup() {
    // Only show once per delivery and if context is available
    if (_feedbackShown || _context == null || !_context!.mounted) {
      return;
    }

    _feedbackShown = true;

    // Show feedback popup after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (_context != null && _context!.mounted) {
        ReviewBottomSheet.show(
          _context!,
          orderTitle: 'Rate Your Order',
          orderSubtitle: 'Delivered successfully',
        ).then((rating) {
          if (rating != null) {
            Logger.info('User rated order: $rating stars');
            // TODO: Send rating to backend if needed
          }
        });
      }
    });
  }

  /// Start polling for delivery status updates
  void _startPolling(int orderId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      if (mounted) {
        _fetchDeliveryStatus(orderId);
      }
    });
  }

  /// Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Schedule auto-hide after delivery is completed
  void _scheduleAutoHide() {
    Timer(_completedHideDelay, () {
      if (mounted) {
        state = const DeliveryStatusState.hidden();
        Logger.info('Delivery status bar auto-hidden after completion');
      }
    });
  }

  /// Manually refresh delivery status
  Future<void> refresh() async {
    final currentOrderId = state.orderId;
    if (currentOrderId != null) {
      await _fetchDeliveryStatus(currentOrderId);
    }
  }

  /// Hide the delivery status bar
  void hide() {
    _stopPolling();
    state = const DeliveryStatusState.hidden();
  }

  /// Dismiss failed delivery status (user acknowledged)
  void dismissFailure() {
    _stopPolling();
    state = const DeliveryStatusState.hidden();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

/// Global provider for delivery status
final deliveryStatusProvider =
    StateNotifierProvider<DeliveryStatusNotifier, DeliveryStatusState>((ref) {
      final deliveryApi = ref.watch(deliveryApiProvider);
      return DeliveryStatusNotifier(deliveryApi);
    });

/// Selector for checking if delivery bar should be visible
final isDeliveryVisibleProvider = Provider<bool>((ref) {
  final status = ref.watch(deliveryStatusProvider);
  return status.isVisible;
});

/// Selector for current delivery status
final currentDeliveryStatusProvider = Provider<DeliveryApiStatus?>((ref) {
  final status = ref.watch(deliveryStatusProvider);
  return status.currentStatus;
});

/// Selector for delivery entity
final currentDeliveryProvider = Provider<DeliveryEntity?>((ref) {
  final status = ref.watch(deliveryStatusProvider);
  return status.delivery;
});
