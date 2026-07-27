import 'package:flutter/material.dart';

/// The tiled grocery-doodle watermark used as the page background.
///
/// WHY THIS EXISTS
/// ---------------
/// `assets/bg.png` is 1572x1680. Decoded to RGBA that is ~10.5 MB resident —
/// about a tenth of Flutter's default 100 MB image cache — spent on a
/// background watermark, on nine different screens.
///
/// [ResizeImage] halves the decoded bitmap to 786x840 (~2.6 MB, a 4x saving)
/// and [DecorationImage.scale] compensates so the pattern still occupies the
/// same 1572x1680 *logical* pixels it did before. Tile size, alignment and
/// layout are therefore unchanged — the only difference is that the artwork is
/// upscaled 2x at paint time.
///
/// That is imperceptible here because the source is line art drawn at alpha 25
/// (~10%) and then composited at `opacity: 0.7`, i.e. a very faint watermark.
/// If it ever does look soft on a high-DPI tablet, set [_decodeWidthPx] to
/// [_sourceWidthPx] (which makes [_scale] 1.0) to restore the original decode.

/// Width the background is decoded at, in source pixels.
const int _decodeWidthPx = 786;

/// Intrinsic width of `assets/bg.png`, in pixels.
const int _sourceWidthPx = 1572;

/// Image pixels per logical pixel. Keeps the painted tile the same size on
/// screen regardless of what [_decodeWidthPx] is set to.
const double _scale = _decodeWidthPx / _sourceWidthPx;

/// Shared background decoration. Use this instead of hand-rolling a
/// `DecorationImage(image: AssetImage('assets/bg.png'), ...)`, so the asset is
/// decoded once at one size and shared across every screen via the image cache.
const DecorationImage kPatternBackgroundImage = DecorationImage(
  image: ResizeImage(
    AssetImage('assets/bg.png'),
    width: _decodeWidthPx,
    allowUpscaling: false,
  ),
  repeat: ImageRepeat.repeat,
  scale: _scale,
  opacity: 0.7,
);

/// White page background with the watermark on top.
const BoxDecoration kPatternBackgroundDecoration = BoxDecoration(
  color: Colors.white,
  image: kPatternBackgroundImage,
);

/// Watermark only, for screens that set their own background colour.
const BoxDecoration kPatternBackgroundDecorationNoColor = BoxDecoration(
  image: kPatternBackgroundImage,
);
