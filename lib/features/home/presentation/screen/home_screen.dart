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
import 'package:pull_to_refresh/pull_to_refresh.dart'; // Requires pull_to_refresh package

// Core & Domain
import 'package:new_app/core/error/failure.dart';
import 'package:new_app/core/utils/logger.dart';
import 'package:new_app/features/home/domain/entities/banner.dart' as entities;
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/product_variant.dart';
import 'package:new_app/features/home/domain/entities/user_address.dart';

// Application Layer
import 'package:new_app/features/home/application/providers/home_provider.dart';
import 'package:new_app/features/home/application/states/home_state.dart';

// Components (Assumed paths - update if different)
import 'package:new_app/features/home/presentation/components/home_header.dart'; // Custom SearchBar
import 'package:new_app/features/home/presentation/components/section_header.dart';
import 'package:new_app/features/home/presentation/components/category_grid.dart';
import 'package:new_app/features/home/presentation/components/product_horizontal_list.dart';
import 'package:new_app/features/home/presentation/components/advertisement_card.dart';
import 'package:new_app/features/home/presentation/components/category_discount_section.dart';
import 'package:new_app/features/home/presentation/components/error_view.dart';

// Other Screens (For navigation)
// import 'package:new_app/features/home/presentation/screen/search_results_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

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
          if (errorState.previousState != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${errorState.failure.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => ref.read(homeProvider.notifier).refresh(),
                ),
              ),
            );
          }
        },
      );
    });

    // Watch the HomeNotifier state
    final homeState = ref.watch(homeProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac), // Custom green color
        statusBarIconBrightness: Brightness.dark, // Dark icons
      ),
      child: Scaffold(
        key: const Key('home_screen_scaffold'), // Widget key for testing
        backgroundColor: Colors.grey[50], // Light background
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
                  return _buildErrorContent(failure, previousState);
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
            onProfileClick: _navigateToProfile,
          ),
        ),

        // 3. Shop by Category Section
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Shop by Category',
            onSeeAllClick: () => _navigateToCategoryList(),
          ),
        ),

        SliverToBoxAdapter(
          child: CategoryGrid(
            categories: categories.take(8).toList(), // Show 8 on home
            onCategoryClick: (category) =>
                _navigateToCategoryProducts(category),
          ),
        ),

        // 4. Best Deals Section
        if (bestDeals.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Best Deals',

              onSeeAllClick: () => _navigateToBestDeals(),
            ),
          ),

          SliverToBoxAdapter(
            child: ProductHorizontalList(
              products: bestDeals,
              onProductClick: (product) => _navigateToProductDetails(product),
            ),
          ),
        ],

        // 5. Advertisement Card
        if (activeAd != null)
          SliverToBoxAdapter(
            child: Padding(
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
            child: Center(
              child: Text(
                "Mega Fresh Offers",
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xff016064),
                ),
              ),
            ),
          ),

        // 7. Discounted products grouped by category
        ...discountGroups.map((group) {
          return SliverToBoxAdapter(
            child: CategoryDiscountSection(
              group: group,
              onProductClick: (product) => _navigateToProductDetails(product),
            ),
          );
        }),

        // 8. Bottom spacing
        SliverToBoxAdapter(
          child: SizedBox(height: 80.h), // Space for bottom navigation
        ),
      ],
    );
  }

  Widget _buildErrorContent(Failure failure, HomeState? previousState) {
    // If we have previous data, show it (SnackBar is handled by ref.listen above)
    if (previousState != null) {
      return previousState.maybeMap(
        loaded: (state) => _buildScrollContent(
          categories: state.categories,
          selectedAddress: state.selectedAddress,
          bestDeals: state.bestDeals,
          discountGroups: state.discountGroups,
          activeAd: state.activeAd,
        ),
        refreshing: (state) => _buildScrollContent(
          categories: state.categories,
          selectedAddress: state.selectedAddress,
          bestDeals: state.bestDeals,
          discountGroups: state.discountGroups,
          activeAd: state.activeAd,
        ),
        orElse: () => _buildFullErrorScrollView(failure),
      );
    }

    // Critical error with no previous data
    return _buildFullErrorScrollView(failure);
  }

  Widget _buildFullErrorScrollView(Failure failure) {
    // Analytics: Track error occurrence
    Logger.error(
      'Home screen error displayed',
      error: failure,
      data: {
        'failure_type': failure.runtimeType.toString(),
        'error_message': failure.toString(),
      },
    );

    return CustomScrollView(
      key: const Key('home_error_scroll'),
      slivers: [
        SliverFillRemaining(
          child: Semantics(
            label: 'Error loading home screen content',
            child: ErrorView(
              message: failure.toString(),
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
          'Home screen refresh',
          stopwatch.elapsed,
          data: {'success': true, 'cache_cleared': true},
        );
      }
    } catch (error, stackTrace) {
      // Handle refresh failure gracefully
      Logger.error(
        'Home screen refresh failed',
        error: error,
        stackTrace: stackTrace,
        data: {'duration_ms': stopwatch.elapsedMilliseconds},
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

    Navigator.pushNamed(
      context,
      '/category-products',
      arguments: {'categoryId': category.id},
    );
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

    Navigator.pushNamed(
      context,
      '/product-details',
      arguments: {'productId': product.productId, 'variantId': product.id},
    );
  }

  void _navigateToAddressSelection() {
    // Navigator.pushNamed(context, '/address-selection');
  }

  void _navigateToProfile() {
    // Navigator.pushNamed(context, '/profile');
  }
}
