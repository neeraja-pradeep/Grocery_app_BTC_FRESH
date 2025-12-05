// lib/features/wishlist/presentation/screen/wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../home/application/providers/home_provider.dart';
import '../../../home/domain/entities/product_variant.dart';
import '../../../home/presentation/components/advertisement_card.dart';
import '../../../home/presentation/components/product_card.dart';
import '../../application/providers/wishlist_provider.dart';
import '../../domain/entities/wishlist_item.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac),
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'My Wishlist',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        body: wishlistState.when(
          initial: () => const Center(child: CircularProgressIndicator()),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (failure, _) => Center(child: Text('Error: $failure')),
          refreshing: (items) => _buildContent(context, ref, items),
          loaded: (items, _) => _buildContent(context, ref, items),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<WishlistItem> items,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    // Convert wishlist items to product variants
    final products = items.map((item) => item.toProductVariant()).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),

          // Horizontal scrolling product list (same as Best Deals)
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              clipBehavior: Clip.none,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: ProductCard(
                    product: product,
                    onTap: () => _handleProductTap(context, product),
                    width: 140,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 24.h),

          // Advertisement Banner
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Consumer(
              builder: (context, ref, child) {
                final activeAd = ref.watch(activeAdProvider);
                if (activeAd != null) {
                  return AdvertisementCard(
                    banner: activeAd,
                    onShopNowClick: () => _handleShopNowClick(context),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          SizedBox(height: 80.h),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80.sp, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            'Your wishlist is empty',
            style: TextStyle(fontSize: 18.sp, color: Colors.grey),
          ),
          SizedBox(height: 32.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Consumer(
              builder: (context, ref, child) {
                final activeAd = ref.watch(activeAdProvider);
                if (activeAd != null) {
                  return AdvertisementCard(
                    banner: activeAd,
                    onShopNowClick: () => _handleShopNowClick(context),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleProductTap(BuildContext context, ProductVariant product) {
    Navigator.pushNamed(
      context,
      '/product-details',
      arguments: {'productId': product.productId, 'variantId': product.id},
    );
  }

  void _handleShopNowClick(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
