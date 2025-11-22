import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/socket_models.dart';

/// State for price updates
/// Maps variant_id to PriceUpdateEvent
class PriceUpdateState {
  const PriceUpdateState({this.updates = const {}});

  final Map<int, PriceUpdateEvent> updates;

  PriceUpdateState copyWith({Map<int, PriceUpdateEvent>? updates}) {
    return PriceUpdateState(updates: updates ?? this.updates);
  }

  /// Get price update for a specific variant
  PriceUpdateEvent? getUpdate(int variantId) => updates[variantId];

  /// Check if variant has a price update
  bool hasUpdate(int variantId) => updates.containsKey(variantId);
}

/// Notifier for managing real-time price updates
class PriceUpdateNotifier extends StateNotifier<PriceUpdateState> {
  PriceUpdateNotifier() : super(const PriceUpdateState());

  /// Handle incoming price update from Socket.IO
  void onPriceUpdate(PriceUpdateEvent event) {
    final updatedMap = Map<int, PriceUpdateEvent>.from(state.updates);
    updatedMap[event.variantId] = event;
    state = state.copyWith(updates: updatedMap);
  }

  /// Clear price update for a variant
  void clearUpdate(int variantId) {
    final updatedMap = Map<int, PriceUpdateEvent>.from(state.updates);
    updatedMap.remove(variantId);
    state = state.copyWith(updates: updatedMap);
  }

  /// Clear all price updates
  void clearAll() {
    state = const PriceUpdateState();
  }
}

/// Riverpod provider for price updates
final priceUpdateNotifierProvider =
    StateNotifierProvider<PriceUpdateNotifier, PriceUpdateState>((ref) {
      return PriceUpdateNotifier();
    });
