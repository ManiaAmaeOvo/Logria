import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

class NutritionTargets {
  const NutritionTargets({
    this.proteinGoalGrams,
    this.carbohydrateGoalGrams,
    this.fatGoalGrams,
    this.calorieLimitKcal,
    this.proteinIsLimit = false,
    this.carbohydrateIsLimit = false,
    this.fatIsLimit = false,
    this.caloriesIsLimit = true,
  });

  final double? proteinGoalGrams;
  final double? carbohydrateGoalGrams;
  final double? fatGoalGrams;
  final double? calorieLimitKcal;
  final bool proteinIsLimit;
  final bool carbohydrateIsLimit;
  final bool fatIsLimit;
  final bool caloriesIsLimit;
}

class NutritionDayData {
  const NutritionDayData({
    required this.localDate,
    required this.foodEntries,
    required this.record,
    required this.targets,
  });

  final String localDate;
  final List<FoodLogEntry> foodEntries;
  final DailyNutritionRecord? record;
  final NutritionTargets targets;
}

class NutritionRepository {
  NutritionRepository(this.database);

  final AppDatabase database;
  final Uuid _uuid = const Uuid();

  String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<NutritionDayData> loadDay(DateTime date) async {
    final localDate = dateKey(date);
    final entries =
        await (database.select(database.foodLogEntries)
              ..where((row) => row.localDate.equals(localDate))
              ..orderBy([
                (row) => OrderingTerm.desc(row.occurredAt),
                (row) => OrderingTerm.desc(row.createdAt),
              ]))
            .get();
    final record = await (database.select(
      database.dailyNutritionRecords,
    )..where((row) => row.localDate.equals(localDate))).getSingleOrNull();
    final settings =
        await (database.select(database.appSettings)..where(
              (row) => row.keyName.isIn([
                'nutrition.proteinGoalGrams',
                'nutrition.carbohydrateGoalGrams',
                'nutrition.fatGoalGrams',
                'nutrition.calorieLimitKcal',
                'nutrition.proteinIsLimit',
                'nutrition.carbohydrateIsLimit',
                'nutrition.fatIsLimit',
                'nutrition.caloriesIsLimit',
              ]),
            ))
            .get();
    final values = {
      for (final setting in settings) setting.keyName: setting.value,
    };

    return NutritionDayData(
      localDate: localDate,
      foodEntries: entries,
      record: record ?? _mealTotal(localDate, entries),
      targets: NutritionTargets(
        proteinIsLimit: values['nutrition.proteinIsLimit'] == '1.0',
        carbohydrateIsLimit: values['nutrition.carbohydrateIsLimit'] == '1.0',
        fatIsLimit: values['nutrition.fatIsLimit'] == '1.0',
        caloriesIsLimit: values['nutrition.caloriesIsLimit'] != '0.0',
        carbohydrateGoalGrams: double.tryParse(
          values['nutrition.carbohydrateGoalGrams'] ?? '',
        ),
        fatGoalGrams: double.tryParse(values['nutrition.fatGoalGrams'] ?? ''),
        proteinGoalGrams: double.tryParse(
          values['nutrition.proteinGoalGrams'] ?? '',
        ),
        calorieLimitKcal: double.tryParse(
          values['nutrition.calorieLimitKcal'] ?? '',
        ),
      ),
    );
  }

  Future<String> addFoodEntry(
    DateTime date,
    String text, {
    double? proteinGrams,
    double? carbohydrateGrams,
    double? fatGrams,
    double? caloriesKcal,
    bool caloriesEstimated = true,
  }) async {
    final content = text.trim();
    if (content.isEmpty) throw ArgumentError('Food note cannot be empty.');
    final now = DateTime.now();
    final id = _uuid.v4();
    await database
        .into(database.foodLogEntries)
        .insert(
          FoodLogEntriesCompanion.insert(
            proteinGrams: Value(proteinGrams),
            carbohydrateGrams: Value(carbohydrateGrams),
            fatGrams: Value(fatGrams),
            caloriesKcal: Value(caloriesKcal),
            caloriesEstimated: Value(caloriesEstimated),
            id: id,
            localDate: dateKey(date),
            textContent: content,
            occurredAt: Value(now),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> updateFoodEntry(
    String id,
    String text, {
    double? proteinGrams,
    double? carbohydrateGrams,
    double? fatGrams,
    double? caloriesKcal,
    bool caloriesEstimated = true,
  }) async {
    final content = text.trim();
    if (content.isEmpty) throw ArgumentError('Food note cannot be empty.');
    await (database.update(
      database.foodLogEntries,
    )..where((row) => row.id.equals(id))).write(
      FoodLogEntriesCompanion(
        proteinGrams: Value(proteinGrams),
        carbohydrateGrams: Value(carbohydrateGrams),
        fatGrams: Value(fatGrams),
        caloriesKcal: Value(caloriesKcal),
        caloriesEstimated: Value(caloriesEstimated),
        textContent: Value(content),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteFoodEntry(String id) async {
    await (database.delete(
      database.foodLogEntries,
    )..where((row) => row.id.equals(id))).go();
  }

  Future<void> saveDailyIntake({
    required DateTime date,
    double? proteinGrams,
    double? carbohydrateGrams,
    double? fatGrams,
    double? caloriesKcal,
  }) async {
    final localDate = dateKey(date);
    final existing = await (database.select(
      database.dailyNutritionRecords,
    )..where((row) => row.localDate.equals(localDate))).getSingleOrNull();
    final values = DailyNutritionRecordsCompanion(
      proteinGrams: Value(proteinGrams),
      carbohydrateGrams: Value(carbohydrateGrams),
      fatGrams: Value(fatGrams),
      caloriesKcal: Value(caloriesKcal),
      source: const Value('manual'),
      updatedAt: Value(DateTime.now()),
    );
    if (existing == null) {
      await database
          .into(database.dailyNutritionRecords)
          .insert(
            DailyNutritionRecordsCompanion.insert(
              id: _uuid.v4(),
              localDate: localDate,
              updatedAt: DateTime.now(),
              proteinGrams: Value(proteinGrams),
              carbohydrateGrams: Value(carbohydrateGrams),
              fatGrams: Value(fatGrams),
              caloriesKcal: Value(caloriesKcal),
            ),
          );
    } else {
      await (database.update(
        database.dailyNutritionRecords,
      )..where((row) => row.id.equals(existing.id))).write(values);
    }
  }

  Future<void> saveTargets(NutritionTargets targets) async {
    final now = DateTime.now();
    await database.transaction(() async {
      await _saveSetting(
        'nutrition.proteinIsLimit',
        targets.proteinIsLimit ? 1 : 0,
        now,
      );
      await _saveSetting(
        'nutrition.carbohydrateIsLimit',
        targets.carbohydrateIsLimit ? 1 : 0,
        now,
      );
      await _saveSetting(
        'nutrition.fatIsLimit',
        targets.fatIsLimit ? 1 : 0,
        now,
      );
      await _saveSetting(
        'nutrition.caloriesIsLimit',
        targets.caloriesIsLimit ? 1 : 0,
        now,
      );
      await _saveSetting(
        'nutrition.carbohydrateGoalGrams',
        targets.carbohydrateGoalGrams,
        now,
      );
      await _saveSetting('nutrition.fatGoalGrams', targets.fatGoalGrams, now);
      await _saveSetting(
        'nutrition.proteinGoalGrams',
        targets.proteinGoalGrams,
        now,
      );
      await _saveSetting(
        'nutrition.calorieLimitKcal',
        targets.calorieLimitKcal,
        now,
      );
    });
  }

  Future<void> useMealTotals(DateTime date) async {
    await (database.delete(
      database.dailyNutritionRecords,
    )..where((row) => row.localDate.equals(dateKey(date)))).go();
  }

  DailyNutritionRecord? _mealTotal(String date, List<FoodLogEntry> entries) {
    double? sum(double? Function(FoodLogEntry) read) {
      final values = entries.map(read).whereType<double>();
      return values.isEmpty ? null : values.fold<double>(0, (a, b) => a + b);
    }

    final p = sum((e) => e.proteinGrams);
    final c = sum((e) => e.carbohydrateGrams);
    final f = sum((e) => e.fatGrams);
    final kcal = sum((e) => e.caloriesKcal);
    if (p == null && c == null && f == null && kcal == null) return null;
    return DailyNutritionRecord(
      id: 'meal-total',
      localDate: date,
      proteinGrams: p,
      carbohydrateGrams: c,
      fatGrams: f,
      caloriesKcal: kcal,
      source: 'meals',
      notes: null,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveSetting(String key, double? value, DateTime now) async {
    if (value == null) {
      await (database.delete(
        database.appSettings,
      )..where((row) => row.keyName.equals(key))).go();
      return;
    }
    await database
        .into(database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            keyName: key,
            value: value.toString(),
            updatedAt: now,
          ),
        );
  }
}
