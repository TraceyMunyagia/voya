import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../providers/trip_providers.dart';
import '../../../trips/presentation/widgets/trip_card_skeleton.dart';
import '../../../trips/presentation/widgets/trip_list_tile.dart';

class MyTripsSection extends ConsumerWidget {
  const MyTripsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(myTripsProvider);

    return trips.when(
      loading: () => const TripCardSkeleton(),
      error: (e, _) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: "Couldn't load your trips",
        message: friendlyError(e),
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(myTripsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.luggage_outlined,
            title: 'No trips yet',
            message: 'Your drafts and published trips will appear here.',
            actionLabel: 'Create a trip',
            onAction: () => context.push(Routes.create),
          );
        }
        return Column(
          children: [
            for (final t in list)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TripListTile(
                  trip: t,
                  // Published trip pages arrive in Week 8.
                  onTap:
                      (t.status == TripStatus.draft ||
                          t.status == TripStatus.revision)
                      ? () => context.push(Routes.tripEdit(t.id))
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}
