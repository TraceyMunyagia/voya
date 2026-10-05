import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/constants/enums.dart';
import 'package:voya/data/models/trip.dart';

void main() {
  test('parses a Supabase trip row', () {
    final trip = Trip.fromMap({
      'id': 'trip-1',
      'owner_id': 'user-1',
      'member_ids': ['user-1'],
      'title': 'Diani weekend',
      'type': 'friends',
      'status': 'published',
      'travellers': 3,
      'total_cost': 45000,
    });

    expect(trip.id, 'trip-1');
    expect(trip.memberIds, ['user-1']);
    expect(trip.type, TripType.friends);
    expect(trip.status, TripStatus.published);
    expect(trip.totalCost, 45000);
  });
}
