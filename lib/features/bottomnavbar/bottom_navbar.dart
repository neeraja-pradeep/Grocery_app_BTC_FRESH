import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/colors.dart';
import '../../core/polling/polling_manager.dart';
import '../../core/polling/polling_tab_controller.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/network_status_banner.dart';
import '../auth/application/providers/auth_provider.dart';
import '../auth/application/states/auth_state.dart';
import '../cart/application/providers/checkout_line_provider.dart';
import '../category/presentation/screen/category_screen.dart';
import '../cart/presentation/screen/cart_screen.dart';
import '../category/presentation/components/widgets/review_bottom_sheet.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../home/presentation/screen/home_screen.dart';
import '../wishlist/presentation/screen/wishlist_screen.dart';

class BottomNavigation extends ConsumerStatefulWidget {
  const BottomNavigation({super.key});

  /// Global key to access BottomNavigation state from anywhere
  static final GlobalKey<BottomNavigationState> globalKey =
      GlobalKey<BottomNavigationState>();

  @override
  ConsumerState<BottomNavigation> createState() => BottomNavigationState();
}

class BottomNavigationState extends ConsumerState<BottomNavigation>
    with WidgetsBindingObserver {
  int? _selectedCategoryId;
  late List<Widget> _pages;

  void navigateToCategories(int categoryId) {
    if (_tabHistory.isEmpty || _tabHistory.last != 1) {
      _tabHistory.add(1);
    }
    setState(() {
      _selectedCategoryId = categoryId;
      _currentIndex = 1;
      _visitedTabs.add(1);
      _pages[1] = CategoryScreen(
        key: ValueKey(categoryId),
        initialCategoryId: categoryId.toString(),
      );
    });
    _pollingController.selectTab(1);
  }

  /// Navigate to a specific tab by index
  void navigateToTab(int index) {
    if (index >= 0 && index < 4) {
      if (_tabHistory.isEmpty || _tabHistory.last != index) {
        _tabHistory.add(index);
      }
      setState(() {
        _currentIndex = index;
        _visitedTabs.add(index);
      });
      _pollingController.selectTab(index);
    }
  }

  int _currentIndex = 0;
  final List<int> _tabHistory = [0]; // Track navigation history
  // Tabs the user has actually visited. Unvisited tabs render as SizedBox in
  // the IndexedStack so their widget trees (and the per-category fetches the
  // Categories tab kicks off on mount) never run until the user goes there.
  final Set<int> _visitedTabs = {0};
  late final PollingTabController _pollingController;
  bool _showReviewSheetOnCategoryLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pages = [
      HomeScreen(onCategoryNavigate: navigateToCategories),
      CategoryScreen(
        key: ValueKey(_selectedCategoryId),
        initialCategoryId: _selectedCategoryId?.toString(),
      ),
      const WishlistScreen(),
      const CartScreen(),
    ];

    _pollingController = PollingTabController(
      tabToFeature: {
        0: 'home',
        1: 'category_products',
        2: 'wishlist',
        3: 'cart',
      },
    );

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
    if (state == AppLifecycleState.resumed) {
      PollingManager.instance.resumeActiveFeaturePolling();
    } else if (state == AppLifecycleState.paused) {
      PollingManager.instance.pauseAllPolling();
    }
  }

  void _onTabSelected(int index) {
    // Check if user is a guest
    final authState = ref.read(authProvider);
    final isGuest = authState is GuestMode;

    // Block wishlist (index 2) and cart (index 3) for guests
    if (isGuest && (index == 2 || index == 3)) {
      final featureName = index == 2 ? 'Wishlist' : 'Cart';
      AppSnackbar.info(context, 'Please login to access $featureName');
      // Navigate to OTP screen
      context.go('/otp');
      return;
    }

    if (_tabHistory.isEmpty || _tabHistory.last != index) {
      _tabHistory.add(index);
    }

    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
    _pollingController.selectTab(index);
  }

  void navigateToCategoryAndShowReview() {
    if (_tabHistory.isEmpty || _tabHistory.last != 1) {
      _tabHistory.add(1);
    }
    setState(() {
      _currentIndex = 1;
      _visitedTabs.add(1);
      _showReviewSheetOnCategoryLoad = true;
    });
    _pollingController.selectTab(1);

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

    // Allow exit only if on Home tab and no history to go back to
    final canExitApp = _tabHistory.length <= 1 && _currentIndex == 0;

    return PopScope(
      canPop: canExitApp,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // Already popped (exiting app)

        // Go back to previous tab in history
        if (_tabHistory.length > 1) {
          _tabHistory.removeLast(); // Remove current tab
          final previousTab = _tabHistory.last;

          setState(() => _currentIndex = previousTab);
          _pollingController.selectTab(previousTab);
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            const NetworkStatusBanner(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    _visitedTabs.contains(i)
                        ? _pages[i]
                        : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomNavBar(
          colorScheme: colorScheme,
          currentIndex: _currentIndex,
          onItemSelected: _onTabSelected,
        ),
      ),
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  const _BottomNavBar({
    required this.colorScheme,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final ColorScheme colorScheme;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch cart state to get item count
    final cartState = ref.watch(checkoutLineControllerProvider);
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState is! GuestMode;

    // Get total number of items in cart (only for authenticated users)
    final cartItemCount = isAuthenticated ? cartState.items.length : 0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -17),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -2),
            blurRadius: 11.9,
          ),
        ],
      ),
      child: SizedBox(
        height: 74.h,
        child: BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: currentIndex,
      onTap: onItemSelected,
      selectedItemColor: AppColors.green100,
      unselectedItemColor: AppColors.black,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svgs/nav_bar/home.svg',
            height: 20.h,
            width: 20.w,
            colorFilter: const ColorFilter.mode(
              AppColors.black,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: Image.asset(
            'assets/svgs/nav_bar/home_active.png',
            height: 20.h,
            width: 20.w,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svgs/nav_bar/categories.svg',
            height: 20.h,
            width: 20.w,
            colorFilter: const ColorFilter.mode(
              AppColors.black,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: Image.asset(
            'assets/svgs/nav_bar/category_active.png',
            height: 20.h,
            width: 20.w,
          ),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svgs/nav_bar/wishlist.svg',
            height: 20.h,
            width: 20.w,
            colorFilter: const ColorFilter.mode(
              AppColors.black,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: Image.asset(
            'assets/svgs/nav_bar/wishlist_active.png',
            height: 20.h,
            width: 20.w,
          ),
          label: 'Wishlist',
        ),
        BottomNavigationBarItem(
          icon: _buildCartIcon(isActive: false, itemCount: cartItemCount),
          activeIcon: _buildCartIcon(isActive: true, itemCount: cartItemCount),
          label: 'Cart',
        ),
      ],
        ),
      ),
    );
  }

  /// Builds cart icon with optional badge showing item count
  Widget _buildCartIcon({required bool isActive, required int itemCount}) {
    final icon = isActive
        ? Image.asset(
            'assets/svgs/nav_bar/cart_active.png',
            height: 20.h,
            width: 20.w,
          )
        : SvgPicture.asset(
            'assets/svgs/nav_bar/cart.svg',
            height: 20.h,
            width: 20.w,
            colorFilter: const ColorFilter.mode(
              AppColors.black,
              BlendMode.srcIn,
            ),
          );

    if (itemCount <= 0) {
      return icon;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8.w,
          top: -4.h,
          child: Container(
            padding: EdgeInsets.all(4.r),
            decoration: const BoxDecoration(
              color: AppColors.red,
              shape: BoxShape.circle,
            ),
            constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
            child: Text(
              itemCount > 99 ? '99+' : itemCount.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
