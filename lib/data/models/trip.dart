import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';

class Trip {
  const Trip({
    required this.id,
    required this.ownerId,
    required this.memberIds,
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
    this.approvals = const {},
    this.originTripId,
    this.likeCount = 0,
    this.commentCount = 0,
    this.saveCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;

  /// Owner + co-creators. Used by queries and security rules.
  final List<String> memberIds;
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
  final double totalCost; // denormalised, maintained server-side later
  final double costPerPerson;

  /// uid -> approved? (used in review / revision flow)
  final Map<String, bool> approvals;

  /// Set when this trip was created with "Make This Trip Mine".
  final String? originTripId;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get nights => (startDate != null && endDate != null)
      ? endDate!.difference(startDate!).inDays
      : 0;

  factory Trip.draft({required String ownerId, required String title}) =>
      Trip(id: '', ownerId: ownerId, memberIds: [ownerId], title: title);

  /// Timestamps are added by the repository (server time).
  Map<String, dynamic> toMap() => {
    'owner_id': ownerId,
    'member_ids': memberIds,
    'title': title,
    'description': description,
    'destinations': destinations,
    'start_date': startDate?.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'travellers': travellers,
    'type': type.name,
    'status': status.name,
    'cover_photo_url': coverPhotoUrl,
    'currency': currency,
    'total_cost': totalCost,
    'cost_per_person': costPerPerson,
    'approvals': approvals,
    'origin_trip_id': originTripId,
    'like_count': likeCount,
    'comment_count': commentCount,
    'save_count': saveCount,
  };

  factory Trip.fromMap(Map<String, dynamic> m) {
    return Trip(
      id: m['id'] as String? ?? '',
      ownerId: m['owner_id'] as String? ?? '',
      memberIds: List<String>.from((m['member_ids'] as List?) ?? []),
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      destinations: List<String>.from((m['destinations'] as List?) ?? []),
      startDate: _dateFrom(m['start_date']),
      endDate: _dateFrom(m['end_date']),
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
      approvals: Map<String, bool>.from((m['approvals'] as Map?) ?? {}),
      originTripId: m['origin_trip_id'] as String?,
      likeCount: (m['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (m['comment_count'] as num?)?.toInt() ?? 0,
      saveCount: (m['save_count'] as num?)?.toInt() ?? 0,
      createdAt: _dateFrom(m['created_at']),
      updatedAt: _dateFrom(m['updated_at']),
    );
  }

  static DateTime? _dateFrom(dynamic value) => value is String
      ? DateTime.tryParse(value)
      : value is DateTime
      ? value
      : null;
}
