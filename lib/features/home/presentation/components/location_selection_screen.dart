// lib/features/home/presentation/components/location_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/location/location_provider.dart';
import '../../../address/presentation/screens/address_form_screen.dart';

/// Data model for selected location
class SelectedLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  const SelectedLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });
}

/// Full-screen location selection screen with Google Maps
/// Allows user to search, tap, or drag to select a location
class LocationSelectionScreen extends ConsumerStatefulWidget {
  final LatLng? initialLocation;
  final VoidCallback? onBackWithoutSelection;

  /// If true, returns SelectedLocation directly without navigating to AddressFormScreen
  final bool returnLocationOnly;

  const LocationSelectionScreen({
    super.key,
    this.initialLocation,
    this.onBackWithoutSelection,
    this.returnLocationOnly = false,
  });

  @override
  ConsumerState<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState
    extends ConsumerState<LocationSelectionScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Map state
  LatLng? _selectedPosition;
  String? _selectedAddress;
  String? _selectedCity;
  String? _selectedState;
  String? _selectedPostalCode;
  String? _selectedCountry;
  bool _isLoadingAddress = false;
  bool _isSearching = false;
  List<_SearchResult> _searchResults = [];
  bool _showSearchResults = false;
  bool _isDragging = false;

  // Debounce for address fetching
  DateTime? _lastAddressFetchTime;
  static const _addressFetchDebounce = Duration(milliseconds: 500);

  // Animation for pin
  late AnimationController _pinAnimationController;
  late Animation<double> _pinBounceAnimation;

  // Theme colors
  static const Color _primaryGreen = Color(0xFF0b6866);
  static const Color _lightGreen = Color(0xFFcaf5ac);

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);

    // Initialize pin bounce animation
    _pinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pinBounceAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(
        parent: _pinAnimationController,
        curve: Curves.easeOut,
        reverseCurve: Curves.bounceOut,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _pinAnimationController.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (!_searchFocusNode.hasFocus) {
      setState(() {
        _showSearchResults = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Move to initial location if provided
    if (widget.initialLocation != null) {
      _selectedPosition = widget.initialLocation;
      _getAddressFromLatLng(widget.initialLocation!);
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _selectedPosition = position;
      _isLoadingAddress = true;
      _showSearchResults = false;
    });
    _searchFocusNode.unfocus();
    await _getAddressFromLatLng(position);
  }

  Future<void> _onCameraIdle() async {
    // Called when map stops moving (after drag)
    if (_isDragging && _selectedPosition != null) {
      setState(() {
        _isDragging = false;
      });

      // Animate pin back down
      _pinAnimationController.reverse();

      // Debounce address fetching to avoid too many API calls
      final now = DateTime.now();
      if (_lastAddressFetchTime == null ||
          now.difference(_lastAddressFetchTime!) > _addressFetchDebounce) {
        _lastAddressFetchTime = now;
        await _getAddressFromLatLng(_selectedPosition!);
      }
    }
  }

  void _onCameraMoveStarted() {
    // Called when user starts dragging the map
    if (!_isDragging) {
      setState(() {
        _isDragging = true;
        _isLoadingAddress = true;
      });
      // Animate pin up
      _pinAnimationController.forward();
    }
  }

  void _onCameraMove(CameraPosition position) {
    // Update selected position as user drags
    setState(() {
      _selectedPosition = position.target;
    });
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = _formatAddress(place);
        setState(() {
          _selectedAddress = address;
          _selectedCity = place.locality;
          _selectedState = place.administrativeArea;
          _selectedPostalCode = place.postalCode;
          _selectedCountry = place.country;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = 'Unable to get address';
          _selectedCity = null;
          _selectedState = null;
          _selectedPostalCode = null;
          _selectedCountry = null;
          _isLoadingAddress = false;
        });
      }
    }
  }

  String _formatAddress(Placemark place) {
    final parts = <String>[];

    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      parts.add(place.postalCode!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      final locations = await locationFromAddress(query);

      if (mounted) {
        final results = <_SearchResult>[];

        for (final location in locations.take(5)) {
          try {
            final placemarks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            );
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              results.add(
                _SearchResult(
                  title: place.locality ?? place.name ?? query,
                  subtitle: _formatAddress(place),
                  position: LatLng(location.latitude, location.longitude),
                ),
              );
            }
          } catch (_) {
            results.add(
              _SearchResult(
                title: query,
                subtitle:
                    '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                position: LatLng(location.latitude, location.longitude),
              ),
            );
          }
        }

        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _selectSearchResult(_SearchResult result) {
    setState(() {
      _selectedPosition = result.position;
      _selectedAddress = result.subtitle;
      _showSearchResults = false;
      _searchController.text = result.title;
    });
    _searchFocusNode.unfocus();

    // Animate to selected location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(result.position, 16.0),
    );
  }

  Future<void> _goToCurrentLocation() async {
    final locationState = ref.read(locationProvider);

    locationState.mapOrNull(
      loaded: (state) {
        final position = LatLng(
          state.location.latitude,
          state.location.longitude,
        );
        setState(() {
          _selectedPosition = position;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 16.0),
        );
        _getAddressFromLatLng(position);
      },
      permissionRequired: (_) {
        // Request permission
        ref.read(locationProvider.notifier).requestPermission();
      },
    );
  }

  Future<void> _confirmSelection() async {
    if (_selectedPosition != null) {
      // Create the selected location with all extracted data
      final selectedLocation = SelectedLocation(
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
        address: _selectedAddress,
        city: _selectedCity,
        state: _selectedState,
        postalCode: _selectedPostalCode,
        country: _selectedCountry,
      );

      // If returnLocationOnly mode, just return the location without navigating
      if (widget.returnLocationOnly) {
        Navigator.pop(context, selectedLocation);
        return;
      }

      // Navigate to address form to fill in additional details
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (context) =>
              AddressFormScreen(selectedLocation: selectedLocation),
        ),
      );

      // If address was successfully saved, close the location selection screen
      // and return the selected location to the caller
      if (result == true && mounted) {
        Navigator.pop(context, selectedLocation);
      }
    }
  }

  void _handleBack() {
    widget.onBackWithoutSelection?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    // Get initial camera position
    LatLng initialPosition =
        widget.initialLocation ??
        const LatLng(20.5937, 78.9629); // Default: India center

    locationState.mapOrNull(
      loaded: (state) {
        if (widget.initialLocation == null && _selectedPosition == null) {
          initialPosition = LatLng(
            state.location.latitude,
            state.location.longitude,
          );
        }
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Google Map (Full Screen) - Professional map with all details visible
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _selectedPosition ?? initialPosition,
                zoom: 17.0, // Higher zoom for better street visibility
                tilt: 0, // No tilt for clearer 2D view
              ),
              onTap: _onMapTap,
              onCameraMoveStarted: _onCameraMoveStarted,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              // Enable all map type features for professional look
              mapType: MapType.normal,
              // Show buildings in 3D for urban areas
              buildingsEnabled: true,
              // Show indoor maps for malls/airports
              indoorViewEnabled: true,
              // Show traffic for better context
              trafficEnabled: false,
              // Padding to account for UI overlays
              padding: EdgeInsets.only(top: 80.h, bottom: 180.h),
            ),

            // Center Pin with animation (Fixed position marker)
            Center(
              child: AnimatedBuilder(
                animation: _pinBounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _pinBounceAnimation.value),
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pin shadow when lifted
                    if (_isDragging)
                      Container(
                        width: 12.w,
                        height: 6.h,
                        margin: EdgeInsets.only(bottom: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    // Main pin icon
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.location_pin,
                        size: 40.sp,
                        color: _primaryGreen,
                      ),
                    ),
                    // Pin pointer
                    Container(
                      width: 3.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _primaryGreen,
                            _primaryGreen.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    // Ground dot
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: _primaryGreen.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top Section: Back button + Search bar
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  if (_showSearchResults) _buildSearchResults(),
                ],
              ),
            ),

            // Bottom Section: Address card + Confirm button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomSection(),
            ),

            // Current Location FAB
            Positioned(
              right: 16.w,
              bottom: 200.h,
              child: _buildCurrentLocationButton(),
            ),

            // Zoom Controls
            Positioned(right: 16.w, bottom: 270.h, child: _buildZoomControls()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // Back Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleBack,
                borderRadius: BorderRadius.circular(24.r),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Icon(
                    Icons.arrow_back,
                    color: _primaryGreen,
                    size: 24.sp,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Search Bar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  if (value.length >= 3) {
                    _searchLocation(value);
                  } else {
                    setState(() {
                      _searchResults = [];
                      _showSearchResults = false;
                    });
                  }
                },
                onSubmitted: _searchLocation,
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14.sp,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _primaryGreen,
                    size: 22.sp,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey.shade500,
                            size: 20.sp,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _showSearchResults = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                ),
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      constraints: BoxConstraints(maxHeight: 250.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isSearching
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryGreen),
                  ),
                ),
              ),
            )
          : _searchResults.isEmpty
          ? Padding(
              padding: EdgeInsets.all(20.w),
              child: Text(
                'No results found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: _searchResults.length,
              separatorBuilder: (_, index) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  onTap: () => _selectSearchResult(result),
                  leading: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: const BoxDecoration(
                      color: _lightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: _primaryGreen,
                      size: 20.sp,
                    ),
                  ),
                  title: Text(
                    result.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    result.subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Selected Location Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: _primaryGreen,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Location',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isLoadingAddress
                              ? Row(
                                  key: const ValueKey('loading'),
                                  children: [
                                    SizedBox(
                                      width: 16.w,
                                      height: 16.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _primaryGreen,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        _isDragging
                                            ? 'Locating selected place...'
                                            : 'Fetching address...',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  key: ValueKey(_selectedAddress),
                                  _selectedAddress ??
                                      'Move the map to select location',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _selectedPosition != null && !_isLoadingAddress
                      ? _confirmSelection
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm Location',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _goToCurrentLocation,
          borderRadius: BorderRadius.circular(24.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Icon(Icons.my_location, color: _primaryGreen, size: 24.sp),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Icon(Icons.add, color: _primaryGreen, size: 22.sp),
              ),
            ),
          ),
          Container(height: 1, width: 30.w, color: Colors.grey.shade200),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  _mapController?.animateCamera(CameraUpdate.zoomOut()),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8.r)),
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Icon(Icons.remove, color: _primaryGreen, size: 22.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Search result model
class _SearchResult {
  final String title;
  final String subtitle;
  final LatLng position;

  const _SearchResult({
    required this.title,
    required this.subtitle,
    required this.position,
  });
}
