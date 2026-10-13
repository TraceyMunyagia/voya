import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_spacing.dart';
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
import 'widgets/travel_section.dart';

/// Safari, hiking, a boat ride, a concert... anything you did, plus how you got there.
class ActivityFormScreen extends StatefulWidget {
  const ActivityFormScreen({
    super.key,
    required this.controller,
    required this.dayId,
    this.existing,
  });

  final TripEditorController controller;
  final String dayId;
  final ItineraryItem? existing;

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  static const _bases = [
    CostBasis.perPerson,
    CostBasis.perGroup,
    CostBasis.perVehicle,
    CostBasis.oneTime,
    CostBasis.free,
  ];

  final _formKey = GlobalKey<FormState>();
  Trip get _trip => widget.controller.trip!;
  ItineraryItem? get _existing => widget.existing;

  late final CommonItemFields _f;
  late ActivityType _type;
  late int _people;
  late CostBasis _basis;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    final d = e == null ? const ActivityDetails() : ActivityDetails.fromJson(e.details);

    _f = CommonItemFields(e, defaultTravelMode: widget.controller.lastTravelMode(widget.dayId));
    _type = d.type;
    _people = e?.people ?? _trip.travellers;
    _basis = e?.cost.basis ?? CostBasis.perPerson;
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
    final name = _name.text.trim();
    final input = ItemInput(
      category: ItemCategory.activity,
      title: name.isEmpty ? _type.label : name,
      description: _f.description.text.trim(),
      cost: _f.cost(_basis, _trip.currency),
      location: _f.location,
      links: _f.links,
      notes: _f.notes.text.trim(),
      rating: _f.rating,
      details: ActivityDetails(
        type: _type,
        people: _people == _trip.travellers ? null : _people,
      ).toJson(),
      photos: _f.photos,
      travelMode: _f.travelMode,
      travelAmount: _f.travelAmountValue,
      travelBasis: _f.travelBasis,
      travelNote: _f.travelNoteValue,
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
      title: _existing == null ? 'Add an activity' : 'Edit activity',
      formKey: _formKey,
      onSave: _save,
      onDelete: _existing == null ? null : () => widget.controller.deleteItem(_existing!.id),
      deleteMessage: 'This activity and its photos will be deleted. This cannot be undone.',
      children: [
        FormSection(
          title: 'What did you do?',
          children: [
            ChoiceWrap<ActivityType>(
              values: ActivityType.values,
              selected: _type,
              label: (t) => t.label,
              icon: (t) => t.icon,
              onSelected: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _name,
              label: 'Name (optional)',
              helperText:
                  'e.g. Dolphin tour at Wasini. Left empty, it is called "${_type.label}".',
              maxLength: 120,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: _f.description,
              label: 'About it (optional)',
              helperText: 'How long, what to expect, what to bring',
              maxLength: 2000,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
        FormSection(
          title: 'People and cost',
          hint: 'Per person suits tickets and tours. Per vehicle suits a game drive. '
              'Choose Free for beaches, walks and the like.',
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
        TravelSection(
          fields: _f,
          currency: _trip.currency,
          people: _people,
          onChanged: _refresh,
        ),
        locationSection(_f, title: 'Where', hint: 'The place, park or meeting point.'),
        linksSection(
          _f,
          _refresh,
          hint: 'Booking page, website or tickets, so others can do the same.',
          presets: const ['Booking', 'Tickets', 'Website', 'Instagram'],
        ),
        photosSection(_f, _trip.id),
        notesSection(
          _f,
          _refresh,
          title: 'Your experience',
          hint: 'Was it worth it? Any tips?',
          rating: true,
        ),
      ],
    );
  }
}