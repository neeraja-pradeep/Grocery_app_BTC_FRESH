import '../../../../core/config/app_config.dart';
import '../../domain/entities/frequently_bought_item.dart';

/// DTO for one entry in `/api/order/v1/orders/frequently-bought/`.
class FrequentlyBoughtItemDto {
  const FrequentlyBoughtItemDto({
    required this.variant,
    this.lastPurchasedAt,
    this.timesPurchased,
    this.totalQuantity,
  });

  final FrequentlyBoughtVariantDto variant;
  final String? lastPurchasedAt;
  final int? timesPurchased;
  final int? totalQuantity;

  factory FrequentlyBoughtItemDto.fromJson(Map<String, dynamic> json) {
    final variantJson = json['product_variant_details'];
    if (variantJson is! Map<String, dynamic>) {
      throw const FormatException(
        'frequently-bought entry missing product_variant_details',
      );
    }
    return FrequentlyBoughtItemDto(
      variant: FrequentlyBoughtVariantDto.fromJson(variantJson),
      lastPurchasedAt: json['last_purchased_at']?.toString(),
      timesPurchased: _asInt(json['times_purchased']),
      totalQuantity: _asInt(json['total_quantity']),
    );
  }

  FrequentlyBoughtItem toEntity() => FrequentlyBoughtItem(
    variant: variant.toEntity(),
    lastPurchasedAt: lastPurchasedAt != null
        ? DateTime.tryParse(lastPurchasedAt!)
        : null,
    timesPurchased: timesPurchased,
    totalQuantity: totalQuantity,
  );
}

class FrequentlyBoughtVariantDto {
  const FrequentlyBoughtVariantDto({
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
  final String? price;
  final String? discountedPrice;
  final String? weight;
  final String? stockUnit;
  final String? imageUrl;
  final int? currentQuantity;
  final bool? status;

  factory FrequentlyBoughtVariantDto.fromJson(Map<String, dynamic> json) {
    return FrequentlyBoughtVariantDto(
      id: _asInt(json['id']) ?? 0,
      productId: _asInt(json['product_id']) ?? 0,
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString(),
      price: json['price']?.toString(),
      discountedPrice: () {
        final raw = json['discounted_price'];
        if (raw == null) return null;
        final s = raw.toString().trim();
        return s.isEmpty ? null : s;
      }(),
      weight: json['weight']?.toString(),
      stockUnit:
          json['current_stock_unit']?.toString() ??
          json['unit']?.toString(),
      imageUrl: _firstMediaUrl(json['media']) ??
          _resolveSingleImage(json['primary_image']),
      currentQuantity: _asInt(json['current_quantity']),
      status: json['status'] is bool ? json['status'] as bool : null,
    );
  }

  FrequentlyBoughtVariant toEntity() => FrequentlyBoughtVariant(
    id: id,
    productId: productId,
    name: name,
    sku: sku,
    price: price,
    discountedPrice: discountedPrice,
    weight: weight,
    stockUnit: stockUnit,
    imageUrl: imageUrl,
    currentQuantity: currentQuantity,
    status: status,
  );
}

/// Envelope: `{count, next, previous, results: [...]}`.
class FrequentlyBoughtResponseDto {
  const FrequentlyBoughtResponseDto({
    required this.results,
    this.count,
    this.next,
    this.previous,
  });

  final List<FrequentlyBoughtItemDto> results;
  final int? count;
  final String? next;
  final String? previous;

  factory FrequentlyBoughtResponseDto.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final items = rawResults is List
        ? rawResults
              .whereType<Map>()
              .map(
                (e) =>
                    FrequentlyBoughtItemDto.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <FrequentlyBoughtItemDto>[];

    return FrequentlyBoughtResponseDto(
      results: items,
      count: _asInt(json['count']),
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
    );
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? _firstMediaUrl(dynamic media) {
  if (media is! List || media.isEmpty) return null;
  final first = media.first;
  if (first is! Map) return null;
  final entry = Map<String, dynamic>.from(first);
  return _resolveSingleImage(entry);
}

/// Resolves either a `media[0]`-shaped object or a `primary_image` object
/// down to a single absolute image URL, with CDN rewriting where needed.
String? _resolveSingleImage(dynamic raw) {
  if (raw is! Map) return null;
  final entry = Map<String, dynamic>.from(raw);
  final candidate =
      entry['image']?.toString() ??
      entry['external_url']?.toString() ??
      entry['file_path']?.toString();
  if (candidate == null || candidate.isEmpty) return null;
  return AppConfig.convertToCdnUrl(candidate);
}
