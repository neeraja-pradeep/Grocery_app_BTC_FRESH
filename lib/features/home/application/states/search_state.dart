// application/states/search_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
// NOTE: Assuming new_app path for entities based on previous chat.
import 'package:new_app/features/home/domain/entities/product.dart';
part 'search_state.freezed.dart';

/// Manages the state related to the product search functionality.
@freezed
class SearchState with _$SearchState {
  const factory SearchState({
    @Default('') String query,
    @Default(false) bool isSearching,
    @Default([]) List<Product> results,
    // The list of recently searched terms retrieved from the repository/local source.
    @Default([]) List<String> history,
    String? error,
  }) = _SearchState;
}
