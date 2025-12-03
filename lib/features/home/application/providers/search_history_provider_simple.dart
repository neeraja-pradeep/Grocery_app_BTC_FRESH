// Simple in-memory version for testing
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SimpleSearchHistoryNotifier extends StateNotifier<List<String>> {
  SimpleSearchHistoryNotifier() : super([]);

  void addSearch(String query) {
    if (query.trim().isEmpty) return;

    final currentList = List<String>.from(state);

    // Remove if exists
    currentList.remove(query.trim());

    // Add to beginning
    currentList.insert(0, query.trim());

    // Keep max 10
    if (currentList.length > 10) {
      currentList.removeRange(10, currentList.length);
    }

    state = currentList;
    // print("Updated search history: $state");
  }

  void removeSearch(String query) {
    final currentList = List<String>.from(state);
    currentList.remove(query);
    state = currentList;
  }

  void clearHistory() {
    state = [];
  }
}

final simpleSearchHistoryProvider =
    StateNotifierProvider<SimpleSearchHistoryNotifier, List<String>>((ref) {
      return SimpleSearchHistoryNotifier();
    });
