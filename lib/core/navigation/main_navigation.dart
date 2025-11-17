// lib/core/navigation/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:new_app/core/widgets/navbar.dart';
import 'package:new_app/features/home/presentation/screen/home_screen.dart';
import 'package:new_app/features/home/presentation/screen/categories_with_sidebar_screen.dart';
import 'package:new_app/features/wishlist/presentation/screen/wishlist_screen.dart';
import 'package:new_app/features/home/presentation/screen/cart_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoriesWithSidebarScreen(),
    const WishlistScreen(),
    const CartScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
