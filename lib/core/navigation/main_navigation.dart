// lib/core/navigation/main_navigation.dart

import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../../features/home/presentation/screen/home_screen.dart';
import '../../features/home/presentation/screen/categories_with_sidebar_screen.dart';
import '../../features/wishlist/presentation/screen/wishlist_screen.dart';
import '../../features/home/presentation/screen/cart_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      HomeScreen(
        onCategoryNavigate: (category) {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      const CategoriesWithSidebarScreen(),
      const WishlistScreen(),
      const CartScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
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
