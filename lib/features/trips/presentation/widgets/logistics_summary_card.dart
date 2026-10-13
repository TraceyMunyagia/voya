import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../data/models/item_details.dart';
import '../../../../data/models/itinerary_item.dart';
import '../../application/trip_editor_controller.dart';

/// On the editor: how you got there and where you stayed, at a glance.
/// Tapping it opens the trip details.
class LogisticsSummaryCard extends StatelessWidget {
  const LogisticsSummaryCard({super.key, required this.controller, required this.onTap});

  final TripEditorController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final trip = controller.trip!;
    final legs = controller.legs;
    final stays = controller.stays;

    if (legs.isEmpty && stays.isEmpty) {
      if (!controller.editable) return const SizedBox.shrink();
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.luggage_outlined),
          title: const Text('Add how you got there and where you stayed'),
          subtitle: const Text('These apply to the whole trip.'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
    }

    Widget row(ItineraryItem item, String prefix) {
      final cost = item.totalFor(trip.travellers);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(itemIcon(item), size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '$prefix${item.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (cost > 0)
              Text(
                Money.format(cost, currency: trip.currency),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Getting there & where you stayed',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final leg in legs)
                row(leg, '${TransportDetails.fromJson(leg.details).leg.label}: '),
              for (final stay in stays) row(stay, 'Stay: '),
            ],
          ),
        ),
      ),
    );
  }
}