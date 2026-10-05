import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/nutrition/data/food_preset_repository.dart';
import 'package:logria/features/nutrition/data/nutrition_repository.dart';
import 'package:logria/features/nutrition/domain/nutrient_values.dart';
import 'package:logria/features/today/data/today_repository.dart';
import 'package:logria/features/today/presentation/today_log_formatter.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en'));
  late AppDatabase db;
  late FoodPresetRepository presets;
  late NutritionRepository nutrition;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    presets = FoodPresetRepository(db);
    nutrition = NutritionRepository(db);
  });
  tearDown(() => db.close());
  final date = DateTime(2026, 10, 5);
  test('built-ins are seeded once, raw/cooked bases differ, and grams scale nutrients', () async {
    final foods = await presets.list();
    expect(foods, hasLength(12));
    expect(await presets.list(), hasLength(12));
    final raw = foods.firstWhere((p) => p.id == 'usda:171077');
    final cooked = foods.firstWhere((p) => p.id == 'usda:171477');
    expect(decodeNutrients(raw.nutrientsJson)['protein'], 22.5);
    expect(decodeNutrients(cooked.nutrientsJson)['protein'], 31.02);
    await presets.log(
      preset: raw,
      date: date,
      quantity: 150,
      description: '150 g raw chicken',
    );
    final entry = (await nutrition.loadDay(date)).foodEntries.single;
    expect(entry.proteinGrams, 33.75);
    expect(entry.caloriesKcal, 180);
    expect(decodeNutrients(entry.extraNutrientsJson)['sodium'], 67.5);
    expect(entry.quantity, 150);
    expect(entry.quantityUnit, 'g');
    expect(entry.presetId, raw.id);
    await expectLater(presets.delete(raw), throwsStateError);
    await expectLater(
      presets.save(
        id: raw.id,
        name: 'Changed',
        unit: 'g',
        referenceQuantity: 100,
        preparation: 'raw',
        nutrients: {'protein': 20},
        estimated: true,
      ),
      throwsStateError,
    );
  });
  test('custom portions and bottles scale independently; edit/delete never changes logged snapshots', () async {
    final id = await presets.save(
      name: 'My yogurt',
      unit: 'bottle',
      referenceQuantity: 1,
      preparation: 'packaged',
      nutrients: {
        'protein': 20,
        'carbohydrate': 10,
        'fat': 3,
        'calories': 150,
        'sodium': 120,
      },
      estimated: false,
    );
    final food = (await presets.list()).firstWhere((p) => p.id == id);
    await presets.log(
      preset: food,
      date: date,
      quantity: 0.5,
      description: 'Half bottle',
    );
    await presets.save(
      id: id,
      name: 'New formula',
      unit: 'bottle',
      referenceQuantity: 1,
      preparation: 'packaged',
      nutrients: {'protein': 25, 'calories': 180},
      estimated: false,
    );
    await presets.delete((await presets.list()).firstWhere((p) => p.id == id));
    final entry = (await nutrition.loadDay(date)).foodEntries.single;
    expect(entry.proteinGrams, 10);
    expect(entry.caloriesKcal, 75);
    expect(entry.textContent, 'Half bottle');
    expect(decodeNutrients(entry.extraNutrientsJson), {'sodium': 60});
    final recipe = await presets.save(
      name: 'Dinner',
      unit: 'portion',
      referenceQuantity: 2,
      preparation: 'other',
      nutrients: {
        'protein': 60,
        'carbohydrate': 160,
        'fat': 40,
        'calories': 1240,
      },
      estimated: true,
    );
    await presets.log(
      preset: (await presets.list()).firstWhere((p) => p.id == recipe),
      date: date,
      quantity: 1,
      description: 'One dinner portion',
    );
    expect((await nutrition.loadDay(date)).record!.proteinGrams, 40);
  });
  test('unknown, zero and partial extras differ; overrides and target modes persist', () async {
    await nutrition.addFoodEntry(
      date,
      'Meal A',
      extraNutrients: {'sodium': 0, 'fiber': 4},
    );
    await nutrition.addFoodEntry(date, 'Unknown meal');
    var day = await nutrition.loadDay(date);
    expect(decodeNutrients(day.record!.extraNutrientsJson), {
      'sodium': 0,
      'fiber': 4,
    });
    expect(day.record!.proteinGrams, isNull);
    expect(
      decodeNutrients(day.record!.extraNutrientsJson).containsKey('iron'),
      isFalse,
    );
    await nutrition.saveTargets(
      const NutritionTargets(
        extraTargets: {
          'sodium': NutrientTarget(2000, 'limit'),
          'fiber': NutrientTarget(25, 'minimum'),
          'calcium': NutrientTarget(1000, 'goal'),
        },
      ),
    );
    day = await NutritionRepository(db).loadDay(date);
    expect(day.targets.extraTargets['fiber']!.mode, 'minimum');
    await nutrition.saveDailyIntake(
      date: date,
      extraNutrients: {'sodium': 600},
    );
    expect(
      decodeNutrients(
        (await nutrition.loadDay(date)).record!.extraNutrientsJson,
      ),
      {'sodium': 600},
    );
    await nutrition.useMealTotals(date);
    expect(
      decodeNutrients(
        (await nutrition.loadDay(date)).record!.extraNutrientsJson,
      )['sodium'],
      0,
    );
    final text = TodayLogFormatter(
      await TodayRepository(db).loadDay(date),
      lookupAppLocalizations(const Locale('en')),
    ).all;
    expect(text, contains('Sodium: 0 mg'));
    expect(text, contains('Dietary fiber: 4 g'));
    expect((await nutrition.loadDay(DateTime(2026, 10, 4))).record, isNull);
    await nutrition.saveTargets(const NutritionTargets());
    expect((await nutrition.loadDay(date)).targets.extraTargets, isEmpty);
  });
  test(
    'invalid quantities and nutrients are rejected before logging',
    () async {
      for (final amount in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          () => scaleNutrients({'protein': 20}, amount, 100),
          throwsArgumentError,
        );
      }
      expect(
        () => scaleNutrients({'protein': 1e308}, 1e308, 1),
        throwsArgumentError,
      );
      await expectLater(
        presets.save(
          name: 'Invalid',
          unit: 'g',
          referenceQuantity: 0,
          preparation: 'raw',
          nutrients: {},
          estimated: true,
        ),
        throwsArgumentError,
      );
      await expectLater(
        nutrition.addFoodEntry(date, 'Invalid', extraNutrients: {'sodium': -1}),
        throwsArgumentError,
      );
      await expectLater(
        nutrition.saveTargets(
          const NutritionTargets(
            extraTargets: {'sodium': NutrientTarget(2000, 'bad')},
          ),
        ),
        throwsArgumentError,
      );
      expect((await nutrition.loadDay(date)).foodEntries, isEmpty);
    },
  );
}
