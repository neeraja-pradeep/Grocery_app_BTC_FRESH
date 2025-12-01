import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/repositories/category_product_repository.dart';
import '../../infrastructure/data_sources/local/category_product_local_data_source.dart';
import '../../infrastructure/data_sources/remote/category_product_remote_data_source.dart';
import '../../infrastructure/repositories/category_product_repository_impl.dart';
import '../states/category_product_state.dart';

/// ============================================================================
/// CATEGORY PRODUCTS LAST-MODIFIED UPDATE SYSTEM
/// ============================================================================
///
/// This implementation uses HTTP conditional requests to efficiently check
/// for updates without downloading unchanged product lists.
///
/// FLOW:
/// -----
/// 1. INITIAL LOAD (per category):
///    - Check local Hive cache with categoryId
///    - If empty, fetch from server (200 OK response)
///    - Extract Last-Modified header from response
///    - Save cache + Last-Modified to Hive with categoryId key
///
/// 2. CACHE STORAGE (Hive):
///    - categoryId: The category these products belong to
///    - products: List of product items
///    - lastSyncedAt: When we last checked
///    - lastModified: Server's Last-Modified header (for If-Modified-Since)
///    - eTag: Alternate validation mechanism
///    - count, next, previous: Pagination info
///
/// PER-CATEGORY CACHING:
/// --------------------
/// Each category's products are cached separately with key:
/// 'category_products_{categoryId}'
/// This means viewing multiple categories doesn't cause conflicts.
/// ============================================================================

final categoryProductLocalDataSourceProvider =
    Provider<CategoryProductLocalDataSource>((ref) {
      return CategoryProductLocalDataSource();
    });

final categoryProductRepositoryProvider = Provider<CategoryProductRepository>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  final localDataSource = ref.watch(categoryProductLocalDataSourceProvider);
  final remoteDataSource = CategoryProductRemoteDataSource(apiClient);

  return CategoryProductRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

final categoryProductControllerProvider =
    AutoDisposeNotifierProviderFamily<
      CategoryProductController,
      CategoryProductState,
      String
    >(CategoryProductController.new);

class CategoryProductController
    extends AutoDisposeFamilyNotifier<CategoryProductState, String> {
  CategoryProductRepository get _repository =>
      ref.read(categoryProductRepositoryProvider);

  bool _initialized = false;
  late String _categoryId;

  @override
  CategoryProductState build(String categoryId) {
    _categoryId = categoryId;
    if (!_initialized) {
      _initialized = true;
      Future<void>.microtask(_loadInitial);
    }

    ref.onDispose(_handleDispose);

    return CategoryProductState.initial();
  }

  Future<void> _loadInitial() async {
    final cached = await _repository.getCachedProducts(_categoryId);

    if (cached != null) {
      state = state.copyWith(
        status: cached.hasData
            ? CategoryProductStatus.data
            : CategoryProductStatus.empty,
        products: cached.products,
        lastSyncedAt: cached.lastSyncedAt,
        lastModified: cached.lastModified,
        isRefreshing: cached.isStale,
        totalCount: cached.totalCount,
        next: cached.next,
        previous: cached.previous,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        status: CategoryProductStatus.loading,
        isRefreshing: true,
        clearError: true,
      );
    }

    final shouldRefresh = cached == null || cached.isStale;
    if (shouldRefresh) {
      await _refreshInternal(forceRemote: cached == null);
    } else {
      state = state.copyWith(isRefreshing: false);
    }
  }

  Future<void> refresh({bool force = false}) async {
    await _refreshInternal(forceRemote: force);
  }

  Future<void> refreshIfStale() async {
    final lastSyncedAt = state.lastSyncedAt;
    final now = DateTime.now();

    if (lastSyncedAt == null ||
        now.difference(lastSyncedAt) >= _repository.cacheTtl) {
      await refresh();
    }
  }

  Future<void> _refreshInternal({required bool forceRemote}) async {
    if (state.isRefreshing && !forceRemote) return;

    final hasData = state.hasData;
    state = state.copyWith(
      status: hasData
          ? CategoryProductStatus.data
          : CategoryProductStatus.loading,
      isRefreshing: true,
      clearError: true,
    );

    try {
      final result = await _repository.syncProducts(
        _categoryId,
        forceRemote: forceRemote,
      );

      state = state.copyWith(
        status: result.hasData
            ? CategoryProductStatus.data
            : CategoryProductStatus.empty,
        products: result.products,
        lastSyncedAt: result.lastSyncedAt,
        lastModified: result.lastModified,
        isRefreshing: false,
        totalCount: result.totalCount,
        next: result.next,
        previous: result.previous,
        clearError: true,
      );
    } catch (error) {
      final message = _mapError(error);

      if (!hasData) {
        state = state.copyWith(
          status: CategoryProductStatus.error,
          isRefreshing: false,
          errorMessage: message,
        );
      } else {
        state = state.copyWith(isRefreshing: false, errorMessage: message);
      }
    }
  }

  String _mapError(Object error) {
    if (error is NetworkException) {
      return error.message;
    }
    if (error is FormatException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }

  void _handleDispose() {
    _initialized = false;
  }
}
