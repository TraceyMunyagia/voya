import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/router/auth_redirect.dart';
import 'package:voya/core/router/routes.dart';
import 'package:voya/data/models/app_user.dart';

const _onboarded = AppUser(
  id: 'u',
  username: 'tracey',
  onboardingCompleted: true,
);
const _fresh = AppUser(id: 'u');

String? run({
  bool signedIn = true,
  bool recovering = false,
  AsyncValue<AppUser?> profile = const AsyncData(_onboarded),
  String location = Routes.home,
}) {
  return authRedirect(
    signedIn: signedIn,
    recovering: recovering,
    profile: profile,
    location: location,
  );
}

void main() {
  group('signed out', () {
    test('is sent to the welcome screen', () {
      expect(
        run(signedIn: false, profile: const AsyncData(null)),
        Routes.welcome,
      );
    });
    test('may stay on the public screens', () {
      for (final path in [
        Routes.welcome,
        Routes.signIn,
        Routes.signUp,
        Routes.checkEmail,
        Routes.forgotPassword,
      ]) {
        expect(
          run(signedIn: false, profile: const AsyncData(null), location: path),
          isNull,
          reason: path,
        );
      }
    });
  });

  test('password recovery overrides everything', () {
    expect(run(recovering: true), Routes.resetPassword);
    expect(run(recovering: true, location: Routes.resetPassword), isNull);
  });

  test(
    'a signed-in user whose profile is loading waits on the splash screen',
    () {
      expect(run(profile: const AsyncLoading()), Routes.splash);
      expect(
        run(profile: const AsyncLoading(), location: Routes.splash),
        isNull,
      );
    },
  );

  test('a user who has not finished onboarding is sent to onboarding', () {
    expect(run(profile: const AsyncData(_fresh)), Routes.onboarding);
    expect(
      run(profile: const AsyncData(_fresh), location: Routes.onboarding),
      isNull,
    );
  });

  test('an onboarded user is moved off the auth screens', () {
    expect(run(location: Routes.welcome), Routes.home);
    expect(run(location: Routes.signIn), Routes.home);
    expect(run(location: Routes.splash), Routes.home);
    expect(run(location: Routes.onboarding), Routes.home);
  });

  test('an onboarded user can use the app', () {
    expect(run(location: Routes.saved), isNull);
    expect(run(location: Routes.editProfile), isNull);
  });
}
