import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../models/itinerary_item.dart';

class ItemRepository {
  ItemRepository(this._db);

  final SupabaseClient _db;

  /// Every item of the trip, in display order.
  Future<List<ItineraryItem>> forTrip(String tripId) async {
    final rows = await _db
        .from(Tbl.itineraryItems)
        .select()
        .eq('trip_id', tripId)
        .order('sort_order')
        .order('created_at');
    return rows.map(ItineraryItem.fromJson).toList();
  }

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
        .update({
          'category': category.name,
          'title': title,
          'cost_amount': amount,
        })
        .eq('id', id)
        .select('id')
        .single();
  }

  Future<void> delete(String id) async {
    await _db
        .from(Tbl.itineraryItems)
        .delete()
        .eq('id', id)
        .select('id')
        .single();
  }

  Future<void> reorder(String dayId, List<String> orderedIds) async {
    await _db.rpc(
      'reorder_items',
      params: {'p_day_id': dayId, 'p_ids': orderedIds},
    );
  }

  /// Moves an item to the end of another day of the same trip.
  Future<void> move(
    String id, {
    required String toDayId,
    required int sortOrder,
  }) async {
    await _db
        .from(Tbl.itineraryItems)
        .update({'day_id': toDayId, 'sort_order': sortOrder})
        .eq('id', id)
        .select('id')
        .single();
  }
}
