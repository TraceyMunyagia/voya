import 'package:flutter/material.dart';

import '../../../../core/constants/enum_labels.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Amount + "charged per..." + a live total. The form works out [total] and
/// [perPerson] (it knows the nights and people), this widget only shows them.
class CostField extends StatelessWidget {
  const CostField({
    super.key,
    required this.amount,
    required this.basis,
    required this.allowedBases,
    required this.onBasisChanged,
    required this.currency,
    required this.total,
    required this.perPerson,
    this.onChanged,
  });

  final TextEditingController amount;
  final CostBasis basis;
  final List<CostBasis> allowedBases;
  final ValueChanged<CostBasis> onBasisChanged;
  final String currency;
  final double total;
  final double perPerson;

  /// Called on every keystroke in the amount field.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final isFree = basis == CostBasis.free;
    final scheme = Theme.of(context).colorScheme;
    final options = allowedBases.contains(basis) ? allowedBases : [...allowedBases, basis];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: AppTextField(
                controller: amount,
                label: 'Cost',
                prefixText: '${Money.symbol(currency)} ',
                enabled: !isFree,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.amount,
                onChanged: (_) => onChanged?.call(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Charged'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CostBasis>(
                    value: basis,
                    isExpanded: true,
                    isDense: true,
                    items: [
                      for (final b in options) DropdownMenuItem(value: b, child: Text(b.label)),
                    ],
                    onChanged: (v) {
                      if (v != null) onBasisChanged(v);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isFree
              ? 'Free'
              : 'Total ${Money.format(total, currency: currency)} · '
                  '${Money.format(perPerson, currency: currency)} per person',
          style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}