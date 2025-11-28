# If-Modified-Since HTTP Caching System - Complete Documentation

## 📚 Documentation Index

This project implements an advanced HTTP conditional request caching system using **If-Modified-Since** headers to reduce bandwidth consumption by **90%+** on polling checks.

### 📖 Available Documentation

| Document | Purpose | For Whom |
|----------|---------|----------|
| **[IF_MODIFIED_SINCE_QUICK_REFERENCE.md](IF_MODIFIED_SINCE_QUICK_REFERENCE.md)** | 30-second overview + key facts | Quick lookup, anyone |
| **[IF_MODIFIED_SINCE_ARCHITECTURE.md](IF_MODIFIED_SINCE_ARCHITECTURE.md)** | Complete architectural explanation | Architecture understanding, deep dive |
| **[IF_MODIFIED_SINCE_FLOW_DIAGRAMS.md](IF_MODIFIED_SINCE_FLOW_DIAGRAMS.md)** | Visual flow diagrams and state machines | Visual learners, debugging |
| **[IF_MODIFIED_SINCE_CODE_EXAMPLES.md](IF_MODIFIED_SINCE_CODE_EXAMPLES.md)** | Complete code examples + patterns | Developers implementing features |
| **[IF_MODIFIED_SINCE_README.md](IF_MODIFIED_SINCE_README.md)** | This file - navigation guide | Finding what you need |

---

## 🚀 Quick Start

### For First-Time Learners
1. Read: [Quick Reference](IF_MODIFIED_SINCE_QUICK_REFERENCE.md) (5 min)
2. View: [Flow Diagrams](IF_MODIFIED_SINCE_FLOW_DIAGRAMS.md) (10 min)
3. Read: [Architecture](IF_MODIFIED_SINCE_ARCHITECTURE.md) (20 min)

### For Developers Adding Features
1. Reference: [Code Examples](IF_MODIFIED_SINCE_CODE_EXAMPLES.md) - Copy patterns
2. Check: [Quick Reference](IF_MODIFIED_SINCE_QUICK_REFERENCE.md) - Configuration
3. Read: [Architecture](IF_MODIFIED_SINCE_ARCHITECTURE.md) - Fill understanding gaps

### For Code Reviews
1. Check: [Architecture](IF_MODIFIED_SINCE_ARCHITECTURE.md) - Design principles
2. Reference: [Code Examples](IF_MODIFIED_SINCE_CODE_EXAMPLES.md) - Expected patterns
3. Test: Against [testing checklist](IF_MODIFIED_SINCE_QUICK_REFERENCE.md#testing-checklist)

---

## 📝 What This System Does

### The Problem
Normal API polling every 30 seconds downloads ~100KB of product data each time, even when nothing changed.

```
Without If-Modified-Since:
30 requests/minute × 100KB = 3MB/minute = 180MB/hour 📈 WASTEFUL!
```

### The Solution
Use HTTP conditional headers to skip download when data unchanged.

```
With If-Modified-Since:
30 requests/minute:
  - 29 requests × 1KB = 29KB (304 Not Modified)
  - 1 request × 100KB = 100KB (200 OK when changed)
  = ~130KB/minute = ~7.8MB/hour 📉 90% SAVINGS!
```

---

## 🔑 Key Concepts

### HTTP 200 OK ✅
Server says: "Data has changed since your If-Modified-Since timestamp"
- Response includes full data (~100KB)
- Save new metadata (ETag, Last-Modified)
- Update UI with new data

### HTTP 304 Not Modified 🔄
Server says: "Data hasn't changed since your If-Modified-Since timestamp"
- Response has NO body (just headers ~1KB)
- Keep old metadata unchanged
- Don't update UI (show user same data)

### Metadata Caching
Store ONLY in Hive:
- `lastModified`: HTTP Last-Modified header (RFC 1123 format)
- `eTag`: HTTP ETag header (opaque string)
- `lastSyncedAt`: When we last synced (TTL tracking)

DO NOT store: Product data (name, price, image, etc.) - that's in Riverpod state!

---

## 🏗️ Architecture Overview

```
UI Layer (Flutter Widgets)
          ↓
Riverpod Notifiers (State Management)
          ↓
Repositories (Domain Logic)
          ├─ Check: "Return null on 304, data on 200"
          │
          ├─ LocalDataSource: Read/write metadata from Hive
          │
          └─ RemoteDataSource: Send conditional headers, extract headers
                   ↓
                API Client (Dio)
                   ↓
                Server
```

---

## 📊 Component Roles

### CacheHeadersHelper (`lib/core/network/cache_headers_helper.dart`)
Utilities for HTTP header manipulation:
- `buildConditionalHeaders()` - Build If-Modified-Since headers
- `extractCacheHeaders()` - Extract ETag, Last-Modified from response
- `isNotModified()` - Check if status is 304

### CacheConfig (`lib/core/storage/cache_config.dart`)
Global configuration:
- `pollingInterval` = 30 seconds
- `cacheTTL` = 1 hour
- Hive key prefixes (pd:variant_meta:, cat:list_meta, etc)
- Single hive box name ('app_cache_box')

### LocalDataSource
Hive database operations:
- Read cached metadata
- Write/update metadata
- Clear cache
- Namespaced Hive keys

### RemoteDataSource
API calls:
- Send conditional headers
- Handle 304 (return null)
- Extract headers on 200
- Error handling

### Repository
Orchestration:
- Get cached metadata from local
- Send conditional request to remote
- If 304: Return null (no UI update)
- If 200: Save metadata, return data (update UI)

### Notifier/Provider
Riverpod state:
- Manage polling timer
- Call repository every 30 seconds
- Update state if new data
- Show loading indicator

---

## 💾 Hive Database Structure

### Single Shared Box
```
Box Name: 'app_cache_box'

Keys (Namespaced):
├── pd:variant_meta:{variantId}    → Product variant metadata
├── pd:product_meta:{productId}    → Product base metadata
├── cat:list_meta                  → Category list metadata
└── cat:products_meta:{catId}      → Category products metadata

Value Format:
{
  'last_synced_at': ISO8601 datetime,
  'etag': string or null,
  'last_modified': RFC1123 datetime or null
}
```

### Why Single Box?
- ✅ One box for all features (less memory overhead)
- ✅ Namespaced keys prevent collisions
- ✅ Centralized configuration
- ✅ Easy to manage and clear

---

## ⏱️ Timing Configuration

| Setting | Value | Purpose |
|---------|-------|---------|
| **Polling Interval** | 30 seconds | How often to check for updates |
| **Cache TTL** | 1 hour | How long metadata is considered valid |
| **Refresh Indicator** | 1.5 seconds | Duration to show loading indicator |

---

## 🔄 Request/Response Cycle

### First Load (No Cache)
```
1. User opens product page
2. Send unconditional request (no If-Modified-Since)
3. Server: HTTP 200 OK + ETag + Last-Modified + data
4. Save metadata to Hive
5. Update UI with product data
```

### Polling Check (With Cache, No Change)
```
1. Timer fires every 30 seconds
2. Read metadata from Hive
3. Send conditional request (with If-Modified-Since)
4. Server: HTTP 304 Not Modified (no body)
5. Update sync timestamp (refresh TTL)
6. Return null → Don't update UI (save 99% bandwidth!)
```

### Polling Check (With Cache, Data Changed)
```
1. Timer fires every 30 seconds
2. Read metadata from Hive
3. Send conditional request (with If-Modified-Since)
4. Server: HTTP 200 OK + new data + new ETag + new Last-Modified
5. Save new metadata to Hive
6. Return new data → Update UI (user sees changes)
```

---

## 📂 Key Source Files

```
lib/
├── core/
│   ├── network/
│   │   ├── cache_headers_helper.dart        ← Header building/extraction
│   │   └── endpoints.dart
│   └── storage/
│       ├── cache_config.dart                ← Global config
│       └── hive/
│           └── boxes.dart                   ← Hive box names
│
└── features/
    ├── product_details/
    │   ├── application/
    │   │   ├── providers/
    │   │   │   └── product_detail_providers.dart  ← Polling timer
    │   │   └── config/
    │   │       └── product_detail_config.dart
    │   └── infrastructure/
    │       ├── data_sources/
    │       │   ├── local/
    │       │   │   ├── product_detail_local_data_source.dart  ← Hive ops
    │       │   │   └── product_detail_cache_dto.dart          ← Metadata DTO
    │       │   └── remote/
    │       │       └── product_detail_remote_data_source.dart  ← API calls
    │       └── repositories/
    │           └── product_detail_repository_impl.dart         ← Orchestration
    │
    └── category/
        ├── application/
        │   └── providers/
        │       ├── category_providers.dart        ← Category polling
        │       └── category_product_providers.dart ← Products polling
        └── infrastructure/
            └── data_sources/
                └── local/
                    ├── category_local_data_source.dart
                    └── category_product_local_data_source.dart
```

---

## 🧪 Testing Checklist

Before considering implementation complete:

- [ ] **First Load:** Unconditional request → 200 OK → Metadata saved
- [ ] **Polling 304:** Conditional request → 304 → Timestamp updated → UI unchanged
- [ ] **Polling 200:** Conditional request → 200 → Metadata updated → UI refreshes
- [ ] **Force Refresh:** `forceRefresh=true` → Ignores cache → Always fresh data
- [ ] **Navigation Back:** Previous page data cleared → Fresh data on return
- [ ] **Network Error:** Exception caught → State becomes error → UI shows error
- [ ] **Hive Keys:** All keys use correct prefix (pd:variant_meta:, etc)
- [ ] **Logging:** Debug logs show request/response details
- [ ] **Bandwidth:** Monitor - 304 responses ~1KB, 200 responses ~100KB
- [ ] **Timer Management:** Timer starts on page open, stops on page close

---

## 🐛 Debugging Tips

### View Network Logs
```
Android Studio Logcat: Filter by "ProductRemoteDataSource" or "ProductRepo"
```

### Key Log Messages
- `UNCONDITIONAL REQUEST` = First load (no cache)
- `CONDITIONAL REQUEST` = Polling with cached metadata
- `HTTP 304` = No change, bandwidth saved!
- `HTTP 200` = Data changed, UI will update
- `NetworkException` = Network error occurred

### Monitor Hive Database
```dart
// In debug console
Box<dynamic> cacheBox = Hive.box<dynamic>('app_cache_box');
print(cacheBox.toMap());  // Print all cached metadata
```

---

## ⚠️ Common Mistakes

❌ **Storing full product data in Hive**
- ✅ Store ONLY metadata (ETag, Last-Modified, timestamp)

❌ **Updating UI when remoteResponse is null (304)**
- ✅ Return null and skip state update

❌ **Not extracting headers from 200 response**
- ✅ Always save new ETag and Last-Modified

❌ **Sending conditional headers on forceRefresh=true**
- ✅ Pass null for headers when forceRefresh=true

❌ **Using different Hive boxes per feature**
- ✅ Use single 'app_cache_box' with namespaced keys

---

## 📈 Performance Impact

### Bandwidth Reduction
- **Without optimization:** ~180MB/hour per polling feature
- **With If-Modified-Since:** ~7.8MB/hour per feature
- **Savings:** **95%+** when data rarely changes

### User Experience
- **Responsiveness:** Check for updates every 30 seconds
- **Real-time:** See price/inventory changes within 30 seconds
- **No Flicker:** 304 responses don't refresh UI unnecessarily

### Battery/Data Impact
- **Mobile:** Minimal network activity saves battery
- **Data Plans:** Huge savings for users on metered connections

---

## 🔗 External References

### HTTP Standards
- [RFC 7232 - HTTP Conditional Requests](https://tools.ietf.org/html/rfc7232)
- [HTTP 200 OK](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/200)
- [HTTP 304 Not Modified](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/304)
- [If-Modified-Since Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since)
- [ETag Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag)

### Flutter Packages Used
- **Riverpod:** State management (async values, notifiers)
- **Dio:** HTTP client (custom headers support)
- **Hive:** Local database (fast key-value storage)
- **Flutter Async:** Timer for periodic polling

---

## ❓ Frequently Asked Questions

**Q: Where is product data stored?**
A: In Riverpod state (in-memory). Only metadata is in Hive.

**Q: Why not cache product data in Hive?**
A: Simplicity. Product data changes frequently. On navigate back, fresh fetch with `forceRefresh=true` ensures correctness.

**Q: What if network is down during polling?**
A: NetworkException is caught, state becomes error, UI shows error message.

**Q: Can I change polling interval?**
A: Yes, modify `CacheConfig.pollingInterval` (default 30 seconds).

**Q: Why single Hive box for all features?**
A: Reduces memory overhead. Namespaced keys prevent collisions.

**Q: What if server doesn't support If-Modified-Since?**
A: Don't use conditional request logic. Always fetch fresh (example: Product Base API).

**Q: How long is metadata cached?**
A: `CacheConfig.cacheTTL = 1 hour`. After 1 hour, consider refreshing.

**Q: What's the difference between ETag and Last-Modified?**
A: ETag is opaque (server decides). Last-Modified is standardized (RFC 1123). Server respects whichever is sent.

---

## 📞 Support & Questions

### Need Help?
1. Check [Quick Reference](IF_MODIFIED_SINCE_QUICK_REFERENCE.md) for quick answers
2. Review [Architecture](IF_MODIFIED_SINCE_ARCHITECTURE.md) for detailed explanation
3. Look at [Code Examples](IF_MODIFIED_SINCE_CODE_EXAMPLES.md) for implementation patterns
4. Check [Diagrams](IF_MODIFIED_SINCE_FLOW_DIAGRAMS.md) for visual understanding

### Found a Bug?
1. Check debug logs for error messages
2. Verify Hive key prefixes are correct
3. Ensure metadata JSON structure matches DTO
4. Test with force refresh to isolate issue

---

## 📋 Document Information

| Property | Value |
|----------|-------|
| **Created** | 2025-11-27 |
| **Project** | Grocery App (Flutter + Riverpod) |
| **Architecture** | Clean Architecture |
| **Status** | Production Implementation |
| **Files Documented** | 8+ core files |
| **Code Examples** | 50+ complete examples |

---

## 🎯 Next Steps

1. **Read Quick Reference** for overview (5 min)
2. **View Flow Diagrams** for visualization (10 min)
3. **Study Architecture** for deep understanding (20 min)
4. **Review Code Examples** for implementation patterns (15 min)
5. **Test all scenarios** using testing checklist
6. **Deploy with confidence!** 🚀

---

**Happy coding!** 🎉

For detailed information, navigate to one of the documentation files above.
