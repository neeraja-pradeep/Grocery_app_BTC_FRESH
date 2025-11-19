import 'package:flutter/material.dart';
import 'package:new_app/features/home/domain/entities/user_address.dart';

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

  @override
  Widget build(BuildContext context) {
    // Define theme colors
    const Color backgroundColor = Color(0xFFCCF3B8); // Light green background
    const Color darkGreenColor = Color(0xFF004D40); // Dark green for Text/Icons
    const Color brightGreenColor = Color(
      0xFF64DD17,
    ); // Bright green for logo accent

    // UPDATED: Background color for the specific row (Red tint)

    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add status bar spacing manually since we removed the main wrapper padding
          const SizedBox(height: 20),

          // --- 1. LOGO SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset(
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
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- 2. LOCATION & PROFILE SECTION (Full Width Background) ---
          Container(
            width: double.infinity,
            color: Colors.greenAccent, // UPDATED: The Red background
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Location Icon - Reverted to Dark Green for contrast on Red bg
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
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Search For 'Cooker'",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),

                  const Icon(Icons.mic, color: darkGreenColor, size: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
