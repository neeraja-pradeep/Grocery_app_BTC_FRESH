Hive Cache Implementation - Production Specification
Core Architecture
Cache Key Strategy
cacheKey = SHA256(
  endpoint + 
  HTTP_method + 
  sorted_query_params + 
  request_body_hash +
  auth_token_hash
)
Cache Layers

Memory Cache (L1): LRU, 50MB max, 500 entries max
Hive Cache (L2): LRU, 200MB max, auto-eviction on 90% full
Network (L3): API with conditional requests


Scenarios with Error Handling
Scenario 1: Cold Start (No Cache, Network Available)
1. Check Memory → Miss
2. Check Hive → Miss
3. Show skeleton loader
4. API Call → Success (200 OK)
5. Parse & validate response
6. Update UI (100-500ms total)
7. Write to Memory cache (sync)
8. Write to Hive (async, non-blocking)
9. Store Last-Modified header from response

Error Paths:
- API timeout (10s): Show error, allow retry
- Parse failure: Log, show error, don't cache
- Hive write fails: Log silently, continue (cache miss next time)
Scenario 2: Warm Start (Valid Cache < 12h, Network Available)
1. Check Memory → Miss (app restart cleared it)
2. Check Hive → Hit (8h old)
3. Load Hive to Memory cache
4. Show cached data immediately (~50ms)
5. Show subtle "updating..." indicator (top banner, non-intrusive)
6. API Call with If-Modified-Since header → Background
   
   Case A: 304 Not Modified
   - Hide "updating..." indicator
   - Keep showing cached data
   - Update cache timestamp to "now"
   
   Case B: 200 OK (data changed)
   - Parse response
   - Animate transition to new data
   - Update Memory + Hive
   - Replace Last-Modified timestamp
   - Hide indicator

Error Paths:
- API fails: Keep showing cached data, hide indicator, log error
- Hive read corrupt: Delete corrupt entry, fallback to API only
- Memory cache full: Evict LRU entry, add new

Scenario 3: Warm Start (Valid Cache, No Network)
1. Check Memory → Miss
2. Check Hive → Hit (8h old)
3. Show cached data immediately
4. Show persistent offline indicator (subtle icon in app bar)
5. API call fails silently (ConnectionException)
6. Don't retry while offline
7. Listen to ConnectivityPlus stream
8. When online: Auto-retry API call (once)

Error Paths:
- Hive corrupted + offline: Show error screen with retry button
- Cache exists but unreadable: Show last known good data from memory if available
Scenario 4: Navigation Between Screens
1. Check Memory → Hit
2. Return from Memory (~1-5ms)
3. UI renders immediately
4. No API call needed (cache still valid)

Fallback:
- Memory evicted: Check Hive (Scenario 2 flow)
- Both miss: Scenario 1 flow
Scenario 5: Stale Cache (> 24h old)
1. Check Hive → Hit (26h old)
2. Show cached data with amber warning banner:
   "Data from 1 day ago • Tap to refresh"
3. API Call → Background with retry logic

Retry Strategy (Exponential Backoff):
- Attempt 1: Immediate
- Attempt 2: +2s delay
- Attempt 3: +4s delay  
- Attempt 4: +8s delay
- Max attempts: 4
- Max total wait: 15s
- On all failures: Keep stale data, show "Unable to update" message

Success:
- 200 OK: Update UI + cache, remove warning
- 304: Update timestamp, remove warning
- 4xx: Remove warning, log error, don't retry
- 5xx: Follow retry strategy

User Actions:
- Tap warning banner: Force immediate retry (reset counter)
- Pull-to-refresh: Force immediate retry
Scenario 6: Conditional Requests (HTTP 304 Optimization)
On Every API Call:
1. Check if Last-Modified exists in cache metadata
2. If yes: Add header "If-Modified-Since: <timestamp>"
3. Make request

Backend Response:
- 304 Not Modified:
  * No response body (saves bandwidth)
  * Return cached data from Hive
  * Update cache access timestamp (for LRU)
  * DON'T update Last-Modified value
  
- 200 OK:
  * Response contains updated data
  * Parse response body
  * Extract Last-Modified from response headers
  * REPLACE old Last-Modified with new value
  * Update cache with new data + new Last-Modified
  
- 412 Precondition Failed:
  * Cache out of sync with server
  * Delete cache entry
  * Retry without If-Modified-Since

Implementation:
{
  "endpoint": "/api/products",
  "data": {...},
  "lastModified": "Thu, 21 Nov 2024 10:30:00 GMT",
  "cachedAt": 1732186200000,
  "expiresAt": 1732272600000
}
Scenario 7: Concurrent Requests (Race Condition Prevention)
Problem: Same endpoint called twice simultaneously

Solution: Request Deduplication Pool

1. Before API call, check RequestPool:
   requestId = cacheKey
   
2. If request in-flight:
   - Attach listener to existing request
   - Return same Future to both callers
   - Don't make duplicate network call
   
3. If no active request:
   - Register in RequestPool
   - Make API call
   - Notify all listeners on completion
   - Remove from RequestPool

Implementation:
class RequestPool {
  Map<String, Completer> _activeRequests = {};
  
  Future<T> dedupe<T>(String key, Future<T> request) {
    if (_activeRequests.containsKey(key)) {
      return _activeRequests[key]!.future;
    }
    
    final completer = Completer<T>();
    _activeRequests[key] = completer;
    
    request.then((result) {
      completer.complete(result);
      _activeRequests.remove(key);
    }).catchError((error) {
      completer.completeError(error);
      _activeRequests.remove(key);
    });
    
    return completer.future;
  }
}
Scenario 8: Cache Eviction & Size Management
Hive Monitor (runs every 5 minutes):
1. Check total Hive size
2. If > 180MB (90% of 200MB limit):
   - Get all entries with access timestamps
   - Sort by LRU (oldest access first)
   - Delete oldest 20% of entries
   - Compact Hive boxes

Memory Cache (on every write):
1. If entries > 500 OR size > 50MB:
   - Evict LRU entry
   - Repeat until under limits

Per-Entry Metadata:
{
  "accessCount": 142,
  "lastAccessed": 1732186200000,
  "createdAt": 1732100000000,
  "size": 15360 // bytes
}
Scenario 9: Cache Corruption Recovery
On Hive Read Error:
1. Catch HiveError/FormatException
2. Log error with cache key
3. Delete corrupted box/entry
4. Mark cache key as "corrupted" in memory (5min TTL)
5. Fallback to API call
6. Don't cache result if same key corrupted 3+ times in 1 hour

On Hive Write Error:
1. Catch and log
2. Don't block UI
3. Continue with in-memory cache only
4. Try again on next write (different data)
5. If 10 consecutive write failures: Disable Hive, show warning
Scenario 10: Partial/Invalid Response Handling
Response Validation Pipeline:
1. Check HTTP status (200-299 valid)
2. Check Content-Type header matches expected
3. Parse JSON (catch FormatException)
4. Validate against model schema
5. Check required fields exist
6. Validate data types

If ANY validation fails:
- Don't update cache
- Return previous cached data if available
- Show error: "Unable to load data"
- Log full response for debugging
- Allow manual retry

Partial Success (paginated):
- Cache each page independently
- Use separate cache keys per page
- Show pages as they load

Implementation Classes
CacheConfig
dartclass CacheConfig {
  static const memoryCacheMaxSize = 50 * 1024 * 1024; // 50MB
  static const memoryCacheMaxEntries = 500;
  static const hiveCacheMaxSize = 200 * 1024 * 1024; // 200MB
  static const staleCacheThreshold = Duration(hours: 24);
  static const validCacheThreshold = Duration(hours: 12);
  static const apiTimeout = Duration(seconds: 10);
  static const maxRetryAttempts = 4;
  static const retryBaseDelay = Duration(seconds: 2);
}
CacheEntry Model
dart@HiveType(typeId: 1)
class CacheEntry {
  @HiveField(0)
  final String key;
  
  @HiveField(1)
  final dynamic data;
  
  @HiveField(2)
  final String? lastModified;
  
  @HiveField(3)
  final int cachedAt;
  
  @HiveField(4)
  final int lastAccessed;
  
  @HiveField(5)
  final int accessCount;
  
  @HiveField(6)
  final int size;
  
  bool get isStale => 
    DateTime.now().millisecondsSinceEpoch - cachedAt > 
    CacheConfig.staleCacheThreshold.inMilliseconds;
    
  bool get isValid =>
    DateTime.now().millisecondsSinceEpoch - cachedAt < 
    CacheConfig.validCacheThreshold.inMilliseconds;
}
Retry Logic
dartclass RetryPolicy {
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation,
    {int maxAttempts = 4}
  ) async {
    int attempt = 0;
    
    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        if (attempt >= maxAttempts) rethrow;
        
        if (e is HttpException && 
            e.statusCode >= 400 && 
            e.statusCode < 500) {
          rethrow; // Don't retry 4xx
        }
        
        final delay = Duration(
          seconds: pow(2, attempt - 1).toInt() * 2
        );
        
        await Future.delayed(delay);
      }
    }
    
    throw Exception('Max retries exceeded');
  }
}

Thread Safety & Isolate Handling
dart// Use HiveProvider to ensure single Hive instance
class HiveProvider {
  static Box? _box;
  static final _lock = Lock();
  
  static Future<Box> getBox() async {
    return await _lock.synchronized(() async {
      _box ??= await Hive.openBox('cache');
      return _box!;
    });
  }
}

// All Hive operations go through this
await HiveProvider.getBox().then((box) => box.put(key, value));