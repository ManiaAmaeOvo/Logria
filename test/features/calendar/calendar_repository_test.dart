import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/calendar/data/calendar_repository.dart';

void main() {
  late AppDatabase db;
  late CalendarRepository repo;
  final now = DateTime(2026, 10, 4, 12);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CalendarRepository(db);
  });
  tearDown(() => db.close());

  Future<void> plan(String id) => db
      .into(db.trainingPlans)
      .insert(
        TrainingPlansCompanion.insert(
          id: id,
          name: id,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: now,
        ),
      );
  Future<void> cycle(
    String id,
    String planId,
    int number,
    DateTime start, [
    DateTime? end,
  ]) => db
      .into(db.cycleInstances)
      .insert(
        CycleInstancesCompanion.insert(
          id: id,
          planId: planId,
          cycleNumber: number,
          colorValue: 0xFF356859,
          status: end == null ? 'active' : 'completed',
          startedAt: start,
          completedAt: Value(end),
        ),
      );

  test('explicit activity wins at cycle boundaries and meal/body dates inherit spans', () async {
    await plan('PPL');
    await cycle(
      'round1',
      'PPL',
      1,
      DateTime(2026, 9, 25),
      DateTime(2026, 9, 28, 12),
    );
    await cycle(
      'round2',
      'PPL',
      2,
      DateTime(2026, 9, 28, 12),
      DateTime(2026, 10, 3, 12),
    );
    await cycle('round3', 'PPL', 3, DateTime(2026, 10, 3, 12));
    await db
        .into(db.cycleDayExecutions)
        .insert(
          CycleDayExecutionsCompanion.insert(
            id: 'rest',
            cycleInstanceId: 'round1',
            executionType: 'plannedRest',
            occurredAt: DateTime(2026, 9, 28, 12),
          ),
        );
    await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: 'workout',
            localDate: '2026-10-03',
            cycleInstanceId: const Value('round2'),
            status: 'completed',
            startedAt: DateTime(2026, 10, 3, 12),
          ),
        );
    await db
        .into(db.foodLogEntries)
        .insert(
          FoodLogEntriesCompanion.insert(
            id: 'food',
            localDate: '2026-10-04',
            textContent: 'Meal',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.bodyMeasurementTypes)
        .insert(
          BodyMeasurementTypesCompanion.insert(
            id: 'weight',
            keyName: 'weight',
            displayName: 'Weight',
            defaultUnit: 'kg',
          ),
        );
    await db
        .into(db.bodyMeasurements)
        .insert(
          BodyMeasurementsCompanion.insert(
            id: 'body',
            measurementTypeId: 'weight',
            localDate: '2026-10-04',
            value: 80,
            unit: 'kg',
            recordedAt: now,
          ),
        );
    final september = await repo.loadMonth(DateTime(2026, 9), now: now);
    expect(september.days['2026-09-28']!.cycleIds, {'round1'});
    expect(september.days['2026-09-28']!.rest, isTrue);
    expect(september.days['2026-09-29']!.cycleIds, {'round2'});
    final october = await repo.loadMonth(DateTime(2026, 10), now: now);
    expect(october.days['2026-10-03']!.cycleIds, {'round2'});
    expect(october.days['2026-10-03']!.training, isTrue);
    expect(october.days['2026-10-04']!.cycleIds, {'round3'});
    expect(october.days['2026-10-04']!.nutrition, isTrue);
    expect(october.days['2026-10-04']!.body, isTrue);
    expect(october.days['2026-10-05'], isNull);
  });

  test(
    'an unfinished old plan does not overlap a newer plan indefinitely',
    () async {
      await plan('old');
      await plan('new');
      await cycle('old-cycle', 'old', 1, DateTime(2026, 9, 28));
      await cycle('new-cycle', 'new', 1, DateTime(2026, 10, 2));
      final october = await repo.loadMonth(DateTime(2026, 10), now: now);
      expect(october.days['2026-10-01']!.cycleIds, {'old-cycle'});
      expect(october.days['2026-10-02']!.cycleIds, {'new-cycle'});
      expect(october.days['2026-10-04']!.cycleIds, {'new-cycle'});
    },
  );

  test('manual nutrition and skipped training receive markers without meals/workouts', () async {
    await plan('plan');
    await cycle('cycle', 'plan', 1, DateTime(2026, 10, 1));
    await db
        .into(db.cycleDayExecutions)
        .insert(
          CycleDayExecutionsCompanion.insert(
            id: 'skip',
            cycleInstanceId: 'cycle',
            executionType: 'skippedTraining',
            occurredAt: DateTime(2026, 10, 4),
          ),
        );
    await db
        .into(db.dailyNutritionRecords)
        .insert(
          DailyNutritionRecordsCompanion.insert(
            id: 'nutrition',
            localDate: '2026-10-04',
            proteinGrams: const Value(150),
            updatedAt: now,
          ),
        );
    final month = await repo.loadMonth(DateTime(2026, 10), now: now);
    expect(month.days['2026-10-04']!.skipped, isTrue);
    expect(month.days['2026-10-04']!.training, isFalse);
    expect(month.days['2026-10-04']!.nutrition, isTrue);
  });
}
