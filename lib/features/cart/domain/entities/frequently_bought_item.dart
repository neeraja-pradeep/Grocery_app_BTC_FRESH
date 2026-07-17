import 'package:equatable/equatable.dart';

/// Slim view of a variant used by the "Frequently Bought" strip. Mirrors only
/// the fields the `/api/order/v1/orders/frequently-bought/` endpoint returns —
/// it is intentionally narrower than [ProductVariantDetails] used by cart
/// lines (no preorder/inventory-tracking/etc. flags), so this stays decoupled
/// from the checkout-line flow.
class FrequentlyBoughtVariant extends Equatable {
  const FrequentlyBoughtVariant({
    required this.id,
    required this.productId,
    required this.name,
    this.sku,
    this.price,
    this.discountedPrice,
    this.weight,
    this.stockUnit,
    this.imageUrl,
    this.currentQuantity,
    this.status,
  });

  final int id;
  final int productId;
  final String name;
  final String? sku;
  final String? price; // raw API string, e.g. "120.00"
  final String? discountedPrice; // null when no discount
  final String? weight;
  final String? stockUnit;
  final String? imageUrl;
  final int? currentQuantity;
  final bool? status;

  bool get hasDiscount {
    if (discountedPrice == null || discountedPrice!.isEmpty) return false;
    final base = double.tryParse(price ?? '');
    final disc = double.tryParse(discountedPrice!);
    if (base == null || disc == null) return false;
    return disc > 0 && disc < base;
  }

  /// Integer percentage off, e.g. 17 for "₹120 → ₹99". Zero when no discount.
  int get discountPercentage {
    if (!hasDiscount) return 0;
    final base = double.parse(price!);
    final disc = double.parse(discountedPrice!);
    return (((base - disc) / base) * 100).round();
  }

  bool get inStock {
    if (currentQuantity == null) return true; // unknown → assume in stock
    return currentQuantity! > 0;
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    name,
    sku,
    price,
    discountedPrice,
    weight,
    stockUnit,
    imageUrl,
    currentQuantity,
    status,
  ];
}

/// A single entry in the frequently-bought list — purchase metadata plus the
/// variant snapshot needed to render the strip card.
class FrequentlyBoughtItem extends Equatable {
  const FrequentlyBoughtItem({
    required this.variant,
    this.lastPurchasedAt,
    this.timesPurchased,
    this.totalQuantity,
  });

  final FrequentlyBoughtVariant variant;
  final DateTime? lastPurchasedAt;
  final int? timesPurchased;
  final int? totalQuantity;

  @override
  List<Object?> get props => [
    variant,
    lastPurchasedAt,
    timesPurchased,
    totalQuantity,
  ];
}
