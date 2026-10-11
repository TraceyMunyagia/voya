import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_spacing.dart';
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
import 'widgets/captioned_photos_editor.dart';
import 'widgets/choice_wrap.dart';
import 'widgets/cost_field.dart';
import 'widgets/count_stepper.dart';
import 'widgets/form_section.dart';
import 'widgets/item_form_shell.dart';
import 'widgets/links_editor.dart';
import 'widgets/location_editor.dart';

/// One leg of the journey: SGR, matatu, flight, boda, ferry, walking...
class TransportFormScreen extends StatefulWidget {
  const TransportFormScreen({
    super.key,
    required this.controller,
    required this.dayId,
    this.existing,
  });

  final TripEditorController controller;
  final String dayId;
  final ItineraryItem? existing;

  @override
  State<TransportFormScreen> createState() => _TransportFormScreenState();
}

class _TransportFormScreenState extends State<TransportFormScreen> {
  static const _bases = [
    CostBasis.perPerson,
    CostBasis.perVehicle,
    CostBasis.perGroup,
    CostBasis.oneTime,
    CostBasis.free,
  ];

  final _formKey = GlobalKey<FormState>();
  Trip get _trip => widget.controller.trip!;
  ItineraryItem? get _existing => widget.existing;

  late TransportMode _mode;
  late int _people;
  late CostBasis _basis;
  late final TextEditingController _provider;
  late final TextEditingController _from;
  late final TextEditingController _to;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  PlaceRef? _location;
  late List<ItemLink> _links;
  late List<ItemPhoto> _photos;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    final d = e == null ? const TransportDetails() : TransportDetails.fromJson(e.details);

    _mode = d.mode;
    _people = e?.people ?? _trip.travellers;
    _basis = e?.cost.basis ?? CostBasis.perPerson;
    _provider = TextEditingController(text: d.provider);
    _from = TextEditingController(text: d.from);
    _to = TextEditingController(text: d.to);
    _amount = TextEditingController(text: Money.toInput(e?.cost.amount ?? 0));
    _notes = TextEditingController(text: e?.notes ?? '');
    _location = e?.location;
    _links = List.of(e?.links ?? const []);
    _photos = List.of(e?.photos ?? const []);
  }

  @override
  void dispose() {
    _provider.dispose();
    _from.dispose();
    _to.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Cost get _cost => Cost(
        amount: _basis == CostBasis.free ? 0 : (Money.parse(_amount.text) ?? 0),
        currency: _trip.currency,
        basis: _basis,
      );

  double get _total => _cost.total(people: _people);
  double get _perPerson => _people > 0 ? _total / _people : 0;

  String get _title =>
      TransportDetails.autoTitle(_mode, _from.text.trim(), _to.text.trim());

  Future<String?> _save() {
    final input = ItemInput(
      category: ItemCategory.transport,
      title: _title,
      cost: _cost,
      location: _location,
      links: _links,
      notes: _notes.text.trim(),
      details: TransportDetails(
        mode: _mode,
        provider: _provider.text.trim(),
        from: _from.text.trim(),
        to: _to.text.trim(),
        people: _people == _trip.travellers ? null : _people,
      ).toJson(),
      photos: _photos,
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

    return ItemFormShell(
      title: _existing == null ? 'Add transport' : 'Edit transport',
      formKey: _formKey,
      onSave: _save,
      onDelete: _existing == null ? null : () => widget.controller.deleteItem(_existing!.id),
      deleteMessage: 'This journey and its photos will be deleted. This cannot be undone.',
      children: [
        FormSection(
          title: 'How did you travel?',
          children: [
            ChoiceWrap<TransportMode>(
              values: TransportMode.values,
              selected: _mode,
              label: (m) => m.label,
              icon: (m) => m.icon,
              onSelected: (m) => setState(() => _mode = m),
            ),
          ],
        ),
        FormSection(
          title: 'Route',
          hint: 'It becomes the title, e.g. Nairobi → Mombasa.',
          children: [
            AppTextField(
              controller: _from,
              label: 'From',
              maxLength: 60,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: _to,
              label: 'To',
              maxLength: 60,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: _provider,
              label: 'Provider (optional)',
              helperText: 'e.g. Madaraka Express, Kenya Airways, Uber',
              maxLength: 60,
              textInputAction: TextInputAction.done,
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
        ),
        FormSection(
          title: 'People and cost',
          hint: 'Per person suits tickets. Per vehicle suits a taxi, a hired car or fuel.',
          children: [
            CountStepper(
              label: 'People',
              value: _people,
              onChanged: (v) => setState(() => _people = v),
            ),
            const SizedBox(height: AppSpacing.md),
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
          title: 'Departure point',
          hint: 'Station, stage or terminal. Optional.',
          children: [
            LocationEditor(
              initial: _location,
              nameLabel: 'Station, stage or terminal',
              onChanged: (p) => _location = p,
            ),
          ],
        ),
        FormSection(
          title: 'Links',
          hint: 'Where to buy tickets or book.',
          children: [
            LinksEditor(
              links: _links,
              presets: const ['Tickets', 'Booking', 'Website'],
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
          title: 'Notes',
          children: [
            AppTextField(
              controller: _notes,
              label: 'Notes (optional)',
              helperText: 'Travel time, where to board, tips',
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