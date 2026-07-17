import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../../models/frequently_bought_dto.dart';

/// Log tag used for every debug line emitted by this data source. Grep
/// `FrequentlyBought` in the `flutter run` output to isolate just these logs.
const String _kLogTag = 'FrequentlyBought';

abstract class FrequentlyBoughtRemoteDataSource {
  Future<FrequentlyBoughtResponseDto> fetch();
}

class FrequentlyBoughtRemoteDataSourceImpl
    implements FrequentlyBoughtRemoteDataSource {
  FrequentlyBoughtRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<FrequentlyBoughtResponseDto> fetch() async {
    // Query params chosen to match the contract supplied by backend:
    //   ?since=90&include_unavailable=false
    final queryParams = <String, dynamic>{
      'since': 90,
      'include_unavailable': false,
    };

    developer.log(
      'GET ${ApiEndpoints.frequentlyBought} query=$queryParams',
      name: _kLogTag,
    );

    try {
      final response = await _apiClient.get(
        ApiEndpoints.frequentlyBought,
        queryParameters: queryParams,
      );

      developer.log(
        'HTTP ${response.statusCode} bodyType=${response.data?.runtimeType}',
        name: _kLogTag,
      );
      // Full raw body — verbose, but invaluable for diagnosing parsing issues.
      developer.log(
        'raw response: ${response.data}',
        name: _kLogTag,
      );

      final data = response.data;
      if (data is! Map) {
        developer.log(
          'response is not a JSON object — aborting parse',
          name: _kLogTag,
        );
        throw const FormatException(
          'frequently-bought response is not a JSON object',
        );
      }

      final dto = FrequentlyBoughtResponseDto.fromJson(
        Map<String, dynamic>.from(data),
      );

      developer.log(
        'parsed ${dto.results.length} items '
        '(count=${dto.count}, hasNext=${dto.next != null})',
        name: _kLogTag,
      );

      return dto;
    } on DioException catch (e) {
      developer.log(
        'DioException: status=${e.response?.statusCode} message=${e.message}',
        name: _kLogTag,
        error: e,
      );
      throw NetworkException.fromDio(e);
    } catch (e, st) {
      developer.log(
        'parse / unexpected error',
        name: _kLogTag,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}

final frequentlyBoughtRemoteDataSourceProvider =
    Provider<FrequentlyBoughtRemoteDataSource>((ref) {
      return FrequentlyBoughtRemoteDataSourceImpl(
        ref.watch(apiClientProvider),
      );
    });
