// lib/features/home/presentation/components/advertisement_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/banner.dart' as entities;

class AdvertisementCard extends StatelessWidget {
  final entities.Banner banner;
  final VoidCallback onShopNowClick;

  const AdvertisementCard({
    super.key,
    required this.banner,
    required this.onShopNowClick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            // 1. Background Image
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: banner.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 1080,
                maxWidthDiskCache: 1080,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),

            // 2. Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 3. Text Content (FIXED FOR OVERFLOW)
            Padding(
              // Reduced padding slightly to give more space to content
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use Expanded to force the text section to take available space
                  // and push the button to the bottom
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          banner.name,
                          maxLines: 2, // Enforce max lines
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Slightly smaller to fit better
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (banner.descriptionPlaintext != null) ...[
                          const SizedBox(height: 4), // Reduced gap
                          Text(
                            banner.descriptionPlaintext!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Button stays at the bottom
                  ElevatedButton(
                    onPressed: onShopNowClick,
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(120, 50),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      // Make button slightly more compact vertically
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Shop Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
