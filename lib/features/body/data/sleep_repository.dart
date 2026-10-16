import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/record_day.dart';

class SleepRepository {
  SleepRepository(this.database);
  final AppDatabase database;
  Future<SleepLog?> load(DateTime date) => (database.select(
    database.sleepLogs,
  )..where((r) => r.localDate.equals(RecordDay.key(date)))).getSingleOrNull();
  Future<List<SleepLog>> history(DateTime date) =>
      (database.select(database.sleepLogs)
            ..where(
              (r) => r.localDate.isSmallerOrEqualValue(RecordDay.key(date)),
            )
            ..orderBy([(r) => OrderingTerm.desc(r.localDate)])
            ..limit(14))
          .get();
  Future<void> save(
    DateTime date,
    DateTime start,
    DateTime end,
    String notes,
  ) async {
    if (end.difference(start).inMinutes <= 0 ||
        end.difference(start).inMinutes > 48 * 60 ||
        date.isAfter(RecordDay.today())) {
      throw ArgumentError('Invalid sleep interval');
    }
    await database
        .into(database.sleepLogs)
        .insertOnConflictUpdate(
          SleepLogsCompanion.insert(
            localDate: RecordDay.key(date),
            startedAt: start,
            endedAt: end,
            notes: Value(notes.trim().isEmpty ? null : notes.trim()),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<void> delete(DateTime date) => (database.delete(
    database.sleepLogs,
  )..where((r) => r.localDate.equals(RecordDay.key(date)))).go();
}
