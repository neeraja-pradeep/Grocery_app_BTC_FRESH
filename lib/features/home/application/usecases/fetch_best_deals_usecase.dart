// application/usecases/fetch_best_deals_usecase.dart

// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:new_app/features/home/domain/repositories/home_repository.dart';
import 'package:new_app/features/home/infrastructure/repositories/home_repostory_impl.dart';
import '../providers/home_provider.dart';

// Use Case Class
class FetchBestDealsUsecase {
  final HomeRepository _repository;
  final CatalogController _catalogController;

  FetchBestDealsUsecase({
    required HomeRepository repository,
    required CatalogController catalogController,
  }) : _repository = repository,
       _catalogController = catalogController;

  /// Fetches best deals from the remote repository, caches them, and updates the state.
  Future<void> execute() async {
    try {
      final deals = await _repository.getBestDeals(); // Use direct fetch method

      // 1. Cache the fetched data
      await _repository.cacheBestDeals(deals);

      // 2. Update the CatalogController state
      _catalogController.setBestDeals(deals);
    } catch (e) {
      // print('Error fetching best deals: $e');
      _catalogController.setError('Failed to load best deals.');
    }
  }
}

// --- Provider to instantiate the use case ---
final fetchBestDealsUsecaseProvider = Provider<FetchBestDealsUsecase>((ref) {
  return FetchBestDealsUsecase(
    repository: ref.watch(homeRepositoryProvider),
    catalogController: ref.watch(catalogControllerProvider.notifier),
  );
});
