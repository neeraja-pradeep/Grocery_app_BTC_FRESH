// application/providers/home_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
// Infrastructure dependencies (assuming correct paths)
import 'package:new_app/features/home/infrastructure/repositories/home_repostory_impl.dart';
import 'package:new_app/features/home/infrastructure/data_sources/local/home_local_ds.dart'; // For cache service

// Application dependencies (for State and Entities)
// REMOVED 'as domain' ALIASES
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/product.dart';
import 'package:new_app/features/home/domain/entities/offer.dart';
import 'package:new_app/features/home/domain/repositories/home_repository.dart';

import '../states/home_state.dart';
import '../states/catalog_state.dart';
import '../states/search_state.dart';

// ----------------------------------------------------------------------
// 1. Controller Definitions
// ----------------------------------------------------------------------

typedef HomeCacheService = HomeLocalDataSource;

// --- CatalogController (Manages CatalogState) ---
class CatalogController extends StateNotifier<CatalogState> {
  CatalogController({required HomeRepository repository})
    : super(const CatalogState());

  bool get hasData => state.hasData;

  // Used unqualified names
  void setCategories(List<Category> categories) {
    state = state.copyWith(
      categories: categories,
      error: null,
      lastUpdated: DateTime.now(),
    );
  }

  void setBestDeals(List<Product> deals) {
    state = state.copyWith(
      bestDeals: deals,
      error: null,
      lastUpdated: DateTime.now(),
    );
  }

  void setMegaOffers(List<Offer> offers) {
    state = state.copyWith(
      megaOffers: offers,
      error: null,
      lastUpdated: DateTime.now(),
    );
  }

  void setError(String error) {
    state = state.copyWith(error: error, isRefreshing: false);
  }

  void setAllData({
    required List<Category> categories,
    required List<Product> deals,
    required List<Offer> offers,
  }) {
    state = state.copyWith(
      categories: categories,
      bestDeals: deals,
      megaOffers: offers,
      error: null,
      lastUpdated: DateTime.now(),
      isRefreshing: false,
    );
  }

  void updateAllData(
    List<Category> categories,
    List<Product> deals,
    List<Offer> offers,
  ) {
    setAllData(categories: categories, deals: deals, offers: offers);
  }
}

// --- HomeBootstrapController (No change needed here) ---
class HomeBootstrapController extends StateNotifier<HomeState> {
  HomeBootstrapController({required HomeRepository repository})
    : super(const HomeState());

  void setLoading(bool loading) {
    state = state.copyWith(isInitialLoading: loading, error: null);
  }

  void markBootComplete() {
    state = state.copyWith(
      isBootComplete: true,
      isInitialLoading: false,
      error: null,
    );
  }

  void setError(String error) {
    state = state.copyWith(
      error: error,
      isInitialLoading: false,
      isBootComplete: false,
    );
  }
}

// --- SearchController (Updated) ---
class SearchController extends StateNotifier<SearchState> {
  final HomeRepository _repository;
  SearchController({required HomeRepository repository})
    : _repository = repository,
      super(const SearchState()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _repository.getSearchHistory();
    state = state.copyWith(history: history);
  }

  void setLoading(bool loading) =>
      state = state.copyWith(isSearching: loading, error: null);
  // Used unqualified name
  void setResults(List<Product> results) =>
      state = state.copyWith(results: results, error: null);
  void clearResults() =>
      state = state.copyWith(results: [], query: '', error: null);
  void setError(String error) => state = state.copyWith(error: error);

  Future<void> addToHistory(String query) async {
    await _repository.saveSearchHistory(query);
    await _loadHistory();
  }
}

// ----------------------------------------------------------------------
// 2. Controller Providers
// ----------------------------------------------------------------------

final catalogControllerProvider =
    StateNotifierProvider<CatalogController, CatalogState>((ref) {
      final repository = ref.watch(homeRepositoryProvider);
      return CatalogController(repository: repository);
    });

final homeBootstrapControllerProvider =
    StateNotifierProvider<HomeBootstrapController, HomeState>((ref) {
      final repository = ref.watch(homeRepositoryProvider);
      return HomeBootstrapController(repository: repository);
    });

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
      final repository = ref.watch(homeRepositoryProvider);
      return SearchController(repository: repository);
    });

final homeCacheServiceProvider = Provider<HomeCacheService>((ref) {
  return ref.watch(homeLocalDataSourceProvider);
});

// ----------------------------------------------------------------------
// 3. Data Providers (State Selectors - Updated)
// ----------------------------------------------------------------------

/// Categories Provider (Reads from CatalogController state)
final categoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(
    catalogControllerProvider.select((state) => state.categories),
  );
});

/// Best Deals Provider (Reads from CatalogController state)
final bestDealsProvider = Provider<List<Product>>((ref) {
  return ref.watch(
    catalogControllerProvider.select((state) => state.bestDeals),
  );
});

/// Mega Offers Provider (Reads from CatalogController state)
final megaOffersProvider = Provider<List<Offer>>((ref) {
  return ref.watch(
    catalogControllerProvider.select((state) => state.megaOffers),
  );
});
