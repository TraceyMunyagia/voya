/// Trip photos are stored twice: `{trip_id}/{id}.jpg` (full) and
/// `{trip_id}/{id}_thumb.jpg` (thumbnail). The database only stores the full
/// URL; the thumbnail URL is derived from it by this naming convention.
class ImageUrls {
  static const thumbSuffix = '_thumb';

  /// `.../abc.jpg?v=1` -> `.../abc_thumb.jpg?v=1`. Safe to call twice.
  static String thumb(String url) {
    final q = url.indexOf('?');
    final base = q == -1 ? url : url.substring(0, q);
    final query = q == -1 ? '' : url.substring(q);

    final dot = base.lastIndexOf('.');
    final slash = base.lastIndexOf('/');
    if (dot <= slash) return url; // no file extension
    if (base.substring(0, dot).endsWith(thumbSuffix)) {
      return url; // already a thumb
    }

    return '${base.substring(0, dot)}$thumbSuffix${base.substring(dot)}$query';
  }

  /// Public URL -> path inside the bucket, or null if the URL isn't from it.
  /// `.../object/public/trip-photos/t1/abc.jpg?v=1` -> `t1/abc.jpg`
  static String? pathInBucket(String url, String bucket) {
    final marker = '/object/public/$bucket/';
    final i = url.indexOf(marker);
    if (i == -1) return null;
    final rest = url.substring(i + marker.length);
    final q = rest.indexOf('?');
    return Uri.decodeComponent(q == -1 ? rest : rest.substring(0, q));
  }
}
