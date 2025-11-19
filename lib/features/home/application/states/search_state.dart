// lib/features/home/application/states/search_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:new_app/core/error/failure.dart';
import 'package:new_app/features/home/domain/entities/product_variant.dart';

part 'search_state.freezed.dart';

@freezed
sealed class SearchState with _$SearchState {
  // Idle state
  const factory SearchState.initial() = SearchInitial;

  // Voice search listening active
  const factory SearchState.listening({required bool isVoiceSearch}) =
      SearchListening;

  // Executing search (network request)
  const factory SearchState.loading({
    required String query,
    required bool isVoiceSearch,
  }) = SearchLoading;

  // Results available
  const factory SearchState.loaded({
    required String query,
    required List<ProductVariant> results,
    @Default(false) bool hasMore,
    @Default(1) int currentPage,
  }) = SearchLoaded;

  // No results found
  const factory SearchState.empty({required String query}) = SearchEmpty;

  // Error occurred
  const factory SearchState.error({
    required Failure failure,
    required String query,
  }) = SearchError;
}
