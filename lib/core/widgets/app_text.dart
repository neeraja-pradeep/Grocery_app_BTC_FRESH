import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared text widget that encapsulates the default typography tokens.
class AppText extends StatelessWidget {
  const AppText({
    required this.text,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.color,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.height = 1.0,
    this.letterSpacing = 0.0,
    this.fontStyle = FontStyle.normal,
    this.decoration = TextDecoration.none,
    super.key,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;
  final double height;
  final double letterSpacing;
  final FontStyle fontStyle;
  final TextDecoration decoration;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.onSurface;

    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        height: height,
        letterSpacing: letterSpacing,
        color: resolvedColor,
        decoration: decoration,
      ),
    );
  }
}
