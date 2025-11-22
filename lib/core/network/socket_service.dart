// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../utils/logger.dart';

/// Socket.IO service for real-time updates
/// Handles connections to Django Socket.IO server for:
/// - Price updates
/// - Inventory updates
/// - Delivery location tracking
class SocketService {
  late IO.Socket socket;
  bool _isConnected = false;
  bool _listenersRegistered = false;
  final List<int> _joinedVariantRooms = [];
  final List<int> _joinedDeliveryRooms = [];

  /// Initialize socket connection
  /// Base URL should be your Django ASGI server URL
  /// Example: 'http://156.67.104.149:8080' or 'https://your-domain.com'
  void connect(String baseUrl) {
    logger.i('🔌 Attempting to connect to Socket.IO at: $baseUrl');

    try {
      socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket']) // WebSocket only for reliability
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(5)
            .build(),
      );

      _setupConnectionListeners();
      _setupEventListeners(); // Register all event listeners ONCE

      logger.i('✅ Socket.IO initialization complete');
    } catch (e) {
      logger.e('❌ Socket.IO Connection Error: $e');
    }
  }

  /// Setup core connection listeners
  void _setupConnectionListeners() {
    socket.onConnect((_) {
      _isConnected = true;
      logger.i('🟢 Socket.IO Connected! ID: ${socket.id}');

      // Rejoin all rooms after reconnection
      _rejoinAllRooms();

      // Listen for server welcome message
      socket.on('connection_established', (data) {
        logger.i('✅ Server Welcome: $data');
      });
    });

    socket.onConnectError((error) {
      logger.e('❌ Socket.IO Connection Error: $error');
      _isConnected = false;
    });

    socket.onDisconnect((_) {
      _isConnected = false;
      logger.w('🔴 Socket.IO Disconnected');
    });

    socket.onError((error) {
      logger.e('⚠️ Socket.IO Error: $error');
    });

    socket.on('error', (data) {
      logger.e('⚠️ Server Error: $data');
    });

    socket.on('connect_error', (data) {
      logger.e('⚠️ Connect Error: $data');
    });
  }

  /// Setup all event listeners ONCE during initialization
  void _setupEventListeners() {
    if (_listenersRegistered) {
      logger.i('ℹ️ Event listeners already registered');
      return;
    }

    logger.i('📋 Registering event listeners...');

    // Listen for price updates
    socket.on('price_update', (data) {
      logger.i('🔥 Price Update Received: $data');
    });

    // Listen for inventory updates
    socket.on('inventory_update', (data) {
      logger.i('📦 Inventory Update Received: $data');
    });

    // Listen for delivery location updates
    socket.on('delivery_location_update', (data) {
      logger.i('📍 Delivery Location Update: $data');
    });

    // Listen for room join confirmations
    socket.on('room_joined', (data) {
      logger.i('✅ Room Joined: $data');
    });

    socket.on('delivery_room_joined', (data) {
      logger.i('✅ Delivery Room Joined: $data');
    });

    _listenersRegistered = true;
    logger.i('✅ All event listeners registered');
  }

  /// Join a product variant room for receiving price updates
  /// variant_id: The variant ID to listen for updates
  void joinVariantRoom(int variantId) {
    if (!_isConnected) {
      logger.w('⚠️ Socket not connected. Cannot join variant room $variantId');
      return;
    }

    if (_joinedVariantRooms.contains(variantId)) {
      logger.d('ℹ️ Already joined variant room $variantId');
      return;
    }

    socket.emit('join_product_room', {'variant_id': variantId});

    _joinedVariantRooms.add(variantId);
    logger.i('📍 Requested to join variant room: $variantId');
  }

  /// Leave a product variant room
  void leaveVariantRoom(int variantId) {
    if (!_isConnected) return;

    socket.emit('leave_product_room', {'variant_id': variantId});

    _joinedVariantRooms.remove(variantId);
    logger.i('📍 Left variant room: $variantId');
  }

  /// Join a delivery room for tracking
  void joinDeliveryRoom(int deliveryId) {
    if (!_isConnected) {
      logger.w(
        '⚠️ Socket not connected. Cannot join delivery room $deliveryId',
      );
      return;
    }

    if (_joinedDeliveryRooms.contains(deliveryId)) {
      logger.d('ℹ️ Already joined delivery room $deliveryId');
      return;
    }

    socket.emit('join_delivery_room', {'delivery_id': deliveryId});

    _joinedDeliveryRooms.add(deliveryId);
    logger.i('📍 Requested to join delivery room: $deliveryId');
  }

  /// Leave a delivery room
  void leaveDeliveryRoom(int deliveryId) {
    if (!_isConnected) return;

    socket.emit('leave_delivery_room', {'delivery_id': deliveryId});

    _joinedDeliveryRooms.remove(deliveryId);
    logger.i('📍 Left delivery room: $deliveryId');
  }

  /// Rejoin all previously joined rooms after reconnection
  void _rejoinAllRooms() {
    for (final variantId in _joinedVariantRooms) {
      socket.emit('join_product_room', {'variant_id': variantId});
      logger.i('🔄 Rejoined variant room: $variantId');
    }

    for (final deliveryId in _joinedDeliveryRooms) {
      socket.emit('join_delivery_room', {'delivery_id': deliveryId});
      logger.i('🔄 Rejoined delivery room: $deliveryId');
    }
  }

  /// Get connection status
  bool get isConnected => _isConnected;

  /// Get list of joined variant rooms
  List<int> get joinedVariantRooms => List.unmodifiable(_joinedVariantRooms);

  /// Get list of joined delivery rooms
  List<int> get joinedDeliveryRooms => List.unmodifiable(_joinedDeliveryRooms);

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_isConnected) {
      socket.disconnect();
      _isConnected = false;
      _joinedVariantRooms.clear();
      _joinedDeliveryRooms.clear();
      logger.i('🔴 Socket.IO Disconnected');
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
  }
}
