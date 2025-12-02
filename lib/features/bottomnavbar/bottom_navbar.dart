import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/theme/colors.dart';
import '../../core/polling/polling_manager.dart';
import '../../core/polling/polling_tab_controller.dart';
import '../category/presentation/screen/category_screen.dart';
import '../cart/presentation/screen/cart_screen.dart';
import '../category/presentation/components/widgets/review_bottom_sheet.dart';
import '../home/presentation/screen/home_screen.dart';
import '../wishlist/presentation/screen/wishlist_screen.dart';
import '../profile/presentation/screen/profile_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  /// Global key to access BottomNavigation state from anywhere
  static final GlobalKey<BottomNavigationState> globalKey =
      GlobalKey<BottomNavigationState>();

  @override
  State<BottomNavigation> createState() => BottomNavigationState();
}

class BottomNavigationState extends State<BottomNavigation>
    with WidgetsBindingObserver {
  static const List<Widget> _pages = [
    CategoryScreen(),
    HomeScreen(),
    WishlistScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  int _currentIndex = 0;
  late final PollingTabController _pollingController;
  bool _showReviewSheetOnCategoryLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize PollingTabController to manage polling based on tab selection
    // Feature names must match the featureName used in registerPoller() calls:
    // - 'category_products' for CategoryProductController
    // - 'cart' for CheckoutLineController
    // - 'product_detail' is used when navigating to product details (handled separately)
    _pollingController = PollingTabController(
      tabToFeature: {
        0: 'category',
        1: 'home',
        2: 'wishlist',
        3: 'cart',
        4: 'profile',
      },
    );
    // Activate category tab initially
    _pollingController.selectTab(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes for polling
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - resume polling for the active feature
      PollingManager.instance.resumeActiveFeaturePolling();
    } else if (state == AppLifecycleState.paused) {
      // App went to background - pause all polling to save battery
      PollingManager.instance.pauseAllPolling();
    }
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
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person_outline,
            color: currentIndex == 4 ? AppColors.green100 : AppColors.black,
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}
