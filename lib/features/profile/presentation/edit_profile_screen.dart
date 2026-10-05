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
import 'widgets/avatar_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _city;
  late final TextEditingController _bio;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(currentProfileProvider).value;
    _name = TextEditingController(text: p?.displayName ?? '');
    _username = TextEditingController(text: p?.username ?? '');
    _city = TextEditingController(text: p?.city ?? '');
    _bio = TextEditingController(text: p?.bio ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _city.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = ref.read(currentProfileProvider).value!;
      final updated = await ref
          .read(profileRepositoryProvider)
          .update(profile.id, {
            'display_name': _name.text.trim(),
            'city': _city.text.trim(),
            'bio': _bio.text.trim(),
          });
      ref.read(currentProfileProvider.notifier).setProfile(updated);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AvatarPicker(radius: 52)),
                  const SizedBox(height: AppSpacing.lg),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _name,
                          label: 'Your name',
                          textInputAction: TextInputAction.next,
                          maxLength: 50,
                          validator: (v) =>
                              Validators.required(v, 'Enter your name'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          controller: _username,
                          label: 'Username',
                          prefixText: '@',
                          enabled: false,
                          helperText: "Usernames can't be changed yet",
                        ),
                        const SizedBox(height: AppSpacing.md),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FormError(_error),
                  BusyButton(
                    label: 'Save changes',
                    busy: _busy,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
