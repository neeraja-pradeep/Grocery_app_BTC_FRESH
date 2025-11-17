// application/usecases/search_products_usecase.dart

// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:new_app/features/home/domain/repositories/home_repository.dart';
import 'package:new_app/features/home/infrastructure/repositories/home_repostory_impl.dart';
import '../providers/home_provider.dart';

// Use Case Class
class SearchProductsUsecase {
  final HomeRepository _repository;
  final SearchController _searchController;
  Timer? _debounceTimer;

  static const Duration _debounceDuration = Duration(milliseconds: 300);

  SearchProductsUsecase({
    required HomeRepository repository,
    required SearchController searchController,
  }) : _repository = repository,
       _searchController = searchController;

  /// Debounces the input, calls the API, writes to search history, and updates results.
  Future<void> search(String query) async {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    if (query.isEmpty) {
      _searchController.clearResults();
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () async {
      _searchController.setLoading(true);

      try {
        final results = await _repository.searchProducts(query);

        _searchController.setResults(results);

        // Write history using the controller, which delegates to the repository
        await _searchController.addToHistory(query);
      } catch (e) {
        // print('Error searching products: $e');
        _searchController.setError('Search failed. Please try again.');
      } finally {
        _searchController.setLoading(false);
      }
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

// --- Provider to instantiate the use case ---
final searchProductsUsecaseProvider =
    Provider.autoDispose<SearchProductsUsecase>((ref) {
      final usecase = SearchProductsUsecase(
        repository: ref.watch(homeRepositoryProvider),
        searchController: ref.watch(searchControllerProvider.notifier),
      );
      ref.onDispose(usecase.dispose);
      return usecase;
    });
