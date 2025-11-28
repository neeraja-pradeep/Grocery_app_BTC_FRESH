import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/features/category/presentation/screen/category_screen.dart';
import 'package:grocery_app/features/cart/presentation/screen/cart_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  static const List<Widget> _pages = [
    CategoryScreen(),
    _PlaceholderPage(title: 'Home'),
    _PlaceholderPage(title: 'Wishlist'),
    CartScreen(),
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
      selectedItemColor: AppColors.green100,
      unselectedItemColor: AppColors.black,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svgs/nav_bar/categories.svg',
            height: 24,
            width: 24,
            colorFilter: ColorFilter.mode(
              currentIndex == 0 ? AppColors.green100 : AppColors.black,
              BlendMode.srcIn,
            ),
          ),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svgs/nav_bar/home.svg',
            height: 24,
            width: 24,
            colorFilter: ColorFilter.mode(
              currentIndex == 1 ? AppColors.green100 : AppColors.black,
              BlendMode.srcIn,
            ),
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svgs/nav_bar/wishlist.svg',
            height: 24,
            width: 24,
            colorFilter: ColorFilter.mode(
              currentIndex == 2 ? AppColors.green100 : AppColors.black,
              BlendMode.srcIn,
            ),
          ),
          label: 'Wishlist',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svgs/nav_bar/cart.svg',
            height: 24,
            width: 24,
            colorFilter: ColorFilter.mode(
              currentIndex == 3 ? AppColors.green100 : AppColors.black,
              BlendMode.srcIn,
            ),
          ),
          label: 'Cart',
        ),
      ],
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title));
  }
}
