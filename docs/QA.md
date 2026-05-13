We do the complete code QA and audit via claude code. So here are the prompts which we used for the code auditing. This may be of multiple parts. Analyse this to generate the codes that passes the below tests:

Prompt 1
--------
You are a Flutter architect specializing in Riverpod. Audit this codebase for state management violations.

### CRITICAL VIOLATIONS
1. Direct .state mutations outside owning StateNotifier
2. ref.watch() in callbacks/event handlers/async functions
3. Missing autoDispose on temporary UI state (page index, selected dates, form fields)
4. FutureProvider used for mutations (add/update/delete)
5. BuildContext passed to StateNotifier/Provider
6. Business logic in Widget build methods
7. ref.invalidate() called inside provider's own body
8. Repositories instantiated directly instead of via provider
9. Circular provider dependencies
10. Provider families missing autoDispose for dynamic data
11. Navigation/SnackBar/Dialog logic in providers/notifiers
12. UI-specific code in business logic layer

### HIGH PRIORITY
13. ConsumerWidget used when StatelessWidget sufficient
14. Inconsistent provider naming (not following {feature}RepositoryProvider pattern)
15. Global providers incorrectly marked autoDispose
16. Repositories containing business logic
17. UI widgets directly accessing data sources
18. Models containing business logic methods

## OUTPUT FORMAT

For each issues found, provide:

1. **File Path**
2. **Severity**: CRITICAL | HIGH | MEDIUM | LOW
3. **Issue Description**: What's wrong and why it matters
4. **Code Snippet**: Show the problematic code
5. **Fix**: Explain how to fix it with example code
6. **Impact**: What breaks if this isn't fixed

Priority order:
1. All files in /lib/providers/
2. All files in /lib/repositories/
3. All files touching Hive (search for "Hive.box")
4. All ConsumerWidget and ConsumerStatefulWidget files
5. Files with StateNotifier implementations

## Deliverables

1. **Executive Summary**: 
   - Total files reviewed
   - Critical issues count
   - High priority issues count
   - Top 3 systemic problems

2. **Detailed Issue Log**: 
   - All issues with severity, location, fix

3. **Refactoring Recommendations**:
   - Architectural improvements needed
   - Priority order for fixes

4. **Technical Debt Score**: 
   - Rate codebase 1-10 (10 = excellent)
   - Justify the score

Start with the providers/ and repositories/ directories first.

Start audit now.

Prompt 2
---------
You are a Flutter security architect. Audit this codebase for data persistence and security vulnerabilities.

### CRITICAL VIOLATIONS
1. Hive.openBox() called inside repository methods
2. Hive boxes not closed in autoDispose providers
3. Hive imported in UI layer (screens/widgets)
4. Hive operations in build() methods
5. android:allowBackup setting in AndroidManifest.xml
6. Auth tokens in plain SharedPreferences
7. Logout missing: token clearing
8. Logout missing: Hive box deletion
9. Logout missing: FirebaseAuth.instance.signOut()
10. Auto-login without token validation
11. Auto-login without null checks on Hive data
12. Login not clearing previous user's data
13. Sensitive data (tokens/passwords/OTPs) in print statements
14. Missing backup_rules.xml when allowBackup=true
15. Hardcoded API keys/secrets/credentials
16. Exposed Firebase configuration in version control

### HIGH PRIORITY
17. TypeAdapters not registered before box access
18. Synchronous Hive operations on large datasets
19. Hive boxes not deleted on logout
20. Logout not using pushNamedAndRemoveUntil
21. Logout not invalidating providers
22. Firebase initialization order issues
23. Firebase authentication error handling missing
24. Firebase listeners not disposed

## SPECIAL FOCUS
- Trace complete logout flow (show all steps)
- Trace auto-login flow (show validation checks)
- Check AndroidManifest.xml backup configuration
- List all token storage locations

## OUTPUT FORMAT

For each violation:
**File:** path/to/file.dart:line_number
**Severity:** CRITICAL | HIGH
**Security Risk:** [Impact description]
**Code:**
```dart
[Show problematic code]
```

## ANDROID MANIFEST CHECK
**Current allowBackup setting:**
**Backup rules file exists:**
**Assessment:**

## TOKEN STORAGE INVENTORY
List all locations where auth tokens are stored/retrieved/cleared.

Start audit now.

Prompt 3
----------
You are a Flutter performance architect. Audit this codebase for error handling and performance issues.

### CRITICAL VIOLATIONS
1. Async providers without try-catch or AsyncValue.guard()
2. Heavy operations in build() methods (JSON parsing, file I/O, calculations)

### HIGH PRIORITY
3. Async operations returning null without error indication
4. Network errors without retry logic for critical operations
5. Widget rebuilds excessively (check with DevTools)
6. Large lists not using builder pattern
7. Unnecessary widget rebuilds
8. Dependencies without version constraints (using 'any')

### MEDIUM PRIORITY
9. Generic catch blocks without logging
10. APK size >50MB
11. Unoptimized images/assets (large files, wrong formats)
12. Multiple ABIs bundled in single APK
13. Debug symbols not stripped in release builds
14. Unused dependencies in pubspec.yaml
15. Duplicate functionality across packages
16. Heavy packages without lighter alternatives

## PERFORMANCE ANALYSIS
Run these checks:
1. Identify all heavy operations in build() methods
2. List all large lists not using .builder pattern
3. Check pubspec.yaml for optimization opportunities
4. Identify providers that rebuild frequently

## OUTPUT FORMAT

For each issue:
**File:** path/to/file.dart:line_number
**Severity:** CRITICAL | HIGH | MEDIUM
**Performance Impact:** [Description]
**Code:**
```dart
[Show problematic code]
```

## DEPENDENCY REPORT
- Total dependencies: X
- Unused dependencies: [list]
- Version constraint issues: [list]
- Heavy packages (>5MB): [list]

Start audit now.

Prompt 4
---------
You are a Flutter code quality auditor. Audit this codebase for code quality and deployment readiness.

### CRITICAL VIOLATIONS
1. App crashes after uninstall/reinstall
2. Auto-login persists to wrong user after reinstall
3. User B sees User A's data when switching accounts
4. Debug/test credentials in production build
5. flutter analyze has errors/warnings
6. flutter test has failing tests
7. Critical user flows untested on physical device
8. Version number not incremented for release

### HIGH PRIORITY
9. Memory leaks (navigate 20+ times, check DevTools)
10. App fails with internet OFF
11. App doesn't handle low memory situations
12. Migration logic missing for breaking changes
13. Old data formats not handled in new versions
14. Corrupted backup data not handled
15. Git commit contains unrelated files
16. CHANGELOG.md not updated
17. App not tested on multiple Android versions
18. Firebase listeners not disposed

### MEDIUM PRIORITY
19. Excessive print statements
20. Magic numbers and hardcoded delays
21. Missing documentation on complex providers
22. Unused imports and providers
23. Duplicate logic across files
24. TODO/FIXME in production code
25. App crashes after background for extended period
26. App store metadata outdated
27. dart format not applied

## TESTING VALIDATION
Check if these manual tests are documented:
- Uninstall/reinstall flow
- User switching flow
- Internet OFF scenarios
- Low memory scenarios
- Background/foreground transitions

## OUTPUT FORMAT

For each issue:
**Category:** Testing | Code Quality | Deployment
**Severity:** CRITICAL | HIGH | MEDIUM
**Issue:** [Description]
**Location:** [If applicable]

## DEPLOYMENT READINESS SCORE
Rate 1-10 based on:
- Critical issues blocking deployment
- Testing coverage
- Code quality
- Documentation

## RECOMMENDED ACTIONS
List top 5 actions before deployment.

Start audit now.

Prompt 5
----------
Comming soon
We do the complete code QA and audit via claude code. So here are the prompts which we used for the code auditing. This may be of multiple parts. Analyse this to generate the codes that passes the below tests:

Prompt 1
--------
You are a Flutter architect specializing in Riverpod. Audit this codebase for state management violations.

### CRITICAL VIOLATIONS
1. Direct .state mutations outside owning StateNotifier
2. ref.watch() in callbacks/event handlers/async functions
3. Missing autoDispose on temporary UI state (page index, selected dates, form fields)
4. FutureProvider used for mutations (add/update/delete)
5. BuildContext passed to StateNotifier/Provider
6. Business logic in Widget build methods
7. ref.invalidate() called inside provider's own body
8. Repositories instantiated directly instead of via provider
9. Circular provider dependencies
10. Provider families missing autoDispose for dynamic data
11. Navigation/SnackBar/Dialog logic in providers/notifiers
12. UI-specific code in business logic layer

### HIGH PRIORITY
13. ConsumerWidget used when StatelessWidget sufficient
14. Inconsistent provider naming (not following {feature}RepositoryProvider pattern)
15. Global providers incorrectly marked autoDispose
16. Repositories containing business logic
17. UI widgets directly accessing data sources
18. Models containing business logic methods

## OUTPUT FORMAT

For each issues found, provide:

1. **File Path**
2. **Severity**: CRITICAL | HIGH | MEDIUM | LOW
3. **Issue Description**: What's wrong and why it matters
4. **Code Snippet**: Show the problematic code
5. **Fix**: Explain how to fix it with example code
6. **Impact**: What breaks if this isn't fixed

Priority order:
1. All files in /lib/providers/
2. All files in /lib/repositories/
3. All files touching Hive (search for "Hive.box")
4. All ConsumerWidget and ConsumerStatefulWidget files
5. Files with StateNotifier implementations

## Deliverables

1. **Executive Summary**: 
   - Total files reviewed
   - Critical issues count
   - High priority issues count
   - Top 3 systemic problems

2. **Detailed Issue Log**: 
   - All issues with severity, location, fix

3. **Refactoring Recommendations**:
   - Architectural improvements needed
   - Priority order for fixes

4. **Technical Debt Score**: 
   - Rate codebase 1-10 (10 = excellent)
   - Justify the score

Start with the providers/ and repositories/ directories first.

Start audit now.

Prompt 2
---------
You are a Flutter security architect. Audit this codebase for data persistence and security vulnerabilities.

### CRITICAL VIOLATIONS
1. Hive.openBox() called inside repository methods
2. Hive boxes not closed in autoDispose providers
3. Hive imported in UI layer (screens/widgets)
4. Hive operations in build() methods
5. android:allowBackup setting in AndroidManifest.xml
6. Auth tokens in plain SharedPreferences
7. Logout missing: token clearing
8. Logout missing: Hive box deletion
9. Logout missing: FirebaseAuth.instance.signOut()
10. Auto-login without token validation
11. Auto-login without null checks on Hive data
12. Login not clearing previous user's data
13. Sensitive data (tokens/passwords/OTPs) in print statements
14. Missing backup_rules.xml when allowBackup=true
15. Hardcoded API keys/secrets/credentials
16. Exposed Firebase configuration in version control

### HIGH PRIORITY
17. TypeAdapters not registered before box access
18. Synchronous Hive operations on large datasets
19. Hive boxes not deleted on logout
20. Logout not using pushNamedAndRemoveUntil
21. Logout not invalidating providers
22. Firebase initialization order issues
23. Firebase authentication error handling missing
24. Firebase listeners not disposed

## SPECIAL FOCUS
- Trace complete logout flow (show all steps)
- Trace auto-login flow (show validation checks)
- Check AndroidManifest.xml backup configuration
- List all token storage locations

## OUTPUT FORMAT

For each violation:
**File:** path/to/file.dart:line_number
**Severity:** CRITICAL | HIGH
**Security Risk:** [Impact description]
**Code:**
```dart
[Show problematic code]
```

## ANDROID MANIFEST CHECK
**Current allowBackup setting:**
**Backup rules file exists:**
**Assessment:**

## TOKEN STORAGE INVENTORY
List all locations where auth tokens are stored/retrieved/cleared.

Start audit now.

Prompt 3
----------
You are a Flutter performance architect. Audit this codebase for error handling and performance issues.

### CRITICAL VIOLATIONS
1. Async providers without try-catch or AsyncValue.guard()
2. Heavy operations in build() methods (JSON parsing, file I/O, calculations)

### HIGH PRIORITY
3. Async operations returning null without error indication
4. Network errors without retry logic for critical operations
5. Widget rebuilds excessively (check with DevTools)
6. Large lists not using builder pattern
7. Unnecessary widget rebuilds
8. Dependencies without version constraints (using 'any')

### MEDIUM PRIORITY
9. Generic catch blocks without logging
10. APK size >50MB
11. Unoptimized images/assets (large files, wrong formats)
12. Multiple ABIs bundled in single APK
13. Debug symbols not stripped in release builds
14. Unused dependencies in pubspec.yaml
15. Duplicate functionality across packages
16. Heavy packages without lighter alternatives

## PERFORMANCE ANALYSIS
Run these checks:
1. Identify all heavy operations in build() methods
2. List all large lists not using .builder pattern
3. Check pubspec.yaml for optimization opportunities
4. Identify providers that rebuild frequently

## OUTPUT FORMAT

For each issue:
**File:** path/to/file.dart:line_number
**Severity:** CRITICAL | HIGH | MEDIUM
**Performance Impact:** [Description]
**Code:**
```dart
[Show problematic code]
```

## DEPENDENCY REPORT
- Total dependencies: X
- Unused dependencies: [list]
- Version constraint issues: [list]
- Heavy packages (>5MB): [list]

Start audit now.

Prompt 4
---------
You are a Flutter code quality auditor. Audit this codebase for code quality and deployment readiness.

### CRITICAL VIOLATIONS
1. App crashes after uninstall/reinstall
2. Auto-login persists to wrong user after reinstall
3. User B sees User A's data when switching accounts
4. Debug/test credentials in production build
5. flutter analyze has errors/warnings
6. flutter test has failing tests
7. Critical user flows untested on physical device
8. Version number not incremented for release

### HIGH PRIORITY
9. Memory leaks (navigate 20+ times, check DevTools)
10. App fails with internet OFF
11. App doesn't handle low memory situations
12. Migration logic missing for breaking changes
13. Old data formats not handled in new versions
14. Corrupted backup data not handled
15. Git commit contains unrelated files
16. CHANGELOG.md not updated
17. App not tested on multiple Android versions
18. Firebase listeners not disposed

### MEDIUM PRIORITY
19. Excessive print statements
20. Magic numbers and hardcoded delays
21. Missing documentation on complex providers
22. Unused imports and providers
23. Duplicate logic across files
24. TODO/FIXME in production code
25. App crashes after background for extended period
26. App store metadata outdated
27. dart format not applied

## TESTING VALIDATION
Check if these manual tests are documented:
- Uninstall/reinstall flow
- User switching flow
- Internet OFF scenarios
- Low memory scenarios
- Background/foreground transitions

## OUTPUT FORMAT

For each issue:
**Category:** Testing | Code Quality | Deployment
**Severity:** CRITICAL | HIGH | MEDIUM
**Issue:** [Description]
**Location:** [If applicable]

## DEPLOYMENT READINESS SCORE
Rate 1-10 based on:
- Critical issues blocking deployment
- Testing coverage
- Code quality
- Documentation

## RECOMMENDED ACTIONS
List top 5 actions before deployment.

Start audit now.

Prompt 5
----------
You are a Flutter caching architect. Audit this codebase for Hive cache implementation correctness, covering all cache scenarios, eviction, concurrency, and HTTP optimization.

### CRITICAL VIOLATIONS
1. No 3-layer cache (L1 Memory → L2 Hive → L3 Network) — data fetched directly from API on every call
2. Cache key does not incorporate HTTP method, sorted query params, request body hash, and auth token hash (SHA256)
3. No request deduplication pool — same endpoint called twice simultaneously makes two network calls
4. Hive write errors block the UI thread instead of failing silently and continuing
5. No response validation pipeline before caching — invalid/partial responses written to cache
6. Cache corruption not recovered — HiveError/FormatException crashes the app instead of falling back to API

### HIGH PRIORITY
7. Cold start shows no skeleton loader while API call is in-flight
8. Warm start (cache < 12h old) does not show cached data immediately — waits for API response
9. No background refresh with non-intrusive "updating..." indicator on warm start
10. Stale cache (> 24h old) shown without amber warning banner or "Tap to refresh" affordance
11. Offline mode: no persistent offline indicator shown in app bar when network is unavailable
12. Offline mode: app retries API continuously instead of listening to ConnectivityPlus stream and retrying once on reconnect
13. If-Modified-Since header not sent on API calls when Last-Modified metadata exists in cache
14. HTTP 304 Not Modified response not handled — full re-parse attempted instead of returning cached data
15. HTTP 412 Precondition Failed not handled — cache not deleted and request not retried without If-Modified-Since
16. Exponential backoff retry strategy missing or incorrect (must be: 4 attempts, delays +2s/+4s/+8s, max total 15s, 4xx errors must NOT be retried)
17. HiveProvider is not a singleton with a lock — multiple Hive box instances can be opened concurrently across isolates

### MEDIUM PRIORITY
18. Hive size monitor not running every 5 minutes to check against 200MB limit
19. Eviction does not delete oldest 20% of LRU entries when Hive exceeds 90% capacity (180MB)
20. Memory cache does not evict LRU entry on every write when entries > 500 or size > 50MB
21. CacheEntry model missing per-entry metadata: accessCount, lastAccessed, size (bytes)
22. Cache corruption recovery missing: same cache key corrupted 3+ times in 1 hour must be blacklisted (not cached) for 5 minutes
23. 10 consecutive Hive write failures do not trigger Hive disable with a user-visible warning
24. Paginated responses not cached with per-page independent cache keys
25. Last-Modified value incorrectly replaced on 304 response (must NOT be updated on 304, only on 200)
26. CacheConfig constants not centralised — timeout (10s), valid threshold (12h), stale threshold (24h), max retries (4), retry base delay (2s), memory limits (50MB/500 entries), Hive limit (200MB) are hardcoded across files

## SCENARIO VALIDATION CHECKLIST

Run through each scenario manually or via integration test:

**Scenario 1 — Cold Start (no cache, network available)**
- [ ] Memory miss → Hive miss → skeleton loader shown
- [ ] API call made with 10s timeout
- [ ] On success: UI updates, Memory written sync, Hive written async (non-blocking)
- [ ] On timeout: error shown, retry available
- [ ] On parse failure: error logged, not cached, error shown
- [ ] On Hive write failure: logged silently, app continues

**Scenario 2 — Warm Start (cache < 12h, network available)**
- [ ] Hive hit → data loaded to Memory → cached UI shown within ~50ms
- [ ] Background API call made with If-Modified-Since header
- [ ] 304: "updating..." hidden, cache timestamp updated, Last-Modified NOT changed
- [ ] 200: data animated in, Memory + Hive updated, Last-Modified replaced
- [ ] API failure: cached data kept, indicator hidden, error logged

**Scenario 3 — Warm Start (no network)**
- [ ] Hive hit → data shown immediately
- [ ] Persistent offline indicator shown in app bar
- [ ] No continuous retry — listens to ConnectivityPlus stream
- [ ] Auto-retries once when connectivity restored
- [ ] Hive corrupted + offline: error screen with retry button shown

**Scenario 4 — Navigation Between Screens**
- [ ] Memory hit returns in 1–5ms with no API call
- [ ] Memory evicted: falls through to Hive (Scenario 2 flow)
- [ ] Both miss: falls through to API (Scenario 1 flow)

**Scenario 5 — Stale Cache (> 24h)**
- [ ] Stale data shown with amber banner: "Data from X ago • Tap to refresh"
- [ ] Background API call with exponential backoff (4 attempts max)
- [ ] 4xx errors: retry stopped, warning removed, error logged
- [ ] 5xx errors: retry strategy applied
- [ ] All retries exhausted: "Unable to update" message, stale data kept
- [ ] Tap banner / pull-to-refresh: retry counter reset, immediate retry

**Scenario 6 — Conditional Requests (HTTP 304)**
- [ ] If-Modified-Since header added when metadata exists
- [ ] 304: cached data returned, access timestamp updated, Last-Modified unchanged
- [ ] 200: new data parsed, Last-Modified replaced with response header value
- [ ] 412: cache entry deleted, request retried without If-Modified-Since

**Scenario 7 — Concurrent Requests (Race Condition)**
- [ ] Two simultaneous calls to same endpoint make only ONE network request
- [ ] Both callers receive the same Future result
- [ ] RequestPool entry removed on completion or error

**Scenario 8 — Cache Eviction**
- [ ] Hive monitor runs every 5 minutes
- [ ] At >180MB: oldest 20% of entries deleted by LRU, Hive compacted
- [ ] Memory cache: LRU entry evicted on each write when >500 entries or >50MB

**Scenario 9 — Cache Corruption Recovery**
- [ ] HiveError/FormatException caught on read
- [ ] Corrupted entry deleted, key marked as corrupted for 5 minutes
- [ ] Falls back to API call
- [ ] Same key corrupted 3+ times in 1 hour: result not cached
- [ ] Hive write error: caught, logged, does not block UI
- [ ] 10 consecutive write failures: Hive disabled, warning shown to user

**Scenario 10 — Partial/Invalid Response**
- [ ] Validation pipeline runs: HTTP status → Content-Type → JSON parse → schema → required fields → data types
- [ ] Any failure: cache not updated, previous cached data returned if available
- [ ] Error message shown, full response logged for debugging
- [ ] Manual retry allowed

## IMPLEMENTATION CLASS CHECKS

Verify these classes exist and are correctly implemented:

**CacheConfig**
- [ ] `memoryCacheMaxSize = 50MB`
- [ ] `memoryCacheMaxEntries = 500`
- [ ] `hiveCacheMaxSize = 200MB`
- [ ] `staleCacheThreshold = 24h`
- [ ] `validCacheThreshold = 12h`
- [ ] `apiTimeout = 10s`
- [ ] `maxRetryAttempts = 4`
- [ ] `retryBaseDelay = 2s`

**CacheEntry (@HiveType)**
- [ ] `key`, `data`, `lastModified`, `cachedAt`, `lastAccessed`, `accessCount`, `size` fields present
- [ ] All fields annotated with `@HiveField`
- [ ] `isStale` getter: `now - cachedAt > 24h`
- [ ] `isValid` getter: `now - cachedAt < 12h`

**RetryPolicy**
- [ ] Exponential delay: `pow(2, attempt-1) * 2` seconds
- [ ] 4xx errors re-thrown immediately (no retry)
- [ ] Max 4 attempts before throwing

**HiveProvider**
- [ ] Singleton `_box` with `Lock` from `synchronized` package
- [ ] All Hive operations go through `HiveProvider.getBox()`
- [ ] No direct `Hive.openBox()` calls outside HiveProvider

**RequestPool**
- [ ] `Map<String, Completer>` tracks in-flight requests by cache key
- [ ] Returns existing Future if request in-flight
- [ ] Removes entry from pool on success and error

## OUTPUT FORMAT

For each violation found:
**File:** path/to/file.dart:line_number
**Severity:** CRITICAL | HIGH | MEDIUM
**Scenario Affected:** [Scenario number(s) from above]
**Issue:** [What is wrong and why it matters]
**Code:**
```dart
[Problematic code]
```
**Fix:**
```dart
[Corrected code]
```

## CACHE HEALTH REPORT

Provide a summary table:

| Scenario | Status | Files Checked | Issues Found |
|----------|--------|---------------|--------------|
| 1. Cold Start | PASS / FAIL | ... | ... |
| 2. Warm Start (network) | PASS / FAIL | ... | ... |
| 3. Warm Start (offline) | PASS / FAIL | ... | ... |
| 4. Navigation | PASS / FAIL | ... | ... |
| 5. Stale Cache | PASS / FAIL | ... | ... |
| 6. HTTP 304 | PASS / FAIL | ... | ... |
| 7. Concurrent Requests | PASS / FAIL | ... | ... |
| 8. Cache Eviction | PASS / FAIL | ... | ... |
| 9. Corruption Recovery | PASS / FAIL | ... | ... |
| 10. Invalid Response | PASS / FAIL | ... | ... |

## CACHE IMPLEMENTATION SCORE
Rate 1-10 based on:
- Scenario coverage
- Error resilience
- Thread safety
- HTTP optimization (304 usage)
- Eviction correctness

Start audit now.

Prompt 6
----------
You are a Flutter architecture auditor. Audit this codebase for compliance with its 4-layer architecture (Domain → Infrastructure → Application → Presentation), Riverpod state purity, Hive model integrity, and responsive UI rules.

### CRITICAL VIOLATIONS

**Hive Model Integrity**
1. Two or more `@HiveType` classes share the same `typeId` — causes silent data corruption across all devices
2. A `@HiveField` index was changed after data was already saved to device — existing data will be read incorrectly (fields mismatched)
3. A `@HiveType` model is missing a `TypeAdapter` registration before any box is opened

**Layer Boundary Violations**
4. Presentation layer (screens/widgets) accesses Infrastructure directly — calls `AuthApi`, `Hive`, or `Dio` without going through a provider
5. Application layer (StateNotifier/Provider) imports from `infrastructure/` — business logic must call the domain contract, not the implementation
6. Domain layer imports from `infrastructure/` or `application/` — domain must have zero upward dependencies
7. `ref.read()` used inside `build()` for reactive state — `ref.read()` does not subscribe, so the widget will not rebuild when state changes

**Domain Layer Purity**
8. A domain entity class contains a method that fetches data, calls an API, reads Hive, or contains UI logic
9. An abstract domain repository contains implementation code inside method bodies (curly braces with logic) instead of being a pure contract

**Infrastructure Layer Purity**
10. A `remote/` API class (e.g. `AuthApi`) contains caching decisions, business logic, or direct Hive calls — it must only make the HTTP call and convert the JSON response to a domain entity
11. Hive reads or writes exist outside of `infrastructure/local/` — any Hive access in `application/`, `presentation/`, or `domain/` is a boundary violation

### HIGH PRIORITY

**Riverpod / State**
12. A `StateNotifier` controller holds a reference to the infrastructure implementation (`AuthRepositoryImpl`) instead of the domain contract (`AuthRepository`) — breaks dependency inversion
13. A `State` class has mutable (`non-final`) fields — state must be immutable; all updates must go through `copyWith()`
14. `StateNotifier` updates state by mutating fields directly instead of using `copyWith()` to produce a new state object
15. `StatefulWidget` is used to manage actual data state (user profile, cart items, API results) instead of Riverpod — `StatefulWidget` is for purely visual/local state only (e.g. password show/hide, dropdown open/close)

**Infrastructure Repository**
16. An infrastructure repository class does not declare `implements <DomainRepository>` — the domain contract is not being fulfilled
17. An infrastructure repository method returns data without first checking the local Hive cache — skips the cache-check-then-API pattern

### MEDIUM PRIORITY

18. Feature folder does not follow the required 4-layer structure: `features/<name>/domain/`, `features/<name>/infrastructure/`, `features/<name>/application/`, `features/<name>/presentation/`
19. Hardcoded pixel values (`SizedBox(width: 24)`, `padding: EdgeInsets.all(16)`) used instead of ScreenUtil equivalents (`24.w`, `16.r`)
20. A domain entity has fields that are not `final` — entities must be immutable value objects
21. `ref.watch()` and `ref.read()` usage reversed: `ref.watch()` in a callback/onPressed, or `ref.read()` used where the widget must react to changes
22. A `ConsumerWidget` is used where no Riverpod provider is read — should be a `StatelessWidget`

## ARCHITECTURE COMPLIANCE CHECKLIST

### Domain Layer (`features/<name>/domain/`)
- [ ] All entity classes contain only `final` fields — no methods that fetch, mutate, or display
- [ ] All domain repository files are `abstract class` with no implementation inside method bodies
- [ ] Domain layer imports nothing from `infrastructure/`, `application/`, or `presentation/`
- [ ] No Hive, Dio, SharedPreferences, or Flutter imports anywhere in `domain/`

### Infrastructure Layer (`features/<name>/infrastructure/`)
- [ ] Every `remote/` class (API) only makes HTTP calls and converts JSON → domain entity. No caching, no business logic
- [ ] Every `local/` class is the ONLY file in the project that reads from or writes to Hive for its feature
- [ ] Every infrastructure repository class declares `implements <DomainRepository>`
- [ ] Every infrastructure repository method checks local cache before making a network call
- [ ] No `Hive` import exists outside of `infrastructure/local/` files

### Hive Model Integrity
- [ ] Every `@HiveType` class has a unique `typeId` — run a search across all files to confirm no duplicates
- [ ] No `@HiveField` index has been changed from its original value on a model that has already shipped to users
- [ ] Every `TypeAdapter` is registered in `main.dart` or an initializer before any `Hive.openBox()` call
- [ ] `@HiveField` indices are contiguous starting from 0 — no gaps (gaps suggest a field was deleted; document this)

### Application Layer (`features/<name>/application/`)
- [ ] Every `StateNotifier` constructor accepts the domain repository interface (abstract class), not the implementation
- [ ] All `State` classes have only `final` fields and a `copyWith()` method
- [ ] All state mutations inside `StateNotifier` use `copyWith()` — no direct field assignments
- [ ] No `import` from `infrastructure/` in any application-layer file
- [ ] `FutureProvider` is used only for read operations — mutations use `StateNotifierProvider`
- [ ] No `BuildContext`, `Navigator`, `SnackBar`, or `Dialog` in any provider or notifier

### Presentation Layer (`features/<name>/presentation/`)
- [ ] No `import` from `infrastructure/` — no direct Hive, Dio, or API class access
- [ ] No business logic in `build()` methods — data transformation belongs in the application or infrastructure layer
- [ ] `ref.watch()` used only inside `build()` — never in `onPressed`, `initState`, or async callbacks
- [ ] `ref.read()` used only in callbacks (`onPressed`, `onChange`) — never in `build()` for reactive state
- [ ] Widget type used correctly per decision tree:
  - `ConsumerWidget` → widget reads from at least one Riverpod provider
  - `StatefulWidget` → widget manages purely visual/local state (show/hide, open/close)
  - `StatelessWidget` → widget only receives data as constructor parameters and renders it
- [ ] No hardcoded pixel values — all sizes use ScreenUtil (`sp`, `w`, `h`, `r`)

### Feature Folder Structure
For each feature, verify this structure exists:
```
features/<feature_name>/
├── domain/
│   ├── entities/         ← plain Dart classes, final fields only
│   └── repositories/     ← abstract contracts, no implementation
├── infrastructure/
│   ├── data_sources/
│   │   ├── remote/       ← HTTP only, Dio, JSON → entity
│   │   └── local/        ← Hive only, no business logic
│   └── repositories/     ← implements domain contract
├── application/
│   ├── states/           ← immutable state classes with copyWith()
│   ├── providers/        ← Riverpod provider registrations
│   └── usecases/         ← (optional) complex multi-step operations
└── presentation/
    ├── screens/          ← full pages, ConsumerWidget
    └── components/       ← reusable UI pieces for this feature
```

## OUTPUT FORMAT

For each violation found:
**File:** path/to/file.dart:line_number
**Layer:** Domain | Infrastructure | Application | Presentation | Cross-layer
**Severity:** CRITICAL | HIGH | MEDIUM
**Rule Violated:** [Which numbered rule above]
**Issue:** [What is wrong and why it matters]
**Code:**
```dart
[Problematic code]
```
**Fix:**
```dart
[Corrected code]
```

## ARCHITECTURE HEALTH REPORT

| Layer | Files Audited | Critical | High | Medium | Status |
|-------|---------------|----------|------|--------|--------|
| Domain | ... | ... | ... | ... | PASS / FAIL |
| Infrastructure | ... | ... | ... | ... | PASS / FAIL |
| Application | ... | ... | ... | ... | PASS / FAIL |
| Presentation | ... | ... | ... | ... | PASS / FAIL |
| Cross-layer boundaries | ... | ... | ... | ... | PASS / FAIL |
| Hive model integrity | ... | ... | ... | ... | PASS / FAIL |

## ARCHITECTURE SCORE
Rate 1-10 based on:
- Layer boundary discipline (no shortcuts between layers)
- Domain purity (entities and contracts have no implementation leaks)
- Infrastructure isolation (Hive and Dio confined correctly)
- Riverpod correctness (watch/read usage, state immutability)
- Folder structure compliance per feature

Start audit now.
