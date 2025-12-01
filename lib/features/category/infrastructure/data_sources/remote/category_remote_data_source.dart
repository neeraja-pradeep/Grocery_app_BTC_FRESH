import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../../../core/network/network_exceptions.dart';

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

  Future<CategoryRemoteResponse?> fetchCategories({
    String? ifNoneMatch,
    String? ifModifiedSince,
  }) async {
    try {
      final response = await _apiClient.get<dynamic>(
        ApiEndpoints.categories,
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
