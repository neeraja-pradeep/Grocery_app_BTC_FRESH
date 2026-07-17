import 'package:freezed_annotation/freezed_annotation.dart';
import 'product_media.dart';
import 'product_variant.dart';

part 'product.freezed.dart';

@freezed
class Product with _$Product {
  const Product._();

  const factory Product({
    required int id,
    required String name,
    String? description,
    required String categoryName,
    required int categoryId,
    String? slug,
    String? descriptionPlaintext,
    String? searchDocument,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? weight,
    int? defaultVariantId,
    required String rating,
    required int taxClassId,
    required List<ProductMedia> media,
    required List<ProductVariant> variants,
    required bool status,
    String? tags,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) {
    final productId = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id'].toString()) ?? 0;
    final productName = json['name']?.toString() ?? '';

    // Media: support both the `media` array and the `primary_image` singular
    // object returned by `/api/products/v1/?is_discounted=true`.
    final rawMediaList = json['media'];
    final rawPrimaryImage = json['primary_image'];
    final List<Map<String, dynamic>> mediaJsonForVariants =
        rawMediaList is List && rawMediaList.isNotEmpty
        ? rawMediaList.whereType<Map<String, dynamic>>().toList()
        : (rawPrimaryImage is Map<String, dynamic>
              ? [rawPrimaryImage]
              : const []);

    final media = mediaJsonForVariants.map(ProductMedia.fromJson).toList();

    // The discounted-products endpoint embeds variants that are missing
    // `name`, `product_id`, `media`, and `current_quantity` (it returns an
    // `in_stock` boolean instead). Backfill those from the parent product so
    // the rest of the app sees complete `ProductVariant`s.
    final variants = <ProductVariant>[];
    final rawVariants = json['variants'];
    if (rawVariants is List) {
      for (final raw in rawVariants) {
        if (raw is! Map<String, dynamic>) continue;
        final enriched = Map<String, dynamic>.from(raw);
        enriched.putIfAbsent('product_id', () => productId);
        enriched.putIfAbsent('name', () => productName);
        if ((enriched['media'] is! List ||
                (enriched['media'] as List).isEmpty) &&
            mediaJsonForVariants.isNotEmpty) {
          enriched['media'] = mediaJsonForVariants;
        }
        if (enriched['current_quantity'] == null &&
            enriched['in_stock'] is bool) {
          enriched['current_quantity'] = (enriched['in_stock'] as bool)
              ? '1'
              : '0';
        }
        variants.add(ProductVariant.fromJson(enriched));
      }
    }

    return Product(
      id: productId,
      name: productName,
      description: json['description'] is Map
          ? (json['description'] as Map)['text']?.toString()
          : json['description']?.toString(),
      categoryName: json['category_name']?.toString() ?? '',
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id'].toString()) ?? 0,
      slug: json['slug']?.toString(),
      descriptionPlaintext: json['description_plaintext']?.toString(),
      searchDocument: json['search_document']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      weight: json['weight']?.toString(),
      defaultVariantId: json['default_variant_id'] is int
          ? json['default_variant_id']
          : int.tryParse(json['default_variant_id']?.toString() ?? ''),
      rating: json['rating']?.toString() ?? '0.0',
      taxClassId: json['tax_class_id'] is int
          ? json['tax_class_id']
          : int.tryParse(json['tax_class_id'].toString()) ?? 0,
      media: media,
      variants: variants,
      status: json['status'] == true,
      tags: json['tags']?.toString(),
    );
  }

  // Helper getters
  bool get hasVariants => variants.isNotEmpty;

  ProductVariant? get defaultVariant {
    if (variants.isEmpty) return null;
    if (defaultVariantId != null) {
      try {
        return variants.firstWhere((v) => v.id == defaultVariantId);
      } catch (e) {
        return variants.first;
      }
    }
    return variants.first;
  }

  List<ProductVariant> get availableVariants {
    return variants.where((v) => v.status).toList();
  }

  String get displayImage {
    if (media.isNotEmpty) {
      return media.first.imageUrl;
    }
    if (hasVariants && defaultVariant?.media.isNotEmpty == true) {
      return defaultVariant!.media.first.imageUrl;
    }
    return '';
  }

  double get displayPrice {
    final variant = defaultVariant;
    if (variant == null) return 0.0;
    return variant.hasDiscount ? variant.discountedPrice! : variant.price;
  }

  bool get hasDiscount {
    return defaultVariant?.hasDiscount ?? false;
  }
}
