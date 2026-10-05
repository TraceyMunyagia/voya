import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:voya/core/router/app_router.dart';
import 'package:voya/data/models/app_user.dart';
import 'package:voya/providers/auth_providers.dart';
import 'package:voya/providers/supabase_providers.dart';

class _FakeProfile extends CurrentProfileNotifier {
  @override
  Future<AppUser?> build() async => const AppUser(
    id: 'u1',
    username: 'tracey',
    displayName: 'Tracey',
    onboardingCompleted: true,
  );
}

void main() {
  testWidgets('signed-in, onboarded user sees 5 tabs and the profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            User(
              id: 'u1',
              appMetadata: const {},
              userMetadata: const {},
              aud: 'authenticated',
              createdAt: '2026-01-01T00:00:00Z',
            ),
          ),
          currentProfileProvider.overrideWith(_FakeProfile.new),
        ],
        child: Consumer(
          builder: (context, ref, _) =>
              MaterialApp.router(routerConfig: ref.watch(routerProvider)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Explore', 'Create', 'Saved', 'Profile']) {
      expect(find.text(label), findsWidgets);
    }

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('@tracey'), findsOneWidget);
  });
}
