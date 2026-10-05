import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/built_in_foods.dart';
import '../domain/nutrient_values.dart';
import 'nutrition_repository.dart';

const foodUnits = ['g', 'ml', 'portion', 'bottle', 'scoop', 'bag'];
const foodPreparations = ['raw', 'cooked', 'packaged', 'other'];

class FoodPresetRepository {
  FoodPresetRepository(this.database);
  final AppDatabase database;
  Future<List<FoodPreset>> list() async {
    await database.transaction(() async {
      for (final food in builtInFoods) {
        await database
            .into(database.foodPresets)
            .insert(
              FoodPresetsCompanion.insert(
                id: 'usda:${food.id}',
                name: food.en,
                nameZh: Value(food.zh),
                unit: 'g',
                referenceQuantity: 100,
                preparation: Value(food.preparation),
                isBuiltIn: const Value(true),
                source: Value('USDA SR Legacy · FDC ${food.id} · 2018-04'),
                nutrientsJson: jsonEncode({
                  'protein': food.p,
                  'carbohydrate': food.c,
                  'fat': food.f,
                  'calories': food.kcal,
                  'sodium': food.sodium,
                  'potassium': food.potassium,
                  'calcium': food.calcium,
                  'iron': food.iron,
                  'fiber': food.fiber,
                }),
                updatedAt: DateTime(2018, 4),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
    return (database.select(database.foodPresets)..orderBy([
          (r) => OrderingTerm.asc(r.isBuiltIn),
          (r) => OrderingTerm.asc(r.name),
        ]))
        .get();
  }

  Future<String> save({
    String? id,
    required String name,
    required String unit,
    required double referenceQuantity,
    required String preparation,
    required Map<String, double> nutrients,
    required bool estimated,
  }) async {
    validateNutrients(nutrients);
    if (name.trim().isEmpty ||
        !foodUnits.contains(unit) ||
        !foodPreparations.contains(preparation) ||
        !referenceQuantity.isFinite ||
        referenceQuantity <= 0) {
      throw ArgumentError('Invalid food preset.');
    }
    final existing = id == null
        ? null
        : await (database.select(
            database.foodPresets,
          )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (id != null && (existing == null || existing.isBuiltIn)) {
      throw StateError('Copy built-in presets instead of changing them.');
    }
    final key = id ?? const Uuid().v4();
    await database
        .into(database.foodPresets)
        .insertOnConflictUpdate(
          FoodPresetsCompanion.insert(
            id: key,
            name: name.trim(),
            unit: unit,
            referenceQuantity: referenceQuantity,
            preparation: Value(preparation),
            nutrientsJson: jsonEncode(nutrients),
            caloriesEstimated: Value(estimated),
            updatedAt: DateTime.now(),
          ),
        );
    return key;
  }

  Future<void> delete(FoodPreset preset) async {
    if (preset.isBuiltIn) throw StateError('Built-in presets are read-only.');
    await (database.delete(
      database.foodPresets,
    )..where((r) => r.id.equals(preset.id))).go();
  }

  Future<void> log({
    required FoodPreset preset,
    required DateTime date,
    required double quantity,
    required String description,
  }) async {
    final values = scaleNutrients(
      decodeNutrients(preset.nutrientsJson),
      quantity,
      preset.referenceQuantity,
    );
    await NutritionRepository(database).addFoodEntry(
      date,
      description,
      proteinGrams: values['protein'],
      carbohydrateGrams: values['carbohydrate'],
      fatGrams: values['fat'],
      caloriesKcal: values['calories'],
      caloriesEstimated: preset.caloriesEstimated,
      extraNutrients: {
        for (final k in extraNutrientUnits.keys)
          if (values[k] != null) k: values[k]!,
      },
      presetId: preset.id,
      quantity: quantity,
      quantityUnit: preset.unit,
    );
  }
}
