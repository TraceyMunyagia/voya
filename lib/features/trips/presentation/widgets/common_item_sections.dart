import 'package:flutter/material.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/cost.dart';
import '../../../../data/models/item_details.dart';
import '../../../../data/models/item_link.dart';
import '../../../../data/models/item_photo.dart';
import '../../../../data/models/itinerary_item.dart';
import '../../../../data/models/place_ref.dart';
import 'captioned_photos_editor.dart';
import 'form_section.dart';
import 'links_editor.dart';
import 'location_editor.dart';
import 'rating_field.dart';

/// The fields every day item has, kept together. Create one in initState and
/// call [dispose] in dispose().
class CommonItemFields {
  /// [defaultTravelMode] is only used for a new item: it pre-selects the ride
  /// you used for the previous stop of the day.
  CommonItemFields(ItineraryItem? existing, {String? defaultTravelMode})
      : amount = TextEditingController(text: Money.toInput(existing?.cost.amount ?? 0)),
        notes = TextEditingController(text: existing?.notes ?? ''),
        description = TextEditingController(text: existing?.description ?? ''),
        location = existing?.location,
        links = List.of(existing?.links ?? const []),
        photos = List.of(existing?.photos ?? const []),
        rating = existing?.rating,
        travelMode = existing != null ? existing.travelMode : defaultTravelMode,
        travelAmount = TextEditingController(text: Money.toInput(existing?.travelCost.amount ?? 0)),
        travelNote = TextEditingController(text: existing?.travelNote ?? ''),
        travelBasis = (existing != null && existing.travelMode != null)
            ? existing.travelCost.basis
            : (existing == null && defaultTravelMode != null
                ? TransportMode.fromDb(defaultTravelMode).defaultTravelBasis
                : CostBasis.perVehicle);

  final TextEditingController amount;
  final TextEditingController notes;
  final TextEditingController description;
  PlaceRef? location;
  List<ItemLink> links;
  List<ItemPhoto> photos;
  int? rating;

  /// How you got here: a TransportMode.db value, or null.
  String? travelMode;
  CostBasis travelBasis;
  final TextEditingController travelAmount;
  final TextEditingController travelNote;

  /// The cost as the form currently reads. Free is always zero.
  Cost cost(CostBasis basis, String currency) => Cost(
        amount: basis == CostBasis.free ? 0 : (Money.parse(amount.text) ?? 0),
        currency: currency,
        basis: basis,
      );

  double get travelAmountValue => (travelMode == null || travelBasis == CostBasis.free)
      ? 0
      : (Money.parse(travelAmount.text) ?? 0);

  String get travelNoteValue => travelMode == null ? '' : travelNote.text.trim();

  Cost travelCost(String currency) =>
      Cost(amount: travelAmountValue, currency: currency, basis: travelBasis);

  void dispose() {
    amount.dispose();
    notes.dispose();
    description.dispose();
    travelAmount.dispose();
    travelNote.dispose();
  }
}

Widget locationSection(
  CommonItemFields f, {
  String title = 'Location',
  String? hint,
  String nameLabel = 'Place name',
}) {
  return FormSection(
    title: title,
    hint: hint,
    children: [
      LocationEditor(
        initial: f.location,
        nameLabel: nameLabel,
        onChanged: (p) => f.location = p,
      ),
    ],
  );
}

Widget linksSection(
  CommonItemFields f,
  VoidCallback refresh, {
  String title = 'Links',
  String? hint,
  List<String> presets = const ['Booking', 'Website', 'Instagram'],
}) {
  return FormSection(
    title: title,
    hint: hint,
    children: [
      LinksEditor(
        links: f.links,
        presets: presets,
        onChanged: (l) {
          f.links = l;
          refresh();
        },
      ),
    ],
  );
}

Widget photosSection(CommonItemFields f, String tripId) {
  return FormSection(
    title: 'Photos',
    children: [
      CaptionedPhotosEditor(
        tripId: tripId,
        photos: f.photos,
        onChanged: (p) => f.photos = p,
      ),
    ],
  );
}

Widget notesSection(
  CommonItemFields f,
  VoidCallback refresh, {
  String title = 'Notes',
  String? hint,
  bool rating = false,
}) {
  return FormSection(
    title: title,
    children: [
      if (rating) ...[
        RatingField(
          value: f.rating,
          onChanged: (r) {
            f.rating = r;
            refresh();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      AppTextField(
        controller: f.notes,
        label: 'Notes (optional)',
        helperText: hint,
        maxLength: 2000,
        maxLines: 4,
        keyboardType: TextInputType.multiline,
      ),
    ],
  );
}