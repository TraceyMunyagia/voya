import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import 'cost.dart';
import 'item_link.dart';
import 'item_photo.dart';
import 'place_ref.dart';

/// One entry of a trip.
/// - Trip level ([dayId] null): accommodation, and transport to the destination.
/// - Day level: meals, activities and other items. These can also record how
///   you got there ([travelMode], [travelCost], [travelNote]).
/// Category-specific fields live in [details] (see item_details.dart).
class ItineraryItem {
  const ItineraryItem({
    required this.id,
    required this.tripId,
    this.dayId,
    required this.category,
    required this.title,
    this.description = '',
    this.cost = const Cost(),
    this.location,
    this.links = const [],
    this.photos = const [],
    this.notes = '',
    this.rating,
    this.sortOrder = 0,
    this.details = const {},
    this.travelMode,
    this.travelCost = const Cost(basis: CostBasis.perVehicle),
    this.travelNote = '',
  });

  final String id;
  final String tripId;

  /// null for accommodation and transport to the destination.
  final String? dayId;
  final ItemCategory category;
  final String title;
  final String description;
  final Cost cost;
  final PlaceRef? location;
  final List<ItemLink> links;
  final List<ItemPhoto> photos;
  final String notes;
  final int? rating; // 1-5
  final int sortOrder;
  final Map<String, dynamic> details;

  /// TransportMode.db of the ride used to get here (day-level items only).
  final String? travelMode;
  final Cost travelCost;
  final String travelNote;

  bool get isTripLevel => dayId == null;

  List<String> get photoUrls => photos.map((p) => p.url).toList();

  /// Only set when this item differs from the trip's traveller count, so
  /// changing the trip's travellers (Make This Trip Mine) rescales costs.
  int? get people => (details['people'] as num?)?.toInt();

  /// Accommodation only.
  int? get nights => (details['nights'] as num?)?.toInt();

  /// The item's own cost for the whole group.
  double totalFor(int tripTravellers) =>
      cost.total(people: people ?? tripTravellers, nights: nights ?? 1);

  /// The cost of getting here for the whole group (0 when no ride was recorded).
  double travelTotalFor(int tripTravellers) =>
      travelMode == null ? 0 : travelCost.total(people: people ?? tripTravellers);

  /// The item plus the ride to it.
  double grandTotalFor(int tripTravellers) =>
      totalFor(tripTravellers) + travelTotalFor(tripTravellers);

  factory ItineraryItem.fromJson(Map<String, dynamic> m) {
    final rawPhotos = ((m['item_photos'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) => ((a['sort_order'] as num?) ?? 0).compareTo((b['sort_order'] as num?) ?? 0));

    final currency = m['cost_currency'] as String? ?? AppConstants.defaultCurrency;

    return ItineraryItem(
      id: m['id'] as String,
      tripId: m['trip_id'] as String,
      dayId: m['day_id'] as String?,
      category: enumFromName(ItemCategory.values, m['category'] as String?, ItemCategory.other),
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      cost: Cost.fromColumns(m),
      location: m['location'] == null
          ? null
          : PlaceRef.fromJson(Map<String, dynamic>.from(m['location'] as Map)),
      links: ((m['links'] as List?) ?? [])
          .map((e) => ItemLink.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      photos: rawPhotos.map(ItemPhoto.fromJson).toList(),
      notes: m['notes'] as String? ?? '',
      rating: (m['rating'] as num?)?.toInt(),
      sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
      details: Map<String, dynamic>.from((m['details'] as Map?) ?? {}),
      travelMode: m['travel_mode'] as String?,
      travelCost: Cost(
        amount: (m['travel_cost_amount'] as num?)?.toDouble() ?? 0,
        currency: currency,
        basis: m['travel_cost_basis'] == null
            ? CostBasis.perVehicle
            : CostBasis.fromDb(m['travel_cost_basis'] as String?),
      ),
      travelNote: m['travel_note'] as String? ?? '',
    );
  }
}