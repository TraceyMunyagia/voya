import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../data/models/trip.dart';
import 'trip_status_chip.dart';

/// Compact row for "My trips".
class TripListTile extends StatelessWidget {
  const TripListTile({super.key, required this.trip, this.onTap});

  final Trip trip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cover = trip.coverPhotoUrl;
    final parts = [
      if (trip.destinations.isNotEmpty) trip.destinations.join(', '),
      if (trip.startDate != null && trip.endDate != null)
        Dates.range(trip.startDate!, trip.endDate!),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(AppSpacing.sm),
        leading: SizedBox(
          width: 56,
          height: 56,
          child: cover != null && cover.isNotEmpty
              ? AppNetworkImage(
                  cover,
                  thumb: true,
                  memCacheWidth: 200,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.luggage_rounded,
                    color: Colors.white54,
                  ),
                ),
        ),
        title: Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: parts.isEmpty
            ? null
            : Text(
                parts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: TripStatusChip(trip.status),
      ),
    );
  }
}
