import 'package:flutter/material.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/launcher.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/photo_gallery_screen.dart';
import '../../../../data/models/item_details.dart';
import '../../../../data/models/itinerary_item.dart';
import 'rating_field.dart';

/// Read-only bottom sheet for an item. Used for trips that can't be edited
/// now and reused on the trip page in Week 8.
Future<void> showItemDetails(
  BuildContext context,
  ItineraryItem item, {
  required int travellers,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) =>
          ItemDetailsView(item: item, travellers: travellers, scrollController: scroll),
    ),
  );
}

class ItemDetailsView extends StatelessWidget {
  const ItemDetailsView({
    super.key,
    required this.item,
    required this.travellers,
    this.scrollController,
  });

  final ItineraryItem item;
  final int travellers;
  final ScrollController? scrollController;

  String? _costLine() {
    final c = item.cost;
    final money = Money.format(c.amount, currency: c.currency);
    switch (c.basis) {
      case CostBasis.free:
        return 'Free';
      case CostBasis.perPerson:
        return '$money per person × ${item.people ?? travellers}';
      case CostBasis.perNight:
        return '$money per night × ${item.nights ?? 1}';
      case CostBasis.perGroup:
        return '$money for the group';
      case CostBasis.perVehicle:
        return '$money per vehicle';
      case CostBasis.oneTime:
        return c.amount > 0 ? money : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final people = item.people ?? travellers;
    // the ride has its own row below, so this is the item on its own
    final total = item.totalFor(travellers);
    final travelTotal = item.travelTotalFor(travellers);
    final costLine = _costLine();
    final location = item.location;
    final mapsLink = location?.mapsLink;
    final urls = item.photoUrls;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.secondaryContainer,
              child: Icon(itemIcon(item), color: scheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  Text(itemSubtitle(item), style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        if (item.rating != null) ...[
          const SizedBox(height: AppSpacing.sm),
          RatingStars(item.rating!, size: 22),
        ],
        if (costLine != null) ...[
          const SizedBox(height: AppSpacing.md),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.cost.basis != CostBasis.free) ...[
                    Text(
                      Money.format(total, currency: item.cost.currency),
                      style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${Money.format(people > 0 ? total / people : 0, currency: item.cost.currency)} per person',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(costLine),
                ],
              ),
            ),
          ),
        ],
        if (item.travel case final mode?) ...[
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(mode.icon),
            title: const Text('How they got there'),
            subtitle: Text(
              [mode.label, if (item.travelNote.isNotEmpty) item.travelNote].join(' · '),
            ),
            trailing: travelTotal > 0
                ? Text(Money.format(travelTotal, currency: item.travelCost.currency))
                : null,
          ),
        ],
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(item.description),
        ],
        if (location != null) ...[
          const SizedBox(height: AppSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined),
            title: Text(location.name),
            subtitle: location.address == null ? null : Text(location.address!),
            trailing: mapsLink == null
                ? null
                : TextButton(
                    onPressed: () => openUrl(mapsLink),
                    child: const Text('Open in Maps'),
                  ),
          ),
        ],
        if (item.links.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final l in item.links)
                ActionChip(
                  avatar: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(l.label),
                  onPressed: () => openUrl(l.url),
                ),
            ],
          ),
        ],
        if (urls.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < item.photos.length; i++) ...[
            GestureDetector(
              onTap: () => showPhotoGallery(context, urls, initialIndex: i),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: AppNetworkImage(
                  item.photos[i].url,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            if (item.photos[i].caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  item.photos[i].caption,
                  style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        if (item.notes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Notes', style: text.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(item.notes),
        ],
      ],
    );
  }
}