import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/constants/enums.dart';
import 'package:voya/data/models/item_details.dart';
import 'package:voya/data/models/itinerary_item.dart';

ItineraryItem _item(ItemCategory category, Map<String, dynamic> details) => ItineraryItem(
      id: 'i1',
      tripId: 't1',
      dayId: 'd1',
      category: category,
      title: 'x',
      details: details,
    );

void main() {
  group('AccommodationDetails', () {
    test('round trips and only stores people when set', () {
      const d = AccommodationDetails(type: AccommodationType.airbnb, nights: 3);
      expect(d.toJson(), {'stay_type': 'airbnb', 'nights': 3});

      const withPeople = AccommodationDetails(nights: 2, people: 5);
      expect(withPeople.toJson()['people'], 5);

      final back = AccommodationDetails.fromJson(withPeople.toJson());
      expect(back.nights, 2);
      expect(back.people, 5);
    });

    test('bad or missing data falls back safely', () {
      final d = AccommodationDetails.fromJson({'stay_type': 'castle', 'nights': 500});
      expect(d.type, AccommodationType.hotel);
      expect(d.nights, 60); // clamped
      expect(AccommodationDetails.fromJson({}).nights, 1);
    });
  });

  group('TransportDetails', () {
    test('autoTitle uses the route, then one end, then the mode', () {
      expect(TransportDetails.autoTitle(TransportMode.sgr, 'Nairobi', 'Mombasa'), 'Nairobi → Mombasa');
      expect(TransportDetails.autoTitle(TransportMode.taxi, '', 'Diani'), 'To Diani');
      expect(TransportDetails.autoTitle(TransportMode.taxi, 'Nairobi', ''), 'From Nairobi');
      expect(TransportDetails.autoTitle(TransportMode.boda, '', ''), 'Boda boda');
    });

    test('round trips', () {
      const d = TransportDetails(
        mode: TransportMode.rideHail,
        provider: 'Bolt',
        from: 'A',
        to: 'B',
      );
      final back = TransportDetails.fromJson(d.toJson());
      expect(back.mode, TransportMode.rideHail);
      expect(back.provider, 'Bolt');
      expect(d.toJson().containsKey('people'), isFalse);
    });
  });

  group('itemSubtitle', () {
    test('accommodation shows type and nights', () {
      expect(
        itemSubtitle(_item(ItemCategory.accommodation, {'stay_type': 'airbnb', 'nights': 3})),
        'Airbnb · 3 nights',
      );
      expect(
        itemSubtitle(_item(ItemCategory.accommodation, {'stay_type': 'hostel', 'nights': 1})),
        'Hostel · 1 night',
      );
    });

    test('transport shows mode and provider', () {
      expect(
        itemSubtitle(_item(ItemCategory.transport, {'mode': 'sgr', 'provider': 'Madaraka Express'})),
        'SGR · Madaraka Express',
      );
      expect(itemSubtitle(_item(ItemCategory.transport, {'mode': 'walking'})), 'Walking');
    });

    test('other categories show the category name', () {
      expect(itemSubtitle(_item(ItemCategory.activity, {})), 'Activities');
    });
  });
}