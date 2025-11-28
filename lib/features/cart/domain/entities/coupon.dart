import 'package:equatable/equatable.dart';

/// Coupon domain entity
/// Represents a coupon/discount code that can be applied to orders
class Coupon extends Equatable {
  const Coupon({
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

  /// Check if coupon is currently active/valid
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Check if coupon has reached usage limit
  bool get isAtLimit => usage >= limit;

  /// Check if coupon is available for use
  bool get isAvailable => isActive && !isAtLimit;

  /// Get remaining uses
  int get remainingUses => limit - usage;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    discountPercentage,
    limit,
    usage,
    startDate,
    endDate,
    createdAt,
    updatedAt,
  ];

  Coupon copyWith({
    int? id,
    String? name,
    String? description,
    String? discountPercentage,
    int? limit,
    int? usage,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Coupon(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      limit: limit ?? this.limit,
      usage: usage ?? this.usage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Paginated response for coupons list
class CouponListResponse extends Equatable {
  const CouponListResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<Coupon> results;

  bool get hasNext => next != null;
  bool get hasPrevious => previous != null;

  @override
  List<Object?> get props => [count, next, previous, results];

  CouponListResponse copyWith({
    int? count,
    String? next,
    String? previous,
    List<Coupon>? results,
  }) {
    return CouponListResponse(
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      results: results ?? this.results,
    );
  }
}
