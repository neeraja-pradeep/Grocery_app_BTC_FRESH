import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/features/home/application/providers/search_history_provider.dart';
import 'package:grocery_app/features/home/application/states/search_history_state.dart';

void main() {
  group('SearchHistoryProvider', () {
    test('should start with initial state', () {
      final container = ProviderContainer();
      final state = container.read(searchHistoryProvider);

      expect(state, isA<SearchHistoryInitial>());

      container.dispose();
    });

    test('should provide empty list initially', () {
      final container = ProviderContainer();
      final searches = container.read(recentSearchesProvider);

      expect(searches, isEmpty);

      container.dispose();
    });
  });
}
