import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/dates.dart';

/// Optional start and end date in one tap. Past dates are fine: people also
/// share trips they have already taken. Trips are limited to 60 days.
class DateRangeField extends StatelessWidget {
  const DateRangeField({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
  });

  final DateTime? start;
  final DateTime? end;

  /// null means the dates were cleared.
  final ValueChanged<DateTimeRange?> onChanged;

  bool get _hasDates => start != null && end != null;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
      helpText: 'When was (or is) the trip?',
      initialDateRange: _hasDates
          ? DateTimeRange(start: start!, end: end!)
          : null,
    );
    if (picked == null || !context.mounted) return;

    if (Dates.dayCount(picked.start, picked.end) > AppConstants.maxTripDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trips can be up to ${AppConstants.maxTripDays} days.'),
        ),
      );
      return;
    }
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final days = _hasDates ? Dates.dayCount(start!, end!) : 0;
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Dates (optional)',
          suffixIcon: _hasDates
              ? IconButton(
                  tooltip: 'Clear dates',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_month_outlined),
        ),
        child: Text(
          _hasDates
              ? '${Dates.range(start!, end!)} · $days ${days == 1 ? 'day' : 'days'}'
              : 'Add dates',
        ),
      ),
    );
  }
}
