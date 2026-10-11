import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProcessedImage {
  const ProcessedImage({required this.full, required this.thumb});

  final Uint8List full;
  final Uint8List thumb;
}

class ImageProcessor {
  static const fullSize = 1600;
  static const fullQuality = 80;
  static const thumbSize = 480;
  static const thumbQuality = 75;

  /// Original photo bytes (JPEG, PNG, WebP or HEIC) -> full + thumbnail JPEGs.
  static Future<ProcessedImage> process(Uint8List original) async {
    final full = await _compress(original, fullSize, fullQuality);
    // Shrinking the already-small full version is faster than the 12MP original.
    final thumb = await _compress(full, thumbSize, thumbQuality);
    return ProcessedImage(full: full, thumb: thumb);
  }

  /// The plugin treats these as lower bounds, so the shorter side of the
  /// result ends up at about [size] pixels. Smaller images are not enlarged.
  static Future<Uint8List> _compress(
    Uint8List bytes,
    int size,
    int quality,
  ) async {
    final out = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: size,
      minHeight: size,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    if (out.isEmpty) throw const FormatException('Could not read that image');
    return out;
  }
}
