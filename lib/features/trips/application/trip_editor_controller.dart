import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/constants/enums.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/list_utils.dart';
import '../../../data/models/itinerary_item.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/trip_day.dart';
import '../../../data/repositories/day_repository.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../data/repositories/trip_repository.dart';
import '../../../data/models/item_input.dart';

/// State and actions for the trip editor. Every action returns an error
/// message (null on success) that the screen shows in a snackbar.
class TripEditorController extends ChangeNotifier {
  TripEditorController({
    required this.tripId,
    required this._trips,
    required DayRepository days,
    required this._items,
    required this._storage,
  }) : _days = days;

  final String tripId;
  final TripRepository _trips;
  final DayRepository _days;
  final ItemRepository _items;
  final StorageRepository _storage;

  Trip? trip;
  List<TripDay> days = const [];
  Map<String, List<ItineraryItem>> itemsByDay = const {};
  bool loading = true;
  String? loadError;

  /// True once anything was changed (the trip list refreshes when the editor closes).
  bool dirty = false;

  int _saving = 0;
  bool _disposed = false;

  bool get saving => _saving > 0;

  bool get editable =>
      trip?.status == TripStatus.draft || trip?.status == TripStatus.revision;

  /// Days the dates cover that don't exist yet.
  int get missingDays {
    final want = trip?.days;
    if (want == null) return 0;
    return (want - days.length).clamp(0, 1000);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    try {
      final loaded = await Future.wait<Object>([
        _trips.getTrip(tripId),
        _days.forTrip(tripId),
        _items.forTrip(tripId),
      ]);
      trip = loaded[0] as Trip;
      days = loaded[1] as List<TripDay>;

      final grouped = <String, List<ItineraryItem>>{
        for (final d in days) d.id: <ItineraryItem>[],
      };
      for (final item in loaded[2] as List<ItineraryItem>) {
        grouped.putIfAbsent(item.dayId, () => []).add(item);
      }
      itemsByDay = grouped;
      loadError = null;
    } catch (e) {
      loadError = friendlyError(e);
    }
    loading = false;
    _notify();
  }

  /// Runs a save, reloads from the server (always after a failure, so the
  /// screen never shows something that wasn't saved) and returns the error.
  Future<String?> _run(
    Future<void> Function() action, {
    bool reload = true,
  }) async {
    _saving++;
    dirty = true;
    _notify();

    String? error;
    try {
      await action();
    } catch (e) {
      error = friendlyError(e);
    }
    if (reload || error != null) await load();

    _saving--;
    _notify();
    return error;
  }

  // ---------- trip ----------

  Future<String?> updateTrip(Map<String, dynamic> values) =>
      _run(() => _trips.updateFields(tripId, values));

  /// Adds the days the dates cover but the trip doesn't have yet.
  Future<String?> syncDaysToDates() {
    final want = trip?.days;
    if (want == null) return Future.value(null);
    return _run(() => _days.syncToCount(tripId, want));
  }

  /// Removes the photos and the trip itself. Drafts only.
  Future<String?> deleteDraft() async {
    try {
      await _storage.deleteTripFolder(
        tripId,
      ); // before the row: policy needs membership
      await _trips.delete(tripId);
      dirty = true;
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  // ---------- days ----------

  Future<String?> addDay() => _run(() async {
    try {
      await _days.add(tripId);
    } on PostgrestException catch (e) {
      // two people added a day at the same moment: take the next number
      if (e.code == '23505') {
        await _days.add(tripId);
      } else {
        rethrow;
      }
    }
  });

  Future<String?> saveDay(
    String dayId, {
    required String title,
    required String story,
    required List<String> photoUrls,
  }) => _run(
    () => _days.update(dayId, title: title, story: story, photoUrls: photoUrls),
  );

  Future<String?> deleteDay(String dayId) async {
    final day = days.where((d) => d.id == dayId).firstOrNull;
    final urls = <String>[
      ...?day?.photoUrls,
      for (final i in itemsByDay[dayId] ?? const <ItineraryItem>[]) ...i.photos.map((p) => p.url),
    ];

    final err = await _run(() => _days.delete(dayId));
    if (err == null) await _deleteFiles(urls);
    return err;
  }

  Future<String?> deleteItem(String itemId) async {
    final urls = <String>[
      for (final i in itemsByDay.values.expand((l) => l))
        if (i.id == itemId) ...i.photos.map((p) => p.url),
    ];

    final err = await _run(() => _items.delete(itemId));
    if (err == null) await _deleteFiles(urls);
    return err;
  }

  /// Best effort: a leftover file is harmless, a failed delete must not show as an error.
  Future<void> _deleteFiles(List<String> urls) async {
    if (urls.isEmpty) return;
    try {
      await _storage.deleteTripPhotos(urls);
    } catch (_) {}
  }

  Future<String?> reorderDays(List<String> orderedIds) =>
      _run(() => _days.reorder(tripId, orderedIds));

  // ---------- items ----------

  Future<String?> addItem({
    required String dayId,
    required ItemCategory category,
    required String title,
    double amount = 0,
  }) => _run(
    () => _items.add(
      tripId: tripId,
      dayId: dayId,
      category: category,
      title: title,
      amount: amount,
      sortOrder: itemsByDay[dayId]?.length ?? 0,
    ),
  );

  Future<String?> saveItem(
    String itemId, {
    required ItemCategory category,
    required String title,
    required double amount,
  }) => _run(
    () =>
        _items.update(itemId, category: category, title: title, amount: amount),
  );

  /// Full save used by the accommodation / transport forms (and meals and
  /// activities from Week 6). Photos removed from the item are deleted from
  /// storage once the save succeeded.
  Future<String?> saveFullItem({
    String? itemId,
    required String dayId,
    required ItemInput input,
  }) async {
    final before = <String>{
      for (final i in itemsByDay.values.expand((l) => l))
        if (i.id == itemId) ...i.photos.map((p) => p.url),
    };

    final err = await _run(
      () => _items.save(tripId: tripId, dayId: dayId, itemId: itemId, input: input),
    );

    if (err == null) {
      final removed = before.difference(input.photos.map((p) => p.url).toSet()).toList();
      await _deleteFiles(removed);
    }
    return err;
  }

  /// Updates the screen immediately, then saves; a failure reloads the old order.
  Future<String?> reorderItems(String dayId, int oldIndex, int newIndex) {
    final list = [...?itemsByDay[dayId]];
    ReorderUtils.move(list, oldIndex, newIndex);
    itemsByDay = {...itemsByDay, dayId: list};
    _notify();
    return _run(
      () => _items.reorder(dayId, list.map((i) => i.id).toList()),
      reload: false,
    );
  }

  Future<String?> moveItem(String itemId, String toDayId) => _run(
    () => _items.move(
      itemId,
      toDayId: toDayId,
      sortOrder: itemsByDay[toDayId]?.length ?? 0,
    ),
  );
}
