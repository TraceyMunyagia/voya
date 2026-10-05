import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import 'routes.dart';

/// Pure function (easy to test): where should this user be?
/// Returns null to stay on [location], or the path to redirect to.
String? authRedirect({
  required bool signedIn,
  required bool recovering,
  required AsyncValue<AppUser?> profile,
  required String location,
}) {
  const publicRoutes = {
    Routes.welcome,
    Routes.signIn,
    Routes.signUp,
    Routes.checkEmail,
    Routes.forgotPassword,
  };

  // Arrived through a password-reset link: must set a new password first.
  if (recovering) {
    return location == Routes.resetPassword ? null : Routes.resetPassword;
  }

  if (!signedIn) {
    return publicRoutes.contains(location) ? null : Routes.welcome;
  }

  // Signed in, but the profile is still loading (or failed): the splash
  // screen shows a spinner, or a retry button on error.
  final p = profile.value;
  if (p == null) {
    return location == Routes.splash ? null : Routes.splash;
  }

  if (!p.onboardingCompleted) {
    return location == Routes.onboarding ? null : Routes.onboarding;
  }

  // Fully onboarded: keep them out of the auth screens.
  const authOnly = {
    ...publicRoutes,
    Routes.splash,
    Routes.onboarding,
    Routes.resetPassword,
  };
  return authOnly.contains(location) ? Routes.home : null;
}
