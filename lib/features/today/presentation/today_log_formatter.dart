import 'package:intl/intl.dart';

import '../../../core/number_format.dart';
import '../../../core/workout_set_values.dart';

import '../../../l10n/app_localizations.dart';
import '../data/today_repository.dart';
import '../../nutrition/domain/nutrient_values.dart';
import '../../nutrition/presentation/nutrition_labels.dart';
import '../../nutrition/domain/meal_ingredient.dart';

class TodayLogFormatter {
  TodayLogFormatter(this.data, this.l, {this.historical = false});
  final bool historical;
  final TodayLogData data;
  final AppLocalizations l;

  String get fitness {
    final lines = <String>[];
    if (data.workouts.isEmpty && data.actions.isEmpty) lines.add(l.defaultRest);
    for (final action in data.actions) {
      if (action.execution.executionType == 'completedTraining' &&
          data.workouts.isNotEmpty) {
        continue;
      }
      final label = switch (action.execution.executionType) {
        'plannedRest' => l.plannedRestDone,
        'movedRest' => l.movedRestTaken,
        'extraRest' => l.extraRestTaken,
        'skippedTraining' => l.trainingSkipped,
        'completedTraining' => l.trainingRecorded,
        _ => action.execution.executionType,
      };
      lines.add('${_time(action.execution.occurredAt)} · $label');
      lines.add(
        [
          action.planName,
          if (action.cycleNumber != null) l.cycleNumber(action.cycleNumber!),
          action.dayName,
        ].whereType<String>().join(' · '),
      );
    }
    for (final workout in data.workouts) {
      final session = workout.session;
      if (lines.isNotEmpty) lines.add('');
      lines.add(
        [
          _time(session.startedAt),
          session.planNameSnapshot,
          if (workout.cycleNumber != null) l.cycleNumber(workout.cycleNumber!),
          session.dayNameSnapshot ?? l.freeWorkout,
        ].whereType<String>().join(' · '),
      );
      for (final exercise in workout.exercises) {
        lines.add(exercise.exercise.exerciseNameSnapshot);
        for (final set in exercise.sets) {
          lines.add(
            '  ${l.setLine(set.setNumber, set.weightText ?? _value(set.weightValue), set.weightText == null ? set.weightUnit : '', set.reps?.toString() ?? '—', set.rirLabel ?? '—', !set.isCompleted ? l.skippedSuffix : '')}',
          );
          if (set.notes?.isNotEmpty ?? false) lines.add('    ${set.notes}');
        }
        if (exercise.exercise.notes?.isNotEmpty ?? false) {
          lines.add(exercise.exercise.notes!);
        }
      }
      if (session.notes?.isNotEmpty ?? false) lines.add(session.notes!);
    }
    for (final cardio in data.cardio) {
      lines.add(
        '${l.cardioTitle}: ${cardio.activity} · ${cardio.minutes} min${cardio.distanceKm == null ? '' : ' · ${cardio.distanceKm} km'}${cardio.notes?.isNotEmpty == true ? ' · ${cardio.notes}' : ''}',
      );
    }
    return lines.isEmpty
        ? (historical ? l.noDateTraining : l.noTodayTraining)
        : lines.join('\n').trim();
  }

  List<String> get _foodExtras => extraNutrientUnits.keys
      .where(
        (key) =>
            decodeNutrients(data.nutrition.record?.extraNutrientsJson)
                .containsKey(key) ||
            data.nutrition.foodEntries.any(
              (e) =>
                  decodeNutrients(e.extraNutrientsJson).containsKey(key) ||
                  MealIngredient.decode(e.mealItemsJson)
                      .any((item) => item.nutrients.containsKey(key)),
            ),
      )
      .toList();
  List<String> get foodColumns => [
    l.foodLog,
    'P (g)',
    'C (g)',
    'F (g)',
    'kcal',
    for (final key in _foodExtras)
      '${nutrientLabel(key, l)} (${extraNutrientUnits[key]})',
  ];
  List<List<String>> get foodRows {
    final record = data.nutrition.record;
    final extras = _foodExtras;
    final rows = <List<String>>[];
    for (final entry in data.nutrition.foodEntries.reversed) {
      final items = MealIngredient.decode(entry.mealItemsJson);
      rows.add([
        '${_time(entry.occurredAt ?? entry.createdAt)} ${entry.textContent}${items.isEmpty ? '' : ' · ${l.mealRecordedSubtotal}'}${entry.caloriesKcal == null
            ? ''
            : entry.caloriesEstimated
            ? ' ≈'
            : ''}',
        _value(entry.proteinGrams),
        _value(entry.carbohydrateGrams),
        _value(entry.fatGrams),
        _value(entry.caloriesKcal),
        for (final key in extras)
          _value(decodeNutrients(entry.extraNutrientsJson)[key]),
      ]);
      for (final item in items) {
        rows.add([
          '↳ ${item.name} · ${_value(item.quantity)} ${foodUnitLabel(item.unit, l)}',
          for (final key in [
            'protein',
            'carbohydrate',
            'fat',
            'calories',
            ...extras,
          ])
            _value(item.nutrients[key]),
        ]);
      }
    }
    rows.add([
      '${l.dailyIntake} · ${record?.source == 'meals' || record == null ? l.mealTotalLabel : l.manualTotalLabel}',
      _value(record?.proteinGrams),
      _value(record?.carbohydrateGrams),
      _value(record?.fatGrams),
      _value(record?.caloriesKcal),
      for (final key in extras)
        _value(decodeNutrients(record?.extraNutrientsJson)[key]),
    ]);
    return rows;
  }

  bool get hasMealIngredients => data.nutrition.foodEntries.any(
    (entry) => MealIngredient.decode(entry.mealItemsJson).isNotEmpty,
  );

  String _cell(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('\\', '\\\\')
      .replaceAll('|', '\\|')
      .replaceAll('\n', '<br>')
      .replaceAll('\r', '')
      .replaceAll('`', '\\`')
      .replaceAll('*', '\\*')
      .replaceAll('[', '\\[')
      .replaceAll(']', '\\]');
  String get food => [
    '| ${foodColumns.map(_cell).join(' | ')} |',
    '| ${List.filled(foodColumns.length, '---').join(' | ')} |',
    for (final row in foodRows) '| ${row.map(_cell).join(' | ')} |',
    if (hasMealIngredients) l.mealIngredientTableHint,
    l.missingNutritionHint,
    if (_foodExtras.isNotEmpty) l.foodMissingHint,
  ].join('\n');

  String get body {
    if (data.measurements.isEmpty && data.sleep == null) {
      return historical ? l.noDateBody : l.noTodayBody;
    }
    final measurements = data.measurements
        .map((m) {
          final type = data.bodyTypes[m.measurementTypeId];
          final name = switch (type?.keyName) {
            'weight' => l.bodyWeight,
            'height' => l.bodyHeight,
            'body_fat' => l.bodyFat,
            'waist' => l.bodyWaist,
            'arm' => l.bodyArm,
            'chest' => l.bodyChest,
            'hip' => l.bodyHip,
            'thigh' => l.bodyThigh,
            _ => type?.displayName ?? l.measurementType,
          };
          return '$name: ${_value(m.value)} ${m.unit}${m.notes?.isNotEmpty == true ? ' · ${m.notes}' : ''}';
        })
        .join('\n');
    final sleep = data.sleep;
    return [
      if (measurements.isNotEmpty) measurements,
      if (sleep != null)
        '${l.sleep}: ${sleep.startedAt.toIso8601String()} → ${sleep.endedAt.toIso8601String()} · ${_value(sleep.endedAt.difference(sleep.startedAt).inMinutes / 60)} h${sleep.notes == null ? '' : ' · ${sleep.notes}'}',
    ].join('\n');
  }

  String section(String title, String text) =>
      '$title · ${data.nutrition.localDate}\n$text';
  String get all => [
    'Logria · ${data.nutrition.localDate}',
    section(l.fitness, fitness),
    section(l.nutrition, food),
    section(l.body, body),
    if (data.note.isNotEmpty) section(l.dailyReview, data.note),
  ].join('\n\n');
  String _time(DateTime value) =>
      DateFormat.Hm(l.localeName).format(value.toLocal());
  String _value(double? value) => value == null ? '—' : formatNumber(value);
}
