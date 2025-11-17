// lib/config/theme/color_theme.dart

import 'package:flutter/material.dart';

/// Defines the primary color palette used throughout the application.
class AppColors {
  // --- Primary App Colors (Based on Logo/Branding) ---

  /// Primary Green for background/promotions (e.g., SliverAppBar background)
  static const Color primaryGreenDark = Color(
    0xFFC3E6C3,
  ); // Used in home_app_bar.dart

  /// Secondary Green for the logo or accents (e.g., 'Gro' in EasyGro)
  static const Color secondaryGreenLogo = Color(0xFF4CAF50);

  /// Tertiary Green for deep contrast (e.g., 'Easy' in EasyGro logo text)
  static const Color tertiaryGreenDeep = Color(0xFF1B5E20);

  // --- Header/Location Bar Colors ---

  /// Lightest Green for the location strip background (Used in location_chip.dart)
  static const Color locationStripLight = Color(0xFFC7E2A6);

  /// Dark text color used for icons and text in the header/location strip
  static const Color headerDarkText = Color(0xFF374151);

  // --- Product/Offer Colors ---

  /// Primary color for product prices and "Add" buttons (MegaOfferProductCard)
  static const Color productPriceBlue = Color(0xFF3B82F6);

  /// Primary color for discount badges (Red in MegaOfferProductCard)
  static const Color discountRed = Color(0xFFE53935); // A standard red

  /// Lightest background for placeholder images (F7F7F7 in product_card.dart)
  static const Color lightBackground = Color(0xFFF7F7F7);

  // --- General Text/UI Colors ---

  /// Default text color for body copy
  static const Color bodyTextBlack = Color(0xFF333333);

  /// Default color for secondary/hint text
  static const Color hintGrey = Color(0xFF9E9E9E);

  /// Standard white color
  static const Color white = Colors.white;
}
