import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';

class Cost {
  const Cost({
    this.amount = 0,
    this.currency = AppConstants.defaultCurrency,
    this.basis = CostBasis.oneTime,
  });

  final double amount;
  final String currency;
  final CostBasis basis;

  /// Total cost of this line for the whole group.
  double total({required int people, int nights = 1}) {
    switch (basis) {
      case CostBasis.free:
        return 0;
      case CostBasis.perPerson:
        return amount * people;
      case CostBasis.perNight:
        return amount * nights;
      case CostBasis.perGroup:
      case CostBasis.perVehicle:
      case CostBasis.oneTime:
        return amount;
    }
  }

  /// The three flat columns on `itinerary_items`.
  Map<String, dynamic> toColumns() => {
    'cost_amount': amount,
    'cost_currency': currency,
    'cost_basis': basis.db,
  };

  factory Cost.fromColumns(Map<String, dynamic> m) => Cost(
    amount: (m['cost_amount'] as num?)?.toDouble() ?? 0,
    currency: m['cost_currency'] as String? ?? AppConstants.defaultCurrency,
    basis: CostBasis.fromDb(m['cost_basis'] as String?),
  );
}
