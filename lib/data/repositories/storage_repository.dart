import 'dart:typed_data';

import 'package:image_picker/image_picker.dart' show XFile;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/media/image_processor.dart';
import '../../core/media/image_urls.dart';

class UploadedPhoto {
  const UploadedPhoto({required this.url, required this.thumbUrl});

  final String url;
  final String thumbUrl;
}

class StorageRepository {
  StorageRepository(this._storage);

  final SupabaseStorageClient _storage;

  static const _mimeByExt = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  // ---------- avatars (Week 2) ----------

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

  // ---------- trip photos (Week 3) ----------

  /// Picked file -> compressed full + thumb -> uploaded.
  Future<UploadedPhoto> uploadTripPhotoFile({
    required String tripId,
    required XFile file,
  }) async {
    final original = await file.readAsBytes();
    final processed = await ImageProcessor.process(original);
    return uploadTripPhoto(tripId: tripId, image: processed);
  }

  /// Stores `{tripId}/{id}.jpg` and `{tripId}/{id}_thumb.jpg`. Files get a
  /// random id, so nothing is ever overwritten and they can be cached for a year.
  Future<UploadedPhoto> uploadTripPhoto({
    required String tripId,
    required ProcessedImage image,
  }) async {
    final id = const Uuid().v4();
    final bucket = _storage.from(Buckets.tripPhotos);
    final path = '$tripId/$id.jpg';
    final thumbPath = '$tripId/${id}_thumb.jpg';
    const options = FileOptions(
      contentType: 'image/jpeg',
      cacheControl: '31536000',
    );

    await bucket.uploadBinary(path, image.full, fileOptions: options);
    try {
      await bucket.uploadBinary(thumbPath, image.thumb, fileOptions: options);
    } catch (_) {
      // Don't leave a full image without its thumbnail.
      try {
        await bucket.remove([path]);
      } catch (_) {}
      rethrow;
    }

    return UploadedPhoto(
      url: bucket.getPublicUrl(path),
      thumbUrl: bucket.getPublicUrl(thumbPath),
    );
  }

  /// Removes photos (full + thumb) by their stored URLs. Used when a draft
  /// trip or an item is deleted (Week 4 onwards).
  Future<void> deleteTripPhotos(List<String> urls) async {
    final paths = <String>[];
    for (final url in urls) {
      final path = ImageUrls.pathInBucket(url, Buckets.tripPhotos);
      if (path == null) continue;
      paths
        ..add(path)
        ..add(ImageUrls.thumb(path));
    }
    if (paths.isNotEmpty) {
      await _storage.from(Buckets.tripPhotos).remove(paths);
    }
  }

  /// Removes every file (photos and thumbnails) under `trip-photos/{tripId}/`.
  /// Call this BEFORE deleting the trip row: the storage policy checks
  /// membership, which disappears with the row.
  Future<void> deleteTripFolder(String tripId) async {
    final bucket = _storage.from(Buckets.tripPhotos);
    final files = await bucket.list(
      path: tripId,
      searchOptions: const SearchOptions(limit: 1000),
    );
    final paths = files
        .where((f) => f.id != null)
        .map((f) => '$tripId/${f.name}')
        .toList();
    if (paths.isNotEmpty) await bucket.remove(paths);
  }
}
