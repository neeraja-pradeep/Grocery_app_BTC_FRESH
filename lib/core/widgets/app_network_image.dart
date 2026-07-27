import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// Shared network image widget for every remote image in the app.
///
/// WHY THIS EXISTS
/// ---------------
/// Raw `Image.network` / `NetworkImage` has two properties that are very
/// expensive on a product grid:
///
///  1. No disk cache — the bytes are re-downloaded on every cold start and
///     again whenever Flutter's in-memory `ImageCache` evicts the entry.
///  2. No decode bound — a 1000x1000 JPEG is decoded at full resolution even
///     when it is painted into a 130x170 dp card. That is ~4 MB of RAM per
///     image, so ~25 product photos fill the default 100 MB image cache and
///     the grid starts thrashing (evict -> re-download -> re-decode) while
///     the user scrolls.
///
/// [AppNetworkImage] fixes both: it delegates to [CachedNetworkImage] for the
/// disk cache and always passes a decode bound derived from the box the image
/// is actually painted into.
///
/// USAGE
/// -----
/// Pass the layout size when you know it — that is what the decode bound is
/// derived from:
///
/// ```dart
/// AppNetworkImage(imageUrl: product.imageUrl, width: 130, height: 170)
/// ```
///
/// When the widget is laid out by its parent (e.g. inside `Positioned.fill`)
/// leave the sizes null and pass [decodeWidth] with a rough upper bound of the
/// painted width in logical pixels.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.decodeWidth,
    this.placeholder,
    this.errorWidget,
    this.httpHeaders,
    this.alignment = Alignment.center,
    super.key,
  });

  /// Remote URL, a bundled `assets/...` path, or null/empty for the fallback.
  final String? imageUrl;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// Upper bound of the painted width in *logical* pixels. Only needed when
  /// [width] is null (parent-driven layout). Ignored when [width] is set.
  final double? decodeWidth;

  final Widget? placeholder;
  final Widget? errorWidget;
  final Map<String, String>? httpHeaders;
  final Alignment alignment;

  /// Hard ceiling on the decoded width in physical pixels.
  ///
  /// Nothing in this app paints an image wider than the screen, and phones cap
  /// out around 1440 physical px. Anything above this is wasted memory, so we
  /// clamp even when a caller asks for more.
  static const int _maxDecodeWidthPx = 1080;

  /// Fallback decode bound for images with no size information at all.
  static const double _defaultDecodeWidth = 400;

  /// Resolves the decode width in physical pixels for the current display.
  int _resolveCacheWidth(BuildContext context) {
    final logicalWidth = width ?? decodeWidth ?? _defaultDecodeWidth;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final physicalWidth = (logicalWidth * devicePixelRatio).round();

    if (physicalWidth <= 0) return _maxDecodeWidthPx;
    return physicalWidth.clamp(1, _maxDecodeWidthPx);
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    if (url == null || url.trim().isEmpty) {
      return _fallback(isError: false);
    }

    // Some payloads hand back bundled asset paths rather than URLs.
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => _fallback(isError: true),
      );
    }

    final cacheWidth = _resolveCacheWidth(context);

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      httpHeaders: httpHeaders,
      // Bound the in-memory decode. Height is left unbounded so the aspect
      // ratio is preserved.
      memCacheWidth: cacheWidth,
      // Bound what is written to the disk cache too, so the on-disk copy is
      // not a full-resolution original either.
      maxWidthDiskCache: _maxDecodeWidthPx,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => placeholder ?? _placeholder(),
      errorWidget: (_, _, _) => errorWidget ?? _fallback(isError: true),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.green10,
    );
  }

  Widget _fallback({required bool isError}) {
    return Container(
      width: width,
      height: height,
      color: isError ? AppColors.green10 : const Color.fromARGB(189, 239, 244, 235),
      alignment: Alignment.center,
      child: Icon(
        isError ? Icons.broken_image_outlined : Icons.local_grocery_store_outlined,
        size: 28,
        color: AppColors.green100,
      ),
    );
  }
}
