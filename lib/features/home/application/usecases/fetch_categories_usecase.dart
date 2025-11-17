// application/usecases/fetch_categories_usecase.dart

// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:new_app/features/home/domain/repositories/home_repository.dart';
import 'package:new_app/features/home/infrastructure/repositories/home_repostory_impl.dart';
import '../providers/home_provider.dart';

// Use Case Class
class FetchCategoriesUsecase {
  final HomeRepository _repository;
  final CatalogController _catalogController;

  FetchCategoriesUsecase({
    required HomeRepository repository,
    required CatalogController catalogController,
  }) : _repository = repository,
       _catalogController = catalogController;

  /// Fetches categories from the remote repository, caches them, and updates the state.
  Future<void> execute() async {
    try {
      final categories = await _repository
          .getCategories(); // Use direct fetch method

      // 1. Cache the fetched data using the repository
      await _repository.cacheCategories(categories);

      // 2. Update the CatalogController state
      _catalogController.setCategories(categories);
    } catch (e) {
      // print('Error fetching categories: $e');
      _catalogController.setError('Failed to load categories.');
    }
  }
}

// --- Provider to instantiate the use case ---
final fetchCategoriesUsecaseProvider = Provider<FetchCategoriesUsecase>((ref) {
  return FetchCategoriesUsecase(
    repository: ref.watch(homeRepositoryProvider),
    catalogController: ref.watch(catalogControllerProvider.notifier),
  );
});
