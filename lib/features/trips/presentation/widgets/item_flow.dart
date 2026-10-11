import 'package:flutter/material.dart';

import '../../../../core/constants/enum_labels.dart';
import '../../../../core/constants/enums.dart';
import '../../../../data/models/itinerary_item.dart';
import '../../../../data/models/trip_day.dart';
import '../../application/trip_editor_controller.dart';
import '../accommodation_form_screen.dart';
import '../transport_form_screen.dart';
import 'item_sheet.dart';

const _categoryHints = {
  ItemCategory.accommodation: 'Hotel, Airbnb, campsite, family...',
  ItemCategory.transport: 'SGR, matatu, flight, boda...',
  ItemCategory.meal: 'Restaurant, street food, cooked at home...',
  ItemCategory.activity: 'Safari, beach, museum, nightlife...',
  ItemCategory.other: 'Shopping, tips, anything else',
};

/// "What are you adding?" Returns null if dismissed.
Future<ItemCategory?> showCategoryPicker(BuildContext context) {
  return showModalBottomSheet<ItemCategory>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in ItemCategory.values)
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

/// Adds (existing == null) or edits an item, opening the right form for its
/// category. Meals and activities keep the quick sheet until Week 6.
Future<void> openItemForm(
  BuildContext context, {
  required TripEditorController controller,
  required TripDay day,
  ItineraryItem? existing,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  final category = existing?.category ?? await showCategoryPicker(context);
  if (category == null || !context.mounted) return;

  if (category == ItemCategory.accommodation) {
    await navigator.push(MaterialPageRoute<void>(
      builder: (context) =>
          AccommodationFormScreen(controller: controller, dayId: day.id, existing: existing),
    ));
    return;
  }

  if (category == ItemCategory.transport) {
    await navigator.push(MaterialPageRoute<void>(
      builder: (context) =>
          TransportFormScreen(controller: controller, dayId: day.id, existing: existing),
    ));
    return;
  }

  final draft = await showItemSheet(
    context,
    existing: existing,
    currency: controller.trip!.currency,
    initialCategory: category,
    categories: const [ItemCategory.meal, ItemCategory.activity, ItemCategory.other],
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