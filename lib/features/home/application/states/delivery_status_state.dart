// lib/features/home/application/states/delivery_status_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_status_state.freezed.dart';

/// Delivery status enum representing the 4 stages
enum DeliveryStage {
  orderGettingPacked,
  orderPacked,
  outForDelivery,
  orderCompleted,
}

extension DeliveryStageExtension on DeliveryStage {
  String get displayText {
    switch (this) {
      case DeliveryStage.orderGettingPacked:
        return 'Order is getting packed!';
      case DeliveryStage.orderPacked:
        return 'Order is packed!';
      case DeliveryStage.outForDelivery:
        return 'Out for delivery';
      case DeliveryStage.orderCompleted:
        return 'Order completed';
    }
  }

  String get estimatedTime {
    switch (this) {
      case DeliveryStage.orderGettingPacked:
        return '30 mins';
      case DeliveryStage.orderPacked:
        return '20 mins';
      case DeliveryStage.outForDelivery:
        return '10 mins';
      case DeliveryStage.orderCompleted:
        return 'Delivered';
    }
  }

  /// Get the next stage in progression
  DeliveryStage? get nextStage {
    switch (this) {
      case DeliveryStage.orderGettingPacked:
        return DeliveryStage.orderPacked;
      case DeliveryStage.orderPacked:
        return DeliveryStage.outForDelivery;
      case DeliveryStage.outForDelivery:
        return DeliveryStage.orderCompleted;
      case DeliveryStage.orderCompleted:
        return null; // No next stage
    }
  }
}

@freezed
class DeliveryStatusState with _$DeliveryStatusState {
  const factory DeliveryStatusState.hidden() = _Hidden;

  const factory DeliveryStatusState.active({
    required DeliveryStage stage,
    required DateTime startedAt,
    required String orderId,
  }) = _Active;

  const factory DeliveryStatusState.completed({required String orderId}) =
      _Completed;
}
