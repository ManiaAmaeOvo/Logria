import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/today/data/today_repository.dart';
import 'package:logria/features/today/presentation/today_log_formatter.dart';
import 'package:logria/features/calendar/data/calendar_repository.dart';
import 'package:logria/l10n/app_localizations_en.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en'));
  late AppDatabase db;
  late FitnessRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FitnessRepository(db);
  });
  tearDown(() => db.close());

  test(
    'numeric, text-zero and text-null weights round trip and filter PR',
    () async {
      await repo.activateTemplate(builtInTrainingPlanTemplates.first);
      await repo.completeWorkout((await repo.loadDashboard())!, const [
        WorkoutDraftExercise(
          name: 'Bench press',
          saveAsPreset: true,
          sets: [
            WorkoutDraftSet(weight: 40, reps: 8, rir: 2),
            WorkoutDraftSet(weight: 45, reps: 4, rir: null),
            WorkoutDraftSet(
              weight: null,
              weightText: 'bodyweight',
              reps: 10,
              rir: null,
            ),
          ],
        ),
        WorkoutDraftExercise(
          name: 'Push-up',
          saveAsPreset: true,
          sets: [
            WorkoutDraftSet(
              weight: 0,
              weightText: 'bodyweight',
              reps: 12,
              rir: null,
            ),
          ],
        ),
        WorkoutDraftExercise(
          name: 'Unknown',
          saveAsPreset: false,
          sets: [
            WorkoutDraftSet(
              weight: null,
              weightText: 'heavy band',
              reps: null,
              rir: 2,
            ),
          ],
        ),
      ]);
      final sets = await db.select(db.workoutSets).get();
      expect(sets[2].weightText, 'bodyweight');
      expect(sets[2].weightValue, isNull);
      expect(sets[3].weightText, 'bodyweight');
      expect(sets[3].weightValue, 0);
      expect((await repo.prHistory('Bench press')).single.weight, 45);
      expect((await repo.prHistory('Push-up')).single.weight, 0);
      expect(await repo.prHistory('Unknown'), isEmpty);
      final text = TodayLogFormatter(
        await TodayRepository(db).loadDay(DateTime.now()),
        AppLocalizationsEn(),
      ).fitness;
      expect(text, contains('heavy band'));
      expect(text, contains('bodyweight'));
    },
  );

  test(
    'selected tracking and manual PR persist independently of workouts',
    () async {
      expect(await repo.trackedExercises(), isEmpty);
      await repo.trackExercise('Squat', true);
      await repo.addPr('Squat', DateTime(2026, 10, 1), 100, 3);
      await repo.addPr('Squat', DateTime(2026, 9, 1), 90, null);
      expect(await FitnessRepository(db).trackedExercises(), ['Squat']);
      final points = await repo.prHistory('Squat');
      expect(points.map((p) => p.weight), [90, 100]);
      await repo.trackExercise('Squat', false);
      expect(await repo.prHistory('Squat'), hasLength(2));
      await repo.deletePr(points.last.id!);
      expect(await repo.prHistory('Squat'), hasLength(1));
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      await expectLater(
        repo.addPr('Squat', DateTime.now(), double.nan, null),
        throwsArgumentError,
      );
    },
  );

  test(
    'cardio can be logged on rest days without consuming another cycle day',
    () async {
      await repo.activateTemplate(builtInTrainingPlanTemplates.first);
      await repo.takeRest();
      await repo.saveCardio(
        date: DateTime.now(),
        activity: 'Running',
        minutes: 30,
        distance: 5,
        notes: 'Easy',
      );
      final c = (await repo.cardioHistory()).single;
      expect(
        (await repo.loadDashboard())!.progress.consumedDayIds,
        hasLength(1),
      );
      final day = await TodayRepository(db).loadDay(DateTime.now());
      expect(
        TodayLogFormatter(day, AppLocalizationsEn()).fitness,
        contains('Running'),
      );
      final month = await CalendarRepository(db).loadMonth(DateTime.now());
      expect(month.days[c.localDate]!.training, isTrue);
      await repo.saveCardio(
        id: c.id,
        date: DateTime.now(),
        activity: 'Walking',
        minutes: 20,
      );
      expect((await repo.cardioHistory()).single.distanceKm, isNull);
      await repo.deleteCardio(c.id);
      expect(await repo.cardioHistory(), isEmpty);
      await expectLater(
        repo.saveCardio(date: DateTime.now(), activity: 'Run', minutes: 0),
        throwsArgumentError,
      );
    },
  );

  test('common presets are additive and idempotent', () async {
    await repo.createExercisePreset('My exercise');
    await repo.ensureCommonExercises(false);
    final count = (await repo.listExercises()).length;
    await repo.ensureCommonExercises(false);
    expect(await repo.listExercises(), hasLength(count));
    expect(
      (await repo.listExercises()).map((e) => e.name),
      containsAll(['My exercise', 'Bench press', 'Squat', 'Pull-up']),
    );
  });

  test(
    'schema 2 numeric sets survive the additive schema 3 migration',
    () async {
      await db.close();
      db = AppDatabase(
        NativeDatabase.memory(
          setup: (sqlite) {
            sqlite.execute(
              'CREATE TABLE workout_sets (id TEXT NOT NULL PRIMARY KEY, workout_exercise_id TEXT NOT NULL, set_number INTEGER NOT NULL, set_type TEXT NOT NULL DEFAULT \'working\', weight_value REAL, weight_unit TEXT NOT NULL DEFAULT \'kg\', reps INTEGER, rir REAL, is_completed INTEGER NOT NULL DEFAULT 0, notes TEXT)',
            );
            sqlite.execute(
              "INSERT INTO workout_sets (id, workout_exercise_id, set_number, weight_value, reps) VALUES ('old', 'exercise', 1, 40, 8)",
            );
            sqlite.execute('PRAGMA user_version = 2');
            sqlite.execute(
              'CREATE TABLE food_log_entries (id TEXT PRIMARY KEY)',
            );
            sqlite.execute(
              'CREATE TABLE daily_nutrition_records (id TEXT PRIMARY KEY)',
            );
          },
        ),
      );
      final set = await db.select(db.workoutSets).getSingle();
      expect(set.weightValue, 40);
      expect(set.weightText, isNull);
      expect(set.reps, 8);
      expect(await db.select(db.cardioLogs).get(), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
    },
  );
}
