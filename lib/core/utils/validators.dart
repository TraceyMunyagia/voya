import '../constants/app_constants.dart';
import 'money.dart';
import 'urls.dart';

class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(s)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Enter a password';
    if (v.length < AppConstants.minPasswordLength) {
      return 'Use at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Repeat your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? v, String message) {
    return (v == null || v.trim().isEmpty) ? message : null;
  }
    /// Optional: empty is fine, otherwise it must look like a web address.
  static String? optionalUrl(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return Urls.normalise(s) == null ? 'Enter a valid web address' : null;
  }

  /// Optional: empty is fine, otherwise a number that isn't negative.
  static String? amount(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return Money.parse(s) == null ? 'Enter a valid amount' : null;
  }
}
