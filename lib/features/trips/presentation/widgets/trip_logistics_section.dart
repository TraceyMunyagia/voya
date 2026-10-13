import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../data/models/itinerary_item.dart';
import '../../application/trip_editor_controller.dart';
import '../accommodation_form_screen.dart';
import '../transport_form_screen.dart';
import 'item_details_view.dart';
import 'item_tile.dart';

/// "Getting there" and "Where you stayed": the constants of the trip.
/// Read-only (no add buttons, tiles open the item view) when the trip can't
/// be edited.
class TripLogisticsSection extends StatelessWidget {
  const TripLogisticsSection({super.key, required this.controller});

  final TripEditorController controller;

  Future<void> _open(BuildContext context, Widget form) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => form));

  Widget _form(ItineraryItem? item, {required bool transport}) => transport
      ? TransportFormScreen(controller: controller, existing: item)
      : AccommodationFormScreen(controller: controller, existing: item);

  Future<void> _delete(BuildContext context, ItineraryItem item) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete "${item.title}"?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    final err = await controller.deleteItem(item.id);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = controller.trip!;
    final editable = controller.editable;
    final tripItems = [...controller.legs, ...controller.stays];
    final total = tripItems.fold<double>(0, (s, i) => s + i.totalFor(trip.travellers));

    Widget tile(ItineraryItem item, {required bool transport}) => ItemTile(
          key: ValueKey(item.id),
          item: item,
          travellers: trip.travellers,
          onTap: () => editable
              ? _open(context, _form(item, transport: transport))
              : showItemDetails(context, item, travellers: trip.travellers),
          onEdit: editable ? () => _open(context, _form(item, transport: transport)) : null,
          onDelete: editable ? () => _delete(context, item) : null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Group(
          title: 'Getting there',
          hint: 'How you travelled to your destination: the way there, the way back, '
              'and any other leg. Rides to meals and activities are chosen on each day.',
          icon: Icons.flight_takeoff_rounded,
          emptyText: 'No journeys added yet.',
          addLabel: 'Add transport',
          onAdd: editable ? () => _open(context, _form(null, transport: true)) : null,
          children: [for (final i in controller.legs) tile(i, transport: true)],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Group(
          title: 'Where you stayed',
          hint: 'Hotels, Airbnbs, campsites or family homes. These belong to the whole trip.',
          icon: Icons.hotel_rounded,
          emptyText: 'No stays added yet.',
          addLabel: 'Add accommodation',
          onAdd: editable ? () => _open(context, _form(null, transport: false)) : null,
          children: [for (final i in controller.stays) tile(i, transport: false)],
        ),
        if (total > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Getting there and staying: ${Money.format(total, currency: trip.currency)} · '
            '${Money.format(total / trip.travellers, currency: trip.currency)} per person',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.hint,
    required this.icon,
    required this.emptyText,
    required this.addLabel,
    required this.onAdd,
    required this.children,
  });

  final String title;
  final String hint;
  final IconData icon;
  final String emptyText;
  final String addLabel;
  final VoidCallback? onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(hint, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(emptyText, style: TextStyle(color: scheme.onSurfaceVariant)),
              )
            else
              ...children,
            if (onAdd != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(addLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}