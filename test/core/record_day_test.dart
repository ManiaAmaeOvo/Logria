import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/record_day.dart';

void main() {
  test(
    'journal boundary is local 04:00, including year and leap rollovers',
    () {
      expect(
        RecordDay.dateOf(DateTime(2026, 10, 7, 3, 59)),
        DateTime(2026, 10, 6),
      );
      expect(RecordDay.dateOf(DateTime(2026, 10, 7, 4)), DateTime(2026, 10, 7));
      expect(
        RecordDay.dateOf(DateTime(2026, 10, 7, 23, 59)),
        DateTime(2026, 10, 7),
      );
      expect(RecordDay.dateOf(DateTime(2026, 1, 1)), DateTime(2025, 12, 31));
      expect(RecordDay.dateOf(DateTime(2024, 3, 1, 2)), DateTime(2024, 2, 29));
      expect(RecordDay.dateOnly(DateTime(2026, 10, 7)), DateTime(2026, 10, 7));
      expect(
        RecordDay.nextBoundary(DateTime(2026, 10, 7, 2)),
        DateTime(2026, 10, 7, 4),
      );
      expect(
        RecordDay.nextBoundary(DateTime(2026, 10, 7, 4)),
        DateTime(2026, 10, 8, 4),
      );
      final local = DateTime(2026, 10, 7, 2);
      expect(RecordDay.dateOf(local.toUtc()), RecordDay.dateOf(local));
    },
  );
}
