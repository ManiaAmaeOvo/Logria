import 'dart:convert';

/// Canonical units: P/C/F/fiber in grams; minerals in milligrams; energy in kcal.
const extraNutrientUnits = {
  'sodium': 'mg',
  'potassium': 'mg',
  'calcium': 'mg',
  'iron': 'mg',
  'fiber': 'g',
};
const nutrientKeys = [
  'protein',
  'carbohydrate',
  'fat',
  'calories',
  'sodium',
  'potassium',
  'calcium',
  'iron',
  'fiber',
];
const kilojoulesPerKcal = 4.184;

Map<String, double> decodeNutrients(String? raw) => raw == null
    ? {}
    : (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );

void validateNutrients(Map<String, double> values) {
  for (final entry in values.entries) {
    if (!nutrientKeys.contains(entry.key) ||
        !entry.value.isFinite ||
        entry.value < 0) {
      throw ArgumentError('Invalid nutrient: ${entry.key}');
    }
  }
}

Map<String, double> scaleNutrients(
  Map<String, double> values,
  double quantity,
  double referenceQuantity,
) {
  validateNutrients(values);
  if (!quantity.isFinite ||
      quantity <= 0 ||
      !referenceQuantity.isFinite ||
      referenceQuantity <= 0) {
    throw ArgumentError('Quantity must be finite and positive.');
  }
  final result = values.map(
    (k, v) => MapEntry(k, v * quantity / referenceQuantity),
  );
  validateNutrients(result);
  return result;
}

Map<String, double> sumExtras(Iterable<String?> records) {
  final result = <String, double>{};
  for (final raw in records) {
    for (final entry in decodeNutrients(raw).entries) {
      if (extraNutrientUnits.containsKey(entry.key)) {
        result.update(
          entry.key,
          (v) => v + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }
  }
  return result;
}

class NutrientTarget {
  const NutrientTarget(this.value, this.mode);
  final double value;

  /// goal = progress target; minimum = lower bound; limit = upper bound.
  final String mode;
}
