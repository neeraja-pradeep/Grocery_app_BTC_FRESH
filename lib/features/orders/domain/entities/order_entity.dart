/// Order rating entity
class OrderRatingEntity {
  final int id;
  final int stars;
  final String? body;

  const OrderRatingEntity({required this.id, required this.stars, this.body});

  factory OrderRatingEntity.fromJson(Map<String, dynamic> json) {
    return OrderRatingEntity(
      id: json['id'] as int,
      stars: json['stars'] as int? ?? 0,
      body: json['body'] as String?,
    );
  }
}

/// Order entity representing a user's order
class OrderEntity {
  final int id;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderLineEntity> orderLines;
  final OrderAddressEntity? deliveryAddress;
  final int orderlinesCount;
  final OrderRatingEntity? rating;

  const OrderEntity({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.updatedAt,
    this.orderLines = const [],
    this.deliveryAddress,
    this.orderlinesCount = 0,
    this.rating,
  });

  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    // Try shipping_address first, fallback to delivery_address
    final addressJson = json['shipping_address'] ?? json['delivery_address'];

    // Parse order lines if present
    final orderLinesList =
        (json['order_lines'] as List?)
            ?.map((e) => OrderLineEntity.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Get orderlines count - prefer the count field, fallback to actual list length
    final orderlinesCount =
        json['orderlines_count'] as int? ?? orderLinesList.length;

    // Parse rating if available
    // Note: The order list endpoint doesn't include ratings by default.
    // Ratings are fetched separately via /api/order/v1/{order_id}/ratings/
    final ratingJson = json['rating'];
    OrderRatingEntity? rating;
    if (ratingJson != null) {
      if (ratingJson is Map<String, dynamic>) {
        rating = OrderRatingEntity.fromJson(ratingJson);
      } else if (ratingJson is List && ratingJson.isNotEmpty) {
        // If rating is returned as a list, take the first item
        rating = OrderRatingEntity.fromJson(
          ratingJson[0] as Map<String, dynamic>,
        );
      }
    }

    return OrderEntity(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'pending',
      // API returns 'total', fallback to 'total_amount'
      totalAmount: _parseDouble(json['total'] ?? json['total_amount']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      orderLines: orderLinesList,
      deliveryAddress: addressJson != null
          ? OrderAddressEntity.fromJson(addressJson as Map<String, dynamic>)
          : null,
      orderlinesCount: orderlinesCount,
      rating: rating,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool get isActive {
    final s = status.toLowerCase();
    return s == 'active' ||
        s == 'shipped' ||
        s == 'processing' ||
        s == 'out_for_delivery';
  }

  bool get isPending => status.toLowerCase() == 'pending';

  bool get isCompleted {
    final s = status.toLowerCase();
    return s == 'completed' || s == 'delivered';
  }

  bool get isCancelled => status.toLowerCase() == 'cancelled';
}

/// Order line item entity
class OrderLineEntity {
  final int id;
  final int orderId;
  final int productVariantId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double price;
  final double totalPrice;

  const OrderLineEntity({
    required this.id,
    required this.orderId,
    required this.productVariantId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderLineEntity.fromJson(Map<String, dynamic> json) {
    final quantity = json['quantity'] as int? ?? 1;
    final price = _parseDouble(json['price']);
    return OrderLineEntity(
      id: json['id'] as int,
      orderId: json['order'] as int? ?? 0,
      productVariantId: json['product_variant'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'Unknown Product',
      productImage: json['product_image'] as String?,
      quantity: quantity,
      price: price,
      totalPrice: _parseDouble(json['total_price']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Order delivery address entity
class OrderAddressEntity {
  final int id;
  final String firstName;
  final String lastName;
  final String streetAddress1;
  final String? streetAddress2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String addressType;

  const OrderAddressEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.streetAddress1,
    this.streetAddress2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    required this.addressType,
  });

  factory OrderAddressEntity.fromJson(Map<String, dynamic> json) {
    return OrderAddressEntity(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      streetAddress1: json['street_address1'] as String? ?? '',
      streetAddress2: json['street_address2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      addressType: json['address_type'] as String? ?? 'home',
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  String get fullAddress {
    final parts = <String>[
      streetAddress1,
      if (streetAddress2 != null && streetAddress2!.isNotEmpty) streetAddress2!,
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
      if (postalCode != null && postalCode!.isNotEmpty) postalCode!,
    ];
    return parts.join(', ');
  }
}
