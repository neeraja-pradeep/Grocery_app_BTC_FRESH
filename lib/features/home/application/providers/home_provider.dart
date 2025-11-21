// lib/features/home/application/providers/home_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:new_app/core/error/failure.dart';
import 'package:new_app/features/home/domain/entities/banner.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/category_discount_group.dart';
import 'package:new_app/features/home/domain/entities/product_variant.dart';
import 'package:new_app/features/home/domain/entities/user_address.dart';
import 'package:new_app/features/home/domain/repositories/home_repository.dart';
import 'package:new_app/features/home/infrastructure/repositories/home_repostory_impl.dart';

// Import the sealed state classes
import '../states/home_state.dart';
import '../states/search_state.dart';

// ----------------------------------------------------------------------
// 1. Home Notifier (Manages the entire Home Screen State)
// ----------------------------------------------------------------------

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repository;

  HomeNotifier({required HomeRepository repository})
    : _repository = repository,
      super(const HomeState.initial()) {
    // Load home screen data on app start
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    // Only set loading if we are in initial or error state
    state.maybeMap(
      refreshing: (_) {}, // Don't overwrite refreshing state with loading
      orElse: () => state = const HomeState.loading(),
    );

    // Load all sections concurrently
    final results = await Future.wait([
      _repository.getCategories(page: 1),
      _repository.getSelectedAddress(),
      _repository.getBestDeals(limit: 10),
      _repository.getDiscountedProductsByCategory(
        ordering: '-discounted_price',
      ),
      _repository.getBanners(
        page: 1,
      ), // Used getBanners instead of getActiveAdvertisement
    ]);

    // Process results
    final categoriesResult =
        results[0] as Either<Failure, PaginatedResult<Category>>;
    final addressResult = results[1] as Either<Failure, UserAddress?>;
    final bestDealsResult = results[2] as Either<Failure, List<ProductVariant>>;
    final discountsResult =
        results[3] as Either<Failure, List<CategoryDiscountGroup>>;
    final bannersResult = results[4] as Either<Failure, List<Banner>>;

    // Check for critical failures (Categories are critical)
    if (categoriesResult.isLeft()) {
      final failure = categoriesResult.getLeft().getOrElse(
        () => const ServerFailure('Unknown Error'),
      );

      state = HomeState.error(
        failure: failure,
        previousState: state, // Keep old data visible if available
      );
      return;
    }

    // Extract successful data (use defaults for non-critical failures)
    final categories = categoriesResult
        .getRight()
        .getOrElse(() => PaginatedResult(count: 0, results: []))
        .results;
    final address = addressResult.getRight().getOrElse(() => null);
    final bestDeals = bestDealsResult.getRight().getOrElse(() => []);
    final discounts = discountsResult.getRight().getOrElse(() => []);

    // Debug output
    // print('DEBUG: Categories loaded: ${categories.length}');
    // print('DEBUG: Best deals loaded: ${bestDeals.length}');
    // print('DEBUG: Discount groups loaded: ${discounts.length}');

    // Logic: Use the first banner as the "active ad" for now, or null
    final banners = bannersResult.getRight().getOrElse(() => []);
    final activeAd = banners.isNotEmpty ? banners.first : null;

    state = HomeState.loaded(
      categories: categories,
      selectedAddress: address,
      bestDeals: bestDeals,
      discountGroups: discounts,
      activeAd: activeAd,
      categoriesLoading: false,
      bestDealsLoading: false,
      discountsLoading: false,
    );
  }

  Future<void> refresh() async {
    // Only refresh if we have data loaded
    state.mapOrNull(
      loaded: (loadedState) {
        state = HomeState.refreshing(
          categories: loadedState.categories,
          selectedAddress: loadedState.selectedAddress,
          bestDeals: loadedState.bestDeals,
          discountGroups: loadedState.discountGroups,
          activeAd: loadedState.activeAd,
        );
        _loadHomeData();
      },
      error: (_) => _loadHomeData(), // Retry on error
    );
  }

  Future<void> clearCacheAndRefresh() async {
    // Clear Hive cache first
    await _repository.clearCache();

    // Then refresh data
    await refresh();
  }

  Future<void> reloadAddress() async {
    // Called when user updates address in profile/settings
    final result = await _repository.getSelectedAddress();

    result.fold(
      (failure) {
        // Keep current address on error, maybe show a snackbar in UI
      },
      (address) {
        state.mapOrNull(
          loaded: (loadedState) {
            state = loadedState.copyWith(selectedAddress: address);
          },
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// 2. Search Notifier (Manages Search Logic)
// ----------------------------------------------------------------------

class SearchNotifier extends StateNotifier<SearchState> {
  final HomeRepository _repository;

  SearchNotifier({required HomeRepository repository})
    : _repository = repository,
      super(const SearchState.initial()) {
    // Optional: Load history on init?
    // _loadHistory();
  }

  void startSearch(String query, {bool isVoice = false}) {
    if (query.isEmpty) return;

    state = SearchState.loading(query: query, isVoiceSearch: isVoice);
    performSearch(query);
  }

  Future<void> performSearch(String query) async {
    final result = await _repository.searchProducts(query: query);

    result.fold(
      (failure) => state = SearchState.error(failure: failure, query: query),
      (products) {
        if (products.isEmpty) {
          state = SearchState.empty(query: query);
        } else {
          state = SearchState.loaded(
            query: query,
            results: products,
            hasMore: false, // Pagination logic can be added later
          );
        }
      },
    );
  }

  void clearSearch() {
    state = const SearchState.initial();
  }
}

// ----------------------------------------------------------------------
// 3. Providers Definition
// ----------------------------------------------------------------------

// Replaces 'homeProvider' and 'catalogControllerProvider'
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return HomeNotifier(repository: repository);
});

// Replaces 'searchControllerProvider'
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  final repository = ref.watch(homeRepositoryProvider);
  return SearchNotifier(repository: repository);
});

// ----------------------------------------------------------------------
// 4. Selectors (Helpers for UI optimization)
// ----------------------------------------------------------------------

// Example: Watch only categories to avoid rebuilding entire home screen
final categoriesProvider = Provider<List<Category>>((ref) {
  final homeState = ref.watch(homeProvider);
  return homeState.maybeMap(
    loaded: (s) => s.categories,
    refreshing: (s) => s.categories,
    orElse: () => [],
  );
});

final activeAdProvider = Provider<Banner?>((ref) {
  final homeState = ref.watch(homeProvider);
  return homeState.maybeMap(
    loaded: (s) => s.activeAd,
    refreshing: (s) => s.activeAd,
    orElse: () => null,
  );
});
