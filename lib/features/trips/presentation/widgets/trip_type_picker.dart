import 'package:flutter/material.dart';

import '../../../../core/constants/enum_labels.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_spacing.dart';

class TripTypePicker extends StatelessWidget {
  const TripTypePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TripType value;
  final ValueChanged<TripType> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final t in TripType.values)
          ChoiceChip(
            showCheckmark: false,
            selected: t == value,
            selectedColor: scheme.primary,
            avatar: Icon(
              t.icon,
              size: 18,
              color: t == value ? scheme.onPrimary : scheme.onSurface,
            ),
            label: Text(t.label),
            labelStyle: TextStyle(
              color: t == value ? scheme.onPrimary : scheme.onSurface,
            ),
            onSelected: (_) => onChanged(t),
          ),
      ],
    );
  }
}
