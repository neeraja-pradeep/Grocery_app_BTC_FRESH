import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/user_address.dart';
import '../screen/search_screen.dart';
import 'profile_icon_button.dart';
import 'search_bar.dart';

class HomeHeader extends StatelessWidget {
  final UserAddress? address;
  final VoidCallback onAddressClick;
  final VoidCallback onProfileClick;

  const HomeHeader({
    super.key,
    this.address,
    required this.onAddressClick,
    required this.onProfileClick,
  });

  // --- Search Handlers ---
  // // Updated to accept BuildContext so you can navigate
  // void _handleTextSearch(BuildContext context, String query) {
  //   // debugPrint("Search query submitted: $query");
  //   // TODO: Implement navigation to search results
  //   // Navigator.push(context, MaterialPageRoute(builder: (_) => SearchResultsPage(query: query)));
  // }

  // void _handleVoiceSearch(BuildContext context) {
  //   // debugPrint("Voice search clicked");
  //   // TODO: Implement voice search logic or navigation
  // }

  @override
  Widget build(BuildContext context) {
    // Define theme colors
    const Color backgroundColor = Color(0xFFcaf5ac); // Light green background
    const Color darkGreenColor = Color(0xFF0b6866); // Dark green for Text/Icons
    const Color brightGreenColor = Color(
      0xFF64DD17,
    ); // Bright green for logo accent

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
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
            color: const Color(0xffbae888), // The specific row background color
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Location Icon
                Icon(Icons.location_on, color: darkGreenColor, size: 32.sp),

                SizedBox(width: 12.w),

                // Address Details
                Expanded(
                  child: GestureDetector(
                    onTap: onAddressClick,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Line: City : Area
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                address != null
                                    ? 'Calicut :'
                                    : 'Select Location',
                                style: TextStyle(
                                  color: darkGreenColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // Bottom Line: Specific Address + Dropdown Icon
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                address?.shortDisplay ??
                                    'Ozanam bhavan Devagiri',
                                style: TextStyle(
                                  color: darkGreenColor,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 18.sp,
                              color: darkGreenColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Profile Icon
                ProfileIconButton(onProfileTap: onProfileClick),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // --- 3. SEARCH BAR SECTION ---
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 20.h),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              // AbsorbPointer prevents the TextField inside CustomSearchBar from getting focus
              child: AbsorbPointer(
                child: CustomSearchBar(
                  onTextSearch: (query) {}, // Won't be called here
                  onVoiceSearch: () {}, // Handle separately if needed
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
