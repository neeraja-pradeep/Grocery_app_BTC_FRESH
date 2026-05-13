# Search Flow — Code Audit Report

**Scope:** Search Screen · Voice Search Overlay · Voice Search Provider · Voice Search Service · Search History Providers · Product Search Card

**QA Criteria:** QA.md Prompts 1 · 2 · 3 · 4 · 6

**Date:** 2026-05-01

---

## Summary

| QA Section | Critical | High | Medium | Total |
|---|:-:|:-:|:-:|:-:|
| Prompt 1 — State Management | 2 | 3 | 2 | 7 |
| Prompt 2 — Security & Data Persistence | 0 | 2 | 2 | 4 |
| Prompt 3 — Performance & Error Handling | 1 | 2 | 3 | 6 |
| Prompt 4 — Code Quality & Deployment | 1 | 2 | 3 | 6 |
| Prompt 6 — Architecture Compliance | 2 | 2 | 2 | 6 |
| **Total** | **6** | **11** | **12** | **29** |

---

## Top Blockers Before Any Production Release

1. **Trending product taps are a complete no-op** — `SearchScreen._buildHistoryAndTrending` renders trending products but the `onProductClick` callback body is an empty comment. Tapping any trending product does nothing. User-visible broken feature.
2. **`ProductSearchCard` imports infrastructure directly** — the search result card imports `checkout_line_data_source.dart` from the cart infrastructure layer to catch `InsufficientStockException`. The presentation layer must never import infrastructure files.
3. **`SearchNotifier.performSearch()` has no try-catch** — if the repository throws instead of returning a `Left(failure)`, the exception is uncaught and crashes the app during any search.
4. **Duplicate `simpleSearchHistoryProvider` in two separate files** — `simple_search_history.dart` and `search_history_provider_simple.dart` both export a provider with the identical name but different implementations (one persists to SharedPreferences, the other is in-memory only). Importing the wrong file causes silent data loss between app sessions.
5. **`ref.watch()` called conditionally inside `_buildSearchResults`** — watches on `simpleSearchHistoryProvider` and `homeProvider` only fire inside the `initial:` branch of `searchState.when()`. When state transitions to `loaded`, the watches are dropped and trending data becomes stale.

---

---

# QA Prompt 1 — State Management (Riverpod Violations)

---

## Critical Issues

---

### C1 — `ref.watch()` called conditionally inside `_buildSearchResults`

**File:** `lib/features/home/presentation/screen/search_screen.dart:229–236`

**Severity:** CRITICAL

**Issue:** Inside `_buildSearchResults()` (called from `build()`), the `initial:` branch of `searchState.when()` calls `ref.watch(simpleSearchHistoryProvider)` and `ref.watch(homeProvider)`. These watches only execute when the state is `initial`. Riverpod requires watches to be unconditional and consistent across every `build()` invocation.

**Code:**
```dart
Widget _buildSearchResults(SearchState searchState) {
  return searchState.when(
    initial: () => _buildHistoryAndTrending(
      ref.watch(simpleSearchHistoryProvider), // conditional watch
      ref.watch(homeProvider).maybeMap(...),  // conditional watch
    ),
    ...
  );
}
```

**Impact:** When state transitions from `initial` to `loaded`, the subscriptions to `simpleSearchHistoryProvider` and `homeProvider` are silently dropped. If those providers update while results are showing, the widget will not rebuild — the user sees stale recent searches and stale trending data when they clear the search field.

**Fix Required:** Move both `ref.watch` calls to the top of `build()` unconditionally (they are already watched there — `recentSearches` and `trendingProducts` at lines 95–103). Pass the already-computed values into `_buildHistoryAndTrending` rather than re-watching inside the method. Remove the inner watches entirely.

---

### C2 — `SearchNotifier` and `VoiceSearchNotifier` use deprecated `StateNotifier` instead of Riverpod 2.x codegen

**File:** `lib/features/home/application/providers/home_provider.dart:177`
**File:** `lib/features/home/application/providers/voice_search_provider.dart:27`

**Severity:** CRITICAL

**Issue:** Both notifiers use the deprecated `StateNotifier<T>` pattern with manual `StateNotifierProvider` registration. The rest of the codebase uses `@riverpod` code generation (e.g. `AuthNotifier` uses `@Riverpod(keepAlive: true)`). The search feature is architecturally inconsistent with every other feature.

**Code:**
```dart
// home_provider.dart
class SearchNotifier extends StateNotifier<SearchState> { ... }
final searchProvider = StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) { ... });

// voice_search_provider.dart
class VoiceSearchNotifier extends StateNotifier<VoiceSearchState> { ... }
final voiceSearchProvider = StateNotifierProvider.autoDispose<VoiceSearchNotifier, VoiceSearchState>((ref) { ... });
```

**Impact:** Two different state management paradigms in the same app. `StateNotifier` is deprecated in Riverpod 2.x. Codegen providers automatically gain `autoDispose`, `family`, and ref-safety features. Developers context-switch between the old and new patterns, increasing maintenance burden and bug risk.

**Fix Required:** Migrate to:
```dart
@riverpod
class SearchController extends _$SearchController {
  @override
  SearchState build() => const SearchState.initial();
  ...
}
```
Follow the codegen pattern used in `AuthNotifier`.

---

## High Priority Issues

---

### H1 — Trending product `onProductClick` callback is an empty no-op

**File:** `lib/features/home/presentation/screen/search_screen.dart:362–367`

**Severity:** HIGH

**Issue:** The callback for tapping a trending product contains only a comment and no navigation code. Any trending product tap silently does nothing.

**Code:**
```dart
ProductHorizontalList(
  products: trendingProducts,
  onProductClick: (product) {
    // Navigate to product detail
  },
)
```

**Impact:** Trending products are visible and tappable but entirely non-interactive. This is a broken user-facing feature that will be noticed immediately during QA testing on a physical device.

**Fix Required:**
```dart
onProductClick: (product) {
  context.push('/product-details/${product.id}');
},
```

---

### H2 — `simpleSearchHistoryProvider` has no lifecycle annotation — risk of unintended disposal

**File:** `lib/features/home/application/providers/simple_search_history.dart:69`

**Severity:** HIGH

**Issue:** `simpleSearchHistoryProvider` is registered as a plain `StateNotifierProvider` with no `autoDispose` or `keepAlive`. When no widget is watching it (e.g. after navigating away from the search screen), Riverpod's default behaviour disposes the provider. The next time the search screen opens, the history is reloaded from SharedPreferences from scratch, causing a flash of empty history before the async load completes.

**Code:**
```dart
final simpleSearchHistoryProvider =
    StateNotifierProvider<SimpleSearchHistory, List<String>>((ref) {
      return SimpleSearchHistory();
    });
```

**Impact:** Users see an empty recent searches list on every open of the search screen until the async `_loadHistory()` completes. Session consistency is broken.

**Fix Required:** Add `keepAlive()` to prevent disposal between search screen visits:
```dart
final simpleSearchHistoryProvider =
    StateNotifierProvider<SimpleSearchHistory, List<String>>((ref) {
      ref.keepAlive();
      return SimpleSearchHistory();
    });
```

---

### H3 — Duplicate `simpleSearchHistoryProvider` defined in two files with different implementations

**File:** `lib/features/home/application/providers/simple_search_history.dart:69`
**File:** `lib/features/home/application/providers/search_history_provider_simple.dart:38`

**Severity:** HIGH

**Issue:** Both files export a provider named `simpleSearchHistoryProvider`. The one in `simple_search_history.dart` uses `SharedPreferences` (persists across restarts). The one in `search_history_provider_simple.dart` is purely in-memory ("Simple in-memory version for testing"). `search_screen.dart` currently imports the SharedPreferences version, but the in-memory version in the same directory will cause confusion and can be imported by mistake.

**Code:**
```dart
// simple_search_history.dart — persists to SharedPreferences
final simpleSearchHistoryProvider =
    StateNotifierProvider<SimpleSearchHistory, List<String>>(...);

// search_history_provider_simple.dart — in-memory only
final simpleSearchHistoryProvider =
    StateNotifierProvider<SimpleSearchHistoryNotifier, List<String>>(...);
```

**Impact:** Any developer importing `search_history_provider_simple.dart` instead of `simple_search_history.dart` will silently lose search history on every app restart. The duplicate name makes this a single-import-path error away from a data-loss regression.

**Fix Required:** Delete `search_history_provider_simple.dart` entirely (test code must not live in production source). If an in-memory version is needed for tests, move it to the `test/` directory.

---

## Medium Priority Issues

---

### M1 — `SearchState.listening` state defined but `SearchNotifier` never transitions to it

**File:** `lib/features/home/application/states/search_state.dart:16`
**File:** `lib/features/home/application/providers/home_provider.dart:187–191`

**Severity:** MEDIUM

**Issue:** `SearchState` declares a `listening` factory for voice search listening, but `SearchNotifier.startSearch()` transitions directly from `initial` to `loading`, skipping `listening` entirely. The UI handles `listening` with a spinner, but it is never triggered by the notifier.

**Code:**
```dart
// State declared:
const factory SearchState.listening({required bool isVoiceSearch}) = SearchListening;

// Notifier skips it:
void startSearch(String query, {bool isVoice = false}) {
  state = SearchState.loading(query: query, isVoiceSearch: isVoice); // jumps to loading
  performSearch(query);
}
```

**Impact:** Dead state variant in production code. The `listening:` branch in `_buildSearchResults` (`search_screen.dart:239`) is an unreachable code path. Confuses developers reading the state machine.

**Fix Required:** Either remove `SearchState.listening` from the freezed class (and the `when` branch in the UI) if voice listening state is already handled by `VoiceSearchState`, or wire `SearchNotifier.startSearch(isVoice: true)` to set `state = SearchState.listening(isVoiceSearch: true)` before starting the search.

---

### M2 — `voiceSearchServiceProvider` is a global `Provider` but `voiceSearchProvider` is `autoDispose` — lifecycle mismatch

**File:** `lib/features/home/application/providers/voice_search_provider.dart:11–24`

**Severity:** MEDIUM

**Issue:** `voiceSearchServiceProvider` is a plain global `Provider<VoiceSearchService>` (always alive). `voiceSearchProvider` is `StateNotifierProvider.autoDispose`, so when the search screen is closed, the notifier disposes — but the `VoiceSearchService` it was using remains alive indefinitely. The `VoiceSearchService` holds a `SpeechToText` instance that keeps the microphone permission binding active.

**Code:**
```dart
final voiceSearchServiceProvider = Provider<VoiceSearchService>((ref) { // never disposes
  final service = VoiceSearchService();
  ref.onDispose(() => service.dispose()); // only called on full app teardown
  return service;
});

final voiceSearchProvider =
    StateNotifierProvider.autoDispose<VoiceSearchNotifier, VoiceSearchState>((ref) {
      final service = ref.watch(voiceSearchServiceProvider);
      return VoiceSearchNotifier(service: service);
    });
```

**Impact:** `SpeechToText` is instantiated once at first use and lives for the entire app lifetime. On Android, this keeps a reference that may hold onto microphone-related resources longer than necessary.

**Fix Required:** Mark `voiceSearchServiceProvider` as `autoDispose` to match the notifier:
```dart
final voiceSearchServiceProvider = Provider.autoDispose<VoiceSearchService>((ref) {
  final service = VoiceSearchService();
  ref.onDispose(() => service.dispose());
  return service;
});
```

---

---

# QA Prompt 2 — Security & Data Persistence Violations

---

## Critical Issues

*No critical violations found in the search flow.*

---

## High Priority Issues

---

### H1 — Search history stored in plain unencrypted `SharedPreferences`

**File:** `lib/features/home/application/providers/simple_search_history.dart:14, 27`

**Severity:** HIGH

**Issue:** Recent search queries are persisted to `SharedPreferences` with a plain string key `'search_history'`. On rooted Android devices, other applications can read `SharedPreferences` data. Search queries may reveal sensitive purchasing intent (medications, personal items) that users expect to remain private.

**Code:**
```dart
Future<void> _loadHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final history = prefs.getStringList(_key) ?? []; // plain storage, no encryption
  state = history;
}

Future<void> addSearch(String query) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_key, newHistory); // stored unencrypted
}
```

**Impact:** On rooted devices or via Android backup extraction, a third party can read the user's full search history. No encryption or secure storage is applied.

**Fix Required:** Migrate to `flutter_secure_storage` for search history, or at minimum use Hive with AES encryption (already a project dependency) rather than plain `SharedPreferences`.

---

### H2 — `VoiceSearchService` error callbacks silently swallowed during initialization

**File:** `lib/core/services/voice_search_service.dart:22–29`

**Severity:** HIGH

**Issue:** The `SpeechToText.initialize()` `onError` and `onStatus` callbacks are intentionally emptied (the print statements are commented out and no alternative logging is substituted). Speech recognition errors during initialization are silently discarded, making it impossible to detect failure modes in production.

**Code:**
```dart
_isInitialized = await _speechToText.initialize(
  onError: (error) {
    // Log error for debugging
    // print('Speech recognition error: ${error.errorMsg}');
  },
  onStatus: (status) {
    // Log status for debugging
    // print('Speech recognition status: $status');
  },
);
```

**Impact:** If speech recognition fails mid-session (e.g. due to system resource limits or OS permission revocation), the error is completely invisible. No crash reporting, no user feedback, no ability to triage production failures. The user may see a stuck overlay with no indication of what went wrong.

**Fix Required:** Replace the commented-out prints with the project's Logger utility:
```dart
onError: (error) {
  Logger.error('Voice search recognition error', data: {'error': error.errorMsg, 'permanent': error.permanent});
},
onStatus: (status) {
  Logger.debug('Voice search status changed', data: {'status': status});
},
```

---

## Medium Priority Issues

---

### M1 — `SharedPreferences.getInstance()` called on every `addSearch` invocation — repeated initialisation

**File:** `lib/features/home/application/providers/simple_search_history.dart:27`
**File:** `lib/features/home/application/providers/search_history_provider.dart:38`

**Severity:** MEDIUM

**Issue:** Both `SimpleSearchHistory.addSearch()` and `SearchHistoryNotifier.addSearch()` call `SharedPreferences.getInstance()` each time a search is submitted. `getInstance()` re-acquires the singleton on every call, adding unnecessary async overhead and platform channel roundtrips on every keystroke submit.

**Code:**
```dart
Future<void> addSearch(String query) async {
  final prefs = await SharedPreferences.getInstance(); // called on every add
  ...
}
```

**Impact:** On low-end Android devices, the platform channel call to `getInstance()` introduces a measurable delay (5–20ms) on every search submission. With debounce-throttled searches, this compounds.

**Fix Required:** Cache the `SharedPreferences` instance as a field, initialised once in the constructor or via `_loadHistory()`:
```dart
late final SharedPreferences _prefs;
Future<void> _loadHistory() async {
  _prefs = await SharedPreferences.getInstance();
  ...
}
```

---

### M2 — `voiceSearchServiceProvider` not `autoDispose` — `SpeechToText` instance lives for app lifetime

**File:** `lib/features/home/application/providers/voice_search_provider.dart:11`

**Severity:** MEDIUM

**Issue:** `VoiceSearchService` (which wraps `SpeechToText`) is instantiated as a non-disposable global provider. The `SpeechToText` package documentation notes it should be disposed when no longer needed to release OS-level speech recognition resources. The `onDispose` callback only fires at full app teardown.

**Code:**
```dart
final voiceSearchServiceProvider = Provider<VoiceSearchService>((ref) {
  final service = VoiceSearchService();
  ref.onDispose(() => service.dispose()); // only fires on app exit
  return service;
});
```

**Impact:** OS microphone resources tied to `SpeechToText` are held for the entire app session even though voice search is only used during the search screen lifetime. On some Android versions this can cause microphone access conflicts with other apps.

**Fix Required:** See Prompt 1 M2 — convert to `autoDispose`.

---

---

# QA Prompt 3 — Error Handling & Performance

---

## Critical Issues

---

### C1 — `SearchNotifier.performSearch()` has no try-catch — unhandled exception crashes the app

**File:** `lib/features/home/application/providers/home_provider.dart:194–213`

**Severity:** CRITICAL

**Issue:** `performSearch()` calls `_repository.searchProducts()` without wrapping it in try-catch or using `AsyncValue.guard()`. If the repository throws synchronously (e.g. `Dio` throws before returning an `Either`, or a `TypeError` occurs during response parsing), the exception propagates through the notifier and crashes the app. The method is also `async` with no error boundary.

**Code:**
```dart
Future<void> performSearch(String query) async {
  final result = await _repository.searchProducts(query: query); // no try-catch
  result.fold(
    (failure) => state = SearchState.error(failure: failure, query: query),
    (variants) { ... },
  );
}
```

**Impact:** Any unexpected exception during a search — malformed JSON, network interruption throwing synchronously, null reference in response parsing — will crash the app instead of showing the error state. The `error:` UI branch built in the screen is never reached in these scenarios.

**Fix Required:**
```dart
Future<void> performSearch(String query) async {
  try {
    final result = await _repository.searchProducts(query: query);
    result.fold(
      (failure) => state = SearchState.error(failure: failure, query: query),
      (variants) { ... },
    );
  } catch (e, st) {
    Logger.error('Unexpected search error', error: e, stackTrace: st);
    state = SearchState.error(
      failure: UnexpectedFailure(message: 'Search failed unexpectedly'),
      query: query,
    );
  }
}
```

---

## High Priority Issues

---

### H1 — No timeout on `searchProducts` API call — search hangs indefinitely on slow network

**File:** `lib/features/home/application/providers/home_provider.dart:195`

**Severity:** HIGH

**Issue:** `_repository.searchProducts(query: query)` has no per-call timeout. If the server is slow or unresponsive, the search stays in `loading` state indefinitely. The QA rules require per-request timeouts for critical operations.

**Code:**
```dart
final result = await _repository.searchProducts(query: query); // no timeout
```

**Impact:** A user typing in the search field triggers a debounced search. If the network stalls, the spinner shows forever. The user has no way to know if the app is working or frozen. No retry mechanism is offered.

**Fix Required:**
```dart
final result = await _repository.searchProducts(query: query)
    .timeout(
      const Duration(seconds: 10),
      onTimeout: () => const Left(NetworkFailure(message: 'Search timed out')),
    );
```
Additionally wire the `error:` UI branch to offer a retry button (already present at `search_screen.dart:279`).

---

### H2 — `VoiceSearchNotifier.startListening()` has no try-catch — exception crashes the app

**File:** `lib/features/home/application/providers/voice_search_provider.dart:70–74`

**Severity:** HIGH

**Issue:** `startListening()` on the service layer calls `SpeechToText.listen()`. The `speech_to_text` package can throw platform exceptions (e.g. if the OS denies microphone access mid-session or the audio session is interrupted). Neither `VoiceSearchService.startListening()` nor `VoiceSearchNotifier.startVoiceSearch()` wraps this in try-catch.

**Code:**
```dart
// voice_search_provider.dart
await _service.startListening(       // no try-catch
  onResult: _onSpeechResult,
  listenFor: const Duration(seconds: 30),
  pauseFor: const Duration(seconds: 3),
);

// voice_search_service.dart
await _speechToText.listen(          // no try-catch
  onResult: onResult,
  ...
);
```

**Impact:** A `PlatformException` from the audio system (common on Android when another app holds the audio focus) propagates uncaught, crashing the app while the voice search overlay is open.

**Fix Required:**
```dart
// In VoiceSearchNotifier
try {
  await _service.startListening(onResult: _onSpeechResult, ...);
} catch (e) {
  Logger.error('Voice search start failed', error: e);
  state = VoiceSearchState.error(message: 'Failed to start listening');
}
```

---

## Medium Priority Issues

---

### M1 — Load-more indicator uses hardcoded `EdgeInsets.all(16.0)` instead of ScreenUtil

**File:** `lib/features/home/presentation/screen/search_screen.dart:384–387`

**Severity:** MEDIUM

**Issue:** The pagination loader at the bottom of the results list uses a hardcoded pixel padding.

**Code:**
```dart
return const Padding(
  padding: EdgeInsets.all(16.0), // hardcoded, not 16.r
  child: Center(child: CircularProgressIndicator()),
);
```

**Impact:** Inconsistent with the rest of the UI that uses ScreenUtil responsive sizing. On tablets and large-screen Android devices this renders proportionally small.

**Fix Required:** `Padding(padding: EdgeInsets.all(16.r), child: ...)`. Remove `const`.

---

### M2 — `SimpleSearchHistory` loads history asynchronously in constructor — no loading state during fetch

**File:** `lib/features/home/application/providers/simple_search_history.dart:8–9`

**Severity:** MEDIUM

**Issue:** `SimpleSearchHistory()` immediately calls `_loadHistory()` in the constructor. The state starts as `[]` and asynchronously transitions once the SharedPreferences read completes. The search screen renders "no recent searches" momentarily every time the provider is re-created after disposal.

**Code:**
```dart
class SimpleSearchHistory extends StateNotifier<List<String>> {
  SimpleSearchHistory() : super([]) { // starts empty
    _loadHistory();                   // async — may take 10-50ms
  }
```

**Impact:** On each fresh navigation to the search screen (if the provider was disposed), users see a brief flash of empty recent searches before the list appears. Minor but noticeable UX regression.

**Fix Required:** Use a `keepAlive()` provider (see Prompt 1 H2) so the loaded state persists between search screen visits. Alternatively initialise `SharedPreferences` once at app start and inject it.

---

### M3 — `_buildHistoryAndTrending` uses `SingleChildScrollView` + `Column` — not lazy

**File:** `lib/features/home/presentation/screen/search_screen.dart:289–371`

**Severity:** MEDIUM

**Issue:** The history and trending section uses `SingleChildScrollView` wrapping a `Column`. If trending products grow (best deals list), all product widgets are rendered upfront regardless of whether they are visible.

**Code:**
```dart
Widget _buildHistoryAndTrending(...) {
  return SingleChildScrollView(
    child: Column(
      children: [
        ...recentSearches.map((...) { ... }).toList(), // all rendered
        ProductHorizontalList(products: trendingProducts, ...), // all rendered
      ],
    ),
  );
}
```

**Impact:** Minor current performance cost since trending items are horizontally scrolled. However, if the number of recent searches grows to the maximum 10, all 10 + all trending products are always laid out. On rebuild (e.g. new search history added), all children re-evaluate.

**Fix Required:** Use `ListView` with a fixed `itemCount` for the combined history + trending section, or keep `SingleChildScrollView` but ensure `ProductHorizontalList` internally uses a `ListView.builder` rather than a `Row`.

---

---

# QA Prompt 4 — Code Quality & Deployment Readiness

---

## Critical Issues

---

### C1 — Trending product tap is entirely non-functional — user-visible broken feature

**File:** `lib/features/home/presentation/screen/search_screen.dart:362–367`

**Severity:** CRITICAL

**Issue:** The `onProductClick` callback passed to `ProductHorizontalList` for trending products contains only a comment with no implementation. Tapping any trending product silently does nothing.

**Code:**
```dart
ProductHorizontalList(
  products: trendingProducts,
  onProductClick: (product) {
    // Navigate to product detail
  },
)
```

**Impact:** Trending products are one of the primary discovery features on the search screen. The entire section is decorative — tapping produces no navigation, no feedback, and no error. This will be caught in any physical device test and blocks release.

**Fix Required:**
```dart
onProductClick: (product) {
  context.push('/product-details/${product.id}');
},
```

---

## High Priority Issues

---

### H1 — `SearchHistoryNotifier` provider is fully implemented but entirely unused — dead code

**File:** `lib/features/home/application/providers/search_history_provider.dart:114–139`

**Severity:** HIGH

**Issue:** `search_history_provider.dart` contains a complete, typed `SearchHistoryNotifier` with `addSearch`, `removeSearch`, `clearHistory`, and `refreshHistory` methods, plus a typed freezed `SearchHistoryState` with error handling. The `SearchScreen` uses none of this — it uses `simpleSearchHistoryProvider` from `simple_search_history.dart` instead. The full implementation is dead code.

**Code:**
```dart
// search_history_provider.dart — never imported by search_screen.dart
final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, SearchHistoryState>((ref) {
      ref.keepAlive();
      return SearchHistoryNotifier();
    });

final recentSearchesProvider = Provider<List<String>>((ref) { ... }); // also unused
```

**Impact:** ~140 lines of dead production code. Two notifier classes + two provider files exist for the same feature with no clear documentation of which is authoritative. Any new developer will waste time determining which to use.

**Fix Required:** Decide on one implementation. If `simple_search_history.dart` is the chosen path, delete `search_history_provider.dart` and `search_history_provider_simple.dart`. If `search_history_provider.dart` is preferred (better typed state, error handling), wire `SearchScreen` to use `searchHistoryProvider`/`recentSearchesProvider` and delete `simple_search_history.dart` and `search_history_provider_simple.dart`.

---

### H2 — `Navigator.pop(context)` used instead of GoRouter `context.pop()` for back navigation

**File:** `lib/features/home/presentation/screen/search_screen.dart:138`

**Severity:** HIGH

**Issue:** The back arrow in the search screen uses `Navigator.pop(context)` directly, bypassing GoRouter's navigation stack management.

**Code:**
```dart
GestureDetector(
  onTap: () => Navigator.pop(context), // bypasses GoRouter
  child: Container(
    ...
    child: Icon(Icons.arrow_back_ios_new, ...),
  ),
),
```

**Impact:** GoRouter's `redirect` guards, route history tracking, and deep link back-stack are bypassed. If the search screen is reached via a deep link or from a non-standard route, `Navigator.pop` may pop the wrong route or pop past a GoRouter-managed boundary, leaving the app on an incorrect screen.

**Fix Required:** `onTap: () => context.pop(),` — use GoRouter's pop method consistently.

---

## Medium Priority Issues

---

### M1 — Hardcoded product-specific hint text in search inputs

**File:** `lib/features/home/presentation/screen/search_screen.dart:178`
**File:** `lib/features/home/presentation/components/search_bar.dart:51`

**Severity:** MEDIUM

**Issue:** Two separate search input widgets hardcode specific product names as hint text examples.

**Code:**
```dart
// search_screen.dart
hintText: "Search For 'Cooker'",

// search_bar.dart (CustomSearchBar)
hintText: 'Search for "Rice"',
```

**Impact:** A grocery delivery app hardcoding "Cooker" and "Rice" as examples may mislead users if the product catalogue doesn't include those items, or may feel irrelevant to users in markets where those aren't common search terms. Both hint texts should be generic or pulled from top-searched terms.

**Fix Required:** Use generic hint text: `'Search products...'` or `'What are you looking for?'`. If the backend supports a "top searches" API, the hint can rotate through actual popular queries.

---

### M2 — `SearchState.listening` is a dead state variant — unreachable code path in the UI

**File:** `lib/features/home/application/states/search_state.dart:16`

**Severity:** MEDIUM

**Issue:** `SearchState.listening` is declared in the freezed class and handled in `_buildSearchResults` with a `CircularProgressIndicator`, but `SearchNotifier.startSearch()` never transitions to this state. The `listening:` branch is unreachable dead code.

**Code:**
```dart
// Defined in search_state.dart
const factory SearchState.listening({required bool isVoiceSearch}) = SearchListening;

// Handled in search_screen.dart (line 239) but never reached:
listening: (isVoice) => const Center(child: CircularProgressIndicator()),
```

**Impact:** Dead state machine variants and dead UI branches add cognitive overhead and mislead developers about the intended flow.

**Fix Required:** Either remove `SearchState.listening` and its UI branch entirely, or wire the notifier to use it before starting an API call for voice-initiated searches.

---

### M3 — `VoiceSearchButton` component is dead code — not used by `SearchScreen`

**File:** `lib/features/home/presentation/components/voice_search_button.dart`

**Severity:** MEDIUM

**Issue:** `VoiceSearchButton` is a standalone widget component, but `SearchScreen` implements its own inline mic icon using a `GestureDetector` + `Icon(Icons.mic, ...)`. The component is not imported or used anywhere in the search flow.

**Code:**
```dart
// voice_search_button.dart — unused component
class VoiceSearchButton extends StatelessWidget {
  final VoidCallback onStartVoiceSearch;
  ...
  child: Icon(Icons.mic, color: Colors.green, size: 20),
  ...
}

// search_screen.dart — inline implementation (not reusing the component)
GestureDetector(
  onTap: _handleVoiceSearch,
  child: Icon(Icons.mic, color: const Color(0xFF0b6866), size: 24.sp),
),
```

**Impact:** Dead component in production code. Also, the inline icon uses `Color(0xFF0b6866)` while the component uses `Colors.green` — if the component is ever reused, the colour inconsistency will be a visual bug.

**Fix Required:** Delete `voice_search_button.dart` and replace the `SearchScreen`'s inline mic icon with `VoiceSearchButton(onStartVoiceSearch: _handleVoiceSearch)` if reuse is desired. Otherwise remove the dead file.

---

---

# QA Prompt 6 — Architecture Compliance (4-Layer Violations)

---

## Critical Issues

---

### C1 — `ProductSearchCard` imports infrastructure layer directly — layer boundary violation

**File:** `lib/features/home/presentation/components/product_search_card.dart:9`

**Layer:** Presentation → Infrastructure (Rule 4 violation)

**Severity:** CRITICAL

**Issue:** `ProductSearchCard` (a presentation layer widget) imports `cart/infrastructure/data_sources/remote/checkout_line_data_source.dart` to catch `InsufficientStockException`. Presentation must never import infrastructure files — exceptions and domain errors must be surfaced through the application layer.

**Code:**
```dart
import '../../../cart/infrastructure/data_sources/remote/checkout_line_data_source.dart';
// Used as:
} on InsufficientStockException catch (e) {
  if (context.mounted) {
    AppSnackbar.warning(context, e.message);
  }
}
```

**Impact:** The search result card is tightly coupled to the cart infrastructure implementation. Any refactor of `checkout_line_data_source.dart` (renaming the exception, moving the file) requires changes in the UI layer. This collapses the 4-layer boundary between presentation and infrastructure.

**Fix Required:** Move `InsufficientStockException` to the domain layer (`cart/domain/exceptions/`) or to a shared core exceptions file. Presentation catches only domain exceptions, never infrastructure ones.

---

### C2 — Providers defined inside notifier/history class files instead of `application/providers/`

**File:** `lib/features/home/application/providers/simple_search_history.dart:69`
**File:** `lib/features/home/application/providers/search_history_provider_simple.dart:38`

**Layer:** Application (Rule 5 pattern — providers misplaced)

**Severity:** CRITICAL

**Issue:** Both `simple_search_history.dart` and `search_history_provider_simple.dart` define their Riverpod providers inside the same file as the notifier class, creating monolithic files that mix the notifier implementation with its provider registration. The prescribed architecture separates these concerns.

**Code:**
```dart
// simple_search_history.dart — notifier + provider in one file
class SimpleSearchHistory extends StateNotifier<List<String>> { ... }

final simpleSearchHistoryProvider =                       // ← provider in same file
    StateNotifierProvider<SimpleSearchHistory, List<String>>((ref) { ... });
```

**Impact:** Both files can be independently imported, creating two provider registrations with the same name. Any file that uses both is non-deterministic about which provider it resolves. Mixtures of notifier + provider in the same file prevent clean dependency inversion.

**Fix Required:** Separate into two files: `simple_search_history_notifier.dart` (class only) and `search_history_provider.dart` (provider registration only). Follow the same pattern as `auth_provider.dart` which separates state, notifier, and provider.

---

## High Priority Issues

---

### H1 — `SearchNotifier` imports infrastructure implementation file — application depends on infrastructure

**File:** `lib/features/home/application/providers/home_provider.dart:12`

**Layer:** Application → Infrastructure (Rule 5 violation)

**Severity:** HIGH

**Issue:** `home_provider.dart` imports `home_repostory_impl.dart` (an infrastructure file) to access `homeRepositoryProvider`. The application layer must depend on the domain abstract `HomeRepository`, resolved through a provider in `application/providers/` — not by importing the infrastructure implementation file.

**Code:**
```dart
import '../../infrastructure/repositories/home_repostory_impl.dart';
// Accessed via:
final repository = ref.watch(homeRepositoryProvider);
```

**Impact:** `SearchNotifier` is coupled to the infrastructure repository implementation. This is the same systemic violation flagged in the Home audit (Prompt 6 H1). It must be resolved for the entire `home_provider.dart` file — both `HomeNotifier` and `SearchNotifier` are affected.

**Fix Required:** Move `homeRepositoryProvider` to `lib/features/home/application/providers/home_repository_provider.dart`. Replace the infrastructure import with this application-layer provider file.

---

### H2 — `VoiceSearchService` has no domain interface — application layer depends on concrete class

**File:** `lib/features/home/application/providers/voice_search_provider.dart:7–8`

**Layer:** Application → Concrete class (Rule 8 pattern violation)

**Severity:** HIGH

**Issue:** `VoiceSearchNotifier` depends directly on the concrete `VoiceSearchService` class rather than an abstract interface. There is no `AbstractVoiceSearchService` or `IVoiceSearchService` contract in the domain layer.

**Code:**
```dart
import '../../../../core/services/voice_search_service.dart'; // concrete class

class VoiceSearchNotifier extends StateNotifier<VoiceSearchState> {
  final VoiceSearchService _service; // concrete, not abstract
  VoiceSearchNotifier({required VoiceSearchService service}) ...
}
```

**Impact:** The notifier cannot be unit tested with a mock speech service — tests must use the real `SpeechToText` implementation. Any swap of the speech recognition provider (e.g. switching from `speech_to_text` to a different package) requires changes in both the service and the notifier.

**Fix Required:** Define an abstract `VoiceSearchService` interface (or rename current to `VoiceSearchServiceImpl`) in the domain or core layer. The notifier accepts the abstract type. Tests can inject a `MockVoiceSearchService`.

---

## Medium Priority Issues

---

### M1 — `search_history_provider_simple.dart` is in-memory test code in the production source tree

**File:** `lib/features/home/application/providers/search_history_provider_simple.dart:1`

**Layer:** Presentation / Application (test artefact in production path)

**Severity:** MEDIUM

**Issue:** The file header explicitly states "Simple in-memory version for testing". The class `SimpleSearchHistoryNotifier` stores nothing to disk and resets on every app start. This file is in `lib/` (production source), not `test/`.

**Code:**
```dart
// Simple in-memory version for testing
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SimpleSearchHistoryNotifier extends StateNotifier<List<String>> {
  SimpleSearchHistoryNotifier() : super([]); // no persistence
  ...
}
```

**Impact:** Test code in production source increases bundle size and creates the duplicate provider name collision described in Prompt 1 H3. If a developer imports this file (intending the "simple" version), search history is silently non-persistent.

**Fix Required:** Delete from `lib/`. If needed for tests, place in `test/helpers/` or `test/mocks/`.

---

### M2 — `VoiceSearchState.error` defined in the state class but `VoiceSearchNotifier` never emits it

**File:** `lib/features/home/application/states/voice_search_state.dart:37`
**File:** `lib/features/home/application/providers/voice_search_provider.dart`

**Layer:** Application (dead state variant)

**Severity:** MEDIUM

**Issue:** `VoiceSearchState.error` with a `required String message` field is declared in the freezed class and handled in `_VoiceSearchDialog._buildErrorUI()`, but `VoiceSearchNotifier` never transitions to it. There is no code path in the notifier that sets `state = VoiceSearchState.error(message: ...)`.

**Code:**
```dart
// Declared in voice_search_state.dart
const factory VoiceSearchState.error({required String message}) = VoiceSearchError;

// Handled in voice_search_overlay.dart
error: (message) => _buildErrorUI(message), // unreachable

// Never emitted in voice_search_provider.dart — no VoiceSearchState.error(...) call
```

**Impact:** The error UI in the voice search overlay is an unreachable code path. Any speech recognition error that should show the error UI instead transitions to `idle` or silently fails. Users see no feedback when voice search errors occur.

**Fix Required:** Wire `VoiceSearchNotifier` to emit `VoiceSearchState.error` in the try-catch blocks introduced in Prompt 3 H2. The error state and the UI to display it are already built — they just need to be connected.

---
