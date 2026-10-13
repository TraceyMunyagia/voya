import '../../core/constants/enums.dart';
import 'cost.dart';
import 'item_link.dart';
import 'item_photo.dart';
import 'place_ref.dart';

/// Everything an item form saves, passed to the `save_item` database function.
class ItemInput {
  const ItemInput({
    required this.category,
    required this.title,
    this.description = '',
    this.cost = const Cost(),
    this.location,
    this.links = const [],
    this.notes = '',
    this.rating,
    this.details = const {},
    this.photos = const [],
    this.travelMode,
    this.travelAmount = 0,
    this.travelBasis = CostBasis.perVehicle,
    this.travelNote = '',
  });

  final ItemCategory category;
  final String title;
  final String description;
  final Cost cost;
  final PlaceRef? location;
  final List<ItemLink> links;
  final String notes;
  final int? rating;
  final Map<String, dynamic> details;
  final List<ItemPhoto> photos;

  /// How you got to this item: a TransportMode.db value, or null.
  final String? travelMode;
  final double travelAmount;
  final CostBasis travelBasis;
  final String travelNote;

  Map<String, dynamic> toFields() => {
        'category': category.name,
        'title': title,
        'description': description,
        ...cost.toColumns(),
        'location': location?.toJson(),
        'links': links.map((l) => l.toJson()).toList(),
        'notes': notes,
        'rating': rating,
        'details': details,
        'travel_mode': travelMode,
        'travel_cost_amount': travelMode == null ? 0 : travelAmount,
        'travel_cost_basis': travelBasis.db,
        'travel_note': travelMode == null ? '' : travelNote,
      };

  List<Map<String, dynamic>> toPhotos() => photos.map((p) => p.toJson()).toList();
}