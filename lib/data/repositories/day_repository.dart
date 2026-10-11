import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/trip_day.dart';

class DayRepository {
  DayRepository(this._db);

  final SupabaseClient _db;

  Future<List<TripDay>> forTrip(String tripId) async {
    final rows = await _db
        .from(Tbl.tripDays)
        .select()
        .eq('trip_id', tripId)
        .order('day_number');
    return rows.map(TripDay.fromJson).toList();
  }

  /// Appends the next day number (server-side, so two people can't clash).
  Future<TripDay> add(String tripId) async {
    final row = await _db.rpc('add_day', params: {'p_trip_id': tripId});
    return TripDay.fromJson(Map<String, dynamic>.from(row as Map));
  }

  /// Makes sure days 1..[days] exist. Never removes any.
  Future<void> syncToCount(String tripId, int days) async {
    await _db.rpc(
      'sync_trip_days',
      params: {'p_trip_id': tripId, 'p_days': days},
    );
  }

  Future<void> update(
    String dayId, {
    required String title,
    required String story,
    required List<String> photoUrls,
  }) async {
    await _db
        .from(Tbl.tripDays)
        .update({'title': title, 'story': story, 'photo_urls': photoUrls})
        .eq('id', dayId)
        .select('id')
        .single();
  }

  /// Deletes the day and its items, then closes the gap in the numbering.
  Future<void> delete(String dayId) async {
    await _db.rpc('delete_day', params: {'p_day_id': dayId});
  }

  /// [orderedIds] must contain every day of the trip.
  Future<void> reorder(String tripId, List<String> orderedIds) async {
    await _db.rpc(
      'reorder_days',
      params: {'p_trip_id': tripId, 'p_ids': orderedIds},
    );
  }
}
