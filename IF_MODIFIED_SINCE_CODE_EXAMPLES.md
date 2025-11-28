# If-Modified-Since Code Examples & Implementations

## Table of Contents
1. [Building Conditional Headers](#1-building-conditional-headers)
2. [Extracting Response Headers](#2-extracting-response-headers)
3. [Handling 304 vs 200 Responses](#3-handling-304-vs-200-responses)
4. [Local Data Source Operations](#4-local-data-source-operations)
5. [Remote Data Source Operations](#5-remote-data-source-operations)
6. [Repository Implementation](#6-repository-implementation)
7. [Polling & Timer Management](#7-polling--timer-management)
8. [Complete End-to-End Flow](#8-complete-end-to-end-flow)
9. [Hive Cache Operations](#9-hive-cache-operations)
10. [Error Handling](#10-error-handling)

---

## 1. Building Conditional Headers

### Using CacheHeadersHelper

```dart
// From: lib/core/network/cache_headers_helper.dart

/// Build conditional request headers from cached metadata
static Map<String, String> buildConditionalHeaders({
  String? ifModifiedSince,  // Last-Modified from previous response
  String? ifNoneMatch,      // ETag from previous response
}) {
  final headers = <String, String>{};

  // Priority: If-None-Match first (ETag more accurate)
  if (ifNoneMatch != null) {
    headers['If-None-Match'] = ifNoneMatch;
  }

  // Then add If-Modified-Since
  if (ifModifiedSince != null) {
    headers['If-Modified-Since'] = ifModifiedSince;
  }

  return headers;
}
```

### Usage Example

```dart
// First time (no cache)
final headers1 = CacheHeadersHelper.buildConditionalHeaders(
  ifModifiedSince: null,  // No cache yet
  ifNoneMatch: null,
);
print(headers1);  // {} (empty)

// Subsequent times (with cache)
final headers2 = CacheHeadersHelper.buildConditionalHeaders(
  ifModifiedSince: 'Wed, 21 Oct 2025 07:28:00 GMT',
  ifNoneMatch: '"abc123def456"',
);
print(headers2);
// Output:
// {
//   If-None-Match: "abc123def456",
//   If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
// }
```

---

## 2. Extracting Response Headers

### Helper Method

```dart
// From: lib/core/network/cache_headers_helper.dart

/// Extract cache headers from HTTP response
///
/// HTTP headers are case-insensitive but servers may use different cases.
/// This function checks both lowercase and proper case variants.
static (String?, String?) extractCacheHeaders(Headers responseHeaders) {
  // Try lowercase first, then proper case
  final eTag = responseHeaders.value('etag') ??
               responseHeaders.value('ETag');

  final lastModified = responseHeaders.value('last-modified') ??
                       responseHeaders.value('Last-Modified');

  // Returns tuple: (eTag, lastModified)
  return (eTag, lastModified);
}
```

### Usage Example

```dart
import 'package:dio/dio.dart';

// After receiving HTTP response
final response = await client.get('/api/products/variants/123/');

// Extract headers (case-insensitive)
final (eTag, lastModified) = CacheHeadersHelper.extractCacheHeaders(
  response.headers,
);

print('ETag: $eTag');
print('Last-Modified: $lastModified');
// Output:
// ETag: "abc123def456"
// Last-Modified: Wed, 21 Oct 2025 07:28:00 GMT
```

### Response Headers Object Structure

```dart
// Headers is from Dio package
// Accessing response headers:
response.headers.value('etag')           // Case-sensitive in Dio
response.headers.value('ETag')           // Different case
response.statusCode                      // 200 or 304
response.data                            // Response body
```

---

## 3. Handling 304 vs 200 Responses

### Check If Not Modified

```dart
// From: lib/core/network/cache_headers_helper.dart

static bool isNotModified(int? statusCode) {
  return statusCode == 304;
}
```

### Complete Response Handling

```dart
// In RemoteDataSource
try {
  final response = await _apiClient.get(
    '/api/products/variants/$productId/',
    headers: conditionalHeaders,
  );

  final statusCode = response.statusCode ?? 200;

  // HANDLE 304 NOT MODIFIED
  if (statusCode == 304) {
    developer.log('Variant $productId: HTTP 304 (no change)');
    return null;  // Signal: No change, use cached data
  }

  // HANDLE 200 OK
  if (statusCode == 200) {
    final eTag = response.headers.value('etag') ??
                 response.headers.value('ETag');
    final lastModified = response.headers.value('last-modified') ??
                         response.headers.value('Last-Modified');

    return ProductDetailRemoteResponse(
      productDetail: ProductVariantDto.fromJson(response.data),
      fetchedAt: DateTime.now(),
      eTag: eTag,
      lastModified: lastModified,
    );
  }

  // OTHER STATUS CODES (2xx except 304)
  return null;
} on NetworkException catch (error) {
  // Some servers return 304 as NetworkException
  if (error.statusCode == 304) {
    return null;
  }
  rethrow;
}
```

### Handling in Repository

```dart
// In ProductDetailRepositoryImpl
final remoteResponse = await _remoteDataSource.fetchProductDetail(
  productId: variantId,
  ifModifiedSince: cachedMetadata?.lastModified,
  ifNoneMatch: cachedMetadata?.eTag,
);

// remoteResponse is:
// - null → HTTP 304 (no change)
// - ProductDetailRemoteResponse → HTTP 200 (new data)

if (remoteResponse == null) {
  // 304 NOT MODIFIED
  developer.log('Variant $variantId: 304 Not Modified');
  return null;  // Don't update UI
} else {
  // 200 OK
  developer.log('Variant $variantId: 200 OK');

  // Save new metadata
  await _localDataSource.cacheProductDetailWithMetadata(
    variantId,
    ProductDetailCacheDto(
      lastSyncedAt: DateTime.now(),
      eTag: remoteResponse.eTag,
      lastModified: remoteResponse.lastModified,
    ),
  );

  return remoteResponse.productDetail.toDomain();  // Update UI
}
```

---

## 4. Local Data Source Operations

### Cache DTO

```dart
// From: lib/features/product_details/infrastructure/data_sources/local/product_detail_cache_dto.dart

class ProductDetailCacheDto {
  const ProductDetailCacheDto({
    required this.lastSyncedAt,
    this.eTag,
    this.lastModified,
  });

  final DateTime lastSyncedAt;        // When last synced (TTL tracking)
  final String? eTag;                 // HTTP ETag header
  final String? lastModified;         // HTTP Last-Modified header

  /// Convert to JSON for Hive storage
  Map<String, dynamic> toJson() => {
    'last_synced_at': lastSyncedAt.toIso8601String(),
    'etag': eTag,
    'last_modified': lastModified,
  };

  /// Create from Hive JSON
  factory ProductDetailCacheDto.fromJson(Map<String, dynamic> json) {
    return ProductDetailCacheDto(
      lastSyncedAt: DateTime.parse(json['last_synced_at'] as String),
      eTag: json['etag'] as String?,
      lastModified: json['last_modified'] as String?,
    );
  }

  /// Immutable update
  ProductDetailCacheDto copyWith({
    DateTime? lastSyncedAt,
    String? eTag,
    String? lastModified,
  }) {
    return ProductDetailCacheDto(
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      eTag: eTag ?? this.eTag,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
```

### Reading from Hive

```dart
// From: ProductDetailLocalDataSourceImpl

Future<ProductDetailCacheDto?> getCachedProductDetail(
  String productId,
) async {
  try {
    // Build Hive key using config prefix
    final key = '${CacheConfig.productDetailVariantMetadataPrefix}$productId';
    // Example key: 'pd:variant_meta:variant_789'

    // Get from Hive box
    final json = _box.get(key) as Map<String, dynamic>?;

    // Convert to DTO or null
    return json != null ? ProductDetailCacheDto.fromJson(json) : null;
  } catch (e) {
    // If read fails, treat as no cache
    return null;
  }
}
```

### Writing to Hive

```dart
// From: ProductDetailLocalDataSourceImpl

Future<void> cacheProductDetailWithMetadata(
  String productId,
  ProductDetailCacheDto cacheDto,
) async {
  try {
    // Build Hive key
    final key = '${CacheConfig.productDetailVariantMetadataPrefix}$productId';

    // Save as JSON
    await _box.put(key, cacheDto.toJson());
  } catch (e) {
    rethrow;
  }
}

// Usage:
await localDataSource.cacheProductDetailWithMetadata(
  'variant_789',
  ProductDetailCacheDto(
    lastSyncedAt: DateTime.now(),
    eTag: '"abc123def456"',
    lastModified: 'Wed, 21 Oct 2025 07:28:00 GMT',
  ),
);
```

### Updating Sync Timestamp Only

```dart
// From: ProductDetailLocalDataSourceImpl
// Called on 304 Not Modified to refresh TTL

Future<void> updateProductDetailSyncTime(
  String productId,
  DateTime timestamp,
) async {
  try {
    // Get existing cache
    final cached = await getCachedProductDetail(productId);

    if (cached != null) {
      // Update ONLY lastSyncedAt, keep eTag and lastModified
      await cacheProductDetailWithMetadata(
        productId,
        cached.copyWith(
          lastSyncedAt: timestamp,  // ← ONLY THIS CHANGES
          // eTag stays same
          // lastModified stays same
        ),
      );
    }
  } catch (e) {
    rethrow;
  }
}

// Usage on 304 response:
if (remoteResponse == null) {
  if (cachedMetadata != null) {
    await _localDataSource.updateProductDetailSyncTime(
      variantId,
      DateTime.now(),
    );
  }
}
```

### Clearing Cache

```dart
// From: ProductDetailLocalDataSourceImpl

Future<void> clearProductDetail(String productId) async {
  try {
    final key = '${CacheConfig.productDetailVariantMetadataPrefix}$productId';
    await _box.delete(key);
  } catch (e) {
    rethrow;
  }
}

Future<void> clearAllCache() async {
  try {
    final keys = _box.keys.toList();
    for (final key in keys) {
      if (key.toString().startsWith(
            CacheConfig.productDetailVariantMetadataPrefix,
          )) {
        await _box.delete(key);
      }
    }
  } catch (e) {
    rethrow;
  }
}
```

---

## 5. Remote Data Source Operations

### Complete Implementation

```dart
// From: lib/features/product_details/infrastructure/data_sources/remote/
//       product_detail_remote_data_source.dart

class ProductDetailRemoteDataSourceImpl
    implements ProductDetailRemoteDataSource {
  ProductDetailRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  /// Fetch product variant with conditional headers (supports 304)
  /// Returns:
  /// - ProductDetailRemoteResponse: HTTP 200 (new data)
  /// - null: HTTP 304 (no change)
  @override
  Future<ProductDetailRemoteResponse?> fetchProductDetail({
    required String productId,
    String? ifNoneMatch,
    String? ifModifiedSince,
  }) async {
    try {
      // ======== STEP 1: Build headers ========
      final headers = <String, String>{};

      if (ifNoneMatch != null) {
        headers['If-None-Match'] = ifNoneMatch;
      }
      if (ifModifiedSince != null) {
        headers['If-Modified-Since'] = ifModifiedSince;
      }

      // ======== STEP 2: Log request ========
      if (headers.isNotEmpty) {
        developer.log(
          'CONDITIONAL REQUEST for variant $productId\n'
          'Headers: ${headers.toString()}',
          name: 'ProductRemoteDataSource',
          level: 700,
        );
      } else {
        developer.log(
          'UNCONDITIONAL REQUEST for variant $productId (no cache)',
          name: 'ProductRemoteDataSource',
          level: 700,
        );
      }

      // ======== STEP 3: Send request ========
      final response = await _apiClient.get(
        '/api/products/variants/$productId/',
        headers: headers.isNotEmpty ? headers : null,
      );

      // ======== STEP 4: Check status code ========
      final statusCode = response.statusCode ?? 200;
      final responseHeaders = response.headers;

      // Handle 304 Not Modified
      if (statusCode == 304) {
        developer.log(
          'Variant $productId: HTTP 304 (bandwidth optimized)',
          name: 'RemoteDataSource',
        );
        return null;  // Signal: no change
      }

      // ======== STEP 5: Extract headers ========
      final eTag = responseHeaders.value('etag') ??
                   responseHeaders.value('ETag');
      final lastModified = responseHeaders.value('last-modified') ??
                           responseHeaders.value('Last-Modified');

      // ======== STEP 6: Return response ========
      developer.log(
        'Variant $productId: HTTP 200 (Last-Modified: $lastModified)',
        name: 'RemoteDataSource',
      );

      return ProductDetailRemoteResponse(
        productDetail: ProductVariantDto.fromJson(
          response.data as Map<String, dynamic>,
        ),
        fetchedAt: DateTime.now(),
        eTag: eTag,
        lastModified: lastModified,
      );
    } on NetworkException catch (error) {
      // Handle 304 wrapped in NetworkException
      if (error.statusCode == 304) {
        developer.log(
          'Variant $productId: HTTP 304 (via NetworkException)',
          name: 'RemoteDataSource',
        );
        return null;
      }
      developer.log(
        'Variant $productId: NetworkException - $error',
        name: 'RemoteDataSource',
      );
      rethrow;
    } on DioException catch (error) {
      developer.log(
        'Variant $productId: DioException - $error',
        name: 'RemoteDataSource',
      );
      throw NetworkException.fromDio(error);
    } catch (e) {
      developer.log(
        'Variant $productId: Error - $e',
        name: 'RemoteDataSource',
      );
      rethrow;
    }
  }
}
```

### Response Models

```dart
/// Response model with metadata
class ProductDetailRemoteResponse {
  ProductDetailRemoteResponse({
    required this.productDetail,
    required this.fetchedAt,
    this.eTag,
    this.lastModified,
  });

  final ProductVariantDto productDetail;  // New product data
  final DateTime fetchedAt;               // When fetched
  final String? eTag;                     // For next request
  final String? lastModified;             // For next request
}

class ProductBaseRemoteResponse {
  ProductBaseRemoteResponse({
    required this.productBase,
    required this.fetchedAt,
    this.eTag,
    this.lastModified,
  });

  final ProductBaseDto productBase;
  final DateTime fetchedAt;
  final String? eTag;
  final String? lastModified;
}
```

---

## 6. Repository Implementation

### Complete Flow

```dart
// From: lib/features/product_details/infrastructure/repositories/
//       product_detail_repository_impl.dart

class ProductDetailRepositoryImpl implements ProductDetailRepository {
  ProductDetailRepositoryImpl({
    required ProductDetailLocalDataSource localDataSource,
    required ProductDetailRemoteDataSource remoteDataSource,
    this.cacheTTL = const Duration(hours: 1),
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final ProductDetailLocalDataSource _localDataSource;
  final ProductDetailRemoteDataSource _remoteDataSource;
  final Duration cacheTTL;

  /// Get product detail with If-Modified-Since optimization
  ///
  /// Returns:
  /// - ProductVariant: 200 OK (new data, update UI)
  /// - null: 304 Not Modified (no change, keep UI same)
  @override
  Future<ProductVariant?> getProductDetail(
    String variantId, {
    bool forceRefresh = false,
  }) async {
    try {
      // ========== STEP 1: Get cached metadata ==========
      final cachedMetadata = await _localDataSource.getCachedProductDetail(
        variantId,
      );

      // Log cache state
      if (cachedMetadata != null && !forceRefresh) {
        final now = DateTime.now();
        final cacheAge = now.difference(cachedMetadata.lastSyncedAt);
        developer.log(
          'Variant $variantId: Metadata age ${cacheAge.inSeconds}s '
          '(TTL ${cacheTTL.inSeconds}s)',
          name: 'ProductRepo',
        );
      }

      // ========== STEP 2: Fetch from API ==========
      final remoteResponse = await _remoteDataSource.fetchProductDetail(
        productId: variantId,
        // If forceRefresh, ignore cache (pass null)
        ifNoneMatch: forceRefresh ? null : cachedMetadata?.eTag,
        ifModifiedSince: forceRefresh
            ? null
            : cachedMetadata?.lastModified,
      );

      final now = DateTime.now();

      // ========== STEP 3a: Handle 304 Not Modified ==========
      if (remoteResponse == null) {
        developer.log(
          'Variant $variantId: 304 Not Modified (no UI refresh)',
          name: 'ProductRepo',
        );

        // Update sync timestamp to refresh TTL
        if (cachedMetadata != null) {
          await _localDataSource.cacheProductDetailWithMetadata(
            variantId,
            cachedMetadata.copyWith(
              lastSyncedAt: now,  // ← ONLY UPDATE THIS
              // Keep eTag and lastModified same
            ),
          );
        }

        // Return null → Don't update state
        return null;
      }

      // ========== STEP 3b: Handle 200 OK ==========
      developer.log(
        'Variant $variantId: 200 OK (UI will refresh)',
        name: 'ProductRepo',
      );

      // Save NEW metadata
      final newCacheDto = ProductDetailCacheDto(
        lastSyncedAt: now,
        eTag: remoteResponse.eTag,
        lastModified: remoteResponse.lastModified,
      );

      await _localDataSource.cacheProductDetailWithMetadata(
        variantId,
        newCacheDto,
      );

      // Return new data → Update UI
      return remoteResponse.productDetail.toDomain();
    } catch (e) {
      developer.log(
        'Variant $variantId: Error - $e',
        name: 'ProductRepo',
      );
      rethrow;
    }
  }
}
```

### Calling the Repository

```dart
// From UI/Notifier

// First load (no cache)
final result1 = await repository.getProductDetail(
  variantId,
  forceRefresh: false,
);
// → Makes unconditional request
// → Gets 200 OK
// → Returns ProductVariant
// → UI updates

// Polling (with cache)
final result2 = await repository.getProductDetail(
  variantId,
  forceRefresh: false,
);
// → Makes conditional request (with If-Modified-Since)
// → Gets 304 or 200
// → Returns null (304) or ProductVariant (200)
// → UI updates if new data

// Force refresh (ignore cache)
final result3 = await repository.getProductDetail(
  variantId,
  forceRefresh: true,
);
// → Makes unconditional request (ignores cache)
// → Gets 200 OK (always fresh)
// → Returns ProductVariant
// → UI updates
```

---

## 7. Polling & Timer Management

### Setting Up Polling

```dart
// From: lib/features/product_details/application/providers/
//       product_detail_providers.dart

class ProductDetailNotifier extends AsyncNotifier<ProductVariant> {
  late ProductDetailRepository repository;
  Timer? _pollingTimer;
  DateTime? _lastRefreshAttempt;

  /// Start polling timer
  void _startPolling() {
    if (_pollingTimer != null) return;  // Already polling

    _pollingTimer = Timer.periodic(
      Duration(seconds: 30),  // From CacheConfig.pollingInterval
      (_) async {
        // This callback fires every 30 seconds
        await _refreshProductDetail(shouldNotify: true);
      },
    );

    developer.log(
      'Started polling every 30 seconds',
      name: 'ProductDetailNotifier',
    );
  }

  /// Stop polling timer
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;

    developer.log(
      'Stopped polling',
      name: 'ProductDetailNotifier',
    );
  }

  /// Refresh product detail from API
  Future<void> _refreshProductDetail({
    bool shouldNotify = true,
  }) async {
    try {
      // Call repository (which sends conditional request)
      final result = await repository.getProductDetail(
        variantId,
        forceRefresh: false,  // Use cache for conditional headers
      );

      // result is null (304) or ProductVariant (200)
      if (result != null) {
        // Update state only on 200 OK
        state = AsyncValue.data(result);
      }
      // On 304 (null), state unchanged → UI doesn't refresh
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Initialize notifier
  @override
  FutureOr<ProductVariant> build() async {
    // Initial fetch
    final result = await repository.getProductDetail(variantId);

    // Start polling after initial load
    _startPolling();

    // Clean up on dispose
    ref.onDispose(() {
      _stopPolling();
    });

    return result!;
  }

  /// Manual refresh
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _refreshProductDetail();
  }

  /// Force refresh (ignore cache)
  Future<void> forceRefresh() async {
    state = const AsyncValue.loading();
    try {
      final result = await repository.getProductDetail(
        variantId,
        forceRefresh: true,  // Ignore cached metadata
      );
      state = AsyncValue.data(result!);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
```

### Timer States

```
                    ┌─────────────────┐
                    │  No Timer       │
                    │ (page not open) │
                    └────────┬────────┘
                             │
                    User navigates to page
                             │
                             ▼
                    ┌─────────────────┐
                    │ Polling Active  │
                    │  (every 30s)    │
                    └────────┬────────┘
                             │
                 User navigates away
                             │
                             ▼
                    ┌─────────────────┐
                    │ Timer Cancelled │
                    │ (page disposed) │
                    └─────────────────┘
```

---

## 8. Complete End-to-End Flow

### Scenario: Product Opens → Polls → Price Changes

```dart
// STEP 1: User opens product detail page
// ==========================================

// UI calls Notifier.build()
@override
FutureOr<ProductVariant> build() async {
  // Fetch fresh data (no cache)
  final result = await repository.getProductDetail(variantId);

  // HTTP GET /api/products/variants/variant_789/ (no If-*)
  // ← Server responds: HTTP 200 OK
  //                     ETag: "abc123"
  //                     Last-Modified: "Wed, 21 Oct 2025 07:28:00 GMT"
  //                     Body: {id, name, price: 4.99, ...}

  // Save metadata to Hive
  // Key: 'pd:variant_meta:variant_789'
  // Value: {
  //   last_synced_at: 2025-11-27T10:00:00.000Z
  //   etag: "abc123"
  //   last_modified: "Wed, 21 Oct 2025 07:28:00 GMT"
  // }

  // Start polling timer
  _startPolling();

  // Return product data → UI renders
  return result!;  // ProductVariant(name: "Fresh Apples", price: 4.99)
}

// ==========================================
// STEP 2: First polling check (10:00:30)
// ==========================================

// Timer fires after 30 seconds
_refreshProductDetail() async {
  // Get cached metadata from Hive
  final cached = await localDataSource.getCachedProductDetail(variantId);
  // Returns: {
  //   lastSyncedAt: 2025-11-27T10:00:00.000Z
  //   eTag: "abc123"
  //   lastModified: "Wed, 21 Oct 2025 07:28:00 GMT"
  // }

  // Fetch with conditional headers
  final result = await repository.getProductDetail(variantId);

  // HTTP GET /api/products/variants/variant_789/
  // Headers:
  //   If-None-Match: "abc123"
  //   If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
  // ← Server checks: "Has data changed since that time?"
  // ← Server responds: HTTP 304 Not Modified (no body)

  // Repository returns null (304)
  if (result == null) {
    // Don't update state
    return;  // UI unchanged, shows same price ($4.99)
  }
}

// ==========================================
// STEP 3: On Server (between 10:01:00-10:01:15)
// ==========================================

// Server admin updates product price
// Update timestamp: 2025-11-27T10:01:15 UTC
// New price: $5.99 (was $4.99)
// New ETag: "xyz789"

// ==========================================
// STEP 4: Next polling check (10:01:30)
// ==========================================

_refreshProductDetail() async {
  // Get cached metadata (still from 10:00:00)
  final cached = await localDataSource.getCachedProductDetail(variantId);
  // Returns: {
  //   lastSyncedAt: 2025-11-27T10:00:30.000Z  ← from previous 304
  //   eTag: "abc123"                           ← old ETag
  //   lastModified: "Wed, 21 Oct 2025 07:28:00 GMT"  ← old timestamp
  // }

  final result = await repository.getProductDetail(variantId);

  // HTTP GET /api/products/variants/variant_789/
  // Headers:
  //   If-None-Match: "abc123"
  //   If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
  // ← Server checks: "Has data changed since 07:28:00 GMT?"
  // ← Server sees data was modified at 10:01:15 GMT (AFTER 07:28:00)
  // ← Server responds: HTTP 200 OK (new data included!)
  //                     ETag: "xyz789"  (NEW)
  //                     Last-Modified: Wed, 21 Oct 2025 08:45:00 GMT (NEW)
  //                     Body: {id, name, price: 5.99, ...}

  // Repository returns new ProductVariant
  if (result != null) {
    // Update state with new data
    state = AsyncValue.data(result);
    // ProductVariant(name: "Fresh Apples", price: 5.99)

    // Save NEW metadata to Hive
    // Key: 'pd:variant_meta:variant_789'
    // Value: {
    //   last_synced_at: 2025-11-27T10:01:30.000Z  ← UPDATED
    //   etag: "xyz789"                            ← UPDATED
    //   last_modified: "Wed, 21 Oct 2025 08:45:00 GMT"  ← UPDATED
    // }
  }
}

// ==========================================
// RESULT
// ==========================================
// UI automatically rebuilds
// User sees: Price changed from $4.99 → $5.99
// Next 304 check will use new ETag/timestamp
```

---

## 9. Hive Cache Operations

### Full Database Example

```dart
// All operations use single Hive box

// ========== INITIALIZATION ==========
// In app_bootstrap.dart or main.dart

await Hive.initFlutter();

// Open single cache box for ALL features
final cacheBox = await Hive.openBox<dynamic>(
  CacheConfig.hiveBoxName,  // 'app_cache_box'
);

// ========== READING ==========
Box<dynamic> cacheBox = Hive.box<dynamic>('app_cache_box');

// Read product detail variant metadata
final variantKey = 'pd:variant_meta:variant_789';
final variantJson = cacheBox.get(variantKey) as Map<String, dynamic>?;
// Returns: {last_synced_at: "...", etag: "...", last_modified: "..."}

// Read product base metadata
final productKey = 'pd:product_meta:product_456';
final productJson = cacheBox.get(productKey) as Map<String, dynamic>?;

// Read category list metadata
final categoryKey = 'cat:list_meta';
final categoryJson = cacheBox.get(categoryKey) as Map<String, dynamic>?;

// Read category products metadata
final catProductsKey = 'cat:products_meta:category_1';
final catProductsJson = cacheBox.get(catProductsKey) as Map<String, dynamic>?;

// ========== WRITING ==========

// Save variant metadata
final variantKey = 'pd:variant_meta:variant_789';
await cacheBox.put(variantKey, {
  'last_synced_at': DateTime.now().toIso8601String(),
  'etag': '"abc123def456"',
  'last_modified': 'Wed, 21 Oct 2025 07:28:00 GMT',
});

// Save product metadata
final productKey = 'pd:product_meta:product_456';
await cacheBox.put(productKey, {
  'last_synced_at': DateTime.now().toIso8601String(),
  'etag': null,  // Product API might not return ETag
  'last_modified': 'Tue, 20 Oct 2025 14:20:00 GMT',
});

// ========== UPDATING ==========

// Get current value
final variantJson = cacheBox.get(variantKey) as Map<String, dynamic>?;

// Update specific field (only lastSyncedAt)
if (variantJson != null) {
  variantJson['last_synced_at'] = DateTime.now().toIso8601String();
  // Keep etag and last_modified same
  await cacheBox.put(variantKey, variantJson);
}

// ========== DELETING ==========

// Delete specific key
await cacheBox.delete('pd:variant_meta:variant_789');

// Delete all variant metadata
final keys = cacheBox.keys.toList();
for (final key in keys) {
  if (key.toString().startsWith('pd:variant_meta:')) {
    await cacheBox.delete(key);
  }
}

// Clear entire box
await cacheBox.clear();

// ========== QUERYING ==========

// Get all keys
final allKeys = cacheBox.keys.toList();
// Output: ['pd:variant_meta:789', 'pd:product_meta:456', 'cat:list_meta', ...]

// Get all values
final allValues = cacheBox.values.toList();

// Find keys with prefix
final productDetailKeys = cacheBox.keys
    .where((key) => key.toString().startsWith('pd:'))
    .toList();

// Count entries
final count = cacheBox.length;
```

### Hive Data Structure

```
Box: 'app_cache_box'
Type: Map<dynamic, dynamic>

Content:
{
  'pd:variant_meta:variant_789': {
    'last_synced_at': '2025-11-27T10:01:30.000Z',
    'etag': '"xyz789abc123"',
    'last_modified': 'Wed, 21 Oct 2025 08:45:00 GMT'
  },

  'pd:variant_meta:variant_123': {
    'last_synced_at': '2025-11-27T10:00:00.000Z',
    'etag': '"abc456def789"',
    'last_modified': 'Tue, 20 Oct 2025 12:30:00 GMT'
  },

  'pd:product_meta:product_456': {
    'last_synced_at': '2025-11-27T09:55:00.000Z',
    'etag': null,
    'last_modified': 'Mon, 19 Oct 2025 09:00:00 GMT'
  },

  'cat:list_meta': {
    'last_synced_at': '2025-11-27T09:50:00.000Z',
    'etag': '"cat_list_v1"',
    'last_modified': 'Fri, 17 Oct 2025 16:30:00 GMT'
  },

  'cat:products_meta:category_1': {
    'last_synced_at': '2025-11-27T09:45:00.000Z',
    'etag': '"cat1_products_v2"',
    'last_modified': 'Fri, 17 Oct 2025 17:00:00 GMT'
  }
}

Size: ~5-10KB (very small, just metadata)
Format: ISO8601 dates, ETag strings
```

---

## 10. Error Handling

### Network Error Handling

```dart
// In RemoteDataSource

try {
  final response = await _apiClient.get(
    '/api/products/variants/$productId/',
    headers: conditionalHeaders,
  );

  // Handle response
  if (response.statusCode == 304) {
    return null;
  }

  // ... extract headers, return response

} on NetworkException catch (error) {
  // Some servers return 304 as NetworkException
  if (error.statusCode == 304) {
    developer.log('304 via NetworkException');
    return null;
  }

  // Other network errors
  developer.log('NetworkException: ${error.message}');
  rethrow;

} on DioException catch (error) {
  // Dio connection errors, timeouts, etc.
  developer.log('DioException: $error');
  throw NetworkException.fromDio(error);

} on FormatException catch (error) {
  // JSON parsing error
  developer.log('FormatException: ${error.message}');
  throw NetworkException(message: error.message);

} catch (e) {
  // Unknown errors
  developer.log('Error: $e');
  rethrow;
}
```

### Repository Error Handling

```dart
// In Repository

Future<ProductVariant?> getProductDetail(
  String variantId, {
  bool forceRefresh = false,
}) async {
  try {
    final cachedMetadata = await _localDataSource.getCachedProductDetail(
      variantId,
    );

    final remoteResponse = await _remoteDataSource.fetchProductDetail(
      productId: variantId,
      ifModifiedSince: forceRefresh ? null : cachedMetadata?.lastModified,
      ifNoneMatch: forceRefresh ? null : cachedMetadata?.eTag,
    );

    if (remoteResponse == null) {
      // 304: Update TTL and return null
      if (cachedMetadata != null) {
        await _localDataSource.cacheProductDetailWithMetadata(
          variantId,
          cachedMetadata.copyWith(lastSyncedAt: DateTime.now()),
        );
      }
      return null;
    }

    // 200: Save metadata and return data
    await _localDataSource.cacheProductDetailWithMetadata(
      variantId,
      ProductDetailCacheDto(
        lastSyncedAt: DateTime.now(),
        eTag: remoteResponse.eTag,
        lastModified: remoteResponse.lastModified,
      ),
    );

    return remoteResponse.productDetail.toDomain();

  } catch (e) {
    developer.log(
      'Repository error for $variantId: $e',
      name: 'ProductRepo',
    );
    rethrow;  // Let Notifier handle the error
  }
}
```

### Notifier Error Handling

```dart
// In Notifier/Provider

class ProductDetailNotifier extends AsyncNotifier<ProductVariant> {
  @override
  FutureOr<ProductVariant> build() async {
    try {
      final result = await repository.getProductDetail(variantId);
      _startPolling();
      return result!;

    } catch (error, stackTrace) {
      // State becomes error
      // UI shows error message
      developer.log('Build error: $error');
      rethrow;
    }
  }

  Future<void> _refreshProductDetail() async {
    try {
      final result = await repository.getProductDetail(variantId);

      if (result != null) {
        // Update state (200 OK)
        state = AsyncValue.data(result);
      }
      // Else: 304, state unchanged

    } catch (error, stackTrace) {
      // Only update state on error during refresh
      state = AsyncValue.error(error, stackTrace);
      developer.log('Refresh error: $error');
    }
  }

  Future<void> retry() async {
    state = const AsyncValue.loading();
    await _refreshProductDetail();
  }
}

// In UI Widget

@override
Widget build(BuildContext context, WidgetRef ref) {
  final productAsync = ref.watch(productDetailProvider(variantId));

  return productAsync.when(
    data: (product) => ProductDetailView(product: product),

    loading: () => const LoadingIndicator(),

    error: (error, stackTrace) => ErrorView(
      error: error,
      onRetry: () {
        ref.refresh(productDetailProvider(variantId));
      },
    ),
  );
}
```

---

## Key Takeaways

1. **Metadata Only:** Store ETag, Last-Modified, timestamp in Hive
2. **Return Null on 304:** Signal "no change" to prevent UI refresh
3. **Always Extract Headers:** Save new ETag/Last-Modified from 200 OK
4. **Update Timestamp on 304:** Refresh TTL without changing other fields
5. **Use Namespaced Keys:** 'pd:variant_meta:', 'cat:list_meta', etc
6. **Single Hive Box:** All features share 'app_cache_box'
7. **Handle Edge Cases:** 304 wrapped in NetworkException, timeout, etc

---

**Code Examples Last Updated:** 2025-11-27
**Framework:** Flutter + Riverpod + Hive + Dio
