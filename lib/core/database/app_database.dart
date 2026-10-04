import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  TextColumn get primaryMuscleGroup => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(true))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {normalizedName},
  ];
}

class TrainingPlans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PlanDays extends Table {
  TextColumn get id => text()();
  TextColumn get planId =>
      text().references(TrainingPlans, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get position => integer()();
  TextColumn get dayType => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {planId, position},
  ];
}

class PlanDayExercises extends Table {
  TextColumn get id => text()();
  TextColumn get planDayId =>
      text().references(PlanDays, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get position => integer()();
  IntColumn get targetSets => integer().nullable()();
  IntColumn get targetRepsMin => integer().nullable()();
  IntColumn get targetRepsMax => integer().nullable()();
  RealColumn get targetWeight => real().nullable()();
  IntColumn get restSeconds => integer().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {planDayId, position},
  ];
}

class CycleInstances extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text().references(TrainingPlans, #id)();
  IntColumn get cycleNumber => integer()();
  IntColumn get colorValue => integer()();
  TextColumn get status => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {planId, cycleNumber},
  ];
}

class CycleDayExecutions extends Table {
  TextColumn get id => text()();
  TextColumn get cycleInstanceId =>
      text().references(CycleInstances, #id, onDelete: KeyAction.cascade)();
  TextColumn get planDayId => text().nullable().references(PlanDays, #id)();
  TextColumn get executionType => text()();
  IntColumn get originalPosition => integer().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get localDate => text()();
  TextColumn get cycleInstanceId =>
      text().nullable().references(CycleInstances, #id)();
  TextColumn get planDayId => text().nullable().references(PlanDays, #id)();
  TextColumn get planNameSnapshot => text().nullable()();
  TextColumn get dayNameSnapshot => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WorkoutExercises extends Table {
  TextColumn get id => text()();
  TextColumn get workoutSessionId =>
      text().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().nullable().references(Exercises, #id)();
  TextColumn get exerciseNameSnapshot => text()();
  IntColumn get position => integer()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {workoutSessionId, position},
  ];
}

class WorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutExerciseId =>
      text().references(WorkoutExercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get setNumber => integer()();
  TextColumn get setType => text().withDefault(const Constant('working'))();
  RealColumn get weightValue => real().nullable()();
  TextColumn get weightUnit => text().withDefault(const Constant('kg'))();
  IntColumn get reps => integer().nullable()();
  RealColumn get rir => real().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {workoutExerciseId, setNumber},
  ];
}

class FoodLogEntries extends Table {
  RealColumn get proteinGrams => real().nullable()();
  RealColumn get carbohydrateGrams => real().nullable()();
  RealColumn get fatGrams => real().nullable()();
  RealColumn get caloriesKcal => real().nullable()();
  BoolColumn get caloriesEstimated =>
      boolean().withDefault(const Constant(true))();
  TextColumn get id => text()();
  TextColumn get localDate => text()();
  TextColumn get textContent => text()();
  DateTimeColumn get occurredAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DailyNutritionRecords extends Table {
  TextColumn get id => text()();
  TextColumn get localDate => text().unique()();
  RealColumn get proteinGrams => real().nullable()();
  RealColumn get carbohydrateGrams => real().nullable()();
  RealColumn get fatGrams => real().nullable()();
  RealColumn get caloriesKcal => real().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BodyMeasurementTypes extends Table {
  TextColumn get id => text()();
  TextColumn get keyName => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get defaultUnit => text()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BodyMeasurements extends Table {
  TextColumn get id => text()();
  TextColumn get measurementTypeId =>
      text().references(BodyMeasurementTypes, #id)();
  TextColumn get localDate => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get keyName => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {keyName};
}

@DriftDatabase(
  tables: [
    Exercises,
    TrainingPlans,
    PlanDays,
    PlanDayExercises,
    CycleInstances,
    CycleDayExecutions,
    WorkoutSessions,
    WorkoutExercises,
    WorkoutSets,
    FoodLogEntries,
    DailyNutritionRecords,
    BodyMeasurementTypes,
    BodyMeasurements,
    AppSettings,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'logria'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(foodLogEntries, foodLogEntries.proteinGrams);
        await m.addColumn(foodLogEntries, foodLogEntries.carbohydrateGrams);
        await m.addColumn(foodLogEntries, foodLogEntries.fatGrams);
        await m.addColumn(foodLogEntries, foodLogEntries.caloriesKcal);
        await m.addColumn(foodLogEntries, foodLogEntries.caloriesEstimated);
      }
    },
  );
}
