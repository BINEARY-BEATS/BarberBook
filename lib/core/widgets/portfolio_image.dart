import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Renders portfolio images stored as HTTP URLs or Firestore data-URIs.
class PortfolioImage extends StatelessWidget {
  const PortfolioImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final comma = imageUrl.indexOf(',');
        final raw = comma >= 0 ? imageUrl.substring(comma + 1) : imageUrl;
        final bytes = base64Decode(raw);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _fallback(context),
        );
      } catch (_) {
        return _fallback(context);
      }
    }

    if (imageUrl.startsWith('http')) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, _) => Container(
          width: width,
          height: height,
          color: AppColors.card(isDark),
        ),
        errorWidget: (_, _, _) => _fallback(context),
      );
    }

    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: AppColors.card(isDark),
      child: Center(
        child: Icon(
          Icons.content_cut_rounded,
          color: AppColors.secondaryText(isDark),
          size: (width != null && height != null)
              ? (width! * 0.28).clamp(16.0, 36.0)
              : 24,
        ),
      ),
    );
  }
}
