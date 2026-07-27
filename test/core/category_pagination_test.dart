import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/core/network/api_client.dart';
import 'package:grocery_app/core/storage/cache_schema.dart';
import 'package:grocery_app/core/storage/hive/boxes.dart';
import 'package:grocery_app/features/category/infrastructure/data_sources/local/category_local_data_source.dart';
import 'package:grocery_app/features/category/infrastructure/data_sources/remote/category_product_remote_data_source.dart';
import 'package:grocery_app/features/category/infrastructure/data_sources/remote/category_remote_data_source.dart';
import 'package:grocery_app/features/category/infrastructure/repositories/category_repository_impl.dart';
import 'package:hive_ce/hive.dart';

/// Serves canned responses and records every request it received, so the tests
/// can assert on the exact URLs and headers the data sources produce.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  /// Maps a request to (statusCode, jsonBody).
  final (int, Map<String, dynamic>?) Function(RequestOptions options) handler;

  final List<RequestOptions> requests = [];

  List<String> get requestedUris =>
      requests.map((r) => r.uri.toString()).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'etag': ['"page1-etag"'],
        'last-modified': ['Wed, 01 Jan 2025 00:00:00 GMT'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Builds an [ApiClient] backed by [adapter], skipping `init()` (which needs
/// path_provider for the cookie jar and is irrelevant here).
ApiClient _apiClientWith(_FakeAdapter adapter) {
  final client = ApiClient();
  client.dio = Dio(BaseOptions(baseUrl: 'https://api.test/'))
    ..httpClientAdapter = adapter;
  return client;
}

Map<String, dynamic> _categoryPage({
  required int from,
  required int count,
  required int total,
  String? next,
}) => {
  'count': total,
  'next': next,
  'previous': null,
  'results': [
    for (var i = from; i < from + count; i++)
      {'id': i, 'name': 'Category $i'},
  ],
};

Map<String, dynamic> _productPage({
  required int from,
  required int count,
  required int total,
  required String categoryId,
  String? next,
  // The discounted view keeps only variants with a positive `discounted_price`,
  // so fixtures for that path must carry one.
  bool discounted = false,
}) => {
  'count': total,
  'next': next,
  'previous': null,
  'results': [
    for (var i = from; i < from + count; i++)
      {
        'id': i,
        'name': 'Product $i',
        'category_id': int.parse(categoryId),
        'variants': [
          {
            'id': i * 100,
            'name': 'Variant $i',
            'price': '10.00',
            if (discounted) 'discounted_price': '7.50',
          },
        ],
      },
  ],
};

/// Extracts the `page` query param, or null for page 1.
String? _pageOf(RequestOptions o) => o.uri.queryParameters['page'];

void main() {
  group('CategoryRemoteDataSource pagination', () {
    test('follows `next` and returns every category across pages', () async {
      // Mirrors production: 40 categories, fixed page size of 25.
      final adapter = _FakeAdapter((o) {
        switch (_pageOf(o)) {
          case null:
            return (
              200,
              _categoryPage(
                from: 1,
                count: 25,
                total: 40,
                next: 'https://api.test/api/products/v1/category/?page=2',
              ),
            );
          case '2':
            return (200, _categoryPage(from: 26, count: 15, total: 40));
          default:
            return (404, null);
        }
      });

      final result = await CategoryRemoteDataSource(
        _apiClientWith(adapter),
      ).fetchCategories();

      expect(result, isNotNull);
      expect(
        result!.categories.length,
        40,
        reason: 'all 40 categories must be returned, not just page 1',
      );
      expect(result.categories.first.title, 'Category 1');
      expect(result.categories.last.title, 'Category 40');
      // Fully drained.
      expect(result.next, isNull);
      expect(adapter.requests.length, 2);
      expect(adapter.requestedUris[1], contains('page=2'));
    });

    test('sends conditional headers on page 1 only', () async {
      final adapter = _FakeAdapter((o) {
        switch (_pageOf(o)) {
          case null:
            return (
              200,
              _categoryPage(
                from: 1,
                count: 25,
                total: 40,
                next: 'https://api.test/api/products/v1/category/?page=2',
              ),
            );
          default:
            return (200, _categoryPage(from: 26, count: 15, total: 40));
        }
      });

      await CategoryRemoteDataSource(_apiClientWith(adapter)).fetchCategories(
        ifNoneMatch: '"abc"',
        ifModifiedSince: 'Wed, 01 Jan 2025 00:00:00 GMT',
      );

      expect(adapter.requests[0].headers['If-None-Match'], '"abc"');
      expect(
        adapter.requests[1].headers.containsKey('If-None-Match'),
        isFalse,
        reason: 'validators belong to page 1; later pages must fetch fresh',
      );
    });

    test('304 on page 1 short-circuits without fetching later pages', () async {
      final adapter = _FakeAdapter((_) => (304, null));

      final result = await CategoryRemoteDataSource(
        _apiClientWith(adapter),
      ).fetchCategories(ifNoneMatch: '"abc"');

      expect(result, isNull, reason: 'caller keeps using its cache');
      expect(adapter.requests.length, 1, reason: 'no page 2 request');
    });

    test('a failing later page propagates instead of caching a partial list',
        () async {
      final adapter = _FakeAdapter((o) {
        if (_pageOf(o) == null) {
          return (
            200,
            _categoryPage(
              from: 1,
              count: 25,
              total: 40,
              next: 'https://api.test/api/products/v1/category/?page=2',
            ),
          );
        }
        return (500, null);
      });

      await expectLater(
        CategoryRemoteDataSource(_apiClientWith(adapter)).fetchCategories(),
        throwsA(anything),
      );
    });

    test('a server that always returns `next` cannot loop forever', () async {
      // Pathological: every page claims another page follows.
      final adapter = _FakeAdapter(
        (_) => (
          200,
          _categoryPage(
            from: 1,
            count: 1,
            total: 999999,
            next: 'https://api.test/api/products/v1/category/?page=99',
          ),
        ),
      );

      final result = await CategoryRemoteDataSource(
        _apiClientWith(adapter),
      ).fetchCategories();

      expect(result, isNotNull);
      // Bounded by kMaxPagesPerFetch (100).
      expect(adapter.requests.length, lessThanOrEqualTo(100));
    });
  });

  group('CategoryProductRemoteDataSource pagination', () {
    test('follows `next` for a category with more than one page', () async {
      // Mirrors production category 49 (VEGITABLES): 46 products, 25 per page.
      final adapter = _FakeAdapter((o) {
        switch (_pageOf(o)) {
          case null:
            return (
              200,
              _productPage(
                from: 1,
                count: 25,
                total: 46,
                categoryId: '49',
                next: 'https://api.test/api/products/v1/?category_id=49&page=2',
              ),
            );
          case '2':
            return (
              200,
              _productPage(from: 26, count: 21, total: 46, categoryId: '49'),
            );
          default:
            return (404, null);
        }
      });

      final result = await CategoryProductRemoteDataSource(
        _apiClientWith(adapter),
      ).fetchProducts('49');

      expect(result, isNotNull);
      expect(
        result!.products.length,
        46,
        reason: 'all 46 products, not the first 25',
      );
      expect(result.next, isNull);
      expect(adapter.requests.length, 2);
    });

    test('appends page with & when the path already has a query string',
        () async {
      final adapter = _FakeAdapter((o) {
        if (_pageOf(o) == null) {
          return (
            200,
            _productPage(
              from: 1,
              count: 25,
              total: 30,
              categoryId: '49',
              next: 'https://api.test/api/products/v1/?category_id=49&page=2',
            ),
          );
        }
        return (
          200,
          _productPage(from: 26, count: 5, total: 30, categoryId: '49'),
        );
      });

      await CategoryProductRemoteDataSource(
        _apiClientWith(adapter),
      ).fetchProducts('49');

      final page2 = adapter.requests[1].uri;
      expect(page2.queryParameters['category_id'], '49');
      expect(page2.queryParameters['page'], '2');
    });

    test('single-page categories still issue exactly one request', () async {
      final adapter = _FakeAdapter(
        (_) => (200, _productPage(from: 1, count: 5, total: 5, categoryId: '7')),
      );

      final result = await CategoryProductRemoteDataSource(
        _apiClientWith(adapter),
      ).fetchProducts('7');

      expect(result!.products.length, 5);
      expect(adapter.requests.length, 1, reason: 'no wasted extra request');
    });

    test('discounted (Price Drop) variant paginates too', () async {
      final adapter = _FakeAdapter((o) {
        expect(o.uri.queryParameters['is_discounted'], 'true');
        if (_pageOf(o) == null) {
          return (
            200,
            _productPage(
              from: 1,
              count: 25,
              total: 28,
              categoryId: '49',
              discounted: true,
              next: 'https://api.test/api/products/v1/?page=2',
            ),
          );
        }
        return (
          200,
          _productPage(
            from: 26,
            count: 3,
            total: 28,
            categoryId: '49',
            discounted: true,
          ),
        );
      });

      final result = await CategoryProductRemoteDataSource(
        _apiClientWith(adapter),
      ).fetchDiscountedProducts('49');

      expect(result!.products.length, 28);
      expect(adapter.requests.length, 2);
    });
  });

  group('legacy cache migration (self-healing after upgrade)', () {
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      tempDir = await Directory.systemTemp.createTemp('btc_cache_test');
      Hive.init(tempDir.path);
      await Hive.openBox<dynamic>(Boxes.cache);
    });

    tearDownAll(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    setUp(() async => Hive.box<dynamic>(Boxes.cache).clear());

    /// Writes the shape the OLD (pre-pagination) build persisted: page 1 only,
    /// valid validators, and no `schemaVersion` key.
    Future<void> seedLegacyCache() async {
      await Hive.box<dynamic>(Boxes.cache).put('cat:list_meta', {
        'categories': [
          for (var i = 1; i <= 25; i++) {'id': '\$i', 'title': 'Category \$i'},
        ],
        'lastSyncedAt': DateTime.now().toIso8601String(),
        'eTag': '"stale-etag"',
        'lastModified': 'Wed, 01 Jan 2025 00:00:00 GMT',
        'count': 40,
        // NOTE: no schemaVersion — that is what marks it as legacy.
      });
    }

    CategoryRepositoryImpl repoWith(_FakeAdapter adapter) =>
        CategoryRepositoryImpl(
          localDataSource: CategoryLocalDataSource(),
          remoteDataSource: CategoryRemoteDataSource(_apiClientWith(adapter)),
        );

    test('a truncated legacy cache reads back as stale', () async {
      await seedLegacyCache();

      final cached = await repoWith(
        _FakeAdapter((_) => (200, null)),
      ).getCachedCategories();

      expect(cached!.categories.length, 25);
      expect(
        cached.isStale,
        isTrue,
        reason: 'fresh by age, but incomplete — must refresh immediately',
      );
    });

    test('sync drops validators for a legacy cache and refetches in full',
        () async {
      await seedLegacyCache();

      final adapter = _FakeAdapter((o) {
        // If the stale validators were replayed the server would 304 here and
        // the truncated list would stay pinned forever.
        expect(
          o.headers.containsKey('If-None-Match'),
          isFalse,
          reason: 'legacy cache must not be revalidated',
        );
        if (o.uri.queryParameters['page'] == null) {
          return (
            200,
            _categoryPage(
              from: 1,
              count: 25,
              total: 40,
              next: 'https://api.test/api/products/v1/category/?page=2',
            ),
          );
        }
        return (200, _categoryPage(from: 26, count: 15, total: 40));
      });

      final result = await repoWith(adapter).syncCategories();

      expect(result.categories.length, 40);
      expect(adapter.requests.length, 2);
    });

    test('after migrating, the entry is v2 and validators resume', () async {
      await seedLegacyCache();

      final adapter = _FakeAdapter((o) {
        if (o.uri.queryParameters['page'] == null) {
          return (
            200,
            _categoryPage(
              from: 1,
              count: 25,
              total: 40,
              next: 'https://api.test/api/products/v1/category/?page=2',
            ),
          );
        }
        return (200, _categoryPage(from: 26, count: 15, total: 40));
      });
      final repo = repoWith(adapter);
      await repo.syncCategories();

      // Stored entry is now marked current.
      final stored = Hive.box<dynamic>(Boxes.cache).get('cat:list_meta') as Map;
      expect(stored['schemaVersion'], CacheSchema.categoryList);

      // A second sync should now revalidate normally rather than force a
      // full refetch every time.
      var sentValidator = false;
      final adapter2 = _FakeAdapter((o) {
        if (o.headers.containsKey('If-None-Match')) sentValidator = true;
        return (304, null);
      });
      await repoWith(adapter2).syncCategories();

      expect(sentValidator, isTrue, reason: 'migrated cache revalidates again');
    });
  });
}
