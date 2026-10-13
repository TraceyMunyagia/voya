import 'package:flutter/material.dart';

import '../../../../core/constants/enum_labels.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/cost.dart';
import '../../../../data/models/item_details.dart';
import '../../../../data/models/itinerary_item.dart';

class ItemDraft {
  const ItemDraft({
    required this.category,
    required this.title,
    required this.amount,
    this.travelMode,
    this.travelCost = const Cost(basis: CostBasis.perVehicle),
    this.travelNote = '',
  });

  final ItemCategory category;
  final String title;
  final double amount;

  /// Meals and activities: how they got there, null when they didn't say.
  final TransportMode? travelMode;
  final Cost travelCost;
  final String travelNote;
}

/// Bottom sheet to add or edit an item. Returns null if dismissed.
Future<ItemDraft?> showItemSheet(
  BuildContext context, {
  ItineraryItem? existing,
  required String currency,
  ItemCategory? initialCategory,
  List<ItemCategory>? categories,
  String travelNote = '',
}) {
  return showModalBottomSheet<ItemDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ItemSheet(
      existing: existing,
      currency: currency,
      initialCategory: initialCategory,
      categories: categories,
      travelNote: travelNote,
    ),
  );
}

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({
    required this.existing,
    required this.currency,
    this.initialCategory,
    this.categories,
    this.travelNote = '',
  });

  final ItineraryItem? existing;
  final String currency;
  final ItemCategory? initialCategory;
  final List<ItemCategory>? categories;

  /// Prefills the note of a new ride, e.g. "From Diani Airbnb".
  final String travelNote;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late ItemCategory _category =
      widget.existing?.category ?? widget.initialCategory ?? ItemCategory.activity;
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _amount = TextEditingController(text: _initialAmount());

  late final TransportMode? _savedTravel = widget.existing?.travel;
  late bool _rideOn = _savedTravel != null;
  late TransportMode _rideMode = _savedTravel ?? TransportMode.matatu;
  late CostBasis _rideBasis = _savedTravel == null
      ? _rideMode.defaultTravelBasis
      : widget.existing!.travelCost.basis;
  late final _rideNote = TextEditingController(
    text: _savedTravel == null ? widget.travelNote : widget.existing!.travelNote,
  );
  late final _rideAmount = TextEditingController(
    text: Money.toInput(_savedTravel == null ? 0 : widget.existing!.travelCost.amount),
  );

  /// Meals and activities can record how you got there.
  bool get _canTravel =>
      _category == ItemCategory.meal || _category == ItemCategory.activity;

  String _initialAmount() {
    final a = widget.existing?.cost.amount ?? 0;
    if (a <= 0) return '';
    return a % 1 == 0 ? a.toStringAsFixed(0) : a.toString();
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _rideNote.dispose();
    _rideAmount.dispose();
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
        travelMode: _canTravel && _rideOn ? _rideMode : null,
        travelCost: Cost(
          amount: _rideBasis == CostBasis.free ? 0 : (_parseAmount(_rideAmount.text) ?? 0),
          currency: widget.currency,
          basis: _rideBasis,
        ),
        travelNote: _rideNote.text.trim(),
      ),
    );
  }

  List<Widget> _rideFields() => [
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<TransportMode>(
          initialValue: _rideMode,
          decoration: const InputDecoration(labelText: 'How?'),
          items: [
            for (final m in TransportMode.gettingAround)
              DropdownMenuItem(
                value: m,
                child: Row(
                  children: [
                    Icon(m.icon, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(m.label),
                  ],
                ),
              ),
          ],
          onChanged: (m) => setState(() {
            _rideMode = m ?? _rideMode;
            _rideBasis = _rideMode.defaultTravelBasis;
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _rideNote,
          label: 'Note (optional)',
          helperText: 'e.g. From the Airbnb, about 15 minutes',
          maxLength: 500,
          textInputAction: TextInputAction.next,
        ),
        if (_rideBasis != CostBasis.free) ...[
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            controller: _rideAmount,
            label: 'Fare (optional)',
            prefixText: '${Money.symbol(widget.currency)} ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            validator: _validateAmount,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<CostBasis>(
          segments: const [
            ButtonSegment(value: CostBasis.perPerson, label: Text('Per person')),
            ButtonSegment(value: CostBasis.perVehicle, label: Text('Per vehicle')),
            ButtonSegment(value: CostBasis.free, label: Text('Free')),
          ],
          selected: {_rideBasis},
          onSelectionChanged: (s) => setState(() => _rideBasis = s.first),
        ),
      ];

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
                  for (final c in widget.categories ?? ItemCategory.values)
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
              if (_canTravel) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('How did you get there?'),
                  subtitle: const Text('e.g. a boda or matatu from where you stayed'),
                  value: _rideOn,
                  onChanged: (v) => setState(() => _rideOn = v),
                ),
                if (_rideOn) ..._rideFields(),
              ],
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
