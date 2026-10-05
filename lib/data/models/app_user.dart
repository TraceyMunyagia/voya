class AppUser {
  const AppUser({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl,
    this.bio = '',
    this.city = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.tripsCount = 0,
  });

  final String uid;
  final String username; // unique, lowercase, no "@"
  final String displayName;
  final String? photoUrl;
  final String bio;
  final String city;
  final int followersCount;
  final int followingCount;
  final int tripsCount;

  Map<String, dynamic> toMap() => {
    'username': username,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'bio': bio,
    'city': city,
    'followersCount': followersCount,
    'followingCount': followingCount,
    'tripsCount': tripsCount,
  };

  factory AppUser.fromMap(Map<String, dynamic> m) {
    return AppUser(
      uid: m['id'] as String? ?? '',
      username: m['username'] as String? ?? '',
      displayName: m['displayName'] as String? ?? '',
      photoUrl: m['photoUrl'] as String?,
      bio: m['bio'] as String? ?? '',
      city: m['city'] as String? ?? '',
      followersCount: (m['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (m['followingCount'] as num?)?.toInt() ?? 0,
      tripsCount: (m['tripsCount'] as num?)?.toInt() ?? 0,
    );
  }
}
