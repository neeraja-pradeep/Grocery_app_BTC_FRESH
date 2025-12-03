// lib/features/home/application/providers/search_history_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../states/search_history_state.dart';

// ----------------------------------------------------------------------
// Search History Notifier (Manages Recent Search History)
// ----------------------------------------------------------------------

class SearchHistoryNotifier extends StateNotifier<SearchHistoryState> {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 10;

  SearchHistoryNotifier() : super(const SearchHistoryState.initial()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_searchHistoryKey) ?? [];
      // print('Loading search history: $searches'); // Debug
      state = SearchHistoryState.loaded(searches: searches);
    } catch (e) {
      // print('Error loading search history: $e'); // Debug
      state = const SearchHistoryState.error(
        message: 'Failed to load search history',
      );
    }
  }

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSearches = prefs.getStringList(_searchHistoryKey) ?? [];

      final trimmedQuery = query.trim();

      // print('Adding search: $trimmedQuery'); // Debug
      // print('Current searches before: $currentSearches'); // Debug

      // Remove if already exists to avoid duplicates
      currentSearches.remove(trimmedQuery);

      // Add to the beginning
      currentSearches.insert(0, trimmedQuery);

      // Keep only the latest items
      if (currentSearches.length > _maxHistoryItems) {
        currentSearches.removeRange(_maxHistoryItems, currentSearches.length);
      }

      // print('Current searches after: $currentSearches'); // Debug

      // Save to SharedPreferences
      final success = await prefs.setStringList(
        _searchHistoryKey,
        currentSearches,
      );

      if (success) {
        state = SearchHistoryState.loaded(searches: currentSearches);
        // print('Search history state updated: ${state.toString()}'); // Debug
      } else {
        throw Exception('Failed to save to SharedPreferences');
      }
    } catch (e) {
      // print('Error adding search: $e'); // Debug
      state = const SearchHistoryState.error(message: 'Failed to save search');
    }
  }

  Future<void> removeSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSearches = prefs.getStringList(_searchHistoryKey) ?? [];

      currentSearches.remove(query);

      await prefs.setStringList(_searchHistoryKey, currentSearches);
      state = SearchHistoryState.loaded(searches: currentSearches);
    } catch (e) {
      state = const SearchHistoryState.error(
        message: 'Failed to remove search',
      );
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
      state = const SearchHistoryState.loaded(searches: []);
    } catch (e) {
      state = const SearchHistoryState.error(
        message: 'Failed to clear history',
      );
    }
  }

  /// Manually refresh the search history from SharedPreferences
  Future<void> refreshHistory() async {
    await _loadHistory();
  }
}

// ----------------------------------------------------------------------
// Provider Definition
// ----------------------------------------------------------------------

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, SearchHistoryState>((ref) {
      // Keep the provider alive
      ref.keepAlive();
      return SearchHistoryNotifier();
    });

// ----------------------------------------------------------------------
// Selector for UI optimization
// ----------------------------------------------------------------------

final recentSearchesProvider = Provider<List<String>>((ref) {
  final historyState = ref.watch(searchHistoryProvider);

  final searches = historyState.maybeMap(
    loaded: (state) {
      return state.searches;
    },
    orElse: () {
      return <String>[];
    },
  );

  // print('recentSearchesProvider returning: $searches'); // Debug/
  return searches;
});
