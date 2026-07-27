import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/core/network/api_client.dart';
import 'package:grocery_app/features/home/infrastructure/data_sources/remote/home_api.dart';

/// Serves canned pages and records the requests that produced them.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final (int, Map<String, dynamic>?) Function(RequestOptions options) handler;

  final List<RequestOptions> requests = [];

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
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

HomeApiImpl _apiWith(_FakeAdapter adapter) {
  final client = ApiClient();
  client.dio = Dio(BaseOptions(baseUrl: 'https://api.test/'))
    ..httpClientAdapter = adapter;
  return HomeApiImpl(client);
}

int? _pageOf(RequestOptions o) =>
    int.tryParse(o.uri.queryParameters['page'] ?? '');

Map<String, dynamic> _envelope({
  required List<Map<String, dynamic>> results,
  required int total,
  String? next,
}) => {
  'count': total,
  'next': next,
  'previous': null,
  'results': results,
};

List<Map<String, dynamic>> _categories(int from, int count) => [
  for (var i = from; i < from + count; i++)
    {'id': i, 'name': 'Category $i', 'slug': 'cat-$i'},
];

List<Map<String, dynamic>> _discountedProducts(int from, int count) => [
  for (var i = from; i < from + count; i++)
    {
      'id': i,
      'name': 'Product $i',
      'category_id': 1,
      'variants': [
        {
          'id': i * 100,
          'price': '10.00',
          'discounted_price': '7.50',
          'in_stock': true,
        },
      ],
    },
];

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // AppConfig.convertToCdnUrl reads .env during media parsing; an empty
    // in-memory env is enough to keep dotenv from throwing.
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('HomeApiImpl.getCategories', () {
    test('returns every category across pages, not just the first 25', () async {
      // Mirrors production: 40 categories at a fixed page size of 25.
      final adapter = _FakeAdapter((o) {
        switch (_pageOf(o)) {
          case 1:
            return (
              200,
              _envelope(
                results: _categories(1, 25),
                total: 40,
                next: 'https://api.test/api/products/v1/category/?page=2',
              ),
            );
          case 2:
            return (200, _envelope(results: _categories(26, 15), total: 40));
          default:
            return (404, null);
        }
      });

      final result = await _apiWith(adapter).getCategories();

      expect(
        result.results.length,
        40,
        reason: 'the Home category grid must show the whole catalogue',
      );
      expect(result.results.first.name, 'Category 1');
      expect(result.results.last.name, 'Category 40');
      expect(result.next, isNull, reason: 'fully drained');
      expect(adapter.requests.length, 2);
    });

    test('stops after one request when there is no next page', () async {
      final adapter = _FakeAdapter(
        (_) => (200, _envelope(results: _categories(1, 5), total: 5)),
      );

      final result = await _apiWith(adapter).getCategories();

      expect(result.results.length, 5);
      expect(adapter.requests.length, 1, reason: 'no wasted extra request');
    });
  });

  group('HomeApiImpl.getDiscountedProducts', () {
    test('drains all pages so no discount section is dropped', () async {
      final adapter = _FakeAdapter((o) {
        expect(o.uri.queryParameters['is_discounted'], 'true');
        switch (_pageOf(o)) {
          case 1:
            return (
              200,
              _envelope(
                results: _discountedProducts(1, 25),
                total: 30,
                next: 'https://api.test/api/products/v1/?page=2',
              ),
            );
          case 2:
            return (
              200,
              _envelope(results: _discountedProducts(26, 5), total: 30),
            );
          default:
            return (404, null);
        }
      });

      final result = await _apiWith(adapter).getDiscountedProducts();

      expect(result.variants.length, 30);
      expect(result.productCategoryMap.length, 30);
      expect(adapter.requests.length, 2);
    });

    test('handles a bare list response without asking for a second page',
        () async {
      // Some endpoints return an array rather than a pagination envelope.
      // There is no `next` to follow, so this must resolve in one request
      // rather than looping to the page cap.
      final requests = <RequestOptions>[];
      final client = ApiClient();
      client.dio = Dio(BaseOptions(baseUrl: 'https://api.test/'))
        ..httpClientAdapter = _ListAdapter(_discountedProducts(1, 3), requests);

      final result = await HomeApiImpl(client).getDiscountedProducts();

      expect(result.variants.length, 3);
      expect(requests.length, 1, reason: 'no `next` to follow');
    });
  });
}

/// Returns a bare JSON array (no pagination envelope).
class _ListAdapter implements HttpClientAdapter {
  _ListAdapter(this.items, this.requests);

  final List<Map<String, dynamic>> items;
  final List<RequestOptions> requests;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(items),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
