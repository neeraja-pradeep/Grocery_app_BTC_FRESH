// lib/features/home/application/providers/delivery_status_provider.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/delivery_status_state.dart';

/// Provider for managing delivery status on the home screen.
///
/// Features:
/// - Shows status bar after successful order payment
/// - Auto-advances through 4 stages every 10 minutes
/// - Hides when order is completed
/// - UI-only, no backend integration
class DeliveryStatusNotifier extends StateNotifier<DeliveryStatusState> {
  Timer? _autoUpdateTimer;
  static const Duration _updateInterval = Duration(minutes: 10);

  DeliveryStatusNotifier() : super(const DeliveryStatusState.hidden());

  /// Start tracking delivery after successful payment
  void startDeliveryTracking(String orderId) {
    // Cancel any existing timer
    _autoUpdateTimer?.cancel();

    // Set initial state
    state = DeliveryStatusState.active(
      stage: DeliveryStage.orderGettingPacked,
      startedAt: DateTime.now(),
      orderId: orderId,
    );

    // Start auto-update timer
    _startAutoUpdateTimer();
  }

  /// Manually advance to next stage (for testing or manual updates)
  void advanceToNextStage() {
    state.mapOrNull(
      active: (activeState) {
        final nextStage = activeState.stage.nextStage;
        if (nextStage != null) {
          if (nextStage == DeliveryStage.orderCompleted) {
            // Move to completed and hide after a brief delay
            state = DeliveryStatusState.completed(orderId: activeState.orderId);
            _autoUpdateTimer?.cancel();

            // Auto-hide after 5 seconds
            Timer(const Duration(seconds: 5), () {
              if (mounted) {
                state = const DeliveryStatusState.hidden();
              }
            });
          } else {
            state = DeliveryStatusState.active(
              stage: nextStage,
              startedAt: activeState.startedAt,
              orderId: activeState.orderId,
            );
          }
        }
      },
    );
  }

  /// Set a specific stage (for manual control or simulation)
  void setStage(DeliveryStage stage, String orderId) {
    if (stage == DeliveryStage.orderCompleted) {
      state = DeliveryStatusState.completed(orderId: orderId);
      _autoUpdateTimer?.cancel();
    } else {
      state = DeliveryStatusState.active(
        stage: stage,
        startedAt: DateTime.now(),
        orderId: orderId,
      );
      _startAutoUpdateTimer();
    }
  }

  /// Hide the delivery status bar
  void hide() {
    _autoUpdateTimer?.cancel();
    state = const DeliveryStatusState.hidden();
  }

  /// Check if delivery tracking is active
  bool get isActive => state.map(
    hidden: (_) => false,
    active: (_) => true,
    completed: (_) => true,
  );

  void _startAutoUpdateTimer() {
    _autoUpdateTimer?.cancel();
    _autoUpdateTimer = Timer.periodic(_updateInterval, (_) {
      advanceToNextStage();
    });
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel();
    super.dispose();
  }
}

/// Global provider for delivery status
final deliveryStatusProvider =
    StateNotifierProvider<DeliveryStatusNotifier, DeliveryStatusState>((ref) {
      return DeliveryStatusNotifier();
    });

/// Selector for checking if delivery is active (for conditional rendering)
final isDeliveryActiveProvider = Provider<bool>((ref) {
  final status = ref.watch(deliveryStatusProvider);
  return status.map(
    hidden: (_) => false,
    active: (_) => true,
    completed: (_) => true,
  );
});

/// Selector for current delivery stage
final currentDeliveryStageProvider = Provider<DeliveryStage?>((ref) {
  final status = ref.watch(deliveryStatusProvider);
  return status.mapOrNull(active: (s) => s.stage);
});
