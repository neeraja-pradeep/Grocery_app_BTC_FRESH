// lib/features/home/application/states/delivery_status_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/delivery.dart';

part 'delivery_status_state.freezed.dart';

/// Delivery status state for UI representation
/// Maps backend API status to frontend display states
@freezed
class DeliveryStatusState with _$DeliveryStatusState {
  /// Initial state - bar is hidden (no active delivery)
  const factory DeliveryStatusState.hidden() = DeliveryStatusHidden;

  /// Loading state - fetching delivery status
  const factory DeliveryStatusState.loading({required int orderId}) =
      DeliveryStatusLoading;

  /// Active delivery tracking - order is being processed/delivered
  const factory DeliveryStatusState.active({
    required int orderId,
    required DeliveryApiStatus status,
    required DeliveryEntity delivery,
  }) = DeliveryStatusActive;

  /// Order delivered successfully
  const factory DeliveryStatusState.completed({
    required int orderId,
    required DeliveryEntity delivery,
  }) = DeliveryStatusCompleted;

  /// Delivery failed
  const factory DeliveryStatusState.failed({
    required int orderId,
    required DeliveryEntity delivery,
    String? failureReason,
  }) = DeliveryStatusFailed;

  /// Error fetching delivery status
  const factory DeliveryStatusState.error({
    required int orderId,
    required String message,
  }) = DeliveryStatusError;
}

/// Extension for convenience methods on DeliveryStatusState
extension DeliveryStatusStateExtension on DeliveryStatusState {
  /// Get the order ID if available
  int? get orderId => maybeMap(
    loading: (s) => s.orderId,
    active: (s) => s.orderId,
    completed: (s) => s.orderId,
    failed: (s) => s.orderId,
    error: (s) => s.orderId,
    orElse: () => null,
  );

  /// Check if delivery tracking is active (visible to user)
  bool get isVisible => maybeMap(
    loading: (_) => true,
    active: (_) => true,
    completed: (_) => true,
    failed: (_) => true,
    orElse: () => false,
  );

  /// Get the delivery entity if available
  DeliveryEntity? get delivery => maybeMap(
    active: (s) => s.delivery,
    completed: (s) => s.delivery,
    failed: (s) => s.delivery,
    orElse: () => null,
  );

  /// Get current status for display
  DeliveryApiStatus? get currentStatus => maybeMap(
    active: (s) => s.status,
    completed: (_) => DeliveryApiStatus.delivered,
    failed: (_) => DeliveryApiStatus.failed,
    orElse: () => null,
  );
}
