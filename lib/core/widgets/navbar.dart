// lib/core/widgets/navbar.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Define custom colors to match the image
  static const Color selectedColor = Color(
    0xFF00897B,
  ); // Dark Teal/Green color from image
  static const Color unselectedColor = Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 1. Add BoxDecoration for rounded corners and elevation
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            spreadRadius: 2.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: BottomNavigationBar(
        // Remove default elevation since the Container handles the shadow
        elevation: 0,
        backgroundColor: Colors
            .transparent, // Important: makes the Container's color visible

        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: onTap,

        // 3. Update Colors: Selected color applied to the icon/label for the current index
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        selectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 11.sp),

        items: [
          // Home
          BottomNavigationBarItem(
            icon: Icon(currentIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Home',
          ),
          // Categories
          BottomNavigationBarItem(
            icon: Icon(
              currentIndex == 1 ? Icons.apps : Icons.apps_outlined,
            ), // Solid grid icon when selected
            label: 'Categories',
          ),
          // Wishlist (Targeted change: Solid heart if currentIndex is 2, else outlined)
          BottomNavigationBarItem(
            icon: Icon(
              currentIndex == 2 ? Icons.favorite : Icons.favorite_border,
            ),
            label: 'Wishlist',
          ),
          // Cart
          BottomNavigationBarItem(
            icon: Icon(
              currentIndex == 3
                  ? Icons.shopping_cart
                  : Icons.shopping_cart_outlined,
            ),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}
