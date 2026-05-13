import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../core/polling/polling_manager.dart';
import '../../domain/repositories/category_repository.dart';
import '../../infrastructure/providers/category_infrastructure_providers.dart';
import '../states/category_state.dart';

final categoryControllerProvider =
    NotifierProvider<CategoryController, CategoryState>(CategoryController.new);

class CategoryController extends Notifier<CategoryState> {
  CategoryRepository get _repository => ref.read(categoryRepositoryProvider);

  bool _initialized = false;

  @override
  CategoryState build() {
    if (!_initialized) {
      _initialized = true;
      Future<void>.microtask(_loadInitial);
    }
    ref.onDispose(_disposeController);
    return CategoryState.initial();
  }

  Future<void> _loadInitial() async {
    final cached = await _repository.getCachedCategories();

    if (cached != null) {
      state = state.copyWith(
        status: cached.hasData ? CategoryStatus.data : CategoryStatus.empty,
        categories: cached.categories,
        lastSyncedAt: cached.lastSyncedAt,
        lastModified: cached.lastModified,
        isRefreshing: cached.isStale,
        totalCount: cached.totalCount,
        next: cached.next,
        previous: cached.previous,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        status: CategoryStatus.loading,
        isRefreshing: true,
        clearError: true,
      );
    }

    final shouldRefresh = cached == null || cached.isStale;
    if (shouldRefresh) {
      await _refreshInternal(forceRemote: cached == null);
    } else {
      state = state.copyWith(isRefreshing: false);
    }
  }

  Future<void> refresh({bool force = false}) async {
    await _refreshInternal(forceRemote: force);
  }

  Future<void> refreshIfStale() async {
    final lastSyncedAt = state.lastSyncedAt;
    final now = DateTime.now();

    if (lastSyncedAt == null ||
        now.difference(lastSyncedAt) >= _repository.cacheTtl) {
      await refresh();
    }
  }

  Future<void> _refreshInternal({required bool forceRemote}) async {
    if (state.isRefreshing && !forceRemote) return;

    final hasData = state.hasData;
    state = state.copyWith(
      status: hasData ? CategoryStatus.data : CategoryStatus.loading,
      isRefreshing: true,
      clearError: true,
    );

    const retryDelays = [
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
    ];

    Object? lastError;
    for (var attempt = 0; attempt <= 3; attempt++) {
      try {
        final result =
            await _repository.syncCategories(forceRemote: forceRemote);

        state = state.copyWith(
          status: result.hasData ? CategoryStatus.data : CategoryStatus.empty,
          categories: result.categories,
          lastSyncedAt: result.lastSyncedAt,
          lastModified: result.lastModified,
          isRefreshing: false,
          totalCount: result.totalCount,
          next: result.next,
          previous: result.previous,
          clearError: true,
        );
        return;
      } catch (error) {
        lastError = error;
        // Don't retry on 4xx client errors
        if (error is NetworkException &&
            error.statusCode != null &&
            error.statusCode! >= 400 &&
            error.statusCode! < 500) {
          break;
        }
        if (attempt < 3) {
          await Future.delayed(retryDelays[attempt]);
        }
      }
    }

    final message = _mapError(lastError!);
    if (!hasData) {
      state = state.copyWith(
        status: CategoryStatus.error,
        isRefreshing: false,
        errorMessage: message,
      );
    } else {
      state = state.copyWith(isRefreshing: false, errorMessage: message);
    }
  }

  /// Called by the screen when it mounts to activate polling.
  void activatePolling() {
    final currentFeature = PollingManager.instance.activeFeature;
    if (currentFeature == null || currentFeature == 'category_products') {
      PollingManager.instance.setActiveFeature('category_products');
    }
  }

  String _mapError(Object error) {
    if (error is NetworkException) return error.message;
    if (error is FormatException) return error.message;
    return 'Something went wrong. Please try again.';
  }

  void _disposeController() {
    _initialized = false;
  }
}
