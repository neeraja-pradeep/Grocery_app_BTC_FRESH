// lib/features/home/application/providers/home_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';
import '../../domain/entities/banner.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product_variant.dart';
import '../../domain/entities/user_address.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_repository_provider.dart';
import '../states/home_state.dart';
import '../states/search_state.dart';
import '../usecases/group_products_by_category_usecase.dart';

// ----------------------------------------------------------------------
// 1. Home Notifier (Manages the entire Home Screen State)
// ----------------------------------------------------------------------

class HomeNotifier extends Notifier<HomeState> {
  late final HomeRepository _repository;
  late final GroupProductsByCategoryUseCase _groupUseCase;

  @override
  HomeState build() {
    _repository = ref.watch(homeRepositoryProvider);
    _groupUseCase = ref.watch(groupProductsUseCaseProvider);
    Future.microtask(_loadHomeData);
    return const HomeState.initial();
  }

  Future<void> _loadHomeData({UserAddress? preservedAddress}) async {
    // Only set loading if we are in initial or error state
    state.maybeMap(
      refreshing: (_) {}, // Don't overwrite refreshing state with loading
      orElse: () => state = const HomeState.loading(),
    );

    // Load all sections concurrently
    // Skip address fetch if we have a preserved address (during refresh)
    final results = await Future.wait([
      _repository.getCategories(page: 1),
      preservedAddress != null
          ? Future.value(Right<Failure, UserAddress?>(preservedAddress))
          : _repository.getSelectedAddress().timeout(
              const Duration(seconds: 10),
              onTimeout: () => const Right(null),
            ),
      _repository.getBestDeals(limit: 10),
      _repository.getDiscountedProducts(ordering: '-discounted_price'),
      _repository.getBanners(page: 1),
    ]);

    // Process results
    final categoriesResult = results[0] as Either<Failure, List<Category>>;
    final addressResult = results[1] as Either<Failure, UserAddress?>;
    final bestDealsResult = results[2] as Either<Failure, List<ProductVariant>>;
    final discountedVariantsResult =
        results[3] as Either<Failure, DiscountedProductsResult>;
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
    final categories = categoriesResult.getRight().getOrElse(() => []);
    final address = addressResult.getRight().getOrElse(() => null);
    final bestDeals = bestDealsResult.getRight().getOrElse(() => []);
    final discountedResult = discountedVariantsResult.getRight().getOrElse(
      () => const DiscountedProductsResult(
        variants: [],
        productCategoryMap: {},
      ),
    );

    // Apply business logic via UseCase to group products by category
    final discounts = _groupUseCase.execute(
      variants: discountedResult.variants,
      categories: categories,
      productCategoryMap: discountedResult.productCategoryMap,
    );

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
    final currentState = state;
    if (currentState is HomeLoaded) {
      state = HomeState.refreshing(
        categories: currentState.categories,
        selectedAddress: currentState.selectedAddress,
        bestDeals: currentState.bestDeals,
        discountGroups: currentState.discountGroups,
        activeAd: currentState.activeAd,
      );
      // Preserve current address during refresh (buggy API returns wrong address)
      await _loadHomeData(preservedAddress: currentState.selectedAddress);
    } else if (currentState is HomeError) {
      // Retry on error - fetch fresh address
      await _loadHomeData();
    }
  }

  Future<void> clearCacheAndRefresh() async {
    // Clear Hive cache first
    await _repository.clearCache();

    // Then refresh data (preserve address)
    await refresh();
  }

  /// Update address in the current state
  void updateAddressInState(UserAddress? address) {
    final currentState = state;
    if (currentState is HomeLoaded) {
      state = currentState.copyWith(selectedAddress: address);
    } else if (currentState is HomeRefreshing) {
      state = HomeState.loaded(
        categories: currentState.categories,
        selectedAddress: address,
        bestDeals: currentState.bestDeals,
        discountGroups: currentState.discountGroups,
        activeAd: currentState.activeAd,
      );
    }
  }

  Future<void> reloadAddress() async {
    // Called when user updates address in profile/settings
    // Optimized: Only fetch address without clearing entire cache
    final result = await _repository.getSelectedAddress();

    result.fold(
      (failure) {
        Logger.warning('Failed to reload address', error: failure);
      },
      (address) {
        // Immediately update state for instant UI feedback
        updateAddressInState(address);
      },
    );
  }
}

// ----------------------------------------------------------------------
// 2. Search Notifier (Manages Search Logic)
// ----------------------------------------------------------------------

class SearchNotifier extends AutoDisposeNotifier<SearchState> {
  late final HomeRepository _repository;

  @override
  SearchState build() {
    _repository = ref.watch(homeRepositoryProvider);
    return const SearchState.initial();
  }

  void startSearch(String query, {bool isVoice = false}) {
    if (query.isEmpty) return;

    if (isVoice) {
      state = const SearchState.listening(isVoiceSearch: true);
    }
    state = SearchState.loading(query: query, isVoiceSearch: isVoice);
    performSearch(query);
  }

  Future<void> performSearch(String query) async {
    try {
      final result = await _repository
          .searchProducts(query: query)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => const Left(TimeoutFailure()),
          );

      result.fold(
        (failure) => state = SearchState.error(failure: failure, query: query),
        (variants) {
          if (variants.isEmpty) {
            state = SearchState.empty(query: query);
          } else {
            final sortedVariants = _sortSearchResults(variants, query);
            state = SearchState.loaded(
              query: query,
              results: sortedVariants,
              hasMore: false,
            );
          }
        },
      );
    } catch (e) {
      Logger.error('Unexpected search error', error: e);
      state = SearchState.error(
        failure: UnknownFailure(e.toString()),
        query: query,
      );
    }
  }

  /// Sort search results by relevance:
  /// 1. Products starting with query (case-insensitive)
  /// 2. Products containing query elsewhere
  List<ProductVariant> _sortSearchResults(
    List<ProductVariant> variants,
    String query,
  ) {
    final queryLower = query.toLowerCase();

    // Separate into two groups
    final startsWithQuery = <ProductVariant>[];
    final containsQuery = <ProductVariant>[];

    for (final variant in variants) {
      final nameLower = variant.name.toLowerCase();

      if (nameLower.startsWith(queryLower)) {
        startsWithQuery.add(variant);
      } else {
        containsQuery.add(variant);
      }
    }

    // Return starts-with first, then contains
    return [...startsWithQuery, ...containsQuery];
  }

  void clearSearch() {
    state = const SearchState.initial();
  }
}

// ----------------------------------------------------------------------
// 3. Providers Definition
// ----------------------------------------------------------------------

// Replaces 'homeProvider' and 'catalogControllerProvider'
final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

// UseCase provider
final groupProductsUseCaseProvider = Provider<GroupProductsByCategoryUseCase>((
  ref,
) {
  return GroupProductsByCategoryUseCase();
});

// Replaces 'searchControllerProvider'
final searchProvider =
    AutoDisposeNotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

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

final isGuestProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is GuestMode;
});
