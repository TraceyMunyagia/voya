import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

class StorageRepository {
  StorageRepository(this._storage);

  final SupabaseStorageClient _storage;

  static const _mimeByExt = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// Uploads the picture as `avatars/{userId}/avatar.<ext>` and returns its
  /// public URL. The `?v=` suffix busts image caches after a change.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dot = fileName.lastIndexOf('.');
    var ext = dot == -1 ? 'jpg' : fileName.substring(dot + 1).toLowerCase();
    if (!_mimeByExt.containsKey(ext)) ext = 'jpg';

    final bucket = _storage.from(Buckets.avatars);
    final path = '$userId/avatar.$ext';

    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: _mimeByExt[ext], upsert: true),
    );

    // Best effort: remove an older avatar saved under a different extension.
    try {
      final files = await bucket.list(path: userId);
      final stale = files
          .where((f) => f.name != 'avatar.$ext')
          .map((f) => '$userId/${f.name}')
          .toList();
      if (stale.isNotEmpty) await bucket.remove(stale);
    } catch (_) {}

    return '${bucket.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}
