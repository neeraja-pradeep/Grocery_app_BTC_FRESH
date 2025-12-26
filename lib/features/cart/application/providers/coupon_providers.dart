import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/polling/polling_manager.dart';
import '../../../../core/storage/cache_config.dart';

import '../../domain/repositories/coupon_repository.dart';
import '../../infrastructure/data_sources/local/coupon_local_data_source.dart';
import '../../infrastructure/data_sources/remote/coupon_remote_data_source.dart';
import '../../infrastructure/repositories/coupon_repository_impl.dart';
import '../states/coupon_state.dart';

/// Local data source provider
final couponLocalDataSourceProvider = Provider<CouponLocalDataSource>((ref) {
  return CouponLocalDataSourceImpl();
});

/// Remote data source provider
final couponRemoteDataSourceProvider = Provider<CouponRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CouponRemoteDataSourceImpl(apiClient);
});

/// Repository provider
final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  final localDataSource = ref.watch(couponLocalDataSourceProvider);
  final remoteDataSource = ref.watch(couponRemoteDataSourceProvider);

  return CouponRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    cacheTTL: const Duration(minutes: 10),
  );
});

/// Coupon list controller - manages coupon list state with 30-second polling
class CouponController extends Notifier<CouponState> {
  // Use global polling interval from CacheConfig - same 30 seconds as product_details
  static const Duration _pollingInterval = CacheConfig.pollingInterval;

  late CouponRepository _repository;
  bool _initialized = false;
  Timer? _pollingTimer;
  Timer? _indicatorTimer;

  @override
  CouponState build() {
    final repository = ref.watch(couponRepositoryProvider);
    _repository = repository;

    // Cleanup handler (non-AutoDispose, so manual cleanup on invalidate)
    ref.onDispose(_disposeController);

    // Schedule async initialization after notifier is ready
    Future.microtask(_initialize);

    return const CouponState();
  }

  /// Initialize and load data
  Future<void> _initialize() async {
    if (_initialized) {
      return; // Already initialized
    }

    _initialized = true;

    await _loadInitial();
    _startPolling();
  }

  /// Load initial data from repository (cache or remote)
  /// Passes forceRefresh: true to bypass cache TTL and fetch fresh data from server
  Future<void> _loadInitial() async {
    try {
      state = state.copyWith(
        status: CouponStatus.loading,
        isRefreshing: true,
        refreshStartedAt: DateTime.now(),
      );

      final couponList = await _repository.getCouponList(forceRefresh: true);

      // couponList is null only when server returns 304 (data unchanged)
      // This shouldn't happen on initial load (forceRefresh=true)
      if (couponList == null) {
        state = state.copyWith(
          status: CouponStatus.error,
          errorMessage: 'No coupon data available',
          isRefreshing: false,
        );
      } else if (couponList.results.isEmpty) {
        state = state.copyWith(
          status: CouponStatus.empty,
          couponList: couponList,
          lastSyncedAt: DateTime.now(),
          isRefreshing: false,
        );
      } else {
        state = state.copyWith(
          status: CouponStatus.data,
          couponList: couponList,
          lastSyncedAt: DateTime.now(),
          isRefreshing: false,
        );
      }

      _scheduleIndicatorReset();
    } catch (e) {
      state = state.copyWith(
        status: CouponStatus.error,
        errorMessage: e.toString(),
        isRefreshing: false,
      );

      _scheduleIndicatorReset();
    }
  }

  /// Refresh coupon list data
  Future<void> refresh() async {
    if (state.isRefreshing) return;

    state = state.copyWith(
      isRefreshing: true,
      refreshStartedAt: DateTime.now(),
    );

    await _refreshInternal();
  }

  /// Internal refresh logic with conditional request support
  /// Uses If-Modified-Since optimization (304 or 200)
  Future<void> _refreshInternal() async {
    try {
      // Fetch with conditional request (304 or 200)
      final couponListResult = await _repository.getCouponList();

      // 304 Not Modified - no changes on server
      if (couponListResult == null) {
        developer.log(
          'Polling coupons: 304 Not Modified (no UI update)',
          name: 'CouponController',
        );
        state = state.copyWith(
          isRefreshing: false,
          refreshEndedAt: DateTime.now(),
        );
        _scheduleIndicatorReset();
        return;
      }

      // 200 OK - new data from server
      developer.log(
        'Polling coupons: 200 OK (UI updated)',
        name: 'CouponController',
      );

      final newStatus = couponListResult.results.isEmpty
          ? CouponStatus.empty
          : CouponStatus.data;

      state = state.copyWith(
        status: newStatus,
        couponList: couponListResult,
        lastSyncedAt: DateTime.now(),
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
      );

      _scheduleIndicatorReset();
    } catch (e) {
      developer.log('Polling failed for coupons: $e', name: 'CouponController');

      state = state.copyWith(
        status: CouponStatus.error,
        errorMessage: e.toString(),
        isRefreshing: false,
        refreshEndedAt: DateTime.now(),
      );

      _scheduleIndicatorReset();
    }
  }

  void _startPolling() {
    // Register with PollingManager for screen-aware polling
    // DO NOT start timer here - wait for onResume callback
    PollingManager.instance.registerPoller(
      featureName: 'cart',
      resourceId: 'coupons',
      onResume: _resumePolling,
      onPause: _pausePolling,
    );
  }

  /// Actually start the polling timer (called by PollingManager when cart feature is active)
  void _startPollingTimer() {
    _pollingTimer ??= Timer.periodic(_pollingInterval, (_) async {
      if (state.isRefreshing) return;
      if (!state.hasData && state.status == CouponStatus.loading) {
        return;
      }
      await refresh();
    });
  }

  /// Resume polling when user navigates back to cart screen
  void _resumePolling() {
    if (_pollingTimer == null) {
      developer.log(
        'Resuming polling for coupons',
        name: 'CouponController',
        level: 700,
      );
      _startPollingTimer();
    }
  }

  /// Pause polling when user navigates away from cart screen
  void _pausePolling() {
    if (_pollingTimer != null) {
      developer.log(
        'Pausing polling for coupons',
        name: 'CouponController',
        level: 700,
      );
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  /// Schedule reset of refresh indicators
  /// Duration controlled globally via CacheConfig
  void _scheduleIndicatorReset() {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(CacheConfig.refreshIndicatorDuration, () {
      state = state.copyWith(
        resetRefreshStartedAt: true,
        resetRefreshEndedAt: true,
      );
    });
  }

  /// Dispose resources
  void _disposeController() {
    PollingManager.instance.unregisterPoller(
      featureName: 'cart',
      resourceId: 'coupons',
    );
    _pollingTimer?.cancel();
    _indicatorTimer?.cancel();
    _initialized = false;
  }
}

/// Coupon list provider with Notifier for singleton state
/// Uses regular Notifier (not AutoDispose) to maintain polling across navigation
final couponControllerProvider =
    NotifierProvider<CouponController, CouponState>(CouponController.new);
