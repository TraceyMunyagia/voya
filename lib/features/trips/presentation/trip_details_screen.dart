import 'package:flutter/material.dart';

import '../../../core/constants/enum_labels.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/info_chip.dart';
import '../../../data/models/trip.dart';
import '../application/trip_editor_controller.dart';
import 'trip_about_screen.dart';
import 'widgets/trip_logistics_section.dart';

/// Everything about the trip itself: the basics, how you got there and where
/// you stayed. The days of the itinerary live on the editor screen.
class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key, required this.controller});

  final TripEditorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final trip = controller.trip;
        if (trip == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Trip details')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _AboutCard(
                trip: trip,
                onEdit: controller.editable
                    ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (context) =>
                              TripAboutScreen(controller: controller, trip: trip),
                        ))
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TripLogisticsSection(controller: controller),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.trip, required this.onEdit});

  final Trip trip;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About this trip', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            Text(trip.title, style: text.titleLarge),
            if (trip.destinations.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(trip.destinations.join(' · ')),
            ],
            if (trip.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(trip.description, maxLines: 4, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                InfoChip(icon: trip.type.icon, label: trip.type.label),
                InfoChip(
                  icon: Icons.people_alt_rounded,
                  label: trip.travellers == 1 ? '1 traveller' : '${trip.travellers} travellers',
                ),
                if (trip.startDate != null && trip.endDate != null)
                  InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: Dates.range(trip.startDate!, trip.endDate!),
                  ),
              ],
            ),
            if (onEdit != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit name, story, cover and dates'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}