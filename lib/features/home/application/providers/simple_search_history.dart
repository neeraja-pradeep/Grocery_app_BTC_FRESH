import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleSearchHistory extends StateNotifier<List<String>> {
  static const String _key = 'search_history';
  static const int _maxItems = 10;

  SimpleSearchHistory() : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_key) ?? [];
      // Debug: Loading history
      state = history;
    } catch (e) {
      // Debug: Error loading history
      state = [];
    }
  }

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = query.trim();

      // Create new list
      final newHistory = List<String>.from(state);

      // Remove if exists
      newHistory.remove(trimmed);

      // Add to beginning
      newHistory.insert(0, trimmed);

      // Limit size
      if (newHistory.length > _maxItems) {
        newHistory.removeRange(_maxItems, newHistory.length);
      }

      // Save to SharedPreferences
      await prefs.setStringList(_key, newHistory);

      // Update state
      state = newHistory;

      // Debug: Added search to history
    } catch (e) {
      // Debug: Error adding to history
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      state = [];
      // Debug: Cleared history
    } catch (e) {
      // Debug: Error clearing history
    }
  }
}

final simpleSearchHistoryProvider =
    StateNotifierProvider<SimpleSearchHistory, List<String>>((ref) {
      return SimpleSearchHistory();
    });
