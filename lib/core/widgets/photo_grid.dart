import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_network_image.dart';

/// Read-only collage: 1 photo = wide, 2 = side by side, 3+ = one large photo
/// plus two stacked, with a "+N" overlay when there are more.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.urls,
    this.onTap,
    this.aspectRatio = 4 / 3,
    this.gap = 2,
  });

  final List<String> urls;
  final ValueChanged<int>? onTap;
  final double aspectRatio;
  final double gap;

  Widget _tile(int i, {bool thumb = true, int extra = 0}) {
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(i),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(urls[i], thumb: thumb),
          if (extra > 0)
            ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    final n = urls.length;

    final Widget body;
    if (n == 1) {
      body = _tile(0, thumb: false);
    } else if (n == 2) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _tile(0)),
          SizedBox(width: gap),
          Expanded(child: _tile(1)),
        ],
      );
    } else {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _tile(0, thumb: false)),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _tile(1)),
                SizedBox(height: gap),
                Expanded(child: _tile(2, extra: n - 3)),
              ],
            ),
          ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: body,
      ),
    );
  }
}
