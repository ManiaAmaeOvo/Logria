import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/body/data/body_repository.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/nutrition/data/nutrition_repository.dart';
import 'package:logria/features/today/data/today_repository.dart';
import 'package:logria/features/today/presentation/today_log_formatter.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('zh');
  });
  late AppDatabase db;
  final today = DateUtils.dateOnly(DateTime.now());
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('today reads complete workout details, meals and only same-date measurements', () async {
    final fitness = FitnessRepository(db);
    await fitness.activateTemplate(builtInTrainingPlanTemplates.first);
    final dashboard = (await fitness.loadDashboard())!;
    await fitness.completeWorkout(dashboard, [
      const WorkoutDraftExercise(
        name: 'Bench press',
        saveAsPreset: false,
        sets: [
          WorkoutDraftSet(weight: 40, reps: 8, rir: 2),
          WorkoutDraftSet(weight: 42.5, reps: 6, rir: 1),
        ],
      ),
    ]);
    final nutrition = NutritionRepository(db);
    await nutrition.addFoodEntry(
      today,
      'Rice and chicken',
      proteinGrams: 30,
      carbohydrateGrams: 50,
      fatGrams: 10,
      caloriesKcal: 410,
    );
    await nutrition.addFoodEntry(
      today.subtract(const Duration(days: 1)),
      'Yesterday meal',
    );
    await nutrition.saveDailyIntake(
      date: today,
      proteinGrams: 150,
      caloriesKcal: 2000,
    );
    final body = BodyRepository(db);
    final types = (await body.loadDay(today)).types;
    final weightId = types.firstWhere((t) => t.keyName == 'weight').id;
    await body.saveDay(today.subtract(const Duration(days: 1)), {weightId: 80});
    await body.saveDay(today, {weightId: 79.5});
    final data = await TodayRepository(db).loadDay(today);
    expect(data.workouts.single.exercises.single.sets.length, 2);
    expect(data.workouts.single.cycleNumber, 1);
    expect(data.nutrition.record!.proteinGrams, 150);
    expect(data.measurements.single.value, 79.5);
    final en = TodayLogFormatter(
      data,
      lookupAppLocalizations(const Locale('en')),
    );
    expect(en.all, contains('Bench press'));
    expect(en.all, contains('40 kg × 8 reps · RIR 2'));
    expect(en.all, contains('42.5 kg × 6 reps · RIR 1'));
    expect(en.all, contains('Manual daily total'));
    expect(en.all, contains('P: 150 g'));
    expect(en.all, contains('Weight: 79.5 kg'));
    expect(en.all, isNot(contains('Yesterday meal')));
    final zh = TodayLogFormatter(
      data,
      lookupAppLocalizations(const Locale('zh')),
    );
    expect(zh.all, contains('体重: 79.5 kg'));
    expect(zh.all, contains('手动总量'));
  });

  test(
    'rest is included and unrecorded values are not reported as zero',
    () async {
      final fitness = FitnessRepository(db);
      await fitness.activateTemplate(builtInTrainingPlanTemplates.first);
      await fitness.takeRest();
      await NutritionRepository(db).addFoodEntry(today, 'Meal without numbers');
      final data = await TodayRepository(db).loadDay(today);
      expect(data.workouts, isEmpty);
      final text = TodayLogFormatter(
        data,
        lookupAppLocalizations(const Locale('en')),
      );
      expect(text.fitness, contains('rest'));
      expect(text.food, contains('P: — g'));
      expect(text.body, contains('No body measurements'));
      final empty = await TodayRepository(db)
          .loadDay(today.subtract(const Duration(days: 1)));
      expect(empty.actions, isEmpty);
    },
  );

  test(
    'reading empty Today does not create a plan or measurement presets',
    () async {
      final data = await TodayRepository(db).loadDay(today);
      expect(data.workouts, isEmpty);
      expect(data.bodyTypes, isEmpty);
      expect(await db.select(db.trainingPlans).get(), isEmpty);
    },
  );
}
