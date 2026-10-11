import 'package:flutter/material.dart';

import '../../../../core/constants/enum_labels.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/itinerary_item.dart';

class ItemDraft {
  const ItemDraft({
    required this.category,
    required this.title,
    required this.amount,
  });

  final ItemCategory category;
  final String title;
  final double amount;
}

/// Bottom sheet to add or edit an item. Returns null if dismissed.
Future<ItemDraft?> showItemSheet(
  BuildContext context, {
  ItineraryItem? existing,
  required String currency,
}) {
  return showModalBottomSheet<ItemDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ItemSheet(existing: existing, currency: currency),
  );
}

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({required this.existing, required this.currency});

  final ItineraryItem? existing;
  final String currency;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late ItemCategory _category =
      widget.existing?.category ?? ItemCategory.activity;
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _amount = TextEditingController(text: _initialAmount());

  String _initialAmount() {
    final a = widget.existing?.cost.amount ?? 0;
    if (a <= 0) return '';
    return a % 1 == 0 ? a.toStringAsFixed(0) : a.toString();
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', ''));

  String? _validateAmount(String? v) {
    final raw = (v ?? '').trim();
    if (raw.isEmpty) return null;
    final n = _parseAmount(raw);
    return (n == null || n < 0) ? 'Enter a valid amount' : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ItemDraft(
        category: _category,
        title: _title.text.trim(),
        amount: _parseAmount(_amount.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final editing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editing ? 'Edit item' : 'Add to this day',
                style: text.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final c in ItemCategory.values)
                    ChoiceChip(
                      showCheckmark: false,
                      selected: c == _category,
                      selectedColor: scheme.primary,
                      avatar: Icon(
                        c.icon,
                        size: 18,
                        color: c == _category
                            ? scheme.onPrimary
                            : scheme.onSurface,
                      ),
                      label: Text(c.label),
                      labelStyle: TextStyle(
                        color: c == _category
                            ? scheme.onPrimary
                            : scheme.onSurface,
                      ),
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _title,
                label: 'What was it?',
                helperText:
                    'e.g. Airbnb in Diani, Dolphin tour, SGR to Mombasa',
                maxLength: 120,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _amount,
                label: 'Cost (optional)',
                prefixText: '${Money.symbol(widget.currency)} ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                validator: _validateAmount,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Details like location, photos, links and booking info are added '
                'in the full forms coming next.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _submit,
                child: Text(editing ? 'Save' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
