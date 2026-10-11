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
import '../../../../providers/auth_providers.dart';

class _Pending {
  _Pending(this.file);

  final XFile file;
  bool started = false;
  bool failed = false;
  String? error;
}

/// Multi-photo editor for a trip, a day or an item. The parent owns the list
/// of URLs and saves it; this widget picks, compresses, uploads (one at a
/// time) and calls [onChanged] with the new list after every change.
class PhotoGridEditor extends ConsumerStatefulWidget {
  const PhotoGridEditor({
    super.key,
    required this.tripId,
    required this.urls,
    required this.onChanged,
    this.maxPhotos = AppConstants.maxPhotosPerItem,
  });

  final String tripId;
  final List<String> urls;
  final ValueChanged<List<String>> onChanged;
  final int maxPhotos;

  @override
  ConsumerState<PhotoGridEditor> createState() => _PhotoGridEditorState();
}

class _PhotoGridEditorState extends ConsumerState<PhotoGridEditor> {
  final _picker = MediaPicker();
  late List<String> _urls = List.of(widget.urls);
  final List<_Pending> _pending = [];
  bool _draining = false;

  int get _room => widget.maxPhotos - _urls.length - _pending.length;

  @override
  void didUpdateWidget(PhotoGridEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent replaced the list from outside (e.g. loaded from the database).
    if (!listEquals(widget.urls, _urls)) _urls = List.of(widget.urls);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  /// Uploads queued photos one at a time.
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
            _urls.add(uploaded.url);
          });
          widget.onChanged(List.of(_urls));
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

  void _remove(String url) {
    setState(() => _urls.remove(url));
    widget.onChanged(List.of(_urls));
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (final url in _urls)
        _PhotoTile(url: url, onRemove: () => _remove(url)),
      for (final p in _pending)
        _PendingTile(
          pending: p,
          onRetry: () => _retry(p),
          onDismiss: () => setState(() => _pending.remove(p)),
        ),
      if (_room > 0) _AddTile(onTap: _add),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: tiles,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_urls.length} / ${widget.maxPhotos} photos',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AppNetworkImage(
          url,
          thumb: true,
          memCacheWidth: 300,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Semantics(
            button: true,
            label: 'Remove photo',
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({
    required this.pending,
    required this.onRetry,
    required this.onDismiss,
  });

  final _Pending pending;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(pending.file.path),
            fit: BoxFit.cover,
            cacheWidth: 300,
            errorBuilder: (context, error, stack) =>
                const ColoredBox(color: AppColors.sand),
          ),
          ColoredBox(color: pending.failed ? Colors.black54 : Colors.black38),
          if (pending.failed) ...[
            Tooltip(
              message: pending.error ?? 'Upload failed. Tap to retry.',
              child: InkWell(
                onTap: onRetry,
                child: const Center(
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDismiss,
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ] else
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add photos',
      child: Material(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: const Center(
            child: Icon(Icons.add_a_photo_outlined, color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}
