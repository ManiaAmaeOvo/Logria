import 'package:flutter/material.dart';

import '../../../core/number_format.dart';
import '../../../l10n/app_localizations.dart';
import '../data/nutrition_repository.dart';
import '../domain/built_in_foods.dart';

/// Display-only arithmetic using the same reference foods as the preset library.
/// Missing intake is unknown, not zero. No database writes or implied meal plan.
class FoodEquivalenceHint extends StatelessWidget {
  const FoodEquivalenceHint({super.key, required this.day});

  final NutritionDayData day;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rice = builtInFoods.singleWhere((f) => f.id == '169757');
    final egg = builtInFoods.singleWhere((f) => f.id == '173424');
    final chicken = builtInFoods.singleWhere((f) => f.id == '171077');
    final estimates = <Widget>[];

    void add({
      required String nutrient,
      required double? target,
      required double? current,
      required bool isLimit,
      required String Function(double remaining) equivalent,
    }) {
      if (target == null || current == null || target <= current) return;
      final remaining = target - current;
      estimates.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLimit
                    ? l.foodEquivalenceLimit(formatNumber(remaining), nutrient)
                    : l.foodEquivalenceGoal(formatNumber(remaining), nutrient),
              ),
              Text(equivalent(remaining)),
            ],
          ),
        ),
      );
    }

    add(
      nutrient: l.foodEquivalenceCarbs,
      target: day.targets.carbohydrateGoalGrams,
      current: day.record?.carbohydrateGrams,
      isLimit: day.targets.carbohydrateIsLimit,
      equivalent: (r) =>
          l.foodEquivalenceRice((r * 100 / rice.c).toStringAsFixed(0)),
    );
    add(
      nutrient: l.foodEquivalenceProteinLabel,
      target: day.targets.proteinGoalGrams,
      current: day.record?.proteinGrams,
      isLimit: day.targets.proteinIsLimit,
      equivalent: (r) => l.foodEquivalenceProtein(
        (r / (egg.p * .5)).toStringAsFixed(1),
        (r * 100 / chicken.p).toStringAsFixed(0),
      ),
    );
    if (estimates.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.foodEquivalenceTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...estimates,
              const SizedBox(height: 12),
              Text(
                l.foodEquivalenceBasis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
