import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

/// A journal date is a label, not an instant. Only instants are shifted at 04:00.
abstract final class RecordDay {
  static DateTime dateOf(DateTime instant) {
    final local = instant.toLocal();
    return DateTime(
      local.year,
      local.month,
      local.day - (local.hour < 4 ? 1 : 0),
    );
  }

  static DateTime today({DateTime? now}) => dateOf(now ?? DateTime.now());
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static String key(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  static DateTime start(DateTime date) =>
      DateTime(date.year, date.month, date.day, 4);
  static DateTime nextBoundary(DateTime instant) {
    final date = dateOf(instant);
    return DateTime(date.year, date.month, date.day + 1, 4);
  }

  /// Null dates are legacy midnight-based entries and must keep their old date.
  static Expression<bool> matches(
    TextColumn storedDate,
    DateTimeColumn timestamp,
    DateTime date,
  ) {
    final start = dateOnly(date);
    final end = DateTime(date.year, date.month, date.day + 1);
    return storedDate.equals(key(date)) |
        (storedDate.isNull() &
            timestamp.isBiggerOrEqualValue(start) &
            timestamp.isSmallerThanValue(end));
  }
}
