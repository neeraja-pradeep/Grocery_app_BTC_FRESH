import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/storage/hive/boxes.dart';
import '../../domain/repositories/category_repository.dart';
import '../../infrastructure/data_sources/local/category_local_data_source.dart';
import '../../infrastructure/data_sources/remote/category_remote_data_source.dart';
import '../../infrastructure/repositories/category_repository_impl.dart';
import '../states/category_state.dart';

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((
  ref,
) {
  final box = Hive.box<dynamic>(AppHiveBoxes.cache);
  return CategoryLocalDataSource(box);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localDataSource = ref.watch(categoryLocalDataSourceProvider);
  final remoteDataSource = CategoryRemoteDataSource(apiClient);

  return CategoryRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

final categoryControllerProvider =
    NotifierProvider<CategoryController, CategoryState>(CategoryController.new);

class CategoryController extends Notifier<CategoryState> {
  static const Duration _pollingInterval = Duration(seconds: 30);

  CategoryRepository get _repository => ref.read(categoryRepositoryProvider);

  bool _initialized = false;
  DateTime? _lastRefreshAttempt;
  Timer? _pollingTimer;
  Timer? _indicatorTimer;

  @override
  CategoryState build() {
    if (!_initialized) {
      _initialized = true;
      Future<void>.microtask(_loadInitial);
      _startPolling();
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
        refreshStartedAt: cached.isStale
            ? DateTime.now()
            : state.refreshStartedAt,
        refreshEndedAt: cached.isStale ? null : DateTime.now(),
        resetRefreshEndedAt: cached.isStale,
        totalCount: cached.totalCount,
        next: cached.next,
        previous: cached.previous,
        clearError: true,
      );
      _scheduleIndicatorReset();
    } else {
      state = state.copyWith(
        status: CategoryStatus.loading,
        isRefreshing: true,
        refreshStartedAt: DateTime.now(),
        resetRefreshEndedAt: true,
        clearError: true,
      );
      _scheduleIndicatorReset();
    }

    final shouldRefresh = cached == null || cached.isStale;
    if (shouldRefresh) {
      await _refreshInternal(forceRemote: cached == null);
    } else {
      state = state.copyWith(isRefreshing: false, resetRefreshStartedAt: true);
    }
  }

  Future<void> refresh({bool force = false}) async {
    await _refreshInternal(forceRemote: force);
  }

  Future<void> refreshIfStale() async {
    final lastSyncedAt = state.lastSyncedAt;
    final now = DateTime.now();

    final recentlyRequested =
        _lastRefreshAttempt != null &&
        now.difference(_lastRefreshAttempt!) < _pollingInterval;
    if (recentlyRequested) return;

    if (lastSyncedAt == null ||
        now.difference(lastSyncedAt) >= _repository.cacheTtl) {
      _lastRefreshAttempt = now;
      await refresh();
    }
  }

  Future<void> _refreshInternal({required bool forceRemote}) async {
    if (state.isRefreshing && !forceRemote) return;

    final hasData = state.hasData;
    state = state.copyWith(
      status: hasData ? CategoryStatus.data : CategoryStatus.loading,
      isRefreshing: true,
      refreshStartedAt: DateTime.now(),
      resetRefreshEndedAt: true,
      clearError: true,
    );
    _scheduleIndicatorReset();

    try {
      final result = await _repository.syncCategories(forceRemote: forceRemote);

      state = state.copyWith(
        status: result.hasData ? CategoryStatus.data : CategoryStatus.empty,
        categories: result.categories,
        lastSyncedAt: result.lastSyncedAt,
        lastModified: result.lastModified,
        isRefreshing: false,
        resetRefreshStartedAt: true,
        refreshEndedAt: DateTime.now(),
        resetRefreshEndedAt: false,
        totalCount: result.totalCount,
        next: result.next,
        previous: result.previous,
        clearError: true,
      );
      _scheduleIndicatorReset();
      _lastRefreshAttempt = DateTime.now();
    } catch (error) {
      final message = _mapError(error);

      if (!hasData) {
        state = state.copyWith(
          status: CategoryStatus.error,
          isRefreshing: false,
          resetRefreshStartedAt: true,
          refreshEndedAt: DateTime.now(),
          resetRefreshEndedAt: false,
          errorMessage: message,
        );
      } else {
        state = state.copyWith(
          isRefreshing: false,
          resetRefreshStartedAt: true,
          refreshEndedAt: DateTime.now(),
          resetRefreshEndedAt: false,
          errorMessage: message,
        );
      }
      _scheduleIndicatorReset();
    }
  }

  String _mapError(Object error) {
    if (error is NetworkException) {
      return error.message;
    }
    if (error is FormatException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }

  void _startPolling() {
    _pollingTimer ??= Timer.periodic(_pollingInterval, (_) {
      if (state.isRefreshing) return;
      if (!state.hasData && state.status == CategoryStatus.loading) return;
      unawaited(refresh());
    });
  }

  void _scheduleIndicatorReset() {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 1500), () {
      state = state.copyWith(
        resetRefreshStartedAt: true,
        resetRefreshEndedAt: true,
      );
    });
  }

  void _disposeController() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _indicatorTimer?.cancel();
    _indicatorTimer = null;
    _initialized = false;
    _lastRefreshAttempt = null;
  }
}
