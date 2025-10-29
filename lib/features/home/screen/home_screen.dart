import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/features/category/presentation/components/_header.dart';
import 'package:grocery_app/features/category/presentation/components/category_list.dart';
import 'package:grocery_app/features/category/presentation/components/filter_bar.dart';
import 'package:grocery_app/features/category/presentation/components/product_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ProductGridState> _productGridKey =
      GlobalKey<ProductGridState>();
  static final List<CategoryItem> _categories = [
    const CategoryItem(
      title: 'Vegetables & Fruits',
      assetPath: 'assets/images/fruits.png',
    ),
    const CategoryItem(
      title: 'Dairy & Beverages',
      assetPath: 'assets/images/fruits.png',
    ),
    const CategoryItem(
      title: 'Grocery & Essentials',
      assetPath: 'assets/images/fruits.png',
    ),
    const CategoryItem(
      title: 'Packaged Food & Snacks',
      assetPath: 'assets/images/fruits.png',
    ),
    const CategoryItem(
      title: 'Fruits & Vegetables',
      assetPath: 'assets/images/fruits.png',
    ),
    const CategoryItem(title: 'Home & Kitchen Dining'),
    const CategoryItem(title: 'Personal Care & Hygiene'),
    const CategoryItem(title: 'Stationery & Office Supplies'),
  ];

  static const List<String> _filters = ['Brand', 'Price Drop', 'Popular'];

  int _selectedCategoryIndex = 0;
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.green10,

      bottomNavigationBar: _BottomNavBar(colorScheme: colorScheme),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 42.h, color: AppColors.green60),
          Header(colorScheme: colorScheme),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                // color: Colors.brown
                image: DecorationImage(
                  image: AssetImage('assets/images/background_graphics.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  //.................................. header
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CategoryList(
                                categories: _categories,
                                selectedIndex: _selectedCategoryIndex,
                                onCategorySelected: (index) {
                                  if (_selectedCategoryIndex != index) {
                                    setState(
                                      () => _selectedCategoryIndex = index,
                                    );
                                  }
                                  _productGridKey.currentState
                                      ?.scrollToCategory(index);
                                },
                              ), //................................. category list
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              AppSpacing.h4,

                              FilterBar(
                                filters: _filters,
                                selectedIndex: _selectedFilterIndex,
                                onFilterSelected: (index) => setState(
                                  () => _selectedFilterIndex = index,
                                ),
                                leadingIconAsset: 'assets/svgs/filter_icon.svg',
                              ),
                              AppSpacing.h4,

                              Expanded(
                                child: ProductGrid(
                                  key: _productGridKey,
                                  categories: _categories,
                                  selectedCategoryIndex: _selectedCategoryIndex,
                                  onCategoryInViewChanged: (index) {
                                    if (_selectedCategoryIndex != index) {
                                      setState(
                                        () => _selectedCategoryIndex = index,
                                      );
                                    }
                                  },
                                  onAddToCart: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (_) {},
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      showUnselectedLabels: true,
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
      ],
    );
  }
}
