import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns any exception into a sentence a traveller can act on.
String friendlyError(Object e) {
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Wrong email or password.';
    }
    if (m.contains('email not confirmed')) {
      return 'Please confirm your email first. Check your inbox.';
    }
    if (m.contains('already registered')) {
      return 'An account with this email already exists. Try signing in.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    return e.message;
  }
  if (e is PostgrestException) {
    if (e.code == '23505') return 'That is already taken.';
    if (e.code == '42501') return 'You do not have permission to do that.';
    return e.message;
  }
  if (e is StorageException) return e.message;
  if (e is SocketException) return 'No internet connection.';
  return 'Something went wrong. Please try again.';
}
