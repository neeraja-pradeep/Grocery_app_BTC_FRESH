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
class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier({LocationService? locationService})
    : _locationService = locationService ?? LocationService.instance,
      super(const LocationState.initial());

  /// Initialize and check permission status
  Future<void> initialize() async {
    state = const LocationState.loading();

    final permissionStatus = await _locationService.checkPermissionStatus();

    if (permissionStatus == LocationPermissionStatus.granted) {
      // Permission already granted, fetch location
      await fetchCurrentLocation();
    } else {
      // Permission needed
      state = LocationState.permissionRequired(status: permissionStatus);
    }
  }

  /// Request location permission
  Future<void> requestPermission() async {
    state = const LocationState.loading();

    final status = await _locationService.requestPermission();

    if (status == LocationPermissionStatus.granted) {
      // Permission granted, fetch location
      await fetchCurrentLocation();
    } else {
      state = LocationState.permissionRequired(status: status);
    }
  }

  /// Fetch current location
  Future<void> fetchCurrentLocation() async {
    // Preserve previous location if available
    LocationData? previousLocation;
    state.mapOrNull(
      loaded: (s) => previousLocation = s.location,
      error: (s) => previousLocation = s.previousLocation,
    );

    state = const LocationState.loading();

    final result = await _locationService.getCurrentLocation();

    result.fold(
      (failure) {
        // Check if it's a permission-related failure
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

  /// Refresh location
  Future<void> refresh() async {
    await fetchCurrentLocation();
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
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier();
  },
);

/// Provider for LocationService singleton
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService.instance;
});

/// Selector for current location data
final currentLocationProvider = Provider<LocationData?>((ref) {
  final state = ref.watch(locationProvider);
  return state.mapOrNull(
    loaded: (s) => s.location,
    error: (s) => s.previousLocation,
  );
});

/// Selector for checking if location is available
final hasLocationProvider = Provider<bool>((ref) {
  final location = ref.watch(currentLocationProvider);
  return location != null;
});
