import '../../core/constants/enums.dart';

class TripMember {
  const TripMember({
    required this.userId,
    this.role = MemberRole.coCreator,
    this.approved = false,
  });

  final String userId;
  final MemberRole role;
  final bool approved;

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'role': role.name,
    'approved': approved,
  };

  factory TripMember.fromMap(Map<String, dynamic> map) => TripMember(
    userId: map['user_id'] as String? ?? map['userId'] as String? ?? '',
    role: enumFromName(
      MemberRole.values,
      map['role'] as String?,
      MemberRole.coCreator,
    ),
    approved: map['approved'] as bool? ?? false,
  );
}
