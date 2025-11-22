// lib/features/home/presentation/screens/search_results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_app/features/home/application/providers/home_provider.dart';
import 'package:new_app/features/home/application/states/home_state.dart'; // Needed for HomeState
import 'package:new_app/features/home/domain/entities/product_variant.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // FIX: Safely extract query since it doesn't exist in all SearchStates (like Initial)
    final currentQuery = ref
        .read(searchProvider)
        .maybeMap(
          loading: (s) => s.query,
          loaded: (s) => s.query,
          empty: (s) => s.query,
          error: (s) => s.query,
          orElse: () => '',
        );

    _textController.text = currentQuery;

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      // Implement pagination loadMore if needed
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Debouncing is handled in the Notifier/Usecase, but we can trigger here
    ref.read(searchProvider.notifier).startSearch(query);
  }

  void _clearSearch() {
    _textController.clear();
    ref.read(searchProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final homeState = ref.watch(homeProvider); // To get "Trending" (Best Deals)

    // Theme colors extracted from image
    final backgroundColor = const Color(0xFFE6F8D6); // Light pastel green
    final searchBarColor = Colors.white;
    final chipColor = Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac), // Custom green color
        statusBarIconBrightness: Brightness.dark, // Dark icons
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // --- Custom Header & Search Bar ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row (Back Button)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search Input Field
                    Container(
                      decoration: BoxDecoration(
                        color: searchBarColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Search For 'Cooker'",
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon: _textController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.grey,
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : const Icon(Icons.mic, color: Colors.black87),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Body Content ---
              Expanded(
                child: searchState.when(
                  // 1. Initial / Idle State (Show History + Trending)
                  initial: () => _buildIdleView(homeState, chipColor),

                  // 2. Loading State
                  loading: (query, _) => _textController.text.isEmpty
                      ? _buildIdleView(
                          homeState,
                          chipColor,
                        ) // Show idle if text cleared fast
                      : const Center(child: CircularProgressIndicator()),

                  // 3. Active Search Results
                  loaded: (query, results, hasMore, page) =>
                      _buildResultsView(results),

                  // 4. Empty State
                  empty: (query) => _buildEmptyView(query),

                  // 5. Error State
                  error: (failure, query) =>
                      _buildErrorView(failure.toString()),

                  // 6. Voice Listening
                  listening: (_) => const Center(
                    child: Icon(Icons.mic, size: 64, color: Colors.green),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- View 1: Idle (Recent Searches + Trending) ---
  Widget _buildIdleView(HomeState homeState, Color chipColor) {
    // Hardcoded history for now as SearchState doesn't strictly expose it in all states
    final history = <String>['Good Knight', 'Cooker', 'Rice', 'Oil'];

    // Get Trending items from Home Provider (Best Deals)
    // Using maybeMap to safely extract bestDeals from HomeState
    final trendingProducts = homeState.maybeMap(
      loaded: (data) => data.bestDeals,
      refreshing: (data) => data.bestDeals,
      orElse: () => <ProductVariant>[],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Search Section
          if (history.isNotEmpty) ...[
            const Text(
              'Recent Search',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: history.map((term) {
                return ActionChip(
                  label: Text(term),
                  backgroundColor: chipColor,
                  elevation: 0,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelStyle: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                  onPressed: () {
                    _textController.text = term;
                    _onSearchChanged(term);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Trending Now Section
          const Text(
            'Trending Now',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          if (trendingProducts.isEmpty)
            const Text(
              "No trending items right now.",
              style: TextStyle(color: Colors.grey),
            ),

          if (trendingProducts.isNotEmpty)
            SizedBox(
              height: 220, // Height for product cards
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trendingProducts.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 150,
                      child: _buildTrendingCard(trendingProducts[index]),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --- View 2: Results List ---
  Widget _buildResultsView(List<ProductVariant> results) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTrendingCard(results[index], isFullWidth: true),
        );
      },
    );
  }

  // --- Helper Widgets ---

  Widget _buildTrendingCard(
    ProductVariant product, {
    bool isFullWidth = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Soft shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.network(
                      product.media.isNotEmpty
                          ? product.media.first.imageUrl
                          : '',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                // Add Button (Green +)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green, width: 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add, color: Colors.green, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Details Area
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),

                  // Price and Heart Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹ ${product.displayPrice}',
                            style: const TextStyle(
                              color: Color(0xFF0B7041), // Dark Green
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            product.stockUnit ?? '1 Unit',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Text(error, style: const TextStyle(color: Colors.red)),
    );
  }
}
