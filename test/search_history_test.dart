import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/features/home/application/providers/simple_search_history.dart';

void main() {
  group('SimpleSearchHistory', () {
    test('should start with an empty history', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(simpleSearchHistoryProvider), isEmpty);
    });
  });
}
