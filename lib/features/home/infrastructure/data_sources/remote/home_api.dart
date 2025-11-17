// features/home/infrastructure/data_sources/remote/home_api.dart

// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:new_app/core/network/endpoints.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart'; // Import the package
import 'package:cookie_jar/cookie_jar.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/product.dart';
import 'package:new_app/features/home/domain/entities/offer.dart';

final cookieJar = CookieJar();

/// Riverpod provider for the Dio client instance configured with the base URL.
final dioProvider = riverpod.Provider<Dio>((riverpod.Ref ref) {
  final options = BaseOptions(
    baseUrl: Endpoints.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'dev': '2'},
  );

  final dio = Dio(options);

  // 2. Add the CookieManager Interceptor to Dio
  dio.interceptors.add(CookieManager(cookieJar));

  // 3. Call the instance method on the 'cookieJar' variable (the instance), NOT the CookieJar class.
  // This is the line that must be correct:
  cookieJar.saveFromResponse(Uri.parse(Endpoints.baseUrl), [
    Cookie('sessionid', 'test'),
  ]);

  return dio;
});

// ----------------------------------------------------------------------

/// The abstract contract for the remote Home data source.
abstract class HomeRemoteDataSource {
  /// Fetches the list of product categories.
  Future<List<Category>> categoriesApi();

  /// Fetches the list of best deal products.
  Future<List<Product>> bestDealsApi();

  /// Fetches the list of promotional mega offers.
  Future<List<Offer>> megaOffersApi();

  /// Searches for products using a query string [q].
  Future<List<Product>> searchApi(String q);
}

/// Concrete implementation of the [HomeRemoteDataSource] using Dio.
class HomeApiImpl implements HomeRemoteDataSource {
  final Dio _dio;

  HomeApiImpl(this._dio);

  /// Helper method to handle API calls, response validation, and parsing uniformly.
  /// MODIFIED to handle both List and Paginated Map responses.
  Future<List<T>> _fetchData<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    Response? response;
    try {
      // print('DEBUG: Attempting API Call to: ${Endpoints.baseUrl}$path');
      // print(
      //   'DEBUG: Request Options (Headers/Cookies): ${_dio.options.headers}',
      // );
      response = await _dio.get(path, queryParameters: queryParameters);

      // Check for a successful response (status code 200)
      if (response.statusCode == 200 && response.data != null) {
        // print('DEBUG: Response received successfully');
        // print('DEBUG: Response data type: ${response.data.runtimeType}');
        // print('DEBUG: Response data: ${response.data}');

        // Declare a dynamic list variable
        List responseList;

        if (response.data is List) {
          // Case 1: Direct List response (e.g., old endpoints)
          responseList = response.data as List;
          // print(
          //   'DEBUG: Processing direct list with ${responseList.length} items',
          // );
        } else if (response.data is Map &&
            (response.data as Map).containsKey('results')) {
          // Case 2: Paginated Map response (e.g., new category endpoint)
          responseList =
              (response.data as Map<String, dynamic>)['results'] as List;
          // print(
          //   'DEBUG: Processing paginated response with ${responseList.length} items',
          // );
        } else {
          // Handle unexpected non-list/non-paginated response structure
          throw Exception(
            'API response data is not in expected List or Paginated format.',
          );
        }

        if (responseList.isNotEmpty) {
          // print('DEBUG: First item structure: ${responseList.first}');
          if (responseList.first is Map) {
            final firstItem = responseList.first as Map<String, dynamic>;
            // print('DEBUG: First item keys and types:');
            firstItem.forEach((key, value) {
              // print('  $key: $value (${value.runtimeType})');
            });
          }
        }

        // Map the list of JSON objects to the desired model type
        return responseList
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList()
            .cast<T>();
      }

      // Handle non-200 responses that didn't throw a DioException
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Server responded with status: ${response.statusCode}',
      );
    } on DioException {
      // Log the error and rethrow the DioException for upper layers to handle
      // print('API Error on $path: ${e.message}');
      rethrow;
    } catch (e) {
      // Catch other parsing or unexpected errors (like type casting issues)
      // print('Unknown error on $path: $e');
      if (response != null) {
        // print('Response data was: ${response.data}');
        // print('Response data type: ${response.data.runtimeType}');
        if (response.data is List && (response.data as List).isNotEmpty) {
          final data = response.data as List;
          // print('First item: ${data.first}');
          // print('First item type: ${data.first.runtimeType}');
          if (data.first is Map) {
            final firstItem = data.first as Map<String, dynamic>;
            // print('First item keys and types:');
            firstItem.forEach((key, value) {
              // print('  $key: $value (${value.runtimeType})');
            });
          }
        }
      }
      throw Exception('JSON parsing error: $e');
    }
  }

  @override
  Future<List<Category>> categoriesApi() async {
    // New endpoint: /api/products/category/
    return _fetchData(HomeEndpoints.categories, fromJson: Category.fromJson);
  }

  @override
  Future<List<Product>> bestDealsApi() async {
    // Uses the shared discountedVariants endpoint with 'Best Deals' filters
    return _fetchData(
      HomeEndpoints.discountedVariants,
      queryParameters: {
        // Suggested filter: Sort by the highest discount first
        'ordering': '-discounted_price',
        // You might add other common filters here if they are always applied for 'Best Deals'
      },
      fromJson: Product.fromJson,
    );
  }

  @override
  Future<List<Offer>> megaOffersApi() async {
    // Uses the shared discountedVariants endpoint with 'Mega Offer' filters
    return _fetchData(
      HomeEndpoints.discountedVariants,
      queryParameters: {
        // Suggested filter: Sort by the highest discount first
        'ordering': '-discounted_price',
        // Suggested filter: Limit the price to find "Mega" offers (e.g., items under $100)
        'maxprice': 100,
      },
      fromJson: Offer.fromJson,
    );
  }

  @override
  Future<List<Product>> searchApi(String q) async {
    return _fetchData(
      HomeEndpoints.search,
      queryParameters: {'q': q},
      fromJson: Product.fromJson,
    );
  }
}

// --- Riverpod Provider for Dependency Injection ---

/// Provides the concrete implementation of the remote Home data source.
final homeRemoteDataSourceProvider = riverpod.Provider<HomeRemoteDataSource>((
  riverpod.Ref ref,
) {
  // Inject the shared Dio instance
  final dio = ref.watch(dioProvider);
  return HomeApiImpl(dio);
});
