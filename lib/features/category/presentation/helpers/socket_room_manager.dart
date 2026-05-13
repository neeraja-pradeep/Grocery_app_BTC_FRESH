import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/socket_provider.dart';
import '../../../../core/utils/logger.dart';

/// Helper for managing Socket.IO room subscriptions.
/// Automatically joins/leaves rooms and handles lifecycle.
///
/// Riverpod providers that use this class live in
/// `application/providers/socket_providers.dart`.
class SocketRoomManager {
  final Ref ref;
  final List<int> _managedRooms = [];

  SocketRoomManager(this.ref);

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

  void cleanup() {
    leaveVariantRooms(List.from(_managedRooms));
    logger.i('🧹 Cleaned up all managed rooms');
  }

  List<int> getManagedRooms() => List.unmodifiable(_managedRooms);
}
