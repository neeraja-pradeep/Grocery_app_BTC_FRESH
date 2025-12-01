import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:grocery_app/features/home/application/providers/simple_search_history.dart';
import 'package:grocery_app/features/home/application/providers/home_provider.dart';
import 'package:grocery_app/features/home/presentation/components/product_horizontal_list.dart';
import 'package:grocery_app/features/home/presentation/components/product_search_card.dart';
import 'package:grocery_app/features/home/domain/entities/product_variant.dart';
import 'package:grocery_app/features/home/domain/entities/product.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    // Add to search history for submitted searches
    await ref
        .read(simpleSearchHistoryProvider.notifier)
        .addSearch(query.trim());

    // Trigger search
    ref.read(searchProvider.notifier).startSearch(query.trim());
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      _debounceTimer?.cancel();
      ref.read(searchProvider.notifier).clearSearch();
      return;
    }

    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    // Start new timer for debounced search
    _debounceTimer = Timer(_debounceDuration, () {
      ref.read(searchProvider.notifier).startSearch(query.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final recentSearches = ref.watch(simpleSearchHistoryProvider);
    final homeState = ref.watch(homeProvider);
    final searchState = ref.watch(searchProvider);

    final trendingProducts = homeState.maybeMap(
      loaded: (state) => state.bestDeals,
      refreshing: (state) => state.bestDeals,
      orElse: () => <ProductVariant>[],
    );

    // Determine what to show based on search state and text field content
    final showSearchResults = searchState.maybeMap(
      loading: (_) => true,
      loaded: (_) => true,
      empty: (_) => true,
      error: (_) => true,
      orElse: () => false,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9dc08b), Color(0xFFbddec0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),

              // --- 1. HEADER SECTION (Back Arrow) ---
              Padding(
                padding: EdgeInsets.only(left: 16.w, bottom: 16.h),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    color: Colors.transparent,
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20.sp,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              // --- 2. SEARCH BAR SECTION ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Container(
                  height: 48.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[400], size: 24.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          style: TextStyle(fontSize: 14.sp),
                          decoration: InputDecoration(
                            hintText: "Search For 'Cooker'",
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14.sp,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(bottom: 4.h),
                          ),
                          onChanged: _onSearchChanged, // Real-time search
                          onSubmitted: _performSearch,
                        ),
                      ),
                      Container(
                        width: 1.w,
                        height: 24.h,
                        color: Colors.grey[300],
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.mic, color: Colors.black, size: 24.sp),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // --- 3. DYNAMIC CONTENT SECTION ---
              Expanded(
                child: showSearchResults
                    ? _buildSearchResults(searchState)
                    : _buildHistoryAndTrending(
                        recentSearches,
                        trendingProducts,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(searchState) {
    return searchState.when(
      initial: () => _buildHistoryAndTrending(
        ref.watch(simpleSearchHistoryProvider),
        ref
            .watch(homeProvider)
            .maybeMap(
              loaded: (state) => state.bestDeals,
              refreshing: (state) => state.bestDeals,
              orElse: () => <ProductVariant>[],
            ),
      ),
      listening: (isVoice) => const Center(child: CircularProgressIndicator()),
      loading: (query, isVoice) =>
          const Center(child: CircularProgressIndicator()),
      loaded: (query, results, hasMore, currentPage) =>
          _buildResultsList(results, hasMore),
      empty: (query) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'No products found for "$query"',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try searching with different keywords',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
      error: (failure, query) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red[400]),
            SizedBox(height: 16.h),
            Text(
              'Error searching for "$query"',
              style: TextStyle(fontSize: 16.sp, color: Colors.red[600]),
            ),
            SizedBox(height: 8.h),
            Text(
              failure.message,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _performSearch(_controller.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryAndTrending(
    List<String> recentSearches,
    List<ProductVariant> trendingProducts,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Recent Search Section ---
          if (recentSearches.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                "Recent Search",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: recentSearches.map((search) {
                  return GestureDetector(
                    onTap: () {
                      _controller.text = search;
                      _performSearch(search);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        search,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 24.h),
          ],

          // --- Trending Now Section ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              "Trending Now",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 12.h),

          if (trendingProducts.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                "No trending items right now.",
                style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
              ),
            )
          else
            ProductHorizontalList(
              products: trendingProducts,
              onProductClick: (product) {
                // Navigate to product detail
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<Product> products, bool hasMore) {
    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        bottom: 20.h, // Extra bottom padding for floating buttons
      ),
      itemCount: products.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == products.length) {
          // Load more indicator
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final product = products[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: 16.h,
          ), // Increased spacing for floating buttons
          child: ProductSearchCard(
            product: product,
            onTap: () {
              // Navigate to product detail
              // TODO: Implement navigation to product detail screen
            },
          ),
        );
      },
    );
  }
}
