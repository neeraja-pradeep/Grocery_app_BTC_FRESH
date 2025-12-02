// lib/features/home/domain/repositories/home_repository.dart

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/banner.dart';
import '../entities/category.dart';
import '../entities/product.dart';
import '../entities/product_variant.dart';
import '../entities/user_address.dart';

// Placeholder for UserAddress if not yet created
// import 'package:grocery_app/features/home/domain/entities/user_address.dart';
// Temporary placeholder class

class PaginatedResult<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginatedResult({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
}

abstract class HomeRepository {
  Future<Either<Failure, PaginatedResult<Category>>> getCategories({
    int page = 1,
  });

  // --- Discounted Products (Mega Fresh Offers) ---

  Future<Either<Failure, List<ProductVariant>>> getDiscountedProducts({
    String? parentCategoryName,
    double? minPrice,
    double? maxPrice,
    String ordering = '-discounted_price', // highest discount first
  });

  // --- Banners ---
  /// Returns paginated list of banners.
  /// Logic: For home screen, use the first active banner from page 1.
  Future<Either<Failure, List<Banner>>> getBanners({int page = 1});

  // --- Search ---
  /// Searches for product variants based on a query string.
  Future<Either<Failure, List<ProductVariant>>> searchProducts({
    required String query,
    int page = 1,
  });

  /// Searches for products (with variants) based on a query string.
  Future<Either<Failure, PaginatedResult<Product>>> searchProductsWithVariants({
    required String query,
    int page = 1,
  });

  // --- Address ---
  /// Returns the user's selected address (or null if skipped/not set).
  Future<Either<Failure, UserAddress?>> getSelectedAddress();

  // --- Best Deals ---
  /// Fetches a list of specific product variants marked as "Best Deals".
  Future<Either<Failure, List<ProductVariant>>> getBestDeals({int limit = 10});

  // --- Cache Management ---
  /// Clears all cached home data to force fresh data on next request
  Future<void> clearCache();
}
