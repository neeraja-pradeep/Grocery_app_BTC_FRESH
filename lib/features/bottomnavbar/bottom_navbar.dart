import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/theme/colors.dart';
import '../../core/polling/polling_tab_controller.dart';
import '../category/presentation/screen/category_screen.dart';
import '../cart/presentation/screen/cart_screen.dart';
import '../category/presentation/components/widgets/review_bottom_sheet.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  /// Global key to access BottomNavigation state from anywhere
  static final GlobalKey<BottomNavigationState> globalKey =
      GlobalKey<BottomNavigationState>();

  @override
  State<BottomNavigation> createState() => BottomNavigationState();
}

class BottomNavigationState extends State<BottomNavigation> {
  static const List<Widget> _pages = [
    CategoryScreen(),
    _PlaceholderPage(title: 'Home'),
    _PlaceholderPage(title: 'Wishlist'),
    CartScreen(),
  ];

  int _currentIndex = 0;
  late final PollingTabController _pollingController;
  bool _showReviewSheetOnCategoryLoad = false;

  @override
  void initState() {
    super.initState();
    // Initialize PollingTabController to manage polling based on tab selection
    _pollingController = PollingTabController(
      tabToFeature: {0: 'category', 1: 'home', 2: 'wishlist', 3: 'cart'},
    );
    // Activate category tab initially
    _pollingController.selectTab(0);
  }

  @override
  void dispose() {
    _pollingController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    // Notify polling controller about tab change
    _pollingController.selectTab(index);
  }

  /// Navigate to category tab and show review bottom sheet
  void navigateToCategoryAndShowReview() {
    setState(() {
      _currentIndex = 0;
      _showReviewSheetOnCategoryLoad = true;
    });
    _pollingController.selectTab(0);

    // Show the review bottom sheet after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showReviewSheetOnCategoryLoad && mounted) {
        _showReviewSheetOnCategoryLoad = false;
        ReviewBottomSheet.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNavBar(
        colorScheme: colorScheme,
        currentIndex: _currentIndex,
        onItemSelected: _onTabSelected,
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
