import 'package:hive_ce/hive.dart';

part 'delivery_tracking.g.dart';

/// Hive model for persisting delivery tracking data across app restarts
///
/// Stores the minimum required data to restore delivery tracking state:
/// - order_id: To fetch latest status from backend
/// - delivery_id: The delivery entity ID
/// - status: Last known delivery status
/// - last_updated: Timestamp of last update
/// - notes: Delivery notes (for failure cases)
/// - proof_of_delivery: Proof URL if available
@HiveType(typeId: 3)
class DeliveryTrackingData {
  @HiveField(0)
  final int orderId;

  @HiveField(1)
  final int deliveryId;

  @HiveField(2)
  final String status; // Store as string for simplicity

  @HiveField(3)
  final DateTime lastUpdated;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final String? proofOfDelivery;

  DeliveryTrackingData({
    required this.orderId,
    required this.deliveryId,
    required this.status,
    required this.lastUpdated,
    this.notes,
    this.proofOfDelivery,
  });

  /// Check if delivery is in an active state (not completed/failed)
  bool get isActive {
    final statusLower = status.toLowerCase();
    return statusLower != 'delivered' && statusLower != 'failed';
  }

  /// Check if delivery is completed
  bool get isCompleted => status.toLowerCase() == 'delivered';

  /// Check if delivery failed
  bool get isFailed => status.toLowerCase() == 'failed';

  @override
  String toString() {
    return 'DeliveryTrackingData('
        'orderId: $orderId, '
        'deliveryId: $deliveryId, '
        'status: $status, '
        'lastUpdated: $lastUpdated'
        ')';
  }
}
