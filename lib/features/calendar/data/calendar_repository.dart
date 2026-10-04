import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';

class CalendarCycle {
  const CalendarCycle(this.cycle, this.planName, this.endDate);
  final CycleInstance cycle;
  final String planName;
  final DateTime endDate;
  DateTime get startDate => DateTime(
    cycle.startedAt.year,
    cycle.startedAt.month,
    cycle.startedAt.day,
  );
}

class CalendarDay {
  bool training = false,
      rest = false,
      skipped = false,
      nutrition = false,
      body = false;
  final Set<String> cycleIds = {};
}

class CalendarMonthData {
  const CalendarMonthData(this.days, this.cycles);
  final Map<String, CalendarDay> days;
  final List<CalendarCycle> cycles;
}

class CalendarRepository {
  CalendarRepository(this.database);
  final AppDatabase database;
  String key(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<CalendarMonthData> loadMonth(
    DateTime month, {
    DateTime? now,
  }) => database.transaction(() async {
    final today = now ?? DateTime.now();
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final days = <String, CalendarDay>{};
    CalendarDay day(String date) => days.putIfAbsent(date, CalendarDay.new);
    final plans = await database.select(database.trainingPlans).get();
    final planNames = {for (final p in plans) p.id: p.name};
    final allCycles =
        await (database.select(database.cycleInstances)..orderBy([
              (c) => OrderingTerm.asc(c.startedAt),
              (c) => OrderingTerm.asc(c.cycleNumber),
            ]))
            .get();
    final cycles = <CalendarCycle>[];
    for (var i = 0; i < allCycles.length; i++) {
      final cycle = allCycles[i];
      if (cycle.startedAt.isAfter(today)) continue;
      // Switching plans leaves older cycles active; the next cycle's start caps their span.
      var until = cycle.completedAt ?? today;
      if (i + 1 < allCycles.length &&
          allCycles[i + 1].startedAt.isBefore(until)) {
        until = allCycles[i + 1].startedAt;
      }
      if (until.isAfter(today)) until = today;
      cycles.add(
        CalendarCycle(
          cycle,
          planNames[cycle.planId] ?? '',
          DateTime(until.year, until.month, until.day),
        ),
      );
    }
    final executions =
        await (database.select(database.cycleDayExecutions)..where(
              (e) =>
                  e.occurredAt.isBiggerOrEqualValue(start) &
                  e.occurredAt.isSmallerThanValue(end),
            ))
            .get();
    for (final e in executions) {
      final d = day(key(e.occurredAt));
      d.cycleIds.add(e.cycleInstanceId);
      if (e.executionType == 'completedTraining') d.training = true;
      if (e.executionType == 'skippedTraining') d.skipped = true;
      if (['plannedRest', 'movedRest', 'extraRest'].contains(e.executionType)) {
        d.rest = true;
      }
    }
    final workouts =
        await (database.select(database.workoutSessions)..where(
              (s) =>
                  s.localDate.isBiggerOrEqualValue(key(start)) &
                  s.localDate.isSmallerThanValue(key(end)) &
                  s.status.equals('completed'),
            ))
            .get();
    for (final s in workouts) {
      final d = day(s.localDate)..training = true;
      if (s.cycleInstanceId != null) d.cycleIds.add(s.cycleInstanceId!);
    }
    final cardio =
        await (database.select(database.cardioLogs)..where(
              (r) =>
                  r.localDate.isBiggerOrEqualValue(key(start)) &
                  r.localDate.isSmallerThanValue(key(end)),
            ))
            .get();
    for (final c in cardio) {
      day(c.localDate).training = true;
    }
    final foods =
        await (database.select(database.foodLogEntries)..where(
              (f) =>
                  f.localDate.isBiggerOrEqualValue(key(start)) &
                  f.localDate.isSmallerThanValue(key(end)),
            ))
            .get();
    for (final f in foods) {
      day(f.localDate).nutrition = true;
    }
    final totals =
        await (database.select(database.dailyNutritionRecords)..where(
              (n) =>
                  n.localDate.isBiggerOrEqualValue(key(start)) &
                  n.localDate.isSmallerThanValue(key(end)),
            ))
            .get();
    for (final n in totals) {
      if ([
        n.proteinGrams,
        n.carbohydrateGrams,
        n.fatGrams,
        n.caloriesKcal,
      ].any((v) => v != null)) {
        day(n.localDate).nutrition = true;
      }
    }
    final measurements =
        await (database.select(database.bodyMeasurements)..where(
              (b) =>
                  b.localDate.isBiggerOrEqualValue(key(start)) &
                  b.localDate.isSmallerThanValue(key(end)),
            ))
            .get();
    for (final b in measurements) {
      day(b.localDate).body = true;
    }
    for (
      var date = start;
      date.isBefore(end) &&
          !date.isAfter(DateTime(today.year, today.month, today.day));
      date = DateTime(date.year, date.month, date.day + 1)
    ) {
      final d = day(key(date));
      // Explicit records win on the day a completed round creates the next round.
      if (d.cycleIds.isNotEmpty) continue;
      for (final cycle in cycles.reversed) {
        if (!date.isBefore(cycle.startDate) && !date.isAfter(cycle.endDate)) {
          d.cycleIds.add(cycle.cycle.id);
          break;
        }
      }
    }
    return CalendarMonthData(days, cycles.reversed.toList());
  });
}
