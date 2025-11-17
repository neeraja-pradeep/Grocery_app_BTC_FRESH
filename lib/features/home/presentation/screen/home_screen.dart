// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Local Component Imports ---
import 'package:new_app/features/home/presentation/components/home_app_bar.dart';
import 'package:new_app/features/home/presentation/components/category_grid.dart';
import 'package:new_app/features/home/presentation/components/mega_offers_section.dart';
import 'package:new_app/features/home/presentation/components/best_deals_strip.dart';
import 'package:new_app/features/home/presentation/screen/categories_screen.dart';

// --- Bootstrap Logic ---
import 'package:new_app/features/home/application/usecases/load_home_bootstrap_usecase.dart';
import 'package:new_app/features/home/application/providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Trigger data loading when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final bootstrap = ref.read(loadHomeBootstrapUsecaseProvider);
    await bootstrap.execute();
  }

  // --- Placeholder Interaction Handlers ---

  void _handleLocationTap() {
    // print('Location Chip Tapped');
  }

  void _handleProfileTap() {
    // print('Profile Icon Tapped');
  }

  void _handleSearchSubmit(String query) {
    if (query.isNotEmpty) {
      // print('Search Submitted: $query');
    }
  }

  void _handleVoiceSearchStart() {
    // print('Voice Search Started');
  }

  void _handleSeeAllCategories() {
    // Navigate to categories screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoriesScreen()),
    );
  }

  // void _handleCategoryTap() {
  //   print('Category Tapped:');
  // }

  // void _handleProductTap() {
  //   print('Product Tapped:');
  // }

  // void _handleSeeAllDeals() {
  //   print('See All Best Deals Tapped');
  // }

  @override
  Widget build(BuildContext context) {
    // Watch the catalog state to show loading/error states
    final catalogState = ref.watch(catalogControllerProvider);
    final bootstrapState = ref.watch(homeBootstrapControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(catalogState, bootstrapState),
    );
  }

  Widget _buildBody(catalogState, bootstrapState) {
    // Show error state only for critical errors
    if (catalogState.error != null) {
      return _buildErrorState(catalogState.error!);
    }

    // Show loading state during initial load
    if (bootstrapState.isInitialLoading) {
      return _buildLoadingState();
    }

    // Show empty state if no data and not loading
    if (!catalogState.hasData && bootstrapState.isBootComplete) {
      return _buildEmptyState();
    }

    // Show normal content
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        HomeAppBar(
          title: '',
          locationLabel: 'Calicut : Kuttikkattoor mavor',
          onLocationTap: _handleLocationTap,
          onProfileTap: _handleProfileTap,
          onSubmitSearch: _handleSearchSubmit,
          onStartVoiceSearch: _handleVoiceSearchStart,
          searchController: _searchController,
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 12),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white, // Ensure this matches the Container color
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(100.0), // Adjust radius as needed
                  topRight: Radius.circular(100.0), // Adjust radius as needed
                ),
              ),

              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Shop by Category',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        TextButton(
                          onPressed: _handleSeeAllCategories,
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xff5AC268),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const CategoryGrid(),
                    const SizedBox(height: 24),
                    const BestDealsStrip(),
                    const SizedBox(height: 24),
                    const MegaOffersSection(),
                    const SizedBox(height: 32),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your data...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Unable to load products at the moment.\nPlease check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Critical Error',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }
}
