import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/trip.dart';

class TripRepository {
  TripRepository(this._db);

  final SupabaseClient _db;

  /// Trip plus its owner / co-creators.
  static const _withMembers = '*, trip_members(*)';

  String get _uid {
    final user = _db.auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    return user.id;
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
}
