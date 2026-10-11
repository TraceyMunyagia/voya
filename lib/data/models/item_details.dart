import 'package:flutter/material.dart';

import '../../core/constants/enum_labels.dart';
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
}

class TransportDetails {
  const TransportDetails({
    this.mode = TransportMode.sgr,
    this.provider = '',
    this.from = '',
    this.to = '',
    this.people,
  });

  final TransportMode mode;
  final String provider;
  final String from;
  final String to;
  final int? people;

  Map<String, dynamic> toJson() => {
        'mode': mode.db,
        'provider': provider,
        'from': from,
        'to': to,
        if (people != null) 'people': people,
      };

  factory TransportDetails.fromJson(Map<String, dynamic> m) => TransportDetails(
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

// ---------------------------------------------------------------- shared helpers

/// The line under an item's title, e.g. `Airbnb · 3 nights` or `SGR · Madaraka Express`.
String itemSubtitle(ItineraryItem item) {
  switch (item.category) {
    case ItemCategory.accommodation:
      final d = AccommodationDetails.fromJson(item.details);
      return '${d.type.label} · ${d.nights} ${d.nights == 1 ? 'night' : 'nights'}';
    case ItemCategory.transport:
      final d = TransportDetails.fromJson(item.details);
      return [d.mode.label, if (d.provider.isNotEmpty) d.provider].join(' · ');
    case ItemCategory.meal:
    case ItemCategory.activity:
    case ItemCategory.other:
      return item.category.label;
  }
}

/// The most specific icon for an item (its stay type or transport mode).
IconData itemIcon(ItineraryItem item) {
  switch (item.category) {
    case ItemCategory.accommodation:
      return AccommodationDetails.fromJson(item.details).type.icon;
    case ItemCategory.transport:
      return TransportDetails.fromJson(item.details).mode.icon;
    case ItemCategory.meal:
    case ItemCategory.activity:
    case ItemCategory.other:
      return item.category.icon;
  }
}