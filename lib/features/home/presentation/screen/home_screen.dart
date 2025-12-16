// lib/features/home/presentation/screens/home_screen.dart

/// HomeScreen - Main landing screen of the application
///
/// CACHING STRATEGY DOCUMENTATION:
/// ================================
///
/// 1. CATEGORIES: Cached for 1 hour (frequently accessed, rarely change)
///    - Cache Key: HiveKeys.homeCategories
///    - TTL: 1 hour
///    - Fallback: Stale cache on network error
///
/// 2. BEST DEALS: Cached for 10 minutes (price-sensitive, changes frequently)
///    - Cache Key: HiveKeys.homeBestDeals
///    - TTL: 10 minutes
///    - Fallback: Stale cache on network error
///
/// 3. DISCOUNTED PRODUCTS: Cached for 10 minutes (price-sensitive)
///    - Cache Key: Dynamic based on filters (parentCategory_ordering)
///    - TTL: 10 minutes
///    - Fallback: None (returns empty list)
///
/// 4. BANNERS: Cached for 30 minutes (marketing content, moderate change frequency)
///    - Cache Key: HiveKeys.homeAdvertisement
///    - TTL: 30 minutes
///    - Fallback: Stale cache on network error
///
/// 5. USER ADDRESS: Cached indefinitely (user-specific, rarely changes)
///    - Cache Key: HiveKeys.userSelectedAddress
///    - TTL: No expiration
///    - Fallback: None (returns null)
///
/// REFRESH STRATEGY:
/// - Pull-to-refresh clears ALL cache and fetches fresh data
/// - Auto-refresh on app resume (handled by provider)
/// - Graceful degradation with stale cache on network errors
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart'; // Requires pull_to_refresh package

// Core & Domain
import '../../../../core/error/failure.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/location/location_provider.dart';
import '../../domain/entities/banner.dart' as entities;
import '../../domain/entities/category.dart';
import '../../domain/entities/product_variant.dart';
import '../../domain/entities/user_address.dart';

// Application Layer
import '../../application/providers/home_provider.dart';
import '../../application/states/home_state.dart';
import '../../../cart/application/providers/checkout_line_provider.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';

// Components
import '../../../../core/widgets/app_snackbar.dart';
import '../components/home_header.dart';
import '../components/section_header.dart';
import '../components/category_grid.dart';
import '../components/product_horizontal_list.dart';
import '../components/advertisement_card.dart';
import '../components/category_discount_section.dart';
import '../components/error_view.dart';

// Other Screens (For navigation)
import '../../../profile/presentation/screen/profile_screen.dart';
import '../../../address/presentation/screens/address_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final ValueChanged<Category> onCategoryNavigate;
  const HomeScreen({super.key, required this.onCategoryNavigate});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  late final RefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController(initialRefresh: false);

    // Analytics: Track screen view
    Logger.info(
      'Home screen viewed',
      data: {
        'timestamp': DateTime.now().toIso8601String(),
        'user_session': 'active',
      },
    );

    // Initialize location on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).initialize();
    });

    // Listen to scroll for "scroll to top" FAB or animations
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Analytics: Track scroll behavior for UX insights
    final scrollPosition = _scrollController.position;
    if (scrollPosition.pixels > 0 && scrollPosition.pixels % 1000 < 50) {
      Logger.debug(
        'User scrolled',
        data: {
          'scroll_position': scrollPosition.pixels.round(),
          'max_scroll': scrollPosition.maxScrollExtent.round(),
          'scroll_percentage':
              ((scrollPosition.pixels / scrollPosition.maxScrollExtent) * 100)
                  .round(),
        },
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state changes to handle side effects (SnackBars)
    ref.listen<HomeState>(homeProvider, (previous, next) {
      next.mapOrNull(
        error: (errorState) {
          // Only show SnackBar if we have previous data (partial failure)
          if (errorState.previousState != null && context.mounted) {
            AppSnackbar.error(
              context,
              'Unable to refresh data. Please check your connection.',
            );
          }
        },
      );
    });

    // Watch the HomeNotifier state
    final homeState = ref.watch(homeProvider);

    // Check if user is in guest mode
    final authState = ref.watch(authProvider);
    final isGuest = authState is GuestMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac), // Custom green color
        statusBarIconBrightness: Brightness.dark, // Dark icons
      ),
      child: Scaffold(
        key: const Key('home_screen_scaffold'), // Widget key for testing
        backgroundColor: const Color(
          0xFFcaf5ac,
        ), // Green header color for rounded corner effect
        body: SafeArea(
          child: SmartRefresher(
            key: const Key('home_screen_refresher'), // Widget key for testing
            controller: _refreshController,
            onRefresh: _handleRefresh,
            enablePullDown: true,
            enablePullUp: false, // Disable pull up to load more for now
            header: const WaterDropMaterialHeader(
              backgroundColor: Colors.green,
              color: Colors.white,
            ),
            child: Semantics(
              label: 'Home screen content',
              child: homeState.when(
                initial: () => CustomScrollView(
                  key: const Key('home_loading_initial'),
                  slivers: [
                    SliverFillRemaining(
                      child: Center(
                        child: Semantics(
                          label: 'Loading home screen content',
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => CustomScrollView(
                  key: const Key('home_loading'),
                  slivers: [
                    SliverFillRemaining(
                      child: Center(
                        child: Semantics(
                          label: 'Loading home screen content',
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ],
                ),

                // Success State
                loaded:
                    (
                      categories,
                      address,
                      deals,
                      discounts,
                      ad,
                      catLoad,
                      dealLoad,
                      discLoad,
                    ) {
                      // Analytics: Track successful load
                      Logger.info(
                        'Home screen loaded successfully',
                        data: {
                          'categories_count': categories.length,
                          'deals_count': deals.length,
                          'discount_groups_count': discounts.length,
                          'has_address': address != null,
                          'has_ad': ad != null,
                        },
                      );

                      return _buildScrollContent(
                        categories: categories,
                        selectedAddress: address,
                        bestDeals: deals,
                        discountGroups: discounts,
                        activeAd: ad,
                        isGuest: isGuest,
                      );
                    },

                // Refreshing State (Show content with loading indicator)
                refreshing: (categories, address, deals, discounts, ad) {
                  return Stack(
                    children: [
                      _buildScrollContent(
                        categories: categories,
                        selectedAddress: address,
                        bestDeals: deals,
                        discountGroups: discounts,
                        activeAd: ad,
                        isRefreshing: true,
                        isGuest: isGuest,
                      ),
                      // Optional: Show a subtle loading indicator at the top
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: 2.h,
                          child: const LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },

                // Error State
                error: (failure, previousState) {
                  return _buildErrorContent(failure, previousState, isGuest);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollContent({
    required List<Category> categories,
    required UserAddress? selectedAddress,
    required List<ProductVariant> bestDeals,
    required List<dynamic> discountGroups,
    required entities.Banner? activeAd,
    bool isRefreshing = false,
    required bool isGuest,
  }) {
    return CustomScrollView(
      key: const Key('home_content_scroll'),
      controller: _scrollController,
      semanticChildCount: _calculateSemanticChildCount(
        categories,
        bestDeals,
        discountGroups,
        activeAd,
      ),
      slivers: [
        // 1. Header with Logo + Address + Profile
        SliverToBoxAdapter(
          child: HomeHeader(
            address: selectedAddress,
            onAddressClick: _navigateToAddressSelection,
            onProfileClick: isGuest ? _navigateToLogin : _navigateToProfile,
            isGuest: isGuest,
          ),
        ),

        // 3. Shop by Category Section - with rounded top corners
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.h),
                topRight: Radius.circular(24.h),
              ),
            ),
            child: Column(
              children: [
                SectionHeader(
                  title: 'Shop by Category',
                  onSeeAllClick: () => _navigateToCategoryList(),
                ),
                CategoryGrid(
                  categories: categories.take(8).toList(), // Show 8 on home
                  onCategoryClick: (category) =>
                      _navigateToCategoryProducts(category),
                ),
              ],
            ),
          ),
        ),

        // 4. Best Deals Section
        if (bestDeals.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: SectionHeader(
                title: 'Best Deals',
                onSeeAllClick: () => _navigateToBestDeals(),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: ProductHorizontalList(
                products: bestDeals,
                onProductClick: (product) => _navigateToProductDetails(product),
              ),
            ),
          ),
        ],

        // 5. Advertisement Card
        if (activeAd != null)
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
              child: AdvertisementCard(
                banner: activeAd, // Updated param name to match entity
                onShopNowClick: () => _handleBannerClick(activeAd),
              ),
            ),
          ),

        // 6. Mega Fresh Offers Section Title
        if (discountGroups.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Text(
                  'MEGA FRESH OFFERS',
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff016064),
                  ),
                ),
              ),
            ),
          ),

        // 7. Discounted products grouped by category
        ...discountGroups.map((group) {
          return SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: CategoryDiscountSection(
                onAddToCart: _handleAddToCart,
                group: group,
                onProductClick: (product) => _navigateToProductDetails(product),
              ),
            ),
          );
        }),

        // 8. Bottom spacing
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            height: 80.h, // Space for bottom navigation
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(
    Failure failure,
    HomeState? previousState,
    bool isGuest,
  ) {
    // If we have previous data, show it (SnackBar is handled by ref.listen above)
    if (previousState != null) {
      return previousState.maybeMap(
        loaded: (state) => _buildScrollContent(
          categories: state.categories,
          selectedAddress: state.selectedAddress,
          bestDeals: state.bestDeals,
          discountGroups: state.discountGroups,
          activeAd: state.activeAd,
          isGuest: isGuest,
        ),
        refreshing: (state) => _buildScrollContent(
          categories: state.categories,
          selectedAddress: state.selectedAddress,
          bestDeals: state.bestDeals,
          discountGroups: state.discountGroups,
          activeAd: state.activeAd,
          isGuest: isGuest,
        ),
        orElse: () => _buildFullErrorScrollView(failure),
      );
    }

    // Critical error with no previous data
    return _buildFullErrorScrollView(failure);
  }

  Widget _buildFullErrorScrollView(Failure failure) {
    // Log technical details for debugging (not shown to user)
    Logger.error(
      'Home screen error: ${failure.runtimeType} - ${failure.message}',
      error: failure,
    );

    return CustomScrollView(
      key: const Key('home_error_scroll'),
      slivers: [
        SliverFillRemaining(
          child: Semantics(
            label: 'Error loading home screen content',
            child: ErrorView(
              message: _getUserFriendlyMessage(failure),
              onRetry: () {
                Logger.info('User tapped retry on home screen error');
                ref.read(homeProvider.notifier).refresh();
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Convert technical failures to user-friendly messages
  String _getUserFriendlyMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'No internet connection. Please check your network and try again.';
    } else if (failure is TimeoutFailure) {
      return 'Request timed out. Please check your connection and try again.';
    } else if (failure is ServerFailure) {
      return 'Unable to connect to server. Please try again later.';
    } else if (failure is DataParsingFailure) {
      return 'Something went wrong. Please try again later.';
    } else {
      // Use the displayMessage from the Failure class
      return failure.displayMessage;
    }
  }

  /// Calculate semantic child count for accessibility
  int _calculateSemanticChildCount(
    List<Category> categories,
    List<ProductVariant> bestDeals,
    List<dynamic> discountGroups,
    entities.Banner? activeAd,
  ) {
    int count = 2; // Header + Category section header
    count += (categories.length / 2).ceil(); // Category grid (2 per row)

    if (bestDeals.isNotEmpty) {
      count += 2; // Best deals header + horizontal list
    }

    if (activeAd != null) {
      count += 1; // Advertisement card
    }

    if (discountGroups.isNotEmpty) {
      count += 1 + discountGroups.length; // Title + discount sections
    }

    return count;
  }

  // --- Handlers ---

  Future<void> _handleRefresh() async {
    final stopwatch = Stopwatch()..start();

    try {
      Logger.info('User initiated home screen refresh');

      // Clear Hive cache before refreshing to ensure fresh data
      await ref.read(homeProvider.notifier).clearCacheAndRefresh();

      // Complete refresh successfully
      if (mounted) {
        _refreshController.refreshCompleted();
        Logger.performance(
          'Home screen refresh completed in ${stopwatch.elapsedMilliseconds}ms',
          data: {'success': true, 'cache_cleared': true},
        );
      }
    } catch (error, stackTrace) {
      // Handle refresh failure gracefully
      Logger.error(
        'Home screen refresh failed after ${stopwatch.elapsedMilliseconds}ms: $error\n$stackTrace',
        error: error,
      );

      if (mounted) {
        _refreshController.refreshFailed();
        // Error SnackBar will be shown by ref.listen when state changes to error
      }
    }
  }

  void _handleBannerClick(entities.Banner banner) {
    // Handle navigation based on banner type
    if (banner.productVariantId != null) {
      // Navigate to variant
    } else if (banner.categoryId != null) {
      // Navigate to category
    }
  }

  // --- Navigation ---

  // void _navigateToSearchResults() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
  //   );
  // }

  void _navigateToCategoryList() {
    // print("_navigateToCategoryList()");
  }

  void _navigateToCategoryProducts(Category category) {
    Logger.info(
      'User navigated to category products',
      data: {
        'category_id': category.id,
        'category_name': category.name,
        'category_slug': category.slug,
      },
    );

    widget.onCategoryNavigate(category);
  }

  void _navigateToBestDeals() {
    Logger.info('User navigated to best deals');
    Navigator.pushNamed(context, '/best-deals');
  }

  void _navigateToProductDetails(ProductVariant product) {
    Logger.info(
      'User navigated to product details',
      data: {
        'product_id': product.productId,
        'variant_id': product.id,
        'product_name': product.name,
        'price': product.price,
        'discounted_price': product.discountedPrice,
      },
    );

    context.push('/product-details/${product.id}');
  }

  void _navigateToAddressSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressListScreen()),
    ).then((_) {
      // Refresh home data after returning from address selection
      // to update the displayed address
      ref.read(homeProvider.notifier).refresh();
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToLogin() {
    context.go('/otp');
  }

  Future<void> _handleAddToCart(ProductVariant product) async {
    // Block guests from adding to cart
    final authState = ref.read(authProvider);
    final isGuest = authState is GuestMode;

    if (isGuest) {
      AppSnackbar.info(context, 'Please login to add items to cart');
      return;
    }

    try {
      await ref
          .read(checkoutLineControllerProvider.notifier)
          .addToCart(productVariantId: product.id, quantity: 1);

      if (mounted) {
        AppSnackbar.success(context, '${product.name} added to cart');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Unable to add item to cart');
      }
    }
  }
}
