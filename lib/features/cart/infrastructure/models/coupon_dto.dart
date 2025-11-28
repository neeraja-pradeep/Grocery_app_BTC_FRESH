import '../../domain/entities/coupon.dart';

/// Data Transfer Object for Coupon API response
class CouponDto {
  const CouponDto({
    required this.id,
    required this.name,
    required this.description,
    required this.discountPercentage,
    required this.limit,
    required this.usage,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String description;
  final String discountPercentage;
  final int limit;
  final int usage;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CouponDto.fromJson(Map<String, dynamic> json) {
    return CouponDto(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      discountPercentage: json['discount_percentage'] as String,
      limit: json['limit'] as int,
      usage: json['usage'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'discount_percentage': discountPercentage,
      'limit': limit,
      'usage': usage,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert DTO to domain entity
  Coupon toDomain() {
    return Coupon(
      id: id,
      name: name,
      description: description,
      discountPercentage: discountPercentage,
      limit: limit,
      usage: usage,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Data Transfer Object for paginated coupon list response
class CouponListResponseDto {
  const CouponListResponseDto({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<CouponDto> results;

  factory CouponListResponseDto.fromJson(Map<String, dynamic> json) {
    return CouponListResponseDto(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => CouponDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }

  /// Convert DTO to domain entity
  CouponListResponse toDomain() {
    return CouponListResponse(
      count: count,
      next: next,
      previous: previous,
      results: results.map((e) => e.toDomain()).toList(),
    );
  }
}
