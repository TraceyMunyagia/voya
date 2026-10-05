import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../providers/supabase_providers.dart';

class CreateTripScreen extends ConsumerWidget {
  const CreateTripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create trip')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton(
            onPressed: () async {
              final supabase = ref.read(supabaseClientProvider);
              final user =
                  supabase.auth.currentUser ??
                  (await supabase.auth.signInAnonymously()).user!;
              final id = await ref
                  .read(tripRepositoryProvider)
                  .createDraft(ownerId: user.id, title: 'Test draft');
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Created trip $id')));
              }
            },
            child: const Text('Create test draft'),
          ),
        ),
      ),
    );
  }
}
