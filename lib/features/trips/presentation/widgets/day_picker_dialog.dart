import 'package:flutter/material.dart';

import '../../../../data/models/trip_day.dart';

/// Pick the day to move an item to. Returns the day id, or null if dismissed.
Future<String?> showDayPicker(
  BuildContext context, {
  required List<TripDay> days,
  required String excludeDayId,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Move to which day?'),
      children: [
        for (final d in days.where((d) => d.id != excludeDayId))
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, d.id),
            child: Text(
              d.title.isEmpty
                  ? 'Day ${d.dayNumber}'
                  : 'Day ${d.dayNumber} — ${d.title}',
            ),
          ),
      ],
    ),
  );
}
