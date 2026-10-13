import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/constants/enums.dart';
import 'package:voya/data/models/cost.dart';
import 'package:voya/data/models/item_details.dart';
import 'package:voya/data/models/item_input.dart';
import 'package:voya/data/models/itinerary_item.dart';

ItineraryItem _activity({String? travelMode, Cost travelCost = const Cost()}) => ItineraryItem(
  id: 'a',
  tripId: 't1',
  dayId: 'd2',
  category: ItemCategory.activity,
  title: 'Fort Jesus',
  cost: const Cost(amount: 600, basis: CostBasis.perPerson),
  travelMode: travelMode,
  travelCost: travelCost,
);

void main() {
  group('trip legs', () {
    test('a leg survives a round trip through details', () {
      const d = TransportDetails(
        mode: TransportMode.flight,
        from: 'Diani',
        leg: TransportLeg.returning,
      );
      final back = TransportDetails.fromJson(d.toJson());
      expect(back.leg, TransportLeg.returning);
      expect(back.from, 'Diani');
    });

    test('transport saved before legs existed reads as going there', () {
      expect(TransportDetails.fromJson(const {'mode': 'sgr'}).leg, TransportLeg.outbound);
    });
  });

  group('getting to an activity', () {
    test('travel reads the saved mode', () {
      expect(_activity(travelMode: 'boda_boda').travel, TransportMode.boda);
      expect(_activity().travel, isNull);
    });

    test("the ride's cost is added to the grand total only", () {
      final item = _activity(
        travelMode: 'taxi',
        travelCost: const Cost(amount: 1000, basis: CostBasis.perVehicle),
      );
      expect(item.totalFor(4), 2400); // 600 x 4 people
      expect(item.travelTotalFor(4), 1000);
      expect(item.grandTotalFor(4), 3400);
    });

    test('walking is free and taxis are charged per vehicle', () {
      expect(TransportMode.walking.defaultTravelBasis, CostBasis.free);
      expect(TransportMode.taxi.defaultTravelBasis, CostBasis.perVehicle);
      expect(TransportMode.matatu.defaultTravelBasis, CostBasis.perPerson);
    });

    test('the travel columns are saved, and cleared when there is no ride', () {
      const withRide = ItemInput(
        category: ItemCategory.activity,
        title: 'x',
        travelMode: 'matatu',
        travelAmount: 150,
        travelBasis: CostBasis.perPerson,
        travelNote: 'From the Airbnb',
      );
      expect(withRide.toFields()['travel_mode'], 'matatu');
      expect(withRide.toFields()['travel_cost_amount'], 150);
      expect(withRide.toFields()['travel_cost_basis'], 'per_person');
      expect(withRide.toFields()['travel_note'], 'From the Airbnb');

      const noRide = ItemInput(category: ItemCategory.activity, title: 'x', travelNote: 'stale');
      expect(noRide.toFields()['travel_mode'], isNull);
      expect(noRide.toFields()['travel_cost_amount'], 0);
      expect(noRide.toFields()['travel_note'], '');
    });
  });
}
