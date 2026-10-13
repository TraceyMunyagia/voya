import 'package:flutter/material.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cost_chip.dart';
import '../../../../core/widgets/info_chip.dart';
import '../../../../data/models/item_details.dart';
import '../../../../data/models/itinerary_item.dart';
import 'rating_field.dart';

enum _ItemAction { edit, move, delete }

/// One itinerary item inside a day. Callbacks left null hide that action.
class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.travellers,
    this.onTap,
    this.onEdit,
    this.onMove,
    this.onDelete,
    this.dragHandle,
  });

  final ItineraryItem item;
  final int travellers;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;

  /// A ReorderableDragStartListener supplied by the day card.
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasMenu = onEdit != null || onMove != null || onDelete != null;
    final total = item.grandTotalFor(travellers);
    final isFree = item.cost.basis == CostBasis.free;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scheme.brightness == Brightness.light ? Colors.white : scheme.surface,
        child: Icon(itemIcon(item), size: 20, color: scheme.primary),
      ),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(itemSubtitle(item), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (item.travel case final mode?)
            Row(
              children: [
                Icon(mode.icon, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    [mode.label, if (item.travelNote.isNotEmpty) item.travelNote].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isFree)
                const CostChip(amount: 0, basis: CostBasis.free)
              else if (total > 0)
                CostChip(amount: total, currency: item.cost.currency),
              if (item.rating != null) RatingStars(item.rating!, size: 15),
              if (item.photos.isNotEmpty)
                InfoChip(icon: Icons.photo_outlined, label: '${item.photos.length}'),
              if (item.location != null)
                const Icon(Icons.place_outlined, size: 18),
              if (item.links.isNotEmpty)
                const Icon(Icons.link_rounded, size: 18),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasMenu)
            PopupMenuButton<_ItemAction>(
              tooltip: 'Item actions',
              onSelected: (a) {
                switch (a) {
                  case _ItemAction.edit:
                    onEdit?.call();
                  case _ItemAction.move:
                    onMove?.call();
                  case _ItemAction.delete:
                    onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                if (onEdit != null) const PopupMenuItem(value: _ItemAction.edit, child: Text('Edit')),
                if (onMove != null)
                  const PopupMenuItem(value: _ItemAction.move, child: Text('Move to another day')),
                if (onDelete != null)
                  const PopupMenuItem(value: _ItemAction.delete, child: Text('Delete')),
              ],
            ),
          ?dragHandle,
        ],
      ),
    );
  }
}