// lib/features/home/infrastructure/data_sources/local/home_local_ds.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../../../core/constants/hive_boxes.dart';
import '../../../../../core/storage/hive/keys.dart';
import '../../../domain/entities/banner.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product_variant.dart';
import '../../../domain/entities/user_address.dart';

/// Helper class for timestamped cache
/// You might need a Hive Adapter for this generic class, or store it as a Map.
/// To keep it simple and robust without generating Generic Adapters,
/// we will store the data in Hive as a Map: {'data': T, 'cachedAt': DateTime}
class CachedData<T> {
  final T data;
  final DateTime cachedAt;

  CachedData({required this.data, required this.cachedAt});

  bool isFresh(Duration ttl) {
    return DateTime.now().difference(cachedAt) < ttl;
  }
}

abstract class HomeLocalDataSource {
  // Categories
  Future<CachedData<List<Category>>?> getCategories();
  Future<void> saveCategories(List<Category> categories);

  // Discounted Products
  Future<CachedData<List<ProductVariant>>?> getDiscountedProducts({
    required String cacheKey,
  });
  Future<void> saveDiscountedProducts({
    required String cacheKey,
    required List<ProductVariant> products,
  });

  // Banners (Advertisement)
  Future<CachedData<List<Banner>>?> getBanners();
  Future<void> saveBanners(List<Banner> banners);

  // Best Deals
  Future<CachedData<List<ProductVariant>>?> getBestDeals();
  Future<void> saveBestDeals(List<ProductVariant> deals);

  // Address
  Future<UserAddress?> getSelectedAddress();
  Future<void> saveSelectedAddress(UserAddress address);
  Future<void> clearSelectedAddress();

  // Utility
  Future<void> clearAllHomeCache();
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  Box? _box;

  HomeLocalDataSourceImpl([this._box]);

  /// Safely get the Hive box with proper error handling
  Future<Box> get box async {
    // If we already have an open box, return it
    if (_box != null && _box!.isOpen) {
      return _box!;
    }

    // Check if the box is already open globally
    if (Hive.isBoxOpen(HiveBoxes.homeBox)) {
      _box = Hive.box(HiveBoxes.homeBox);
      return _box!;
    }

    // If not open, try to open it
    try {
      _box = await Hive.openBox(HiveBoxes.homeBox);
      return _box!;
    } catch (e) {
      throw StateError(
        'Failed to open Hive box "${HiveBoxes.homeBox}". '
        'Error: $e. '
        'Ensure Hive.initFlutter() is called before accessing the box.',
      );
    }
  }

  // --- Helper to wrap data as JSON ---
  // Store entities as JSON maps to avoid Hive adapter issues
  Map<String, dynamic> _wrapJson(List<Map<String, dynamic>> jsonData) {
    return {
      'data': jsonData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Future<CachedData<List<Category>>?> getCategories() async {
    final b = await box;
    final raw = b.get(HiveKeys.homeCategories);
    if (raw == null) return null;

    try {
      final rawMap = raw as Map<dynamic, dynamic>;
      final jsonList = (rawMap['data'] as List).cast<Map<String, dynamic>>();
      final categories = jsonList
          .map((json) => Category.fromJson(json))
          .toList();
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        rawMap['timestamp'] as int,
      );

      return CachedData(data: categories, cachedAt: timestamp);
    } catch (e) {
      // If parsing fails, return null to force fresh fetch
      return null;
    }
  }

  @override
  Future<void> saveCategories(List<Category> categories) async {
    final b = await box;
    // Convert categories to JSON before storing
    final jsonList = categories
        .map(
          (category) => {
            'id': category.id,
            'name': category.name,
            'slug': category.slug,
            'description': category.description,
            'background_image_url': category.backgroundImageUrl,
            'background_image_alt': category.backgroundImageAlt,
            'parent_id': category.parentId,
            'created_at': category.createdAt.toIso8601String(),
            'updated_at': category.updatedAt.toIso8601String(),
          },
        )
        .toList();

    await b.put(HiveKeys.homeCategories, _wrapJson(jsonList));
  }

  @override
  Future<CachedData<List<ProductVariant>>?> getDiscountedProducts({
    required String cacheKey,
  }) async {
    final b = await box;
    final fullKey = '${HiveKeys.homeDiscounts}$cacheKey';
    final raw = b.get(fullKey);
    if (raw == null) return null;

    try {
      final rawMap = raw as Map<dynamic, dynamic>;
      final jsonList = (rawMap['data'] as List).cast<Map<String, dynamic>>();
      final products = jsonList
          .map((json) => ProductVariant.fromJson(json))
          .toList();
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        rawMap['timestamp'] as int,
      );

      return CachedData(data: products, cachedAt: timestamp);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveDiscountedProducts({
    required String cacheKey,
    required List<ProductVariant> products,
  }) async {
    final b = await box;
    final fullKey = '${HiveKeys.homeDiscounts}$cacheKey';
    // Convert to JSON - simplified version, you may need to expand this
    final jsonList = products
        .map(
          (product) => {
            'id': product.id,
            'name': product.name,
            'product_id': product.productId,
            'sku': product.sku,
            'price': product.price,
            'discounted_price': product.discountedPrice,
            'stock_unit': product.stockUnit,
            'current_quantity': product.currentQuantity,
            'status': product.status,
            'media': product.media
                .map(
                  (m) => {
                    'id': m.id,
                    'file_path': m.imagePath,
                    'image': m.imageUrl,
                    'alt': m.alt,
                    'external_url': m.externalUrl,
                    'product_id': m.productId,
                    'created_at': m.createdAt.toIso8601String(),
                  },
                )
                .toList(),
            'product_description': product.productDescription,
            'product_rating': product.productRating,
            'quantity_limit_per_customer': product.quantityLimitPerCustomer,
            'is_preorder': product.isPreorder,
            'preorder_end_date': product.preorderEndDate?.toIso8601String(),
            'tags': product.tags,
            'created_at': product.createdAt.toIso8601String(),
            'updated_at': product.updatedAt.toIso8601String(),
          },
        )
        .toList();

    await b.put(fullKey, _wrapJson(jsonList));
  }

  @override
  Future<CachedData<List<Banner>>?> getBanners() async {
    final b = await box;
    // Using the Advertisement key for Banners
    final raw = b.get(HiveKeys.homeAdvertisement);
    if (raw == null) return null;

    try {
      final rawMap = raw as Map<dynamic, dynamic>;
      final jsonList = (rawMap['data'] as List).cast<Map<String, dynamic>>();
      final banners = jsonList.map((json) => Banner.fromJson(json)).toList();
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        rawMap['timestamp'] as int,
      );

      return CachedData(data: banners, cachedAt: timestamp);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveBanners(List<Banner> banners) async {
    final b = await box;
    final jsonList = banners
        .map(
          (banner) => {
            'id': banner.id,
            'name': banner.name,
            'description_plaintext': banner.descriptionPlaintext,
            'image': banner.imageUrl,
            'category_id': banner.categoryId,
            'product_id': banner.productId,
            'product_variant_id': banner.productVariantId,
          },
        )
        .toList();

    await b.put(HiveKeys.homeAdvertisement, _wrapJson(jsonList));
  }

  @override
  Future<CachedData<List<ProductVariant>>?> getBestDeals() async {
    final b = await box;
    final raw = b.get(HiveKeys.homeBestDeals);
    if (raw == null) return null;

    try {
      final rawMap = raw as Map<dynamic, dynamic>;
      final jsonList = (rawMap['data'] as List).cast<Map<String, dynamic>>();
      final deals = jsonList
          .map((json) => ProductVariant.fromJson(json))
          .toList();
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        rawMap['timestamp'] as int,
      );

      return CachedData(data: deals, cachedAt: timestamp);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveBestDeals(List<ProductVariant> deals) async {
    final b = await box;
    // Convert to JSON - same structure as discounted products
    final jsonList = deals
        .map(
          (product) => {
            'id': product.id,
            'name': product.name,
            'product_id': product.productId,
            'sku': product.sku,
            'price': product.price,
            'discounted_price': product.discountedPrice,
            'stock_unit': product.stockUnit,
            'current_quantity': product.currentQuantity,
            'status': product.status,
            'media': product.media
                .map(
                  (m) => {
                    'id': m.id,
                    'file_path': m.imagePath,
                    'image': m.imageUrl,
                    'alt': m.alt,
                    'external_url': m.externalUrl,
                    'product_id': m.productId,
                    'created_at': m.createdAt.toIso8601String(),
                  },
                )
                .toList(),
            'product_description': product.productDescription,
            'product_rating': product.productRating,
            'quantity_limit_per_customer': product.quantityLimitPerCustomer,
            'is_preorder': product.isPreorder,
            'preorder_end_date': product.preorderEndDate?.toIso8601String(),
            'tags': product.tags,
            'created_at': product.createdAt.toIso8601String(),
            'updated_at': product.updatedAt.toIso8601String(),
          },
        )
        .toList();

    await b.put(HiveKeys.homeBestDeals, _wrapJson(jsonList));
  }

  @override
  Future<UserAddress?> getSelectedAddress() async {
    final b = await box;
    final raw = b.get(HiveKeys.userSelectedAddress);
    if (raw == null) return null;

    try {
      final json = raw as Map<String, dynamic>;
      return UserAddress.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveSelectedAddress(UserAddress address) async {
    final b = await box;
    final json = {
      'id': address.id,
      'first_name': address.firstName,
      'last_name': address.lastName,
      'street_address_1': address.streetAddress1,
      'street_address_2': address.streetAddress2,
      'city': address.city,
      'state': address.state,
      'postal_code': address.postalCode,
      'country': address.country,
      'latitude': address.latitude,
      'longitude': address.longitude,
      'address_type': address.addressType,
      'selected': address.selected,
      'created_at': address.createdAt.toIso8601String(),
    };

    await b.put(HiveKeys.userSelectedAddress, json);
  }

  @override
  Future<void> clearSelectedAddress() async {
    final b = await box;
    await b.delete(HiveKeys.userSelectedAddress);
  }

  @override
  Future<void> clearAllHomeCache() async {
    final b = await box;
    // Clear all cache including address (address always fetched from API now)
    await b.clear();
  }
}

final homeLocalDataSourceProvider = Provider<HomeLocalDataSource>((ref) {
  // Safe provider that handles box initialization gracefully
  return HomeLocalDataSourceImpl();
});
