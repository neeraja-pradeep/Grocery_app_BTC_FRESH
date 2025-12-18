// lib/features/wishlist/presentation/screen/wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/socket_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../home/application/providers/home_provider.dart';
import '../../../home/domain/entities/product_variant.dart';
import '../../../home/presentation/components/advertisement_card.dart';
import '../../../home/presentation/components/product_card.dart';
import '../../application/providers/wishlist_provider.dart';
import '../../domain/entities/wishlist_item.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  final Set<int> _joinedRooms = {};

  @override
  void initState() {
    super.initState();
    // Join socket rooms after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _joinWishlistItemRooms();
      }
    });
  }

  @override
  void dispose() {
    _leaveAllRooms();
    super.dispose();
  }

  /// Join socket rooms for all wishlist items to receive real-time price updates
  void _joinWishlistItemRooms() {
    final wishlistState = ref.read(wishlistProvider);

    wishlistState.maybeWhen(
      loaded: (items, _) {
        final socketService = ref.read(socketServiceProvider);
        for (final item in items) {
          final variantId = int.tryParse(item.productId) ?? 0;
          if (variantId > 0 && !_joinedRooms.contains(variantId)) {
            socketService.joinVariantRoom(variantId);
            _joinedRooms.add(variantId);
          }
        }
      },
      refreshing: (items) {
        final socketService = ref.read(socketServiceProvider);
        for (final item in items) {
          final variantId = int.tryParse(item.productId) ?? 0;
          if (variantId > 0 && !_joinedRooms.contains(variantId)) {
            socketService.joinVariantRoom(variantId);
            _joinedRooms.add(variantId);
          }
        }
      },
      orElse: () {},
    );
  }

  /// Leave all joined rooms
  void _leaveAllRooms() {
    if (_joinedRooms.isEmpty) return;

    final socketService = ref.read(socketServiceProvider);
    for (final variantId in _joinedRooms) {
      socketService.leaveVariantRoom(variantId);
    }
    _joinedRooms.clear();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistState = ref.watch(wishlistProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac),
        statusBarIconBrightness: Brightness.dark,
      ),
      child: SafeArea(
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
            error: (failure, _) => _WishlistErrorView(failure: failure),
            refreshing: (items) => _buildContent(context, ref, items),
            loaded: (items, _) => _buildContent(context, ref, items),
          ),
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
    context.push('/product-details/${product.id}');
  }

  void _handleShopNowClick(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

/// Error view widget for wishlist screen
class _WishlistErrorView extends ConsumerWidget {
  final Failure failure;

  const _WishlistErrorView({required this.failure});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Log technical details for debugging (not shown to user)
    Logger.error(
      'Wishlist error: ${failure.runtimeType} - ${failure.message}',
      error: failure,
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48.sp,
                color: Colors.red.shade400,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Unable to load wishlist',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _getUserFriendlyMessage(failure),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                Logger.info('User tapped retry on wishlist error');
                ref.read(wishlistProvider.notifier).refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: Icon(Icons.refresh, size: 20.sp),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
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
    } else if (failure is NotAuthenticatedFailure) {
      return 'Please log in to view your wishlist.';
    } else {
      // Use the displayMessage from the Failure class
      return failure.displayMessage;
    }
  }
}
