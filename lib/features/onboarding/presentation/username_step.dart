import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/username_rules.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/busy_button.dart';
import '../../../core/widgets/form_error.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/supabase_providers.dart';

enum _Availability { idle, invalid, checking, available, taken }

class UsernameStep extends ConsumerStatefulWidget {
  const UsernameStep({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<UsernameStep> createState() => _UsernameStepState();
}

class _UsernameStepState extends ConsumerState<UsernameStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _username = TextEditingController();
  Timer? _debounce;
  _Availability _availability = _Availability.idle;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Prefilled from the sign-up name or the Google account name.
    _name = TextEditingController(
      text: ref.read(currentProfileProvider).value?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();
    if (value.isEmpty) {
      setState(() => _availability = _Availability.idle);
      return;
    }
    if (UsernameRules.validate(value) != null) {
      setState(() => _availability = _Availability.invalid);
      return;
    }
    setState(() => _availability = _Availability.checking);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final free = await ref
            .read(profileRepositoryProvider)
            .isUsernameAvailable(
              value,
              exceptUserId: ref.read(currentUserProvider)?.id,
            );
        if (!mounted || _username.text != value) return;
        setState(
          () => _availability = free
              ? _Availability.available
              : _Availability.taken,
        );
      } catch (_) {
        if (mounted) setState(() => _availability = _Availability.idle);
      }
    });
  }

  String? _validateUsername(String? v) {
    final rule = UsernameRules.validate(v);
    if (rule != null) return rule;
    if (_availability == _Availability.taken) return 'That username is taken';
    return null;
  }

  Widget? _statusIcon() {
    switch (_availability) {
      case _Availability.checking:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _Availability.available:
        return const Icon(Icons.check_circle_rounded, color: AppColors.success);
      case _Availability.taken:
        return const Icon(Icons.cancel_rounded, color: AppColors.danger);
      default:
        return null;
    }
  }

  Future<void> _submit() async {
    if (_availability == _Availability.checking) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uid = ref.read(currentUserProvider)!.id;
      final updated = await ref.read(profileRepositoryProvider).update(uid, {
        'username': _username.text.trim(),
        'display_name': _name.text.trim(),
      });
      ref.read(currentProfileProvider.notifier).setProfile(updated);
      widget.onDone();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      if (e.code == '23505') {
        // Someone grabbed it between the check and the save.
        setState(() => _availability = _Availability.taken);
        _formKey.currentState!.validate();
      } else {
        setState(() => _error = friendlyError(e));
      }
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose your username', style: text.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This is how other travellers find and tag you.',
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
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
                      helperText: '3-20 characters: a-z, 0-9 and _',
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      suffix: _statusIcon(),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9_]'),
                        ),
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => newValue.copyWith(
                            text: newValue.text.toLowerCase(),
                          ),
                        ),
                        LengthLimitingTextInputFormatter(
                          UsernameRules.maxLength,
                        ),
                      ],
                      onChanged: _onUsernameChanged,
                      onSubmitted: (_) => _submit(),
                      validator: _validateUsername,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormError(_error),
              BusyButton(label: 'Continue', busy: _busy, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
