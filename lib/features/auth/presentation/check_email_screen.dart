import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_text.dart';
import '../../../providers/auth_providers.dart';
import 'widgets/auth_scaffold.dart';

class CheckEmailScreen extends ConsumerStatefulWidget {
  const CheckEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends ConsumerState<CheckEmailScreen> {
  bool _busy = false;

  Future<void> _resend() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).resendConfirmation(widget.email);
      messenger.showSnackBar(
        const SnackBar(content: Text('Email sent again.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AuthScaffold(
      title: 'Check your email',
      children: [
        Icon(Icons.mark_email_unread_outlined, size: 64, color: scheme.primary),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'We sent a confirmation link to',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.email,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Open the link on this phone to finish creating your account.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton(
          onPressed: _busy ? null : _resend,
          child: const Text('Resend email'),
        ),
        TextButton(
          onPressed: () => context.go('/sign-in'),
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }
}
