import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

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
    if (e.code == 'PGRST116') {
      return 'That could not be saved. It may have been changed or removed.';
    }
    return e.message;
  }
  if (e is StorageException) return e.message;
  if (e is AuthRetryableFetchException) return 'No internet connection.';
  if (e is SocketException) return 'No internet connection.';
  if (e is PlatformException) {
    if (e.code.contains('denied')) {
      return 'Voya does not have permission. Allow photo or camera access in Settings.';
    }
    return e.message ?? 'Could not open the photo picker.';
  }
  final raw = e.toString();
  if (raw.contains('SocketException') || raw.contains('ClientException')) {
    return 'No internet connection.';
  }
  return 'Something went wrong. Please try again.';
}
