import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// Needed for the `DartySocket` extension that provides onConnect/onDisconnect.
import 'package:socket_io_client/socket_io_client.dart';

import '../../features/category/application/providers/inventory_update_notifier.dart';
import '../../features/category/application/providers/price_update_notifier.dart';
import '../utils/logger.dart';
import 'endpoints.dart';
import 'socket_models.dart';
import 'socket_service.dart';

/// Riverpod provider for Socket.IO service
/// Initialize socket connection with base URL
final socketServiceProvider = Provider<SocketService>((ref) {
  logger.i('🔧 Initializing Socket.IO service...');

  final socketService = SocketService();

  // Get the base URL from endpoints (using AppConfig)
  final baseUrl = ApiEndpoints.baseUrl;

  // Connect to Socket.IO server
  socketService.connect(baseUrl);

  // Register Socket.IO event handlers that update Riverpod state
  _registerSocketEventHandlers(socketService, ref);

  // Cleanup when ref is disposed
  ref.onDispose(() {
    logger.i('🧹 Disposing Socket.IO service');
    socketService.dispose();
  });

  return socketService;
});

/// Register all Socket.IO event handlers
void _registerSocketEventHandlers(SocketService socketService, Ref ref) {
  // Listen to socket.io events and update Riverpod state
  logger.i('📡 Setting up event handler callbacks...');

  // Setup price update handler
  socketService.socket.on('price_update', (data) {
    try {
      logger.i('🔥 Processing price update: $data');
      final priceEvent = PriceUpdateEvent.fromJson(
        data as Map<String, dynamic>,
      );
      ref.read(priceUpdateNotifierProvider.notifier).onPriceUpdate(priceEvent);
      logger.i('✅ Price update applied: $priceEvent');
    } catch (e) {
      logger.e('❌ Error processing price update: $e');
    }
  });

  // Setup inventory update handler
  socketService.socket.on('inventory_update', (data) {
    try {
      logger.i('📦 Processing inventory update: $data');
      final inventoryEvent = InventoryUpdateEvent.fromJson(
        data as Map<String, dynamic>,
      );
      ref
          .read(inventoryUpdateNotifierProvider.notifier)
          .onInventoryUpdate(inventoryEvent);
      logger.i('✅ Inventory update applied: $inventoryEvent');
    } catch (e) {
      logger.e('❌ Error processing inventory update: $e');
    }
  });

  // Setup delivery location handler
  socketService.socket.on('delivery_location_update', (data) {
    try {
      logger.i('📍 Processing delivery location: $data');
      final locationEvent = DeliveryLocationEvent.fromJson(
        data as Map<String, dynamic>,
      );
      logger.i('✅ Delivery location update: $locationEvent');
    } catch (e) {
      logger.e('❌ Error processing delivery location: $e');
    }
  });

  logger.i('✅ All event handlers registered');
}

/// Helper provider to join a variant room and listen for updates
final joinVariantRoomProvider = FutureProvider.family<void, int>((
  ref,
  variantId,
) async {
  final socketService = ref.watch(socketServiceProvider);

  // Wait a moment to ensure socket is connected
  await Future.delayed(const Duration(milliseconds: 500));

  socketService.joinVariantRoom(variantId);
});

/// Helper provider to join a delivery room
final joinDeliveryRoomProvider = FutureProvider.family<void, int>((
  ref,
  deliveryId,
) async {
  final socketService = ref.watch(socketServiceProvider);

  await Future.delayed(const Duration(milliseconds: 500));

  socketService.joinDeliveryRoom(deliveryId);
});

/// Provider to get connection status.
///
/// Event-driven rather than polled. The previous implementation was an
/// unbounded `while (true) { await Future.delayed(1s); yield ... }` loop, which
/// emitted every second forever — rebuilding every watcher once a second even
/// when the connection state had not changed.
final socketConnectionStatusProvider = StreamProvider<bool>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final controller = StreamController<bool>();

  var lastValue = socketService.isConnected;
  controller.add(lastValue);

  void emit() {
    final value = socketService.isConnected;
    // Distinct: connect/disconnect handlers can fire more than once.
    if (value == lastValue || controller.isClosed) return;
    lastValue = value;
    controller.add(value);
  }

  socketService.socket
    ..onConnect((_) => emit())
    ..onDisconnect((_) => emit())
    ..onConnectError((_) => emit());

  ref.onDispose(controller.close);

  return controller.stream;
});
