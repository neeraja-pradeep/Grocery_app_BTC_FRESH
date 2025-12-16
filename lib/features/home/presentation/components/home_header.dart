import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/location/location_provider.dart';
import '../../domain/entities/user_address.dart';
import '../screen/search_screen.dart';
import 'location_selection_screen.dart';
import 'profile_icon_button.dart';
import 'search_bar.dart';
import 'voice_search_overlay.dart';

class HomeHeader extends ConsumerWidget {
  final UserAddress? address;
  final VoidCallback onAddressClick;
  final VoidCallback onProfileClick;
  final bool isGuest;
  final bool showMap;

  const HomeHeader({
    super.key,
    this.address,
    required this.onAddressClick,
    required this.onProfileClick,
    this.isGuest = false,
    this.showMap = true,
  });

  /// Truncate address to show only first few words
  String _truncateToWords(String text, {int maxWords = 2}) {
    if (text.isEmpty) return text;
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length <= maxWords) return text;
    return '${words.take(maxWords).join(' ')}...';
  }

  // --- Search Handlers ---
  // // Updated to accept BuildContext so you can navigate
  // void _handleTextSearch(BuildContext context, String query) {
  //   // debugPrint("Search query submitted: $query");
  //   // Navigator.push(context, MaterialPageRoute(builder: (_) => SearchResultsPage(query: query)));
  // }

  // void _handleVoiceSearch(BuildContext context) {
  //   // debugPrint("Voice search clicked");
  // }

  /// Navigate to full-screen location selection map with smooth transition
  void _navigateToLocationSelection(BuildContext context, WidgetRef ref) {
    // Get current location if available
    final locationState = ref.read(locationProvider);
    LatLng? initialPosition;

    locationState.mapOrNull(
      loaded: (state) {
        initialPosition = LatLng(
          state.location.latitude,
          state.location.longitude,
        );
      },
    );

    // Also check if we have address with coordinates
    if (initialPosition == null &&
        address?.latitude != null &&
        address?.longitude != null) {
      final lat = double.tryParse(address!.latitude!);
      final lng = double.tryParse(address!.longitude!);
      if (lat != null && lng != null) {
        initialPosition = LatLng(lat, lng);
      }
    }

    // Use smooth page transition for professional feel
    Navigator.push<SelectedLocation>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LocationSelectionScreen(
              initialLocation: initialPosition,
              onBackWithoutSelection: () {
                // User pressed back without selecting - no action needed
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth slide up transition like delivery apps
          const begin = Offset(0.0, 0.3);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          var fadeTween = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((selectedLocation) {
      if (selectedLocation != null) {
        // Location was selected, trigger the original callback
        // The parent widget can handle saving the location
        onAddressClick();
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Define theme colors
    const Color backgroundColor = Color(0xFFcaf5ac); // Light green background
    const Color darkGreenColor = Color(0xFF0b6866); // Dark green for Text/Icons
    const Color brightGreenColor = Color(
      0xFF64DD17,
    ); // Bright green for logo accent

    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        // borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add status bar spacing manually
          SizedBox(height: 20.h),

          // --- 1. LOGO SECTION ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                // Wrap Image in limited box or use error builder to handle missing asset safely
                SizedBox(
                  height: 36.h,
                  child: Image.asset(
                    'assets/title.png',
                    height: 36.h,
                    errorBuilder: (c, e, s) => RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Sans',
                        ),
                        children: const [
                          TextSpan(
                            text: 'Easy',
                            style: TextStyle(color: darkGreenColor),
                          ),
                          TextSpan(
                            text: 'Gro',
                            style: TextStyle(color: brightGreenColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // --- 2. LOCATION & PROFILE SECTION (Full Width Background) ---
          Container(
            width: double.infinity,
            height: 50.h,
            color: const Color(0xffbae888), // The specific row background color
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isGuest) ...[
                  // Location Icon (only for authenticated users)
                  Icon(Icons.location_on, color: darkGreenColor, size: 30.h),
                  SizedBox(width: 12.w),
                  // Address Details (only for authenticated users)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToLocationSelection(context, ref),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Line: City or "Select Location"
                                Text(
                                  address != null && address!.city.isNotEmpty
                                      ? _truncateToWords(
                                          address!.city,
                                          maxWords: 2,
                                        )
                                      : 'Select Location',
                                  style: TextStyle(
                                    color: darkGreenColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2.h),
                                // Bottom Line: Street Address (truncated to 2 words)
                                Text(
                                  address != null &&
                                          address!.streetAddress1.isNotEmpty
                                      ? _truncateToWords(
                                          address!.streetAddress1,
                                          maxWords: 2,
                                        )
                                      : 'Tap to add address',
                                  style: TextStyle(
                                    color: darkGreenColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Guest mode: Show Login button
                  Expanded(
                    child: GestureDetector(
                      onTap: onProfileClick, // Navigate to login
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, color: darkGreenColor, size: 24.h),
                          SizedBox(width: 8.w),
                          Text(
                            'Login',
                            style: TextStyle(
                              color: darkGreenColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (!isGuest)
                  // Profile Icon (only for authenticated users)
                  SizedBox(
                    width: 40.h,
                    height: 40.h,
                    child: ProfileIconButton(onProfileTap: onProfileClick),
                  ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          SizedBox(height: 12.h),

          // --- 4. SEARCH BAR SECTION ---
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 20.h),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: CustomSearchBar(
                disableTextInput: true, // Prevent text field focus on home
                onTextSearch: (query) {}, // Won't be called here
                onVoiceSearch: () async {
                  // Handle voice search from home header
                  final recognizedText = await showVoiceSearchOverlay(context);
                  if (recognizedText != null && recognizedText.isNotEmpty) {
                    // Navigate to search screen with voice query
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SearchScreen(initialQuery: recognizedText),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
