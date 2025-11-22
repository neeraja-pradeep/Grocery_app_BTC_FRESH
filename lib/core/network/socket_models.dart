/// Price update event from Socket.IO server
class PriceUpdateEvent {
  PriceUpdateEvent({
    required this.variantId,
    required this.newPrice,
    this.oldPrice,
    this.discountedPrice,
  });

  final int variantId;
  final double newPrice;
  final double? oldPrice;
  final double? discountedPrice;

  /// Create from Socket.IO event data
  factory PriceUpdateEvent.fromJson(Map<String, dynamic> json) {
    return PriceUpdateEvent(
      variantId: _parseInt(json['variant_id']),
      newPrice: _parseDouble(json['new_price']),
      oldPrice: _parseDouble(json['old_price']),
      discountedPrice: _parseDouble(json['discounted_price']),
    );
  }

  @override
  String toString() =>
      'PriceUpdateEvent(variantId: $variantId, newPrice: $newPrice, oldPrice: $oldPrice, discountedPrice: $discountedPrice)';
}

/// Inventory/Stock update event from Socket.IO server
class InventoryUpdateEvent {
  InventoryUpdateEvent({
    required this.variantId,
    required this.currentQuantity,
    this.previousQuantity,
    this.stockUnit,
    this.warehouseId,
  });

  final int variantId;
  final int currentQuantity;
  final int? previousQuantity;
  final String? stockUnit;
  final int? warehouseId;

  /// Create from Socket.IO event data
  factory InventoryUpdateEvent.fromJson(Map<String, dynamic> json) {
    return InventoryUpdateEvent(
      variantId: _parseInt(json['variant_id']),
      currentQuantity: _parseInt(json['current_quantity']),
      previousQuantity: _parseInt(json['previous_quantity']),
      stockUnit: json['current_stock_unit']?.toString(),
      warehouseId: _parseInt(json['warehouse_id']),
    );
  }

  @override
  String toString() =>
      'InventoryUpdateEvent(variantId: $variantId, currentQuantity: $currentQuantity, stockUnit: $stockUnit)';
}

/// Delivery location update event from Socket.IO server
class DeliveryLocationEvent {
  DeliveryLocationEvent({
    required this.deliveryId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.timestamp,
  });

  final int deliveryId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? timestamp;

  /// Create from Socket.IO event data
  factory DeliveryLocationEvent.fromJson(Map<String, dynamic> json) {
    return DeliveryLocationEvent(
      deliveryId: _parseInt(json['delivery_id']),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      accuracy: _parseDouble(json['accuracy']),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }

  @override
  String toString() =>
      'DeliveryLocationEvent(deliveryId: $deliveryId, lat: $latitude, lng: $longitude)';
}

/// Room joined confirmation event
class RoomJoinedEvent {
  RoomJoinedEvent({required this.roomName, this.message});

  final String roomName;
  final String? message;

  factory RoomJoinedEvent.fromJson(Map<String, dynamic> json) {
    return RoomJoinedEvent(
      roomName: json['room']?.toString() ?? '',
      message: json['message']?.toString(),
    );
  }

  @override
  String toString() => 'RoomJoinedEvent(room: $roomName, msg: $message)';
}

/// Helper function to safely parse integers
int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

/// Helper function to safely parse doubles
double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
