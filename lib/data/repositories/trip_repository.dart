import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/trip.dart';

class TripRepository {
  TripRepository(this._db);

  final SupabaseClient _db;

  /// Creates an empty private draft and returns its id.
  Future<String> createDraft({
    required String ownerId,
    required String title,
  }) async {
    final trip = Trip.draft(ownerId: ownerId, title: title);
    final row = await _db
        .from(Tables.trips)
        .insert(trip.toMap())
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Every trip (draft or published) the user owns or co-creates.
  Stream<List<Trip>> watchMyTrips(String uid) {
    return _db
        .from(Tables.trips)
        .stream(primaryKey: ['id'])
        .map(
          (rows) => rows
              .where(
                (row) => (row['member_ids'] as List?)?.contains(uid) == true,
              )
              .map(Trip.fromMap)
              .toList(),
        );
  }

  Stream<Trip?> watchTrip(String tripId) {
    return _db.from(Tables.trips).stream(primaryKey: ['id']).map((rows) {
      final matches = rows.where((row) => row['id'] == tripId);
      return matches.isEmpty ? null : Trip.fromMap(matches.first);
    });
  }
}
