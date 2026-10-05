import '../../../l10n/app_localizations.dart';

String nutrientLabel(String key, AppLocalizations l) => switch (key) {
  'protein' => l.proteinGrams,
  'carbohydrate' => l.carbohydrateGrams,
  'fat' => l.fatGrams,
  'calories' => l.caloriesKcal,
  'sodium' => l.nutrientSodium,
  'potassium' => l.nutrientPotassium,
  'calcium' => l.nutrientCalcium,
  'iron' => l.nutrientIron,
  'fiber' => l.nutrientFiber,
  _ => key,
};
String foodUnitLabel(String unit, AppLocalizations l) => switch (unit) {
  'portion' => l.foodPortion,
  'bottle' => l.foodBottle,
  'scoop' => l.foodScoop,
  'bag' => l.foodBag,
  'ml' => 'mL',
  _ => unit,
};
String preparationLabel(String value, AppLocalizations l) => switch (value) {
  'raw' => l.foodRaw,
  'cooked' => l.foodCooked,
  'packaged' => l.foodPackaged,
  _ => l.foodOther,
};
String targetModeLabel(String mode, AppLocalizations l) => switch (mode) {
  'limit' => l.nutrientLimit,
  'minimum' => l.nutrientMinimum,
  _ => l.nutrientGoal,
};
