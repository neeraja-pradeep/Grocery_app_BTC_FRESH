// features/home/infrastructure/data_sources/local/home_local_data_source.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/product.dart';
import 'package:new_app/features/home/domain/entities/offer.dart';

/// The abstract contract for the local Home data source.
/// This contract defines the methods for local caching (persistence).
abstract class HomeLocalDataSource {
  // Category operations
  Future<List<Category>?> loadCategories();
  Future<void> saveCategories(List<Category> categories);

  // Best Deals operations
  Future<List<Product>?> loadBestDeals();
  Future<void> saveBestDeals(List<Product> deals);

  // Mega Offers operations
  Future<List<Offer>?> loadMegaOffers();
  Future<void> saveMegaOffers(List<Offer> offers);

  // Search History operations
  Future<List<String>> getSearchHistory();
  Future<void> saveSearchHistory(String query);
  Future<void> clearSearchHistory();
}

/// Concrete implementation of the [HomeLocalDataSource] using in-memory variables
/// as a placeholder for a real local database (like Hive/Isar).
class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  // In-memory cache variables
  List<Category>? _cachedCategories;
  List<Product>? _cachedBestDeals;
  List<Offer>? _cachedMegaOffers;
  List<String> _searchHistory = []; // Already defined in original repository

  // --- Category Cache ---
  @override
  Future<List<Category>?> loadCategories() async =>
      Future.value(_cachedCategories);

  @override
  Future<void> saveCategories(List<Category> categories) async {
    _cachedCategories = categories;
  }

  // --- Best Deals Cache ---
  @override
  Future<List<Product>?> loadBestDeals() async =>
      Future.value(_cachedBestDeals);

  @override
  Future<void> saveBestDeals(List<Product> deals) async {
    _cachedBestDeals = deals;
  }

  // --- Mega Offers Cache ---
  @override
  Future<List<Offer>?> loadMegaOffers() async =>
      Future.value(_cachedMegaOffers);

  @override
  Future<void> saveMegaOffers(List<Offer> offers) async {
    _cachedMegaOffers = offers;
  }

  // --- Search History ---
  @override
  Future<List<String>> getSearchHistory() async {
    return Future.value(_searchHistory);
  }

  @override
  Future<void> saveSearchHistory(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    _searchHistory.removeWhere((q) => q.toLowerCase() == normalizedQuery);
    _searchHistory.insert(0, query.trim());
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
  }

  @override
  Future<void> clearSearchHistory() async {
    _searchHistory = [];
  }
}

// --- Riverpod Provider for Dependency Injection ---

/// Provides the concrete implementation of the local Home data source.
final homeLocalDataSourceProvider = Provider<HomeLocalDataSource>((ref) {
  return HomeLocalDataSourceImpl();
});
