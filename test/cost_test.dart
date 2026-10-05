import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/constants/enums.dart';
import 'package:voya/data/models/cost.dart';

void main() {
  group('Cost.total', () {
    test('perPerson multiplies by people', () {
      const c = Cost(amount: 1500, basis: CostBasis.perPerson);
      expect(c.total(people: 4), 6000);
    });
    test('perNight multiplies by nights', () {
      const c = Cost(amount: 5000, basis: CostBasis.perNight);
      expect(c.total(people: 4, nights: 3), 15000);
    });
    test('perGroup stays flat', () {
      const c = Cost(amount: 2400, basis: CostBasis.perGroup);
      expect(c.total(people: 4), 2400);
    });
    test('free is always zero', () {
      const c = Cost(amount: 999, basis: CostBasis.free);
      expect(c.total(people: 4), 0);
    });
  });

  test('Cost round-trips through database columns', () {
    const c = Cost(amount: 3500, basis: CostBasis.perGroup);
    final back = Cost.fromColumns(c.toColumns());
    expect(back.amount, 3500);
    expect(back.basis, CostBasis.perGroup);
    expect(c.toColumns()['cost_basis'], 'per_group');
  });
}
