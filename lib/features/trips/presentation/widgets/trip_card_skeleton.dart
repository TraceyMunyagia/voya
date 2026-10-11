import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Placeholder shown while the feed loads.
class TripCardSkeleton extends StatelessWidget {
  const TripCardSkeleton({super.key});

  Widget _bar(double width, {double height = 14}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.sand.withAlpha(180),
      borderRadius: BorderRadius.circular(6),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const CircleAvatar(radius: 18, backgroundColor: AppColors.sand),
                const SizedBox(width: AppSpacing.sm),
                _bar(120),
              ],
            ),
          ),
          const AspectRatio(
            aspectRatio: 4 / 3,
            child: ColoredBox(color: AppColors.sand),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _bar(70, height: 28),
                const SizedBox(width: AppSpacing.sm),
                _bar(90, height: 28),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
