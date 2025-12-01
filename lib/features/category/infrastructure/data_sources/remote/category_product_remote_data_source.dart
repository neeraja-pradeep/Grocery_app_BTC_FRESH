import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../../../core/network/network_exceptions.dart';

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

  Future<CategoryProductRemoteResponse?> fetchProducts(
    String categoryId, {
    String? ifNoneMatch,
    String? ifModifiedSince,
  }) async {
    try {
      final response = await _apiClient.get<dynamic>(
        ApiEndpoints.categoryProducts(categoryId),
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

      final products = CategoryProductDto.listFromJson(
        payload,
        filterCategoryId: categoryId,
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
