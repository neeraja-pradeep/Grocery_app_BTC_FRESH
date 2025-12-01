// lib/features/home/application/states/search_history_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_history_state.freezed.dart';

@freezed
sealed class SearchHistoryState with _$SearchHistoryState {
  // Initial state with empty history
  const factory SearchHistoryState.initial() = SearchHistoryInitial;

  // Loaded state with search history
  const factory SearchHistoryState.loaded({required List<String> searches}) =
      SearchHistoryLoaded;

  // Error state
  const factory SearchHistoryState.error({required String message}) =
      SearchHistoryError;
}
