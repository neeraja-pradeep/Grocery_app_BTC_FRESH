// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart'; // Requires pull_to_refresh package

// Core & Domain
import 'package:new_app/core/error/failure.dart';
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

    // Optional: Log analytics event
    // Analytics.logEvent('home_screen_viewed');

    // Listen to scroll for "scroll to top" FAB or animations
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Can implement scroll-based animations here
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the HomeNotifier state
    final homeState = ref.watch(homeProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac), // Custom green color
        statusBarIconBrightness: Brightness.dark, // Dark icons
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50], // Light background
        body: SafeArea(
          child: SmartRefresher(
            controller: _refreshController,
            onRefresh: _handleRefresh,
            enablePullDown: true,
            enablePullUp: false, // Disable pull up to load more for now
            header: const WaterDropMaterialHeader(
              backgroundColor: Colors.green,
              color: Colors.white,
            ),
            child: homeState.when(
              initial: () => const CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              loading: () => const CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
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
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 2,
                        child: LinearProgressIndicator(
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
      controller: _scrollController,
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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: AdvertisementCard(
                banner: activeAd, // Updated param name to match entity
                onShopNowClick: () => _handleBannerClick(activeAd),
              ),
            ),
          ),

        // 6. Mega Fresh Offers Section Title
        if (discountGroups.isNotEmpty)
          const SliverToBoxAdapter(
            child: Center(
              child: Text(
                "Mega Fresh Offers",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff016064),
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
        const SliverToBoxAdapter(
          child: SizedBox(height: 80), // Space for bottom navigation
        ),
      ],
    );
  }

  Widget _buildErrorContent(Failure failure, HomeState? previousState) {
    // If we have previous data, show it with a snackbar error
    if (previousState != null) {
      // Use maybeMap to safely extract data from the previous state
      return previousState.maybeMap(
        loaded: (state) {
          // Schedule snackbar after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Update failed: ${failure.toString()}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () => ref.read(homeProvider.notifier).refresh(),
                  ),
                ),
              );
            }
          });

          return _buildScrollContent(
            categories: state.categories,
            selectedAddress: state.selectedAddress,
            bestDeals: state.bestDeals,
            discountGroups: state.discountGroups,
            activeAd: state.activeAd,
          );
        },
        refreshing: (state) {
          // If error occurred during refresh, show the data with error message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Refresh failed: ${failure.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () => _handleRefresh(),
                  ),
                ),
              );
            }
          });

          return _buildScrollContent(
            categories: state.categories,
            selectedAddress: state.selectedAddress,
            bestDeals: state.bestDeals,
            discountGroups: state.discountGroups,
            activeAd: state.activeAd,
          );
        },
        orElse: () => _buildFullErrorScrollView(failure),
      );
    }

    // Critical error with no previous data
    return _buildFullErrorScrollView(failure);
  }

  Widget _buildFullErrorScrollView(Failure failure) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          child: ErrorView(
            message: failure.toString(),
            onRetry: () => ref.read(homeProvider.notifier).refresh(),
          ),
        ),
      ],
    );
  }

  // --- Handlers ---

  Future<void> _handleRefresh() async {
    try {
      // Clear Hive cache before refreshing to ensure fresh data
      await ref.read(homeProvider.notifier).clearCacheAndRefresh();

      // Complete refresh successfully
      if (mounted) {
        _refreshController.refreshCompleted();
      }
    } catch (error) {
      // Handle refresh failure gracefully
      if (mounted) {
        _refreshController.refreshFailed();

        // Show error message to user with retry option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleRefresh(),
            ),
          ),
        );
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
    Navigator.pushNamed(
      context,
      '/category-products',
      arguments: {'categoryId': category.id},
    );
  }

  void _navigateToBestDeals() {
    Navigator.pushNamed(context, '/best-deals');
  }

  void _navigateToProductDetails(ProductVariant product) {
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
