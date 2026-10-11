import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/utils/dates.dart';

void main() {
  test('iso pads month and day', () {
    expect(Dates.iso(DateTime(2026, 3, 5)), '2026-03-05');
  });

  test('dayCount counts both ends', () {
    expect(Dates.dayCount(DateTime(2026, 12, 1), DateTime(2026, 12, 4)), 4);
    expect(Dates.dayCount(DateTime(2026, 12, 1), DateTime(2026, 12, 1)), 1);
    expect(Dates.dayCount(DateTime(2026, 12, 30), DateTime(2027, 1, 2)), 4);
  });

  test('range text', () {
    expect(
      Dates.range(DateTime(2026, 12, 1), DateTime(2026, 12, 4)),
      '1–4 Dec 2026',
    );
    expect(
      Dates.range(DateTime(2026, 11, 28), DateTime(2026, 12, 2)),
      '28 Nov – 2 Dec 2026',
    );
    expect(
      Dates.range(DateTime(2026, 12, 30), DateTime(2027, 1, 2)),
      '30 Dec 2026 – 2 Jan 2027',
    );
    expect(
      Dates.range(DateTime(2026, 12, 1), DateTime(2026, 12, 1)),
      '1 Dec 2026',
    );
  });
}
