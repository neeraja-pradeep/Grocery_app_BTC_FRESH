// lib/core/location/location_service.dart

import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permission;

import '../error/failure.dart';
import '../storage/hive/boxes.dart';
import '../storage/hive/keys.dart';

/// Location permission status enum
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LocationData.fromJson(Map<dynamic, dynamic> json) => LocationData(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    accuracy: (json['accuracy'] as num?)?.toDouble(),
    timestamp:
        DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
        DateTime.now(),
  );

  @override
  String toString() =>
      'LocationData(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
}

/// Location-specific failures
class LocationPermissionDeniedFailure extends Failure {
  const LocationPermissionDeniedFailure()
    : super('Location permission denied. Please enable it in settings.');
}

class LocationPermissionDeniedForeverFailure extends Failure {
  const LocationPermissionDeniedForeverFailure()
    : super(
        'Location permission permanently denied. '
        'Please enable it from app settings.',
      );
}

class LocationServiceDisabledFailure extends Failure {
  const LocationServiceDisabledFailure()
    : super('Location services are disabled. Please enable GPS.');
}

class LocationTimeoutFailure extends Failure {
  const LocationTimeoutFailure()
    : super('Locating you took too long. Please try again.');
}

/// Carries the reading even though accuracy is worse than the configured
/// threshold — UI may still display it with a "refresh" CTA.
class LocationLowAccuracyFailure extends Failure {
  final LocationData location;
  final double thresholdMeters;

  const LocationLowAccuracyFailure({
    required this.location,
    required this.thresholdMeters,
  }) : super('Location accuracy is low. Tap refresh for a better fix.');
}

class LocationFetchFailure extends Failure {
  const LocationFetchFailure([String? details])
    : super('Unable to fetch your location', details);
}

/// Service class for handling location operations.
///
/// Note: Geolocator falls back gracefully when Google Play Services is
/// unavailable (uses Android's LocationManager directly), so no explicit
/// availability check is needed here.
class LocationService {
  LocationService._();
  static final LocationService _instance = LocationService._();
  static LocationService get instance => _instance;

  /// Cached position TTL — within this window `getCurrentLocation` will
  /// return the cached reading instead of hitting GPS.
  static const Duration cacheTtl = Duration(minutes: 10);

  /// Readings worse than this (in meters) surface as a `LowAccuracy` warning,
  /// but the reading is still exposed.
  static const double accuracyThresholdMeters = 100;

  /// Default fetch timeout.
  static const Duration defaultTimeout = Duration(seconds: 15);

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    final status = await permission.Permission.location.status;

    if (status.isGranted) {
      return LocationPermissionStatus.granted;
    } else if (status.isPermanentlyDenied) {
      return LocationPermissionStatus.deniedForever;
    } else {
      return LocationPermissionStatus.denied;
    }
  }

  /// Request location permission
  Future<LocationPermissionStatus> requestPermission() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      final rechecked = await isLocationServiceEnabled();
      if (!rechecked) {
        return LocationPermissionStatus.serviceDisabled;
      }
    }

    final status = await permission.Permission.location.request();

    if (status.isGranted) {
      return LocationPermissionStatus.granted;
    } else if (status.isPermanentlyDenied) {
      return LocationPermissionStatus.deniedForever;
    } else {
      return LocationPermissionStatus.denied;
    }
  }

  /// Open app settings for permission
  Future<bool> openAppSettings() async {
    return await permission.openAppSettings();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Read the last cached position from local persistence (Hive).
  /// Returns `null` if nothing has ever been cached.
  Future<LocationData?> getCachedLocation() async {
    try {
      final raw = Boxes.cacheBox.get(HiveKeys.lastKnownLocation);
      if (raw is Map) {
        return LocationData.fromJson(raw);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Persist a location reading to Hive under `last_known_location`.
  Future<void> _cacheLocation(LocationData location) async {
    try {
      await Boxes.cacheBox.put(HiveKeys.lastKnownLocation, location.toJson());
    } catch (_) {
      // Caching is best-effort — never fail the read because of cache write.
    }
  }

  /// Returns the cached location only if it's still within TTL.
  Future<LocationData?> _getFreshCachedLocation() async {
    final cached = await getCachedLocation();
    if (cached == null) return null;
    final age = DateTime.now().difference(cached.timestamp);
    if (age <= cacheTtl) return cached;
    return null;
  }

  /// Get current location with proper error handling.
  ///
  /// When [forceFresh] is `false` (default) and a cached reading exists within
  /// the [cacheTtl] window, that cached reading is returned without hitting GPS.
  /// Set [forceFresh] to `true` for flows that must use a brand-new fix
  /// (e.g. confirming a delivery address).
  Future<Either<Failure, LocationData>> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = defaultTimeout,
    bool forceFresh = false,
  }) async {
    if (!forceFresh) {
      final cached = await _getFreshCachedLocation();
      if (cached != null) {
        return Right(cached);
      }
    }

    try {
      final permissionStatus = await checkPermissionStatus();

      switch (permissionStatus) {
        case LocationPermissionStatus.serviceDisabled:
          return const Left(LocationServiceDisabledFailure());
        case LocationPermissionStatus.denied:
          final newStatus = await requestPermission();
          if (newStatus == LocationPermissionStatus.deniedForever) {
            return const Left(LocationPermissionDeniedForeverFailure());
          }
          if (newStatus != LocationPermissionStatus.granted) {
            return const Left(LocationPermissionDeniedFailure());
          }
        case LocationPermissionStatus.deniedForever:
          return const Left(LocationPermissionDeniedForeverFailure());
        case LocationPermissionStatus.granted:
          break;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );

      final reading = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );

      // Cache successful reads regardless of accuracy — the warning UI still
      // wants the coordinates.
      await _cacheLocation(reading);

      if (reading.accuracy != null &&
          reading.accuracy! > accuracyThresholdMeters) {
        return Left(
          LocationLowAccuracyFailure(
            location: reading,
            thresholdMeters: accuracyThresholdMeters,
          ),
        );
      }

      return Right(reading);
    } on TimeoutException {
      return const Left(LocationTimeoutFailure());
    } on LocationServiceDisabledException {
      return const Left(LocationServiceDisabledFailure());
    } on PermissionDeniedException {
      return const Left(LocationPermissionDeniedFailure());
    } catch (e) {
      // geolocator surfaces timeouts as plain TimeoutException on Android,
      // but on some platforms it bubbles a generic exception with the word
      // "timeout" in the message — catch that case too.
      if (e.toString().toLowerCase().contains('timeout')) {
        return const Left(LocationTimeoutFailure());
      }
      return Left(LocationFetchFailure(e.toString()));
    }
  }

  /// Get last known location (faster but may be stale). Prefers Hive cache
  /// over the OS last-known to ensure offline reads work.
  Future<Either<Failure, LocationData?>> getLastKnownLocation() async {
    final cached = await getCachedLocation();
    if (cached != null) return Right(cached);

    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return const Right(null);

      return Right(
        LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        ),
      );
    } catch (e) {
      return Left(LocationFetchFailure(e.toString()));
    }
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Stream location updates
  Stream<LocationData> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).map(
      (position) => LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      ),
    );
  }
}
