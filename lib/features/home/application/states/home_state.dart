// application/states/home_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
part 'home_state.freezed.dart';

/// Represents the top-level state of the Home Screen module's bootstrap process.
@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    // Global loader for the first paint/initial data load.
    @Default(true) bool isInitialLoading,
    // General error message for global failures.
    String? error,
    // Indicates that the first successful load (from cache or remote) is complete.
    @Default(false) bool isBootComplete,
  }) = _HomeState;
}
