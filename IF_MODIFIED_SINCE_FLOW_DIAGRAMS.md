# If-Modified-Since Flow Diagrams

## 1. High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER INTERFACE (Flutter)                     │
│              Product Details Screen / Category Screen            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
         ┌───────────────────────────────────────┐
         │  Application Layer (Riverpod)         │
         │  ┌─────────────────────────────────┐  │
         │  │ProductDetailNotifier             │  │
         │  │ - Manages polling timer          │  │
         │  │ - Calls repository every 30s    │  │
         │  │ - Updates state with new data   │  │
         │  └─────────────────────────────────┘  │
         └────────────┬────────────────────────────┘
                      │
                      ▼
         ┌────────────────────────────────────────┐
         │     DOMAIN LAYER (Repository)          │
         │ ┌──────────────────────────────────┐   │
         │ │ProductDetailRepository           │   │
         │ │ 1. Read metadata from local DS   │   │
         │ │ 2. Send conditional request      │   │
         │ │ 3. Handle 304 vs 200             │   │
         │ │ 4. Save new metadata if 200      │   │
         │ └──────────────────────────────────┘   │
         └────┬──────────────────────────┬────────┘
              │                          │
              ▼                          ▼
    ┌──────────────────────┐   ┌─────────────────────────┐
    │  LOCAL DATA SOURCE   │   │ REMOTE DATA SOURCE      │
    │  (Hive Database)     │   │ (API Client / DIO)      │
    │                      │   │                         │
    │ • Read metadata      │   │ • Build headers         │
    │ • Save metadata      │   │ • Send request          │
    │ • Update timestamp   │   │ • Handle 304 / 200      │
    │ • Clear cache        │   │ • Extract new headers   │
    │                      │   │                         │
    │ Key Format:          │   │ Endpoints:              │
    │ pd:variant_meta:789  │   │ /api/products/          │
    │ pd:product_meta:456  │   │   variants/{id}/        │
    │ cat:list_meta        │   │ /api/products/{id}/     │
    └──────────────────────┘   └─────────────────────────┘
```

---

## 2. Complete Request-Response Cycle (First Load)

```
┌─────────────────────────────────────────────────────────────────────┐
│                          FIRST LOAD (No Cache)                      │
└─────────────────────────────────────────────────────────────────────┘

USER ACTION: Open Product Detail Page
│
▼
ProductDetailNotifier.getProductDetail(variantId)
│
▼
ProductDetailRepositoryImpl.getProductDetail(variantId, forceRefresh: false)
│
├─ STEP 1: Read Hive Cache
│  │
│  localDataSource.getCachedProductDetail(variantId)
│  │
│  └─→ Key: 'pd:variant_meta:variant_789'
│      Returns: null  (no cache exists yet)
│
├─ STEP 2: Send Request
│  │
│  remoteDataSource.fetchProductDetail(
│    productId: variantId,
│    ifModifiedSince: null,      ← No cache!
│    ifNoneMatch: null           ← No cache!
│  )
│  │
│  ├─ Build Headers:
│  │  └─→ {} (empty, no conditional headers)
│  │
│  └─ HTTP Request:
│     GET /api/products/variants/variant_789/ HTTP/1.1
│     Host: api.grocery.com
│     User-Agent: Flutter
│     (no If-Modified-Since header)
│
├─ STEP 3: Server Response
│  │
│  └─→ HTTP/1.1 200 OK
│      ETag: "abc123def456"
│      Last-Modified: Wed, 21 Oct 2025 07:28:00 GMT
│      Content-Length: 87456
│
│      {
│        "id": "variant_789",
│        "productId": "456",
│        "name": "Fresh Apples",
│        "price": 4.99,
│        "stock": 150,
│        ...full product data...
│      }
│
├─ STEP 4: Extract & Cache Headers
│  │
│  Extract:
│    eTag = "abc123def456"
│    lastModified = "Wed, 21 Oct 2025 07:28:00 GMT"
│  │
│  Save to Hive:
│    Key: 'pd:variant_meta:variant_789'
│    Value: {
│      'last_synced_at': '2025-11-27T10:00:00.000Z',
│      'etag': '"abc123def456"',
│      'last_modified': 'Wed, 21 Oct 2025 07:28:00 GMT'
│    }
│
├─ STEP 5: Return Data
│  │
│  Returns: ProductVariant(...)
│  │
│  └─→ ProductDetailNotifier receives data
│      state = AsyncValue.data(ProductVariant)
│
└─ STEP 6: UI Renders
   │
   └─→ Product Detail Screen shows:
       - Fresh Apples
       - Price: $4.99
       - Stock: 150 units
       - [Product images, reviews, etc.]

BANDWIDTH USED: ~87KB (full product data)
TIME TAKEN: ~2 seconds
```

---

## 3. Polling with 304 Not Modified Response

```
┌─────────────────────────────────────────────────────────────────────┐
│                  POLLING CHECK (Every 30 Seconds)                   │
│                    Server: No Data Changed (304)                    │
└─────────────────────────────────────────────────────────────────────┘

TIME: 10:00:30 (30 seconds after first load)

Timer fires!
│
▼
ProductDetailNotifier._startPolling()
│
▼
_refreshProductDetail() [called every 30 seconds]
│
▼
ProductDetailRepositoryImpl.getProductDetail(variantId, forceRefresh: false)
│
├─ STEP 1: Read Hive Cache
│  │
│  localDataSource.getCachedProductDetail(variantId)
│  │
│  └─→ Key: 'pd:variant_meta:variant_789'
│      Returns: ProductDetailCacheDto {
│        lastSyncedAt: 2025-11-27T10:00:00.000Z,
│        eTag: '"abc123def456"',
│        lastModified: 'Wed, 21 Oct 2025 07:28:00 GMT'
│      }
│
├─ STEP 2: Build Conditional Headers
│  │
│  remoteDataSource.fetchProductDetail(
│    productId: variantId,
│    ifModifiedSince: 'Wed, 21 Oct 2025 07:28:00 GMT',  ← FROM CACHE!
│    ifNoneMatch: '"abc123def456"'                      ← FROM CACHE!
│  )
│  │
│  └─ Headers:
│     If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
│     If-None-Match: "abc123def456"
│
└─ STEP 3: Send Conditional Request
   │
   HTTP Request:
   GET /api/products/variants/variant_789/ HTTP/1.1
   Host: api.grocery.com
   If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
   If-None-Match: "abc123def456"
   │
   └─→ Server Processing:
       ├─ Check: "Has variant_789 been modified
       │          since 21 Oct 2025 07:28:00 GMT?"
       │
       ├─ Compare:
       │  └─ Last stored modification time: 21 Oct 2025 07:28:00 GMT
       │  └─ Request If-Modified-Since: 21 Oct 2025 07:28:00 GMT
       │
       └─ Result: SAME → No modification!
│
├─ STEP 4: Server Response (304 Not Modified)
│  │
│  └─→ HTTP/1.1 304 Not Modified
│      ETag: "abc123def456"  (same as before)
│      Cache-Control: public, max-age=3600
│
│      (NO BODY / EMPTY)
│
├─ STEP 5: Handle 304 Response
│  │
│  Check: remoteResponse == null?
│  └─→ YES (304 returns null)
│  │
│  └─ IMPORTANT: Do NOT update UI
│     └─ remoteResponse == null means "no change"
│        → return null from getProductDetail()
│        → ProductDetailNotifier doesn't update state
│        → State stays the same
│        → UI doesn't rebuild
│
├─ STEP 6: Update Sync Timestamp (Reset TTL)
│  │
│  if (cachedMetadata != null) {
│    await localDataSource.cacheProductDetailWithMetadata(
│      variantId,
│      cachedMetadata.copyWith(
│        lastSyncedAt: DateTime.now()  ← UPDATE ONLY THIS
│      )
│    );
│  }
│  │
│  └─ Update Hive:
│     Key: 'pd:variant_meta:variant_789'
│     Value: {
│       'last_synced_at': '2025-11-27T10:00:30.000Z',  ← CHANGED!
│       'etag': '"abc123def456"',                       ← UNCHANGED
│       'last_modified': 'Wed, 21 Oct 2025 07:28:00 GMT' ← UNCHANGED
│     }
│
├─ STEP 7: Return null
│  │
│  Returns: null
│  │
│  └─→ ProductDetailNotifier receives null
│      → Doesn't update state
│      → Doesn't notify listeners
│      → UI stays unchanged
│
└─ RESULT:

   USER SEES: Same product detail (Fresh Apples, $4.99, 150 stock)
   BANDWIDTH USED: ~1KB (headers only, no body)
   TIME TAKEN: ~1 second

   BENEFIT: 87KB saved! (99% bandwidth reduction for this check!)
```

---

## 4. Polling with 200 OK Response (Data Changed)

```
┌─────────────────────────────────────────────────────────────────────┐
│                  POLLING CHECK (Every 30 Seconds)                   │
│                    Server: Data Changed (200 OK)                    │
└─────────────────────────────────────────────────────────────────────┘

TIME: 10:01:15 (Product price changed on server)
TIME: 10:01:30 (Next polling check)

Timer fires!
│
▼
_refreshProductDetail()
│
▼
ProductDetailRepositoryImpl.getProductDetail(variantId, forceRefresh: false)
│
├─ STEP 1: Read Hive Cache
│  │
│  localDataSource.getCachedProductDetail(variantId)
│  │
│  └─→ Returns: ProductDetailCacheDto {
│        lastSyncedAt: 2025-11-27T10:00:30.000Z,
│        eTag: '"abc123def456"',
│        lastModified: 'Wed, 21 Oct 2025 07:28:00 GMT'
│      }
│
├─ STEP 2: Build Conditional Headers
│  │
│  Headers:
│    If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
│    If-None-Match: "abc123def456"
│
└─ STEP 3: Send Conditional Request
   │
   GET /api/products/variants/variant_789/ HTTP/1.1
   If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
   If-None-Match: "abc123def456"
   │
   └─→ Server Processing:
       ├─ Check: "Has variant_789 been modified?"
       │
       ├─ Compare:
       │  └─ Last stored modification time: 21 Oct 2025 08:45:00 GMT
       │  └─ Request If-Modified-Since: 21 Oct 2025 07:28:00 GMT
       │
       └─ Result: DIFFERENT! → Modified at 21 Oct 08:45:00 GMT
                                (after 07:28:00 GMT)
│
├─ STEP 4: Server Response (200 OK with new data!)
│  │
│  └─→ HTTP/1.1 200 OK
│      ETag: "xyz789abc123"          ← NEW ETag!
│      Last-Modified: Wed, 21 Oct 2025 08:45:00 GMT  ← NEW timestamp!
│      Content-Length: 89234
│
│      {
│        "id": "variant_789",
│        "productId": "456",
│        "name": "Fresh Apples",
│        "price": 5.99,              ← CHANGED! (was 4.99)
│        "stock": 145,               ← CHANGED! (was 150)
│        ...full updated product data...
│      }
│
├─ STEP 5: Handle 200 Response
│  │
│  Check: remoteResponse == null?
│  └─→ NO (200 OK returns data)
│  │
│  remoteResponse = ProductDetailRemoteResponse {
│    productDetail: ProductVariantDto(...),
│    eTag: '"xyz789abc123"',
│    lastModified: 'Wed, 21 Oct 2025 08:45:00 GMT'
│  }
│
├─ STEP 6: Save NEW Metadata
│  │
│  newCacheDto = ProductDetailCacheDto(
│    lastSyncedAt: DateTime.now(),
│    eTag: '"xyz789abc123"',           ← NEW
│    lastModified: 'Wed, 21 Oct 2025 08:45:00 GMT'  ← NEW
│  );
│  │
│  await localDataSource.cacheProductDetailWithMetadata(
│    variantId,
│    newCacheDto
│  );
│  │
│  └─ Update Hive:
│     Key: 'pd:variant_meta:variant_789'
│     Value: {
│       'last_synced_at': '2025-11-27T10:01:30.000Z',
│       'etag': '"xyz789abc123"',           ← UPDATED
│       'last_modified': 'Wed, 21 Oct 2025 08:45:00 GMT'  ← UPDATED
│     }
│
├─ STEP 7: Return New Data
│  │
│  Returns: ProductVariant(
│    id: 'variant_789',
│    price: 5.99,      ← UPDATED
│    stock: 145,       ← UPDATED
│    ...
│  )
│  │
│  └─→ ProductDetailNotifier receives NEW data
│      state = AsyncValue.data(NEW ProductVariant)
│      → Notifies all listeners
│
└─ RESULT:

   USER SEES: Product price changed from $4.99 to $5.99
              Stock decreased from 150 to 145 units
              UI smoothly updates without full screen reload

   BANDWIDTH USED: ~89KB (full product data)
   TIME TAKEN: ~2 seconds

   Note: Full download necessary because data changed
         But only paid bandwidth for this one poll (not every 30 seconds!)
```

---

## 5. State Diagram: Metadata Cache Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│              METADATA CACHE STATE MACHINE                   │
└─────────────────────────────────────────────────────────────┘

                    ┌──────────────────┐
                    │   NO CACHE       │
                    │ (First Visit)    │
                    └────────┬─────────┘
                             │
                  User opens product page
                             │
                             ▼
                    ┌──────────────────┐
                    │  CACHE MISS      │
                    │ Send unconditional│
                    │ request (no If-* │
                    │ headers)         │
                    └────────┬─────────┘
                             │
                  Server returns 200 OK
                  + ETag + Last-Modified
                             │
                             ▼
                    ┌──────────────────────────────┐
                    │   METADATA CACHED            │
                    │ (in Hive app_cache_box)      │
                    │ {                            │
                    │  lastSyncedAt: now,          │
                    │  eTag: "abc123...",          │
                    │  lastModified: "Wed, 21..." │
                    │ }                            │
                    └────────┬─────────────────────┘
                             │
                    30 second timer fires
                             │
                             ▼
                    ┌──────────────────────────────┐
                    │  CONDITIONAL REQUEST SENT    │
                    │ Headers:                     │
                    │ - If-Modified-Since: ...     │
                    │ - If-None-Match: ...         │
                    └────────┬────────────────┬────┘
                             │                │
              Server: No change     Server: Data changed
              (304 Not Modified)    (200 OK + new data)
                             │                │
                    ┌────────▼────┐   ┌───────▼─────────┐
                    │UPDATE TTL   │   │UPDATE METADATA  │
                    │             │   │                 │
                    │lastSyncedAt │   │lastSyncedAt: .. │
                    │updated to   │   │eTag: "xyz789.."│
                    │now()        │   │lastModified: ..│
                    │             │   │                 │
                    │OTHER FIELDS │   │(All from new    │
                    │UNCHANGED    │   │response headers)│
                    └────────┬────┘   └───────┬─────────┘
                             │                │
                    Return null        Return ProductVariant
                    No UI update       UI updates
                             │                │
                             └────────┬───────┘
                                      │
                      30 second timer fires again
                                      │
                             (Loop continues)
```

---

## 6. Hive Database Structure

```
┌──────────────────────────────────────────────────────────┐
│                 HIVE DATABASE                            │
│              'app_cache_box' Box                         │
└──────────────────────────────────────────────────────────┘

Content:
{
  // Product Detail Feature - Variant API
  'pd:variant_meta:variant_789': {
    'last_synced_at': '2025-11-27T10:01:30.000Z',
    'etag': '"xyz789abc123"',
    'last_modified': 'Wed, 21 Oct 2025 08:45:00 GMT'
  },

  'pd:variant_meta:variant_123': {
    'last_synced_at': '2025-11-27T09:30:00.000Z',
    'etag': '"def456ghi789"',
    'last_modified': 'Tue, 20 Oct 2025 14:20:00 GMT'
  },

  // Product Detail Feature - Product API
  'pd:product_meta:product_456': {
    'last_synced_at': '2025-11-27T10:00:00.000Z',
    'etag': null,  ← Product API doesn't use ETag
    'last_modified': 'Mon, 19 Oct 2025 10:00:00 GMT'
  },

  // Category Feature - Category List
  'cat:list_meta': {
    'last_synced_at': '2025-11-27T09:50:00.000Z',
    'etag': '"cat_list_123"',
    'last_modified': 'Fri, 17 Oct 2025 16:30:00 GMT'
  },

  // Category Feature - Products by Category
  'cat:products_meta:category_1': {
    'last_synced_at': '2025-11-27T09:45:00.000Z',
    'etag': '"cat_prod_1_xyz"',
    'last_modified': 'Fri, 17 Oct 2025 17:15:00 GMT'
  },

  'cat:products_meta:category_2': {
    'last_synced_at': '2025-11-27T09:40:00.000Z',
    'etag': '"cat_prod_2_abc"',
    'last_modified': 'Fri, 17 Oct 2025 18:00:00 GMT'
  }
}

Key Naming Convention:
├── Feature Abbreviation (pd, cat)
├── Colon (:)
├── Data Type (variant_meta, product_meta, list_meta, etc)
├── Colon (:) [if needed]
└── Resource ID (variant_789, product_456, category_1, etc)

Benefits:
✓ Namespace isolation (no key collisions)
✓ Easy to find related keys with prefix matching
✓ Scalable for adding new features
✓ Single box prevents memory overhead
```

---

## 7. Request Timeline Visualization

```
TIME          ACTION                          METADATA STATE           BANDWIDTH    UI STATE
────          ──────────────────────────────  ─────────────────────   ──────────   ──────────

10:00:00      User opens product page
              │
              └─→ getProductDetail()
                  └─→ Check Hive              No cache
                  └─→ Send request (no If-*)
                  └─→ Receive 200 OK + headers
                                              Cache metadata          ~87KB        Loading
                                              Save to Hive            ↓
                                              {                       ✓ Received   ↓
                                               last_synced_at: now,   Done        ✓ Showing
                                               eTag: "abc123...",                 Fresh Apples
                                               lastModified: "Wed.."              $4.99
                                              }                                   150 stock

10:00:01      UI renders product detail                                         ✓ Display done

10:00:30      Timer fires (30s polling)
              │
              └─→ getProductDetail()
                  └─→ Check Hive              {
                  └─→ Found cache!              last_synced_at: 10:00:00
                  └─→ Build If-Modified-Since   eTag: "abc123..."
                  └─→ Send request              lastModified: "Wed.."
                  └─→ Receive 304 Not Modified }                      ~1KB        ✓ Fresh Apples
                                              Update lastSyncedAt     ↓           $4.99
                                              {                       304         150 stock
                                               last_synced_at: now ←  ✓ Received  (unchanged)
                                               eTag: "abc123...",  (ONLY THIS
                                               lastModified: ".."  CHANGED)
                                              }

10:00:32      UI stays same (no refresh)                            No update   ✓ Same

10:01:00      Timer fires (30s polling)
              │
              └─→ getProductDetail()
                  └─→ Check Hive              {
                  └─→ Found cache!              last_synced_at: 10:00:30
                  └─→ Send If-Modified-Since    eTag: "abc123..."
                  └─→ Receive 304              lastModified: "Wed.."
                                              }                      ~1KB        ✓ Same
                                                                      304

10:01:15      [On server: Product price     (Cache unchanged)        N/A         ✓ Same
              changes to $5.99]

10:01:30      Timer fires (30s polling)
              │
              └─→ getProductDetail()
                  └─→ Check Hive
                  └─→ Send If-Modified-Since
                  └─→ Receive 200 OK!         {
                  └─→ Extract new metadata      last_synced_at: now
                                               eTag: "xyz789..." ←  UPDATED
                                               lastModified: "Wed  UPDATED
                                               21 Oct 08:45"
                                              }                      ~89KB       ✓ Loading
                                              Save to Hive           ↓
                                                                     200 OK
                                                                     ✓ Received

10:01:32      UI refreshes (new price!)                            Update      ✓ Fresh Apples
                                                                    Complete    $5.99 ← Changed!
                                                                                145 stock
                                                                                ← Changed!

10:02:00      Timer fires (30s polling)
              │
              └─→ getProductDetail()
                  └─→ Check Hive              {
                  └─→ Send If-Modified-Since    last_synced_at: 10:01:32
                  └─→ Receive 304              eTag: "xyz789..."
                                              lastModified: "..."
                                              }                      ~1KB        ✓ $5.99
                                              Update lastSyncedAt                145 stock
                                              (only timestamp)                   (unchanged
                                                                                 since 10:01)
```

---

## 8. Decision Tree: When to Use If-Modified-Since

```
                        ┌──────────────────┐
                        │ New API Endpoint │
                        └────────┬─────────┘
                                 │
                    ┌────────────▼────────────┐
                    │ Does server support    │
                    │ If-Modified-Since &    │
                    │ ETag headers?          │
                    └────┬────────────────┬──┘
                         │                │
                    YES  │                │  NO
                         ▼                ▼
                  ┌────────────┐    ┌──────────────┐
                  │ Use        │    │ Fetch fresh  │
                  │ If-Mod-    │    │ every time   │
                  │ Since      │    │ (no caching) │
                  └──────┬─────┘    └──────┬───────┘
                         │                 │
          ┌──────────────▼─────────────────┘
          │
          ├─ Data changes frequently?
          │  ├─ YES → 30s polling interval (responsive)
          │  └─ NO  → 5m polling interval (efficient)
          │
          └─ Store data in Hive?
             ├─ Metadata ONLY → Current approach ✓
             └─ Full data → Consider alternatives
```

---

## 9. Example Request/Response Headers

### Initial Request (No Cache)

```
GET /api/products/variants/variant_789/ HTTP/1.1
Host: api.grocery.com
User-Agent: Flutter/Dio
Accept: application/json

---

HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 87456
ETag: "abc123def456"
Last-Modified: Wed, 21 Oct 2025 07:28:00 GMT
Cache-Control: public, max-age=3600
Date: Wed, 21 Oct 2025 10:00:00 GMT

{
  "id": "variant_789",
  ...full product data...
}
```

### Conditional Request (Cache Exists, No Change)

```
GET /api/products/variants/variant_789/ HTTP/1.1
Host: api.grocery.com
User-Agent: Flutter/Dio
If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
If-None-Match: "abc123def456"

---

HTTP/1.1 304 Not Modified
ETag: "abc123def456"
Cache-Control: public, max-age=3600
Date: Wed, 21 Oct 2025 10:00:30 GMT

(no body)
```

### Conditional Request (Cache Exists, Data Changed)

```
GET /api/products/variants/variant_789/ HTTP/1.1
Host: api.grocery.com
User-Agent: Flutter/Dio
If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
If-None-Match: "abc123def456"

---

HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 89234
ETag: "xyz789abc123"
Last-Modified: Wed, 21 Oct 2025 08:45:00 GMT
Cache-Control: public, max-age=3600
Date: Wed, 21 Oct 2025 10:01:30 GMT

{
  "id": "variant_789",
  "price": 5.99,
  "stock": 145,
  ...updated product data...
}
```

---

## 10. Code Flow Sequence Diagram (ASCII)

```
┌──────────┐    ┌─────────────┐    ┌────────┐    ┌──────────┐    ┌────────┐
│   User   │    │  Notifier   │    │  Repo  │    │  Local   │    │ Remote │
│          │    │             │    │        │    │  Source  │    │ Source │
└────┬─────┘    └──────┬──────┘    └───┬────┘    └────┬─────┘    └───┬────┘
     │                 │                │             │              │
     │ Open Page       │                │             │              │
     │────────────────>│                │             │              │
     │                 │ getDetail()    │             │              │
     │                 │───────────────>│             │              │
     │                 │                │ getCached() │              │
     │                 │                │────────────>│              │
     │                 │                │             │ Check Hive   │
     │                 │                │             │ {returns }  │
     │                 │                │<────────────│              │
     │                 │                │             │              │
     │                 │                │ fetch()     │              │
     │                 │                │─────────────────────────> │
     │                 │                │             │ Send request │
     │                 │                │             │ (no If-*) │
     │                 │                │             │              │
     │                 │                │             │   [Network]  │
     │                 │                │             │              │
     │                 │                │             │<────────────│
     │                 │                │             │ HTTP 200 OK  │
     │                 │                │             │ + ETag      │
     │                 │                │             │ + Last-Mod  │
     │                 │                │<──────────────────────────│
     │                 │                │             │              │
     │                 │                │ cache()     │              │
     │                 │                │────────────>│              │
     │                 │                │             │ Save to Hive │
     │                 │                │<────────────│              │
     │                 │<───────────────│              │              │
     │                 │ ProductVariant │              │              │
     │                 │ data           │              │              │
     │                 │ (state update) │              │              │
     │<────────────────│                │              │              │
     │ UI displays    │                │              │              │
     │                │                │              │              │
     │ [30s later]    │                │              │              │
     │                │ Timer fires    │              │              │
     │                │────────────────>│              │              │
     │                │                 │ getDetail() │              │
     │                │                 │───────────>│              │
     │                │                 │             │ getCached() │
     │                │                 │             │────────────>│
     │                │                 │             │<────────────│
     │                │                 │             │ returns {   │
     │                │                 │             │  eTag:...,  │
     │                │                 │             │  lastMod... │
     │                │                 │             │ }           │
     │                │                 │             │              │
     │                │                 │ fetch()     │              │
     │                │                 │ (with If-*) │              │
     │                │                 │─────────────────────────> │
     │                │                 │             │ Send with   │
     │                │                 │             │ conditional │
     │                │                 │             │ headers     │
     │                │                 │             │              │
     │                │                 │             │   [Network]  │
     │                │                 │             │              │
     │                │                 │             │<────────────│
     │                │                 │             │ HTTP 304    │
     │                │                 │             │ Not Modified│
     │                │                 │             │ (no body)   │
     │                │                 │<──────────────────────────│
     │                │                 │             │              │
     │                │                 │ (null)      │              │
     │                │ (null)          │             │              │
     │                │ NO UPDATE       │             │              │
     │ UI unchanged  │                │              │              │
     │                │                │              │              │
```

---

**All diagrams created:** 2025-11-27
**For:** Grocery App - If-Modified-Since Caching System
