import 'package:flutter/material.dart';
import 'package:new_app/features/home/domain/entities/user_address.dart';
import 'package:new_app/features/home/presentation/components/search_bar.dart';

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
  // Updated to accept BuildContext so you can navigate
  void _handleTextSearch(BuildContext context, String query) {
    // debugPrint("Search query submitted: $query");
    // TODO: Implement navigation to search results
    // Navigator.push(context, MaterialPageRoute(builder: (_) => SearchResultsPage(query: query)));
  }

  void _handleVoiceSearch(BuildContext context) {
    // debugPrint("Voice search clicked");
    // TODO: Implement voice search logic or navigation
  }

  @override
  Widget build(BuildContext context) {
    // Define theme colors
    const Color backgroundColor = Color(0xFFcaf5ac); // Light green background
    const Color darkGreenColor = Color(0xFF0b6866); // Dark green for Text/Icons
    const Color brightGreenColor = Color(
      0xFF64DD17,
    ); // Bright green for logo accent

    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add status bar spacing manually
          const SizedBox(height: 20),

          // --- 1. LOGO SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Wrap Image in limited box or use error builder to handle missing asset safely
                SizedBox(
                  height: 36,
                  child: Image.asset(
                    'assets/title.png',
                    height: 36,
                    errorBuilder: (c, e, s) => RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Sans',
                        ),
                        children: [
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

          const SizedBox(height: 16),

          // --- 2. LOCATION & PROFILE SECTION (Full Width Background) ---
          Container(
            width: double.infinity,
            color: const Color(0xffbae888), // The specific row background color
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Location Icon
                const Icon(Icons.location_on, color: darkGreenColor, size: 32),

                const SizedBox(width: 12),

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
                                style: const TextStyle(
                                  color: darkGreenColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
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
                                style: const TextStyle(
                                  color: darkGreenColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: darkGreenColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Profile Icon
                GestureDetector(
                  onTap: onProfileClick,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: darkGreenColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 28,
                      color: darkGreenColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- 3. SEARCH BAR SECTION ---
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
            child: CustomSearchBar(
              // Pass the context to the handlers
              onTextSearch: (query) => _handleTextSearch(context, query),
              onVoiceSearch: () => _handleVoiceSearch(context),
            ),
          ),
        ],
      ),
    );
  }
}
