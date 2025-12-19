import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/storage/hive/adapters/delivery_tracking.dart';
import '../../../../../core/storage/hive/boxes.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/entities/delivery.dart';

/// Service for persisting delivery tracking data using Hive
///
/// This service handles saving and loading delivery tracking state
/// so that the DeliveryStatusBar persists across app restarts.
class DeliveryStorageService {
  static const String _activeDeliveryKey = 'active_delivery';

  /// Save delivery tracking data to Hive
  ///
  /// This is called when:
  /// - Delivery tracking starts (after payment)
  /// - Delivery status is updated from API
  /// - Any delivery state changes
  Future<void> saveDeliveryTracking(DeliveryEntity delivery) async {
    try {
      // Don't save if delivery is completed or failed
      if (delivery.status.isCompleted || delivery.status.isFailed) {
        Logger.info('Delivery is completed/failed, clearing stored data');
        await clearDeliveryTracking();
        return;
      }

      final trackingData = DeliveryTrackingData(
        orderId: delivery.order,
        deliveryId: delivery.id,
        status: delivery.status.name,
        lastUpdated: DateTime.now(),
        notes: delivery.notes,
        proofOfDelivery: delivery.proofOfDelivery,
      );

      await Boxes.deliveryTrackingBox.put(_activeDeliveryKey, trackingData);
      Logger.info('Saved delivery tracking: $trackingData');
    } catch (e) {
      Logger.error('Error saving delivery tracking', error: e);
    }
  }

  /// Load saved delivery tracking data from Hive
  ///
  /// Returns null if:
  /// - No delivery was saved
  /// - Saved delivery is completed/failed
  /// - Error loading data
  DeliveryTrackingData? loadDeliveryTracking() {
    try {
      final trackingData =
          Boxes.deliveryTrackingBox.get(_activeDeliveryKey)
              as DeliveryTrackingData?;

      if (trackingData == null) {
        Logger.info('No saved delivery tracking found');
        return null;
      }

      // Don't return completed/failed deliveries
      if (!trackingData.isActive) {
        Logger.info(
          'Saved delivery is not active (status: ${trackingData.status}), clearing',
        );
        clearDeliveryTracking();
        return null;
      }

      Logger.info('Loaded delivery tracking: $trackingData');
      return trackingData;
    } catch (e) {
      Logger.error('Error loading delivery tracking', error: e);
      return null;
    }
  }

  /// Clear saved delivery tracking data
  ///
  /// Called when:
  /// - Delivery is completed
  /// - Delivery is failed
  /// - User dismisses delivery status
  Future<void> clearDeliveryTracking() async {
    try {
      await Boxes.deliveryTrackingBox.delete(_activeDeliveryKey);
      Logger.info('Cleared delivery tracking data');
    } catch (e) {
      Logger.error('Error clearing delivery tracking', error: e);
    }
  }

  /// Check if there's an active delivery saved
  bool hasActiveDelivery() {
    final trackingData = loadDeliveryTracking();
    return trackingData != null && trackingData.isActive;
  }
}

/// Provider for DeliveryStorageService
final deliveryStorageServiceProvider = Provider<DeliveryStorageService>((ref) {
  return DeliveryStorageService();
});
