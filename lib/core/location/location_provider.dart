// lib/core/location/location_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../error/failure.dart';
import 'location_service.dart';

part 'location_provider.freezed.dart';

/// Location state using Freezed for immutability
@freezed
sealed class LocationState with _$LocationState {
  const factory LocationState.initial() = LocationInitial;

  const factory LocationState.loading() = LocationLoading;

  const factory LocationState.permissionRequired({
    required LocationPermissionStatus status,
  }) = LocationPermissionRequired;

  const factory LocationState.loaded({required LocationData location}) =
      LocationLoaded;

  const factory LocationState.error({
    required Failure failure,
    LocationData? previousLocation,
  }) = LocationError;
}

/// Location state notifier for managing location state
class LocationNotifier extends Notifier<LocationState> {
  LocationService get _locationService => LocationService.instance;

  @override
  LocationState build() {
    return const LocationState.initial();
  }

  /// Initialize and check permission status.
  ///
  /// Hydrates from the Hive cache first so we have *something* on screen
  /// instantly (offline-friendly), then revalidates against the OS.
  Future<void> initialize() async {
    state = const LocationState.loading();

    final cached = await _locationService.getCachedLocation();
    if (cached != null) {
      state = LocationState.loaded(location: cached);
    }

    final permissionStatus = await _locationService.checkPermissionStatus();

    if (permissionStatus == LocationPermissionStatus.granted) {
      await fetchCurrentLocation();
    } else if (cached == null) {
      // No cache to fall back on — surface the permission state.
      state = LocationState.permissionRequired(status: permissionStatus);
    }
  }

  /// Request location permission
  Future<void> requestPermission() async {
    state = const LocationState.loading();

    final status = await _locationService.requestPermission();

    if (status == LocationPermissionStatus.granted) {
      await fetchCurrentLocation();
    } else {
      state = LocationState.permissionRequired(status: status);
    }
  }

  /// Fetch current location.
  ///
  /// Pass [forceFresh] = true when callers must bypass the cached reading
  /// (e.g. confirming a delivery address right before saving).
  Future<void> fetchCurrentLocation({bool forceFresh = false}) async {
    // Preserve previous location if available
    LocationData? previousLocation;
    state.mapOrNull(
      loaded: (s) => previousLocation = s.location,
      error: (s) => previousLocation = s.previousLocation,
    );

    state = const LocationState.loading();

    final result = await _locationService.getCurrentLocation(
      forceFresh: forceFresh,
    );

    result.fold(
      (failure) {
        if (failure is LocationPermissionDeniedFailure) {
          state = const LocationState.permissionRequired(
            status: LocationPermissionStatus.denied,
          );
        } else if (failure is LocationPermissionDeniedForeverFailure) {
          state = const LocationState.permissionRequired(
            status: LocationPermissionStatus.deniedForever,
          );
        } else if (failure is LocationServiceDisabledFailure) {
          state = const LocationState.permissionRequired(
            status: LocationPermissionStatus.serviceDisabled,
          );
        } else if (failure is LocationLowAccuracyFailure) {
          // Expose the low-accuracy reading via previousLocation so consumers
          // can still render the coords alongside the warning + refresh CTA.
          state = LocationState.error(
            failure: failure,
            previousLocation: failure.location,
          );
        } else {
          state = LocationState.error(
            failure: failure,
            previousLocation: previousLocation,
          );
        }
      },
      (location) {
        state = LocationState.loaded(location: location);
      },
    );
  }

  /// Open app settings (for permanently denied permission)
  Future<void> openSettings() async {
    await _locationService.openAppSettings();
  }

  /// Open location settings (for disabled location service)
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Refresh location — always bypasses the cache.
  Future<void> refresh() async {
    await fetchCurrentLocation(forceFresh: true);
  }

  /// Get current location data if available
  LocationData? get currentLocation {
    return state.mapOrNull(
      loaded: (s) => s.location,
      error: (s) => s.previousLocation,
    );
  }
}

/// Provider for LocationNotifier
final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  LocationNotifier.new,
);

/// Provider for LocationService singleton
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService.instance;
});

/// Selector for current location data
final currentLocationProvider = Provider<LocationData?>((ref) {
  final locationState = ref.watch(locationProvider);
  return locationState.mapOrNull(
    loaded: (s) => s.location,
    error: (s) => s.previousLocation,
  );
});

/// Selector for checking if location is available
final hasLocationProvider = Provider<bool>((ref) {
  final location = ref.watch(currentLocationProvider);
  return location != null;
});
