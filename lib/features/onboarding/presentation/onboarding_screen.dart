import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_providers.dart';
import 'profile_details_step.dart';
import 'username_step.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int? _step;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;

    // Resume where the user left off: step 2 if they already have a username.
    _step ??= (profile?.username == null) ? 0 : 1;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Step ${_step! + 1} of 2'),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _step == 0
              ? UsernameStep(
                  key: const ValueKey('username'),
                  onDone: () => setState(() => _step = 1),
                )
              : const ProfileDetailsStep(key: ValueKey('details')),
        ),
      ),
    );
  }
}
