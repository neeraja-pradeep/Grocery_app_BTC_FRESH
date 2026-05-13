import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleSearchHistory extends StateNotifier<List<String>> {
  static const String _key = 'search_history';
  static const int _maxItems = 10;

  SharedPreferences? _prefs;

  SimpleSearchHistory() : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final history = _prefs!.getStringList(_key) ?? [];
      state = history;
    } catch (e) {
      state = [];
    }
  }

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      _prefs ??= await SharedPreferences.getInstance();
      final trimmed = query.trim();

      final newHistory = List<String>.from(state);
      newHistory.remove(trimmed);
      newHistory.insert(0, trimmed);

      if (newHistory.length > _maxItems) {
        newHistory.removeRange(_maxItems, newHistory.length);
      }

      await _prefs!.setStringList(_key, newHistory);
      state = newHistory;
    } catch (e) {
      // history update failure is non-critical, don't surface to user
    }
  }

  Future<void> clearHistory() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.remove(_key);
      state = [];
    } catch (e) {
      // ignore
    }
  }
}

final simpleSearchHistoryProvider =
    StateNotifierProvider<SimpleSearchHistory, List<String>>((ref) {
      ref.keepAlive();
      return SimpleSearchHistory();
    });
