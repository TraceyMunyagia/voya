import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../data/models/itinerary_item.dart';
import '../../../../data/models/trip_day.dart';
import 'item_tile.dart';

/// One day of the trip: title, story, photos, its items and a cost subtotal.
/// Every callback left null switches that feature off, so the same card
/// works read-only.
class DayCard extends StatelessWidget {
  const DayCard({
    super.key,
    required this.day,
    required this.items,
    required this.editable,
    required this.travellers,
    required this.onEditDay,
    this.onAddItem,
    this.onEditItem,
    this.onViewItem,
    this.onMoveItem,
    this.onDeleteItem,
    this.onReorderItems,
  });

  final TripDay day;
  final List<ItineraryItem> items;
  final bool editable;
  final int travellers;
  final VoidCallback onEditDay;
  final VoidCallback? onAddItem;
  final ValueChanged<ItineraryItem>? onEditItem;
  final ValueChanged<ItineraryItem>? onViewItem;
  final ValueChanged<ItineraryItem>? onMoveItem;
  final ValueChanged<ItineraryItem>? onDeleteItem;
  final void Function(int oldIndex, int newIndex)? onReorderItems;

  ItemTile _tile(ItineraryItem item, {Widget? handle}) {
    final tap = editable ? onEditItem : onViewItem;
    return ItemTile(
      key: ValueKey(item.id),
      item: item,
      travellers: travellers,
      onTap: tap == null ? null : () => tap(item),
      onEdit: onEditItem == null ? null : () => onEditItem!(item),
      onMove: onMoveItem == null ? null : () => onMoveItem!(item),
      onDelete: onDeleteItem == null ? null : () => onDeleteItem!(item),
      dragHandle: handle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final heading =
        day.title.isEmpty ? 'Day ${day.dayNumber}' : 'Day ${day.dayNumber} — ${day.title}';
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.grandTotalFor(travellers));

    final Widget list;
    if (items.isEmpty) {
      list = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          'Nothing planned yet.',
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    } else if (onReorderItems != null && items.length > 1) {
      list = ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: items.length,
        onReorder: onReorderItems!,
        itemBuilder: (context, i) => _tile(
          items[i],
          handle: ReorderableDragStartListener(
            index: i,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Icon(Icons.drag_handle_rounded),
            ),
          ),
        ),
      );
    } else {
      list = Column(children: [for (final item in items) _tile(item)]);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    heading,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (subtotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: Text(
                      Money.format(subtotal),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (editable)
                  IconButton(
                    tooltip: 'Edit day',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEditDay,
                  ),
              ],
            ),
            if (day.story.isNotEmpty) ...[
              Text(day.story, maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (day.photoUrls.isNotEmpty) ...[
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: day.photoUrls.length,
                  separatorBuilder: (context, i) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) => AspectRatio(
                    aspectRatio: 1,
                    child: AppNetworkImage(
                      day.photoUrls[i],
                      thumb: true,
                      memCacheWidth: 200,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            list,
            if (onAddItem != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onAddItem,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add to this day'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
