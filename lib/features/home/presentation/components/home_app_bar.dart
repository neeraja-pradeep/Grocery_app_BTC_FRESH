// features/home/presentation/components/home_app_bar.dart

// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

// --- Placeholder Imports ---
import 'package:new_app/features/home/presentation/components/location_chip.dart';
import 'package:new_app/features/home/presentation/components/search_bar.dart';
// ---------------------------

class HomeAppBar extends StatelessWidget {
  final String title;
  final String locationLabel;
  final VoidCallback onLocationTap;
  final VoidCallback onProfileTap;
  final ValueChanged<String> onSubmitSearch;
  final VoidCallback onStartVoiceSearch;
  final TextEditingController searchController;

  const HomeAppBar({
    super.key,
    required this.title,
    required this.locationLabel,
    required this.onLocationTap,
    required this.onProfileTap,
    required this.onSubmitSearch,
    required this.onStartVoiceSearch,
    required this.searchController,
  });

  // Define the colors from the design image
  // The dark green background for the overall header
  static const Color darkGreenBackground = Color(0xFFC3E6C3);
  // The light green for the location strip is handled inside LocationChip (Color(0xFFC7E2A6))

  @override
  Widget build(BuildContext context) {
    // We will use a calculated height to ensure no overflow
    // Logo (30) + Padding (20) + LocationChip (55) + SearchBar (60) + Bottom Margin (10)
    const double requiredHeight = 175.0;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      // Increased expandedHeight to fix the bottom overflow error
      expandedHeight: requiredHeight,
      backgroundColor: darkGreenBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: Column(
          children: [
            // Row 1: Logo (Recreated visually as text since the image asset is unavailable)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                // Top padding relative to system status bar height
                MediaQuery.of(context).padding.top + 10,
                16,
                0, // No bottom padding here
              ),
              child: Row(
                children: [Image(image: AssetImage('assets/title.png'))],
              ),
            ),

            LocationChip(
              // Using dummy data based on the image provided in the prompt's context
              city: "Calicut",
              addressLine1: "Kuttikkattoor mavor",
              addressLine2: "Ozanum bhavan Devagiri",
              onProfileTap: onProfileTap,
              onLocationTap: onLocationTap,
            ),

            // Row 3: Search Bar
            // CustomSearchBar already has horizontal margins, but we need to ensure vertical spacing
            CustomSearchBar(
              controller: searchController,
              onSubmitSearch: onSubmitSearch,
              onStartVoiceSearch: onStartVoiceSearch,
            ),
          ],
        ),
      ),
    );
  }
}
