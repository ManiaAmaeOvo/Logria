import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/core/record_day.dart';
import 'package:logria/features/backup/data/backup_repository.dart';
import 'package:logria/features/backup/data/log_export_repository.dart';
import 'package:logria/features/body/data/sleep_repository.dart';
import 'package:logria/features/body/data/body_repository.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/nutrition/data/nutrition_repository.dart';
import 'package:logria/features/nutrition/data/food_preset_repository.dart';
import 'package:logria/features/nutrition/domain/meal_ingredient.dart';
import 'package:logria/features/today/data/today_repository.dart';
import 'package:logria/features/today/presentation/today_log_formatter.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  late AppDatabase db;
  late BackupRepository backups;
  final date = RecordDay.today();
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    backups = BackupRepository(db);
    await TodayRepository(db).saveNote(RecordDay.key(date), 'Keep this review');
  });
  tearDown(() => db.close());
  test('full backup round-trips every table, settings, drafts, sleep and composition', () async {
    final fitness = FitnessRepository(db);
    await fitness.activateTemplate(builtInTrainingPlanTemplates.first);
    await fitness.completeWorkout((await fitness.loadDashboard())!, const [
      WorkoutDraftExercise(
        name: 'Bench',
        saveAsPreset: true,
        sets: [
          WorkoutDraftSet(
            weight: 40,
            reps: 8,
            rir: '约 2–3',
            notes: 'Last rep slow',
          ),
        ],
      ),
    ]);
    await fitness.writeSetting('fitness.draft.sample', '[]');
    await SleepRepository(db).save(
      date,
      DateTime(date.year, date.month, date.day - 1, 23),
      DateTime(date.year, date.month, date.day, 7),
      'Good',
    );
    await BodyRepository(db).loadDay(date);
    final food = (await FoodPresetRepository(db).list()).first;
    final ingredient = MealIngredient.fromPreset(food, 150, food.name);
    await NutritionRepository(db).addFoodEntry(
      date,
      'Dinner',
      proteinGrams: ingredient.nutrients['protein'],
      mealItemsJson: jsonEncode([ingredient.toJson()]),
    );
    final text = await backups.create();
    final original = (jsonDecode(text) as Map)['tables'];
    await TodayRepository(db).saveNote(RecordDay.key(date), 'Changed');
    await backups.restore(text);
    expect((jsonDecode(await backups.create()) as Map)['tables'], original);
    expect((await db.select(db.workoutSets).getSingle()).rirText, '约 2–3');
    expect(
      (await db.select(db.workoutSets).getSingle()).notes,
      'Last rep slow',
    );
  });
  test('corrupt JSON, health exports, future schemas and incomplete tables reject without changes', () async {
    final text = await backups.create();
    for (final invalid in [
      '{',
      jsonEncode({'format': 'logria.health_log'}),
      jsonEncode({...jsonDecode(text) as Map, 'database_schema': 999}),
      jsonEncode({...jsonDecode(text) as Map, 'tables': {}}),
    ]) {
      await expectLater(backups.restore(invalid), throwsA(anything));
      expect(
        (await TodayRepository(db).loadDay(date)).note,
        'Keep this review',
      );
    }
  });
  test(
    'undo recovery round-trips and can restore text RIR and set feelings',
    () async {
      final fitness = FitnessRepository(db);
      await fitness.activateTemplate(builtInTrainingPlanTemplates.first);
      await fitness.completeWorkout((await fitness.loadDashboard())!, const [
        WorkoutDraftExercise(
          name: 'Bench',
          saveAsPreset: true,
          sets: [
            WorkoutDraftSet(weight: 40, reps: 8, rir: '~2–3', notes: 'Slow'),
          ],
        ),
      ]);
      expect(await fitness.undoLatestFitnessActionToday(), true);
      final backup = await backups.create();
      await backups.restore(backup);
      expect(await fitness.redoLatestFitnessActionToday(), true);
      final set = await db.select(db.workoutSets).getSingle();
      expect(set.rirText, '~2–3');
      expect(set.notes, 'Slow');
    },
  );
  test(
    'legacy orphan workout rows are preserved in an inert restorable archive',
    () async {
      // Simulate an older install where foreign-key enforcement was disabled.
      await db.customStatement('PRAGMA foreign_keys = OFF');
      await db.customStatement(
        "INSERT INTO workout_exercises (id, workout_session_id, exercise_name_snapshot, position) VALUES ('orphan-ex', 'missing-session', 'Legacy bench', 1)",
      );
      await db.customStatement(
        "INSERT INTO workout_sets (id, workout_exercise_id, set_number, weight_value, notes) VALUES ('orphan-set', 'orphan-ex', 1, 40, 'Keep this feeling')",
      );
      await db.customStatement('PRAGMA foreign_keys = ON');
      final text = await backups.create();
      final tables = backups.validate(text);
      expect(BackupRepository.hasOrphanArchive(tables), true);
      expect(tables['workout_sets'], isEmpty);
      // Creating a backup itself never modifies the source database.
      expect(await db.select(db.workoutSets).get(), hasLength(1));
      await backups.restore(text);
      expect(await db.select(db.workoutSets).get(), isEmpty);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
      final setting = (await db.select(db.appSettings).get()).single;
      final archive = jsonDecode(setting.value) as Map;
      expect(archive['workout_sets'][0]['notes'], 'Keep this feeling');
      final roundtrip = jsonDecode(await backups.create()) as Map;
      expect(roundtrip['tables']['app_settings'][0]['value'], setting.value);
    },
  );
  test('foreign key errors rollback ALL replacement writes', () async {
    final json = jsonDecode(await backups.create()) as Map<String, dynamic>;
    (json['tables'] as Map)['body_measurements'] = [
      {
        'id': 'bad',
        'measurement_type_id': 'missing',
        'local_date': RecordDay.key(date),
        'value': 70.0,
        'unit': 'kg',
        'recorded_at': 1,
        'notes': null,
      },
    ];
    await expectLater(backups.restore(jsonEncode(json)), throwsA(anything));
    expect((await TodayRepository(db).loadDay(date)).note, 'Keep this review');
    expect(await db.select(db.bodyMeasurements).get(), isEmpty);
  });
  test(
    'invalid nested settings rollback a structurally valid backup',
    () async {
      final json = jsonDecode(await backups.create()) as Map<String, dynamic>;
      (json['tables'] as Map)['app_settings'] = [
        {
          'key_name': 'nutrition.extraTargets',
          'value': '{"sodium":{"value":"bad","mode":"minimum"}}',
          'updated_at': 1,
        },
      ];
      await expectLater(backups.restore(jsonEncode(json)), throwsA(anything));
      expect(
        (await TodayRepository(db).loadDay(date)).note,
        'Keep this review',
      );
      expect(await db.select(db.appSettings).get(), isEmpty);
    },
  );
  test('wrong scalar types and duplicate primary keys cannot destroy current records', () async {
    final json = jsonDecode(await backups.create()) as Map<String, dynamic>;
    final rows = (json['tables'] as Map)['daily_notes'] as List;
    rows.add(rows.first);
    await expectLater(backups.restore(jsonEncode(json)), throwsA(anything));
    expect((await TodayRepository(db).loadDay(date)).note, 'Keep this review');
    rows.removeLast();
    rows.first['content'] = 123;
    await expectLater(backups.restore(jsonEncode(json)), throwsFormatException);
  });
  test(
    'dated export includes snapshots and body/sleep only when opted in',
    () async {
      await SleepRepository(db).save(
        date,
        DateTime(date.year, date.month, date.day - 1, 23),
        DateTime(date.year, date.month, date.day, 7),
        'Private sleep',
      );
      await NutritionRepository(db).addFoodEntry(date, 'Lunch');
      final exporter = LogExportRepository(db);
      final hidden = jsonDecode(
        await exporter.export(date, date, includeBody: false),
      ) as Map;
      expect(hidden['format'], 'logria.health_log');
      expect(hidden['schema_version'], 2);
      expect(hidden['days'], hasLength(1));
      expect(hidden['days'][0].containsKey('body'), false);
      expect(hidden['days'][0]['food'][0]['textContent'], 'Lunch');
      expect(hidden['days'][0]['fitness']['implicit_rest'], true);
      final all = jsonDecode(await exporter.export(date, date)) as Map;
      expect(all['days'][0]['body']['sleep']['notes'], 'Private sleep');
      expect(all['days'][0]['daily_review'], 'Keep this review');
      await expectLater(
        exporter.export(date, date.subtract(const Duration(days: 1))),
        throwsArgumentError,
      );
      await expectLater(
        exporter.export(date, date.add(const Duration(days: 1))),
        throwsArgumentError,
      );
    },
  );
  test(
    'meal snapshots survive preset changes and preserve partial unknowns',
    () async {
      final foods = FoodPresetRepository(db);
      final id = await foods.save(
        name: 'Yogurt',
        unit: 'g',
        referenceQuantity: 100,
        preparation: 'packaged',
        nutrients: {'protein': 10, 'calories': 60},
        estimated: false,
      );
      final preset = (await foods.list()).firstWhere((p) => p.id == id);
      final a = MealIngredient.fromPreset(preset, 150, 'Yogurt');
      final b = MealIngredient.fromPreset(preset, 50, 'Yogurt');
      final totals = MealIngredient.totals([a, b]);
      expect(totals['protein'], 20);
      expect(totals['fat'], isNull);
      expect(totals['calories'], 120);
      await foods.save(
        id: id,
        name: 'Changed',
        unit: 'g',
        referenceQuantity: 100,
        preparation: 'packaged',
        nutrients: {'protein': 99},
        estimated: false,
      );
      expect(
        MealIngredient.decode(jsonEncode([a.toJson()]))
            .single
            .nutrients['protein'],
        15,
      );
    },
  );
  test('Markdown nutrition table escapes notes, preserves zero/unknown and manual override', () async {
    await NutritionRepository(
      db,
    ).addFoodEntry(date, 'Milk | tea\n<hi>', proteinGrams: 0, fatGrams: null);
    await NutritionRepository(db).saveDailyIntake(date: date, proteinGrams: 99);
    final formatter = TodayLogFormatter(
      await TodayRepository(db).loadDay(date),
      lookupAppLocalizations(const Locale('en')),
    );
    expect(formatter.food, contains('Milk \\| tea<br>&lt;hi&gt;'));
    expect(formatter.food, contains('| 0 | — | — |'));
    expect(formatter.food, contains('| 99 |'));
    expect(formatter.foodRows.last.first, contains('Manual'));
    expect(
      formatter.foodRows.every((r) => r.length == formatter.foodColumns.length),
      true,
    );
  });
  test(
    'sleep interval, editing, daily copying and deletion are date-bound',
    () async {
      final sleep = SleepRepository(db);
      final start = DateTime(date.year, date.month, date.day - 1, 23, 30);
      final end = DateTime(date.year, date.month, date.day, 7);
      await sleep.save(date, start, end, 'Nap?');
      expect(
        (await sleep.load(date))!.endedAt.difference(start).inMinutes,
        450,
      );
      final formatter = TodayLogFormatter(
        await TodayRepository(db).loadDay(date),
        lookupAppLocalizations(const Locale('en')),
      );
      expect(formatter.body, contains('7.5 h'));
      expect(await sleep.load(date.subtract(const Duration(days: 1))), isNull);
      await expectLater(sleep.save(date, end, start, ''), throwsArgumentError);
      await expectLater(
        sleep.save(date, start, start.add(const Duration(hours: 49)), ''),
        throwsArgumentError,
      );
      await sleep.delete(date);
      expect(await sleep.load(date), isNull);
    },
  );
}
