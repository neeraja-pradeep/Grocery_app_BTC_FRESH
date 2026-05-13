import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/socket_provider.dart';
import '../../../../core/network/socket_service.dart';
import 'inventory_update_notifier.dart';
import 'price_update_notifier.dart';

/// Provider for the shared SocketRoomManager instance.
final socketRoomManagerProvider = Provider((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return _SocketRoomManager(socketService, ref);
});

/// Joins variant Socket.IO rooms and auto-cleans on dispose.
final joinVariantRoomsProvider = FutureProvider.family<void, List<int>>((
  ref,
  variantIds,
) async {
  final manager = ref.watch(socketRoomManagerProvider);
  await Future.microtask(() => manager.joinVariantRooms(variantIds));
  ref.onDispose(() => manager.leaveVariantRooms(variantIds));
});

/// Real-time price for a variant (null if no update received yet).
final variantPriceProvider = Provider.family<double?, int>((ref, variantId) {
  final priceEvent =
      ref.watch(priceUpdateNotifierProvider).getUpdate(variantId);
  return priceEvent?.newPrice;
});

/// Real-time quantity for a variant (null if no update received yet).
final variantQuantityProvider = Provider.family<int?, int>((ref, variantId) {
  final inventoryEvent =
      ref.watch(inventoryUpdateNotifierProvider).getUpdate(variantId);
  return inventoryEvent?.currentQuantity;
});

/// Real-time in-stock status for a variant.
final variantInStockProvider = Provider.family<bool, int>((ref, variantId) {
  final quantity = ref.watch(variantQuantityProvider(variantId));
  return (quantity ?? 0) > 0;
});

// ---------------------------------------------------------------------------
// Internal helper — not exported
// ---------------------------------------------------------------------------

class _SocketRoomManager {
  _SocketRoomManager(this._socketService, this._ref);

  final SocketService _socketService;
  final Ref _ref;
  final List<int> _managedRooms = [];

  void joinVariantRooms(List<int> variantIds) {
    for (final id in variantIds) {
      if (!_managedRooms.contains(id)) {
        _socketService.joinVariantRoom(id);
        _managedRooms.add(id);
      }
    }
  }

  void leaveVariantRooms(List<int> variantIds) {
    for (final id in variantIds) {
      if (_managedRooms.contains(id)) {
        _socketService.leaveVariantRoom(id);
        _managedRooms.remove(id);
      }
    }
  }

  void cleanup() => leaveVariantRooms(List.from(_managedRooms));
}
