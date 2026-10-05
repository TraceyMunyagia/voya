import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/storage_repository.dart';
import 'supabase_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseProvider).auth),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseProvider)),
);

/// The signed-in user's profile row (null when signed out).
/// It reloads whenever the signed-in user's id changes.
class CurrentProfileNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final uid = ref.watch(currentUserProvider.select((u) => u?.id));
    if (uid == null) return null;
    return ref.read(profileRepositoryProvider).getProfile(uid);
  }

  /// Call after an update so the router and the UI see new values immediately.
  void setProfile(AppUser profile) => state = AsyncData(profile);

  Future<void> reload() async {
    final uid = ref.read(currentUserProvider)?.id;
    if (uid == null) return;
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getProfile(uid),
    );
  }
}

final currentProfileProvider =
    AsyncNotifierProvider<CurrentProfileNotifier, AppUser?>(
      CurrentProfileNotifier.new,
    );
final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => StorageRepository(ref.watch(supabaseProvider).storage),
);
