enum TripStatus { draft, review, published, revision }

enum TripType { solo, couple, friends, family, group, business, other }

enum ItemCategory { accommodation, transport, meal, activity, other }

/// Postgres enum `cost_basis` uses snake_case, so these carry a db value.
enum CostBasis {
  perPerson('per_person'),
  perNight('per_night'),
  perGroup('per_group'),
  perVehicle('per_vehicle'),
  oneTime('one_time'),
  free('free');

  const CostBasis(this.db);
  final String db;

  static CostBasis fromDb(String? v) => CostBasis.values.firstWhere(
    (e) => e.db == v,
    orElse: () => CostBasis.oneTime,
  );
}

/// Postgres enum `member_role`.
enum MemberRole {
  owner('owner'),
  coCreator('co_creator');

  const MemberRole(this.db);
  final String db;

  static MemberRole fromDb(String? v) => MemberRole.values.firstWhere(
    (e) => e.db == v,
    orElse: () => MemberRole.coCreator,
  );
}

/// Safe lookup for enums whose db value equals their Dart name.
T enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
