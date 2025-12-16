// lib/core/location/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';

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

class LocationFetchFailure extends Failure {
  const LocationFetchFailure([String? details])
    : super('Unable to fetch your location', details);
}

/// Service class for handling location operations
class LocationService {
  LocationService._();
  static final LocationService _instance = LocationService._();
  static LocationService get instance => _instance;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    // First check if location service is enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    // Check permission status
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
    // First check if location service is enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Try to open location settings
      await Geolocator.openLocationSettings();
      // Re-check after user returns
      final rechecked = await isLocationServiceEnabled();
      if (!rechecked) {
        return LocationPermissionStatus.serviceDisabled;
      }
    }

    // Request permission
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

  /// Get current location with proper error handling
  Future<Either<Failure, LocationData>> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      // Check permission status first
      final permissionStatus = await checkPermissionStatus();

      switch (permissionStatus) {
        case LocationPermissionStatus.serviceDisabled:
          return const Left(LocationServiceDisabledFailure());
        case LocationPermissionStatus.denied:
          // Try to request permission
          final newStatus = await requestPermission();
          if (newStatus != LocationPermissionStatus.granted) {
            return const Left(LocationPermissionDeniedFailure());
          }
        case LocationPermissionStatus.deniedForever:
          return const Left(LocationPermissionDeniedForeverFailure());
        case LocationPermissionStatus.granted:
          // Permission granted, proceed
          break;
      }

      // Fetch current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );

      return Right(
        LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        ),
      );
    } on LocationServiceDisabledException {
      return const Left(LocationServiceDisabledFailure());
    } on PermissionDeniedException {
      return const Left(LocationPermissionDeniedFailure());
    } catch (e) {
      return Left(LocationFetchFailure(e.toString()));
    }
  }

  /// Get last known location (faster but may be stale)
  Future<Either<Failure, LocationData?>> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        return const Right(null);
      }

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
