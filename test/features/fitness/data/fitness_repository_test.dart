import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_cycle.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';

void main() {
  late AppDatabase database;
  late FitnessRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = FitnessRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('activating a template creates the first cycle', () async {
    await repository.activateTemplate(builtInTrainingPlanTemplates.first);

    final dashboard = await repository.loadDashboard();

    expect(dashboard, isNotNull);
    expect(dashboard!.plan.name, 'PPL');
    expect(dashboard.cycle.cycleNumber, 1);
    expect(dashboard.planDays.map((day) => day.name), [
      'push',
      'pull',
      'legs',
      'rest',
    ]);
    expect(dashboard.progress.nextDay?.name, 'push');
  });

  test('taking rest early consumes the planned rest slot', () async {
    await repository.activateTemplate(builtInTrainingPlanTemplates.first);
    await repository.takeRest();

    final dashboard = await repository.loadDashboard();

    expect(dashboard!.progress.nextDay?.name, 'push');
    expect(dashboard.progress.consumedDayIds, hasLength(1));
    expect(
      dashboard.executions.single.executionType,
      CycleExecutionType.movedRest.name,
    );
  });

  test('saving a workout advances the cycle and creates a preset', () async {
    await repository.activateTemplate(builtInTrainingPlanTemplates.first);
    final dashboard = (await repository.loadDashboard())!;

    await repository.completeWorkout(dashboard, const [
      WorkoutDraftExercise(
        name: '平板卧推',
        saveAsPreset: true,
        sets: [WorkoutDraftSet(weight: 80, reps: 8, rir: 2)],
      ),
    ]);

    final updated = await repository.loadDashboard();
    final sessions = await database.select(database.workoutSessions).get();
    final exercises = await database.select(database.exercises).get();
    final sets = await database.select(database.workoutSets).get();

    expect(updated!.progress.nextDay?.name, 'pull');
    expect(sessions.single.dayNameSnapshot, 'push');
    expect(exercises.single.name, '平板卧推');
    expect(sets.single.weightValue, 80);
    expect(sets.single.reps, 8);
    expect(sets.single.rir, 2);
  });

  test('one-off exercise is retained only as a workout snapshot', () async {
    await repository.activateTemplate(builtInTrainingPlanTemplates.first);
    final dashboard = (await repository.loadDashboard())!;

    await repository.completeWorkout(dashboard, const [
      WorkoutDraftExercise(
        name: '临时动作',
        saveAsPreset: false,
        sets: [WorkoutDraftSet(weight: 10, reps: 12, rir: 3)],
      ),
    ]);

    final presets = await database.select(database.exercises).get();
    final logged = await database.select(database.workoutExercises).getSingle();

    expect(presets, isEmpty);
    expect(logged.exerciseId, isNull);
    expect(logged.exerciseNameSnapshot, '临时动作');
  });
}
