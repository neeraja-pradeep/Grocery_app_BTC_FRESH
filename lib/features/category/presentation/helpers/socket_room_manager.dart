import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/socket_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../application/providers/price_update_notifier.dart';
import '../../application/providers/inventory_update_notifier.dart';

/// Helper for managing Socket.IO room subscriptions
/// Automatically joins/leaves rooms and handles lifecycle
class SocketRoomManager {
  final Ref ref;
  final List<int> _managedRooms = [];

  SocketRoomManager(this.ref);

  /// Join room(s) for variant IDs
  void joinVariantRooms(List<int> variantIds) {
    final socketService = ref.read(socketServiceProvider);

    for (final variantId in variantIds) {
      if (!_managedRooms.contains(variantId)) {
        socketService.joinVariantRoom(variantId);
        _managedRooms.add(variantId);
        logger.i('➕ Joined room for variant: $variantId');
      }
    }
  }

  /// Leave room(s) for variant IDs
  void leaveVariantRooms(List<int> variantIds) {
    final socketService = ref.read(socketServiceProvider);

    for (final variantId in variantIds) {
      if (_managedRooms.contains(variantId)) {
        socketService.leaveVariantRoom(variantId);
        _managedRooms.remove(variantId);
        logger.i('➖ Left room for variant: $variantId');
      }
    }
  }

  /// Cleanup all managed rooms
  void cleanup() {
    leaveVariantRooms(List.from(_managedRooms));
    logger.i('🧹 Cleaned up all managed rooms');
  }

  /// Get all managed room IDs
  List<int> getManagedRooms() => List.unmodifiable(_managedRooms);
}

/// Riverpod hook-style provider for socket room management
final socketRoomManagerProvider = Provider((ref) {
  final manager = SocketRoomManager(ref);

  // Cleanup on provider dispose
  ref.onDispose(() {
    manager.cleanup();
  });

  return manager;
});

/// Family provider to join a list of variant rooms
final joinVariantRoomsProvider = FutureProvider.family<void, List<int>>((
  ref,
  variantIds,
) async {
  final manager = ref.watch(socketRoomManagerProvider);

  // Use microtask to avoid joining during build
  await Future.microtask(() {
    manager.joinVariantRooms(variantIds);
  });
});

/// Provider to get the current price of a variant with real-time updates
final variantPriceProvider = Provider.family<double?, int>((ref, variantId) {
  final priceUpdates = ref.watch(priceUpdateNotifierProvider);

  // Return real-time price if available
  final priceEvent = priceUpdates.getUpdate(variantId);
  return priceEvent?.newPrice;
});

/// Provider to get the current quantity of a variant with real-time updates
final variantQuantityProvider = Provider.family<int?, int>((ref, variantId) {
  final inventoryUpdates = ref.watch(inventoryUpdateNotifierProvider);

  // Return real-time quantity if available
  final inventoryEvent = inventoryUpdates.getUpdate(variantId);
  return inventoryEvent?.currentQuantity;
});

/// Provider to check if a variant is in stock (with real-time updates)
final variantInStockProvider = Provider.family<bool, int>((ref, variantId) {
  final quantity = ref.watch(variantQuantityProvider(variantId));
  return (quantity ?? 0) > 0;
});

// Import necessary notifiers at the top of this file:
// import '../providers/price_update_notifier.dart';
// import '../providers/inventory_update_notifier.dart';
