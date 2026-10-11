import 'package:flutter/material.dart';

import '../../../../core/constants/enum_labels.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cost_chip.dart';
import '../../../../data/models/itinerary_item.dart';

enum _ItemAction { edit, move, delete }

/// One itinerary item inside a day. Callbacks left null hide that action.
class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    this.onEdit,
    this.onMove,
    this.onDelete,
    this.dragHandle,
  });

  final ItineraryItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;

  /// A ReorderableDragStartListener supplied by the day card.
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final hasMenu = onEdit != null || onMove != null || onDelete != null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      onTap: onEdit,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : AppColors.darkBackground,
        child: Icon(
          item.category.icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Wrap(
        spacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(item.category.label),
          if (item.cost.amount > 0 || item.cost.basis.name == 'free')
            CostChip(
              amount: item.cost.amount,
              currency: item.cost.currency,
              basis: item.cost.basis,
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
                if (onEdit != null)
                  const PopupMenuItem(
                    value: _ItemAction.edit,
                    child: Text('Edit'),
                  ),
                if (onMove != null)
                  const PopupMenuItem(
                    value: _ItemAction.move,
                    child: Text('Move to another day'),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: _ItemAction.delete,
                    child: Text('Delete'),
                  ),
              ],
            ),
          if (dragHandle != null) dragHandle!,
        ],
      ),
    );
  }
}
