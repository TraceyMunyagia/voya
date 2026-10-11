import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

class AuthRepository {
  AuthRepository(this._auth);

  final GoTrueClient _auth;

  /// If email confirmation is on, the response has no session until the
  /// user taps the link in their inbox.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: AppConstants.authRedirect,
      // read by the on_auth_user_created trigger to prefill the profile
      data: (displayName == null || displayName.isEmpty)
          ? null
          : {'full_name': displayName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resendConfirmation(String email) {
    return _auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: AppConstants.authRedirect,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.resetPasswordForEmail(
      email,
      redirectTo: AppConstants.authRedirect,
    );
  }

  Future<UserResponse> updatePassword(String newPassword) {
    return _auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() => _auth.signOut();
}
