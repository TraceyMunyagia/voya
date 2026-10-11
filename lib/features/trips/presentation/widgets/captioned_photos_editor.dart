import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/media/media_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/photo_source_sheet.dart';
import '../../../../data/models/item_photo.dart';
import '../../../../providers/auth_providers.dart';

class _Pending {
  _Pending(this.file);

  final XFile file;
  bool started = false;
  bool failed = false;
  String? error;
}

/// Photos with an optional caption each ("The boat ride was about 30 minutes
/// and we saw dolphins"). Same pipeline as PhotoGridEditor: photos are
/// compressed and uploaded one at a time as they are chosen. Photos are only
/// attached to the item when the form is saved.
class CaptionedPhotosEditor extends ConsumerStatefulWidget {
  const CaptionedPhotosEditor({
    super.key,
    required this.tripId,
    required this.photos,
    required this.onChanged,
    this.max = AppConstants.maxPhotosPerItem,
  });

  final String tripId;
  final List<ItemPhoto> photos;
  final ValueChanged<List<ItemPhoto>> onChanged;
  final int max;

  @override
  ConsumerState<CaptionedPhotosEditor> createState() => _CaptionedPhotosEditorState();
}

class _CaptionedPhotosEditorState extends ConsumerState<CaptionedPhotosEditor> {
  final _picker = MediaPicker();
  late List<ItemPhoto> _photos = List.of(widget.photos);
  final List<_Pending> _pending = [];
  bool _draining = false;

  int get _room => widget.max - _photos.length - _pending.length;

  @override
  void didUpdateWidget(CaptionedPhotosEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only resync when the parent swapped the photos; caption edits flow upwards only.
    if (!listEquals(widget.photos.map((p) => p.url).toList(), _photos.map((p) => p.url).toList())) {
      _photos = List.of(widget.photos);
    }
  }

  Future<void> _add() async {
    if (_room <= 0) return;
    final source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;
    try {
      final files = await _picker.pick(source, limit: _room);
      if (files.isEmpty || !mounted) return;
      setState(() => _pending.addAll(files.take(_room).map(_Pending.new)));
      _drain();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (mounted) {
        final next = _pending.where((p) => !p.started && !p.failed).firstOrNull;
        if (next == null) break;
        next.started = true;
        try {
          final uploaded = await ref
              .read(storageRepositoryProvider)
              .uploadTripPhotoFile(tripId: widget.tripId, file: next.file);
          if (!mounted) return;
          setState(() {
            _pending.remove(next);
            _photos.add(ItemPhoto(url: uploaded.url));
          });
          widget.onChanged(List.of(_photos));
        } catch (e) {
          if (!mounted) return;
          setState(() {
            next.failed = true;
            next.error = friendlyError(e);
          });
        }
      }
    } finally {
      _draining = false;
    }
  }

  void _retry(_Pending p) {
    setState(() {
      p.failed = false;
      p.started = false;
      p.error = null;
    });
    _drain();
  }

  void _setCaption(int i, String caption) {
    _photos[i] = _photos[i].copyWith(caption: caption);
    widget.onChanged(List.of(_photos));
  }

  void _remove(int i) {
    setState(() => _photos.removeAt(i));
    widget.onChanged(List.of(_photos));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _photos.length; i++)
          Padding(
            key: ValueKey(_photos[i].url),
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: AppNetworkImage(
                    _photos[i].url,
                    thumb: true,
                    memCacheWidth: 300,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    initialValue: _photos[i].caption,
                    maxLength: 200,
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(labelText: 'Caption (optional)'),
                    onChanged: (v) => _setCaption(i, v),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove photo',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _remove(i),
                ),
              ],
            ),
          ),
        for (final p in _pending)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.file(
                      File(p.file.path),
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      errorBuilder: (context, error, stack) =>
                          const ColoredBox(color: AppColors.sand),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: p.failed
                      ? InkWell(
                          onTap: () => _retry(p),
                          child: Text(
                            '${p.error ?? 'Upload failed.'} Tap to retry.',
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        )
                      : const Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text('Uploading…'),
                          ],
                        ),
                ),
                if (p.failed)
                  IconButton(
                    tooltip: 'Discard',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _pending.remove(p)),
                  ),
              ],
            ),
          ),
        if (_room > 0)
          OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Add photos'),
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_photos.length} / ${widget.max} photos',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}