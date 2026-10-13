import 'package:flutter/material.dart';

import '../../../../core/constants/enum_labels.dart';
import '../../../../core/constants/enums.dart';
import '../../../../data/models/itinerary_item.dart';
import '../../../../data/models/trip_day.dart';
import '../../application/trip_editor_controller.dart';
import '../activity_form_screen.dart';
import '../meal_form_screen.dart';
import '../other_form_screen.dart';
import 'item_sheet.dart';

const _dayCategories = [ItemCategory.meal, ItemCategory.activity, ItemCategory.other];

const _categoryHints = {
  ItemCategory.meal: 'Restaurant, street food, cooked at home, private chef...',
  ItemCategory.activity: 'Safari, beach, museum, nightlife...',
  ItemCategory.other: 'Shopping, fees, insurance, tips',
};

/// "What are you adding to this day?" Returns null if dismissed.
Future<ItemCategory?> showCategoryPicker(BuildContext context) {
  return showModalBottomSheet<ItemCategory>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in _dayCategories)
            ListTile(
              leading: Icon(c.icon),
              title: Text(c.label),
              subtitle: Text(_categoryHints[c]!),
              onTap: () => Navigator.pop(context, c),
            ),
        ],
      ),
    ),
  );
}

/// Adds (existing == null) or edits a day item.
Future<void> openItemForm(
  BuildContext context, {
  required TripEditorController controller,
  required TripDay day,
  ItineraryItem? existing,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  final category = existing?.category ?? await showCategoryPicker(context);
  if (category == null || !context.mounted) return;

  if (category == ItemCategory.meal) {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) =>
          MealFormScreen(controller: controller, dayId: day.id, existing: existing),
    ));
    return;
  }

  if (category == ItemCategory.activity) {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) =>
          ActivityFormScreen(controller: controller, dayId: day.id, existing: existing),
    ));
    return;
  }

  if (category == ItemCategory.other) {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) =>
          OtherFormScreen(controller: controller, dayId: day.id, existing: existing),
    ));
    return;
  }

  final draft = await showItemSheet(
    context,
    existing: existing,
    currency: controller.trip!.currency,
    initialCategory: category,
    categories: _dayCategories,
  );
  if (draft == null) return;

  final err = existing == null
      ? await controller.addItem(
          dayId: day.id,
          category: draft.category,
          title: draft.title,
          amount: draft.amount,
        )
      : await controller.saveItem(
          existing.id,
          category: draft.category,
          title: draft.title,
          amount: draft.amount,
        );
  if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
}