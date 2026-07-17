import '../../../../core/config/app_config.dart';
import '../../domain/entities/category_product.dart';

class CategoryProductDto {
  const CategoryProductDto({
    required this.id,
    required this.name,
    required this.variantId,
    required this.variantName,
    this.description,
    this.slug,
    this.price,
    this.originalPrice,
    this.variantSku,
    this.weight,
    this.unit,
    this.rating,
    this.imageUrl,
    this.thumbnailUrl,
    this.categoryId,
    this.defaultVariantId,
    this.currentQuantity,
    this.status,
    this.apiInStock,
  });

  final String id;
  final String name;
  final String variantId;
  final String variantName;
  final String? description;
  final String? slug;
  final String? price;
  final String? originalPrice;
  final String? variantSku;
  final String? weight;
  final String? unit;
  final double? rating;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? categoryId;
  final String? defaultVariantId;
  final int? currentQuantity;
  final bool? status;
  // Variant-level `in_stock` boolean from the products list response.
  final bool? apiInStock;

  factory CategoryProductDto.fromProduct({
    required Map<String, dynamic> product,
    Map<String, dynamic>? variant,
  }) {
    final rawId = product['id'] ?? product['product_id'];
    final productId =
        rawId?.toString() ??
        variant?['product_id']?.toString() ??
        product['name'].toString();

    final rawName = product['name'];
    if (rawName == null) {
      throw const FormatException('Product payload missing `name`.');
    }

    final variantId = variant?['id']?.toString() ?? productId;
    final variantName = variant?['name']?.toString() ?? rawName.toString();
    final variantSku = variant?['sku']?.toString();

    // Get the base price from API (this is the original/MRP price)
    final basePrice =
        variant?['price']?.toString() ?? product['price']?.toString();

    // Get discounted price from API (sale price - if available)
    final discountedPriceValue =
        variant?['discounted_price'] ?? product['discounted_price'];

    // Determine display price and original price based on discounted_price
    // If discounted_price exists and is not null → show it as main price, basePrice as strikethrough
    // If discounted_price is null → show basePrice as main price, no strikethrough
    final String? variantPrice;
    final String? originalPrice;

    if (discountedPriceValue != null &&
        discountedPriceValue.toString().isNotEmpty) {
      // Has discount: discounted_price is the display price, price is original
      variantPrice = discountedPriceValue.toString();
      originalPrice = basePrice;
    } else {
      // No discount: price is the display price, no original price
      variantPrice = basePrice;
      // Check for other original price fields (compare_at_price, mrp, etc.)
      final otherOriginalPrice =
          variant?['compare_at_price'] ??
          variant?['original_price'] ??
          variant?['base_price'] ??
          variant?['mrp'] ??
          product['compare_at_price'] ??
          product['original_price'] ??
          product['base_price'] ??
          product['mrp'];
      originalPrice = otherOriginalPrice?.toString();
    }

    final weightValue =
        variant?['weight'] ?? product['weight'] ?? variant?['weight_value'];
    final resolvedWeight = weightValue?.toString();

    // Variant-level `unit` (e.g. "g"/"kg"/"pack"/"units") — prefer the variant
    // field but fall back to the product-level one so older payloads still
    // render a unit string alongside the weight.
    final unitValue =
        variant?['unit'] ??
        product['unit'] ??
        variant?['stock_unit'] ??
        variant?['current_stock_unit'] ??
        product['stock_unit'];
    final resolvedUnit = unitValue?.toString();

    double? resolvedRating;
    final ratingValue = product['rating'];
    if (ratingValue is num) {
      resolvedRating = ratingValue.toDouble();
    } else if (ratingValue is String) {
      resolvedRating = double.tryParse(ratingValue);
    }

    String? imageUrl = product['imageUrl']?.toString();
    String? thumbnailUrl = product['thumbnailUrl']?.toString();

    List<dynamic>? mediaSources;
    if (variant?['media'] is List && (variant?['media'] as List).isNotEmpty) {
      mediaSources = variant?['media'] as List<dynamic>;
    } else if (product['media'] is List &&
        (product['media'] as List).isNotEmpty) {
      mediaSources = product['media'] as List<dynamic>;
    }

    Map<String, dynamic>? primaryMedia;
    if (mediaSources != null && mediaSources.isNotEmpty) {
      final mediaEntry = mediaSources.first;
      if (mediaEntry is Map<String, dynamic>) {
        primaryMedia = mediaEntry;
      } else if (mediaEntry is Map) {
        primaryMedia = Map<String, dynamic>.from(mediaEntry);
      }
    } else {
      // Fallback to `primary_image` (returned by the is_discounted=true list).
      final rawPrimaryImage = product['primary_image'];
      if (rawPrimaryImage is Map<String, dynamic>) {
        primaryMedia = rawPrimaryImage;
      } else if (rawPrimaryImage is Map) {
        primaryMedia = Map<String, dynamic>.from(rawPrimaryImage);
      }
    }

    if (primaryMedia != null) {
      final rawImage =
          primaryMedia['image']?.toString() ?? primaryMedia['external_url'];
      final rawFilePath = primaryMedia['file_path']?.toString();
      imageUrl = _resolveMediaUrl(rawImage?.toString(), rawFilePath);
      thumbnailUrl = _resolveMediaUrl(null, rawFilePath) ?? imageUrl;
    } else {
      final categoryImage = product['background_image_url']?.toString();
      final categoryImagePath = product['background_image_path']?.toString();
      imageUrl = _resolveMediaUrl(categoryImage, categoryImagePath);
      thumbnailUrl = imageUrl;
    }

    if (imageUrl == null) {
      final fallbackImage = product['background_image_url']?.toString();
      final fallbackPath = product['background_image_path']?.toString();
      imageUrl = _resolveMediaUrl(fallbackImage, fallbackPath);
    }
    if (thumbnailUrl == null) {
      final fallbackPath = product['background_image_path']?.toString();
      thumbnailUrl = _resolveMediaUrl(null, fallbackPath) ?? imageUrl;
    }

    String? defaultVariantId;
    final defaultVariantValue = product['default_variant_id'];
    if (defaultVariantValue != null) {
      defaultVariantId = defaultVariantValue.toString();
    } else if (variant?['id'] != null) {
      defaultVariantId = variant?['id'].toString();
    }

    String? categoryId;
    final categoryIdValue =
        product['category_id'] ??
        product['category'] ??
        variant?['category_id'];
    if (categoryIdValue is Map) {
      final nestedId = categoryIdValue['id'];
      if (nestedId != null) {
        categoryId = nestedId.toString();
      }
    } else if (categoryIdValue != null) {
      categoryId = categoryIdValue.toString();
    }

    final description =
        product['description_plaintext']?.toString() ?? product['description'];

    // Parse stock information from variant or product.
    // Products-list endpoint nests variants with `quantity`; the variants
    // endpoint also exposes `current_quantity`. Accept either.
    int? currentQuantity;
    final quantityValue =
        variant?['current_quantity'] ??
        variant?['quantity'] ??
        product['current_quantity'] ??
        product['quantity'];
    if (quantityValue is int) {
      currentQuantity = quantityValue;
    } else if (quantityValue is String) {
      currentQuantity = int.tryParse(quantityValue);
    } else if (quantityValue is num) {
      currentQuantity = quantityValue.toInt();
    }

    // Parse status field
    bool? status;
    final statusValue = variant?['status'] ?? product['status'];
    if (statusValue is bool) {
      status = statusValue;
    } else if (statusValue is int) {
      status = statusValue == 1;
    } else if (statusValue is String) {
      status = statusValue.toLowerCase() == 'true' || statusValue == '1';
    }

    // Parse explicit `in_stock` boolean (variant first, then product).
    final bool? apiInStock = _parseBoolFlag(
      variant?['in_stock'] ?? product['in_stock'],
    );

    return CategoryProductDto(
      id: productId,
      name: rawName.toString(),
      variantId: variantId,
      variantName: variantName,
      variantSku: variantSku,
      description: description?.toString(),
      slug: product['slug']?.toString(),
      price: variantPrice,
      originalPrice: originalPrice,
      weight: resolvedWeight,
      unit: resolvedUnit,
      rating: resolvedRating,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      categoryId: categoryId,
      defaultVariantId: defaultVariantId,
      currentQuantity: currentQuantity,
      status: status,
      apiInStock: apiInStock,
    );
  }

  factory CategoryProductDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawName = json['name'];
    if (rawId == null || rawName == null) {
      throw const FormatException('Product JSON missing `id` or `name`.');
    }

    final rawVariantId = json['variantId'] ?? json['variant_id'] ?? rawId;
    final rawVariantName =
        json['variantName'] ?? json['variant_name'] ?? rawName;

    final rawRating = json['rating'];
    double? rating;
    if (rawRating is num) {
      rating = rawRating.toDouble();
    } else if (rawRating is String) {
      rating = double.tryParse(rawRating);
    }

    // Handle discounted_price for price display logic
    final basePrice = json['price']?.toString();
    final discountedPrice = json['discounted_price']?.toString();

    final String? displayPrice;
    final String? originalPrice;

    if (discountedPrice != null && discountedPrice.isNotEmpty) {
      // Has discount
      displayPrice = discountedPrice;
      originalPrice = basePrice;
    } else {
      // No discount
      displayPrice = basePrice;
      originalPrice =
          json['originalPrice']?.toString() ??
          json['original_price']?.toString() ??
          json['compare_at_price']?.toString() ??
          json['mrp']?.toString();
    }

    // Parse stock information
    int? currentQuantity;
    final quantityValue = json['currentQuantity'] ??
        json['current_quantity'] ??
        json['quantity'];
    if (quantityValue is int) {
      currentQuantity = quantityValue;
    } else if (quantityValue is String) {
      currentQuantity = int.tryParse(quantityValue);
    } else if (quantityValue is num) {
      currentQuantity = quantityValue.toInt();
    }

    // Parse status field
    bool? status;
    final statusValue = json['status'];
    if (statusValue is bool) {
      status = statusValue;
    } else if (statusValue is int) {
      status = statusValue == 1;
    } else if (statusValue is String) {
      status = statusValue.toLowerCase() == 'true' || statusValue == '1';
    }

    final bool? apiInStock = _parseBoolFlag(
      json['apiInStock'] ?? json['in_stock'],
    );

    return CategoryProductDto(
      id: rawId.toString(),
      name: rawName.toString(),
      variantId: rawVariantId.toString(),
      variantName: rawVariantName.toString(),
      variantSku:
          json['variantSku']?.toString() ?? json['variant_sku']?.toString(),
      description: json['description']?.toString(),
      slug: json['slug']?.toString(),
      price: displayPrice,
      originalPrice: originalPrice,
      weight: json['weight']?.toString(),
      unit: json['unit']?.toString(),
      rating: rating,
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      thumbnailUrl:
          json['thumbnailUrl']?.toString() ?? json['thumbnail_url']?.toString(),
      categoryId:
          json['categoryId']?.toString() ?? json['category_id']?.toString(),
      defaultVariantId:
          json['defaultVariantId']?.toString() ??
          json['default_variant_id']?.toString(),
      currentQuantity: currentQuantity,
      status: status,
      apiInStock: apiInStock,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'variantId': variantId,
    'variantName': variantName,
    if (variantSku != null) 'variantSku': variantSku,
    if (description != null) 'description': description,
    if (slug != null) 'slug': slug,
    if (price != null) 'price': price,
    if (originalPrice != null) 'originalPrice': originalPrice,
    if (weight != null) 'weight': weight,
    if (unit != null) 'unit': unit,
    if (rating != null) 'rating': rating,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    if (categoryId != null) 'categoryId': categoryId,
    if (defaultVariantId != null) 'defaultVariantId': defaultVariantId,
    if (currentQuantity != null) 'currentQuantity': currentQuantity,
    if (status != null) 'status': status,
    if (apiInStock != null) 'apiInStock': apiInStock,
  };

  CategoryProduct toDomain() => CategoryProduct(
    id: id,
    name: name,
    variantId: variantId,
    variantName: variantName,
    variantSku: variantSku,
    description: description,
    slug: slug,
    price: price,
    originalPrice: originalPrice,
    weight: weight,
    unit: unit,
    rating: rating,
    imageUrl: imageUrl,
    thumbnailUrl: thumbnailUrl,
    categoryId: categoryId,
    defaultVariantId: defaultVariantId,
    currentQuantity: currentQuantity,
    status: status,
    apiInStock: apiInStock,
  );

  static List<CategoryProductDto> listFromJson(
    dynamic data, {
    String? filterCategoryId,
    bool onlyDiscountedVariants = false,
  }) {
    final normalizedFilter = filterCategoryId?.trim();
    final hasFilter = normalizedFilter != null && normalizedFilter.isNotEmpty;
    final collected = <CategoryProductDto>[];

    void addDto(CategoryProductDto dto) {
      if (hasFilter) {
        final normalizedCategoryId = dto.categoryId?.trim();
        if (normalizedCategoryId == null || normalizedCategoryId.isEmpty) {
          return;
        }
        if (normalizedCategoryId != normalizedFilter) {
          return;
        }
      }
      collected.add(dto);
    }

    Iterable<CategoryProductDto> expandProduct(
      Map<String, dynamic> product,
    ) sync* {
      final variants = product['variants'];

      // If variants field exists and is an empty list, skip this product entirely
      // Products without variants cannot be purchased
      if (variants is List && variants.isEmpty) {
        return;
      }

      if (variants is List && variants.isNotEmpty) {
        for (final dynamic variant in variants) {
          Map<String, dynamic>? variantMap;
          if (variant is Map<String, dynamic>) {
            variantMap = variant;
          } else if (variant is Map) {
            variantMap = Map<String, dynamic>.from(variant);
          } else {
            throw const FormatException('Invalid variant entry.');
          }
          if (onlyDiscountedVariants && !_hasDiscount(variantMap)) {
            continue;
          }
          yield CategoryProductDto.fromProduct(
            product: product,
            variant: variantMap,
          );
        }
        return;
      }

      if (product.containsKey('variantId') ||
          product.containsKey('variant_id')) {
        if (onlyDiscountedVariants && !_hasDiscount(product)) {
          return;
        }
        yield CategoryProductDto.fromJson(product);
        return;
      }

      if (onlyDiscountedVariants && !_hasDiscount(product)) {
        return;
      }
      yield CategoryProductDto.fromProduct(product: product);
    }

    if (data is Map) {
      final map = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data);
      final items = map['results'] ?? map['products'] ?? map['data'];
      if (items is! List) {
        throw const FormatException('Invalid products payload.');
      }
      for (final dynamic item in items) {
        Map<String, dynamic>? product;
        if (item is Map<String, dynamic>) {
          product = item;
        } else if (item is Map) {
          product = Map<String, dynamic>.from(item);
        } else {
          throw const FormatException('Invalid product entry.');
        }
        for (final dto in expandProduct(product)) {
          addDto(dto);
        }
      }
      return collected;
    }

    if (data is List) {
      for (final dynamic item in data) {
        Map<String, dynamic>? product;
        if (item is Map<String, dynamic>) {
          product = item;
        } else if (item is Map) {
          product = Map<String, dynamic>.from(item);
        } else {
          throw const FormatException('Invalid product list item.');
        }
        for (final dto in expandProduct(product)) {
          addDto(dto);
        }
      }
      return collected;
    }

    throw const FormatException('No products.');
  }
}

/// Coerces a JSON value into a `bool?`. Accepts native bools, 0/1 ints,
/// and `"true"` / `"false"` / `"1"` / `"0"` strings (case-insensitive).
/// Returns null for any other shape (including null), so callers can
/// distinguish "absent" from "explicitly true/false".
bool? _parseBoolFlag(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final s = value.trim().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return null;
}

/// True when a variant/product payload has a non-null, non-empty
/// `discounted_price`. Used to drop non-discounted variants in Price Drop mode.
bool _hasDiscount(Map<String, dynamic> payload) {
  final value = payload['discounted_price'];
  if (value == null) return false;
  final str = value.toString().trim();
  if (str.isEmpty) return false;
  final parsed = double.tryParse(str);
  if (parsed == null) return false;
  return parsed > 0;
}

/// Resolve media URL to CDN
/// Now uses centralized AppConfig
String? _resolveMediaUrl(String? url, String? path) {
  // Try primary URL first
  if (url != null && url.isNotEmpty) {
    return AppConfig.convertToCdnUrl(url);
  }

  // Try file_path as fallback
  if (path != null && path.isNotEmpty) {
    return AppConfig.convertToCdnUrl(path);
  }

  return null;
}
