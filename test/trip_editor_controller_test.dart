import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/constants/enums.dart';
import 'package:voya/data/models/itinerary_item.dart';
import 'package:voya/data/models/trip.dart';
import 'package:voya/data/models/trip_day.dart';
import 'package:voya/data/repositories/day_repository.dart';
import 'package:voya/data/repositories/item_repository.dart';
import 'package:voya/data/repositories/storage_repository.dart';
import 'package:voya/data/repositories/trip_repository.dart';
import 'package:voya/features/trips/application/trip_editor_controller.dart';
import 'package:voya/data/models/item_input.dart';
import 'package:voya/data/models/item_photo.dart';

// Only the methods the controller calls are implemented; anything else fails loudly.
class _FakeTrips implements TripRepository {
  Trip trip = Trip(
    id: 't1',
    ownerId: 'u1',
    title: 'Diani',
    status: TripStatus.draft,
    startDate: DateTime(2026, 12, 1),
    endDate: DateTime(2026, 12, 4),
  );
  int deleted = 0;

  @override
  Future<Trip> getTrip(String id) async => trip;

  @override
  Future<void> updateFields(String id, Map<String, dynamic> values) async {}

  @override
  Future<void> delete(String id) async => deleted++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDays implements DayRepository {
  List<TripDay> days = [
    for (var i = 1; i <= 3; i++) TripDay(id: 'd$i', tripId: 't1', dayNumber: i),
  ];

  @override
  Future<List<TripDay>> forTrip(String tripId) async => List.of(days);

  @override
  Future<TripDay> add(String tripId) async {
    final d = TripDay(
      id: 'd${days.length + 1}',
      tripId: tripId,
      dayNumber: days.length + 1,
    );
    days.add(d);
    return d;
  }

  @override
  Future<void> syncToCount(String tripId, int count) async {
    while (days.length < count) {
      await add(tripId);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeItems implements ItemRepository {
  bool failReorder = false;
  ItemInput? lastSaved;
  List<ItineraryItem> items = [
    for (final id in ['a', 'b', 'c'])
      ItineraryItem(
        id: id,
        tripId: 't1',
        dayId: 'd1',
        category: ItemCategory.activity,
        title: id,
        sortOrder: 'abc'.indexOf(id),
        photos: id == 'a'
            ? const [ItemPhoto(url: 'u1'), ItemPhoto(url: 'u2')]
            : const [],
      ),
  ];

  @override
  Future<List<ItineraryItem>> forTrip(String tripId) async =>
      [...items]..sort((x, y) => x.sortOrder.compareTo(y.sortOrder));

  @override
  Future<void> reorder(String dayId, List<String> orderedIds) async {
    if (failReorder) throw Exception('boom');
    items = [
      for (var i = 0; i < orderedIds.length; i++)
        ItineraryItem(
          id: orderedIds[i],
          tripId: 't1',
          dayId: dayId,
          category: ItemCategory.activity,
          title: orderedIds[i],
          sortOrder: i,
          photos: items.firstWhere((x) => x.id == orderedIds[i]).photos,
        ),
    ];
  }

  @override
  Future<String> save({
    required String tripId,
    required String dayId,
    String? itemId,
    required ItemInput input,
  }) async {
    lastSaved = input;
    return itemId ?? 'new';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStorage implements StorageRepository {
  int folderDeletes = 0;

  @override
  Future<void> deleteTripFolder(String tripId) async => folderDeletes++;

  List<String> deletedUrls = [];

  @override
  Future<void> deleteTripPhotos(List<String> urls) async => deletedUrls = urls;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeTrips trips;
  late _FakeDays days;
  late _FakeItems items;
  late _FakeStorage storage;
  late TripEditorController c;

  setUp(() async {
    trips = _FakeTrips();
    days = _FakeDays();
    items = _FakeItems();
    storage = _FakeStorage();
    c = TripEditorController(
      tripId: 't1',
      trips: trips,
      days: days,
      items: items,
      storage: storage,
    );
    await c.load();
  });

  tearDown(() => c.dispose());

  List<String> order(String dayId) =>
      c.itemsByDay[dayId]!.map((i) => i.id).toList();

  test('load groups items under their day and keeps empty days', () {
    expect(c.days.length, 3);
    expect(order('d1'), ['a', 'b', 'c']);
    expect(c.itemsByDay['d2'], isEmpty);
    expect(c.editable, isTrue);
  });

  test('reorderItems saves the new order', () async {
    final err = await c.reorderItems('d1', 0, 3); // drag a to the end
    expect(err, isNull);
    expect(order('d1'), ['b', 'c', 'a']);
    expect(items.items.map((i) => i.id), ['b', 'c', 'a']);
  });

  test(
    'a failed reorder rolls back to the saved order and reports it',
    () async {
      items.failReorder = true;
      final err = await c.reorderItems('d1', 0, 3);
      expect(err, isNotNull);
      expect(order('d1'), ['a', 'b', 'c']);
    },
  );

  test('missingDays compares the dates with the days that exist', () async {
    days.days.removeLast(); // dates cover 4 days, trip has 2
    await c.load();
    expect(c.missingDays, 2);

    final err = await c.syncDaysToDates();
    expect(err, isNull);
    expect(c.missingDays, 0);
    expect(c.days.length, 4);
  });

  test('published trips are read-only', () async {
    trips.trip = Trip(
      id: 't1',
      ownerId: 'u1',
      title: 'x',
      status: TripStatus.published,
    );
    await c.load();
    expect(c.editable, isFalse);
  });

  test('deleteDraft removes the photos folder, then the trip', () async {
    final err = await c.deleteDraft();
    expect(err, isNull);
    expect(storage.folderDeletes, 1);
    expect(trips.deleted, 1);
  });

  test('saveFullItem sends the input and deletes photos that were removed', () async {
    const input = ItemInput(
      category: ItemCategory.accommodation,
      title: 'Hotel',
      photos: [ItemPhoto(url: 'u2')], // u1 was taken off
    );
    final err = await c.saveFullItem(itemId: 'a', dayId: 'd1', input: input);

    expect(err, isNull);
    expect(items.lastSaved?.title, 'Hotel');
    expect(storage.deletedUrls, ['u1']);
  });

  test('saveFullItem on a new item deletes nothing', () async {
    const input = ItemInput(
      category: ItemCategory.transport,
      title: 'SGR',
      photos: [ItemPhoto(url: 'new1')],
    );
    final err = await c.saveFullItem(dayId: 'd1', input: input);

    expect(err, isNull);
    expect(storage.deletedUrls, isEmpty);
  });
}
