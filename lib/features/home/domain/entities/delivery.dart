import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery.freezed.dart';

/// Delivery status values from backend API
enum DeliveryApiStatus { atPickup, pickedUp, outForDelivery, delivered, failed }

/// Extension to get display text and UI properties for each status
extension DeliveryApiStatusExtension on DeliveryApiStatus {
  String get displayText {
    switch (this) {
      case DeliveryApiStatus.atPickup:
        return 'Order is getting packed!';
      case DeliveryApiStatus.pickedUp:
        return 'Order is packed!';
      case DeliveryApiStatus.outForDelivery:
        return 'Out for delivery';
      case DeliveryApiStatus.delivered:
        return 'Order delivered';
      case DeliveryApiStatus.failed:
        return 'Delivery failed';
    }
  }

  /// Dummy estimated time for UI display (10 min intervals as per requirement)
  String get estimatedTime {
    switch (this) {
      case DeliveryApiStatus.atPickup:
        return '30 mins';
      case DeliveryApiStatus.pickedUp:
        return '20 mins';
      case DeliveryApiStatus.outForDelivery:
        return '10 mins';
      case DeliveryApiStatus.delivered:
        return 'Delivered';
      case DeliveryApiStatus.failed:
        return 'Failed';
    }
  }

  bool get isCompleted => this == DeliveryApiStatus.delivered;
  bool get isFailed => this == DeliveryApiStatus.failed;
  bool get isActive => !isCompleted && !isFailed;

  /// Convert from API string to enum
  static DeliveryApiStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'at_pickup':
        return DeliveryApiStatus.atPickup;
      case 'picked_up':
        return DeliveryApiStatus.pickedUp;
      case 'out_for_delivery':
        return DeliveryApiStatus.outForDelivery;
      case 'delivered':
        return DeliveryApiStatus.delivered;
      case 'failed':
        return DeliveryApiStatus.failed;
      default:
        return DeliveryApiStatus.atPickup;
    }
  }
}

/// Delivery entity representing the backend API response
@freezed
class DeliveryEntity with _$DeliveryEntity {
  const DeliveryEntity._();

  const factory DeliveryEntity({
    required int id,
    required int order,
    required DeliveryApiStatus status,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? proofOfDelivery,
    String? notes,
  }) = _DeliveryEntity;

  /// Custom fromJson to handle snake_case API response
  factory DeliveryEntity.fromJson(Map<String, dynamic> json) {
    return DeliveryEntity(
      id: json['id'] as int,
      order: json['order'] as int,
      status: DeliveryApiStatusExtension.fromString(json['status'] as String),
      assignedAt: json['assigned_at'] != null
          ? DateTime.tryParse(json['assigned_at'] as String)
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.tryParse(json['picked_up_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
      proofOfDelivery: json['proof_of_delivery'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// Check if delivery has failure notes
  bool get hasFailureNotes =>
      status.isFailed && notes != null && notes!.isNotEmpty;

  /// Check if delivery has success notes/proof
  bool get hasSuccessInfo =>
      status.isCompleted &&
      (proofOfDelivery != null || (notes != null && notes!.isNotEmpty));
}
