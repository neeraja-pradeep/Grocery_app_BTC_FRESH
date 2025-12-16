// lib/features/home/presentation/components/location_map_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/location/location_service.dart';

/// A compact Google Maps widget for displaying user's current location
/// Designed to be used in the home header section
class LocationMapWidget extends ConsumerStatefulWidget {
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onLocationFetched;

  const LocationMapWidget({
    super.key,
    this.height = 120,
    this.onTap,
    this.onLocationFetched,
  });

  @override
  ConsumerState<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends ConsumerState<LocationMapWidget> {
  GoogleMapController? _mapController;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    // Initialize location when widget loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
  }

  Future<void> _animateToLocation(LocationData location) async {
    if (_mapController != null && _isMapReady) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          16.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    // Listen for location updates to animate camera
    ref.listen<LocationState>(locationProvider, (previous, next) {
      next.mapOrNull(
        loaded: (state) {
          _animateToLocation(state.location);
          widget.onLocationFetched?.call();
        },
      );
    });

    return Container(
      height: widget.height.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: locationState.when(
        initial: () => _buildLoadingState(),
        loading: () => _buildLoadingState(),
        permissionRequired: (status) => _buildPermissionState(status),
        loaded: (location) => _buildMapView(location),
        error: (failure, previousLocation) =>
            _buildErrorState(failure, previousLocation),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0b6866)),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Getting your location...',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF0b6866)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionState(LocationPermissionStatus status) {
    String message;
    String buttonText;
    VoidCallback onPressed;

    switch (status) {
      case LocationPermissionStatus.denied:
        message = 'Enable location to see nearby stores';
        buttonText = 'Enable Location';
        onPressed = () =>
            ref.read(locationProvider.notifier).requestPermission();
      case LocationPermissionStatus.deniedForever:
        message = 'Location permission denied';
        buttonText = 'Open Settings';
        onPressed = () => ref.read(locationProvider.notifier).openSettings();
      case LocationPermissionStatus.serviceDisabled:
        message = 'Location services are off';
        buttonText = 'Enable GPS';
        onPressed = () =>
            ref.read(locationProvider.notifier).openLocationSettings();
      case LocationPermissionStatus.granted:
        message = 'Fetching location...';
        buttonText = 'Retry';
        onPressed = () =>
            ref.read(locationProvider.notifier).fetchCurrentLocation();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: const Color(0xFFE8F5E9),
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 28.sp,
              color: const Color(0xFF0b6866),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF0b6866),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0b6866),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                minimumSize: Size(0, 32.h),
              ),
              child: Text(buttonText, style: TextStyle(fontSize: 12.sp)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(LocationData location) {
    final position = LatLng(location.latitude, location.longitude);

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: position, zoom: 16.0),
            markers: {
              Marker(
                markerId: const MarkerId('current_location'),
                position: position,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: const InfoWindow(title: 'Your Location'),
              ),
            },
            myLocationEnabled: false, // Disable blue dot since we have marker
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            scrollGesturesEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            zoomGesturesEnabled: false,
            // Disable lite mode to show full map details (roads, labels, etc.)
            liteModeEnabled: false,
            // Show buildings for better context
            buildingsEnabled: true,
            // Normal map type shows roads, labels, landmarks
            mapType: MapType.normal,
          ),
          // Overlay for tap handling with subtle hint
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Tap to change hint
          Positioned(
            bottom: 8.h,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF0b6866).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 12.sp, color: Colors.white),
                  SizedBox(width: 4.w),
                  Text(
                    'Tap to change',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Refresh button
          Positioned(top: 8.h, right: 8.w, child: _buildRefreshButton()),
          // Location accuracy indicator
          if (location.accuracy != null)
            Positioned(
              top: 8.h,
              left: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      size: 12.sp,
                      color: const Color(0xFF0b6866),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${location.accuracy!.toStringAsFixed(0)}m',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFF0b6866),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic failure, LocationData? previousLocation) {
    // If we have previous location, show map with error indicator
    if (previousLocation != null) {
      return Stack(
        children: [
          _buildMapView(previousLocation),
          Positioned(
            top: 8.h,
            left: 8.w,
            right: 48.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 14.sp, color: Colors.white),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      'Using last known location',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // No previous location, show error state
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: const Color(0xFFFFEBEE),
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 28.sp, color: Colors.red.shade700),
            SizedBox(height: 8.h),
            Text(
              'Unable to get location',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: () =>
                  ref.read(locationProvider.notifier).fetchCurrentLocation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                minimumSize: Size(0, 32.h),
              ),
              child: Text('Try Again', style: TextStyle(fontSize: 12.sp)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(locationProvider.notifier).refresh(),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Icon(
              Icons.refresh,
              size: 18.sp,
              color: const Color(0xFF0b6866),
            ),
          ),
        ),
      ),
    );
  }
}
