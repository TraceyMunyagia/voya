import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import 'trip_member.dart';

DateTime? _dt(dynamic v) => v == null ? null : DateTime.parse(v as String);

String? _dateOnly(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

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

  int get nights => (startDate != null && endDate != null)
      ? endDate!.difference(startDate!).inDays
      : 0;

  /// Editable fields only. Status, counts and costs change through
  /// dedicated actions, not through a generic update.
  Map<String, dynamic> toUpdateJson() => {
    'title': title,
    'description': description,
    'destinations': destinations,
    'start_date': _dateOnly(startDate),
    'end_date': _dateOnly(endDate),
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
