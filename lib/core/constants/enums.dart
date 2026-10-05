enum TripStatus { draft, review, published, revision }

enum TripType { solo, couple, friends, family, group, business, other }

enum ItemCategory { accommodation, transport, meal, activity, other }

enum CostBasis { perPerson, perNight, perGroup, perVehicle, oneTime, free }

enum MemberRole { owner, coCreator }

/// Safe enum lookup used by every fromMap().
T enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
