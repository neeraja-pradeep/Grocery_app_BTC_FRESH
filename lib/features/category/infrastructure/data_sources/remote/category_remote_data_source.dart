import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../../../../../core/network/pagination.dart';

import '../../models/category_dto.dart';

class CategoryRemoteResponse {
  const CategoryRemoteResponse({
    required this.categories,
    required this.fetchedAt,
    this.eTag,
    this.lastModified,
    this.count,
    this.next,
    this.previous,
  });

  final List<CategoryDto> categories;
  final DateTime fetchedAt;
  final String? eTag;
  final String? lastModified;
  final int? count;
  final String? next;
  final String? previous;
}

class CategoryRemoteDataSource {
  CategoryRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches the full category list, following pagination to the last page.
  ///
  /// The endpoint paginates at a fixed 25 per page (`page_size` and friends are
  /// ignored by the server), so a single request returns only the first 25 of
  /// the 40 categories. This walks `?page=2`, `?page=3`, ... until `next` is
  /// null and returns every category as one list.
  ///
  /// Conditional-request headers are sent on page 1 only. A 304 there means the
  /// collection is unchanged, so the remaining pages are not requested and null
  /// is returned — the caller keeps using its cache.
  ///
  /// If a later page fails the error propagates: caching a partial list would
  /// look like a complete one and silently hide categories, which is the exact
  /// failure being fixed here. The controller's retry/backoff handles it and
  /// the previous cache stays intact.
  Future<CategoryRemoteResponse?> fetchCategories({
    String? ifNoneMatch,
    String? ifModifiedSince,
  }) async {
    final first = await _fetchPage(
      ifNoneMatch: ifNoneMatch,
      ifModifiedSince: ifModifiedSince,
    );

    // 304 Not Modified — nothing changed, skip the remaining pages.
    if (first == null) return null;

    final categories = <CategoryDto>[...first.categories];
    var hasNext = first.next != null;

    for (var page = 2; hasNext && page <= kMaxPagesPerFetch; page++) {
      final next = await _fetchPage(page: page);
      if (next == null) break;
      categories.addAll(next.categories);
      hasNext = next.next != null;
    }

    return CategoryRemoteResponse(
      categories: categories,
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
  Future<CategoryRemoteResponse?> _fetchPage({
    int? page,
    String? ifNoneMatch,
    String? ifModifiedSince,
  }) async {
    try {
      final response = await _apiClient.get<dynamic>(
        ApiEndpoints.categories,
        queryParameters: page == null ? null : <String, dynamic>{'page': page},
        headers: <String, String>{
          if (ifNoneMatch != null) 'If-None-Match': ifNoneMatch,
          if (ifModifiedSince != null) 'If-Modified-Since': ifModifiedSince,
        },
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

      final categories = CategoryDto.listFromJson(payload);
      final headers = response.headers;
      final eTag = headers.value('etag') ?? headers.value('ETag');
      final lastModified =
          headers.value('last-modified') ?? headers.value('Last-Modified');

      return CategoryRemoteResponse(
        categories: categories,
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
