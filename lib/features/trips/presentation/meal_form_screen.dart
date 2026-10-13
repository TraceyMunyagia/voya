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
import 'widgets/travel_section.dart';

/// Eating out, cooking for yourselves, or a private chef, plus how you got there.
class MealFormScreen extends StatefulWidget {
  const MealFormScreen({
    super.key,
    required this.controller,
    required this.dayId,
    this.existing,
    this.initialMealType,
  });

  final TripEditorController controller;
  final String dayId;
  final ItineraryItem? existing;

  /// Set by the "Add breakfast / lunch / dinner" shortcuts on the day card.
  final MealType? initialMealType;

  @override
  State<MealFormScreen> createState() => _MealFormScreenState();
}

class _MealFormScreenState extends State<MealFormScreen> {
  static const _bases = [CostBasis.perGroup, CostBasis.perPerson, CostBasis.free];

  final _formKey = GlobalKey<FormState>();
  Trip get _trip => widget.controller.trip!;
  ItineraryItem? get _existing => widget.existing;

  late final CommonItemFields _f;
  late MealSource _source;
  late MealType _mealType;
  late VenueType _venue;
  late int _people;
  late CostBasis _basis;
  late final TextEditingController _name;
  late final TextEditingController _food;
  late final TextEditingController _cuisine;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    final d = e == null ? null : MealDetails.fromJson(e.details);

    _f = CommonItemFields(e, defaultTravelMode: widget.controller.lastTravelMode(widget.dayId));
    _source = d?.source ?? MealSource.eatingOut;
    _mealType = d?.mealType ?? widget.initialMealType ?? _guessMealType();
    _venue = d?.venue ?? VenueType.restaurant;
    _people = e?.people ?? _trip.travellers;
    _basis = e?.cost.basis ?? CostBasis.perGroup;
    _name = TextEditingController(
      text: (e == null || d?.source == MealSource.selfCatered) ? '' : e.title,
    );
    _food = TextEditingController(text: d?.food ?? '');
    _cuisine = TextEditingController(text: d?.cuisine ?? '');
  }

  @override
  void dispose() {
    _f.dispose();
    _name.dispose();
    _food.dispose();
    _cuisine.dispose();
    super.dispose();
  }

  /// The first meal of a day is probably breakfast, then lunch, then dinner.
  MealType _guessMealType() {
    final meals = widget.controller.itemsByDay[widget.dayId]
            ?.where((i) => i.category == ItemCategory.meal)
            .length ??
        0;
    const order = [MealType.breakfast, MealType.lunch, MealType.dinner];
    return meals < order.length ? order[meals] : MealType.snack;
  }

  String get _title => MealDetails.autoTitle(_source, _mealType, _name.text.trim());

  double get _total => _f.cost(_basis, _trip.currency).total(people: _people);
  double get _perPerson => _people > 0 ? _total / _people : 0;

  void _refresh() => setState(() {});

  Future<String?> _save() {
    final input = ItemInput(
      category: ItemCategory.meal,
      title: _title,
      cost: _f.cost(_basis, _trip.currency),
      location: _f.location,
      links: _source == MealSource.selfCatered ? const [] : _f.links,
      notes: _f.notes.text.trim(),
      rating: _f.rating,
      details: MealDetails(
        source: _source,
        mealType: _mealType,
        venue: _venue,
        food: _food.text.trim(),
        cuisine: _cuisine.text.trim(),
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final eating = _source == MealSource.eatingOut;
    final cooked = _source == MealSource.selfCatered;
    final chef = _source == MealSource.privateChef;

    return ItemFormShell(
      title: _existing == null ? 'Add a meal' : 'Edit meal',
      formKey: _formKey,
      onSave: _save,
      onDelete: _existing == null ? null : () => widget.controller.deleteItem(_existing!.id),
      deleteMessage: 'This meal and its photos will be deleted. This cannot be undone.',
      children: [
        FormSection(
          title: 'What kind of meal?',
          children: [
            ChoiceWrap<MealSource>(
              values: MealSource.values,
              selected: _source,
              label: (s) => s.label,
              icon: (s) => s.icon,
              onSelected: (s) => setState(() => _source = s),
            ),
            const SizedBox(height: AppSpacing.md),
            ChoiceWrap<MealType>(
              values: MealType.values,
              selected: _mealType,
              label: (m) => m.label,
              icon: (m) => m.icon,
              onSelected: (m) => setState(() => _mealType = m),
            ),
          ],
        ),
        FormSection(
          title: eating
              ? 'The place'
              : cooked
                  ? 'What you cooked'
                  : 'The chef',
          children: [
            if (eating) ...[
              ChoiceWrap<VenueType>(
                values: VenueType.values,
                selected: _venue,
                label: (v) => v.label,
                icon: (v) => v.icon,
                onSelected: (v) => setState(() => _venue = v),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _name,
                label: 'Restaurant name',
                helperText: "e.g. Ali Barbour's Cave",
                maxLength: 120,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Enter the restaurant name'),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
                controller: _food,
                label: 'What did you order?',
                helperText: 'Optional, but others love knowing the best dishes',
                maxLength: 500,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
            ],
            if (cooked) ...[
              AppTextField(
                controller: _food,
                label: 'What did you cook or eat?',
                helperText: 'e.g. Pasta, salad and fruit',
                maxLength: 500,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Title: $_title',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (chef) ...[
              AppTextField(
                controller: _name,
                label: 'Chef or service name',
                maxLength: 120,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Enter the chef or service name'),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
                controller: _cuisine,
                label: 'Cuisine (optional)',
                helperText: 'e.g. Swahili, Italian, seafood',
                maxLength: 60,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
                controller: _food,
                label: 'What was on the menu? (optional)',
                maxLength: 500,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
            ],
          ],
        ),
        FormSection(
          title: 'People and cost',
          hint: cooked
              ? 'Enter the total you spent on groceries.'
              : 'Enter the total bill, or switch to per person.',
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
        locationSection(
          _f,
          title: cooked ? 'Where you bought the groceries' : 'Location',
          hint: cooked ? 'Optional, e.g. Carrefour Diani.' : null,
          nameLabel: cooked ? 'Store' : 'Place name',
        ),
        if (!cooked)
          linksSection(
            _f,
            _refresh,
            hint: chef ? 'Contact or booking link.' : 'Menu, website or Instagram.',
            presets: chef
                ? const ['Booking', 'Website', 'Instagram']
                : const ['Menu', 'Website', 'Instagram'],
          ),
        photosSection(_f, _trip.id),
        notesSection(
          _f,
          _refresh,
          title: 'Your experience',
          hint: 'What was good? Would you go again?',
          rating: true,
        ),
      ],
    );
  }
}