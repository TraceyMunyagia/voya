import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../models/item_input.dart';
import '../models/itinerary_item.dart';

class ItemRepository {
  ItemRepository(this._db);

  final SupabaseClient _db;

  /// Every item of the trip with its photos, in display order.
  Future<List<ItineraryItem>> forTrip(String tripId) async {
    final rows = await _db
        .from(Tbl.itineraryItems)
        .select('*, item_photos(*)')
        .eq('trip_id', tripId)
        .order('sort_order')
        .order('created_at');
    return rows.map(ItineraryItem.fromJson).toList();
  }

  /// Creates (itemId null) or fully updates an item and its photos in one
  /// database transaction. [dayId] is null for trip-level items (accommodation
  /// and transport). Returns the item's id.
  Future<String> save({
    required String tripId,
    String? dayId,
    String? itemId,
    required ItemInput input,
  }) async {
    final id = await _db.rpc('save_item', params: {
      'p_trip_id': tripId,
      'p_day_id': dayId,
      'p_item_id': itemId,
      'p_fields': input.toFields(),
      'p_photos': input.toPhotos(),
    });
    return id as String;
  }

  // ---- quick versions used by the meal / activity sheet until Week 6 ----

  Future<void> add({
    required String tripId,
    required String dayId,
    required ItemCategory category,
    required String title,
    required int sortOrder,
    double amount = 0,
    CostBasis basis = CostBasis.oneTime,
  }) async {
    await _db.from(Tbl.itineraryItems).insert({
      'trip_id': tripId,
      'day_id': dayId,
      'category': category.name,
      'title': title,
      'sort_order': sortOrder,
      'cost_amount': amount,
      'cost_basis': basis.db,
    });
  }

  Future<void> update(
    String id, {
    required ItemCategory category,
    required String title,
    required double amount,
  }) async {
    await _db
        .from(Tbl.itineraryItems)
        .update({'category': category.name, 'title': title, 'cost_amount': amount})
        .eq('id', id)
        .select('id')
        .single();
  }

  Future<void> delete(String id) async {
    await _db.from(Tbl.itineraryItems).delete().eq('id', id).select('id').single();
  }

  Future<void> reorder(String dayId, List<String> orderedIds) async {
    await _db.rpc('reorder_items', params: {'p_day_id': dayId, 'p_ids': orderedIds});
  }

  /// Moves an item to the end of another day of the same trip.
  Future<void> move(String id, {required String toDayId, required int sortOrder}) async {
    await _db
        .from(Tbl.itineraryItems)
        .update({'day_id': toDayId, 'sort_order': sortOrder})
        .eq('id', id)
        .select('id')
        .single();
  }
}