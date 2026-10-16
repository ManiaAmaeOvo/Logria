import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/core/workout_set_values.dart';

void main() {
  test(
    'schema 6 numeric RIR and set notes survive additive schema 7 migration',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (sqlite) {
            sqlite.execute(
              'CREATE TABLE workout_sets (id TEXT PRIMARY KEY, workout_exercise_id TEXT NOT NULL, set_number INTEGER NOT NULL, set_type TEXT NOT NULL, weight_value REAL, weight_text TEXT, weight_unit TEXT NOT NULL, reps INTEGER, rir REAL, is_completed INTEGER NOT NULL, notes TEXT)',
            );
            sqlite.execute(
              "INSERT INTO workout_sets VALUES ('old-set', 'exercise', 1, 'working', 40, NULL, 'kg', 8, 2.5, 1, 'Existing feeling')",
            );
            sqlite.execute(
              'CREATE TABLE food_log_entries (id TEXT PRIMARY KEY)',
            );
            sqlite.execute("INSERT INTO food_log_entries VALUES ('old-meal')");
            sqlite.execute('PRAGMA user_version = 6');
          },
        ),
      );
      addTearDown(db.close);
      final set = await db.select(db.workoutSets).getSingle();
      expect(set.rir, 2.5);
      expect(set.rirText, isNull);
      expect(set.rirLabel, '2.5');
      expect(set.notes, 'Existing feeling');
      final meal = await db
          .customSelect('SELECT id, meal_items_json FROM food_log_entries')
          .getSingle();
      expect(meal.data, {'id': 'old-meal', 'meal_items_json': null});
      expect(await db.select(db.sleepLogs).get(), isEmpty);
      expect(db.schemaVersion, 7);
    },
  );
}
