import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/colors.dart';
import '../../core/polling/polling_manager.dart';
import '../../core/polling/polling_tab_controller.dart';
import '../../core/widgets/app_snackbar.dart';
import '../auth/application/providers/auth_provider.dart';
import '../auth/application/states/auth_state.dart';
import '../category/presentation/screen/category_screen.dart';
import '../cart/presentation/screen/cart_screen.dart';
import '../category/presentation/components/widgets/review_bottom_sheet.dart';
import '../home/presentation/screen/home_screen.dart';
import '../wishlist/presentation/screen/wishlist_screen.dart';
import '../home/domain/entities/category.dart';

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

  void navigateToCategories(Category category) {
    setState(() {
      _selectedCategoryId = category.id;
      _currentIndex = 0;
    });
    _pollingController.selectTab(0);
  }

  List<Widget> get _pages {
    return [
      CategoryScreen(
        key: ValueKey(
          _selectedCategoryId,
        ), // Force rebuild when category changes
        initialCategoryId: _selectedCategoryId?.toString(),
      ),
      HomeScreen(onCategoryNavigate: navigateToCategories),
      const WishlistScreen(),
      const CartScreen(),
    ];
  }

  int _currentIndex = 0;
  late final PollingTabController _pollingController;
  bool _showReviewSheetOnCategoryLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pollingController = PollingTabController(
      tabToFeature: {
        0: 'category_products', // Matches CategoryProductController registration
        1: 'home',
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

    setState(() => _currentIndex = index);
    _pollingController.selectTab(index);
  }

  void navigateToCategoryAndShowReview() {
    setState(() {
      _currentIndex = 0;
      _showReviewSheetOnCategoryLoad = true;
    });
    _pollingController.selectTab(0);

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
            colorFilter: const ColorFilter.mode(
              AppColors.black,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: Image.asset(
            'assets/svgs/nav_bar/category_active.png',
            height: 24,
            width: 24,
          ),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svgs/nav_bar/home.svg',
            height: 24,
            width: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.black,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: Image.asset(
            'assets/svgs/nav_bar/home_active.png',
            height: 24,
            width: 24,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svgs/nav_bar/wishlist.svg',
            height: 24,
            width: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.black,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: Image.asset(
            'assets/svgs/nav_bar/wishlist_active.png',
            height: 24,
            width: 24,
          ),
          label: 'Wishlist',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svgs/nav_bar/cart.svg',
            height: 24,
            width: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.black,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: Image.asset(
            'assets/svgs/nav_bar/cart_active.png',
            height: 24,
            width: 24,
          ),
          label: 'Cart',
        ),
      ],
    );
  }
}
