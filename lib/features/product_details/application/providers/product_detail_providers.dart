import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/core/network/api_client.dart';
import 'package:grocery_app/core/storage/hive/boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/repositories/product_detail_repository.dart';
import '../../infrastructure/data_sources/local/product_detail_local_data_source.dart';
import '../../infrastructure/data_sources/remote/product_detail_remote_data_source.dart';
import '../../infrastructure/repositories/product_detail_repository_impl.dart';
import '../states/product_detail_state.dart';

/// Riverpod Providers for Product Details Feature

/// Local data source provider
final productDetailLocalDataSourceProvider =
    Provider<ProductDetailLocalDataSource>((ref) {
      final box = Hive.box<dynamic>(AppHiveBoxes.cache);
      return ProductDetailLocalDataSourceImpl(box);
    });

/// Remote data source provider
final productDetailRemoteDataSourceProvider =
    Provider<ProductDetailRemoteDataSource>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return ProductDetailRemoteDataSourceImpl(apiClient);
    });

/// Repository provider
final productDetailRepositoryProvider = Provider<ProductDetailRepository>((
  ref,
) {
  final localDataSource = ref.watch(productDetailLocalDataSourceProvider);
  final remoteDataSource = ref.watch(productDetailRemoteDataSourceProvider);

  return ProductDetailRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

/// Product detail controller - manages product detail state
final productDetailControllerProvider =
    StateNotifierProvider.family<
      ProductDetailController,
      ProductDetailState,
      String
    >((ref, productId) {
      final repository = ref.watch(productDetailRepositoryProvider);
      return ProductDetailController(
        repository: repository,
        productId: productId,
      );
    });

/// State notifier for managing product detail
class ProductDetailController extends StateNotifier<ProductDetailState> {
  ProductDetailController({required this.repository, required this.productId})
    : super(const ProductDetailState()) {
    _loadProductDetail();
    _checkWishlist();
  }

  final ProductDetailRepository repository;
  final String productId;

  /// Load product detail from repository
  Future<void> _loadProductDetail() async {
    state = state.copyWith(status: ProductDetailStatus.loading);

    try {
      final productDetail = await repository.getProductDetail(productId);

      // Load reviews
      final reviews = await repository.getProductReviews(productId);

      state = state.copyWith(
        status: ProductDetailStatus.data,
        productDetail: productDetail,
        reviews: reviews,
        lastFetchedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: ProductDetailStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Check if product is in wishlist
  Future<void> _checkWishlist() async {
    try {
      final isInWishlist = await repository.isInWishlist(productId);
      state = state.copyWith(isInWishlist: isInWishlist);
    } catch (e) {
      // Silently fail for wishlist check
    }
  }

  /// Refresh product detail data
  Future<void> refresh() async {
    await _loadProductDetail();
  }

  /// Increment quantity (add to cart)
  void incrementQuantity() {
    state = state.copyWith(quantity: state.quantity + 1);
  }

  /// Decrement quantity
  void decrementQuantity() {
    if (state.quantity > 0) {
      state = state.copyWith(quantity: state.quantity - 1);
    }
  }

  /// Set quantity
  void setQuantity(int quantity) {
    if (quantity >= 0) {
      state = state.copyWith(quantity: quantity);
    }
  }

  /// Toggle wishlist status
  Future<void> toggleWishlist() async {
    try {
      if (state.isInWishlist) {
        await repository.removeFromWishlist(productId);
        state = state.copyWith(isInWishlist: false);
      } else {
        await repository.addToWishlist(productId);
        state = state.copyWith(isInWishlist: true);
      }
    } catch (e) {
      // Handle error appropriately
      state = state.copyWith(errorMessage: 'Failed to update wishlist: $e');
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
