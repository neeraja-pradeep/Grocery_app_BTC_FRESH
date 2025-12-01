import 'package:flutter/material.dart';
import 'package:grocery_app/features/home/presentation/screen/home_screen.dart';
import 'package:grocery_app/features/home/presentation/screen/categories_with_sidebar_screen.dart';
import 'package:grocery_app/features/wishlist/presentation/screen/wishlist_screen.dart';
import 'package:grocery_app/features/home/presentation/screen/cart_screen.dart';
import 'package:grocery_app/features/profile/presentation/screen/profile_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  static const List<Widget> _pages = [
    HomeScreen(),
    CategoriesWithSidebarScreen(),
    WishlistScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNavBar(
        colorScheme: colorScheme,
        currentIndex: _currentIndex,
        onItemSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.colorScheme,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final ColorScheme colorScheme;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onItemSelected,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          label: 'Wishlist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
