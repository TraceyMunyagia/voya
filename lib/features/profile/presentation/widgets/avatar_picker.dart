import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../providers/auth_providers.dart';
import '../../../../providers/supabase_providers.dart';

/// Tap to choose a photo. It uploads straight away and updates the profile,
/// so callers don't need to hold the file.
class AvatarPicker extends ConsumerStatefulWidget {
  const AvatarPicker({super.key, this.radius = 48});

  final double radius;

  @override
  ConsumerState<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<AvatarPicker> {
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (file == null) return;

      setState(() => _busy = true);
      final uid = ref.read(currentUserProvider)!.id;
      final bytes = await file.readAsBytes();
      final url = await ref
          .read(storageRepositoryProvider)
          .uploadAvatar(userId: uid, bytes: bytes, fileName: file.name);
      final updated = await ref.read(profileRepositoryProvider).update(uid, {
        'photo_url': url,
      });
      ref.read(currentProfileProvider.notifier).setProfile(updated);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final r = widget.radius;

    return Semantics(
      button: true,
      label: 'Change profile photo',
      child: GestureDetector(
        onTap: _busy ? null : _pick,
        child: SizedBox(
          width: r * 2,
          height: r * 2,
          child: Stack(
            children: [
              UserAvatar(
                photoUrl: profile?.photoUrl,
                initials: profile?.initials ?? '?',
                radius: r,
              ),
              if (_busy)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              const Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.coral,
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
