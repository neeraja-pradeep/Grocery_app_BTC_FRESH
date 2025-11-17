// features/home/application/usecases/load_home_bootstrap_usecase.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_app/features/home/domain/repositories/home_repository.dart';
import 'package:new_app/features/home/application/providers/home_provider.dart';
import 'package:new_app/features/home/infrastructure/repositories/home_repostory_impl.dart';

class LoadHomeBootstrapUsecase {
  final HomeRepository _repository;
  final CatalogController _catalogController;
  final HomeBootstrapController _bootstrapController;

  LoadHomeBootstrapUsecase({
    required HomeRepository repository,
    required CatalogController catalogController,
    required HomeBootstrapController bootstrapController,
  }) : _repository = repository,
       _catalogController = catalogController,
       _bootstrapController = bootstrapController;

  /// Executes the home screen bootstrap logic with cache-first approach.
  Future<void> execute() async {
    try {
      // Always set loading state at the beginning
      _bootstrapController.setLoading(true);

      // print('Bootstrap: Starting cache-first data loading...');

      // Step 1: Try to load from cache first
      final cachedCategories = await _repository.loadCachedCategories();
      final cachedDeals = await _repository.loadCachedBestDeals();
      final cachedOffers = await _repository.loadCachedMegaOffers();

      final hasCache =
          (cachedCategories?.isNotEmpty ?? false) ||
          (cachedDeals?.isNotEmpty ?? false) ||
          (cachedOffers?.isNotEmpty ?? false);

      if (hasCache) {
        // print('Bootstrap: Found cached data, loading immediately...');
        _catalogController.setAllData(
          categories: cachedCategories ?? [],
          deals: cachedDeals ?? [],
          offers: cachedOffers ?? [],
        );
        _bootstrapController.markBootComplete();
        // print(
        //   'Bootstrap: Cached data loaded, now fetching fresh data in background...',
        // );
      }

      // Step 2: Fetch fresh data from API (either as primary or background refresh)
      try {
        // print('Bootstrap: Fetching fresh data from API...');

        final categories = await _repository.getCategories();
        final deals = await _repository.getBestDeals();
        final offers = await _repository.getMegaOffers();

        // print(
        //   'Bootstrap: Got ${categories.length} categories, ${deals.length} deals, ${offers.length} offers',
        // );

        // Cache the fresh data
        await Future.wait([
          _repository.cacheCategories(categories),
          _repository.cacheBestDeals(deals),
          _repository.cacheMegaOffers(offers),
        ]);

        // Update the state with fresh data
        _catalogController.setAllData(
          categories: categories,
          deals: deals,
          offers: offers,
        );

        _bootstrapController.markBootComplete();
        // print('Bootstrap: Fresh data loaded and cached successfully');
      } catch (apiError) {
        // print('Bootstrap: API fetch failed: $apiError');

        if (!hasCache) {
          // No cache and API failed - show empty state, not error
          // print('Bootstrap: No cache available, showing empty state');
          _catalogController.setAllData(categories: [], deals: [], offers: []);
          _bootstrapController.markBootComplete();
        } else {
          // We have cache, so just log the error but don't show error state
          // print(
          // 'Bootstrap: API failed but cache is available, keeping cached data',
          // );
          _bootstrapController.markBootComplete();
        }
      }
    } catch (e) {
      // print('Bootstrap: Critical error: $e');
      // print('Stack trace: $stackTrace');

      // Only show error state for critical failures (like cache corruption)
      _catalogController.setError('Critical error: $e');
      _bootstrapController.setError(e.toString());
    }
  }
}

// Provider for the use case
final loadHomeBootstrapUsecaseProvider = Provider<LoadHomeBootstrapUsecase>((
  ref,
) {
  return LoadHomeBootstrapUsecase(
    repository: ref.watch(homeRepositoryProvider),
    catalogController: ref.watch(catalogControllerProvider.notifier),
    bootstrapController: ref.watch(homeBootstrapControllerProvider.notifier),
  );
});
