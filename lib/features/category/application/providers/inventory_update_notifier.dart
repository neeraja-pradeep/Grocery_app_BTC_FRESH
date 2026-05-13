import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/socket_models.dart';

class InventoryUpdateState {
  const InventoryUpdateState({this.updates = const {}});

  final Map<int, InventoryUpdateEvent> updates;

  InventoryUpdateState copyWith({Map<int, InventoryUpdateEvent>? updates}) {
    return InventoryUpdateState(updates: updates ?? this.updates);
  }

  InventoryUpdateEvent? getUpdate(int variantId) => updates[variantId];

  bool hasUpdate(int variantId) => updates.containsKey(variantId);
}

class InventoryUpdateNotifier extends Notifier<InventoryUpdateState> {
  @override
  InventoryUpdateState build() => const InventoryUpdateState();

  void onInventoryUpdate(InventoryUpdateEvent event) {
    final updatedMap = Map<int, InventoryUpdateEvent>.from(state.updates);
    updatedMap[event.variantId] = event;
    state = state.copyWith(updates: updatedMap);
  }

  void clearUpdate(int variantId) {
    final updatedMap = Map<int, InventoryUpdateEvent>.from(state.updates);
    updatedMap.remove(variantId);
    state = state.copyWith(updates: updatedMap);
  }

  void clearAll() {
    state = const InventoryUpdateState();
  }
}

final inventoryUpdateNotifierProvider =
    NotifierProvider<InventoryUpdateNotifier, InventoryUpdateState>(
      InventoryUpdateNotifier.new,
    );
