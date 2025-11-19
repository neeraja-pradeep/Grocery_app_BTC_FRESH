// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
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
import 'package:new_app/features/home/presentation/components/home_header.dart';
import 'package:new_app/features/home/presentation/components/search_bar.dart'; // Custom SearchBar
import 'package:new_app/features/home/presentation/components/section_header.dart';
import 'package:new_app/features/home/presentation/components/category_grid.dart';
import 'package:new_app/features/home/presentation/components/product_horizontal_list.dart';
import 'package:new_app/features/home/presentation/components/advertisement_card.dart';
import 'package:new_app/features/home/presentation/components/category_discount_section.dart';
import 'package:new_app/features/home/presentation/components/error_view.dart';

// Other Screens (For navigation)
import 'package:new_app/features/home/presentation/screen/search_results_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: SafeArea(
        child: homeState.when(
          initial: () => const Center(child: CircularProgressIndicator()),
          loading: () => const Center(child: CircularProgressIndicator()),

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
                return _buildLoadedContent(
                  categories: categories,
                  selectedAddress: address,
                  bestDeals: deals,
                  discountGroups: discounts,
                  activeAd: ad,
                );
              },

          // Refreshing State (Show content with loading indicator if needed, or just same as loaded)
          refreshing: (categories, address, deals, discounts, ad) {
            return _buildLoadedContent(
              categories: categories,
              selectedAddress: address,
              bestDeals: deals,
              discountGroups: discounts,
              activeAd: ad,
              isRefreshing: true,
            );
          },

          // Error State
          error: (failure, previousState) {
            return _buildErrorContent(failure, previousState);
          },
        ),
      ),
    );
  }

  Widget _buildLoadedContent({
    required List<Category> categories,
    required UserAddress? selectedAddress,
    required List<ProductVariant> bestDeals,
    required List<dynamic> discountGroups,
    required entities.Banner? activeAd,
    bool isRefreshing = false,
  }) {
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _handleRefresh,
      // Custom header for refresher can be added here
      child: CustomScrollView(
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

          // 2. Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CustomSearchBar(
                // Renamed to avoid conflict with Material SearchBar
                onTextSearch: _handleTextSearch,
                onVoiceSearch: _handleVoiceSearch,
              ),
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
                subtitle: '${bestDeals.length} products',
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
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: AdvertisementCard(
                  banner: activeAd, // Updated param name to match entity
                  onShopNowClick: () => _handleBannerClick(activeAd),
                ),
              ),
            ),

          // 6. Mega Fresh Offers Section Title
          if (discountGroups.isNotEmpty)
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'MEGA FRESH OFFERS',
                subtitle: 'Products with special discounts',
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
      ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.toString()), // Use proper failure message
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => ref.read(homeProvider.notifier).refresh(),
                ),
              ),
            );
          });

          return _buildLoadedContent(
            categories: state.categories,
            selectedAddress: state.selectedAddress,
            bestDeals: state.bestDeals,
            discountGroups: state.discountGroups,
            activeAd: state.activeAd,
          );
        },
        orElse: () => _buildFullErrorView(failure),
      );
    }

    // Critical error with no previous data
    return _buildFullErrorView(failure);
  }

  Widget _buildFullErrorView(Failure failure) {
    return ErrorView(
      message: failure.toString(),
      onRetry: () => ref.read(homeProvider.notifier).refresh(),
    );
  }

  // --- Handlers ---

  Future<void> _handleRefresh() async {
    await ref.read(homeProvider.notifier).refresh();
    _refreshController.refreshCompleted();
  }

  void _handleTextSearch(String query) {
    // TODO: Implement search functionality
    _navigateToSearchResults();
  }

  void _handleVoiceSearch() {
    // TODO: Implement voice search logic
    _navigateToSearchResults();
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

  void _navigateToSearchResults() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
    );
  }

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
