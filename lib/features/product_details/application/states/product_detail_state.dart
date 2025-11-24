import 'package:equatable/equatable.dart';

import '../../domain/entities/product_variant.dart';
import '../../domain/entities/product_base.dart';

/// Status enum for product detail state
enum ProductDetailStatus { initial, loading, data, empty, error }

/// State for product detail
/// Uses Equatable for value-based comparison so Riverpod change detection works reliably.
/// When API returns new data, Riverpod will detect the state change and trigger rebuilds.
class ProductDetailState extends Equatable {
  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.productDetail,
    this.productBase,
    this.reviews,
    this.isInWishlist = false,
    this.quantity = 0,
    this.errorMessage,
    this.lastFetchedAt,
    this.lastSyncedAt,
    this.isRefreshing = false,
    this.eTag,
    this.lastModified,
    this.refreshStartedAt,
    this.refreshEndedAt,
  });

  final ProductDetailStatus status;
  final ProductVariant? productDetail;
  final ProductBase? productBase;
  final List<ProductVariantReview>? reviews;
  final bool isInWishlist;
  final int quantity;
  final String? errorMessage;
  final DateTime? lastFetchedAt;
  final DateTime? lastSyncedAt;
  final bool isRefreshing;
  final String? eTag;
  final String? lastModified;
  final DateTime? refreshStartedAt;
  final DateTime? refreshEndedAt;

  /// Copy with method for immutable updates
  ProductDetailState copyWith({
    ProductDetailStatus? status,
    ProductVariant? productDetail,
    ProductBase? productBase,
    List<ProductVariantReview>? reviews,
    bool? isInWishlist,
    int? quantity,
    String? errorMessage,
    DateTime? lastFetchedAt,
    DateTime? lastSyncedAt,
    bool? isRefreshing,
    String? eTag,
    String? lastModified,
    DateTime? refreshStartedAt,
    DateTime? refreshEndedAt,
    bool resetRefreshStartedAt = false,
    bool resetRefreshEndedAt = false,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      productDetail: productDetail ?? this.productDetail,
      productBase: productBase ?? this.productBase,
      reviews: reviews ?? this.reviews,
      isInWishlist: isInWishlist ?? this.isInWishlist,
      quantity: quantity ?? this.quantity,
      errorMessage: errorMessage ?? this.errorMessage,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      eTag: eTag ?? this.eTag,
      lastModified: lastModified ?? this.lastModified,
      refreshStartedAt: resetRefreshStartedAt
          ? null
          : (refreshStartedAt ?? this.refreshStartedAt),
      refreshEndedAt: resetRefreshEndedAt
          ? null
          : (refreshEndedAt ?? this.refreshEndedAt),
    );
  }

  /// Check if state is loading
  bool get isLoading => status == ProductDetailStatus.loading;

  /// Check if state has data
  bool get hasData => status == ProductDetailStatus.data;

  /// Check if state has error
  bool get hasError => status == ProductDetailStatus.error;

  /// Check if product is in cart (quantity > 0)
  bool get isInCart => quantity > 0;

  /// Equatable props for value-based comparison.
  /// Riverpod uses these to detect when state changes and rebuild widgets.
  @override
  List<Object?> get props => [
    status,
    productDetail,
    productBase,
    reviews,
    isInWishlist,
    quantity,
    errorMessage,
    lastFetchedAt,
    lastSyncedAt,
    isRefreshing,
    eTag,
    lastModified,
    refreshStartedAt,
    refreshEndedAt,
  ];

  @override
  String toString() =>
      'ProductDetailState(status: $status, hasData: $hasData, '
      'quantity: $quantity, isInWishlist: $isInWishlist)';
}
