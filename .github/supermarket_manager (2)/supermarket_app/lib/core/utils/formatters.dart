import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ar_SA',
    symbol: 'ر.س',
    decimalDigits: 2,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'ar_SA');

  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd', 'ar_SA');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'ar_SA');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar_SA');

  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String number(int number) {
    return _numberFormat.format(number);
  }

  static String date(DateTime date) {
    return _dateFormat.format(date);
  }

  static String time(DateTime date) {
    return _timeFormat.format(date);
  }

  static String dateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم ${time(date)}';
    } else if (difference.inDays == 1) {
      return 'أمس ${time(date)}';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return dateTime(date);
    }
  }
}
