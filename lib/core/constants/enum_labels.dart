import 'package:flutter/material.dart';

import 'enums.dart';

extension TripTypeUi on TripType {
  String get label {
    switch (this) {
      case TripType.solo:
        return 'Solo';
      case TripType.couple:
        return 'Couple';
      case TripType.friends:
        return 'Friends';
      case TripType.family:
        return 'Family';
      case TripType.group:
        return 'Group';
      case TripType.business:
        return 'Business';
      case TripType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case TripType.solo:
        return Icons.person_rounded;
      case TripType.couple:
        return Icons.favorite_rounded;
      case TripType.friends:
        return Icons.group_rounded;
      case TripType.family:
        return Icons.family_restroom_rounded;
      case TripType.group:
        return Icons.groups_rounded;
      case TripType.business:
        return Icons.business_center_rounded;
      case TripType.other:
        return Icons.luggage_rounded;
    }
  }
}

extension ItemCategoryUi on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.accommodation:
        return 'Accommodation';
      case ItemCategory.transport:
        return 'Transport';
      case ItemCategory.meal:
        return 'Meals';
      case ItemCategory.activity:
        return 'Activities';
      case ItemCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemCategory.accommodation:
        return Icons.hotel_rounded;
      case ItemCategory.transport:
        return Icons.directions_car_rounded;
      case ItemCategory.meal:
        return Icons.restaurant_rounded;
      case ItemCategory.activity:
        return Icons.local_activity_rounded;
      case ItemCategory.other:
        return Icons.more_horiz_rounded;
    }
  }
}

extension CostBasisUi on CostBasis {
  String get label {
    switch (this) {
      case CostBasis.perPerson:
        return 'per person';
      case CostBasis.perNight:
        return 'per night';
      case CostBasis.perGroup:
        return 'per group';
      case CostBasis.perVehicle:
        return 'per vehicle';
      case CostBasis.oneTime:
        return 'one-time';
      case CostBasis.free:
        return 'free';
    }
  }
}
