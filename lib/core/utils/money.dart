import 'package:intl/intl.dart';

class Money {
  static String symbol(String currency) {
    switch (currency) {
      case 'KES':
        return 'KSh';
      case 'TZS':
        return 'TSh';
      case 'UGX':
        return 'USh';
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  /// `format(84500)` -> `KSh 84,500`, `format(1234.5)` -> `KSh 1,234.50`,
  /// `format(120, currency: 'USD')` -> `$120`.
  static String format(num amount, {String currency = 'KES'}) {
    final whole = amount == amount.roundToDouble();
    final number = NumberFormat.decimalPatternDigits(
      locale: 'en_US',
      decimalDigits: whole ? 0 : 2,
    ).format(amount);
    final s = symbol(currency);
    return s.length <= 1 ? '$s$number' : '$s $number';
  }
}
