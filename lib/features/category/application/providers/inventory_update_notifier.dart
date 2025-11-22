import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/socket_models.dart';

/// State for inventory updates
/// Maps variant_id to InventoryUpdateEvent
class InventoryUpdateState {
  const InventoryUpdateState({this.updates = const {}});

  final Map<int, InventoryUpdateEvent> updates;

  InventoryUpdateState copyWith({Map<int, InventoryUpdateEvent>? updates}) {
    return InventoryUpdateState(updates: updates ?? this.updates);
  }

  /// Get inventory update for a specific variant
  InventoryUpdateEvent? getUpdate(int variantId) => updates[variantId];

  /// Check if variant has an inventory update
  bool hasUpdate(int variantId) => updates.containsKey(variantId);
}

/// Notifier for managing real-time inventory updates
class InventoryUpdateNotifier extends StateNotifier<InventoryUpdateState> {
  InventoryUpdateNotifier() : super(const InventoryUpdateState());

  /// Handle incoming inventory update from Socket.IO
  void onInventoryUpdate(InventoryUpdateEvent event) {
    final updatedMap = Map<int, InventoryUpdateEvent>.from(state.updates);
    updatedMap[event.variantId] = event;
    state = state.copyWith(updates: updatedMap);
  }

  /// Clear inventory update for a variant
  void clearUpdate(int variantId) {
    final updatedMap = Map<int, InventoryUpdateEvent>.from(state.updates);
    updatedMap.remove(variantId);
    state = state.copyWith(updates: updatedMap);
  }

  /// Clear all inventory updates
  void clearAll() {
    state = const InventoryUpdateState();
  }
}

/// Riverpod provider for inventory updates
final inventoryUpdateNotifierProvider =
    StateNotifierProvider<InventoryUpdateNotifier, InventoryUpdateState>((ref) {
      return InventoryUpdateNotifier();
    });
