import 'package:flutter/material.dart';

import '../../core/constants/enums.dart';
import 'itinerary_item.dart';

// ---------------------------------------------------------------- accommodation

enum AccommodationType {
  hotel('hotel', 'Hotel', Icons.hotel_rounded),
  airbnb('airbnb', 'Airbnb', Icons.home_rounded),
  hostel('hostel', 'Hostel', Icons.bed_rounded),
  resort('resort', 'Resort', Icons.pool_rounded),
  villa('villa', 'Villa', Icons.villa_rounded),
  campsite('campsite', 'Campsite', Icons.park_rounded),
  guestHouse('guest_house', 'Guest house', Icons.house_rounded),
  withFriends('with_friends_family', 'Friends or family', Icons.diversity_3_rounded),
  other('other', 'Other', Icons.more_horiz_rounded);

  const AccommodationType(this.db, this.label, this.icon);
  final String db;
  final String label;
  final IconData icon;

  static AccommodationType fromDb(String? v) => AccommodationType.values
      .firstWhere((e) => e.db == v, orElse: () => AccommodationType.hotel);
}

class AccommodationDetails {
  const AccommodationDetails({
    this.type = AccommodationType.hotel,
    this.nights = 1,
    this.people,
  });

  final AccommodationType type;
  final int nights;

  /// null = same as the trip's travellers.
  final int? people;

  Map<String, dynamic> toJson() => {
        'stay_type': type.db,
        'nights': nights,
        if (people != null) 'people': people,
      };

  factory AccommodationDetails.fromJson(Map<String, dynamic> m) => AccommodationDetails(
        type: AccommodationType.fromDb(m['stay_type'] as String?),
        nights: ((m['nights'] as num?)?.toInt() ?? 1).clamp(1, 60),
        people: (m['people'] as num?)?.toInt(),
      );
}

// -------------------------------------------------------------------- transport

enum TransportMode {
  personalCar('personal_car', 'Personal car', Icons.directions_car_rounded),
  rentalCar('rental_car', 'Rental car', Icons.car_rental_rounded),
  matatu('matatu', 'Matatu', Icons.airport_shuttle_rounded),
  bus('bus', 'Bus', Icons.directions_bus_rounded),
  train('train', 'Train', Icons.train_rounded),
  sgr('sgr', 'SGR', Icons.directions_railway_rounded),
  flight('flight', 'Flight', Icons.flight_rounded),
  taxi('taxi', 'Taxi', Icons.local_taxi_rounded),
  rideHail('uber_bolt', 'Uber / Bolt', Icons.phone_android_rounded),
  tukTuk('tuk_tuk', 'Tuk-tuk', Icons.electric_rickshaw_rounded),
  boda('boda_boda', 'Boda boda', Icons.two_wheeler_rounded),
  boat('boat_ferry', 'Boat or ferry', Icons.directions_boat_rounded),
  tour('tour_vehicle', 'Tour vehicle', Icons.tour_rounded),
  walking('walking', 'Walking', Icons.directions_walk_rounded),
  other('other', 'Other', Icons.commute_rounded);

  const TransportMode(this.db, this.label, this.icon);
  final String db;
  final String label;
  final IconData icon;

  static TransportMode fromDb(String? v) =>
      TransportMode.values.firstWhere((e) => e.db == v, orElse: () => TransportMode.other);

  /// Modes offered when choosing how you got to a meal or an activity.
  static const gettingAround = [
    TransportMode.walking,
    TransportMode.boda,
    TransportMode.tukTuk,
    TransportMode.rideHail,
    TransportMode.taxi,
    TransportMode.matatu,
    TransportMode.personalCar,
    TransportMode.rentalCar,
    TransportMode.tour,
    TransportMode.boat,
    TransportMode.bus,
    TransportMode.train,
    TransportMode.other,
  ];

  /// How a local ride is usually charged: a whole vehicle (taxi, tuk-tuk,
  /// your own car) or each person (boda, matatu, tickets). Walking is free.
  CostBasis get defaultTravelBasis {
    switch (this) {
      case TransportMode.walking:
        return CostBasis.free;
      case TransportMode.taxi:
      case TransportMode.rideHail:
      case TransportMode.tukTuk:
      case TransportMode.tour:
      case TransportMode.personalCar:
      case TransportMode.rentalCar:
        return CostBasis.perVehicle;
      case TransportMode.matatu:
      case TransportMode.bus:
      case TransportMode.train:
      case TransportMode.sgr:
      case TransportMode.flight:
      case TransportMode.boda:
      case TransportMode.boat:
      case TransportMode.other:
        return CostBasis.perPerson;
    }
  }
}

/// Which journey of the trip this is. Shown in this order: going there,
/// other legs, coming back.
enum TransportLeg {
  outbound('outbound', 'Going there', Icons.flight_takeoff_rounded),
  other('other', 'Another leg', Icons.swap_horiz_rounded),
  returning('return', 'Coming back', Icons.flight_land_rounded);

  const TransportLeg(this.db, this.label, this.icon);
  final String db;
  final String label;
  final IconData icon;

  static TransportLeg fromDb(String? v) =>
      TransportLeg.values.firstWhere((e) => e.db == v, orElse: () => TransportLeg.outbound);
}

class TransportDetails {
  const TransportDetails({
    this.leg = TransportLeg.outbound,
    this.mode = TransportMode.sgr,
    this.provider = '',
    this.from = '',
    this.to = '',
    this.people,
  });

  final TransportLeg leg;
  final TransportMode mode;
  final String provider;
  final String from;
  final String to;
  final int? people;

  Map<String, dynamic> toJson() => {
        'leg': leg.db,
        'mode': mode.db,
        'provider': provider,
        'from': from,
        'to': to,
        if (people != null) 'people': people,
      };

  factory TransportDetails.fromJson(Map<String, dynamic> m) => TransportDetails(
        leg: TransportLeg.fromDb(m['leg'] as String?),
        mode: TransportMode.fromDb(m['mode'] as String?),
        provider: m['provider'] as String? ?? '',
        from: m['from'] as String? ?? '',
        to: m['to'] as String? ?? '',
        people: (m['people'] as num?)?.toInt(),
      );

  /// `Nairobi → Mombasa`, `To Mombasa`, `From Nairobi`, or the mode's name.
  static String autoTitle(TransportMode mode, String from, String to) {
    if (from.isNotEmpty && to.isNotEmpty) return '$from → $to';
    if (to.isNotEmpty) return 'To $to';
    if (from.isNotEmpty) return 'From $from';
    return mode.label;
  }
}

// ------------------------------------------------------------------------ meals

enum MealSource {
  eatingOut('eating_out', 'Eating out', Icons.restaurant_rounded),
  selfCatered('self_catered', 'Cooked ourselves', Icons.soup_kitchen_rounded),
  privateChef('private_chef', 'Private chef', Icons.restaurant_menu_rounded);

  const MealSource(this.db, this.label, this.icon);
  final String db;
  final String label;
  final IconData icon;

  static MealSource fromDb(String? v) =>
      MealSource.values.firstWhere((e) => e.db == v, orElse: () => MealSource.eatingOut);
}

enum MealType {
  breakfast('breakfast', 'Breakfast', Icons.free_breakfast_rounded),
  lunch('lunch', 'Lunch', Icons.lunch_dining_rounded),
  dinner('dinner', 'Dinner', Icons.dinner_dining_rounded),
  snack('snack', 'Snack', Icons.icecream_rounded);

  const MealType(this.db, this.label, this.icon);
  final String db;
  final String label;
  final IconData icon;

  static MealType fromDb(String? v) =>
      MealType.values.firstWhere((e) => e.db == v, orElse: () => MealType.lunch);
}

enum VenueType {
  restaurant('restaurant', 'Restaurant', Icons.restaurant_rounded),
  cafe('cafe', 'Café', Icons.local_cafe_rounded),
  fastFood('fast_food', 'Fast food', Icons.fastfood_rounded),
  streetFood('street_food', 'Street food', Icons.takeout_dining_rounded),
  hotelRestaurant('hotel_restaurant', 'Hotel restaurant', Icons.room_service_rounded),
  localSpot('local_spot', 'Local food spot', Icons.storefront_rounded);

  const VenueType(this.db, this.label, this.icon);
  final String db;
  final String label;
  final IconData icon;

  static VenueType fromDb(String? v) =>
      VenueType.values.firstWhere((e) => e.db == v, orElse: () => VenueType.restaurant);
}

class MealDetails {
  const MealDetails({
    this.source = MealSource.eatingOut,
    this.mealType = MealType.lunch,
    this.venue = VenueType.restaurant,
    this.food = '',
    this.cuisine = '',
    this.people,
  });

  final MealSource source;
  final MealType mealType;

  /// Eating out only.
  final VenueType venue;

  /// What was ordered, cooked or on the menu.
  final String food;

  /// Private chef only.
  final String cuisine;
  final int? people;

  /// Only the fields that belong to the chosen source are stored.
  Map<String, dynamic> toJson() => {
        'source': source.db,
        'meal_type': mealType.db,
        if (source == MealSource.eatingOut) 'venue_type': venue.db,
        if (food.isNotEmpty) 'food': food,
        if (source == MealSource.privateChef && cuisine.isNotEmpty) 'cuisine': cuisine,
        if (people != null) 'people': people,
      };

  factory MealDetails.fromJson(Map<String, dynamic> m) => MealDetails(
        source: MealSource.fromDb(m['source'] as String?),
        mealType: MealType.fromDb(m['meal_type'] as String?),
        venue: VenueType.fromDb(m['venue_type'] as String?),
        food: m['food'] as String? ?? '',
        cuisine: m['cuisine'] as String? ?? '',
        people: (m['people'] as num?)?.toInt(),
      );

  /// Restaurant or chef name; cooked meals are called `Dinner — Self-cooked`.
  static String autoTitle(MealSource source, MealType mealType, String name) {
    if (source == MealSource.selfCatered) return '${mealType.label} — Self-cooked';
    return name.isNotEmpty ? name : source.label;
  }
}

// ------------------------------------------------------------------- activities

enum ActivityType {
  safari('safari', 'Safari', Icons.pets_rounded),
  gameDrive('game_drive', 'Game drive', Icons.directions_car_filled_rounded),
  hiking('hiking', 'Hiking', Icons.hiking_rounded),
  beach('beach', 'Beach', Icons.beach_access_rounded),
  boatRide('boat_ride', 'Boat ride', Icons.directions_boat_rounded),
  swimming('swimming', 'Swimming', Icons.pool_rounded),
  snorkelling('snorkelling', 'Snorkelling', Icons.scuba_diving_rounded),
  ziplining('ziplining', 'Ziplining', Icons.paragliding_rounded),
  museum('museum', 'Museum', Icons.museum_rounded),
  sightseeing('sightseeing', 'Sightseeing', Icons.photo_camera_rounded),
  cultural('cultural', 'Cultural experience', Icons.theater_comedy_rounded),
  nightlife('nightlife', 'Nightlife', Icons.nightlife_rounded),
  concert('concert', 'Concert', Icons.music_note_rounded),
  spa('spa', 'Spa', Icons.spa_rounded),
  shopping('shopping', 'Shopping', Icons.shopping_bag_rounded),
  other('other', 'Something else', Icons.local_activity_rounded);

  const ActivityType(this.db, this.label, this.icon);
  final String db;
  final String label;
  final IconData icon;

  static ActivityType fromDb(String? v) =>
      ActivityType.values.firstWhere((e) => e.db == v, orElse: () => ActivityType.other);
}

class ActivityDetails {
  const ActivityDetails({this.type = ActivityType.sightseeing, this.people});

  final ActivityType type;
  final int? people;

  Map<String, dynamic> toJson() => {
        'activity_type': type.db,
        if (people != null) 'people': people,
      };

  factory ActivityDetails.fromJson(Map<String, dynamic> m) => ActivityDetails(
        type: ActivityType.fromDb(m['activity_type'] as String?),
        people: (m['people'] as num?)?.toInt(),
      );
}

// ------------------------------------------------------------------------ other

enum OtherType {
  shopping('shopping', 'Shopping', Icons.shopping_bag_rounded),
  fees('fees', 'Fees & permits', Icons.receipt_long_rounded),
  insurance('insurance', 'Insurance', Icons.health_and_safety_rounded),
  tips('tips', 'Tips & gratuity', Icons.volunteer_activism_rounded),
  gear('gear', 'Gear & supplies', Icons.backpack_rounded),
  other('other', 'Other', Icons.more_horiz_rounded);

  const OtherType(this.db, this.label, this.icon);
  final String db;
  final String label;
  final IconData icon;

  static OtherType fromDb(String? v) =>
      OtherType.values.firstWhere((e) => e.db == v, orElse: () => OtherType.other);
}

class OtherDetails {
  const OtherDetails({this.type = OtherType.other, this.people});

  final OtherType type;
  final int? people;

  Map<String, dynamic> toJson() => {
        'other_type': type.db,
        if (people != null) 'people': people,
      };

  factory OtherDetails.fromJson(Map<String, dynamic> m) => OtherDetails(
        type: OtherType.fromDb(m['other_type'] as String?),
        people: (m['people'] as num?)?.toInt(),
      );
}

// ---------------------------------------------------------------- shared helpers

/// The line under an item's title, e.g. `Airbnb · 3 nights` or `Dinner · Local food spot`.
String itemSubtitle(ItineraryItem item) {
  switch (item.category) {
    case ItemCategory.accommodation:
      final d = AccommodationDetails.fromJson(item.details);
      return '${d.type.label} · ${d.nights} ${d.nights == 1 ? 'night' : 'nights'}';
    case ItemCategory.transport:
      final d = TransportDetails.fromJson(item.details);
      return [d.leg.label, d.mode.label, if (d.provider.isNotEmpty) d.provider].join(' · ');
    case ItemCategory.meal:
      final d = MealDetails.fromJson(item.details);
      final store = item.location?.name ?? '';
      return switch (d.source) {
        MealSource.eatingOut => '${d.mealType.label} · ${d.venue.label}',
        MealSource.selfCatered => [
            d.mealType.label,
            'Self-catered',
            if (store.isNotEmpty) store,
          ].join(' · '),
        MealSource.privateChef => [
            d.mealType.label,
            'Private chef',
            if (d.cuisine.isNotEmpty) d.cuisine,
          ].join(' · '),
      };
    case ItemCategory.activity:
      return ActivityDetails.fromJson(item.details).type.label;
    case ItemCategory.other:
      return OtherDetails.fromJson(item.details).type.label;
  }
}

/// The most specific icon for an item (its stay type, mode, venue or activity).
IconData itemIcon(ItineraryItem item) {
  switch (item.category) {
    case ItemCategory.accommodation:
      return AccommodationDetails.fromJson(item.details).type.icon;
    case ItemCategory.transport:
      return TransportDetails.fromJson(item.details).mode.icon;
    case ItemCategory.meal:
      final d = MealDetails.fromJson(item.details);
      return d.source == MealSource.eatingOut ? d.venue.icon : d.source.icon;
    case ItemCategory.activity:
      return ActivityDetails.fromJson(item.details).type.icon;
    case ItemCategory.other:
      return OtherDetails.fromJson(item.details).type.icon;
  }
}

/// An optional third line for the tile: what was eaten, or the first line of
/// the description. Null when there is nothing to show.
String? itemExtra(ItineraryItem item) {
  String? firstLine(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t.split('\n').first;
  }

  switch (item.category) {
    case ItemCategory.meal:
      return firstLine(MealDetails.fromJson(item.details).food);
    case ItemCategory.accommodation:
    case ItemCategory.activity:
      return firstLine(item.description);
    case ItemCategory.transport:
    case ItemCategory.other:
      return null;
  }
}

extension ItemTravel on ItineraryItem {
  /// How you got to this item (meals and activities), or null.
  TransportMode? get travel => travelMode == null ? null : TransportMode.fromDb(travelMode);
}
