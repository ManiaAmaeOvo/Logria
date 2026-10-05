import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('schema 3 settings survive the additive daily-note migration', () async {
    await database.close();
    database = AppDatabase(
      NativeDatabase.memory(
        setup: (sqlite) {
          sqlite.execute(
            'CREATE TABLE app_settings (key_name TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL, updated_at INTEGER NOT NULL)',
          );
          sqlite.execute(
            "INSERT INTO app_settings VALUES ('app.language', 'zh', 1)",
          );
          sqlite.execute('PRAGMA user_version = 3');
          sqlite.execute('CREATE TABLE food_log_entries (id TEXT PRIMARY KEY)');
          sqlite.execute(
            'CREATE TABLE daily_nutrition_records (id TEXT PRIMARY KEY)',
          );
        },
      ),
    );
    final old = database;
    expect((await old.select(old.appSettings).getSingle()).value, 'zh');
    await old
        .into(old.dailyNotes)
        .insert(
          DailyNotesCompanion.insert(
            localDate: '2026-10-04',
            content: 'Still local',
            updatedAt: DateTime.now(),
          ),
        );
    expect(
      (await old.select(old.dailyNotes).getSingle()).content,
      'Still local',
    );
    expect(old.schemaVersion, 5);
  });

  test('food text and nutrition totals persist independently', () async {
    final now = DateTime(2026, 9, 23, 12);

    await database
        .into(database.foodLogEntries)
        .insert(
          FoodLogEntriesCompanion.insert(
            id: 'food-1',
            localDate: '2026-09-23',
            textContent: '鸡胸肉、米饭、西兰花',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.dailyNutritionRecords)
        .insert(
          DailyNutritionRecordsCompanion.insert(
            id: 'nutrition-1',
            localDate: '2026-09-23',
            proteinGrams: const Value(160),
            carbohydrateGrams: const Value(260),
            fatGrams: const Value(70),
            caloriesKcal: const Value(2310),
            source: const Value('external_llm'),
            updatedAt: now,
          ),
        );

    final food = await database.select(database.foodLogEntries).getSingle();
    final nutrition = await database
        .select(database.dailyNutritionRecords)
        .getSingle();

    expect(food.textContent, '鸡胸肉、米饭、西兰花');
    expect(nutrition.proteinGrams, 160);
    expect(nutrition.source, 'external_llm');
  });

  test(
    'schema 4 meals and notes survive schema 5; added fields stay unknown',
    () async {
      await database.close();
      database = AppDatabase(
        NativeDatabase.memory(
          setup: (sqlite) {
            sqlite.execute(
              'CREATE TABLE food_log_entries (id TEXT PRIMARY KEY, local_date TEXT NOT NULL, text_content TEXT NOT NULL, occurred_at INTEGER, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, protein_grams REAL, carbohydrate_grams REAL, fat_grams REAL, calories_kcal REAL, calories_estimated INTEGER NOT NULL DEFAULT 1)',
            );
            sqlite.execute(
              "INSERT INTO food_log_entries VALUES ('meal', '2026-10-04', 'Existing dinner', NULL, 0, 0, 30, 40, 10, 370, 0)",
            );
            sqlite.execute(
              'CREATE TABLE daily_nutrition_records (id TEXT PRIMARY KEY)',
            );
            sqlite.execute(
              'CREATE TABLE daily_notes (local_date TEXT PRIMARY KEY, content TEXT NOT NULL, updated_at INTEGER NOT NULL)',
            );
            sqlite.execute(
              "INSERT INTO daily_notes VALUES ('2026-10-04', 'Existing review', 0)",
            );
            sqlite.execute('PRAGMA user_version = 4');
          },
        ),
      );
      final meal = await database.select(database.foodLogEntries).getSingle();
      expect(meal.textContent, 'Existing dinner');
      expect(meal.proteinGrams, 30);
      expect(meal.caloriesKcal, 370);
      expect(meal.extraNutrientsJson, isNull);
      expect(meal.presetId, isNull);
      expect(meal.quantity, isNull);
      expect(
        (await database.select(database.dailyNotes).getSingle()).content,
        'Existing review',
      );
      expect(await database.select(database.foodPresets).get(), isEmpty);
    },
  );
}
