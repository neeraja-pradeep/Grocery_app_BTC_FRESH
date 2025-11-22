// lib/features/cart/presentation/screen/cart_screen.dart

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import necessary widgets for navigation (assuming they are defined in your project)
// import 'package:new_app/core/widgets/navbar.dart';
// import 'package:new_app/features/home/presentation/screen/home_screen.dart';
// import 'package:new_app/features/home/presentation/screen/categories_with_sidebar_screen.dart';
// import 'package:new_app/features/wishlist/presentation/screen/wishlist_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define custom colors based on the image
    const Color greenColor = Color(0xFF8BC34A); // The color of the button/text
    const Color secondaryGreenColor = Color(
      0xFF86BC27,
    ); // Slightly darker for button style

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac), // Custom green color
        statusBarIconBrightness: Brightness.dark, // Dark icons
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          // AppBar title is not visible in the empty state image provided, so we'll simplify or remove it.
          // Keeping it for standard screen structure, but setting elevation to 0.
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),
        body: Center(
          // Use a Column and flexible spacing to position content correctly
          child: Column(
            children: [
              // Flexible space to push content up from the center
              const Spacer(flex: 2),

              // 1. Empty Cart Illustration (Placeholder for the actual image)
              // Note: Since you don't have the 3D cart image as an asset,
              // I'm replacing the previous Icon/Container with a simple Image.network
              // placeholder or leaving space for Image.asset.
              SizedBox(
                width: 150, // Space for the illustration
                height: 150,
                child: Image.asset("assets/cart.png"),
              ),
              const SizedBox(height: 32),

              // 2. Main Text
              Text(
                'Your Cart is empty',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: greenColor, // Text color matches the image's green
                ),
              ),

              // 3. Subtext (Removed as it's not present in the new image)
              // const SizedBox(height: 8),
              // const Text(
              //   'Add items to your cart to see them here',
              //   style: TextStyle(fontSize: 14, color: Colors.grey),
              // ),
              const SizedBox(height: 32),

              // 4. Continue Shopping Button
              SizedBox(
                width:
                    MediaQuery.of(context).size.width *
                    0.8, // Adjust width to match image size
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryGreenColor,
                    foregroundColor: Colors.white,
                    shadowColor: secondaryGreenColor.withValues(alpha: 0.5),
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Slightly rounded corners
                    ),
                  ),
                  child: const Text(
                    'Continue Shopping',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Flexible space to center the content above the bottom nav bar
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
