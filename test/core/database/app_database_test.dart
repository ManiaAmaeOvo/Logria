import 'package:drift/drift.dart';
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
}
