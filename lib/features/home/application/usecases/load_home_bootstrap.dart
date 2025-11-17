// application/usecases/load_home_bootstrap.dart

// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:new_app/features/home/domain/repositories/home_repository.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/product.dart';
import 'package:new_app/features/home/domain/entities/offer.dart';
import 'package:new_app/features/home/infrastructure/repositories/home_repostory_impl.dart';
import '../providers/home_provider.dart'; // Imports all controllers and providers

// Use Case Class
class LoadHomeBootstrap {
  final HomeRepository _repository;
  final HomeBootstrapController _homeController;
  final CatalogController _catalogController;

  LoadHomeBootstrap({
    required HomeRepository repository,
    required HomeBootstrapController homeController,
    required CatalogController catalogController,
    required HomeCacheService
    cacheService, // Keep parameter for compatibility but don't store
  }) : _repository = repository,
       _homeController = homeController,
       _catalogController = catalogController;

  /// Executes the home screen bootstrap logic.
  Future<void> execute() async {
    // Check if we have cached data
    final cachedCategories = await _repository.loadCachedCategories();
    final cachedDeals = await _repository.loadCachedBestDeals();
    final cachedOffers = await _repository.loadCachedMegaOffers();

    final hasCache =
        (cachedCategories?.isNotEmpty ?? false) ||
        (cachedDeals?.isNotEmpty ?? false) ||
        (cachedOffers?.isNotEmpty ?? false);

    if (hasCache) {
      // print(
      //   'Path 2: Cache exists -> Hydrate from Cache -> Background Refresh.',
      // );
      // Hydrate Riverpod state instantly from cache
      _catalogController.setAllData(
        categories: cachedCategories ?? [],
        deals: cachedDeals ?? [],
        offers: cachedOffers ?? [],
      );
      _homeController.markBootComplete(); // Show UI immediately

      _backgroundRefresh();
      return;
    }

    // No Cache exists (Empty Path)
    // print('Path 1: Empty Cache -> Fetch Remote -> Write Cache -> Show UI.');
    try {
      _homeController.setLoading(true);

      // Fetch all necessary data remotely in parallel
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getBestDeals(),
        _repository.getMegaOffers(),
      ]);

      final categories = results[0] as List<Category>;
      final deals = results[1] as List<Product>;
      final offers = results[2] as List<Offer>;

      // Update Riverpod state
      _catalogController.updateAllData(categories, deals, offers);

      // Write to cache using the repository
      await _repository.cacheCategories(categories);
      await _repository.cacheBestDeals(deals);
      await _repository.cacheMegaOffers(offers);

      _homeController.markBootComplete();
    } catch (e) {
      _homeController.setError(e.toString());
    } finally {
      _homeController.setLoading(false);
    }
  }

  /// Refreshes all data in the background and updates cache/state quietly.
  Future<void> _backgroundRefresh() async {
    try {
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getBestDeals(),
        _repository.getMegaOffers(),
      ]);

      final categories = results[0] as List<Category>;
      final deals = results[1] as List<Product>;
      final offers = results[2] as List<Offer>;

      _catalogController.updateAllData(categories, deals, offers);

      await _repository.cacheCategories(categories);
      await _repository.cacheBestDeals(deals);
      await _repository.cacheMegaOffers(offers);
      // print('Background refresh successful and cache updated.');
    } catch (e) {
      // print('Background refresh failed: $e');
    }
  }
}

// --- Provider to instantiate the use case ---
final loadHomeBootstrapProvider = Provider<LoadHomeBootstrap>((ref) {
  return LoadHomeBootstrap(
    repository: ref.watch(homeRepositoryProvider),
    homeController: ref.watch(homeBootstrapControllerProvider.notifier),
    catalogController: ref.watch(catalogControllerProvider.notifier),
    cacheService: ref.watch(homeCacheServiceProvider),
  );
});
