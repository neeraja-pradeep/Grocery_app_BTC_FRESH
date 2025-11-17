// application/usecases/fetch_mega_offers_usecase.dart

// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:new_app/features/home/domain/repositories/home_repository.dart';
import 'package:new_app/features/home/infrastructure/repositories/home_repostory_impl.dart';
import '../providers/home_provider.dart';

// Use Case Class
class FetchMegaOffersUsecase {
  final HomeRepository _repository;
  final CatalogController _catalogController;

  FetchMegaOffersUsecase({
    required HomeRepository repository,
    required CatalogController catalogController,
  }) : _repository = repository,
       _catalogController = catalogController;

  /// Fetches mega offers from the remote repository, caches them, and updates the state.
  Future<void> execute() async {
    try {
      final offers = await _repository
          .getMegaOffers(); // Use direct fetch method

      // 1. Cache the fetched data
      await _repository.cacheMegaOffers(offers);

      // 2. Update the CatalogController state
      _catalogController.setMegaOffers(offers);
    } catch (e) {
      // print('Error fetching mega offers: $e');
      _catalogController.setError('Failed to load mega offers.');
    }
  }
}

// --- Provider to instantiate the use case ---
final fetchMegaOffersUsecaseProvider = Provider<FetchMegaOffersUsecase>((ref) {
  return FetchMegaOffersUsecase(
    repository: ref.watch(homeRepositoryProvider),
    catalogController: ref.watch(catalogControllerProvider.notifier),
  );
});
