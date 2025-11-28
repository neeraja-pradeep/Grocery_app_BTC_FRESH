import 'package:equatable/equatable.dart';

/// Product variant details within a checkout line
class ProductVariantDetails extends Equatable {
  const ProductVariantDetails({
    required this.id,
    required this.sku,
    required this.name,
    required this.productId,
    required this.trackInventory,
    required this.price,
    required this.discountedPrice,
    required this.isSelected,
    required this.isPreorder,
    this.preorderEndDate,
    required this.preorderGlobalThreshold,
    required this.quantityLimitPerCustomer,
    required this.createdAt,
    required this.updatedAt,
    required this.weight,
    required this.status,
    required this.tags,
    this.barCode,
    required this.media,
    required this.currentQuantity,
    required this.currentStockUnit,
    required this.prodDescription,
    required this.productRating,
    required this.warehouseName,
    required this.warehouseId,
  });

  final int id;
  final String sku;
  final String name;
  final int productId;
  final bool trackInventory;
  final String price;
  final String discountedPrice;
  final bool isSelected;
  final bool isPreorder;
  final DateTime? preorderEndDate;
  final int preorderGlobalThreshold;
  final int quantityLimitPerCustomer;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String weight;
  final bool status;
  final String tags;
  final String? barCode;
  final List<String> media;
  final int currentQuantity;
  final String currentStockUnit;
  final String prodDescription;
  final String productRating;
  final String warehouseName;
  final int warehouseId;

  /// Get numeric price value
  double get priceValue => double.tryParse(price) ?? 0.0;

  /// Get numeric discounted price value
  double get discountedPriceValue => double.tryParse(discountedPrice) ?? 0.0;

  /// Get effective price (discounted if available, otherwise regular price)
  double get effectivePrice =>
      discountedPriceValue > 0 ? discountedPriceValue : priceValue;

  /// Check if product has discount
  bool get hasDiscount =>
      discountedPriceValue > 0 && discountedPriceValue < priceValue;

  /// Get discount percentage
  double get discountPercentage {
    if (!hasDiscount) return 0.0;
    return ((priceValue - discountedPriceValue) / priceValue) * 100;
  }

  @override
  List<Object?> get props => [
    id,
    sku,
    name,
    productId,
    trackInventory,
    price,
    discountedPrice,
    isSelected,
    isPreorder,
    preorderEndDate,
    preorderGlobalThreshold,
    quantityLimitPerCustomer,
    createdAt,
    updatedAt,
    weight,
    status,
    tags,
    barCode,
    media,
    currentQuantity,
    currentStockUnit,
    prodDescription,
    productRating,
    warehouseName,
    warehouseId,
  ];
}

/// Checkout line (cart item) entity
class CheckoutLine extends Equatable {
  const CheckoutLine({
    required this.id,
    required this.checkout,
    required this.productVariantId,
    required this.quantity,
    required this.productVariantDetails,
  });

  final int id;
  final int checkout;
  final int productVariantId;
  final int quantity;
  final ProductVariantDetails productVariantDetails;

  /// Calculate line total (quantity * effective price)
  double get lineTotal => quantity * productVariantDetails.effectivePrice;

  /// Calculate savings on this line
  double get lineSavings {
    if (!productVariantDetails.hasDiscount) return 0.0;
    return quantity *
        (productVariantDetails.priceValue -
            productVariantDetails.discountedPriceValue);
  }

  @override
  List<Object?> get props => [
    id,
    checkout,
    productVariantId,
    quantity,
    productVariantDetails,
  ];

  CheckoutLine copyWith({
    int? id,
    int? checkout,
    int? productVariantId,
    int? quantity,
    ProductVariantDetails? productVariantDetails,
  }) {
    return CheckoutLine(
      id: id ?? this.id,
      checkout: checkout ?? this.checkout,
      productVariantId: productVariantId ?? this.productVariantId,
      quantity: quantity ?? this.quantity,
      productVariantDetails:
          productVariantDetails ?? this.productVariantDetails,
    );
  }
}

/// Checkout lines list response
class CheckoutLinesResponse extends Equatable {
  const CheckoutLinesResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<CheckoutLine> results;

  /// Calculate total for all items
  double get totalAmount =>
      results.fold(0.0, (sum, line) => sum + line.lineTotal);

  /// Calculate total savings
  double get totalSavings =>
      results.fold(0.0, (sum, line) => sum + line.lineSavings);

  /// Get total item count (sum of all quantities)
  int get totalItems => results.fold(0, (sum, line) => sum + line.quantity);

  @override
  List<Object?> get props => [count, next, previous, results];
}
