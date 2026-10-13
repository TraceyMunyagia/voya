import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/item_details.dart';
import '../../../data/models/item_input.dart';
import '../../../data/models/itinerary_item.dart';
import '../../../data/models/trip.dart';
import '../application/trip_editor_controller.dart';
import 'widgets/choice_wrap.dart';
import 'widgets/common_item_sections.dart';
import 'widgets/cost_field.dart';
import 'widgets/count_stepper.dart';
import 'widgets/form_section.dart';
import 'widgets/item_form_shell.dart';

/// Anything else that cost money or is worth remembering: shopping, fees,
/// insurance, tips, gear.
class OtherFormScreen extends StatefulWidget {
  const OtherFormScreen({
    super.key,
    required this.controller,
    required this.dayId,
    this.existing,
  });

  final TripEditorController controller;
  final String dayId;
  final ItineraryItem? existing;

  @override
  State<OtherFormScreen> createState() => _OtherFormScreenState();
}

class _OtherFormScreenState extends State<OtherFormScreen> {
  static const _bases = [
    CostBasis.oneTime,
    CostBasis.perPerson,
    CostBasis.perGroup,
    CostBasis.free,
  ];

  final _formKey = GlobalKey<FormState>();
  Trip get _trip => widget.controller.trip!;
  ItineraryItem? get _existing => widget.existing;

  late final CommonItemFields _f;
  late OtherType _type;
  late int _people;
  late CostBasis _basis;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    final d = e == null ? const OtherDetails() : OtherDetails.fromJson(e.details);

    _f = CommonItemFields(e);
    _type = d.type;
    _people = e?.people ?? _trip.travellers;
    _basis = e?.cost.basis ?? CostBasis.oneTime;
    _name = TextEditingController(text: e?.title ?? '');
  }

  @override
  void dispose() {
    _f.dispose();
    _name.dispose();
    super.dispose();
  }

  double get _total => _f.cost(_basis, _trip.currency).total(people: _people);
  double get _perPerson => _people > 0 ? _total / _people : 0;

  void _refresh() => setState(() {});

  Future<String?> _save() {
    final input = ItemInput(
      category: ItemCategory.other,
      title: _name.text.trim(),
      cost: _f.cost(_basis, _trip.currency),
      location: _f.location,
      links: _f.links,
      notes: _f.notes.text.trim(),
      details: OtherDetails(
        type: _type,
        people: _people == _trip.travellers ? null : _people,
      ).toJson(),
      photos: _f.photos,
    );
    return widget.controller.saveFullItem(
      itemId: _existing?.id,
      dayId: widget.dayId,
      input: input,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ItemFormShell(
      title: _existing == null ? 'Add something else' : 'Edit item',
      formKey: _formKey,
      onSave: _save,
      onDelete: _existing == null ? null : () => widget.controller.deleteItem(_existing!.id),
      deleteMessage: 'This item and its photos will be deleted. This cannot be undone.',
      children: [
        FormSection(
          title: 'What was it?',
          children: [
            ChoiceWrap<OtherType>(
              values: OtherType.values,
              selected: _type,
              label: (t) => t.label,
              icon: (t) => t.icon,
              onSelected: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _name,
              label: 'Title',
              helperText: 'e.g. Souvenirs at the market, Park entry permit',
              maxLength: 120,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.required(v, 'Enter a title'),
            ),
          ],
        ),
        FormSection(
          title: 'People and cost',
          children: [
            CountStepper(
              label: 'People',
              value: _people,
              onChanged: (v) => setState(() => _people = v),
            ),
            const SizedBox(height: AppSpacing.md),
            CostField(
              amount: _f.amount,
              basis: _basis,
              allowedBases: _bases,
              currency: _trip.currency,
              total: _total,
              perPerson: _perPerson,
              onChanged: _refresh,
              onBasisChanged: (b) => setState(() => _basis = b),
            ),
          ],
        ),
        locationSection(_f, hint: 'Optional.'),
        linksSection(_f, _refresh, presets: const ['Website', 'Booking', 'Instagram']),
        photosSection(_f, _trip.id),
        notesSection(_f, _refresh, hint: 'Anything worth remembering'),
      ],
    );
  }
}