# If-Modified-Since Quick Reference Guide

## TL;DR (Too Long; Didn't Read)

**What:** HTTP caching using If-Modified-Since headers to skip downloading full data when nothing changed.

**Why:** Save 90% bandwidth on polling checks (304 = 1KB vs 200 = 100KB).

**How:**
1. Cache metadata (ETag, Last-Modified) in Hive
2. Send metadata with next request as conditional headers
3. Server: 304 (no change) or 200 (new data)
4. Return null (304) or data (200) to prevent/trigger UI refresh

---

## 30-Second Summary

| Step | Action | Details |
|------|--------|---------|
| **First Load** | Send no headers | GET /api/products/variant/123 (no If-*) |
| **Response** | Get 200 + metadata | HTTP 200 OK, ETag: "abc123", Last-Modified: "..." |
| **Cache** | Save metadata | Store in Hive: {eTag, lastModified, timestamp} |
| **Polling** | Check every 30s | Send cached metadata as If-Modified-Since headers |
| **304 Response** | No change | Return null, don't update UI, save 99% bandwidth |
| **200 Response** | Data changed | Return new data, UI updates, save metadata again |

---

## HTTP Status Codes

### **200 OK** ✅

**Meaning:** Resource has changed since If-Modified-Since

```
Response: Full product data included
Size: ~50-100KB
Action:
  ✓ Parse response body
  ✓ Save new metadata
  ✓ Update state/UI
```

### **304 Not Modified** 🔄

**Meaning:** Resource hasn't changed since If-Modified-Since

```
Response: No body (empty)
Size: ~1KB (headers only)
Action:
  ✓ Ignore response body
  ✓ Update sync timestamp
  ✓ Return null (don't update UI)
```

---

## Key Files

| File | Purpose |
|------|---------|
| [cache_headers_helper.dart](lib/core/network/cache_headers_helper.dart) | Build/extract conditional headers |
| [cache_config.dart](lib/core/storage/cache_config.dart) | Global timing & Hive config |
| [product_detail_cache_dto.dart](lib/features/product_details/infrastructure/data_sources/local/product_detail_cache_dto.dart) | Metadata DTO (not product data) |
| [product_detail_local_data_source.dart](lib/features/product_details/infrastructure/data_sources/local/product_detail_local_data_source.dart) | Hive read/write |
| [product_detail_remote_data_source.dart](lib/features/product_details/infrastructure/data_sources/remote/product_detail_remote_data_source.dart) | API calls + header extraction |
| [product_detail_repository_impl.dart](lib/features/product_details/infrastructure/repositories/product_detail_repository_impl.dart) | Orchestrates local + remote |

---

## Configuration Constants

```dart
// In CacheConfig
pollingInterval       = 30 seconds        // How often to check
cacheTTL              = 1 hour            // How long metadata valid
refreshIndicatorTime  = 1.5 seconds       // Loading indicator duration
hiveBoxName           = 'app_cache_box'   // Single box for all features

// Key prefixes (namespacing)
pd:variant_meta:      // Product variant metadata
pd:product_meta:      // Product base metadata
cat:list_meta         // Category list metadata
cat:products_meta:    // Category products metadata
```

---

## Hive Database Keys

```
Format: {prefix}{resourceId}

Examples:
  'pd:variant_meta:variant_789'
  'pd:product_meta:product_456'
  'cat:list_meta'
  'cat:products_meta:category_1'

Stored Value:
  {
    'last_synced_at': '2025-11-27T10:00:00.000Z',
    'etag': '"abc123def456"' or null,
    'last_modified': 'Wed, 21 Oct 2025 07:28:00 GMT' or null
  }
```

---

## Complete Request-Response Examples

### Initial Request
```
GET /api/products/variants/123/ HTTP/1.1
(no If-Modified-Since header)

→ HTTP 200 OK
  ETag: "abc123"
  Last-Modified: Wed, 21 Oct 2025 07:28:00 GMT
  [Full product data]
```

### Conditional Request (No Change)
```
GET /api/products/variants/123/ HTTP/1.1
If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
If-None-Match: "abc123"

→ HTTP 304 Not Modified
  (no body)
```

### Conditional Request (Changed)
```
GET /api/products/variants/123/ HTTP/1.1
If-Modified-Since: Wed, 21 Oct 2025 07:28:00 GMT
If-None-Match: "abc123"

→ HTTP 200 OK
  ETag: "xyz789" (NEW)
  Last-Modified: Wed, 21 Oct 2025 08:45:00 GMT (NEW)
  [Updated product data]
```

---

## API Method Signatures

### Build Headers
```dart
CacheHeadersHelper.buildConditionalHeaders({
  String? ifModifiedSince,
  String? ifNoneMatch,
}) → Map<String, String>
```

### Extract Headers
```dart
CacheHeadersHelper.extractCacheHeaders(Headers headers)
  → (String? eTag, String? lastModified)
```

### Check If Not Modified
```dart
CacheHeadersHelper.isNotModified(int? statusCode) → bool
// Returns true if statusCode == 304
```

---

## Code Patterns

### Reading Cache (Local Data Source)
```dart
final cached = await localDataSource.getCachedProductDetail(variantId);
// Returns: ProductDetailCacheDto | null
```

### Sending Conditional Request (Remote Data Source)
```dart
final response = await remoteDataSource.fetchProductDetail(
  productId: variantId,
  ifModifiedSince: cached?.lastModified,
  ifNoneMatch: cached?.eTag,
);
// Returns: ProductDetailRemoteResponse | null (304)
```

### Handling Response (Repository)
```dart
if (remoteResponse == null) {
  // 304 Not Modified
  return null;  // Don't update UI
} else {
  // 200 OK
  await localDataSource.cacheProductDetailWithMetadata(variantId, newMetadata);
  return remoteResponse.productDetail.toDomain();  // Update UI
}
```

---

## Bandwidth Comparison

### Without If-Modified-Since
- Every request: ~100KB
- 30-second polls: 2 requests/minute = 200KB/min
- Per hour: **12MB** 📈

### With If-Modified-Since
- Initial load: ~100KB
- 304 responses: ~1KB each
- Average (assuming 1 change/minute): ~2KB/min = ~120KB/hour
- Per hour: **~2-5MB** 📉

**Savings: 90%+** ✨

---

## Logging for Debugging

### View Logs
Android Studio → Logcat (filter by "ProductRepo" or "RemoteDataSource")

### Log Points
```
UNCONDITIONAL REQUEST    → First load
CONDITIONAL REQUEST      → Polling with cache
HTTP 304                 → No change, saved bandwidth
HTTP 200                 → Data changed, UI updates
NetworkException         → Network error
```

### Example Output
```
I/ProductRemoteDataSource: CONDITIONAL REQUEST for variant variant_789
                           Headers: {If-Modified-Since: Wed, 21 Oct..., If-None-Match: "abc123"}

I/RemoteDataSource: Variant variant_789: HTTP 304 (bandwidth optimized)

I/ProductRepo: Variant variant_789: 304 Not Modified (no UI refresh)
```

---

## Common Questions

**Q: Where is product data stored?**
A: In Riverpod state (in-memory). When user navigates away, state is cleared. Only metadata is stored in Hive.

**Q: What if I want to force-refresh (ignore cache)?**
A: Use `forceRefresh: true` parameter: `getProductDetail(variantId, forceRefresh: true)`. Passes null for conditional headers.

**Q: Can I change the polling interval?**
A: Modify `CacheConfig.pollingInterval` (currently 30 seconds).

**Q: What if the server doesn't support If-Modified-Since?**
A: The endpoint should NOT use conditional requests. Example: Product Base API always fetches fresh.

**Q: How long do I keep cached metadata?**
A: `CacheConfig.cacheTTL = 1 hour`. After 1 hour without sync, metadata is considered stale (but still used for now).

**Q: What if network fails during polling?**
A: NetworkException is thrown and caught. State becomes error, UI shows error message.

**Q: Multiple features sharing Hive?**
A: Yes! Single 'app_cache_box' used by all features (product detail, category, etc). Namespaced keys prevent conflicts.

---

## Architecture Layer Mapping

```
Presentation (UI)
  ↓ getProductDetail()
  ↓
Riverpod Notifiers
  ↓ setProductDetail() / state updates
  ↓
Repositories (Domain)
  ↓ Logic: "If 304, return null; if 200, save + return"
  ↓
┌─────────────────────┐
│ Data Sources        │
├─────────────────────┤
│ Local (Hive) ← read metadata, write metadata
│ Remote (API) ← send conditional headers, extract headers
└─────────────────────┘
  ↓
Core Helpers
  ├─ CacheHeadersHelper (build/extract headers)
  └─ CacheConfig (global config)
```

---

## Testing Checklist

- [ ] **First Load:** No cache → Unconditional request → 200 OK → Save metadata → UI displays
- [ ] **Polling (No Change):** Conditional request → 304 → Return null → UI unchanged
- [ ] **Polling (Changed):** Conditional request → 200 → Save metadata → UI updates
- [ ] **Force Refresh:** `forceRefresh=true` → Unconditional request → Always fetch fresh
- [ ] **Network Error:** Exception handled → State becomes error → UI shows error
- [ ] **Hive Keys:** Verify keys use correct prefixes (pd:variant_meta:, etc.)
- [ ] **Metadata Format:** Verify JSON structure in Hive matches ProductDetailCacheDto
- [ ] **Logging:** Check debug logs for CONDITIONAL REQUEST, 304, 200

---

## Adding New Feature with If-Modified-Since

1. **Create CacheDto** (metadata only)
2. **Add prefix to CacheConfig** (e.g., 'feature:data_meta:')
3. **Implement LocalDataSource** (get/set/clear)
4. **Implement RemoteDataSource** (build headers, extract headers, handle 304)
5. **Implement Repository** (orchestrate, return null on 304)
6. **Add Polling** (Timer every 30s)
7. **Test:** All flows above
8. **Document:** How API supports If-Modified-Since

---

## Common Pitfalls to Avoid

❌ **Storing full product data in Hive**
- Use metadata-only approach (lastModified, eTag, timestamp)

❌ **Updating UI on 304 response**
- Return null when remoteResponse == null

❌ **Forgetting to extract headers from 200 response**
- Always save new ETag and Last-Modified from response

❌ **Sending conditional headers on forceRefresh**
- When `forceRefresh=true`, pass null for headers

❌ **Using different Hive boxes per feature**
- Use single 'app_cache_box' with namespaced keys

❌ **Not checking statusCode == 304**
- Some servers return 304 as NetworkException, need special handling

---

## Performance Metrics

| Metric | Value | Impact |
|--------|-------|--------|
| Polling Interval | 30 seconds | Real-time responsiveness |
| Cache TTL | 1 hour | Metadata freshness |
| Typical 200 Response | 50-100KB | Full product data |
| Typical 304 Response | ~1KB | Headers only |
| Bandwidth Reduction | ~90% | On unchanged data |
| API Calls Reduction | ~90% | Frequent polling possible |

---

## Resources

- **RFC 7232:** HTTP Conditional Requests specification
- **Dio Package:** HTTP client used (supports custom headers)
- **Hive:** Local database for metadata persistence
- **Riverpod:** State management (notifiers, async values)
- **Flutter Docs:** HTTP Headers, Async Programming

---

## Quick Start for New Developers

1. **Understand the flow:** Read [IF_MODIFIED_SINCE_ARCHITECTURE.md](IF_MODIFIED_SINCE_ARCHITECTURE.md)
2. **See visual diagrams:** Check [IF_MODIFIED_SINCE_FLOW_DIAGRAMS.md](IF_MODIFIED_SINCE_FLOW_DIAGRAMS.md)
3. **Review implementation:** Look at [product_detail_repository_impl.dart](lib/features/product_details/infrastructure/repositories/product_detail_repository_impl.dart)
4. **Debug with logs:** Filter Logcat for "ProductRepo" or "RemoteDataSource"
5. **Test all scenarios:** Use checklist above

---

**Last Updated:** 2025-11-27
**For:** Grocery App Team
**Questions?** See IF_MODIFIED_SINCE_ARCHITECTURE.md for detailed explanation
