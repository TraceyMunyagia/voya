import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/constants/enums.dart';
import 'package:voya/data/models/itinerary_item.dart';

Map<String, dynamic> _row({
  String basis = 'per_person',
  num amount = 1500,
  Map<String, dynamic> details = const {},
}) =>
    {
      'id': 'i1',
      'trip_id': 't1',
      'day_id': 'd1',
      'category': 'transport',
      'title': 'Nairobi → Mombasa',
      'cost_amount': amount,
      'cost_basis': basis,
      'details': details,
    };

void main() {
  test('photos are parsed and sorted by sort_order', () {
    final item = ItineraryItem.fromJson({
      ..._row(),
      'item_photos': [
        {'id': 'b', 'url': 'u2', 'caption': 'second', 'sort_order': 1},
        {'id': 'a', 'url': 'u1', 'caption': 'first', 'sort_order': 0},
      ],
    });
    expect(item.photos.map((p) => p.caption), ['first', 'second']);
    expect(item.photoUrls, ['u1', 'u2']);
  });

  test('an item without photos has an empty list', () {
    expect(ItineraryItem.fromJson(_row()).photos, isEmpty);
  });

  group('totalFor', () {
    test('per person uses the trip travellers unless the item overrides people', () {
      expect(ItineraryItem.fromJson(_row()).totalFor(4), 6000);
      expect(ItineraryItem.fromJson(_row(details: {'people': 2})).totalFor(4), 3000);
    });

    test('per night uses the item nights', () {
      final item = ItineraryItem.fromJson(
        _row(basis: 'per_night', amount: 5000, details: {'nights': 3}),
      );
      expect(item.totalFor(4), 15000);
    });

    test('per vehicle and one-time stay flat, free is zero', () {
      expect(ItineraryItem.fromJson(_row(basis: 'per_vehicle', amount: 2400)).totalFor(4), 2400);
      expect(ItineraryItem.fromJson(_row(basis: 'one_time', amount: 900)).totalFor(4), 900);
      expect(ItineraryItem.fromJson(_row(basis: 'free', amount: 900)).totalFor(4), 0);
    });
  });

  test('the cost basis uses the database spelling', () {
    expect(ItineraryItem.fromJson(_row(basis: 'per_vehicle')).cost.basis, CostBasis.perVehicle);
  });
}