import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/busy_button.dart';
import '../../../core/widgets/form_error.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/supabase_providers.dart';
import '../../profile/presentation/widgets/avatar_picker.dart';

class ProfileDetailsStep extends ConsumerStatefulWidget {
  const ProfileDetailsStep({super.key});

  @override
  ConsumerState<ProfileDetailsStep> createState() => _ProfileDetailsStepState();
}

class _ProfileDetailsStepState extends ConsumerState<ProfileDetailsStep> {
  final _city = TextEditingController();
  final _bio = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _city.dispose();
    _bio.dispose();
    super.dispose();
  }

  /// [skip] keeps city and bio empty but still finishes onboarding.
  Future<void> _finish({bool skip = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uid = ref.read(currentUserProvider)!.id;
      final values = <String, dynamic>{'onboarding_completed': true};
      if (!skip) {
        values['city'] = _city.text.trim();
        values['bio'] = _bio.text.trim();
      }
      final updated = await ref
          .read(profileRepositoryProvider)
          .update(uid, values);
      // The router guard now sends the user to Home.
      ref.read(currentProfileProvider.notifier).setProfile(updated);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final username = ref.watch(currentProfileProvider).value?.username;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Make it yours', style: text.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                username == null
                    ? 'Add a photo and a few details. All optional.'
                    : 'Looking good, @$username. Add a photo and a few details. All optional.',
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Center(child: AvatarPicker(radius: 56)),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _city,
                label: 'City',
                textInputAction: TextInputAction.next,
                maxLength: 60,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _bio,
                label: 'Short bio',
                maxLength: 280,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: AppSpacing.md),
              FormError(_error),
              BusyButton(
                label: 'Finish',
                busy: _busy,
                onPressed: () => _finish(),
              ),
              TextButton(
                onPressed: _busy ? null : () => _finish(skip: true),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
