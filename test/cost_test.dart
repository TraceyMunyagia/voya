import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/constants/enums.dart';
import 'package:voya/data/models/cost.dart';

void main() {
  test('calculates per-person cost', () {
    expect(
      const Cost(amount: 1000, basis: CostBasis.perPerson).total(people: 3),
      3000,
    );
  });
  test('calculates per-night cost and quantity', () {
    expect(
      const Cost(
        amount: 2500,
        basis: CostBasis.perNight,
        quantity: 2,
      ).total(nights: 3),
      15000,
    );
  });
}
