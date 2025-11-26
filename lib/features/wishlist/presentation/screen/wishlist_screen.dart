// lib/features/wishlist/presentation/screen/wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:new_app/features/home/domain/entities/product_variant.dart';
import 'package:new_app/features/home/presentation/components/advertisement_card.dart';
import 'package:new_app/features/home/application/providers/home_provider.dart';
import 'package:new_app/features/wishlist/application/providers/wishlist_provider.dart';
import 'package:new_app/features/wishlist/domain/entities/wishlist_item.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac), // Custom green color
        statusBarIconBrightness: Brightness.dark, // Dark icons
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          children: [
            // Product Grid with fixed dimensions 140*215 (increased height for button space)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio:
                    140 / 215, // Increased height slightly for button space
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final wishlistItem = items[index];
                final productVariant = wishlistItem.toProductVariant();
                return SizedBox(
                  width: 140.w,
                  height: 215.h, // Increased height for button space
                  child: WishlistProductCard(
                    product: productVariant,
                    wishlistItem: wishlistItem,
                    onTap: () => _handleProductTap(context, productVariant),
                    ref: ref,
                  ),
                );
              },
            ),

            SizedBox(height: 24.h),

            // Advertisement Banner
            Consumer(
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

            SizedBox(height: 80.h),
          ],
        ),
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

// Wishlist Product Card matching the style from product_horizontal_list.dart
class WishlistProductCard extends StatelessWidget {
  final ProductVariant product;
  final WishlistItem wishlistItem;
  final VoidCallback onTap;
  final WidgetRef ref;

  const WishlistProductCard({
    super.key,
    required this.product,
    required this.wishlistItem,
    required this.onTap,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // Use imageUrl from wishlistItem if available, otherwise from product
    final String imageUrl = wishlistItem.imageUrl.isNotEmpty
        ? wishlistItem.imageUrl
        : (product.media.isNotEmpty ? product.media.first.imageUrl : '');

    // Colors matching product_horizontal_list.dart
    const Color borderColor = Color(0xFF8cc727);
    const Color cardBgColor = Color(0xFFe4fad5);
    const Color iconColor = Color(0xFF00695C);
    const Color priceColor = Color(0xFF2E7D32);

    // Define the button size
    final double buttonSize = 28.w;

    return SizedBox(
      child: Stack(
        clipBehavior: Clip.none, // Allow button to float outside
        children: [
          // MAIN CARD CONTENT
          GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Image Section
                    Container(
                      width: double.infinity,
                      height: 100.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.all(6.w),
                      child: Center(
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Center(
                                  child: SizedBox(
                                    height: 16.h,
                                    width: 16.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5.w,
                                      color: iconColor,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 24.sp,
                                ),
                              )
                            : Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 24.sp,
                              ),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // 2. Product Name
                    SizedBox(
                      height: 32.h,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // 3. Bottom Section
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "₹${product.hasDiscount ? product.discountedPrice?.toStringAsFixed(0) : product.price.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: priceColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  wishlistItem.unitLabel.isNotEmpty
                                      ? wishlistItem.unitLabel
                                      : (product.stockUnit ?? "80 g"),
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final wishlistNotifier = ref.read(
                                wishlistProvider.notifier,
                              );
                              await wishlistNotifier.toggleWishlist(
                                product.id.toString(),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(left: 4.w),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: Colors.red,
                                size: 18.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // FLOATING ADD BUTTON (+)
          // Now positioned outside the card with negative coordinates
          Positioned(
            top: -8.h, // Negative to float outside
            right: -8.w, // Negative to float outside
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added to cart'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: borderColor, width: 1.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(Icons.add, color: iconColor, size: 16.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
