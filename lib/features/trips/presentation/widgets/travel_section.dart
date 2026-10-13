import 'package:flutter/material.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/item_details.dart';
import 'common_item_sections.dart';
import 'cost_field.dart';
import 'form_section.dart';

/// "How did you get there?": the transport used to reach a meal or an
/// activity. Optional. Tap a mode to choose it, tap it again to clear it.
class TravelSection extends StatelessWidget {
  const TravelSection({
    super.key,
    required this.fields,
    required this.currency,
    required this.people,
    required this.onChanged,
  });

  final CommonItemFields fields;
  final String currency;
  final int people;

  /// Called after every change so the form can rebuild.
  final VoidCallback onChanged;

  static const _bases = [
    CostBasis.perVehicle,
    CostBasis.perPerson,
    CostBasis.perGroup,
    CostBasis.oneTime,
    CostBasis.free,
  ];

  void _pick(TransportMode mode) {
    if (fields.travelMode == mode.db) {
      fields.travelMode = null;
    } else {
      fields.travelMode = mode.db;
      // a sensible way of charging, unless a fare was already typed
      if (fields.travelAmount.text.trim().isEmpty) {
        fields.travelBasis = mode.defaultTravelBasis;
      }
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = fields.travelMode == null ? null : TransportMode.fromDb(fields.travelMode);
    final modes = [
      ...TransportMode.gettingAround,
      if (selected != null && !TransportMode.gettingAround.contains(selected)) selected,
    ];
    final cost = fields.travelCost(currency);
    final total = cost.total(people: people);

    return FormSection(
      title: 'How did you get there?',
      hint: 'Optional. Choose the transport you used to reach this place. '
          'Tap it again to clear it.',
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final m in modes)
              ChoiceChip(
                showCheckmark: false,
                selected: m == selected,
                selectedColor: scheme.primary,
                avatar: Icon(
                  m.icon,
                  size: 18,
                  color: m == selected ? scheme.onPrimary : scheme.onSurface,
                ),
                label: Text(m.label),
                labelStyle: TextStyle(color: m == selected ? scheme.onPrimary : scheme.onSurface),
                onSelected: (_) => _pick(m),
              ),
          ],
        ),
        if (selected != null) ...[
          const SizedBox(height: AppSpacing.md),
          CostField(
            label: 'Fare',
            amount: fields.travelAmount,
            basis: fields.travelBasis,
            allowedBases: _bases,
            currency: currency,
            total: total,
            perPerson: people > 0 ? total / people : 0,
            onChanged: onChanged,
            onBasisChanged: (b) {
              fields.travelBasis = b;
              onChanged();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: fields.travelNote,
            label: 'About the ride (optional)',
            helperText: 'e.g. Boda from the hotel, about 15 minutes',
            maxLength: 200,
          ),
        ],
      ],
    );
  }
}