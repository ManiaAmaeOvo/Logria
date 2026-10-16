import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../nutrition/domain/meal_ingredient.dart';
import '../../nutrition/domain/nutrient_values.dart';

class BackupRepository {
  BackupRepository(this.database);
  final AppDatabase database;
  static const maxBytes = 32 * 1024 * 1024;

  Future<String> create() => database.transaction(() async {
    final tables = <String, dynamic>{};
    for (final table in database.allTables) {
      tables[table.actualTableName] =
          (await database
                  .customSelect('SELECT * FROM "${table.actualTableName}"')
                  .get())
              .map((r) => r.data)
              .toList();
    }
    // Older installs may contain rows left behind before FK enforcement. Never
    // discard them and never disable constraints during restore: archive their
    // complete snapshots in a dedicated, inert AppSettings value in the backup.
    final sessions = (tables['workout_sessions'] as List)
        .map((r) => r['id'])
        .toSet();
    final exercises = tables['workout_exercises'] as List;
    final orphanExercises = exercises
        .where((r) => !sessions.contains(r['workout_session_id']))
        .toList();
    exercises.removeWhere((r) => !sessions.contains(r['workout_session_id']));
    final exerciseIds = exercises.map((r) => r['id']).toSet();
    final sets = tables['workout_sets'] as List;
    final orphanSets = sets
        .where((r) => !exerciseIds.contains(r['workout_exercise_id']))
        .toList();
    sets.removeWhere((r) => !exerciseIds.contains(r['workout_exercise_id']));
    final violations = await database
        .customSelect('PRAGMA foreign_key_check')
        .get();
    if (violations.any(
      (r) =>
          !((r.data['table'] == 'workout_exercises' &&
                  r.data['parent'] == 'workout_sessions') ||
              (r.data['table'] == 'workout_sets' &&
                  r.data['parent'] == 'workout_exercises')),
    )) {
      throw StateError(
        'Unsupported broken references. Keep existing app data and export dated logs for diagnosis.',
      );
    }
    if (orphanExercises.isNotEmpty || orphanSets.isNotEmpty) {
      final settings = tables['app_settings'] as List;
      final previous = settings
          .where((r) => r['key_name'] == orphanArchiveKey)
          .firstOrNull;
      final archive = previous == null
          ? <String, dynamic>{'workout_exercises': [], 'workout_sets': []}
          : Map<String, dynamic>.from(jsonDecode(previous['value'] as String));
      (archive['workout_exercises'] as List).addAll(orphanExercises);
      (archive['workout_sets'] as List).addAll(orphanSets);
      settings.removeWhere((r) => r['key_name'] == orphanArchiveKey);
      settings.add({
        'key_name': orphanArchiveKey,
        'value': jsonEncode(archive),
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
    }
    final result = jsonEncode({
      'format': 'logria.backup',
      'version': 1,
      'database_schema': database.schemaVersion,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'tables': tables,
    });
    if (utf8.encode(result).length > maxBytes) {
      throw const FormatException('Backup exceeds 32 MiB');
    }
    return result;
  });
  static const orphanArchiveKey = 'backup.orphanedWorkoutRows';
  static bool hasOrphanArchive(Map<String, dynamic> tables) =>
      (tables['app_settings'] as List).any(
        (r) => r['key_name'] == orphanArchiveKey,
      );

  Map<String, dynamic> validate(String text) {
    if (utf8.encode(text).length > maxBytes) {
      throw const FormatException('Backup exceeds 32 MiB');
    }
    final json = jsonDecode(text);
    if (json is! Map<String, dynamic> ||
        json['format'] != 'logria.backup' ||
        json['version'] != 1 ||
        json['database_schema'] != database.schemaVersion ||
        json['tables'] is! Map<String, dynamic>) {
      throw const FormatException(
        'Unsupported backup format or database version',
      );
    }
    final tables = json['tables'] as Map<String, dynamic>;
    if (tables.length != database.allTables.length) {
      throw const FormatException('Incomplete backup');
    }
    for (final table in database.allTables) {
      final rows = tables[table.actualTableName];
      if (rows is! List || rows.length > 250000) {
        throw const FormatException('Invalid backup table');
      }
      for (final row in rows) {
        if (row is! Map || row.length != table.$columns.length) {
          throw const FormatException('Invalid backup row');
        }
        for (final column in table.$columns) {
          if (!row.containsKey(column.name)) {
            throw const FormatException('Missing backup column');
          }
          final value = row[column.name];
          if (value == null) {
            if (!column.$nullable) {
              throw const FormatException('Unexpected null');
            }
            continue;
          }
          final type = column.type;
          final valid = type == DriftSqlType.string
              ? value is String
              : type == DriftSqlType.double
              ? value is num && value.isFinite
              : type == DriftSqlType.bool
              ? value is int && (value == 0 || value == 1)
              : value is int;
          if (!valid) throw const FormatException('Invalid backup value type');
          if (type == DriftSqlType.dateTime &&
              (value as int).abs() > 8640000000000) {
            throw const FormatException('Invalid timestamp');
          }
        }
      }
    }
    return tables;
  }

  /// All deletion/insertion happens in one transaction, including FK validation.
  /// Names come exclusively from generated schema, never from imported SQL.
  Future<void> restore(String text) async {
    final tables = validate(text);
    await database.transaction(() async {
      for (final table in database.allTables.toList().reversed) {
        await database.customStatement(
          'DELETE FROM "${table.actualTableName}"',
        );
      }
      for (final table in database.allTables) {
        final columns = table.$columns.map((c) => c.name).toList();
        for (final row in tables[table.actualTableName] as List) {
          await database.customStatement(
            'INSERT INTO "${table.actualTableName}" (${columns.map((c) => '"$c"').join(',')}) VALUES (${List.filled(columns.length, '?').join(',')})',
            columns.map((c) => row[c] as Object?).toList(),
          );
        }
      }
      if ((await database.customSelect('PRAGMA foreign_key_check').get())
          .isNotEmpty) {
        throw const FormatException('Broken backup references');
      }
      // Validate nested snapshots/settings before committing a replacement.
      for (final row in await database.select(database.appSettings).get()) {
        if (row.keyName.startsWith('fitness.draft.')) {
          final draft = jsonDecode(row.value);
          if (draft is! List) {
            throw const FormatException('Invalid workout draft');
          }
          for (final exercise in draft) {
            if (exercise is! Map ||
                exercise['name'] is! String ||
                exercise['preset'] is! bool ||
                exercise['sets'] is! List) {
              throw const FormatException('Invalid draft exercise');
            }
            for (final set in exercise['sets'] as List) {
              if (set is! Map ||
                  set['weight'] is! String ||
                  set['reps'] is! String ||
                  set['rir'] is! String ||
                  set['zero'] is! bool) {
                throw const FormatException('Invalid draft set');
              }
            }
          }
        } else if (row.keyName.startsWith('fitness.cycle.start.') ||
            row.keyName == 'fitness.pr.tracked') {
          final list = jsonDecode(row.value);
          if (list is! List || list.any((v) => v is! String)) {
            throw const FormatException('Invalid cycle/PR settings');
          }
        } else if (row.keyName == 'nutrition.extraTargets') {
          final targets = jsonDecode(row.value) as Map<String, dynamic>;
          for (final e in targets.entries) {
            final value = e.value as Map;
            if (!extraNutrientUnits.containsKey(e.key) ||
                value['value'] is! num ||
                !(value['value'] as num).isFinite ||
                (value['value'] as num) <= 0 ||
                !['goal', 'minimum', 'limit'].contains(value['mode'])) {
              throw const FormatException('Invalid nutrient target');
            }
          }
        } else if (row.keyName == 'fitness.undo.today') {
          final undo = jsonDecode(row.value) as Map<String, dynamic>;
          CycleInstance.fromJson(Map<String, dynamic>.from(undo['cycle']));
          CycleDayExecution.fromJson(
            Map<String, dynamic>.from(undo['execution']),
          );
          if (undo['session'] != null) {
            WorkoutSession.fromJson(Map<String, dynamic>.from(undo['session']));
          }
          for (final entry in undo['exercises'] as List) {
            WorkoutExercise.fromJson(
              Map<String, dynamic>.from(entry['exercise']),
            );
            for (final set in entry['sets'] as List) {
              WorkoutSet.fromJson(Map<String, dynamic>.from(set));
            }
          }
        }
      }
      for (final row in await database.select(database.foodLogEntries).get()) {
        MealIngredient.decode(row.mealItemsJson);
        validateNutrients(decodeNutrients(row.extraNutrientsJson));
      }
      for (final row in await database.select(database.foodPresets).get()) {
        validateNutrients(decodeNutrients(row.nutrientsJson));
      }
      for (final row in await database.select(database.sleepLogs).get()) {
        final minutes = row.endedAt.difference(row.startedAt).inMinutes;
        if (minutes <= 0 || minutes > 2880) {
          throw const FormatException('Invalid sleep interval');
        }
      }
    });
  }
}
