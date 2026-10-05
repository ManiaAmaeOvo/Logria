import 'dart:convert';

import '../domain/exercise_variant.dart';

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
    this.hasDraft = false,
    this.canRedo = false,
    this.canChooseStart = false,
    this.unrecordedDayIds = const {},
  });

  final TrainingPlan plan;
  final CycleInstance cycle;
  final List<PlanDay> planDays;
  final List<CycleDayExecution> executions;
  final TrainingCycleProgress progress;
  final bool hasActionToday;
  final WorkoutHistoryItem? todayWorkout;
  final bool hasDraft;
  final bool canRedo, canChooseStart;
  final Set<String> unrecordedDayIds;
}

class FitnessDayActionLockedException implements Exception {}

class WorkoutDraftExercise {
  const WorkoutDraftExercise({
    required this.name,
    required this.saveAsPreset,
    required this.sets,
    this.baseName,
    this.variantNote,
  });

  final String name;
  final bool saveAsPreset;
  final List<WorkoutDraftSet> sets;
  final String? baseName, variantNote;
}

class WorkoutDraftSet {
  const WorkoutDraftSet({
    required this.weight,
    required this.reps,
    required this.rir,
    this.weightText,
  });

  final double? weight;
  final String? weightText;
  final int? reps;
  final double? rir;
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
  static const _redoKey = 'fitness.undo.today';

  Future<String> _planSignature(String planId) async {
    final plan = await (database.select(
      database.trainingPlans,
    )..where((r) => r.id.equals(planId))).getSingle();
    final days =
        await (database.select(database.planDays)
              ..where((r) => r.planId.equals(planId))
              ..orderBy([(r) => OrderingTerm.asc(r.position)]))
            .get();
    final exercises =
        await (database.select(database.planDayExercises)
              ..where((e) => e.planDayId.isIn(days.map((d) => d.id)))
              ..orderBy([
                (e) => OrderingTerm.asc(e.planDayId),
                (e) => OrderingTerm.asc(e.position),
              ]))
            .get();
    return jsonEncode([
      plan.toJson(),
      days.map((d) => d.toJson()).toList(),
      exercises.map((e) => e.toJson()).toList(),
    ]);
  }

  Future<Map<String, dynamic>?> _availableRedo() async {
    final raw = await readSetting(_redoKey);
    if (raw == null) return null;
    final snapshot = Map<String, dynamic>.from(jsonDecode(raw));
    if (snapshot['date'] != DateFormat('yyyy-MM-dd').format(DateTime.now()) ||
        await _hasFitnessActionOnDate(DateTime.now())) {
      return null;
    }
    final planId = snapshot['planId'] as String;
    final plan =
        await (database.select(database.trainingPlans)..where(
              (p) =>
                  p.id.equals(snapshot['activePlanId'] as String) &
                  p.isActive.equals(true) &
                  p.isArchived.equals(false),
            ))
            .getSingleOrNull();
    if (plan == null ||
        await _planSignature(planId) != snapshot['planSignature'] ||
        await _planSignature(plan.id) != snapshot['activePlanSignature']) {
      return null;
    }
    final cycle =
        await (database.select(database.cycleInstances)..where(
              (c) => c.id.equals((snapshot['cycle'] as Map)['id'] as String),
            ))
            .getSingleOrNull();
    if (cycle == null || jsonEncode(cycle.toJson()) != snapshot['afterCycle']) {
      return null;
    }
    final executions = await (database.select(
      database.cycleDayExecutions,
    )..where((e) => e.cycleInstanceId.equals(cycle.id))).get();
    final ids = executions.map((e) => e.id).toList()..sort();
    if (jsonEncode(ids) != snapshot['remainingExecutions']) return null;
    return snapshot;
  }

  /// Archives interrupted progress without deleting health history.
  Future<void> restartTrainingCycle() => database.transaction(() async {
    final dashboard = await _requiredDashboard();
    await _ensureNoFitnessActionToday();
    final now = DateTime.now();
    final cycles = await (database.select(
      database.cycleInstances,
    )..where((c) => c.planId.equals(dashboard.plan.id))).get();
    final nextNumber =
        cycles.map((c) => c.cycleNumber).reduce((a, b) => a > b ? a : b) + 1;
    await (database.update(
      database.cycleInstances,
    )..where((c) => c.id.equals(dashboard.cycle.id))).write(
      CycleInstancesCompanion(
        status: const Value('interrupted'),
        completedAt: Value(now),
      ),
    );
    // Only unfinished drafts belonging to this plan are discarded.
    for (final day in dashboard.planDays) {
      await (database.delete(database.appSettings)..where(
            (s) =>
                s.keyName.like('fitness.draft.%') &
                s.keyName.like('%.${day.id}'),
          ))
          .go();
    }
    await clearSetting(_redoKey);
    await _createCycle(dashboard.plan.id, nextNumber, now);
  });

  /// Changes only this unrecorded cycle's entry point, never fabricates history.
  Future<void> chooseCycleStart(String dayId) => database.transaction(() async {
    final dashboard = await _requiredDashboard();
    await _ensureNoFitnessActionToday();
    final sessions = await (database.select(
      database.workoutSessions,
    )..where((s) => s.cycleInstanceId.equals(dashboard.cycle.id))).get();
    if (dashboard.executions.isNotEmpty ||
        sessions.isNotEmpty ||
        dashboard.hasDraft) {
      throw StateError(
        'Starting day can only change before recording this cycle.',
      );
    }
    final day = dashboard.planDays.where((d) => d.id == dayId).firstOrNull;
    if (day == null) throw ArgumentError('Unknown cycle day.');
    // Do not strand another day's draft when changing the entry point.
    for (final d in dashboard.planDays) {
      if (await readSetting(
            'fitness.draft.${DateFormat('yyyy-MM-dd').format(DateTime.now())}.${d.id}',
          ) !=
          null) {
        throw StateError(
          'Resume or finish the draft before changing the starting day.',
        );
      }
    }
    await writeSetting(
      'fitness.cycle.start.${dashboard.cycle.id}',
      jsonEncode(
        dashboard.planDays
            .where((d) => d.position < day.position)
            .map((d) => d.id)
            .toList(),
      ),
    );
    await clearSetting(_redoKey);
  });

  Future<String?> readSetting(String key) async => (await (database.select(
    database.appSettings,
  )..where((s) => s.keyName.equals(key))).getSingleOrNull())?.value;

  Future<void> writeSetting(String key, String value) => database
      .into(database.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          keyName: key,
          value: value,
          updatedAt: DateTime.now(),
        ),
      );

  Future<void> clearSetting(String key) => (database.delete(
    database.appSettings,
  )..where((s) => s.keyName.equals(key))).go();

  Future<void> ensureCommonExercises(bool chinese) async {
    const names = [
      ['平板卧推', 'Bench press'],
      ['上斜哑铃卧推', 'Incline dumbbell press'],
      ['深蹲', 'Squat'],
      ['硬拉', 'Deadlift'],
      ['罗马尼亚硬拉', 'Romanian deadlift'],
      ['高位下拉', 'Lat pulldown'],
      ['引体向上', 'Pull-up'],
      ['坐姿划船', 'Seated row'],
      ['肩上推举', 'Overhead press'],
      ['侧平举', 'Lateral raise'],
      ['二头弯举', 'Biceps curl'],
      ['绳索下压', 'Triceps pushdown'],
      ['腿举', 'Leg press'],
      ['腿弯举', 'Leg curl'],
      ['提踵', 'Calf raise'],
      ['俯卧撑', 'Push-up'],
      ['平板支撑', 'Plank'],
    ];
    final key = 'fitness.presets.${chinese ? 'zh' : 'en'}.v1';
    if (await readSetting(key) != null) return;
    await database.transaction(() async {
      for (final pair in names) {
        await createExercisePreset(pair[chinese ? 0 : 1]);
      }
      await writeSetting(key, 'seeded');
    });
  }

  Future<List<String>> trackedExercises() async =>
      ((jsonDecode(await readSetting('fitness.pr.tracked') ?? '[]')) as List)
          .cast<String>();

  Future<void> trackExercise(String name, bool enabled) async {
    final names = (await trackedExercises()).toSet();
    if (enabled) {
      names.add(name);
    } else {
      names.remove(name);
    }
    await writeSetting('fitness.pr.tracked', jsonEncode(names.toList()));
  }

  Future<List<PrPoint>> prHistory(String name) async {
    final points = <PrPoint>[];
    final query =
        database.select(database.workoutSets).join([
          innerJoin(
            database.workoutExercises,
            database.workoutExercises.id.equalsExp(
              database.workoutSets.workoutExerciseId,
            ),
          ),
          innerJoin(
            database.workoutSessions,
            database.workoutSessions.id.equalsExp(
              database.workoutExercises.workoutSessionId,
            ),
          ),
        ])..where(
          database.workoutExercises.exerciseNameSnapshot.equals(name) &
              database.workoutSessions.status.equals('completed') &
              database.workoutSets.isCompleted.equals(true),
        );
    final daily = <String, double>{};
    for (final row in await query.get()) {
      final set = row.readTable(database.workoutSets);
      final date = row.readTable(database.workoutSessions).localDate;
      final value = set.weightValue;
      if (value != null &&
          value.isFinite &&
          (daily[date] == null || value > daily[date]!)) {
        daily[date] = value;
      }
    }
    points.addAll(daily.entries.map((e) => PrPoint(e.key, e.value)));
    for (final record in await (database.select(
      database.personalRecords,
    )..where((r) => r.exerciseName.equals(name))).get()) {
      points.add(
        PrPoint(
          record.localDate,
          record.weight,
          id: record.id,
          reps: record.reps,
        ),
      );
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  Future<void> addPr(
    String name,
    DateTime date,
    double weight,
    int? reps,
  ) async {
    if (!weight.isFinite || weight < 0 || (reps != null && reps < 0)) {
      throw ArgumentError('Invalid PR');
    }
    await database
        .into(database.personalRecords)
        .insert(
          PersonalRecordsCompanion.insert(
            id: _uuid.v4(),
            exerciseName: name,
            localDate: DateFormat('yyyy-MM-dd').format(date),
            weight: weight,
            reps: Value(reps),
          ),
        );
  }

  Future<void> deletePr(String id) => (database.delete(
    database.personalRecords,
  )..where((r) => r.id.equals(id))).go();

  Future<List<CardioLog>> cardioHistory() =>
      (database.select(database.cardioLogs)..orderBy([
            (r) => OrderingTerm.desc(r.localDate),
            (r) => OrderingTerm.desc(r.recordedAt),
          ]))
          .get();

  Future<void> saveCardio({
    String? id,
    required DateTime date,
    required String activity,
    required double minutes,
    double? distance,
    String? notes,
  }) async {
    if (activity.trim().isEmpty ||
        !minutes.isFinite ||
        minutes <= 0 ||
        (distance != null && (!distance.isFinite || distance < 0))) {
      throw ArgumentError('Invalid cardio');
    }
    await database
        .into(database.cardioLogs)
        .insertOnConflictUpdate(
          CardioLogsCompanion.insert(
            id: id ?? _uuid.v4(),
            localDate: DateFormat('yyyy-MM-dd').format(date),
            activity: activity.trim(),
            minutes: minutes,
            distanceKm: Value(distance),
            notes: Value(notes),
            recordedAt: DateTime.now(),
          ),
        );
  }

  Future<void> deleteCardio(String id) => (database.delete(
    database.cardioLogs,
  )..where((r) => r.id.equals(id))).go();

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
    final knownIds = planDays.map((d) => d.id).toSet();
    final unrecordedIds = (jsonDecode(
      await readSetting('fitness.cycle.start.${cycle.id}') ?? '[]',
    ) as List).cast<String>().where(knownIds.contains).toSet();
    final consumedIds = executions
        .map((execution) => execution.planDayId)
        .whereType<String>()
        .toSet();
    consumedIds.addAll(unrecordedIds);
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
      unrecordedDayIds: unrecordedIds,
      canRedo: await _availableRedo() != null,
      canChooseStart:
          executions.isEmpty &&
          !await _hasFitnessActionOnDate(DateTime.now()) &&
          (await (database.select(
                database.workoutSessions,
              )..where((s) => s.cycleInstanceId.equals(cycle!.id))).get())
              .isEmpty &&
          await readSetting(
                'fitness.draft.${DateFormat('yyyy-MM-dd').format(DateTime.now())}.${progress.nextDay?.id}',
              ) ==
              null,
      hasDraft:
          await readSetting(
            'fitness.draft.${DateFormat('yyyy-MM-dd').format(DateTime.now())}.${todayWorkout?.session.id ?? progress.nextDay?.id}',
          ) !=
          null,
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
      await clearSetting(_redoKey);
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

  Future<void> replacePlanExercisePreset(
    String planExerciseId,
    String presetId,
  ) async {
    await (database.update(database.planDayExercises)
          ..where((e) => e.id.equals(planExerciseId)))
        .write(PlanDayExercisesCompanion(exerciseId: Value(presetId)));
  }

  Future<String> createExerciseVariant(String baseName, String note) =>
      database.transaction(() async {
        if (baseName.trim().isEmpty || note.trim().isEmpty) {
          throw ArgumentError('Base and note are required.');
        }
        final name = variantExerciseName(baseName, note);
        final existing =
            await (database.select(database.exercises)..where(
                  (e) => e.normalizedName.equals(_normalizeExerciseName(name)),
                ))
                .getSingleOrNull();
        if (existing != null) {
          final variant = exerciseVariant(existing.name, existing.notes);
          if (variant.note == null ||
              _normalizeExerciseName(variant.base) !=
                  _normalizeExerciseName(baseName) ||
              _normalizeExerciseName(variant.note!) !=
                  _normalizeExerciseName(note)) {
            throw StateError(
              'This preset name is already in use. Choose a different note.',
            );
          }
          return existing.id;
        }
        final id = _uuid.v4();
        await database
            .into(database.exercises)
            .insert(
              ExercisesCompanion.insert(
                id: id,
                name: name,
                normalizedName: _normalizeExerciseName(name),
                notes: Value(
                  jsonEncode({
                    'kind': 'variant',
                    'base': baseName.trim(),
                    'note': note.trim(),
                  }),
                ),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
        return id;
      });

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
      if (draft.variantNote != null) {
        if (draft.name !=
            variantExerciseName(
              draft.baseName ?? draft.name,
              draft.variantNote!,
            )) {
          throw ArgumentError('Variant name mismatch.');
        }
        await createExerciseVariant(
          draft.baseName ?? draft.name,
          draft.variantNote!,
        );
      }
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
              exerciseNameSnapshot: draft.variantNote == null
                  ? draft.name.trim()
                  : existing!.name,
              notes: Value(
                draft.variantNote == null
                    ? null
                    : exerciseVariant(existing!.name, existing.notes).note,
              ),
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
                weightText: Value(set.weightText),
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
      if (cycle == null) throw StateError('The original cycle is unavailable.');
      final activePlan =
          await (database.select(database.trainingPlans)
                ..where(
                  (p) => p.isActive.equals(true) & p.isArchived.equals(false),
                )
                ..limit(1))
              .getSingle();
      final snapshot = <String, dynamic>{
        'date': DateFormat('yyyy-MM-dd').format(now),
        'planId': cycle.planId,
        'planSignature': await _planSignature(cycle.planId),
        'activePlanId': activePlan.id,
        'activePlanSignature': await _planSignature(activePlan.id),
        'cycle': cycle.toJson(),
        'execution': execution.toJson(),
        'nextCycle': null,
        'session': session?.toJson(),
        'exercises': <Map<String, dynamic>>[],
      };
      if (session != null) {
        final history = await _loadHistoryItem(session);
        snapshot['exercises'] = [
          for (final item in history.exercises)
            {
              'exercise': item.exercise.toJson(),
              'sets': item.sets.map((s) => s.toJson()).toList(),
            },
        ];
      }
      if (cycle.status == 'completed' &&
          cycle.completedAt == execution.occurredAt) {
        final nextCycle =
            await (database.select(database.cycleInstances)..where(
                  (row) =>
                      row.planId.equals(cycle.planId) &
                      row.cycleNumber.equals(cycle.cycleNumber + 1),
                ))
                .getSingleOrNull();
        if (nextCycle != null) {
          snapshot['nextCycle'] = nextCycle.toJson();
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
      final afterCycle = await (database.select(
        database.cycleInstances,
      )..where((c) => c.id.equals(cycle.id))).getSingle();
      final remaining = await (database.select(
        database.cycleDayExecutions,
      )..where((e) => e.cycleInstanceId.equals(cycle.id))).get();
      final ids = remaining.map((e) => e.id).toList()..sort();
      snapshot['afterCycle'] = jsonEncode(afterCycle.toJson());
      snapshot['remainingExecutions'] = jsonEncode(ids);
      await writeSetting(_redoKey, jsonEncode(snapshot));
      return true;
    });
  }

  Future<bool> redoLatestFitnessActionToday() => database.transaction(() async {
    final snapshot = await _availableRedo();
    if (snapshot == null) return false;
    final cycle = CycleInstance.fromJson(
      Map<String, dynamic>.from(snapshot['cycle']),
    );
    await database
        .update(database.cycleInstances)
        .replace(cycle.toCompanion(false));
    if (snapshot['nextCycle'] != null) {
      await database
          .into(database.cycleInstances)
          .insert(
            CycleInstance.fromJson(
              Map<String, dynamic>.from(snapshot['nextCycle']),
            ).toCompanion(false),
          );
    }
    if (snapshot['session'] != null) {
      await database
          .into(database.workoutSessions)
          .insert(
            WorkoutSession.fromJson(
              Map<String, dynamic>.from(snapshot['session']),
            ).toCompanion(false),
          );
      for (final item in snapshot['exercises'] as List) {
        await database
            .into(database.workoutExercises)
            .insert(
              WorkoutExercise.fromJson(
                Map<String, dynamic>.from(item['exercise']),
              ).toCompanion(false),
            );
        for (final set in item['sets'] as List) {
          await database
              .into(database.workoutSets)
              .insert(
                WorkoutSet.fromJson(Map<String, dynamic>.from(set))
                    .toCompanion(false),
              );
        }
      }
    }
    await database
        .into(database.cycleDayExecutions)
        .insert(
          CycleDayExecution.fromJson(
            Map<String, dynamic>.from(snapshot['execution']),
          ).toCompanion(false),
        );
    await clearSetting(_redoKey);
    return true;
  });

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
    await clearSetting(_redoKey);
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

class PrPoint {
  const PrPoint(this.date, this.weight, {this.id, this.reps});
  final String date;
  final double weight;
  final String? id;
  final int? reps;
}
