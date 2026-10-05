class AppUser {
  const AppUser({
    required this.id,
    this.username,
    this.displayName,
    this.photoUrl,
    this.bio = '',
    this.city = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.tripsCount = 0,
    this.onboardingCompleted = false,
  });

  final String id;
  final String? username; // null until claimed in onboarding
  final String? displayName;
  final String? photoUrl;
  final String bio;
  final String city;
  final int followersCount;
  final int followingCount;
  final int tripsCount;
  final bool onboardingCompleted;

  /// "Jane Doe" -> "JD", "Tracey" -> "T", no name -> first letter of the username.
  String get initials {
    final parts = (displayName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) {
      final first = parts.first[0];
      final second = parts.length > 1 ? parts.last[0] : '';
      return (first + second).toUpperCase();
    }
    if (username != null && username!.isNotEmpty) {
      return username![0].toUpperCase();
    }
    return '?';
  }

  /// Display name, else @username, else "Traveller".
  String get shownName {
    final name = displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    if (username != null && username!.isNotEmpty) return '@$username';
    return 'Traveller';
  }

  Map<String, dynamic> toUpdateJson() => {
    'username': username,
    'display_name': displayName,
    'photo_url': photoUrl,
    'bio': bio,
    'city': city,
  };

  factory AppUser.fromJson(Map<String, dynamic> m) => AppUser(
    id: m['id'] as String,
    username: m['username'] as String?,
    displayName: m['display_name'] as String?,
    photoUrl: m['photo_url'] as String?,
    bio: m['bio'] as String? ?? '',
    city: m['city'] as String? ?? '',
    followersCount: (m['followers_count'] as num?)?.toInt() ?? 0,
    followingCount: (m['following_count'] as num?)?.toInt() ?? 0,
    tripsCount: (m['trips_count'] as num?)?.toInt() ?? 0,
    onboardingCompleted: m['onboarding_completed'] as bool? ?? false,
  );
}
