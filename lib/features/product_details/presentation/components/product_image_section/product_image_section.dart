import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/app/theme/colors.dart';

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
  const ProductImageSection({
    super.key,
    required this.imageUrl,
    required this.isInWishlist,
    required this.onWishlistToggle,
  });

  final String? imageUrl;
  final bool isInWishlist;
  final VoidCallback onWishlistToggle;

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
    _initializeImages();
  }

  void _initializeImages() {
    _images = [];
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      _images.add(widget.imageUrl!);
    }
    // Add mock thumbnail images for demo (in real app, these would come from product data)
    if (_images.isNotEmpty) {
      _images.addAll([_images[0], _images[0]]);
    }
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
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
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
                width: 65.w,
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
                          width: 65.w,
                          height: 65.w,
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
