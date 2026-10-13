import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/cost.dart';
import '../../../data/models/item_details.dart';
import '../../../data/models/item_input.dart';
import '../../../data/models/item_link.dart';
import '../../../data/models/item_photo.dart';
import '../../../data/models/itinerary_item.dart';
import '../../../data/models/place_ref.dart';
import '../../../data/models/trip.dart';
import '../application/trip_editor_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import 'widgets/captioned_photos_editor.dart';
import 'widgets/choice_wrap.dart';
import 'widgets/cost_field.dart';
import 'widgets/count_stepper.dart';
import 'widgets/form_section.dart';
import 'widgets/item_form_shell.dart';
import 'widgets/links_editor.dart';
import 'widgets/location_editor.dart';
import 'widgets/rating_field.dart';

/// Hotel, Airbnb, hostel, campsite, staying with family... for one stay.
class AccommodationFormScreen extends StatefulWidget {
  const AccommodationFormScreen({
    super.key,
    required this.controller,
    this.existing,
  });

  final TripEditorController controller;
  final ItineraryItem? existing;

  @override
  State<AccommodationFormScreen> createState() => _AccommodationFormScreenState();
}

class _AccommodationFormScreenState extends State<AccommodationFormScreen> {
  static const _bases = [
    CostBasis.perNight,
    CostBasis.perPerson,
    CostBasis.perGroup,
    CostBasis.oneTime,
    CostBasis.free,
  ];

  final _formKey = GlobalKey<FormState>();
  Trip get _trip => widget.controller.trip!;
  ItineraryItem? get _existing => widget.existing;

  late AccommodationType _type;
  late int _nights;
  late int _people;
  late CostBasis _basis;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  PlaceRef? _location;
  late List<ItemLink> _links;
  late List<ItemPhoto> _photos;
  int? _rating;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    final d = e == null
        ? AccommodationDetails(nights: _trip.nights.clamp(1, 60))
        : AccommodationDetails.fromJson(e.details);

    _type = d.type;
    _nights = d.nights;
    _people = e?.people ?? _trip.travellers;
    _basis = e?.cost.basis ?? CostBasis.perNight;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _amount = TextEditingController(text: Money.toInput(e?.cost.amount ?? 0));
    _notes = TextEditingController(text: e?.notes ?? '');
    _location = e?.location;
    _links = List.of(e?.links ?? const []);
    _photos = List.of(e?.photos ?? const []);
    _rating = e?.rating;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Cost get _cost => Cost(
        amount: _basis == CostBasis.free ? 0 : (Money.parse(_amount.text) ?? 0),
        currency: _trip.currency,
        basis: _basis,
      );

  double get _total => _cost.total(people: _people, nights: _nights);
  double get _perPerson => _people > 0 ? _total / _people : 0;

  Future<String?> _save() {
    final input = ItemInput(
      category: ItemCategory.accommodation,
      title: _title.text.trim(),
      description: _description.text.trim(),
      cost: _cost,
      location: _location,
      links: _links,
      notes: _notes.text.trim(),
      rating: _rating,
      details: AccommodationDetails(
        type: _type,
        nights: _nights,
        people: _people == _trip.travellers ? null : _people,
      ).toJson(),
      photos: _photos,
    );
    return widget.controller.saveFullItem(
      itemId: _existing?.id,
      input: input,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ItemFormShell(
      title: _existing == null ? 'Add accommodation' : 'Edit accommodation',
      formKey: _formKey,
      onSave: _save,
      onDelete: _existing == null ? null : () => widget.controller.deleteItem(_existing!.id),
      deleteMessage: 'The stay and its photos will be deleted. This cannot be undone.',
      children: [
        FormSection(
          title: 'The stay',
          children: [
            ChoiceWrap<AccommodationType>(
              values: AccommodationType.values,
              selected: _type,
              label: (t) => t.label,
              icon: (t) => t.icon,
              onSelected: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _title,
              label: 'Name',
              helperText: 'e.g. Diani Beach Hotel',
              maxLength: 120,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.required(v, 'Enter the name of the place'),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: _description,
              label: 'About the stay (optional)',
              maxLength: 2000,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
        FormSection(
          title: 'Nights and guests',
          hint: 'Stays belong to the whole trip, not to one day.',
          children: [
            CountStepper(
              label: 'Nights',
              value: _nights,
              min: 1,
              max: 60,
              onChanged: (v) => setState(() => _nights = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            CountStepper(
              label: 'Guests',
              value: _people,
              onChanged: (v) => setState(() => _people = v),
            ),
          ],
        ),
        FormSection(
          title: 'Cost',
          hint: 'Choose how you were charged. Voya works out the total and the cost per person.',
          children: [
            CostField(
              amount: _amount,
              basis: _basis,
              allowedBases: _bases,
              currency: _trip.currency,
              total: _total,
              perPerson: _perPerson,
              onChanged: () => setState(() {}),
              onBasisChanged: (b) => setState(() => _basis = b),
            ),
          ],
        ),
        FormSection(
          title: 'Location',
          children: [
            LocationEditor(initial: _location, onChanged: (p) => _location = p),
          ],
        ),
        FormSection(
          title: 'Links',
          hint: 'Booking page, website, Instagram. So others can book the same place.',
          children: [
            LinksEditor(
              links: _links,
              onChanged: (l) => setState(() => _links = l),
            ),
          ],
        ),
        FormSection(
          title: 'Photos',
          children: [
            CaptionedPhotosEditor(
              tripId: _trip.id,
              photos: _photos,
              onChanged: (p) => _photos = p,
            ),
          ],
        ),
        FormSection(
          title: 'Your experience',
          children: [
            RatingField(value: _rating, onChanged: (r) => setState(() => _rating = r)),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _notes,
              label: 'Notes (optional)',
              helperText: 'Tips for the next traveller',
              maxLength: 2000,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      ],
    );
  }
}