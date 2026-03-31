import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  static String formatAmount(double amount) {
    return 'KES ${_currencyFormat.format(amount)}';
  }

  static String formatDateTime(DateTime dt) {
    return _dateTimeFormat.format(dt);
  }

  static String formatDate(DateTime dt) {
    return _dateFormat.format(dt);
  }

  static String formatTime(DateTime dt) {
    return _timeFormat.format(dt);
  }

  static String formatRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today, ${_timeFormat.format(dt)}';
    if (diff.inDays == 1) return 'Yesterday, ${_timeFormat.format(dt)}';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return _dateTimeFormat.format(dt);
  }
}