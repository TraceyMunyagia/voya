import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/enum_labels.dart';
import '../constants/enums.dart';
import '../theme/app_spacing.dart';
import '../utils/money.dart';

/// Total, per-person cost and a per-category breakdown with proportion bars.
/// Pure display: the numbers come from the cost engine (Week 8).
class CostSummary extends StatelessWidget {
  const CostSummary({
    super.key,
    required this.total,
    required this.perPerson,
    required this.byCategory,
    this.currency = AppConstants.defaultCurrency,
  });

  final double total;
  final double perPerson;
  final Map<ItemCategory, double> byCategory;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final rows = ItemCategory.values
        .where((c) => (byCategory[c] ?? 0) > 0)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total trip',
              style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              Money.format(total, currency: currency),
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${Money.format(perPerson, currency: currency)} per person',
              style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (rows.isNotEmpty) ...[
              const Divider(height: AppSpacing.lg * 2),
              for (final c in rows) ...[
                Row(
                  children: [
                    Icon(c.icon, size: 18, color: scheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(c.label)),
                    Text(
                      Money.format(byCategory[c]!, currency: currency),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0
                        ? (byCategory[c]! / total).clamp(0, 1).toDouble()
                        : 0,
                    minHeight: 6,
                    color: scheme.primary,
                    backgroundColor: scheme.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
