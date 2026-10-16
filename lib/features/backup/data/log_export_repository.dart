import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/record_day.dart';
import '../../../core/workout_set_values.dart';
import '../../today/data/today_repository.dart';
import '../../nutrition/domain/meal_ingredient.dart';

class LogExportRepository {
  LogExportRepository(this.database);
  final AppDatabase database;
  Future<String> export(
    DateTime from,
    DateTime to, {
    bool includeBody = true,
  }) => database.transaction(() async {
    final start = RecordDay.dateOnly(from), end = RecordDay.dateOnly(to);
    if (end.isBefore(start) ||
        end.isAfter(RecordDay.today()) ||
        end.difference(start).inDays > 3660) {
      throw ArgumentError('Invalid export range (maximum 10 years)');
    }
    final days = <Map<String, dynamic>>[];
    for (
      var date = start;
      !date.isAfter(end);
      date = DateTime(date.year, date.month, date.day + 1)
    ) {
      final data = await TodayRepository(database).loadDay(date);
      days.add({
        'date': RecordDay.key(date),
        'fitness': {
          'implicit_rest': data.workouts.isEmpty && data.actions.isEmpty,
          'actions': [
            for (final a in data.actions)
              {
                ...a.execution.toJson(),
                'plan_name': a.planName,
                'cycle_number': a.cycleNumber,
                'day_name': a.dayName,
              },
          ],
          'sessions': [
            for (final w in data.workouts)
              {
                ...w.session.toJson(),
                'cycle_number': w.cycleNumber,
                'exercises': [
                  for (final e in w.exercises)
                    {
                      ...e.exercise.toJson(),
                      'sets': [
                        for (final s in e.sets)
                          {
                            ...s.toJson()
                              ..remove('rir')
                              ..remove('rirText'),
                            'rir': s.rirLabel,
                          },
                      ],
                    },
                ],
              },
          ],
          'cardio': data.cardio.map((c) => c.toJson()).toList(),
          'manual_pr':
              (await (database.select(database.personalRecords)
                        ..where((p) => p.localDate.equals(RecordDay.key(date))))
                      .get())
                  .map((p) => p.toJson())
                  .toList(),
        },
        'food': [
          for (final food in data.nutrition.foodEntries)
            {
              ...food.toJson()..remove('mealItemsJson'),
              'ingredients': MealIngredient.decode(food.mealItemsJson)
                  .map((i) => i.toJson())
                  .toList(),
            },
        ],
        'nutrition': data.nutrition.record?.toJson(),
        'daily_review': data.note,
        if (includeBody)
          'body': {
            'measurements': [
              for (final m in data.measurements)
                {
                  ...m.toJson(),
                  'type': data.bodyTypes[m.measurementTypeId]?.keyName,
                  'display_name':
                      data.bodyTypes[m.measurementTypeId]?.displayName,
                },
            ],
            'sleep': data.sleep?.toJson(),
          },
      });
    }
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'logria.health_log',
      'schema_version': 2,
      'export_id': const Uuid().v4(),
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'time_zone': DateTime.now().timeZoneName,
      'utc_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
      'journal_cutoff_hour': 4,
      'date_range': {'from': RecordDay.key(start), 'to': RecordDay.key(end)},
      'included_data': {
        'fitness': true,
        'food': true,
        'nutrition': true,
        'daily_review': true,
        'body': includeBody,
      },
      'days': days,
    });
  });
}
