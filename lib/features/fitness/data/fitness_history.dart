part of 'fitness_repository.dart';

class FitnessCycleChoice {
  const FitnessCycleChoice(this.cycle, this.plan, this.days, this.live);
  final CycleInstance cycle;
  final TrainingPlan plan;
  final List<PlanDay> days;
  final bool live;
}

class HistoricalFitnessDay {
  const HistoricalFitnessDay(
    this.date,
    this.choices,
    this.executions,
    this.workouts,
    this.revision,
  );
  final DateTime date;
  final List<FitnessCycleChoice> choices;
  final List<CycleDayExecution> executions;
  final List<WorkoutHistoryItem> workouts;
  final String revision;
}

extension HistoricalFitnessRepository on FitnessRepository {
  Future<List<CycleDayExecution>> actionsOnDate(DateTime date) =>
      (database.select(database.cycleDayExecutions)
            ..where((e) => RecordDay.matches(e.localDate, e.occurredAt, date)))
          .get();

  /// A conservative revision protects against plan edits and other cycle actions.
  Future<String> _historyRevision(DateTime date) async => jsonEncode([
    (await database.select(database.trainingPlans).get())
        .map((r) => r.toJson())
        .toList(),
    (await database.select(database.planDays).get())
        .map((r) => r.toJson())
        .toList(),
    (await database.select(database.planDayExercises).get())
        .map((r) => r.toJson())
        .toList(),
    (await database.select(database.cycleInstances).get())
        .map((r) => r.toJson())
        .toList(),
    (await database.select(database.cycleDayExecutions).get())
        .map((r) => r.toJson())
        .toList(),
    (await workoutsOnDate(date))
        .map(
          (w) => [
            w.session.toJson(),
            w.exercises
                .map(
                  (e) => [
                    e.exercise.toJson(),
                    e.sets.map((s) => s.toJson()).toList(),
                  ],
                )
                .toList(),
          ],
        )
        .toList(),
    (await (database.select(
          database.appSettings,
        )..where((s) => s.keyName.like('fitness.cycle.start.%'))).get())
        .map((s) => s.toJson())
        .toList(),
  ]);

  Future<HistoricalFitnessDay> loadHistoricalDay(DateTime date) =>
      database.transaction(() async {
        final label = RecordDay.dateOnly(date);
        if (label.isAfter(recordingDate)) {
          throw ArgumentError('Future dates cannot be recorded.');
        }
        final live = await loadDashboard();
        final actions = await actionsOnDate(label);
        final workouts = await workoutsOnDate(label);
        final referenced = {
          ...actions.map((e) => e.cycleInstanceId),
          ...workouts.map((w) => w.session.cycleInstanceId).whereType<String>(),
        };
        final spans = await CalendarRepository(database)
            .loadMonth(label, now: _now());
        final choices = <FitnessCycleChoice>[];
        for (final span in spans.cycles.reversed) {
          final cycle = span.cycle;
          final isLive = cycle.id == live?.cycle.id;
          if (!isLive &&
              !referenced.contains(cycle.id) &&
              (label.isBefore(span.startDate) || label.isAfter(span.endDate))) {
            continue;
          }
          final plan = await (database.select(
            database.trainingPlans,
          )..where((p) => p.id.equals(cycle.planId))).getSingle();
          final days =
              await (database.select(database.planDays)
                    ..where((d) => d.planId.equals(plan.id))
                    ..orderBy([(d) => OrderingTerm.asc(d.position)]))
                  .get();
          choices.add(FitnessCycleChoice(cycle, plan, days, isLive));
        }
        return HistoricalFitnessDay(
          label,
          choices,
          actions,
          workouts,
          await _historyRevision(label),
        );
      });

  Future<Set<String>> occupiedHistoricalDays(
    String cycleId,
    DateTime date,
  ) async {
    final onDate = (await actionsOnDate(date)).map((e) => e.id).toSet();
    final actions = await (database.select(
      database.cycleDayExecutions,
    )..where((e) => e.cycleInstanceId.equals(cycleId))).get();
    final sessions = await (database.select(
      database.workoutSessions,
    )..where((s) => s.cycleInstanceId.equals(cycleId))).get();
    return {
      ...actions
          .where((e) => !onDate.contains(e.id))
          .map((e) => e.planDayId)
          .whereType<String>(),
      ...sessions
          .where((s) => s.localDate != RecordDay.key(date))
          .map((s) => s.planDayId)
          .whereType<String>(),
    };
  }

  FitnessDashboardData historicalDashboard(
    FitnessCycleChoice choice,
    String dayId,
  ) => FitnessDashboardData(
    plan: choice.plan,
    cycle: choice.cycle,
    planDays: choice.days,
    executions: const [],
    progress: TrainingCycleProgress(
      cycleNumber: choice.cycle.cycleNumber,
      days: choice.days
          .map(
            (d) => CycleDayDefinition(
              id: d.id,
              name: d.name,
              position: d.position,
              type: CycleDayType.values.byName(d.dayType),
            ),
          )
          .toList(),
      consumedDayIds: choice.days
          .where((d) => d.id != dayId)
          .map((d) => d.id)
          .toSet(),
    ),
    hasActionToday: false,
    todayWorkout: null,
  );

  /// Replaces exactly one date atomically; never reassigns later workout snapshots.
  Future<void> replaceHistoricalDay({
    required DateTime date,
    required String cycleId,
    String? dayId,
    required String kind,
    required String expectedRevision,
    List<WorkoutDraftExercise> exercises = const [],
  }) => database.transaction(() async {
    final context = await loadHistoricalDay(date);
    if (context.revision != expectedRevision) {
      throw StateError(
        'Records or plan changed. Reopen this date before saving.',
      );
    }
    if (!['training', 'rest', 'skip'].contains(kind)) {
      throw ArgumentError('Unknown action.');
    }
    final choice = context.choices
        .where((c) => c.cycle.id == cycleId)
        .firstOrNull;
    if (choice == null) {
      throw StateError('This cycle is not compatible with the selected date.');
    }
    final day = choice.days.where((d) => d.id == dayId).firstOrNull;
    if ((kind != 'rest' && day?.dayType != 'training') ||
        (kind == 'rest' && dayId != null && day?.dayType != 'rest')) {
      throw ArgumentError('Select a compatible plan day.');
    }
    if (dayId != null &&
        (await occupiedHistoricalDays(cycleId, date)).contains(dayId)) {
      throw StateError(
        'This plan day is already recorded on another date in this cycle.',
      );
    }
    if (kind == 'training') {
      if (exercises.isEmpty ||
          exercises.any(
            (e) =>
                e.name.trim().isEmpty ||
                e.sets.isEmpty ||
                e.sets.any(
                  (s) =>
                      (s.weight != null &&
                          (!s.weight!.isFinite || s.weight! < 0)) ||
                      (s.reps != null && s.reps! < 0) ||
                      (s.rir != null &&
                          (!s.rir!.isFinite ||
                              s.rir! < 0 ||
                              s.rir! > 10 ||
                              s.rir! * 2 != (s.rir! * 2).roundToDouble())),
                ),
          )) {
        throw ArgumentError('Invalid workout.');
      }
    }
    final existing = context.workouts.firstOrNull;
    final oldAction = context.executions.firstOrNull;
    final occurred =
        existing?.session.startedAt ??
        oldAction?.occurredAt ??
        (RecordDay.dateOnly(date) == recordingDate
            ? _now()
            : DateTime(date.year, date.month, date.day, 12));
    final oldCycles = context.executions.map((e) => e.cycleInstanceId).toSet()
      ..addAll(
        context.workouts
            .map((w) => w.session.cycleInstanceId)
            .whereType<String>(),
      );
    for (final w in context.workouts) {
      await (database.delete(
        database.workoutSessions,
      )..where((s) => s.id.equals(w.session.id))).go();
    }
    for (final action in context.executions) {
      await (database.delete(
        database.cycleDayExecutions,
      )..where((e) => e.id.equals(action.id))).go();
    }
    final sameBinding =
        existing?.session.cycleInstanceId == cycleId &&
        existing?.session.planDayId == dayId;
    if (kind == 'training') {
      final id = sameBinding ? existing!.session.id : _uuid.v4();
      await database
          .into(database.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              id: id,
              localDate: RecordDay.key(date),
              cycleInstanceId: Value(cycleId),
              planDayId: Value(dayId),
              planNameSnapshot: Value(
                sameBinding
                    ? existing!.session.planNameSnapshot
                    : choice.plan.name,
              ),
              dayNameSnapshot: Value(
                sameBinding ? existing!.session.dayNameSnapshot : day!.name,
              ),
              status: 'completed',
              startedAt: occurred,
              completedAt: Value(_now()),
              notes: Value(existing?.session.notes),
            ),
          );
      await _insertWorkoutExercises(id, exercises, _now());
    }
    await database
        .into(database.cycleDayExecutions)
        .insert(
          CycleDayExecutionsCompanion.insert(
            id: _uuid.v4(),
            cycleInstanceId: cycleId,
            planDayId: Value(dayId),
            localDate: Value(RecordDay.key(date)),
            executionType: kind == 'training'
                ? 'completedTraining'
                : kind == 'skip'
                ? 'skippedTraining'
                : dayId == null
                ? 'extraRest'
                : 'plannedRest',
            originalPosition: Value(day?.position),
            occurredAt: occurred,
          ),
        );
    final startIds = (jsonDecode(
      await readSetting('fitness.cycle.start.$cycleId') ?? '[]',
    ) as List).cast<String>();
    if (dayId != null && startIds.contains(dayId)) {
      await writeSetting(
        'fitness.cycle.start.$cycleId',
        jsonEncode(startIds.where((id) => id != dayId).toList()),
      );
    }
    final startDate =
        choice.cycle.startLocalDate ?? RecordDay.key(choice.cycle.startedAt);
    if (RecordDay.key(date).compareTo(startDate) < 0 && choice.live) {
      await (database.update(
        database.cycleInstances,
      )..where((c) => c.id.equals(cycleId))).write(
        CycleInstancesCompanion(startLocalDate: Value(RecordDay.key(date))),
      );
    }
    // Closed historical cycles stay closed even if a former training slot is freed.
    for (final id in {...oldCycles, cycleId}) {
      if (id == choice.cycle.id && choice.live) continue;
      final c = await (database.select(
        database.cycleInstances,
      )..where((c) => c.id.equals(id))).getSingle();
      if (c.status == 'completed') {
        await (database.update(database.cycleInstances)
              ..where((c) => c.id.equals(id)))
            .write(const CycleInstancesCompanion(status: Value('corrected')));
      }
    }
    await clearSetting(FitnessRepository._redoKey);
    final active = await loadDashboard();
    if (active != null && active.progress.isComplete) {
      final actions = await (database.select(
        database.cycleDayExecutions,
      )..where((e) => e.cycleInstanceId.equals(active.cycle.id))).get();
      final dates =
          actions
              .map((e) => e.localDate ?? RecordDay.key(e.occurredAt))
              .toList()
            ..sort();
      await (database.update(
        database.cycleInstances,
      )..where((c) => c.id.equals(active.cycle.id))).write(
        CycleInstancesCompanion(
          status: const Value('completed'),
          completedAt: Value(_now()),
          endLocalDate: Value(
            dates.isEmpty ? RecordDay.key(recordingDate) : dates.last,
          ),
        ),
      );
      await _createCycle(active.plan.id, active.cycle.cycleNumber + 1, _now());
    }
  });
}
