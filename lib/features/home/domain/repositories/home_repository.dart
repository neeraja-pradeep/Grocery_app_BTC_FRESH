import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/product.dart';
import 'package:new_app/features/home/domain/entities/offer.dart';

/// Defines the contract for all data operations related to the Home Screen.
abstract class HomeRepository {
  // --- Remote Fetch Operations ---
  Future<List<Category>> getCategories();
  Future<List<Product>> getBestDeals();
  Future<List<Offer>> getMegaOffers();
  Future<List<Product>> searchProducts(String query);

  // --- Cache Write Operations (Local) ---
  Future<void> cacheCategories(List<Category> categories);
  Future<void> cacheBestDeals(List<Product> products);
  Future<void> cacheMegaOffers(List<Offer> offers);

  // --- Cache Read Operations (Local) ---
  Future<List<Category>?> loadCachedCategories();
  Future<List<Product>?> loadCachedBestDeals();
  Future<List<Offer>?> loadCachedMegaOffers();

  // --- Search History Operations (Local) ---
  Future<void> saveSearchHistory(String query);
  Future<List<String>> getSearchHistory();
  Future<void> clearSearchHistory();
}
