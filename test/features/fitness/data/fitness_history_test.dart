import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/calendar/data/calendar_repository.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/today/data/today_repository.dart';

const workout = [
  WorkoutDraftExercise(
    name: 'Bench',
    saveAsPreset: false,
    sets: [WorkoutDraftSet(weight: 40, reps: 8, rir: 2)],
  ),
];

void main() {
  late AppDatabase db;
  late FitnessRepository repo;
  late DateTime now;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 10, 7, 12);
    repo = FitnessRepository(db, clock: () => now);
    await repo.activateTemplate(builtInTrainingPlanTemplates.first);
  });
  tearDown(() => db.close());

  Future<void> replace(
    DateTime date,
    String kind, {
    String? dayId,
    List<WorkoutDraftExercise> exercises = workout,
  }) async {
    final context = await repo.loadHistoricalDay(date);
    await repo.replaceHistoricalDay(
      date: date,
      cycleId: context.choices.last.cycle.id,
      dayId: dayId,
      kind: kind,
      expectedRevision: context.revision,
      exercises: exercises,
    );
  }

  test(
    '02:00 action is yesterday; undo/redo and 04:00 lock rollover agree',
    () async {
      now = DateTime(2026, 10, 8, 2);
      final dashboard = (await repo.loadDashboard())!;
      await repo.completeWorkout(dashboard, workout);
      expect(
        (await db.select(db.workoutSessions).getSingle()).localDate,
        '2026-10-07',
      );
      expect(
        (await repo.actionsOnDate(DateTime(2026, 10, 7))).single.localDate,
        '2026-10-07',
      );
      expect(
        (await TodayRepository(db).loadDay(DateTime(2026, 10, 7))).actions,
        hasLength(1),
      );
      await expectLater(
        repo.takeRest(),
        throwsA(isA<FitnessDayActionLockedException>()),
      );
      expect(await repo.undoLatestFitnessActionToday(), true);
      expect(await repo.redoLatestFitnessActionToday(), true);
      now = DateTime(2026, 10, 8, 4);
      expect((await repo.loadDashboard())!.hasActionToday, false);
      await repo.takeRest();
      expect(
        (await repo.actionsOnDate(DateTime(2026, 10, 8))).single.localDate,
        '2026-10-08',
      );
    },
  );

  test(
    'backfill edits training/rest/skip without touching later workouts',
    () async {
      final d = (await repo.loadDashboard())!;
      final push = d.planDays[0].id, pull = d.planDays[1].id;
      await replace(DateTime(2026, 10, 5), 'training', dayId: push);
      await replace(DateTime(2026, 10, 6), 'training', dayId: pull);
      final later = (await repo.workoutsOnDate(DateTime(2026, 10, 6))).single;
      await replace(DateTime(2026, 10, 5), 'rest');
      expect(await repo.workoutsOnDate(DateTime(2026, 10, 5)), isEmpty);
      expect((await repo.loadDashboard())!.progress.nextDay!.id, push);
      final preserved = (await repo.workoutsOnDate(DateTime(2026, 10, 6)))
          .single;
      expect(preserved.session, later.session);
      expect(preserved.exercises.single.sets, later.exercises.single.sets);
      await replace(DateTime(2026, 10, 5), 'skip', dayId: push);
      expect(
        (await repo.actionsOnDate(DateTime(2026, 10, 5))).single.executionType,
        'skippedTraining',
      );
      expect((await repo.loadDashboard())!.progress.nextDay!.name, 'legs');
      await replace(DateTime(2026, 10, 5), 'training', dayId: push);
      expect(
        (await repo.workoutsOnDate(DateTime(2026, 10, 5)))
            .single
            .session
            .startedAt
            .hour,
        12,
      );
      expect((await repo.loadDashboard())!.cycle.startLocalDate, '2026-10-05');
    },
  );

  test(
    'duplicate cycle/day and invalid input rollback the original date',
    () async {
      final d = (await repo.loadDashboard())!;
      await replace(DateTime(2026, 10, 5), 'training', dayId: d.planDays[0].id);
      await replace(DateTime(2026, 10, 6), 'training', dayId: d.planDays[1].id);
      final original = (await repo.workoutsOnDate(DateTime(2026, 10, 5)))
          .single;
      await expectLater(
        replace(DateTime(2026, 10, 5), 'training', dayId: d.planDays[1].id),
        throwsStateError,
      );
      await expectLater(
        replace(
          DateTime(2026, 10, 5),
          'training',
          dayId: d.planDays[0].id,
          exercises: const [
            WorkoutDraftExercise(
              name: 'Bad',
              saveAsPreset: false,
              sets: [WorkoutDraftSet(weight: -1, reps: 8, rir: 2)],
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        (await repo.workoutsOnDate(DateTime(2026, 10, 5))).single.session,
        original.session,
      );
      expect(
        (await repo.actionsOnDate(DateTime(2026, 10, 5))).single.planDayId,
        d.planDays[0].id,
      );
    },
  );

  test(
    'stale history context cannot overwrite concurrent plan actions',
    () async {
      final context = await repo.loadHistoricalDay(DateTime(2026, 10, 5));
      await repo.takeRest();
      await expectLater(
        repo.replaceHistoricalDay(
          date: context.date,
          cycleId: context.choices.last.cycle.id,
          kind: 'rest',
          expectedRevision: context.revision,
        ),
        throwsStateError,
      );
      expect(await repo.actionsOnDate(context.date), isEmpty);
    },
  );

  test('backfill closes a complete live cycle once; correcting it never reopens it', () async {
    final d = (await repo.loadDashboard())!;
    for (var i = 0; i < 4; i++) {
      await replace(
        DateTime(2026, 10, 3 + i),
        i == 3 ? 'rest' : 'training',
        dayId: d.planDays[i].id,
      );
    }
    final next = (await repo.loadDashboard())!;
    expect(next.cycle.cycleNumber, 2);
    final context = await repo.loadHistoricalDay(DateTime(2026, 10, 3));
    await repo.replaceHistoricalDay(
      date: context.date,
      cycleId: d.cycle.id,
      kind: 'rest',
      expectedRevision: context.revision,
    );
    expect((await repo.loadDashboard())!.cycle.id, next.cycle.id);
    final old = await (db.select(
      db.cycleInstances,
    )..where((c) => c.id.equals(d.cycle.id))).getSingle();
    expect(old.status, 'corrected');
    expect(old.endLocalDate, '2026-10-06');
    expect(await db.select(db.cycleInstances).get(), hasLength(2));
  });

  test('implicit rest is display-only, including a cardio-only date', () async {
    await db
        .into(db.cardioLogs)
        .insert(
          CardioLogsCompanion.insert(
            id: 'cardio',
            localDate: '2026-10-06',
            activity: 'Walk',
            minutes: 20,
            recordedAt: now,
          ),
        );
    final calendar = await CalendarRepository(db).loadMonth(now, now: now);
    expect(calendar.days['2026-10-05']!.rest, true);
    expect(calendar.days['2026-10-06']!.rest, true);
    expect(calendar.days['2026-10-06']!.training, true);
    expect(calendar.days['2026-10-08'], isNull);
    expect(await db.select(db.cycleDayExecutions).get(), isEmpty);
    expect((await repo.loadDashboard())!.progress.consumedDayIds, isEmpty);
    expect(
      (await TodayRepository(db).loadDay(DateTime(2026, 10, 6))).actions,
      isEmpty,
    );
  });

  test('legacy 02:00 actions keep their old midnight-based date', () async {
    final d = (await repo.loadDashboard())!;
    await db
        .into(db.cycleDayExecutions)
        .insert(
          CycleDayExecutionsCompanion.insert(
            id: 'legacy',
            cycleInstanceId: d.cycle.id,
            executionType: 'extraRest',
            occurredAt: DateTime(2026, 10, 6, 2),
          ),
        );
    expect(await repo.actionsOnDate(DateTime(2026, 10, 5)), isEmpty);
    expect(
      (await repo.actionsOnDate(DateTime(2026, 10, 6))).single.localDate,
      isNull,
    );
  });

  test('future dates reject and never create actions', () async {
    await expectLater(
      repo.loadHistoricalDay(DateTime(2026, 10, 8)),
      throwsArgumentError,
    );
    expect(await db.select(db.cycleDayExecutions).get(), isEmpty);
  });

  test(
    'an editor crossing 04:00 commits its pinned date, not the new day',
    () async {
      now = DateTime(2026, 10, 8, 3, 59);
      final date = repo.recordingDate;
      final d = (await repo.loadDashboard())!;
      now = DateTime(2026, 10, 8, 4, 1);
      await repo.completeWorkout(d, workout, recordDate: date);
      expect(
        (await db.select(db.workoutSessions).getSingle()).localDate,
        '2026-10-07',
      );
      expect((await repo.loadDashboard())!.hasActionToday, false);
    },
  );

  test(
    'today backfill completing a cycle can undo and redo its rollover',
    () async {
      final d = (await repo.loadDashboard())!;
      for (var i = 0; i < 3; i++) {
        await replace(
          DateTime(2026, 10, 4 + i),
          'training',
          dayId: d.planDays[i].id,
        );
      }
      await replace(DateTime(2026, 10, 7), 'rest', dayId: d.planDays.last.id);
      expect((await repo.loadDashboard())!.cycle.cycleNumber, 2);
      expect(await repo.undoLatestFitnessActionToday(), true);
      expect((await repo.loadDashboard())!.cycle.cycleNumber, 1);
      expect(await repo.redoLatestFitnessActionToday(), true);
      expect((await repo.loadDashboard())!.cycle.cycleNumber, 2);
      expect(await db.select(db.cycleInstances).get(), hasLength(2));
    },
  );

  test(
    'backfill a pre-start day removes only that unrecorded override',
    () async {
      final d = (await repo.loadDashboard())!;
      await repo.chooseCycleStart(d.planDays[2].id);
      await replace(DateTime(2026, 10, 5), 'training', dayId: d.planDays[0].id);
      final updated = (await repo.loadDashboard())!;
      expect(updated.unrecordedDayIds, {d.planDays[1].id});
      expect(updated.progress.nextDay!.id, d.planDays[2].id);
      await replace(DateTime(2026, 10, 5), 'rest');
      expect(
        (await repo.loadDashboard())!.progress.nextDay!.id,
        d.planDays[0].id,
      );
    },
  );

  test('editing a switched-plan record preserves the original binding and active plan', () async {
    final old = (await repo.loadDashboard())!;
    await replace(DateTime(2026, 10, 5), 'training', dayId: old.planDays[0].id);
    await repo.activateTemplate(builtInTrainingPlanTemplates[1]);
    final current = (await repo.loadDashboard())!;
    final context = await repo.loadHistoricalDay(DateTime(2026, 10, 5));
    await repo.replaceHistoricalDay(
      date: context.date,
      cycleId: old.cycle.id,
      dayId: old.planDays[0].id,
      kind: 'skip',
      expectedRevision: context.revision,
    );
    expect(
      (await repo.actionsOnDate(context.date)).single.cycleInstanceId,
      old.cycle.id,
    );
    expect((await repo.loadDashboard())!.cycle.id, current.cycle.id);
    expect((await repo.loadDashboard())!.progress.consumedDayIds, isEmpty);
  });
}
