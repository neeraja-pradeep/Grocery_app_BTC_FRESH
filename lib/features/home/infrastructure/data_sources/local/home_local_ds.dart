// lib/features/home/infrastructure/data_sources/local/home_local_ds.dart

import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../../../core/storage/hive/keys.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/entities/banner.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product_variant.dart';
import '../../../domain/entities/user_address.dart';
import '../../../domain/repositories/home_repository.dart';

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
  Future<CachedData<DiscountedProductsResult>?> getDiscountedProducts({
    required String cacheKey,
  });
  Future<void> saveDiscountedProducts({
    required String cacheKey,
    required DiscountedProductsResult result,
  });

  // Banners (Advertisement)
  Future<CachedData<List<Banner>>?> getBanners();
  Future<void> saveBanners(List<Banner> banners);

  // Best Deals
  Future<CachedData<List<ProductVariant>>?> getBestDeals();
  Future<void> saveBestDeals(List<ProductVariant> deals);

  // Address
  Future<UserAddress?> getSelectedAddress();

  // Utility
  Future<void> clearAllHomeCache();
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  final Box _box;

  HomeLocalDataSourceImpl(Box box) : _box = box;

  Box get _hiveBox => _box;

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
    final raw = _hiveBox.get(HiveKeys.homeCategories);
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
      Logger.error('Cache parse failure for categories', error: e);
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

    await _hiveBox.put(HiveKeys.homeCategories, _wrapJson(jsonList));
  }

  @override
  Future<CachedData<DiscountedProductsResult>?> getDiscountedProducts({
    required String cacheKey,
  }) async {
    final fullKey = '${HiveKeys.homeDiscounts}$cacheKey';
    final raw = _hiveBox.get(fullKey);
    if (raw == null) return null;

    try {
      final rawMap = raw as Map<dynamic, dynamic>;
      final jsonList = (rawMap['data'] as List).cast<Map<String, dynamic>>();
      final variants = jsonList
          .map((json) => ProductVariant.fromJson(json))
          .toList();

      // Restore the productId → categoryId map. Older cache entries written
      // before this field existed simply produce an empty map (the use case
      // falls back gracefully).
      final productCategoryMap = <int, int>{};
      final rawCategoryMap = rawMap['product_category_map'];
      if (rawCategoryMap is Map) {
        rawCategoryMap.forEach((key, value) {
          final productId = key is int ? key : int.tryParse(key.toString());
          final categoryId = value is int
              ? value
              : int.tryParse(value.toString());
          if (productId != null && categoryId != null) {
            productCategoryMap[productId] = categoryId;
          }
        });
      }

      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        rawMap['timestamp'] as int,
      );

      return CachedData(
        data: DiscountedProductsResult(
          variants: variants,
          productCategoryMap: productCategoryMap,
        ),
        cachedAt: timestamp,
      );
    } catch (e) {
      Logger.error('Cache parse failure for discounted products', error: e);
      return null;
    }
  }

  @override
  Future<void> saveDiscountedProducts({
    required String cacheKey,
    required DiscountedProductsResult result,
  }) async {
    final fullKey = '${HiveKeys.homeDiscounts}$cacheKey';
    // Convert to JSON - simplified version, you may need to expand this
    final jsonList = result.variants
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

    final wrapped = _wrapJson(jsonList);
    wrapped['product_category_map'] = result.productCategoryMap.map(
      (productId, categoryId) => MapEntry(productId.toString(), categoryId),
    );

    await _hiveBox.put(fullKey, wrapped);
  }

  @override
  Future<CachedData<List<Banner>>?> getBanners() async {
    // Using the Advertisement key for Banners
    final raw = _hiveBox.get(HiveKeys.homeAdvertisement);
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
      Logger.error('Cache parse failure for banners', error: e);
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

    await _hiveBox.put(HiveKeys.homeAdvertisement, _wrapJson(jsonList));
  }

  @override
  Future<CachedData<List<ProductVariant>>?> getBestDeals() async {
    final raw = _hiveBox.get(HiveKeys.homeBestDeals);
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
      Logger.error('Cache parse failure for best deals', error: e);
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

    await _hiveBox.put(HiveKeys.homeBestDeals, _wrapJson(jsonList));
  }

  @override
  Future<UserAddress?> getSelectedAddress() async {
    final raw = _hiveBox.get(HiveKeys.userSelectedAddress);
    if (raw == null) return null;

    try {
      final json = Map<String, dynamic>.from(raw as Map);
      return UserAddress.fromJson(json);
    } catch (e) {
      Logger.error('Cache parse failure for selected address', error: e);
      return null;
    }
  }

  @override
  Future<void> clearAllHomeCache() async {
    // Clear all cache including address (address always fetched from API now)
    await _hiveBox.clear();
  }
}
