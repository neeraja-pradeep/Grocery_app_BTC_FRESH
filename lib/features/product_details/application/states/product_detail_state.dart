import '../../domain/entities/product_detail.dart';

/// Status enum for product detail state
enum ProductDetailStatus { initial, loading, data, empty, error }

/// State for product detail
class ProductDetailState {
  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.productDetail,
    this.reviews,
    this.isInWishlist = false,
    this.quantity = 0,
    this.errorMessage,
    this.lastFetchedAt,
  });

  final ProductDetailStatus status;
  final ProductDetail? productDetail;
  final List<ProductReview>? reviews;
  final bool isInWishlist;
  final int quantity;
  final String? errorMessage;
  final DateTime? lastFetchedAt;

  /// Copy with method for immutable updates
  ProductDetailState copyWith({
    ProductDetailStatus? status,
    ProductDetail? productDetail,
    List<ProductReview>? reviews,
    bool? isInWishlist,
    int? quantity,
    String? errorMessage,
    DateTime? lastFetchedAt,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      productDetail: productDetail ?? this.productDetail,
      reviews: reviews ?? this.reviews,
      isInWishlist: isInWishlist ?? this.isInWishlist,
      quantity: quantity ?? this.quantity,
      errorMessage: errorMessage ?? this.errorMessage,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
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

  @override
  String toString() =>
      'ProductDetailState(status: $status, hasData: $hasData, '
      'quantity: $quantity, isInWishlist: $isInWishlist)';
}
