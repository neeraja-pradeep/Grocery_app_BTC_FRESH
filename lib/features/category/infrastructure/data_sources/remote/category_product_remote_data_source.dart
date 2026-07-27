import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../../../../../core/network/pagination.dart';
import '../../../../../core/utils/concurrency_limiter.dart';

import '../../models/category_product_dto.dart';

class CategoryProductRemoteResponse {
  const CategoryProductRemoteResponse({
    required this.products,
    required this.fetchedAt,
    this.eTag,
    this.lastModified,
    this.count,
    this.next,
    this.previous,
  });

  final List<CategoryProductDto> products;
  final DateTime fetchedAt;
  final String? eTag;
  final String? lastModified;
  final int? count;
  final String? next;
  final String? previous;
}

class CategoryProductRemoteDataSource {
  CategoryProductRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// Caps how many category-product requests are in flight at once.
  ///
  /// The Categories screen watches one provider per category, so without this
  /// every category fetches simultaneously the moment the tab opens (and again
  /// on every poll tick). Static so the cap is shared across all instances.
  static final ConcurrencyLimiter _limiter = ConcurrencyLimiter(4);

  Future<CategoryProductRemoteResponse?> fetchProducts(
    String categoryId, {
    String? ifNoneMatch,
    String? ifModifiedSince,
  }) async {
    return _fetchAllPages(
      ApiEndpoints.categoryProducts(categoryId),
      categoryId: categoryId,
      ifNoneMatch: ifNoneMatch,
      ifModifiedSince: ifModifiedSince,
    );
  }

  /// Fetches the discount-only variant of the category products endpoint.
  /// No conditional-request headers — Price Drop is a transient filter view
  /// the repository does not cache.
  Future<CategoryProductRemoteResponse?> fetchDiscountedProducts(
    String categoryId,
  ) {
    return _fetchAllPages(
      ApiEndpoints.categoryDiscountedProducts(categoryId),
      categoryId: categoryId,
      onlyDiscountedVariants: true,
    );
  }

  /// Fetches every page of [path], following pagination to the last page.
  ///
  /// The products endpoint paginates at a fixed 25 per page, so a category
  /// with more than 25 products silently lost the remainder when only the
  /// first page was read.
  ///
  /// Conditional headers go on page 1 only; a 304 there short-circuits the
  /// whole walk. A failure on a later page propagates rather than caching a
  /// partial list — see [CategoryRemoteDataSource.fetchCategories].
  ///
  /// Note each page passes through [_limiter] independently, so a multi-page
  /// category does not hold a concurrency slot while it walks.
  Future<CategoryProductRemoteResponse?> _fetchAllPages(
    String path, {
    required String categoryId,
    String? ifNoneMatch,
    String? ifModifiedSince,
    bool onlyDiscountedVariants = false,
  }) async {
    final first = await _fetch(
      path,
      categoryId: categoryId,
      ifNoneMatch: ifNoneMatch,
      ifModifiedSince: ifModifiedSince,
      onlyDiscountedVariants: onlyDiscountedVariants,
    );

    // 304 Not Modified — nothing changed, skip the remaining pages.
    if (first == null) return null;

    final products = <CategoryProductDto>[...first.products];
    var hasNext = first.next != null;

    for (var page = 2; hasNext && page <= kMaxPagesPerFetch; page++) {
      final next = await _fetch(
        path,
        categoryId: categoryId,
        page: page,
        onlyDiscountedVariants: onlyDiscountedVariants,
      );
      if (next == null) break;
      products.addAll(next.products);
      hasNext = next.next != null;
    }

    return CategoryProductRemoteResponse(
      products: products,
      fetchedAt: first.fetchedAt,
      // Validators come from page 1 — that is the request the next conditional
      // sync will replay them against.
      eTag: first.eTag,
      lastModified: first.lastModified,
      count: first.count,
      // Fully drained, so there is nothing left to follow.
      next: null,
      previous: null,
    );
  }

  /// Fetches a single page. [page] null means page 1 (no explicit param).
  Future<CategoryProductRemoteResponse?> _fetch(
    String path, {
    required String categoryId,
    int? page,
    String? ifNoneMatch,
    String? ifModifiedSince,
    bool onlyDiscountedVariants = false,
  }) async {
    try {
      final response = await _limiter.run(
        () => _apiClient.get<dynamic>(
          path,
          // `path` already carries a query string, so Dio appends this with
          // `&`. Page 1 sends no page param at all, matching the original URL.
          queryParameters: page == null
              ? null
              : <String, dynamic>{'page': page},
          headers: <String, String>{
            if (ifNoneMatch != null) 'If-None-Match': ifNoneMatch,
            if (ifModifiedSince != null) 'If-Modified-Since': ifModifiedSince,
          },
        ),
      );

      final status = response.statusCode ?? 200;
      if (status == 304) {
        return null;
      }

      final payload = response.data;
      Map<String, dynamic>? payloadMap;
      if (payload is Map<String, dynamic>) {
        payloadMap = payload;
      } else if (payload is Map) {
        payloadMap = Map<String, dynamic>.from(payload);
      }

      final products = CategoryProductDto.listFromJson(
        payload,
        filterCategoryId: categoryId,
        onlyDiscountedVariants: onlyDiscountedVariants,
      );
      final headers = response.headers;
      final eTag = headers.value('etag') ?? headers.value('ETag');
      final lastModified =
          headers.value('last-modified') ?? headers.value('Last-Modified');

      return CategoryProductRemoteResponse(
        products: products,
        fetchedAt: DateTime.now(),
        eTag: eTag,
        lastModified: lastModified,
        count: payloadMap?['count'] as int?,
        next: payloadMap?['next'] as String?,
        previous: payloadMap?['previous'] as String?,
      );
    } on NetworkException catch (error) {
      if (error.statusCode == 304) {
        return null;
      }
      rethrow;
    } on DioException catch (error) {
      throw NetworkException.fromDio(error);
    } on FormatException catch (error) {
      throw NetworkException(message: error.message);
    }
  }
}
