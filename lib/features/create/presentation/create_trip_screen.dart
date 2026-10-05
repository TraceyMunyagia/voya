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
              final messenger = ScaffoldMessenger.of(context);
              try {
                final db = ref.read(supabaseProvider);
                if (db.auth.currentUser == null) {
                  await db.auth.signInAnonymously();
                }
                final trip = await ref
                    .read(tripRepositoryProvider)
                    .createDraft(title: 'Test draft');
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Created ${trip.id} with ${trip.memberIds.length} member(s)',
                    ),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Create test draft'),
          ),
        ),
      ),
    );
  }
}
