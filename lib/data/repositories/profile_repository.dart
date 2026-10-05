import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/app_user.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  final SupabaseClient _db;

  Future<AppUser> getProfile(String uid) async {
    final row = await _db.from(Tbl.profiles).select().eq('id', uid).single();
    return AppUser.fromJson(row);
  }

  /// True if nobody else has this username (your own current one counts as free).
  Future<bool> isUsernameAvailable(
    String username, {
    String? exceptUserId,
  }) async {
    final row = await _db
        .from(Tbl.profiles)
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return row == null || row['id'] == exceptUserId;
  }

  /// Only these columns are writable by clients (see the Day 11 migration):
  /// username, display_name, photo_url, bio, city, onboarding_completed.
  Future<AppUser> update(String uid, Map<String, dynamic> values) async {
    final row = await _db
        .from(Tbl.profiles)
        .update(values)
        .eq('id', uid)
        .select()
        .single();
    return AppUser.fromJson(row);
  }
}
