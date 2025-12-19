# If-Modified-Since Caching Architecture

## Overview
This document explains the **HTTP conditional request caching system** using **If-Modified-Since** headers in the Grocery App. This optimization reduces bandwidth consumption by only downloading full data when server responds with HTTP 200 OK, while skipping downloads when server responds with HTTP 304 Not Modified.

---

## Quick Summary

| Aspect | Details |
|--------|---------|
| **Purpose** | Reduce bandwidth by checking if data changed before downloading |
| **HTTP Headers** | `If-Modified-Since`, `If-None-Match` (ETag) |
| **Server Responses** | `304 Not Modified` (no change) or `200 OK` (new data) |
| **Cache Storage** | Hive database (metadata only: lastModified, eTag, timestamp) |
| **Polling Interval** | 30 seconds |
| **Cache TTL** | 1 hour |
| **Data Storage** | Metadata in Hive, product data in-memory (Riverpod state) |

---

## Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                     │
│          (Product Details Screen, Category Screen)      │
│                   (Riverpod State)                      │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│              APPLICATION LAYER (Providers)              │
│  - ProductDetailNotifier (polling, state management)    │
│  - CategoryNotifier                                     │
│  - Timer-based polling every 30 seconds                 │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│               DOMAIN LAYER (Repositories)               │
│  - ProductDetailRepository                             │
│  - CategoryRepository                                  │
│  - Returns: ProductVariant (200) or null (304)         │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│            INFRASTRUCTURE LAYER                         │
│  ┌────────────────────────────────────────────────────┐ │
│  │ REMOTE DATA SOURCE (API Calls)                    │ │
│  │  - buildConditionalHeaders()                      │ │
│  │  - Send: If-Modified-Since header                 │ │
│  │  - Receive: 304 or 200 + response headers         │ │
│  │  - Extract: ETag, Last-Modified from response     │ │
│  └────────────────────────────────────────────────────┘ │
│                                                         │
│  ┌────────────────────────────────────────────────────┐ │
│  │ LOCAL DATA SOURCE (Hive Cache)                    │ │
│  │  - Read: cached metadata (lastModified, eTag)     │ │
│  │  - Write: new metadata from 200 responses         │ │
│  │  - Location: Hive 'app_cache_box' database        │ │
│  └────────────────────────────────────────────────────┘ │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│                   CORE LAYER                            │
│  - CacheHeadersHelper: Build/extract conditional headers│
│  - CacheConfig: Global timing & Hive key configuration  │
│  - AppHiveBoxes: Single cache box for all features      │
└─────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. **CacheHeadersHelper** (`lib/core/network/cache_headers_helper.dart`)

Global utility for managing HTTP conditional request headers.

#### Key Methods:

```dart
// Build headers from cached metadata
static Map<String, String> buildConditionalHeaders({
  String? ifModifiedSince,  // Last sync timestamp
  String? ifNoneMatch,      // ETag from previous response
})

// Extract cache headers from response
static (String?, String?) extractCacheHeaders(Headers responseHeaders)
  // Returns: (eTag, lastModified)

// Check if 304 Not Modified
static bool isNotModified(int? statusCode)  // true if statusCode == 304
```

#### Example Flow:
```
1. Read cached metadata from Hive
   → lastModified = "Wed, 21 Oct 2025 07:28:00 GMT"
   → eTag = '"33a64df551425fcc"'

2. Build conditional headers
   → {'If-Modified-Since': 'Wed, 21 Oct 2025 07:28:00 GMT',
      'If-None-Match': '"33a64df551425fcc"'}

3. Send request with headers
   → GET /api/products/variants/123/ HTTP/1.1
   → Headers: {...}

4. Server compares timestamps/ETags
   → If resource unchanged: return 304
   → If resource changed: return 200 + new data
```

### 2. **CacheConfig** (`lib/core/storage/cache_config.dart`)

Centralized configuration for all caching behavior.

#### Global Timing:
```dart
static const Duration pollingInterval = Duration(seconds: 30);
  // How often to check for updates via If-Modified-Since requests

static const Duration cacheTTL = Duration(hours: 1);
  // How long to consider cached metadata valid before considering stale

static const Duration refreshIndicatorDuration = Duration(milliseconds: 1500);
  // How long to show loading indicator after polling completes
```

#### Hive Configuration:
```dart
static const String hiveBoxName = 'app_cache_box';
  // Single Hive box shared across ALL features (product detail, category, etc)
  // Prevents multiple box overhead and centralizes cache management
```

#### Key Prefixes (Namespacing):
```dart
// Product Detail Feature
static const String productDetailVariantMetadataPrefix = 'pd:variant_meta:';
  // Format: 'pd:variant_meta:{variantId}'
  // Example: 'pd:variant_meta:variant_789'

static const String productDetailProductMetadataPrefix = 'pd:product_meta:';
  // Format: 'pd:product_meta:{productId}'
  // Example: 'pd:product_meta:product_456'

// Category Feature
static const String categoryMetadataKey = 'cat:list_meta';
static const String categoryProductMetadataPrefix = 'cat:products_meta:';
```

**Why namespacing?** Multiple features use the same Hive box, so prefixes prevent key collisions.

### 3. **ProductDetailCacheDto** (`lib/features/product_details/infrastructure/data_sources/local/product_detail_cache_dto.dart`)

Stores ONLY HTTP metadata, not product data.

```dart
class ProductDetailCacheDto {
  final DateTime lastSyncedAt;        // When we last synced (TTL tracking)
  final String? eTag;                 // HTTP ETag header
  final String? lastModified;         // HTTP Last-Modified header
}
```

**Important:** Product data is NOT stored in Hive. Only metadata for conditional requests.

### 4. **Hive Box Structure** (`lib/core/storage/hive/boxes.dart`)

```dart
class AppHiveBoxes {
  static const String cache = 'app_cache_box';  // Single box for all features
}
```

#### Actual Data in Hive:
```
app_cache_box = {
  'pd:variant_meta:variant_789': {
    'last_synced_at': '2025-11-27T10:30:00.000Z',
    'etag': '"abc123def456"',
    'last_modified': 'Wed, 21 Oct 2025 07:28:00 GMT'
  },
  'pd:product_meta:product_456': {
    'last_synced_at': '2025-11-27T10:25:00.000Z',
    'etag': null,
    'last_modified': 'Tue, 20 Oct 2025 14:15:00 GMT'
  },
  'cat:list_meta': { ... }
}
```

---

## Complete If-Modified-Since Flow

### Step 1: Initial Load (No Cache)

```
User opens product detail page
        ↓
ProductDetailNotifier.getProductDetail(variantId)
        ↓
ProductDetailRepositoryImpl.getProductDetail(variantId)
        ↓
localDataSource.getCachedProductDetail(variantId)  ← Returns null (no cache)
        ↓
remoteDataSource.fetchProductDetail(
  productId: variantId,
  ifModifiedSince: null,  ← No cache, send unconditional request
  ifNoneMatch: null
)
        ↓
ApiClient.get('/api/products/variants/{variantId}/')
  Headers: {}  ← No conditional headers
        ↓
[SERVER PROCESSING]
Server returns 200 OK + new data + response headers
        ↓
Extract response headers:
  - ETag: "abc123def456"
  - Last-Modified: "Wed, 21 Oct 2025 07:28:00 GMT"
        ↓
Save metadata to Hive:
  key: 'pd:variant_meta:variant_789'
  value: {
    'last_synced_at': DateTime.now(),
    'etag': '"abc123def456"',
    'last_modified': 'Wed, 21 Oct 2025 07:28:00 GMT'
  }
        ↓
Return ProductVariant (full data from response)
        ↓
UI displays product detail
```

**Data Volume:** ~50-100KB (full product data downloaded)

---

### Step 2: Polling Check (Every 30 Seconds)

```
Timer fires every 30 seconds
        ↓
ProductDetailNotifier._startPolling()
        ↓
ProductDetailRepositoryImpl.getProductDetail(variantId, forceRefresh: false)
        ↓
localDataSource.getCachedProductDetail(variantId)  ← Returns cached metadata!
  {
    'last_synced_at': DateTime(...),
    'etag': '"abc123def456"',
    'last_modified': 'Wed, 21 Oct 2025 07:28:00 GMT'
  }
        ↓
remoteDataSource.fetchProductDetail(
  productId: variantId,
  ifModifiedSince: 'Wed, 21 Oct 2025 07:28:00 GMT',  ← From cache!
  ifNoneMatch: '"abc123def456"'  ← From cache!
)
        ↓
ApiClient.get('/api/products/variants/{variantId}/')
  Headers: {
    'If-Modified-Since': 'Wed, 21 Oct 2025 07:28:00 GMT',
    'If-None-Match': '"abc123def456"'
  }
        ↓
[SERVER PROCESSING]
Server compares:
  - Request ETag vs stored ETag
  - Request If-Modified-Since vs last modification time
        ↓
        ├─→ Server: "Resource unchanged"
        │   Returns 304 Not Modified (NO BODY)
        │   Response size: ~1KB (headers only)
        │
        └─→ Server: "Resource modified"
            Returns 200 OK + new data + updated headers
            Response size: ~50-100KB
```

---

### Step 3a: Server Returns 304 Not Modified

```
HTTP Response:
  Status: 304 Not Modified
  Body: (empty)
  Headers: (cache control headers only)
        ↓
fetchProductDetail() returns null
        ↓
Check: remoteResponse == null?
  → YES, server returned 304
        ↓
Update lastSyncedAt to reset TTL:
  key: 'pd:variant_meta:variant_789'
  value: {
    'last_synced_at': DateTime.now(),  ← UPDATED
    'etag': '"abc123def456"',          ← UNCHANGED
    'last_modified': 'Wed, 21 Oct 2025 07:28:00 GMT'  ← UNCHANGED
  }
        ↓
Return null from getProductDetail()
        ↓
ProductDetailNotifier receives null
  → Does NOT update state
  → Does NOT refresh UI
  → User sees existing product data (no change)
        ↓
Log: "304 Not Modified (no UI refresh)"
```

**Bandwidth Saved:** ~49-99KB! (vs downloading full product data)

**Timeline:**
- Request sent at: 10:30:00
- 304 response received at: 10:30:02
- Bandwidth: ~1KB (just headers)
- UI stays same: No flicker, no reload

---

### Step 3b: Server Returns 200 OK (Data Changed)

```
HTTP Response:
  Status: 200 OK
  Body: {
    "id": "variant_789",
    "name": "Product Name",
    "price": 29.99,  ← PRICE CHANGED!
    ...more product data...
  }
  Headers:
    ETag: "xyz789abc123"  ← NEW ETag!
    Last-Modified: "Wed, 21 Oct 2025 08:45:00 GMT"  ← UPDATED!
        ↓
fetchProductDetail() returns ProductDetailRemoteResponse:
  {
    productDetail: ProductVariantDto(...),
    fetchedAt: DateTime.now(),
    eTag: '"xyz789abc123"',  ← NEW
    lastModified: 'Wed, 21 Oct 2025 08:45:00 GMT'  ← NEW
  }
        ↓
Check: remoteResponse == null?
  → NO, server returned 200 with new data
        ↓
Save NEW metadata to Hive:
  key: 'pd:variant_meta:variant_789'
  value: {
    'last_synced_at': DateTime.now(),
    'etag': '"xyz789abc123"',          ← UPDATED
    'last_modified': 'Wed, 21 Oct 2025 08:45:00 GMT'  ← UPDATED
  }
        ↓
Return ProductVariant (from response.productDetail.toDomain())
        ↓
ProductDetailNotifier receives new ProductVariant
  → Updates state with new data
  → Rebuilds UI with new price
  → User sees product price change
        ↓
Log: "200 OK (UI will refresh)"
```

**Bandwidth Used:** ~50-100KB (full product data downloaded)

**Timeline:**
- Request sent at: 11:00:00
- 200 response received at: 11:00:02
- Bandwidth: ~50KB (full product data)
- UI refreshes: Price updates in real-time

---

## HTTP Status Codes & Roles

### **200 OK** ✅ Data Changed
```
What it means: Resource HAS been modified since If-Modified-Since timestamp
What to do:
  ✓ Parse response body (contains new data)
  ✓ Save new metadata (Last-Modified, ETag)
  ✓ Update UI with new data

Response size: Full product data (~50-100KB)

Code path in repository:
  if (remoteResponse == null) {
    // This is NOT executed for 200 OK
  } else {
    // 200 OK execution path
    await _localDataSource.cacheProductDetailWithMetadata(variantId, newCacheDto);
    return remoteResponse.productDetail.toDomain();  // Return data
  }
```

### **304 Not Modified** 🔄 No Change
```
What it means: Resource has NOT been modified since If-Modified-Since timestamp
What to do:
  ✓ Ignore response body (it's empty)
  ✓ Update lastSyncedAt (refresh TTL)
  ✓ Keep old metadata (ETag, Last-Modified)
  ✓ Don't refresh UI (return null)

Response size: Headers only (~1KB)

Code path in repository:
  if (remoteResponse == null) {
    // 304 Not Modified execution path
    if (cachedMetadata != null) {
      await _localDataSource.cacheProductDetailWithMetadata(
        variantId,
        cachedMetadata.copyWith(lastSyncedAt: now)  // Only update timestamp
      );
    }
    return null;  // Don't update UI
  }
```

### **Other Status Codes** ⚠️

- **404 Not Found:** Product deleted, throw NetworkException
- **500 Server Error:** Retry or show error screen
- **401 Unauthorized:** User logged out, redirect to login

---

## Hive Database Role & Structure

### What Hive Stores

Hive stores ONLY HTTP metadata for conditional requests:

```
Hive Box: 'app_cache_box'
├── pd:variant_meta:variant_789
│   ├── last_synced_at: "2025-11-27T10:30:00.000Z"
│   ├── etag: '"abc123def456"'
│   └── last_modified: "Wed, 21 Oct 2025 07:28:00 GMT"
│
├── pd:product_meta:product_456
│   ├── last_synced_at: "2025-11-27T10:25:00.000Z"
│   ├── etag: null
│   └── last_modified: "Tue, 20 Oct 2025 14:15:00 GMT"
│
├── cat:list_meta
│   ├── last_synced_at: "2025-11-27T09:50:00.000Z"
│   ├── etag: '"cat123"'
│   └── last_modified: "Mon, 19 Oct 2025 12:00:00 GMT"
│
└── cat:products_meta:category_1
    ├── last_synced_at: "2025-11-27T09:45:00.000Z"
    ├── etag: '"cat_prod_123"'
    └── last_modified: "Mon, 19 Oct 2025 13:30:00 GMT"
```

### What Hive Does NOT Store

❌ Product data (name, price, description, images, reviews)
- These are stored in Riverpod state (in-memory)
- When user navigates away: Riverpod state cleared
- When user returns: `forceRefresh=true` fetches fresh data

### Hive Operations

#### Writing Metadata (On 200 OK):
```dart
// In ProductDetailLocalDataSourceImpl.cacheProductDetailWithMetadata()
final key = 'pd:variant_meta:variant_789';
await _box.put(key, {
  'last_synced_at': DateTime.now().toIso8601String(),
  'etag': '"xyz789abc123"',
  'last_modified': 'Wed, 21 Oct 2025 08:45:00 GMT'
});
```

#### Reading Metadata (On Every Polling):
```dart
// In ProductDetailLocalDataSourceImpl.getCachedProductDetail()
final key = 'pd:variant_meta:variant_789';
final json = _box.get(key) as Map<String, dynamic>?;
return json != null ? ProductDetailCacheDto.fromJson(json) : null;
```

#### Updating Timestamp Only (On 304 Not Modified):
```dart
// In ProductDetailLocalDataSourceImpl.updateProductDetailSyncTime()
final cached = await getCachedProductDetail(variantId);
if (cached != null) {
  await cacheProductDetailWithMetadata(
    variantId,
    cached.copyWith(lastSyncedAt: DateTime.now())  // Only update timestamp
  );
}
```

#### Clearing (On Cache Clear):
```dart
// In ProductDetailLocalDataSourceImpl.clearProductDetail()
final key = 'pd:variant_meta:variant_789';
await _box.delete(key);
```

---

## Timing Configuration

### Polling Interval: 30 Seconds

```dart
// In CacheConfig
static const Duration pollingInterval = Duration(seconds: 30);
```

**Why 30 seconds?**
- ✅ Responsive: User sees updates within 30 seconds
- ✅ Bandwidth efficient: If-Modified-Since prevents full downloads
- ✅ Server friendly: Not too aggressive
- ✅ Real-time enough: Good for product price/inventory updates

**Example Timeline:**
```
10:00:00 - User opens product page
         - Fetch fresh data (200 OK)
         - Save metadata to Hive

10:00:30 - Timer fires, send If-Modified-Since request
         - Server: 304 (no change)
         - 1KB bandwidth used

10:01:00 - Timer fires, send If-Modified-Since request
         - Server: 304 (no change)
         - 1KB bandwidth used

10:01:15 - Product price updated on server

10:01:30 - Timer fires, send If-Modified-Since request
         - Server: 200 OK (price changed!)
         - 50KB bandwidth used
         - UI updates with new price

10:02:00 - Timer fires, send If-Modified-Since request
         - Server: 304 (no change since 10:01:30)
         - 1KB bandwidth used
```

### Cache TTL: 1 Hour

```dart
// In CacheConfig
static const Duration cacheTTL = Duration(hours: 1);
```

**Purpose:** Determine if cached metadata is "stale"

**Current Usage:** Mainly for logging and future validation (not strictly enforced in 304/200 path)

**Future Enhancement:**
```
If (now - lastSyncedAt) > cacheTTL:
  → Metadata considered expired
  → Send unconditional request (ignore cached metadata)
  → Refresh everything
```

### Refresh Indicator Duration: 1.5 Seconds

```dart
// In CacheConfig
static const Duration refreshIndicatorDuration = Duration(milliseconds: 1500);
```

**Purpose:** Show loading indicator during polling

**UX Timeline:**
```
10:00:30 - User taps "Refresh" button
10:00:30 - Loading indicator appears
         - If-Modified-Since request sent
10:00:31 - Server responds (usually within 1 second)
         - If 304: UI unchanged
         - If 200: UI updates with new data
10:00:32.5 - Loading indicator disappears (after 1.5 seconds)
10:00:33 - User sees refreshed data (if any changed)
```

---

## Remote Data Source Implementation

### Building Conditional Headers

**File:** `lib/features/product_details/infrastructure/data_sources/remote/product_detail_remote_data_source.dart`

```dart
Future<ProductDetailRemoteResponse?> fetchProductDetail({
  required String productId,
  String? ifNoneMatch,
  String? ifModifiedSince,
}) async {
  try {
    // Step 1: Build headers map
    final headers = <String, String>{};

    // Step 2: Add conditional headers if provided (from cache)
    if (ifNoneMatch != null) {
      headers['If-None-Match'] = ifNoneMatch;
    }
    if (ifModifiedSince != null) {
      headers['If-Modified-Since'] = ifModifiedSince;
    }

    // Step 3: Log request for debugging
    if (headers.isNotEmpty) {
      developer.log(
        'CONDITIONAL REQUEST for variant $productId\nHeaders: ${headers.toString()}',
        name: 'ProductRemoteDataSource',
      );
    } else {
      developer.log(
        'UNCONDITIONAL REQUEST for variant $productId (no cache)',
        name: 'ProductRemoteDataSource',
      );
    }

    // Step 4: Send request with headers
    final response = await _apiClient.get(
      '/api/products/variants/$productId/',
      headers: headers.isNotEmpty ? headers : null,
    );

    final statusCode = response.statusCode ?? 200;

    // Step 5: Handle 304 Not Modified
    if (statusCode == 304) {
      developer.log('Variant $productId: HTTP 304 (no change)');
      return null;  // Signal "no change"
    }

    // Step 6: Extract new metadata from 200 OK response
    final eTag = response.headers.value('etag') ?? response.headers.value('ETag');
    final lastModified = response.headers.value('last-modified') ??
                         response.headers.value('Last-Modified');

    // Step 7: Return response with extracted metadata
    return ProductDetailRemoteResponse(
      productDetail: ProductVariantDto.fromJson(response.data),
      fetchedAt: DateTime.now(),
      eTag: eTag,
      lastModified: lastModified,
    );
  } on NetworkException catch (error) {
    // Handle 304 wrapped in NetworkException
    if (error.statusCode == 304) {
      return null;
    }
    rethrow;
  }
}
```

---

## Local Data Source Implementation

**File:** `lib/features/product_details/infrastructure/data_sources/local/product_detail_local_data_source.dart`

### Reading Cached Metadata

```dart
Future<ProductDetailCacheDto?> getCachedProductDetail(String productId) async {
  try {
    final key = '${CacheConfig.productDetailVariantMetadataPrefix}$productId';
    final json = _box.get(key) as Map<String, dynamic>?;
    return json != null ? ProductDetailCacheDto.fromJson(json) : null;
  } catch (e) {
    return null;  // If read fails, treat as no cache
  }
}
```

### Writing Metadata

```dart
Future<void> cacheProductDetailWithMetadata(
  String productId,
  ProductDetailCacheDto cacheDto,
) async {
  try {
    final key = '${CacheConfig.productDetailVariantMetadataPrefix}$productId';
    await _box.put(key, cacheDto.toJson());
  } catch (e) {
    rethrow;
  }
}
```

### Updating Timestamp Only

```dart
Future<void> updateProductDetailSyncTime(
  String productId,
  DateTime timestamp,
) async {
  try {
    final cached = await getCachedProductDetail(productId);
    if (cached != null) {
      await cacheProductDetailWithMetadata(
        productId,
        cached.copyWith(lastSyncedAt: timestamp),
      );
    }
  } catch (e) {
    rethrow;
  }
}
```

---

## Repository Implementation

**File:** `lib/features/product_details/infrastructure/repositories/product_detail_repository_impl.dart`

### The Complete Flow

```dart
Future<ProductVariant?> getProductDetail(
  String variantId, {
  bool forceRefresh = false,
}) async {
  try {
    // STEP 1: Get cached metadata from Hive
    final cachedMetadata = await _localDataSource.getCachedProductDetail(variantId);

    if (cachedMetadata != null && !forceRefresh) {
      final cacheAge = DateTime.now().difference(cachedMetadata.lastSyncedAt);
      developer.log(
        'Metadata age ${cacheAge.inSeconds}s (TTL ${cacheTTL.inSeconds}s)',
      );
    }

    // STEP 2: Always fetch from API (metadata prevents re-download on 304)
    final remoteResponse = await _remoteDataSource.fetchProductDetail(
      productId: variantId,
      ifNoneMatch: forceRefresh ? null : cachedMetadata?.eTag,
      ifModifiedSince: forceRefresh ? null : cachedMetadata?.lastModified,
    );

    final now = DateTime.now();

    // STEP 3a: Handle 304 Not Modified (remoteResponse == null)
    if (remoteResponse == null) {
      developer.log('304 Not Modified (no UI refresh)');

      // Update lastSyncedAt to refresh TTL
      if (cachedMetadata != null) {
        await _localDataSource.cacheProductDetailWithMetadata(
          variantId,
          cachedMetadata.copyWith(lastSyncedAt: now),
        );
      }

      return null;  // Controller won't update state/UI
    }

    // STEP 3b: Handle 200 OK (remoteResponse has data)
    developer.log('200 OK (UI will refresh)');

    // Save NEW metadata for next request
    final newCacheDto = ProductDetailCacheDto(
      lastSyncedAt: now,
      eTag: remoteResponse.eTag,
      lastModified: remoteResponse.lastModified,
    );

    await _localDataSource.cacheProductDetailWithMetadata(variantId, newCacheDto);

    return remoteResponse.productDetail.toDomain();  // Return data (UI refreshes)
  } catch (e) {
    rethrow;
  }
}
```

---

## Page-Focused Polling (NEW)

**Problem Solved:** Previously, ALL API polling timers ran continuously regardless of which page the user was viewing. This caused unnecessary API calls and performance issues.

**Solution:** The If-Modified check now runs only for APIs related to the page the user is currently using.

### How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PollingManager (Singleton)                       │
│  - Tracks currently active feature (e.g., 'category_products')      │
│  - Only ONE feature's pollers can run at a time                     │
│  - Pauses all pollers from inactive features                        │
└──────────────────────────────────┬──────────────────────────────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
           ▼                       ▼                       ▼
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│ category_products│    │      cart        │    │  product_detail  │
│     Pollers      │    │     Pollers      │    │     Pollers      │
│  (per category)  │    │   (cart lines)   │    │  (per product)   │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

### Feature Names (Must Match Across Components)

| Tab/Screen | Feature Name | Controller |
|------------|--------------|------------|
| Categories Tab | `category_products` | CategoryProductController |
| Cart Tab | `cart` | CheckoutLineController |
| Product Detail Screen | `product_detail` | ProductDetailController |

### Example Flow

```
1. User opens app (starts on Categories tab)
   → PollingTabController.selectTab(0)
   → PollingManager.setActiveFeature('category_products')
   → Category product pollers START
   → Cart pollers PAUSED (not running)

2. User taps on Cart tab
   → PollingTabController.selectTab(3)
   → PollingManager.setActiveFeature('cart')
   → Category product pollers STOP (timer cancelled)
   → Cart pollers START (timer created)

3. User taps back to Categories tab
   → PollingTabController.selectTab(0)
   → PollingManager.setActiveFeature('category_products')
   → Cart pollers STOP
   → Category product pollers RESTART
```

### Key Components

#### 1. PollingManager (`lib/core/polling/polling_manager.dart`)

```dart
// Set the active feature (pauses all other features)
void setActiveFeature(String featureName);

// Activate a specific poller (also sets active feature)
void activatePoller({required String featureName, required String resourceId});

// Pause all polling (for app background)
void pauseAllPolling();

// Resume polling for active feature (for app foreground)
void resumeActiveFeaturePolling();
```

#### 2. PollingTabController (`lib/core/polling/polling_tab_controller.dart`)

Used by BottomNavigation to manage polling based on tab selection:

```dart
_pollingController = PollingTabController(
  tabToFeature: {
    0: 'category_products',  // Categories tab
    1: 'home',               // Home tab (no polling)
    2: 'wishlist',           // Wishlist tab (no polling)
    3: 'cart',               // Cart tab
  },
);

// When user switches tabs:
_pollingController.selectTab(3);  // Activates 'cart' feature
```

#### 3. Controller Registration Pattern

Controllers do NOT start their timers immediately. Instead:

```dart
// In controller's _initialize():
void _registerForPolling() {
  // Only registers, does NOT start timer
  PollingManager.instance.registerPoller(
    featureName: 'category_products',
    resourceId: categoryId,
    onResume: _startPollingTimer,  // Called when feature becomes active
    onPause: _stopPollingTimer,    // Called when feature becomes inactive
  );
}

// Timer starts ONLY when PollingManager calls onResume
void _startPollingTimer() {
  _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
    await _refreshInternal(forceRemote: false);
  });
}

// Timer stops when PollingManager calls onPause
void _stopPollingTimer() {
  _pollingTimer?.cancel();
  _pollingTimer = null;
}
```

### App Lifecycle Handling

When app goes to background/foreground, BottomNavigation handles it:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    // App came to foreground - resume polling for active feature
    PollingManager.instance.resumeActiveFeaturePolling();
  } else if (state == AppLifecycleState.paused) {
    // App went to background - pause ALL polling
    PollingManager.instance.pauseAllPolling();
  }
}
```

---

## Polling Implementation (Legacy Reference)

**File:** `lib/features/product_details/application/providers/product_detail_providers.dart`

### Starting the Polling Timer

```dart
void _startPollingTimer() {
  if (_pollingTimer != null) return;  // Already polling

  _pollingTimer = Timer.periodic(
    ProductDetailConfig.pollingInterval,  // 30 seconds
    (_) async {
      // This callback fires every 30 seconds
      await _refreshProductDetail(  // Calls getProductDetail
        shouldNotify: true,  // Will notify listeners if data changed
      );
    },
  );

  developer.log('Started polling every ${_pollingInterval.inSeconds}s');
}
```

### Stopping the Polling Timer

```dart
void _stopPollingTimer() {
  _pollingTimer?.cancel();
  _pollingTimer = null;
  developer.log('Stopped polling');
}
```

### Triggering Refresh

```dart
Future<void> _refreshProductDetail({bool shouldNotify = true}) async {
  try {
    // Call repository (which sends If-Modified-Since request)
    final result = await repository.getProductDetail(
      variantId,
      forceRefresh: false,  // Use cache metadata for conditional request
    );

    // result is null (304) or ProductVariant (200)
    if (result != null) {
      // Update state only if 200 OK
      state = AsyncValue.data(result);
    }
    // If null (304), state unchanged (no UI refresh)
  } catch (e) {
    state = AsyncValue.error(e, StackTrace.current);
  }
}
```

---

## Special Case: Product Base API

**File:** `lib/features/product_details/infrastructure/repositories/product_detail_repository_impl.dart`

```dart
Future<ProductBase?> getProductBase(
  String productId, {
  bool forceRefresh = false,
}) async {
  try {
    // IMPORTANT: Product API does NOT support If-Modified-Since!
    // Only fetch fresh data without conditional headers

    developer.log(
      'ProductBase $productId: Fetching fresh (no If-Modified-Since support)',
    );

    // Always fetch fresh without conditional headers
    final remoteResponse = await _remoteDataSource.fetchProductBase(
      productId: productId,
      ifNoneMatch: null,        // ← ALWAYS null (skip conditional)
      ifModifiedSince: null,    // ← ALWAYS null (skip conditional)
    );

    if (remoteResponse == null) {
      return null;
    }

    return remoteResponse.productBase.toDomain();
  } catch (e) {
    rethrow;
  }
}
```

**Why?** The backend's product API doesn't properly support If-Modified-Since headers. Using conditional requests would cause issues, so we always fetch fresh data.

---

## Bandwidth Comparison

### Without If-Modified-Since (Naive Polling)

```
10:00:00 - Initial load: 100KB ✓
10:00:30 - Poll: 100KB ✗
10:01:00 - Poll: 100KB ✗
10:01:30 - Poll: 100KB ✗
10:02:00 - Poll: 100KB ✗

Total per minute: 500KB
Total per hour: 30MB 📈 (Very expensive!)
```

### With If-Modified-Since (Smart Polling)

```
10:00:00 - Initial load: 100KB ✓
10:00:30 - Poll: 1KB (304 not modified) ✓
10:01:00 - Poll: 1KB (304 not modified) ✓
10:01:30 - Poll: 100KB (200 OK, price changed) ✓
10:02:00 - Poll: 1KB (304 not modified) ✓

Total per minute: ~203KB (if one change)
Total per hour: ~2-5MB 📉 (50-90% reduction!)
```

**Savings:** If-Modified-Since reduces bandwidth by **90%** on average!

---

## Debugging & Logging

### Enable Developer Logging

```dart
import 'dart:developer' as developer;

// Logs are printed to console (Android Studio logcat, iOS Xcode)
developer.log(
  'Message here',
  name: 'SomeName',  // Category/tag
  level: 700,        // 0-2000 (higher = more important)
);
```

### Key Log Points

| Log Point | What It Shows |
|-----------|---------------|
| `CONDITIONAL REQUEST` | Sending If-Modified-Since headers |
| `UNCONDITIONAL REQUEST` | First load (no cache) |
| `304 NOT MODIFIED` | Data unchanged, saved bandwidth |
| `200 OK` | Data changed, full download |
| `Metadata age XXXs` | How old cached metadata is |
| `NetworkException` | Network error occurred |

### Example Log Output

```
D/ProductRemoteDataSource: CONDITIONAL REQUEST for variant variant_789
                           Headers: {If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT, If-None-Match: "abc123def456"}

D/RemoteDataSource: Variant variant_789: HTTP 304 (bandwidth optimized)

D/ProductRepo: Variant variant_789: 304 Not Modified (no UI refresh)
```

---

## Key Learnings

### 1. Metadata-Only Caching
- ✅ Only HTTP headers (ETag, Last-Modified) stored in Hive
- ❌ Product data NOT persisted (only in Riverpod state)
- 🎯 Reduces storage, simplifies state management

### 2. Conditional Requests
- Always send If-Modified-Since (if cache exists)
- Server responds: 304 (no change) or 200 (new data)
- Return null (304) to prevent UI refresh

### 3. Hive Single Box
- All features share 'app_cache_box'
- Namespaced keys prevent collisions
- Reduces memory overhead

### 4. Polling Strategy
- 30 second polling interval
- If-Modified-Since prevents full downloads
- Responsive (~30s max delay) yet efficient

### 5. forceRefresh Parameter
- `forceRefresh=false` → Uses cache metadata
- `forceRefresh=true` → Ignores cache, fetches fresh
- Called on navigate back to ensure fresh data

---

## Checklist for New Features

When adding If-Modified-Since caching to a new feature:

- [ ] Create CacheDto class with metadata only
- [ ] Add key prefix to CacheConfig
- [ ] Implement LocalDataSource (get/set/clear)
- [ ] Implement RemoteDataSource (extract headers, handle 304)
- [ ] Implement Repository (orchestrate local + remote)
- [ ] Add polling timer to Notifier/Provider
- [ ] Test: First load, polling 304, polling 200
- [ ] Verify: Hive keys are namespaced correctly
- [ ] Document: API endpoint support for If-Modified-Since

---

## References

### Files in Codebase

- **Core Logic:** [cache_headers_helper.dart](lib/core/network/cache_headers_helper.dart)
- **Configuration:** [cache_config.dart](lib/core/storage/cache_config.dart)
- **Product Details - Local:** [product_detail_local_data_source.dart](lib/features/product_details/infrastructure/data_sources/local/product_detail_local_data_source.dart)
- **Product Details - Remote:** [product_detail_remote_data_source.dart](lib/features/product_details/infrastructure/data_sources/remote/product_detail_remote_data_source.dart)
- **Product Details - Repository:** [product_detail_repository_impl.dart](lib/features/product_details/infrastructure/repositories/product_detail_repository_impl.dart)
- **Product Details - Providers:** [product_detail_providers.dart](lib/features/product_details/application/providers/product_detail_providers.dart)

### HTTP Standards

- [RFC 7232 - HTTP Conditional Requests](https://tools.ietf.org/html/rfc7232)
- [HTTP 304 Not Modified](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/304)
- [HTTP 200 OK](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/200)
- [If-Modified-Since Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since)
- [ETag Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag)

---

**Document Generated:** 2025-11-27
**Project:** Grocery App (Flutter + Riverpod)
**Architecture:** Clean Architecture with If-Modified-Since HTTP Conditional Requests
