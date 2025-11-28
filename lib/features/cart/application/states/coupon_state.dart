import 'package:equatable/equatable.dart';
import '../../domain/entities/coupon.dart';

/// Status of coupon list data
enum CouponStatus { initial, loading, data, error, empty }

/// State for coupon list feature
/// Manages coupon list data, loading states, and refresh indicators
class CouponState extends Equatable {
  const CouponState({
    this.status = CouponStatus.initial,
    this.couponList,
    this.errorMessage,
    this.lastSyncedAt,
    this.isRefreshing = false,
    this.refreshStartedAt,
    this.refreshEndedAt,
  });

  final CouponStatus status;
  final CouponListResponse? couponList;
  final String? errorMessage;
  final DateTime? lastSyncedAt;
  final bool isRefreshing;
  final DateTime? refreshStartedAt;
  final DateTime? refreshEndedAt;

  /// Convenience getters
  bool get isLoading => status == CouponStatus.loading;
  bool get hasData => status == CouponStatus.data && couponList != null;
  bool get hasError => status == CouponStatus.error;
  bool get isEmpty => status == CouponStatus.empty;

  /// Get list of coupons
  List<Coupon> get coupons => couponList?.results ?? [];

  /// Get only active/available coupons
  List<Coupon> get activeCoupons =>
      coupons.where((c) => c.isAvailable).toList();

  @override
  List<Object?> get props => [
    status,
    couponList,
    errorMessage,
    lastSyncedAt,
    isRefreshing,
    refreshStartedAt,
    refreshEndedAt,
  ];

  CouponState copyWith({
    CouponStatus? status,
    CouponListResponse? couponList,
    String? errorMessage,
    DateTime? lastSyncedAt,
    bool? isRefreshing,
    DateTime? refreshStartedAt,
    DateTime? refreshEndedAt,
    bool resetRefreshStartedAt = false,
    bool resetRefreshEndedAt = false,
  }) {
    return CouponState(
      status: status ?? this.status,
      couponList: couponList ?? this.couponList,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshStartedAt: resetRefreshStartedAt
          ? null
          : (refreshStartedAt ?? this.refreshStartedAt),
      refreshEndedAt: resetRefreshEndedAt
          ? null
          : (refreshEndedAt ?? this.refreshEndedAt),
    );
  }
}
