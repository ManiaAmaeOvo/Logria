import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../data/today_repository.dart';

class TodayLogFormatter {
  TodayLogFormatter(this.data, this.l, {this.historical = false});
  final bool historical;
  final TodayLogData data;
  final AppLocalizations l;

  String get fitness {
    final lines = <String>[];
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
            '  ${l.setLine(set.setNumber, _value(set.weightValue), set.weightUnit, set.reps?.toString() ?? '—', _value(set.rir), !set.isCompleted ? l.skippedSuffix : '')}',
          );
          if (set.notes?.isNotEmpty ?? false) lines.add('    ${set.notes}');
        }
        if (exercise.exercise.notes?.isNotEmpty ?? false) {
          lines.add(exercise.exercise.notes!);
        }
      }
      if (session.notes?.isNotEmpty ?? false) lines.add(session.notes!);
    }
    return lines.isEmpty
        ? (historical ? l.noDateTraining : l.noTodayTraining)
        : lines.join('\n').trim();
  }

  String get food {
    final lines = <String>[];
    for (final entry in data.nutrition.foodEntries.reversed) {
      lines.add(
        '${_time(entry.occurredAt ?? entry.createdAt)} · ${entry.textContent}',
      );
      lines.add(
        _macros(
          entry.proteinGrams,
          entry.carbohydrateGrams,
          entry.fatGrams,
          entry.caloriesKcal,
        ),
      );
      if (entry.caloriesKcal != null) {
        lines.add(
          entry.caloriesEstimated
              ? l.caloriesEstimatedLabel
              : l.caloriesManualLabel,
        );
      }
      lines.add('');
    }
    if (lines.isEmpty) lines.add(historical ? l.noDateFood : l.noTodayFood);
    final record = data.nutrition.record;
    lines.add('');
    lines.add(
      '${l.dailyIntake} · ${record?.source == 'meals' || record == null ? l.mealTotalLabel : l.manualTotalLabel}',
    );
    lines.add(
      _macros(
        record?.proteinGrams,
        record?.carbohydrateGrams,
        record?.fatGrams,
        record?.caloriesKcal,
      ),
    );
    lines.add(l.missingNutritionHint);
    return lines.join('\n').trim();
  }

  String get body {
    if (data.measurements.isEmpty) {
      return historical ? l.noDateBody : l.noTodayBody;
    }
    return data.measurements
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
  }

  String section(String title, String text) =>
      '$title · ${data.nutrition.localDate}\n$text';
  String get all => [
    'Logria · ${data.nutrition.localDate}',
    section(l.fitness, fitness),
    section(l.nutrition, food),
    section(l.body, body),
  ].join('\n\n');
  String _time(DateTime value) =>
      DateFormat.Hm(l.localeName).format(value.toLocal());
  String _macros(double? p, double? c, double? f, double? kcal) =>
      'P: ${_value(p)} g · C: ${_value(c)} g · F: ${_value(f)} g · kcal: ${_value(kcal)}';
  String _value(double? value) => value == null
      ? '—'
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}
