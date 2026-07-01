import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final _currency = NumberFormat.simpleCurrency(
    name: 'USD',
    decimalDigits: 2,
  );
  static final _compactCurrency = NumberFormat.compactSimpleCurrency(
    name: 'USD',
    decimalDigits: 2,
  );
  static final _compact = NumberFormat.compact()..maximumFractionDigits = 2;
  static final _percent = NumberFormat.decimalPercentPattern(decimalDigits: 2);
  static final _date = DateFormat.yMMMd();

  static String price(num? value) {
    if (value == null) return '--';
    if (value > 0 && value < 1) {
      return NumberFormat.simpleCurrency(
        name: 'USD',
        decimalDigits: 6,
      ).format(value);
    }
    return _currency.format(value);
  }

  static String compactCurrency(num? value) {
    if (value == null) return '--';
    return _compactCurrency.format(value);
  }

  static String compact(num? value) {
    if (value == null) return '--';
    return _compact.format(value);
  }

  static String percent(num? value) {
    if (value == null) return '--';
    return _percent.format(value / 100);
  }

  static String signedPercent(num? value) {
    if (value == null) return '--';
    final sign = value > 0 ? '+' : '';
    return '$sign${percent(value)}';
  }

  static String date(DateTime? value) {
    if (value == null) return '--';
    return _date.format(value);
  }
}
