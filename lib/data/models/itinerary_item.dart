import '../../core/constants/enums.dart';
import 'cost.dart';
import 'item_link.dart';
import 'place_ref.dart';

/// One entry inside a day. All categories share this shape;
/// category-specific fields live in [details].
/// accommodation: {nights, stayType}
/// transport:     {mode, provider, from, to}
/// meal:          {mealType, source: eatingOut|selfCatered|privateChef, food}
/// activity:      {activityType}
class ItineraryItem {
  const ItineraryItem({
    required this.id,
    required this.category,
    required this.title,
    this.description = '',
    this.cost = const Cost(),
    this.location,
    this.links = const [],
    this.photoUrls = const [],
    this.notes = '',
    this.rating,
    this.order = 0,
    this.details = const {},
  });

  final String id;
  final ItemCategory category;
  final String title;
  final String description;
  final Cost cost;
  final PlaceRef? location;
  final List<ItemLink> links;
  final List<String> photoUrls;
  final String notes;
  final int? rating; // 1-5
  final int order;
  final Map<String, dynamic> details;

  Map<String, dynamic> toMap() => {
    'category': category.name,
    'title': title,
    'description': description,
    'cost': cost.toMap(),
    'location': location?.toMap(),
    'links': links.map((l) => l.toMap()).toList(),
    'photoUrls': photoUrls,
    'notes': notes,
    'rating': rating,
    'order': order,
    'details': details,
  };

  factory ItineraryItem.fromMap(String id, Map<String, dynamic> m) =>
      ItineraryItem(
        id: id,
        category: enumFromName(
          ItemCategory.values,
          m['category'] as String?,
          ItemCategory.other,
        ),
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        cost: Cost.fromMap(m['cost'] as Map<String, dynamic>?),
        location: m['location'] == null
            ? null
            : PlaceRef.fromMap(Map<String, dynamic>.from(m['location'] as Map)),
        links: ((m['links'] as List?) ?? [])
            .map((e) => ItemLink.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        photoUrls: List<String>.from((m['photoUrls'] as List?) ?? []),
        notes: m['notes'] as String? ?? '',
        rating: (m['rating'] as num?)?.toInt(),
        order: (m['order'] as num?)?.toInt() ?? 0,
        details: Map<String, dynamic>.from((m['details'] as Map?) ?? {}),
      );
}
