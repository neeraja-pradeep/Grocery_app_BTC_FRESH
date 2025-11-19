// lib/features/home/infrastructure/data_sources/local/home_local_ds.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:new_app/core/storage/hive/keys.dart';
import 'package:new_app/features/home/domain/entities/banner.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/product_variant.dart';
import 'package:new_app/features/home/domain/entities/user_address.dart';

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
  final Box _box;

  HomeLocalDataSourceImpl(this._box);

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
    final raw = _box.get(HiveKeys.homeCategories);
    if (raw == null) return null;

    try {
      final jsonList = (raw['data'] as List).cast<Map<String, dynamic>>();
      final categories = jsonList
          .map((json) => Category.fromJson(json))
          .toList();
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        raw['timestamp'] as int,
      );

      return CachedData(data: categories, cachedAt: timestamp);
    } catch (e) {
      // If parsing fails, return null to force fresh fetch
      return null;
    }
  }

  @override
  Future<void> saveCategories(List<Category> categories) async {
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

    await _box.put(HiveKeys.homeCategories, _wrapJson(jsonList));
  }

  @override
  Future<CachedData<List<ProductVariant>>?> getDiscountedProducts({
    required String cacheKey,
  }) async {
    final fullKey = '${HiveKeys.homeDiscounts}$cacheKey';
    final raw = _box.get(fullKey);
    if (raw == null) return null;

    try {
      final jsonList = (raw['data'] as List).cast<Map<String, dynamic>>();
      final products = jsonList
          .map((json) => ProductVariant.fromJson(json))
          .toList();
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        raw['timestamp'] as int,
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

    await _box.put(fullKey, _wrapJson(jsonList));
  }

  @override
  Future<CachedData<List<Banner>>?> getBanners() async {
    // Using the Advertisement key for Banners
    final raw = _box.get(HiveKeys.homeAdvertisement);
    if (raw == null) return null;

    try {
      final jsonList = (raw['data'] as List).cast<Map<String, dynamic>>();
      final banners = jsonList.map((json) => Banner.fromJson(json)).toList();
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        raw['timestamp'] as int,
      );

      return CachedData(data: banners, cachedAt: timestamp);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveBanners(List<Banner> banners) async {
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

    await _box.put(HiveKeys.homeAdvertisement, _wrapJson(jsonList));
  }

  @override
  Future<CachedData<List<ProductVariant>>?> getBestDeals() async {
    final raw = _box.get(HiveKeys.homeBestDeals);
    if (raw == null) return null;

    try {
      final jsonList = (raw['data'] as List).cast<Map<String, dynamic>>();
      final deals = jsonList
          .map((json) => ProductVariant.fromJson(json))
          .toList();
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        raw['timestamp'] as int,
      );

      return CachedData(data: deals, cachedAt: timestamp);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveBestDeals(List<ProductVariant> deals) async {
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

    await _box.put(HiveKeys.homeBestDeals, _wrapJson(jsonList));
  }

  @override
  Future<UserAddress?> getSelectedAddress() async {
    final raw = _box.get(HiveKeys.userSelectedAddress);
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

    await _box.put(HiveKeys.userSelectedAddress, json);
  }

  @override
  Future<void> clearSelectedAddress() async {
    await _box.delete(HiveKeys.userSelectedAddress);
  }

  @override
  Future<void> clearAllHomeCache() async {
    // We delete everything EXCEPT the user address
    final keysToDelete = _box.keys.where((key) {
      return key.toString() != HiveKeys.userSelectedAddress;
    });
    await _box.deleteAll(keysToDelete);
  }
}

final homeLocalDataSourceProvider = Provider<HomeLocalDataSource>((ref) {
  // Ensure you open this box in your app initialization!
  final box = Hive.box('home_cache_box');
  return HomeLocalDataSourceImpl(box);
});
