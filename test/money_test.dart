import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/media/image_urls.dart';

void main() {
  const base =
      'https://x.supabase.co/storage/v1/object/public/trip-photos/t1/abc.jpg';

  group('ImageUrls.thumb', () {
    test('inserts _thumb before the extension', () {
      expect(
        ImageUrls.thumb(base),
        'https://x.supabase.co/storage/v1/object/public/trip-photos/t1/abc_thumb.jpg',
      );
    });

    test('keeps the query string', () {
      expect(ImageUrls.thumb('$base?v=1'), endsWith('abc_thumb.jpg?v=1'));
    });

    test('is idempotent', () {
      expect(ImageUrls.thumb(ImageUrls.thumb(base)), ImageUrls.thumb(base));
    });

    test('leaves urls without an extension alone', () {
      expect(
        ImageUrls.thumb('https://x.supabase.co/path/file'),
        'https://x.supabase.co/path/file',
      );
    });
  });

  group('ImageUrls.pathInBucket', () {
    test('extracts the path inside the bucket', () {
      expect(ImageUrls.pathInBucket('$base?v=1', 'trip-photos'), 't1/abc.jpg');
    });

    test('returns null for other buckets or foreign urls', () {
      expect(ImageUrls.pathInBucket(base, 'avatars'), isNull);
      expect(
        ImageUrls.pathInBucket('https://example.com/a.jpg', 'trip-photos'),
        isNull,
      );
    });

    test('the thumb of a bucket path is its _thumb sibling', () {
      expect(ImageUrls.thumb('t1/abc.jpg'), 't1/abc_thumb.jpg');
    });
  });
}
