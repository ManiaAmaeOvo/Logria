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
    required this.hasActionToday,
    required this.todayWorkout,
  });

  final TrainingPlan plan;
  final CycleInstance cycle;
  final List<PlanDay> planDays;
  final List<CycleDayExecution> executions;
  final TrainingCycleProgress progress;
  final bool hasActionToday;
  final WorkoutHistoryItem? todayWorkout;
}

class FitnessDayActionLockedException implements Exception {}

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

class PlanExerciseData {
  const PlanExerciseData({required this.planExercise, required this.exercise});

  final PlanDayExercise planExercise;
  final Exercise exercise;
}

class WorkoutHistoryItem {
  const WorkoutHistoryItem({
    required this.session,
    required this.exercises,
    required this.cycleNumber,
  });

  final WorkoutSession session;
  final List<WorkoutHistoryExercise> exercises;
  final int? cycleNumber;
}

class WorkoutHistoryExercise {
  const WorkoutHistoryExercise({required this.exercise, required this.sets});

  final WorkoutExercise exercise;
  final List<WorkoutSet> sets;
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
    final todayWorkout = await _loadTodayWorkout();

    return FitnessDashboardData(
      plan: plan,
      cycle: cycle,
      planDays: planDays,
      executions: executions,
      progress: progress,
      hasActionToday: await _hasFitnessActionOnDate(DateTime.now()),
      todayWorkout: todayWorkout,
    );
  }

  Future<void> activateTemplate(
    TrainingPlanTemplate template, {
    String? planName,
    List<String>? dayNames,
  }) async {
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
              name: planName ?? template.name,
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
                name: dayNames == null ? day.name : dayNames[index],
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

  Future<String> createExercisePreset(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Exercise name is required.');
    final normalized = _normalizeExerciseName(trimmed);
    final existing = await (database.select(
      database.exercises,
    )..where((row) => row.normalizedName.equals(normalized))).getSingleOrNull();
    if (existing != null) return existing.id;
    final now = DateTime.now();
    final id = _uuid.v4();
    await database
        .into(database.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: id,
            name: trimmed,
            normalizedName: normalized,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<Map<String, List<PlanExerciseData>>> loadPlanExercises(
    List<PlanDay> days,
  ) async {
    final result = <String, List<PlanExerciseData>>{};
    for (final day in days) {
      final query = database.select(database.planDayExercises).join([
        innerJoin(
          database.exercises,
          database.exercises.id.equalsExp(database.planDayExercises.exerciseId),
        ),
      ])..where(database.planDayExercises.planDayId.equals(day.id));
      query.orderBy([OrderingTerm.asc(database.planDayExercises.position)]);
      result[day.id] = [
        for (final row in await query.get())
          PlanExerciseData(
            planExercise: row.readTable(database.planDayExercises),
            exercise: row.readTable(database.exercises),
          ),
      ];
    }
    return result;
  }

  Future<void> renameActivePlan(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Plan name is required.');
    final dashboard = await _requiredDashboard();
    await (database.update(
      database.trainingPlans,
    )..where((row) => row.id.equals(dashboard.plan.id))).write(
      TrainingPlansCompanion(
        name: Value(trimmed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updatePlanDayName(String dayId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Training day name is required.');
    await (database.update(database.planDays)
          ..where((row) => row.id.equals(dayId)))
        .write(PlanDaysCompanion(name: Value(trimmed)));
  }

  Future<void> reorderPlanDays(List<String> dayIds) async {
    await database.transaction(() async {
      for (var index = 0; index < dayIds.length; index++) {
        await (database.update(database.planDays)
              ..where((row) => row.id.equals(dayIds[index])))
            .write(PlanDaysCompanion(position: Value(10000 + index)));
      }
      for (var index = 0; index < dayIds.length; index++) {
        await (database.update(database.planDays)
              ..where((row) => row.id.equals(dayIds[index])))
            .write(PlanDaysCompanion(position: Value(index)));
      }
    });
  }

  Future<String> addPlanDay({
    required String name,
    required CycleDayType type,
  }) async {
    final dashboard = await _requiredDashboard();
    final position = dashboard.planDays.length;
    final id = _uuid.v4();
    await database
        .into(database.planDays)
        .insert(
          PlanDaysCompanion.insert(
            id: id,
            planId: dashboard.plan.id,
            name: name.trim(),
            position: position,
            dayType: type.name,
          ),
        );
    return id;
  }

  Future<bool> removePlanDay(String dayId) async {
    final sessions = await (database.select(
      database.workoutSessions,
    )..where((row) => row.planDayId.equals(dayId))).get();
    final executions = await (database.select(
      database.cycleDayExecutions,
    )..where((row) => row.planDayId.equals(dayId))).get();
    if (sessions.isNotEmpty || executions.isNotEmpty) return false;
    await (database.delete(
      database.planDayExercises,
    )..where((row) => row.planDayId.equals(dayId))).go();
    await (database.delete(
      database.planDays,
    )..where((row) => row.id.equals(dayId))).go();
    return true;
  }

  Future<void> addPlanExercise({
    required String planDayId,
    required String exerciseId,
    required int targetSets,
    required int targetRepsMin,
    required int targetRepsMax,
    double? targetWeight,
  }) async {
    final count =
        await (database.selectOnly(database.planDayExercises)
              ..addColumns([database.planDayExercises.id.count()])
              ..where(database.planDayExercises.planDayId.equals(planDayId)))
            .map((row) => row.read(database.planDayExercises.id.count()) ?? 0)
            .getSingle();
    await database
        .into(database.planDayExercises)
        .insert(
          PlanDayExercisesCompanion.insert(
            id: _uuid.v4(),
            planDayId: planDayId,
            exerciseId: exerciseId,
            position: count,
            targetSets: Value(targetSets),
            targetRepsMin: Value(targetRepsMin),
            targetRepsMax: Value(targetRepsMax),
            targetWeight: Value(targetWeight),
          ),
        );
  }

  Future<void> updatePlanExerciseTargets({
    required String id,
    required int targetSets,
    required int targetRepsMin,
    required int targetRepsMax,
    double? targetWeight,
  }) async {
    await (database.update(
      database.planDayExercises,
    )..where((row) => row.id.equals(id))).write(
      PlanDayExercisesCompanion(
        targetSets: Value(targetSets),
        targetRepsMin: Value(targetRepsMin),
        targetRepsMax: Value(targetRepsMax),
        targetWeight: Value(targetWeight),
      ),
    );
  }

  Future<void> removePlanExercise(String id) async {
    await (database.delete(
      database.planDayExercises,
    )..where((row) => row.id.equals(id))).go();
  }

  Future<List<WorkoutHistoryItem>> listWorkoutHistory({int limit = 100}) async {
    final query = database.select(database.workoutSessions)
      ..where((row) => row.status.equals('completed'))
      ..orderBy([(row) => OrderingTerm.desc(row.startedAt)])
      ..limit(limit);
    final sessions = await query.get();
    final result = <WorkoutHistoryItem>[];
    for (final session in sessions) {
      final cycleNumber = session.cycleInstanceId == null
          ? null
          : await (database.select(database.cycleInstances)
                  ..where((row) => row.id.equals(session.cycleInstanceId!)))
                .map((row) => row.cycleNumber)
                .getSingleOrNull();
      result.add(await _loadHistoryItem(session, cycleNumber: cycleNumber));
    }
    return result;
  }

  Future<List<WorkoutHistoryItem>> workoutsOnDate(DateTime date) async {
    final sessions =
        await (database.select(database.workoutSessions)
              ..where(
                (row) =>
                    row.localDate.equals(
                      DateFormat('yyyy-MM-dd').format(date),
                    ) &
                    row.status.equals('completed'),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.startedAt)]))
            .get();
    final result = <WorkoutHistoryItem>[];
    for (final session in sessions) {
      final cycleNumber = session.cycleInstanceId == null
          ? null
          : await (database.select(database.cycleInstances)
                  ..where((row) => row.id.equals(session.cycleInstanceId!)))
                .map((row) => row.cycleNumber)
                .getSingleOrNull();
      result.add(await _loadHistoryItem(session, cycleNumber: cycleNumber));
    }
    return result;
  }

  Future<WorkoutHistoryItem?> previousSessionForDay({
    required String planDayId,
    required int beforeCycleNumber,
  }) async {
    final sessionsQuery = database.select(database.workoutSessions)
      ..where(
        (row) =>
            row.planDayId.equals(planDayId) & row.status.equals('completed'),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]);
    for (final session in await sessionsQuery.get()) {
      if (session.cycleInstanceId == null) continue;
      final cycleNumber =
          await (database.select(database.cycleInstances)
                ..where((row) => row.id.equals(session.cycleInstanceId!)))
              .map((row) => row.cycleNumber)
              .getSingleOrNull();
      if (cycleNumber != null && cycleNumber < beforeCycleNumber) {
        return _loadHistoryItem(session, cycleNumber: cycleNumber);
      }
    }
    return null;
  }

  Future<WorkoutHistoryItem> _loadHistoryItem(
    WorkoutSession session, {
    int? cycleNumber,
  }) async {
    final exercisesQuery = database.select(database.workoutExercises)
      ..where((row) => row.workoutSessionId.equals(session.id))
      ..orderBy([(row) => OrderingTerm.asc(row.position)]);
    final exercises = await exercisesQuery.get();
    final detail = <WorkoutHistoryExercise>[];
    for (final exercise in exercises) {
      final setsQuery = database.select(database.workoutSets)
        ..where((row) => row.workoutExerciseId.equals(exercise.id))
        ..orderBy([(row) => OrderingTerm.asc(row.setNumber)]);
      detail.add(
        WorkoutHistoryExercise(exercise: exercise, sets: await setsQuery.get()),
      );
    }
    return WorkoutHistoryItem(
      session: session,
      exercises: detail,
      cycleNumber: cycleNumber,
    );
  }

  Future<WorkoutHistoryItem?> _loadTodayWorkout() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final session =
        await (database.select(database.workoutSessions)
              ..where(
                (row) =>
                    row.localDate.equals(today) &
                    row.status.equals('completed'),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.startedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (session == null) return null;

    final cycleNumber = session.cycleInstanceId == null
        ? null
        : await (database.select(database.cycleInstances)
                ..where((row) => row.id.equals(session.cycleInstanceId!)))
              .map((row) => row.cycleNumber)
              .getSingleOrNull();
    return _loadHistoryItem(session, cycleNumber: cycleNumber);
  }

  Future<CycleExecutionType> takeRest() async {
    final dashboard = await _requiredDashboard();
    final transition = dashboard.progress.takeRest(DateTime.now());
    await database.transaction(() async {
      await _ensureNoFitnessActionToday();
      await _persistTransition(dashboard, transition);
    });
    return transition.execution.type;
  }

  Future<void> skipCurrentTraining() async {
    final dashboard = await _requiredDashboard();
    final transition = dashboard.progress.skipCurrentTraining(DateTime.now());
    await database.transaction(() async {
      await _ensureNoFitnessActionToday();
      await _persistTransition(dashboard, transition);
    });
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
      await _ensureNoFitnessActionToday();
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

      await _insertWorkoutExercises(sessionId, exercises, now);

      final transition = dashboard.progress.completeCurrent(now);
      await _persistTransition(dashboard, transition);
    });
  }

  Future<void> updateWorkoutSession(
    String sessionId,
    List<WorkoutDraftExercise> exercises,
  ) async {
    if (exercises.isEmpty) {
      throw ArgumentError('A workout must contain at least one exercise.');
    }
    final now = DateTime.now();
    await database.transaction(() async {
      final session = await (database.select(
        database.workoutSessions,
      )..where((row) => row.id.equals(sessionId))).getSingleOrNull();
      if (session == null || session.status != 'completed') {
        throw StateError('The workout session is no longer available.');
      }
      await (database.delete(
        database.workoutExercises,
      )..where((row) => row.workoutSessionId.equals(sessionId))).go();
      await _insertWorkoutExercises(sessionId, exercises, now);
    });
  }

  Future<void> _insertWorkoutExercises(
    String sessionId,
    List<WorkoutDraftExercise> exercises,
    DateTime now,
  ) async {
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
  }

  Future<bool> undoLatestFitnessActionToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return database.transaction(() async {
      final execution =
          await (database.select(database.cycleDayExecutions)
                ..where(
                  (row) =>
                      row.occurredAt.isBiggerOrEqualValue(start) &
                      row.occurredAt.isSmallerThanValue(end),
                )
                ..orderBy([(row) => OrderingTerm.desc(row.occurredAt)])
                ..limit(1))
              .getSingleOrNull();
      if (execution == null) return false;

      final session =
          await (database.select(database.workoutSessions)..where(
                (row) =>
                    row.cycleInstanceId.equals(execution.cycleInstanceId) &
                    row.startedAt.equals(execution.occurredAt),
              ))
              .getSingleOrNull();

      final cycle =
          await (database.select(database.cycleInstances)
                ..where((row) => row.id.equals(execution.cycleInstanceId)))
              .getSingleOrNull();
      if (cycle != null &&
          cycle.status == 'completed' &&
          cycle.completedAt == execution.occurredAt) {
        final nextCycle =
            await (database.select(database.cycleInstances)..where(
                  (row) =>
                      row.planId.equals(cycle.planId) &
                      row.cycleNumber.equals(cycle.cycleNumber + 1),
                ))
                .getSingleOrNull();
        if (nextCycle != null) {
          final hasNextCycleExecution = await (database.select(
            database.cycleDayExecutions,
          )..where((row) => row.cycleInstanceId.equals(nextCycle.id))).get();
          final hasNextCycleWorkout = await (database.select(
            database.workoutSessions,
          )..where((row) => row.cycleInstanceId.equals(nextCycle.id))).get();
          if (hasNextCycleExecution.isNotEmpty ||
              hasNextCycleWorkout.isNotEmpty) {
            throw StateError(
              'Cannot undo because the next cycle already has activity.',
            );
          }
          await (database.delete(
            database.cycleInstances,
          )..where((row) => row.id.equals(nextCycle.id))).go();
        }
        await (database.update(
          database.cycleInstances,
        )..where((row) => row.id.equals(cycle.id))).write(
          const CycleInstancesCompanion(
            status: Value('active'),
            completedAt: Value(null),
          ),
        );
      }

      if (session != null) {
        await (database.delete(
          database.workoutSessions,
        )..where((row) => row.id.equals(session.id))).go();
      }
      await (database.delete(
        database.cycleDayExecutions,
      )..where((row) => row.id.equals(execution.id))).go();
      return true;
    });
  }

  Future<void> _ensureNoFitnessActionToday() async {
    if (await _hasFitnessActionOnDate(DateTime.now())) {
      throw FitnessDayActionLockedException();
    }
  }

  Future<bool> _hasFitnessActionOnDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final execution =
        await (database.select(database.cycleDayExecutions)
              ..where(
                (row) =>
                    row.occurredAt.isBiggerOrEqualValue(start) &
                    row.occurredAt.isSmallerThanValue(end),
              )
              ..limit(1))
            .getSingleOrNull();
    if (execution != null) return true;

    final session =
        await (database.select(database.workoutSessions)
              ..where(
                (row) =>
                    row.localDate.equals(DateFormat('yyyy-MM-dd').format(date)),
              )
              ..limit(1))
            .getSingleOrNull();
    return session != null;
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
