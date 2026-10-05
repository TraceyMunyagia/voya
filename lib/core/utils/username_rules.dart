class UsernameRules {
  static const minLength = 3;
  static const maxLength = 20;
  static final _pattern = RegExp(r'^[a-z0-9_]+$');

  /// Keep in sync with profiles_username_not_reserved in the database.
  static const reserved = {
    'admin',
    'administrator',
    'voya',
    'support',
    'help',
    'staff',
    'moderator',
    'team',
    'official',
    'api',
    'null',
    'undefined',
    'root',
    'system',
  };

  static String? validate(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return 'Pick a username';
    if (v.length < minLength) return 'At least $minLength characters';
    if (v.length > maxLength) return 'At most $maxLength characters';
    if (!_pattern.hasMatch(v))
      return 'Use lowercase letters, numbers and underscores only';
    if (reserved.contains(v)) return 'That username is reserved';
    return null;
  }
}
