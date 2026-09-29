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
          errorBuilder: (_, _, _) => _fallback(),
        );
      } catch (_) {
        return _fallback();
      }
    }

    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorWidget: (_, _, _) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return ColoredBox(
      color: AppColors.accentSoft,
      child: SizedBox(
        width: width,
        height: height,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
