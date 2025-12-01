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
    return Product(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
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
      media:
          (json['media'] as List<dynamic>?)
              ?.map((e) => ProductMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      variants:
          (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
