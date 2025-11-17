// features/home/domain/entities/deal.dart

class Deal {
  final String productId;
  final String badgeText; // e.g., "Buy 1 Get 1 Free", "Flash Sale"
  final double dealPrice; // The final price under the deal

  const Deal({
    required this.productId,
    required this.badgeText,
    required this.dealPrice,
  });

  /// Factory constructor to create a Deal object from a JSON map.
  factory Deal.fromJson(Map<String, dynamic> json) {
    // Note: JSON numbers can sometimes be ints, so we use .toDouble()
    return Deal(
      productId: json['productId'] as String,
      badgeText: json['badgeText'] as String,
      dealPrice: (json['dealPrice'] as num).toDouble(),
    );
  }
}
