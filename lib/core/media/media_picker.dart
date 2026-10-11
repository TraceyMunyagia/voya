import 'package:image_picker/image_picker.dart';

/// Thin wrapper over image_picker. Returns the original files untouched;
/// compression happens later in [ImageProcessor], one image at a time,
/// so ten 12MP photos never sit in memory together.
class MediaPicker {
  MediaPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<List<XFile>> pick(ImageSource source, {int limit = 1}) async {
    if (source == ImageSource.camera) {
      final f = await _picker.pickImage(source: ImageSource.camera);
      return f == null ? [] : [f];
    }
    if (limit <= 1) {
      final f = await _picker.pickImage(source: ImageSource.gallery);
      return f == null ? [] : [f];
    }
    final files = await _picker.pickMultiImage(limit: limit);
    return files.take(limit).toList();
  }
}
