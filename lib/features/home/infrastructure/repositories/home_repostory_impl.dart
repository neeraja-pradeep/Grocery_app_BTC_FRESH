// features/home/infrastructure/repositories/home_repository_impl.dart

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/product.dart';
import 'package:new_app/features/home/domain/entities/offer.dart';
// NOTE: Assuming these interfaces are correctly defined in your Domain/Data Source layers.
import 'package:new_app/features/home/domain/repositories/home_repository.dart'; // Must be the Domain contract
import 'package:new_app/features/home/infrastructure/data_sources/remote/home_api.dart'; // Correct Remote DS
import 'package:new_app/features/home/infrastructure/data_sources/local/home_local_ds.dart'; // New Local DS

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;
  final HomeLocalDataSource _localDataSource;

  HomeRepositoryImpl({
    required HomeRemoteDataSource remoteDataSource,
    required HomeLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  // --- Remote Fetching & Search (Delegated) ---
  @override
  Future<List<Category>> getCategories() => _remoteDataSource.categoriesApi();

  @override
  Future<List<Product>> getBestDeals() => _remoteDataSource.bestDealsApi();

  @override
  Future<List<Offer>> getMegaOffers() => _remoteDataSource.megaOffersApi();

  @override
  Future<List<Product>> searchProducts(String query) =>
      _remoteDataSource.searchApi(query);

  // --- Cache Read Operations (Delegated to Local DS) ---

  @override
  Future<List<Category>?> loadCachedCategories() =>
      _localDataSource.loadCategories();

  @override
  Future<List<Product>?> loadCachedBestDeals() =>
      _localDataSource.loadBestDeals();

  @override
  Future<List<Offer>?> loadCachedMegaOffers() =>
      _localDataSource.loadMegaOffers();

  // --- Cache Write Operations (Delegated to Local DS) ---

  @override
  Future<void> cacheCategories(List<Category> categories) =>
      _localDataSource.saveCategories(categories);

  @override
  Future<void> cacheBestDeals(List<Product> products) =>
      _localDataSource.saveBestDeals(products);

  @override
  Future<void> cacheMegaOffers(List<Offer> offers) =>
      _localDataSource.saveMegaOffers(offers);

  // --- Search History Operations (Delegated to Local DS) ---

  @override
  Future<List<String>> getSearchHistory() =>
      _localDataSource.getSearchHistory();

  @override
  Future<void> saveSearchHistory(String query) =>
      _localDataSource.saveSearchHistory(query);

  @override
  Future<void> clearSearchHistory() => _localDataSource.clearSearchHistory();
}

// --- Repository Provider (Core Provider) ---
final homeRepositoryProvider = riverpod.Provider<HomeRepository>((
  riverpod.Ref ref,
) {
  // Implemented the actual Remote and Local data source injections here
  final remoteDs = ref.watch(
    homeRemoteDataSourceProvider,
  ); // Injected from home_api.dart
  final localDs = ref.watch(
    homeLocalDataSourceProvider,
  ); // Injected from home_local_data_source.dart

  return HomeRepositoryImpl(
    remoteDataSource: remoteDs,
    localDataSource: localDs,
  );
});

// The dummy classes are now completely removed.
