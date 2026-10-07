import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/record_day.dart';
import '../../fitness/data/fitness_repository.dart';
import '../../nutrition/data/nutrition_repository.dart';

class TodayFitnessAction {
  const TodayFitnessAction(
    this.execution,
    this.cycleNumber,
    this.planName,
    this.dayName,
  );
  final CycleDayExecution execution;
  final int? cycleNumber;
  final String? planName, dayName;
}

class TodayLogData {
  const TodayLogData({
    required this.date,
    required this.workouts,
    required this.actions,
    required this.nutrition,
    required this.bodyTypes,
    required this.measurements,
    this.cardio = const [],
    this.note = '',
  });
  final DateTime date;
  final List<WorkoutHistoryItem> workouts;
  final List<TodayFitnessAction> actions;
  final NutritionDayData nutrition;
  final Map<String, BodyMeasurementType> bodyTypes;
  final List<BodyMeasurement> measurements;
  final List<CardioLog> cardio;
  final String note;
}

class TodayRepository {
  TodayRepository(this.database);
  final AppDatabase database;

  Future<void> saveNote(String localDate, String content) async {
    if (content.trim().isEmpty) {
      await (database.delete(
        database.dailyNotes,
      )..where((r) => r.localDate.equals(localDate))).go();
    } else {
      await database
          .into(database.dailyNotes)
          .insertOnConflictUpdate(
            DailyNotesCompanion.insert(
              localDate: localDate,
              content: content.trim(),
              updatedAt: DateTime.now(),
            ),
          );
    }
  }

  Future<TodayLogData> loadDay(DateTime date) => database.transaction(() async {
    final start = DateTime(date.year, date.month, date.day);
    final nutrition = await NutritionRepository(database).loadDay(start);
    final workouts = await FitnessRepository(database).workoutsOnDate(start);
    final executions =
        await (database.select(database.cycleDayExecutions)
              ..where(
                (row) =>
                    RecordDay.matches(row.localDate, row.occurredAt, start),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.occurredAt)]))
            .get();
    final actions = <TodayFitnessAction>[];
    for (final execution in executions) {
      final cycle =
          await (database.select(database.cycleInstances)
                ..where((row) => row.id.equals(execution.cycleInstanceId)))
              .getSingleOrNull();
      final plan = cycle == null
          ? null
          : await (database.select(
              database.trainingPlans,
            )..where((row) => row.id.equals(cycle.planId))).getSingleOrNull();
      final day = execution.planDayId == null
          ? null
          : await (database.select(database.planDays)
                  ..where((row) => row.id.equals(execution.planDayId!)))
                .getSingleOrNull();
      actions.add(
        TodayFitnessAction(
          execution,
          cycle?.cycleNumber,
          plan?.name,
          day?.name,
        ),
      );
    }
    final types = await database.select(database.bodyMeasurementTypes).get();
    final measurements =
        await (database.select(database.bodyMeasurements)
              ..where((row) => row.localDate.equals(nutrition.localDate))
              ..orderBy([(row) => OrderingTerm.asc(row.recordedAt)]))
            .get();
    return TodayLogData(
      date: start,
      workouts: workouts,
      actions: actions,
      nutrition: nutrition,
      bodyTypes: {for (final type in types) type.id: type},
      measurements: measurements,
      note:
          (await (database.select(database.dailyNotes)
                    ..where((r) => r.localDate.equals(nutrition.localDate)))
                  .getSingleOrNull())
              ?.content ??
          '',
      cardio: await (database.select(
        database.cardioLogs,
      )..where((r) => r.localDate.equals(nutrition.localDate))).get(),
    );
  });
}
