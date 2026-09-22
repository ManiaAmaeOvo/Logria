import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/training_cycle.dart';
import '../domain/training_plan_template.dart';

class FitnessDashboardData {
  const FitnessDashboardData({
    required this.plan,
    required this.cycle,
    required this.planDays,
    required this.executions,
    required this.progress,
  });

  final TrainingPlan plan;
  final CycleInstance cycle;
  final List<PlanDay> planDays;
  final List<CycleDayExecution> executions;
  final TrainingCycleProgress progress;
}

class WorkoutDraftExercise {
  const WorkoutDraftExercise({
    required this.name,
    required this.saveAsPreset,
    required this.sets,
  });

  final String name;
  final bool saveAsPreset;
  final List<WorkoutDraftSet> sets;
}

class WorkoutDraftSet {
  const WorkoutDraftSet({
    required this.weight,
    required this.reps,
    required this.rir,
  });

  final double weight;
  final int reps;
  final double rir;
}

class FitnessRepository {
  FitnessRepository(this.database);

  final AppDatabase database;
  final Uuid _uuid = const Uuid();

  static const _cycleColors = <int>[
    0xFF5B8C85,
    0xFFB56D4B,
    0xFF6C7BA8,
    0xFF9A6B8F,
    0xFF8A874F,
  ];

  Future<FitnessDashboardData?> loadDashboard() async {
    final planQuery = database.select(database.trainingPlans)
      ..where((row) => row.isActive.equals(true) & row.isArchived.equals(false))
      ..limit(1);
    final plan = await planQuery.getSingleOrNull();
    if (plan == null) return null;

    final cycleQuery = database.select(database.cycleInstances)
      ..where((row) => row.planId.equals(plan.id) & row.status.equals('active'))
      ..orderBy([(row) => OrderingTerm.desc(row.cycleNumber)])
      ..limit(1);
    var cycle = await cycleQuery.getSingleOrNull();
    cycle ??= await _createCycle(plan.id, 1, DateTime.now());

    final daysQuery = database.select(database.planDays)
      ..where((row) => row.planId.equals(plan.id))
      ..orderBy([(row) => OrderingTerm.asc(row.position)]);
    final planDays = await daysQuery.get();

    final executionsQuery = database.select(database.cycleDayExecutions)
      ..where((row) => row.cycleInstanceId.equals(cycle!.id))
      ..orderBy([(row) => OrderingTerm.asc(row.occurredAt)]);
    final executions = await executionsQuery.get();
    final consumedIds = executions
        .map((execution) => execution.planDayId)
        .whereType<String>()
        .toSet();
    final progress = TrainingCycleProgress(
      cycleNumber: cycle.cycleNumber,
      days: [
        for (final day in planDays)
          CycleDayDefinition(
            id: day.id,
            name: day.name,
            position: day.position,
            type: CycleDayType.values.byName(day.dayType),
          ),
      ],
      consumedDayIds: consumedIds,
    );

    return FitnessDashboardData(
      plan: plan,
      cycle: cycle,
      planDays: planDays,
      executions: executions,
      progress: progress,
    );
  }

  Future<void> activateTemplate(TrainingPlanTemplate template) async {
    final now = DateTime.now();
    final planId = _uuid.v4();

    await database.transaction(() async {
      await database
          .update(database.trainingPlans)
          .write(
            TrainingPlansCompanion(
              isActive: const Value(false),
              updatedAt: Value(now),
            ),
          );
      await database
          .into(database.trainingPlans)
          .insert(
            TrainingPlansCompanion.insert(
              id: planId,
              name: template.name,
              notes: Value('built_in_template:${template.id}'),
              isActive: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );
      for (var index = 0; index < template.days.length; index++) {
        final day = template.days[index];
        await database
            .into(database.planDays)
            .insert(
              PlanDaysCompanion.insert(
                id: _uuid.v4(),
                planId: planId,
                name: day.name,
                position: index,
                dayType: day.type.name,
              ),
            );
      }
      await _createCycle(planId, 1, now);
    });
  }

  Future<List<Exercise>> listExercises() {
    final query = database.select(database.exercises)
      ..where((row) => row.isArchived.equals(false))
      ..orderBy([(row) => OrderingTerm.asc(row.name)]);
    return query.get();
  }

  Future<CycleExecutionType> takeRest() async {
    final dashboard = await _requiredDashboard();
    final transition = dashboard.progress.takeRest(DateTime.now());
    await database.transaction(() => _persistTransition(dashboard, transition));
    return transition.execution.type;
  }

  Future<void> skipCurrentTraining() async {
    final dashboard = await _requiredDashboard();
    final transition = dashboard.progress.skipCurrentTraining(DateTime.now());
    await database.transaction(() => _persistTransition(dashboard, transition));
  }

  Future<void> completeWorkout(
    FitnessDashboardData dashboard,
    List<WorkoutDraftExercise> exercises,
  ) async {
    if (dashboard.progress.nextDay?.type != CycleDayType.training) {
      throw StateError('The current cycle day is not a training day.');
    }
    if (exercises.isEmpty) {
      throw ArgumentError('A workout must contain at least one exercise.');
    }

    final now = DateTime.now();
    final sessionId = _uuid.v4();
    final currentDay = dashboard.progress.nextDay!;

    await database.transaction(() async {
      await database
          .into(database.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              id: sessionId,
              localDate: DateFormat('yyyy-MM-dd').format(now),
              cycleInstanceId: Value(dashboard.cycle.id),
              planDayId: Value(currentDay.id),
              planNameSnapshot: Value(dashboard.plan.name),
              dayNameSnapshot: Value(currentDay.name),
              status: 'completed',
              startedAt: now,
              completedAt: Value(now),
            ),
          );

      for (
        var exerciseIndex = 0;
        exerciseIndex < exercises.length;
        exerciseIndex++
      ) {
        final draft = exercises[exerciseIndex];
        final normalizedName = _normalizeExerciseName(draft.name);
        final existingQuery = database.select(database.exercises)
          ..where((row) => row.normalizedName.equals(normalizedName))
          ..limit(1);
        final existing = await existingQuery.getSingleOrNull();
        String? exerciseId = existing?.id;
        if (exerciseId == null && draft.saveAsPreset) {
          exerciseId = _uuid.v4();
          await database
              .into(database.exercises)
              .insert(
                ExercisesCompanion.insert(
                  id: exerciseId,
                  name: draft.name.trim(),
                  normalizedName: normalizedName,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }

        final workoutExerciseId = _uuid.v4();
        await database
            .into(database.workoutExercises)
            .insert(
              WorkoutExercisesCompanion.insert(
                id: workoutExerciseId,
                workoutSessionId: sessionId,
                exerciseId: Value(exerciseId),
                exerciseNameSnapshot: draft.name.trim(),
                position: exerciseIndex,
              ),
            );
        for (var setIndex = 0; setIndex < draft.sets.length; setIndex++) {
          final set = draft.sets[setIndex];
          await database
              .into(database.workoutSets)
              .insert(
                WorkoutSetsCompanion.insert(
                  id: _uuid.v4(),
                  workoutExerciseId: workoutExerciseId,
                  setNumber: setIndex + 1,
                  weightValue: Value(set.weight),
                  reps: Value(set.reps),
                  rir: Value(set.rir),
                  isCompleted: const Value(true),
                ),
              );
        }
      }

      final transition = dashboard.progress.completeCurrent(now);
      await _persistTransition(dashboard, transition);
    });
  }

  Future<FitnessDashboardData> _requiredDashboard() async {
    final dashboard = await loadDashboard();
    if (dashboard == null) throw StateError('No active training plan.');
    return dashboard;
  }

  Future<void> _persistTransition(
    FitnessDashboardData dashboard,
    CycleTransition transition,
  ) async {
    await database
        .into(database.cycleDayExecutions)
        .insert(
          CycleDayExecutionsCompanion.insert(
            id: _uuid.v4(),
            cycleInstanceId: dashboard.cycle.id,
            planDayId: Value(transition.execution.planDayId),
            executionType: transition.execution.type.name,
            originalPosition: Value(transition.execution.originalPosition),
            occurredAt: transition.execution.occurredAt,
          ),
        );

    if (transition.progress.isComplete) {
      await (database.update(
        database.cycleInstances,
      )..where((row) => row.id.equals(dashboard.cycle.id))).write(
        CycleInstancesCompanion(
          status: const Value('completed'),
          completedAt: Value(transition.execution.occurredAt),
        ),
      );
      await _createCycle(
        dashboard.plan.id,
        dashboard.cycle.cycleNumber + 1,
        transition.execution.occurredAt,
      );
    }
  }

  Future<CycleInstance> _createCycle(
    String planId,
    int cycleNumber,
    DateTime startedAt,
  ) async {
    final id = _uuid.v4();
    final colorValue = _cycleColors[(cycleNumber - 1) % _cycleColors.length];
    await database
        .into(database.cycleInstances)
        .insert(
          CycleInstancesCompanion.insert(
            id: id,
            planId: planId,
            cycleNumber: cycleNumber,
            colorValue: colorValue,
            status: 'active',
            startedAt: startedAt,
          ),
        );
    return CycleInstance(
      id: id,
      planId: planId,
      cycleNumber: cycleNumber,
      colorValue: colorValue,
      status: 'active',
      startedAt: startedAt,
      completedAt: null,
    );
  }

  String _normalizeExerciseName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
