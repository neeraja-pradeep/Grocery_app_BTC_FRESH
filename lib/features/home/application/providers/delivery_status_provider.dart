// lib/features/home/application/providers/delivery_status_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../category/presentation/components/widgets/review_bottom_sheet.dart';
import '../../../orders/infrastructure/data_sources/orders_api.dart';
import '../../domain/entities/delivery.dart';
import '../../infrastructure/data_sources/local/delivery_storage_service.dart';
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
/// - Submits order rating to backend after user rates
class DeliveryStatusNotifier extends StateNotifier<DeliveryStatusState> {
  final DeliveryApi _deliveryApi;
  final OrdersApi _ordersApi;
  final DeliveryStorageService _storageService;
  Timer? _pollingTimer;
  Timer? _autoHideTimer;
  BuildContext? _context;
  bool _feedbackShown = false;
  static const Duration _pollingInterval = Duration(seconds: 30);
  static const Duration _completedHideDelay = Duration(seconds: 10);

  DeliveryStatusNotifier(
    this._deliveryApi,
    this._ordersApi,
    this._storageService,
  ) : super(const DeliveryStatusState.hidden());

  /// Set the BuildContext for showing feedback popup
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Restore delivery tracking from Hive storage
  ///
  /// Called on app startup to restore active delivery state
  Future<void> restoreDeliveryFromStorage() async {
    final savedDelivery = _storageService.loadDeliveryTracking();

    if (savedDelivery == null || !savedDelivery.isActive) {
      Logger.info('No active delivery to restore');
      return;
    }

    Logger.info(
      'Restoring delivery tracking for order: ${savedDelivery.orderId}',
    );

    // Start tracking the saved delivery
    startDeliveryTracking(savedDelivery.orderId);
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
        // Clear saved tracking data (delivery is complete)
        _storageService.clearDeliveryTracking();
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
        // Clear saved tracking data (delivery failed)
        _storageService.clearDeliveryTracking();
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
        // Save tracking data to Hive for persistence
        _storageService.saveDeliveryTracking(delivery);
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
    final currentOrderId = state.orderId;

    // Cancel auto-hide timer while showing rating popup
    _autoHideTimer?.cancel();

    // Show feedback popup after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (_context != null && _context!.mounted && currentOrderId != null) {
        ReviewBottomSheet.show(
          _context!,
          orderTitle: 'Rate Your Order',
          orderSubtitle: 'Delivered successfully',
        ).then((rating) async {
          if (rating != null && rating > 0) {
            Logger.info('User rated order: $rating stars');

            // Submit rating to backend
            await _submitRating(currentOrderId, rating);
          }

          // Reschedule auto-hide after rating sheet closes
          _scheduleAutoHide();
        });
      }
    });
  }

  /// Submit order rating to backend
  Future<void> _submitRating(int orderId, int stars) async {
    try {
      await _ordersApi.submitOrderRating(orderId: orderId, stars: stars);

      Logger.info(
        'Order rating submitted successfully: $stars stars for order $orderId',
      );

      // Show success message
      if (_context != null && _context!.mounted) {
        AppSnackbar.success(_context!, 'Thank you for your rating!');
      }
    } catch (e) {
      Logger.error('Failed to submit order rating', error: e);

      // Show error message to user
      if (_context != null && _context!.mounted) {
        AppSnackbar.error(
          _context!,
          'Failed to submit rating. Please try again later.',
        );
      }
    }
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
    // Cancel any existing auto-hide timer
    _autoHideTimer?.cancel();

    _autoHideTimer = Timer(_completedHideDelay, () {
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
    _autoHideTimer?.cancel();
    _storageService.clearDeliveryTracking();
    state = const DeliveryStatusState.hidden();
  }

  /// Dismiss failed delivery status (user acknowledged)
  void dismissFailure() {
    _stopPolling();
    _autoHideTimer?.cancel();
    _storageService.clearDeliveryTracking();
    state = const DeliveryStatusState.hidden();
  }

  @override
  void dispose() {
    _stopPolling();
    _autoHideTimer?.cancel();
    super.dispose();
  }
}

/// Global provider for delivery status
final deliveryStatusProvider =
    StateNotifierProvider<DeliveryStatusNotifier, DeliveryStatusState>((ref) {
      final deliveryApi = ref.watch(deliveryApiProvider);
      final ordersApi = ref.watch(ordersApiProvider);
      final storageService = ref.watch(deliveryStorageServiceProvider);
      return DeliveryStatusNotifier(deliveryApi, ordersApi, storageService);
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
