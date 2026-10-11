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
    /// What the user typed -> a non-negative number, or null if it isn't one.
  /// Accepts `1,500` and `1 500`.
  static double? parse(String raw) {
    final s = raw.trim().replaceAll(',', '').replaceAll(' ', '');
    if (s.isEmpty) return null;
    final n = double.tryParse(s);
    if (n == null || n.isNaN || n.isInfinite || n < 0 || n > 100000000) return null;
    return n;
  }

  /// A number back into an editable field: `0` -> empty, `1500.0` -> `1500`.
  static String toInput(double amount) {
    if (amount <= 0) return '';
    return amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toString();
  }
}
