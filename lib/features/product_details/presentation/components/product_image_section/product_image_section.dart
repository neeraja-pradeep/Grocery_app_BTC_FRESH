import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';

import '../../../domain/entities/product_variant.dart';

/// ============================================================================
/// PRODUCT IMAGE SECTION - Media List Integration
/// ============================================================================
///
/// Data Flow:
/// 1. Variant API (GET /api/products/variants/{variant_id}/)
///    └─> imageUrl (single image for variant)
///
/// 2. Product API (GET /api/products/{product_id}/)
///    └─> media[] list with multiple images
///        • media[0] = MAIN image (shown large in center)
///        • media[1:] = THUMBNAILS (shown in right panel)
///
/// Image Priority:
/// • FIRST CHOICE: Use media[0] as main image if product API returns media list
/// • FALLBACK: Use imageUrl from variant API if product API has no media
/// • LAST RESORT: Duplicate main image for thumbnails if not enough images
///
/// User Interaction:
/// • Display main image at _images[0]
/// • Display thumbnails at _images[1], _images[2], ...
/// • Clicking thumbnail updates _currentImageIndex → main image updates
///
/// Logging:
/// • All logs tagged with name: 'ImageSection' for easy filtering
/// • Tracks data initialization and updates during polling
/// ============================================================================

/// Custom painter for curved bottom wave with green accent using circular arc
class ProductCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), whitePaint);

    // Main product image width (same as container image)
    double imageWidth = size.width * 0.53;

    // RADIUS — bigger means deeper curve
    double radius = imageWidth * 2.1;

    // CENTER — push down the arc
    double centerX = size.width / 2;

    double centerY = size.height * 1 - radius;

    final arcPaint = Paint()
      ..color = AppColors.green100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    Path path = Path();

    // ---- LOWER SMOOTH ARC ----
    path.addArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      math.pi * 1.25, // starting angle..............
      math.pi * 1.64, // how wide the curve spreads
    );

    canvas.drawPath(path, arcPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Product image section with main image on left, thumbnails on right
class ProductImageSection extends StatefulWidget {
  const ProductImageSection({super.key, required this.imageUrl, this.media});

  final String? imageUrl;
  final List<ProductVariantMedia>? media;

  @override
  State<ProductImageSection> createState() => _ProductImageSectionState();
}

class _ProductImageSectionState extends State<ProductImageSection> {
  late int _currentImageIndex;
  late List<String> _images;

  @override
  void initState() {
    super.initState();
    _currentImageIndex = 0;

    // Log what data is being passed to this widget
    developer.log(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
      'ProductImageSection INITIALIZED\n'
      '  imageUrl (from variant API): ${widget.imageUrl}\n'
      '  media list (from product API): ${widget.media?.length ?? 0} items\n'
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      name: 'ImageSection',
    );

    _initializeImages();
  }

  @override
  void didUpdateWidget(ProductImageSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if data changed during polling
    final imageUrlChanged = oldWidget.imageUrl != widget.imageUrl;
    final mediaChanged = oldWidget.media?.length != widget.media?.length;

    if (imageUrlChanged || mediaChanged) {
      developer.log(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        'ProductImageSection UPDATED (polling refresh)\n'
        '  imageUrl changed: $imageUrlChanged\n'
        '  media changed: $mediaChanged\n'
        '  new imageUrl: ${widget.imageUrl}\n'
        '  new media items: ${widget.media?.length ?? 0}\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        name: 'ImageSection',
      );
      _currentImageIndex = 0; // Reset to first image when data updates
      _initializeImages();
    }
  }

  void _initializeImages() {
    _images = [];

    // PRIORITY: Use media list from product API if available
    // media[0] is the main image, media[1:] are thumbnails
    if (widget.media != null && widget.media!.isNotEmpty) {
      developer.log(
        'ProductImageSection: Media list found with ${widget.media!.length} items from product API',
        name: 'ImageSection',
      );

      for (int i = 0; i < widget.media!.length; i++) {
        final mediaItem = widget.media![i];
        final externalUrl = mediaItem.externalUrl;
        final image = mediaItem.image;
        final imageUrl = externalUrl ?? image;

        developer.log(
          '🔍 ProductImageSection: Media[$i] URLs\n'
          '   externalUrl: $externalUrl\n'
          '   image: $image\n'
          '   Using: $imageUrl',
          name: 'ImageSection',
        );

        if (imageUrl.isNotEmpty && !_images.contains(imageUrl)) {
          _images.add(imageUrl);
          if (i == 0) {
            developer.log(
              '✓ ProductImageSection: Using media[0] as MAIN image: $imageUrl',
              name: 'ImageSection',
            );
          } else {
            developer.log(
              '✓ ProductImageSection: Added thumbnail media[$i]: $imageUrl',
              name: 'ImageSection',
            );
          }
        }
      }
    } else {
      developer.log(
        '⚠ ProductImageSection: Media list is null or empty - falling back to imageUrl',
        name: 'ImageSection',
      );

      // FALLBACK: Use imageUrl from variant API if media list is not available
      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
        _images.add(widget.imageUrl!);
        developer.log(
          '✓ ProductImageSection: Using imageUrl as fallback main image: ${widget.imageUrl}',
          name: 'ImageSection',
        );
      }
    }

    // IMPORTANT: Only show thumbnails if there are 2 or more images
    // If only 1 image, don't show thumbnail list
    // Don't duplicate images - use only what's in media list
    if (_images.length == 1) {
      developer.log(
        '📌 ProductImageSection: Only 1 image available - showing MAIN only (no thumbnails)',
        name: 'ImageSection',
      );
    } else if (_images.length > 1) {
      developer.log(
        '📌 ProductImageSection: ${_images.length} images available - showing MAIN + THUMBNAILS',
        name: 'ImageSection',
      );
    }

    developer.log(
      '═══ ProductImageSection: Total images: ${_images.length}\n    [0] (MAIN): ${_images.isNotEmpty ? _images[0] : "NONE"}\n    Thumbnails: ${_images.length > 1 ? _images.sublist(1).length : 0} (only shown if 2+)',
      name: 'ImageSection',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 280.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 80.sp,
          color: AppColors.green100,
        ),
      );
    }

    return CustomPaint(
      painter: ProductCardPainter(),
      child: Container(
        // color: Colors.grey,
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20.w, 11.h, 22.w, 35.h),
        child: Row(
          children: [
            // Main Product Image (centered)
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      width: 188.w,
                      height: 188.w,

                      child: ClipRRect(
                        child: Image.network(
                          _images[_currentImageIndex],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            developer.log(
                              'ProductImageSection: Failed to load main image at index $_currentImageIndex: ${_images[_currentImageIndex]}\nError: $error',
                              name: 'ImageSection',
                              error: error,
                              stackTrace: stackTrace,
                            );
                            return Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 60.sp,
                                color: AppColors.green100,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.w16,
            // Thumbnail Images (right side - vertical)
            if (_images.length > 1)
              SizedBox(
                width: 60.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_images.length - 1, (index) {
                    final imageIndex = index + 1;
                    final isSelected = _currentImageIndex == imageIndex;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _images.length - 2 ? 10.h : 0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _currentImageIndex = imageIndex);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.green100
                                  : AppColors.black,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Image.network(
                                  _images[imageIndex],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    developer.log(
                                      'ProductImageSection: Failed to load thumbnail at index $imageIndex: ${_images[imageIndex]}\nError: $error',
                                      name: 'ImageSection',
                                      error: error,
                                      stackTrace: stackTrace,
                                    );
                                    return Container(
                                      color: const Color(0xFFF0F5E8),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: AppColors.grey,
                                        size: 20.sp,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
