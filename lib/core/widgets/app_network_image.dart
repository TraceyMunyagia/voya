import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../media/image_urls.dart';
import '../theme/app_colors.dart';

/// Every remote image in Voya goes through this: disk + memory cache, a
/// sand placeholder while loading and a graceful fallback on error.
/// Use `thumb: true` for trip photos shown small (feeds, grids).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.thumb = false,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.memCacheWidth,
  });

  final String url;
  final bool thumb;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  /// Decode at this width to save memory on long scrolling lists.
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    final src = thumb ? ImageUrls.thumb(url) : url;
    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (context, imageUrl) => const _ImagePlaceholder(),
        errorWidget: (context, imageUrl, error) {
          // Older photos may have no thumbnail: fall back to the full image once.
          if (thumb && src != url) {
            return AppNetworkImage(
              url,
              fit: fit,
              width: width,
              height: height,
              memCacheWidth: memCacheWidth,
            );
          }
          return const _ImagePlaceholder(icon: Icons.broken_image_outlined);
        },
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.icon = Icons.image_outlined});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.sand,
      child: Center(child: Icon(icon, color: AppColors.mist)),
    );
  }
}
