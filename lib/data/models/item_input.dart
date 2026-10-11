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
      };

  List<Map<String, dynamic>> toPhotos() => photos.map((p) => p.toJson()).toList();
}