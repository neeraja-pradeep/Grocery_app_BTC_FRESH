import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/features/category/application/providers/category_providers.dart';
import 'package:grocery_app/features/category/domain/entities/category.dart';
import 'package:grocery_app/features/category/domain/repositories/category_repository.dart';
import 'package:grocery_app/features/category/infrastructure/providers/category_infrastructure_providers.dart';

Category _category(int id) => Category(id: '$id', title: 'Category $id');

class _FakeRepository implements CategoryRepository {
  _FakeRepository({required this.cached, required this.remote});

  /// What local storage holds, or null for a cold cache.
  final CategoryRepositoryResult? cached;

  /// What the server would return.
  final List<Category> remote;

  int syncCallCount = 0;
  final List<bool> forceRemoteFlags = [];

  @override
  Duration get cacheTtl => const Duration(hours: 1);

  @override
  Future<CategoryRepositoryResult?> getCachedCategories() async => cached;

  @override
  Future<CategoryRepositoryResult> syncCategories({
    bool forceRemote = false,
  }) async {
    syncCallCount++;
    forceRemoteFlags.add(forceRemote);
    return CategoryRepositoryResult(
      categories: remote,
      isFromCache: false,
      lastSyncedAt: DateTime.now(),
      isStale: false,
      totalCount: remote.length,
    );
  }
}

ProviderContainer _containerWith(_FakeRepository repo) {
  final container = ProviderContainer(
    overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('CategoryController stale-cache refresh', () {
    test('a stale cache triggers a sync (regression: it silently did not)',
        () async {
      // The exact production shape: cached data exists but is stale — either
      // past its TTL or written before pagination was followed.
      final repo = _FakeRepository(
        cached: CategoryRepositoryResult(
          categories: [_category(1), _category(4)],
          isFromCache: true,
          lastSyncedAt: DateTime.now().subtract(const Duration(hours: 5)),
          isStale: true,
          totalCount: 40,
        ),
        remote: [for (var i = 1; i <= 40; i++) _category(i)],
      );

      final container = _containerWith(repo);
      container.read(categoryControllerProvider);

      // Let the build()-scheduled microtask and the async sync settle.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        repo.syncCallCount,
        greaterThan(0),
        reason: 'a stale cache must actually hit the network',
      );
      final state = container.read(categoryControllerProvider);
      expect(
        state.categories.length,
        40,
        reason: 'the refreshed list must replace the stale two',
      );
      expect(
        state.isRefreshing,
        isFalse,
        reason: 'must not be left stuck refreshing, which blocked all retries',
      );
    });

    test('a fresh cache is used without hitting the network', () async {
      final repo = _FakeRepository(
        cached: CategoryRepositoryResult(
          categories: [for (var i = 1; i <= 40; i++) _category(i)],
          isFromCache: true,
          lastSyncedAt: DateTime.now(),
          isStale: false,
          totalCount: 40,
        ),
        remote: const [],
      );

      final container = _containerWith(repo);
      container.read(categoryControllerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.syncCallCount, 0, reason: 'fresh cache needs no request');
      expect(container.read(categoryControllerProvider).categories.length, 40);
    });

    test('a cold cache forces a remote fetch', () async {
      final repo = _FakeRepository(
        cached: null,
        remote: [for (var i = 1; i <= 40; i++) _category(i)],
      );

      final container = _containerWith(repo);
      container.read(categoryControllerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.syncCallCount, 1);
      expect(repo.forceRemoteFlags.single, isTrue);
      expect(container.read(categoryControllerProvider).categories.length, 40);
    });

    test('refresh still works after the initial stale-cache sync', () async {
      // The old bug left isRefreshing stuck true, which blocked every
      // subsequent refresh for the life of the app.
      final repo = _FakeRepository(
        cached: CategoryRepositoryResult(
          categories: [_category(1)],
          isFromCache: true,
          lastSyncedAt: DateTime.now().subtract(const Duration(hours: 5)),
          isStale: true,
          totalCount: 40,
        ),
        remote: [for (var i = 1; i <= 40; i++) _category(i)],
      );

      final container = _containerWith(repo);
      container.read(categoryControllerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final afterInitial = repo.syncCallCount;
      await container.read(categoryControllerProvider.notifier).refresh();

      expect(
        repo.syncCallCount,
        greaterThan(afterInitial),
        reason: 'later refreshes must not be blocked by a stuck flag',
      );
    });
  });
}
