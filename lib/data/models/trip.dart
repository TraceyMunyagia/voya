import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import 'trip_member.dart';
import '../../core/utils/dates.dart';
import 'app_user.dart';

DateTime? _dt(dynamic v) => v == null ? null : DateTime.parse(v as String);

class Trip {
  const Trip({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description = '',
    this.destinations = const [],
    this.startDate,
    this.endDate,
    this.travellers = 1,
    this.type = TripType.solo,
    this.status = TripStatus.draft,
    this.coverPhotoUrl,
    this.currency = AppConstants.defaultCurrency,
    this.totalCost = 0,
    this.costPerPerson = 0,
    this.originTripId,
    this.likeCount = 0,
    this.commentCount = 0,
    this.saveCount = 0,
    this.members = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String description;
  final List<String> destinations;
  final DateTime? startDate;
  final DateTime? endDate;
  final int travellers;
  final TripType type;
  final TripStatus status;
  final String? coverPhotoUrl;
  final String currency;
  final double totalCost; // denormalised; recomputed server-side from Week 8
  final double costPerPerson;

  /// Set when this trip was created with "Make This Trip Mine".
  final String? originTripId;
  final int likeCount;
  final int commentCount;
  final int saveCount;

  /// Owner + co-creators (loaded with `select('*, trip_members(*)')`).
  final List<TripMember> members;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<String> get memberIds =>
      members.isEmpty ? [ownerId] : members.map((m) => m.userId).toList();

  /// True when every creator has approved (publishing flow, Week 18).
  bool get allApproved =>
      members.isNotEmpty && members.every((m) => m.approved);

  /// Whole nights between start and end (date only, so daylight saving can't skew it).
  int get nights {
    if (startDate == null || endDate == null) return 0;
    final s = DateTime.utc(startDate!.year, startDate!.month, startDate!.day);
    final e = DateTime.utc(endDate!.year, endDate!.month, endDate!.day);
    return e.difference(s).inDays;
  }

  /// Number of days counting both the first and the last (null without dates).
  int? get days => (startDate == null || endDate == null) ? null : nights + 1;

  /// Owner first, then co-creators; only those whose profile was loaded.
  List<AppUser> get creators {
    final owners = members.where((m) => m.role == MemberRole.owner);
    final others = members.where((m) => m.role != MemberRole.owner);
    return [
      ...owners,
      ...others,
    ].map((m) => m.profile).whereType<AppUser>().toList();
  }

  /// Editable fields only. Status, counts and costs change through
  /// dedicated actions, not through a generic update.
  Map<String, dynamic> toUpdateJson() => {
    'title': title,
    'description': description,
    'destinations': destinations,
    'start_date': startDate == null ? null : Dates.iso(startDate!),
    'end_date': endDate == null ? null : Dates.iso(endDate!),
    'travellers': travellers,
    'type': type.name,
    'cover_photo_url': coverPhotoUrl,
    'currency': currency,
  };

  factory Trip.fromJson(Map<String, dynamic> m) => Trip(
    id: m['id'] as String,
    ownerId: m['owner_id'] as String,
    title: m['title'] as String? ?? '',
    description: m['description'] as String? ?? '',
    destinations: List<String>.from((m['destinations'] as List?) ?? []),
    startDate: _dt(m['start_date']),
    endDate: _dt(m['end_date']),
    travellers: (m['travellers'] as num?)?.toInt() ?? 1,
    type: enumFromName(TripType.values, m['type'] as String?, TripType.other),
    status: enumFromName(
      TripStatus.values,
      m['status'] as String?,
      TripStatus.draft,
    ),
    coverPhotoUrl: m['cover_photo_url'] as String?,
    currency: m['currency'] as String? ?? AppConstants.defaultCurrency,
    totalCost: (m['total_cost'] as num?)?.toDouble() ?? 0,
    costPerPerson: (m['cost_per_person'] as num?)?.toDouble() ?? 0,
    originTripId: m['origin_trip_id'] as String?,
    likeCount: (m['like_count'] as num?)?.toInt() ?? 0,
    commentCount: (m['comment_count'] as num?)?.toInt() ?? 0,
    saveCount: (m['save_count'] as num?)?.toInt() ?? 0,
    members: ((m['trip_members'] as List?) ?? [])
        .map((e) => TripMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    createdAt: _dt(m['created_at']),
    updatedAt: _dt(m['updated_at']),
  );
}
