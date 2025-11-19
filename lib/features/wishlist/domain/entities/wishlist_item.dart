// // lib/features/wishlist/domain/entities/wishlist_item.dart

// import 'package:new_app/features/home/domain/entities/product.dart';

// class WishlistItem {
//   final String id;
//   final String productId;
//   final String name;
//   final double price;
//   final double mrp;
//   final String imageUrl;
//   final String unitLabel;
//   final int discountPct;
//   final DateTime? addedAt;

//   const WishlistItem({
//     required this.id,
//     required this.productId,
//     required this.name,
//     required this.price,
//     required this.mrp,
//     required this.imageUrl,
//     required this.unitLabel,
//     required this.discountPct,
//     this.addedAt,
//   });

//   factory WishlistItem.fromJson(Map<String, dynamic> json) {
//     // Handle image URL with protocol fix - try multiple possible sources
//     String rawImageUrl = '';

//     // First try the API response format (image field)
//     rawImageUrl = json['image']?.toString() ?? '';

//     // Fallback to other possible field names
//     if (rawImageUrl.isEmpty) {
//       rawImageUrl =
//           json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? '';
//     }

//     // If not found, try to extract from media array (like in Product/Offer entities)
//     if (rawImageUrl.isEmpty &&
//         json['media'] is List &&
//         (json['media'] as List).isNotEmpty) {
//       final media = (json['media'] as List).first;
//       rawImageUrl = media['image']?.toString() ?? '';
//     }

//     // If still not found, try product field if it exists (nested product data)
//     if (rawImageUrl.isEmpty && json['product'] is Map) {
//       final product = json['product'] as Map<String, dynamic>;
//       rawImageUrl =
//           product['image_url']?.toString() ??
//           product['imageUrl']?.toString() ??
//           '';

//       // Try media array in nested product
//       if (rawImageUrl.isEmpty &&
//           product['media'] is List &&
//           (product['media'] as List).isNotEmpty) {
//         final media = (product['media'] as List).first;
//         rawImageUrl = media['image']?.toString() ?? '';
//       }
//     }

//     String imageUrl = '';
//     if (rawImageUrl.isNotEmpty && !rawImageUrl.startsWith('http')) {
//       imageUrl = 'https://$rawImageUrl';
//     } else {
//       imageUrl = rawImageUrl;
//     }

//     return WishlistItem(
//       id: json['id']?.toString() ?? '',
//       productId:
//           json['product_variant']?.toString() ??
//           json['product_id']?.toString() ??
//           json['productId']?.toString() ??
//           '',
//       name: json['name']?.toString() ?? '',
//       price: _parseDouble(json['price']) ?? 0.0,
//       mrp:
//           _parseDouble(json['mrp']) ??
//           _parseDouble(json['price']) ??
//           0.0, // Use price as mrp if mrp not available
//       imageUrl: imageUrl,
//       unitLabel:
//           json['unit_label']?.toString() ??
//           json['unitLabel']?.toString() ??
//           json['weight']?.toString() ??
//           '', // Fallback to empty string if no unit info
//       discountPct:
//           _parseInt(json['discount_pct']) ??
//           _parseInt(json['discountPct']) ??
//           0, // Default to 0 if no discount info
//       addedAt: json['added_at'] != null
//           ? DateTime.tryParse(json['added_at'])
//           : json['created_at'] != null
//           ? DateTime.tryParse(json['created_at'])
//           : DateTime.now(), // Use current time as fallback
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'product_id': productId,
//       'name': name,
//       'price': price,
//       'mrp': mrp,
//       'image_url': imageUrl,
//       'unit_label': unitLabel,
//       'discount_pct': discountPct,
//       'added_at': addedAt?.toIso8601String(),
//     };
//   }

//   static double? _parseDouble(dynamic value) {
//     if (value == null) return null;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) return double.tryParse(value);
//     return null;
//   }

//   static int? _parseInt(dynamic value) {
//     if (value == null) return null;
//     if (value is int) return value;
//     if (value is double) return value.toInt();
//     if (value is String) return int.tryParse(value);
//     return null;
//   }

//   WishlistItem copyWith({
//     String? id,
//     String? productId,
//     String? name,
//     double? price,
//     double? mrp,
//     String? imageUrl,
//     String? unitLabel,
//     int? discountPct,
//     DateTime? addedAt,
//   }) {
//     return WishlistItem(
//       id: id ?? this.id,
//       productId: productId ?? this.productId,
//       name: name ?? this.name,
//       price: price ?? this.price,
//       mrp: mrp ?? this.mrp,
//       imageUrl: imageUrl ?? this.imageUrl,
//       unitLabel: unitLabel ?? this.unitLabel,
//       discountPct: discountPct ?? this.discountPct,
//       addedAt: addedAt ?? this.addedAt,
//     );
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is WishlistItem &&
//         other.id == id &&
//         other.productId == productId &&
//         other.name == name &&
//         other.price == price &&
//         other.mrp == mrp &&
//         other.imageUrl == imageUrl &&
//         other.unitLabel == unitLabel &&
//         other.discountPct == discountPct &&
//         other.addedAt == addedAt;
//   }

//   @override
//   int get hashCode {
//     return Object.hash(
//       id,
//       productId,
//       name,
//       price,
//       mrp,
//       imageUrl,
//       unitLabel,
//       discountPct,
//       addedAt,
//     );
//   }

//   // Factory method to create WishlistItem from Product
//   factory WishlistItem.fromProduct({
//     required String id,
//     required String productId,
//     required String name,
//     required double price,
//     required double mrp,
//     required String imageUrl,
//     required String unitLabel,
//     required int discountPct,
//     DateTime? addedAt,
//   }) {
//     // Apply the same URL fix as in fromJson
//     String fixedImageUrl = '';
//     if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
//       fixedImageUrl = 'https://$imageUrl';
//     } else {
//       fixedImageUrl = imageUrl;
//     }

//     return WishlistItem(
//       id: id,
//       productId: productId,
//       name: name,
//       price: price,
//       mrp: mrp,
//       imageUrl: fixedImageUrl,
//       unitLabel: unitLabel,
//       discountPct: discountPct,
//       addedAt: addedAt ?? DateTime.now(),
//     );
//   }

//   // Factory method to create WishlistItem from Offer
//   factory WishlistItem.fromOffer({
//     required String id,
//     required String productId,
//     required String name,
//     required double price,
//     required double oldPrice,
//     required String imageUrl,
//     required String weight,
//     DateTime? addedAt,
//   }) {
//     // Apply the same URL fix as in fromJson
//     String fixedImageUrl = '';
//     if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
//       fixedImageUrl = 'https://$imageUrl';
//     } else {
//       fixedImageUrl = imageUrl;
//     }

//     // Calculate discount percentage
//     final discountPct = oldPrice > price
//         ? (((oldPrice - price) / oldPrice) * 100).round()
//         : 0;

//     return WishlistItem(
//       id: id,
//       productId: productId,
//       name: name,
//       price: price,
//       mrp: oldPrice,
//       imageUrl: fixedImageUrl,
//       unitLabel: weight,
//       discountPct: discountPct,
//       addedAt: addedAt ?? DateTime.now(),
//     );
//   }

//   // Convert WishlistItem to Product for use with ProductCard
//   Product toProduct() {
//     return Product(
//       id: productId,
//       name: name,
//       price: price,
//       mrp: mrp,
//       imageUrl: imageUrl,
//       unitLabel: unitLabel,
//       discountPct: discountPct,
//     );
//   }

//   @override
//   String toString() {
//     return 'WishlistItem(id: $id, productId: $productId, name: $name, price: $price, mrp: $mrp, imageUrl: $imageUrl, unitLabel: $unitLabel, discountPct: $discountPct, addedAt: $addedAt)';
//   }
// }
