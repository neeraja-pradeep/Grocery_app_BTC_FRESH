import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/user_address.dart';
import '../../../cart/presentation/components/address_sheet.dart';
import '../screen/search_screen.dart';
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

  // --- Search Handlers ---
  // // Updated to accept BuildContext so you can navigate
  // void _handleTextSearch(BuildContext context, String query) {
  //   // debugPrint("Search query submitted: $query");
  //   // Navigator.push(context, MaterialPageRoute(builder: (_) => SearchResultsPage(query: query)));
  // }

  // void _handleVoiceSearch(BuildContext context) {
  //   // debugPrint("Voice search clicked");
  // }

  /// Open address selection bottom sheet for manual address entry
  void _openAddressSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddressSheet(),
    );
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
          SizedBox(height: 10.h),

          // --- 1. LOGO SECTION ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                // Wrap Image in limited box or use error builder to handle missing asset safely
                SizedBox(
                  height: 32.h,
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
                  // Location area - entire section is tappable (except profile icon)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openAddressSheet(context, ref),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          // Location Icon
                          Icon(
                            Icons.location_on,
                            color: darkGreenColor,
                            size: 30.h,
                          ),
                          SizedBox(width: 12.w),
                          // Address Details
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display the currently selected address
                                Text(
                                  address != null &&
                                          (address!.streetAddress1.isNotEmpty ||
                                              (address!
                                                      .streetAddress2
                                                      ?.isNotEmpty ??
                                                  false))
                                      ? [
                                          if (address!
                                              .streetAddress1
                                              .isNotEmpty)
                                            address!.streetAddress1,
                                          if (address!
                                                  .streetAddress2
                                                  ?.isNotEmpty ??
                                              false)
                                            address!.streetAddress2,
                                        ].join(', ')
                                      : 'Select Location',
                                  style: TextStyle(
                                    color: darkGreenColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                  ),
                                  maxLines: 2,
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
                          Image.asset(
                            'assets/login.png',
                            height: 24.h,
                            width: 24.w,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'LOGIN',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: darkGreenColor,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w900,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (!isGuest) ...[
                  SizedBox(width: 12.w),
                  // Profile Icon (only for authenticated users)
                  SizedBox(
                    width: 40.h,
                    height: 40.h,
                    child: ProfileIconButton(onProfileTap: onProfileClick),
                  ),
                ],
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
