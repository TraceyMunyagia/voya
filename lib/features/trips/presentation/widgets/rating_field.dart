import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Tap a star to rate 1-5; tap the same star again to clear.
class RatingField extends StatelessWidget {
  const RatingField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Your experience',
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                tooltip: '$i star${i == 1 ? '' : 's'}',
                iconSize: 32,
                icon: Icon(
                  value != null && i <= value! ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.warning,
                ),
                onPressed: () => onChanged(value == i ? null : i),
              ),
          ],
        ),
      ],
    );
  }
}

/// Read-only stars for tiles and detail views.
class RatingStars extends StatelessWidget {
  const RatingStars(this.value, {super.key, this.size = 16});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value out of 5 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= value ? Icons.star_rounded : Icons.star_border_rounded,
              size: size,
              color: AppColors.warning,
            ),
        ],
      ),
    );
  }
}