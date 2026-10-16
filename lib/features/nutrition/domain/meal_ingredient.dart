import 'dart:convert';

import '../../../core/database/app_database.dart';
import 'nutrient_values.dart';

/// Immutable, independent snapshot: changing a preset never alters an old meal.
class MealIngredient {
  const MealIngredient({
    required this.presetId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.nutrients,
  });
  final String presetId, name, unit;
  final double quantity;
  final Map<String, double> nutrients;
  factory MealIngredient.fromPreset(
    FoodPreset preset,
    double amount,
    String name,
  ) => MealIngredient(
    presetId: preset.id,
    name: name,
    unit: preset.unit,
    quantity: amount,
    nutrients: scaleNutrients(
      decodeNutrients(preset.nutrientsJson),
      amount,
      preset.referenceQuantity,
    ),
  );
  factory MealIngredient.fromJson(Map<String, dynamic> json) {
    final amount = (json['quantity'] as num).toDouble();
    final nutrients = (json['nutrients'] as Map).map(
      (k, v) => MapEntry(k as String, (v as num).toDouble()),
    );
    validateNutrients(nutrients);
    if (!amount.isFinite ||
        amount <= 0 ||
        (json['name'] as String).trim().isEmpty) {
      throw const FormatException('Invalid meal ingredient');
    }
    return MealIngredient(
      presetId: json['preset_id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      quantity: amount,
      nutrients: nutrients,
    );
  }
  Map<String, dynamic> toJson() => {
    'preset_id': presetId,
    'name': name,
    'unit': unit,
    'quantity': quantity,
    'nutrients': nutrients,
  };
  static List<MealIngredient> decode(String? raw) => raw == null
      ? []
      : (jsonDecode(raw) as List)
            .map((e) => MealIngredient.fromJson(Map<String, dynamic>.from(e)))
            .toList();
  static Map<String, double> totals(List<MealIngredient> items) {
    final values = <String, double>{};
    for (final item in items) {
      for (final e in item.nutrients.entries) {
        values[e.key] = (values[e.key] ?? 0) + e.value;
      }
    }
    validateNutrients(values);
    return values;
  }
}
