import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../providers/auth_providers.dart';

enum _MenuAction { edit, signOut, gallery }

Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
  final shouldSignOut = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text('You can sign back in at any time.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );

  if (shouldSignOut != true) return;

  try {
    await ref.read(authRepositoryProvider).signOut();
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not sign out: $error')));
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('@${profile.username ?? ''}'),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: (a) {
              switch (a) {
                case _MenuAction.edit:
                  context.push(Routes.editProfile);
                case _MenuAction.signOut:
                  _confirmSignOut(context, ref);
                case _MenuAction.gallery:
                  context.push(Routes.gallery);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _MenuAction.edit,
                child: Text('Edit profile'),
              ),
              const PopupMenuItem(
                value: _MenuAction.signOut,
                child: Text('Sign out'),
              ),
              if (kDebugMode)
                const PopupMenuItem(
                  value: _MenuAction.gallery,
                  child: Text('Component gallery'),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              UserAvatar(
                photoUrl: profile.photoUrl,
                initials: profile.initials,
                radius: 44,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.shownName,
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (profile.city.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              profile.city,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(profile.bio),
          ],
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () => context.push(Routes.editProfile),
            child: const Text('Edit profile'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(label: 'Trips', value: '${profile.tripsCount}'),
                  const _Stat(
                    label: 'Saved',
                    value: '–',
                  ), // arrives with Saved (Week 10)
                  _Stat(label: 'Followers', value: '${profile.followersCount}'),
                  _Stat(label: 'Following', value: '${profile.followingCount}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Published trips', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          EmptyState(
            icon: Icons.luggage_outlined,
            title: 'No trips yet',
            message: 'Your published trips will appear here.',
            actionLabel: 'Create a trip',
            onAction: () => context.push(Routes.create),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: text.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
