import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/busy_button.dart';
import '../../../core/widgets/form_error.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/supabase_providers.dart';
import 'widgets/auth_scaffold.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _city = TextEditingController();
  final _bio = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profileState = ref.read(currentProfileProvider);
    final profile = profileState.hasValue ? profileState.value : null;
    _name.text = profile?.displayName ?? '';
    _username.text = profile?.username ?? '';
    _city.text = profile?.city ?? '';
    _bio.text = profile?.bio ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _city.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(currentUserProvider)?.id;
    if (uid == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = await ref.read(profileRepositoryProvider).update(uid, {
        'display_name': _name.text.trim(),
        'username': _username.text.trim().toLowerCase(),
        'city': _city.text.trim(),
        'bio': _bio.text.trim(),
        'onboarding_completed': true,
      });
      ref.read(currentProfileProvider.notifier).setProfile(profile);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Make Voya yours',
      subtitle: 'Set up your profile before you start sharing trips.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _name,
                label: 'Display name',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (value) =>
                    Validators.required(value, 'Enter your name'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _username,
                label: 'Username',
                prefixText: '@',
                textInputAction: TextInputAction.next,
                autocorrect: false,
                validator: (value) {
                  final error = Validators.required(value, 'Choose a username');
                  if (error != null) return error;
                  if (!RegExp(
                    r'^[a-z0-9_]{3,24}$',
                  ).hasMatch(value!.trim().toLowerCase())) {
                    return 'Use 3–24 lowercase letters, numbers, or underscores';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _city,
                label: 'City (optional)',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _bio,
                label: 'Bio (optional)',
                maxLines: 3,
                maxLength: 280,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FormError(_error),
        BusyButton(label: 'Continue', busy: _busy, onPressed: _submit),
      ],
    );
  }
}
