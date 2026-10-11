import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/trip.dart';
import '../../core/constants/enums.dart';
import '../../core/utils/dates.dart';

class TripRepository {
  TripRepository(this._db);

  final SupabaseClient _db;

  /// Trip plus its owner / co-creators.
  static const _withMembers =
      '*, trip_members(*, profiles(id, username, display_name, photo_url))';
  String get _uid {
    final user = _db.auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    return user.id;
  }

  /// Newest published trips for the feed (Week 9 adds following / trending).
  Future<List<Trip>> publishedTrips({int limit = 20, int offset = 0}) async {
    final rows = await _db
        .from(Tbl.trips)
        .select(_withMembers)
        .eq('status', 'published')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return rows.map(Trip.fromJson).toList();
  }

  /// Creates an empty private draft. A database trigger adds the creator
  /// as the owner member, so the trip is re-fetched afterwards to include it.
  Future<Trip> createDraft({required String title}) async {
    final row = await _db
        .from(Tbl.trips)
        .insert({'owner_id': _uid, 'title': title, 'status': 'draft'})
        .select('id')
        .single();
    return getTrip(row['id'] as String);
  }

  Future<Trip> getTrip(String id) async {
    final row = await _db
        .from(Tbl.trips)
        .select(_withMembers)
        .eq('id', id)
        .single();
    return Trip.fromJson(row);
  }

  /// Every trip (draft or published) the user owns or co-creates.
  Future<List<Trip>> myTrips() async {
    final memberships = await _db
        .from(Tbl.tripMembers)
        .select('trip_id')
        .eq('user_id', _uid);
    final ids = memberships.map((r) => r['trip_id'] as String).toList();
    if (ids.isEmpty) return [];

    final rows = await _db
        .from(Tbl.trips)
        .select(_withMembers)
        .inFilter('id', ids)
        .order('updated_at', ascending: false);
    return rows.map(Trip.fromJson).toList();
  }

  /// Live updates for one trip (members are not included in realtime rows).
  Stream<Trip?> watchTrip(String id) {
    return _db
        .from(Tbl.trips)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty ? null : Trip.fromJson(rows.first));
  }

  /// Creates a private draft with its basics. Days are created separately
  /// with DayRepository.syncToCount.
  Future<Trip> create({
    required String title,
    List<String> destinations = const [],
    TripType type = TripType.solo,
    int travellers = 1,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final row = await _db
        .from(Tbl.trips)
        .insert({
          'owner_id': _uid,
          'title': title,
          'status': 'draft',
          'destinations': destinations,
          'type': type.name,
          'travellers': travellers,
          'start_date': startDate == null ? null : Dates.iso(startDate),
          'end_date': endDate == null ? null : Dates.iso(endDate),
        })
        .select('id')
        .single();
    return getTrip(row['id'] as String);
  }

  /// Partial update, e.g. `{'title': 'Diani', 'cover_photo_url': url}`.
  Future<void> updateFields(String id, Map<String, dynamic> values) async {
    await _db.from(Tbl.trips).update(values).eq('id', id).select('id').single();
  }

  /// Only the owner can delete, and only while it is a draft (row security).
  Future<void> delete(String id) async {
    await _db.from(Tbl.trips).delete().eq('id', id).select('id').single();
  }
}
