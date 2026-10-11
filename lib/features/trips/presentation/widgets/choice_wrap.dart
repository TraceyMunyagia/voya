import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// A wrapping row of single-choice chips with icons.
class ChoiceWrap<T> extends StatelessWidget {
  const ChoiceWrap({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final IconData Function(T) icon;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final v in values)
          ChoiceChip(
            showCheckmark: false,
            selected: v == selected,
            selectedColor: scheme.primary,
            avatar: Icon(
              icon(v),
              size: 18,
              color: v == selected ? scheme.onPrimary : scheme.onSurface,
            ),
            label: Text(label(v)),
            labelStyle: TextStyle(color: v == selected ? scheme.onPrimary : scheme.onSurface),
            onSelected: (_) => onSelected(v),
          ),
      ],
    );
  }
}