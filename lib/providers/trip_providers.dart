import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/trip.dart';
import '../data/repositories/day_repository.dart';
import '../data/repositories/item_repository.dart';
import 'supabase_providers.dart';

final dayRepositoryProvider = Provider<DayRepository>(
  (ref) => DayRepository(ref.watch(supabaseProvider)),
);

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepository(ref.watch(supabaseProvider)),
);

/// Every trip the signed-in user owns or co-creates (drafts included).
/// Call `ref.invalidate(myTripsProvider)` after changing trips.
final myTripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) async {
  final uid = ref.watch(currentUserProvider.select((u) => u?.id));
  if (uid == null) return [];
  return ref.watch(tripRepositoryProvider).myTrips();
});
