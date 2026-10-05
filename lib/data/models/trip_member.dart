import '../../core/constants/enums.dart';

class TripMember {
  const TripMember({
    required this.tripId,
    required this.userId,
    this.role = MemberRole.coCreator,
    this.approved = false,
    this.joinedAt,
  });

  final String tripId;
  final String userId;
  final MemberRole role;

  /// Has this creator approved publishing / the pending revision?
  final bool approved;
  final DateTime? joinedAt;

  factory TripMember.fromJson(Map<String, dynamic> m) => TripMember(
    tripId: m['trip_id'] as String,
    userId: m['user_id'] as String,
    role: MemberRole.fromDb(m['role'] as String?),
    approved: m['approved'] as bool? ?? false,
    joinedAt: m['joined_at'] == null
        ? null
        : DateTime.parse(m['joined_at'] as String),
  );
}
