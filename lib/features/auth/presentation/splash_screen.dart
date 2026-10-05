import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../providers/auth_providers.dart';

/// Shown while the signed-in user's profile loads. If loading fails
/// (offline, server hiccup) it offers a retry instead of spinning forever.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: profile.hasError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Couldn't load your profile",
                    style: text.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: 240,
                    child: FilledButton(
                      onPressed: () => ref.invalidate(currentProfileProvider),
                      child: const Text('Try again'),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Voya',
                    style: text.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const CircularProgressIndicator(color: AppColors.coral),
                ],
              ),
      ),
    );
  }
}
