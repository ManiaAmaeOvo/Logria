import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/nutrition/data/nutrition_repository.dart';

void main() {
  late AppDatabase db;
  late NutritionRepository repo;
  final date = DateTime(2026, 10, 4);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = NutritionRepository(db);
  });
  tearDown(() => db.close());

  test('meals aggregate, edit, delete and remain isolated by date', () async {
    await repo.addFoodEntry(date, 'Text only');
    expect((await repo.loadDay(date)).record, isNull);
    final id = await repo.addFoodEntry(
      date,
      'Lunch',
      proteinGrams: 30,
      carbohydrateGrams: 50,
      fatGrams: 10,
      caloriesKcal: 410,
    );
    await repo.addFoodEntry(
      date,
      'Snack',
      proteinGrams: 10,
      caloriesKcal: 80,
      caloriesEstimated: false,
    );
    await repo.addFoodEntry(
      DateTime(2026, 10, 3),
      'Other day',
      proteinGrams: 100,
    );
    var day = await repo.loadDay(date);
    expect(day.record!.proteinGrams, 40);
    expect(day.record!.caloriesKcal, 490);
    expect(day.record!.source, 'meals');
    await repo.updateFoodEntry(
      id,
      'Updated lunch',
      proteinGrams: 20,
      caloriesKcal: 80,
    );
    day = await repo.loadDay(date);
    expect(day.record!.proteinGrams, 30);
    expect(day.record!.carbohydrateGrams, isNull);
    await repo.deleteFoodEntry(id);
    expect((await repo.loadDay(date)).record!.proteinGrams, 10);
  });

  test('manual daily total takes precedence until restored', () async {
    await repo.addFoodEntry(date, 'Lunch', proteinGrams: 30);
    await repo.saveDailyIntake(
      date: date,
      proteinGrams: 150,
      caloriesKcal: 2000,
    );
    await repo.addFoodEntry(date, 'Dinner', proteinGrams: 20);
    expect((await repo.loadDay(date)).record!.proteinGrams, 150);
    await repo.useMealTotals(date);
    expect((await repo.loadDay(date)).record!.proteinGrams, 50);
  });

  test('all four goals persist and can be cleared', () async {
    await repo.saveTargets(
      const NutritionTargets(
        proteinGoalGrams: 150,
        carbohydrateGoalGrams: 250,
        fatGoalGrams: 70,
        calorieLimitKcal: 2300,
      ),
    );
    final goals = (await repo.loadDay(date)).targets;
    expect(goals.proteinGoalGrams, 150);
    expect(goals.carbohydrateGoalGrams, 250);
    expect(goals.fatGoalGrams, 70);
    expect(goals.calorieLimitKcal, 2300);
    await repo.saveTargets(const NutritionTargets());
    expect((await repo.loadDay(date)).targets.fatGoalGrams, isNull);
  });

  test('each nutrient independently remembers goal or limit mode', () async {
    final initial = (await repo.loadDay(date)).targets;
    expect(initial.proteinIsLimit, isFalse);
    expect(initial.caloriesIsLimit, isTrue);
    await repo.saveTargets(
      const NutritionTargets(
        proteinGoalGrams: 150,
        carbohydrateGoalGrams: 250,
        fatGoalGrams: 70,
        calorieLimitKcal: 2300,
        proteinIsLimit: true,
        carbohydrateIsLimit: false,
        fatIsLimit: true,
        caloriesIsLimit: false,
      ),
    );
    final saved = (await repo.loadDay(date)).targets;
    expect(saved.proteinIsLimit, isTrue);
    expect(saved.carbohydrateIsLimit, isFalse);
    expect(saved.fatIsLimit, isTrue);
    expect(saved.caloriesIsLimit, isFalse);
    expect(saved.calorieLimitKcal, 2300);
  });

  test('version 1 food notes survive the additive migration', () async {
    await db.close();
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (sqlite) {
          sqlite.execute(
            'CREATE TABLE food_log_entries (id TEXT NOT NULL PRIMARY KEY, local_date TEXT NOT NULL, text_content TEXT NOT NULL, occurred_at INTEGER, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)',
          );
          sqlite.execute(
            "INSERT INTO food_log_entries VALUES ('old', '2026-10-03', 'Existing note', NULL, 0, 0)",
          );
          sqlite.execute('PRAGMA user_version = 1');
          sqlite.execute(
            'CREATE TABLE workout_sets (id TEXT NOT NULL PRIMARY KEY)',
          );
        },
      ),
    );
    final entry = await db.select(db.foodLogEntries).getSingle();
    expect(entry.textContent, 'Existing note');
    expect(entry.proteinGrams, isNull);
    expect(entry.caloriesEstimated, isTrue);
  });
}
