import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/colors.dart';
import '../../../domain/entities/product_variant.dart';

/// Product header with image gallery and wishlist button
class ProductHeader extends StatefulWidget {
  const ProductHeader({
    super.key,
    required this.productDetail,
    required this.isInWishlist,
    required this.onWishlistToggle,
  });

  final ProductVariant productDetail;
  final bool isInWishlist;
  final VoidCallback onWishlistToggle;

  @override
  State<ProductHeader> createState() => _ProductHeaderState();
}

class _ProductHeaderState extends State<ProductHeader>
    with TickerProviderStateMixin {
  late int _currentImageIndex;
  late PageController _pageController;
  late AnimationController _wishlistController;
  late Animation<double> _wishlistScale;

  @override
  void initState() {
    super.initState();
    _currentImageIndex = 0;
    _pageController = PageController();

    // Wishlist animation
    _wishlistController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _wishlistScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _wishlistController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(ProductHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInWishlist != oldWidget.isInWishlist) {
      _wishlistController.forward().then((_) {
        _wishlistController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _wishlistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = _getImages();

    return Column(
      children: [
        // Product image carousel
        Stack(
          children: [
            Container(
              height: 300.h,
              decoration: BoxDecoration(
                color: AppColors.green10,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: images.isNotEmpty
                  ? PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return _buildProductImage(images[index]);
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 80.sp,
                        color: AppColors.green100,
                      ),
                    ),
            ),
            // Wishlist button with scale animation
            Positioned(
              top: 12.h,
              right: 12.w,
              child: GestureDetector(
                onTap: widget.onWishlistToggle,
                child: ScaleTransition(
                  scale: _wishlistScale,
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.isInWishlist
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.isInWishlist
                          ? Colors.red
                          : AppColors.green100,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            // Image indicators (dots) with smooth animation
            if (images.length > 1)
              Positioned(
                bottom: 12.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => AnimatedContainer(
                        width: _currentImageIndex == index ? 24.w : 8.w,
                        height: 8.w,
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? AppColors.green
                              : AppColors.grey.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Build product image widget
  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Center(
        child: Icon(
          Icons.local_grocery_store_outlined,
          size: 80.sp,
          color: AppColors.green100,
        ),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, fit: BoxFit.cover);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 80.sp,
            color: AppColors.green100,
          ),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  /// Get list of product images
  List<String> _getImages() {
    final images = <String>[];

    // Add main image
    if (widget.productDetail.imageUrl?.isNotEmpty ?? false) {
      images.add(widget.productDetail.imageUrl!);
    }

    // Add thumbnail
    if (widget.productDetail.thumbnailUrl?.isNotEmpty ?? false) {
      images.add(widget.productDetail.thumbnailUrl!);
    }

    // Add gallery images
    if (widget.productDetail.images?.isNotEmpty ?? false) {
      images.addAll(widget.productDetail.images!);
    }

    return images;
  }
}
