import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/constants/enums.dart';
import 'package:voya/data/models/trip.dart';

void main() {
  test('parses a trip row with its members', () {
    final trip = Trip.fromJson({
      'id': 't1',
      'owner_id': 'u1',
      'title': 'Diani Girls Trip',
      'status': 'review',
      'type': 'friends',
      'travellers': 4,
      'start_date': '2026-12-01',
      'end_date': '2026-12-04',
      'destinations': ['Diani'],
      'trip_members': [
        {'trip_id': 't1', 'user_id': 'u1', 'role': 'owner', 'approved': true},
        {
          'trip_id': 't1',
          'user_id': 'u2',
          'role': 'co_creator',
          'approved': false,
        },
      ],
    });

    expect(trip.status, TripStatus.review);
    expect(trip.type, TripType.friends);
    expect(trip.nights, 3);
    expect(trip.memberIds, ['u1', 'u2']);
    expect(trip.members.first.role, MemberRole.owner);
    expect(trip.allApproved, isFalse);
  });

  test('a bare row falls back to safe defaults', () {
    final trip = Trip.fromJson({'id': 't', 'owner_id': 'u', 'title': 'x'});
    expect(trip.status, TripStatus.draft);
    expect(trip.memberIds, ['u']);
    expect(trip.totalCost, 0);
  });

  test('toUpdateJson formats dates as yyyy-MM-dd', () {
    final trip = Trip(
      id: 't',
      ownerId: 'u',
      title: 'x',
      startDate: DateTime(2026, 12, 1),
    );
    expect(trip.toUpdateJson()['start_date'], '2026-12-01');
  });
}
