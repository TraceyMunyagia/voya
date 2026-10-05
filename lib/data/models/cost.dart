import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';

class Cost {
  const Cost({
    this.amount = 0,
    this.currency = AppConstants.defaultCurrency,
    this.basis = CostBasis.oneTime,
    this.quantity = 1,
  });

  final double amount;
  final String currency;
  final CostBasis basis;
  final int quantity;

  /// Total cost of this line for the whole group.
  double total({int people = 1, int nights = 1}) {
    switch (basis) {
      case CostBasis.free:
        return 0;
      case CostBasis.perPerson:
        return amount * people;
      case CostBasis.perNight:
        return amount * nights * quantity;
      case CostBasis.perGroup:
      case CostBasis.perVehicle:
      case CostBasis.oneTime:
        return amount * quantity;
    }
  }

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'currency': currency,
    'basis': basis.name,
  };

  factory Cost.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const Cost();
    return Cost(
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      currency: m['currency'] as String? ?? AppConstants.defaultCurrency,
      basis: enumFromName(
        CostBasis.values,
        m['basis'] as String?,
        CostBasis.oneTime,
      ),
      quantity: (m['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
