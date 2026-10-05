import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Set while Supabase has delivered a password-recovery session.
final passwordRecoveryPending = ValueNotifier<bool>(false);

void listenForPasswordRecovery(SupabaseClient client) {
  client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      passwordRecoveryPending.value = true;
    }
  });
}
