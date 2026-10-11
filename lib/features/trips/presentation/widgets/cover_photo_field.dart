import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/media_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/photo_source_sheet.dart';
import '../../../../providers/auth_providers.dart';

/// One 16:9 cover photo for a trip. Tap to choose, with Change and remove
/// controls once a photo is set. Calls [onChanged] with the new URL (or null).
class CoverPhotoField extends ConsumerStatefulWidget {
  const CoverPhotoField({
    super.key,
    required this.tripId,
    required this.url,
    required this.onChanged,
  });

  final String tripId;
  final String? url;
  final ValueChanged<String?> onChanged;

  @override
  ConsumerState<CoverPhotoField> createState() => _CoverPhotoFieldState();
}

class _CoverPhotoFieldState extends ConsumerState<CoverPhotoField> {
  final _picker = MediaPicker();
  bool _busy = false;

  Future<void> _pick() async {
    final messenger = ScaffoldMessenger.of(context);
    final source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;
    try {
      final files = await _picker.pick(source);
      if (files.isEmpty || !mounted) return;
      setState(() => _busy = true);
      final uploaded = await ref
          .read(storageRepositoryProvider)
          .uploadTripPhotoFile(tripId: widget.tripId, file: files.first);
      widget.onChanged(uploaded.url);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Material(
          color: AppColors.sand,
          child: InkWell(
            onTap: _busy ? null : _pick,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url == null)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36,
                          color: AppColors.navy,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Add a cover photo',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  AppNetworkImage(url),
                if (url != null && !_busy) ...[
                  Positioned(
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: ActionChip(
                      avatar: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Change'),
                      onPressed: _pick,
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.sm,
                    top: AppSpacing.sm,
                    child: IconButton.filledTonal(
                      tooltip: 'Remove cover photo',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => widget.onChanged(null),
                    ),
                  ),
                ],
                if (_busy)
                  const ColoredBox(
                    color: Colors.black38,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
