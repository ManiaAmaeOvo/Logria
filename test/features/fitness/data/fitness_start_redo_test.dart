import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';

void main() {
  late AppDatabase db;
  late FitnessRepository repo;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = FitnessRepository(db);
    await repo.activateTemplate(builtInTrainingPlanTemplates[1]);
  });
  tearDown(() => db.close());
  const workout = [
    WorkoutDraftExercise(
      name: 'Push-up',
      saveAsPreset: true,
      sets: [
        WorkoutDraftSet(
          weight: null,
          weightText: 'bodyweight',
          reps: 12,
          rir: null,
        ),
        WorkoutDraftSet(weight: 0, weightText: 'band', reps: 8, rir: 2),
      ],
    ),
  ];

  test('start at Push 2 persists and never fabricates earlier logs', () async {
    final initial = (await repo.loadDashboard())!;
    await repo.chooseCycleStart(initial.planDays[4].id);
    final started = (await FitnessRepository(db).loadDashboard())!;
    expect(started.progress.nextDay!.id, initial.planDays[4].id);
    expect(started.unrecordedDayIds, hasLength(4));
    expect(started.executions, isEmpty);
    expect(started.hasActionToday, isFalse);
    expect(await repo.listWorkoutHistory(), isEmpty);
    await repo.completeWorkout(started, workout);
    expect(
      (await repo.loadDashboard())!.progress.nextDay!.id,
      initial.planDays[5].id,
    );
    expect(await db.select(db.cycleDayExecutions).get(), hasLength(1));
  });

  test(
    'entry point can be changed before recording but not after an action',
    () async {
      final initial = (await repo.loadDashboard())!;
      await repo.chooseCycleStart(initial.planDays[4].id);
      await repo.chooseCycleStart(initial.planDays[1].id);
      expect((await repo.loadDashboard())!.unrecordedDayIds, {
        initial.planDays.first.id,
      });
      await repo.takeRest();
      await expectLater(
        repo.chooseCycleStart(initial.planDays[4].id),
        throwsA(isA<FitnessDayActionLockedException>()),
      );
      await expectLater(
        repo.chooseCycleStart('unknown'),
        throwsA(isA<FitnessDayActionLockedException>()),
      );
    },
  );

  test('drafts block changing entry point until explicitly discarded', () async {
    final d = (await repo.loadDashboard())!;
    final key =
        'fitness.draft.${DateFormat('yyyy-MM-dd').format(DateTime.now())}.${d.planDays.first.id}';
    await repo.writeSetting(key, '[]');
    expect((await repo.loadDashboard())!.canChooseStart, isFalse);
    await expectLater(
      repo.chooseCycleStart(d.planDays[4].id),
      throwsStateError,
    );
    await repo.clearSetting(key);
    await repo.chooseCycleStart(d.planDays[4].id);
    expect((await repo.loadDashboard())!.canChooseStart, isTrue);
  });

  test(
    'redo restores original IDs, timestamps, sets and current cycle exactly',
    () async {
      final initial = (await repo.loadDashboard())!;
      await repo.chooseCycleStart(initial.planDays[4].id);
      await repo.completeWorkout((await repo.loadDashboard())!, workout);
      final session = await db.select(db.workoutSessions).getSingle();
      final sets = await db.select(db.workoutSets).get();
      final execution = await db.select(db.cycleDayExecutions).getSingle();
      expect(await repo.undoLatestFitnessActionToday(), isTrue);
      expect((await repo.loadDashboard())!.canRedo, isTrue);
      expect(
        (await repo.loadDashboard())!.progress.nextDay!.id,
        initial.planDays[4].id,
      );
      expect(await repo.listWorkoutHistory(), isEmpty);
      expect(
        await FitnessRepository(db).redoLatestFitnessActionToday(),
        isTrue,
      );
      expect(
        (await db.select(db.workoutSessions).getSingle()).toJson(),
        session.toJson(),
      );
      expect(
        (await db.select(db.workoutSets).get()).map((s) => s.toJson()),
        sets.map((s) => s.toJson()),
      );
      expect(
        (await db.select(db.cycleDayExecutions).getSingle()).toJson(),
        execution.toJson(),
      );
      expect((await repo.loadDashboard())!.hasActionToday, isTrue);
      expect(await repo.redoLatestFitnessActionToday(), isFalse);
      expect(await repo.undoLatestFitnessActionToday(), isTrue);
      expect(await repo.redoLatestFitnessActionToday(), isTrue);
      expect(await db.select(db.workoutSets).get(), hasLength(2));
    },
  );

  test('final-day undo/redo restores next cycle without resetting future entry point', () async {
    final initial = (await repo.loadDashboard())!;
    await repo.chooseCycleStart(initial.planDays.last.id);
    await repo.takeRest();
    final next = (await repo.loadDashboard())!;
    expect(next.cycle.cycleNumber, 2);
    expect(next.unrecordedDayIds, isEmpty);
    expect(next.progress.nextDay!.id, initial.planDays.first.id);
    expect(await repo.undoLatestFitnessActionToday(), isTrue);
    expect((await repo.loadDashboard())!.cycle.cycleNumber, 1);
    expect(await db.select(db.cycleInstances).get(), hasLength(1));
    expect(await repo.redoLatestFitnessActionToday(), isTrue);
    expect((await repo.loadDashboard())!.cycle.toJson(), next.cycle.toJson());
    expect(await db.select(db.cycleInstances).get(), hasLength(2));
  });

  test('a replacement action invalidates the old redo', () async {
    await repo.completeWorkout((await repo.loadDashboard())!, workout);
    await repo.undoLatestFitnessActionToday();
    await repo.takeRest();
    expect((await repo.loadDashboard())!.canRedo, isFalse);
    expect(await repo.redoLatestFitnessActionToday(), isFalse);
    expect(await repo.listWorkoutHistory(), isEmpty);
    expect(await repo.undoLatestFitnessActionToday(), isTrue);
    expect(await repo.redoLatestFitnessActionToday(), isTrue);
    expect(
      (await repo.loadDashboard())!.executions.single.executionType,
      'movedRest',
    );
  });

  test(
    'plan edits, switching plans and changing start invalidate redo',
    () async {
      await repo.takeRest();
      await repo.undoLatestFitnessActionToday();
      await repo.renameActivePlan('Changed plan');
      expect(await repo.redoLatestFitnessActionToday(), isFalse);
      await repo.takeRest();
      await repo.undoLatestFitnessActionToday();
      final d = (await repo.loadDashboard())!;
      await repo.chooseCycleStart(d.planDays[4].id);
      expect(await repo.redoLatestFitnessActionToday(), isFalse);
      await repo.takeRest();
      await repo.undoLatestFitnessActionToday();
      await repo.activateTemplate(builtInTrainingPlanTemplates.first);
      expect(await repo.redoLatestFitnessActionToday(), isFalse);
    },
  );

  test('redo expires at a local date boundary', () async {
    await repo.takeRest();
    await repo.undoLatestFitnessActionToday();
    final raw = jsonDecode(
      (await repo.readSetting('fitness.undo.today'))!,
    ) as Map<String, dynamic>;
    raw['date'] = '2000-01-01';
    await repo.writeSetting('fitness.undo.today', jsonEncode(raw));
    expect((await repo.loadDashboard())!.canRedo, isFalse);
    expect(await repo.redoLatestFitnessActionToday(), isFalse);
  });

  test(
    'undo recovery works after a plan switch made before the undo',
    () async {
      await repo.completeWorkout((await repo.loadDashboard())!, workout);
      final original = await db.select(db.workoutSessions).getSingle();
      await repo.activateTemplate(builtInTrainingPlanTemplates.first);
      final activePlan = (await repo.loadDashboard())!.plan.id;
      expect(await repo.undoLatestFitnessActionToday(), isTrue);
      expect((await repo.loadDashboard())!.canRedo, isTrue);
      expect(await repo.redoLatestFitnessActionToday(), isTrue);
      expect(
        (await db.select(db.workoutSessions).getSingle()).toJson(),
        original.toJson(),
      );
      expect((await repo.loadDashboard())!.plan.id, activePlan);
    },
  );

  test(
    'a previous-day record prevents resetting a partially logged cycle',
    () async {
      await repo.takeRest();
      final e = await db.select(db.cycleDayExecutions).getSingle();
      await (db.update(
        db.cycleDayExecutions,
      )..where((r) => r.id.equals(e.id))).write(
        CycleDayExecutionsCompanion(
          occurredAt: Value(DateTime.now().subtract(const Duration(days: 1))),
        ),
      );
      final d = (await repo.loadDashboard())!;
      expect(d.canChooseStart, isFalse);
      await expectLater(
        repo.chooseCycleStart(d.planDays[4].id),
        throwsStateError,
      );
    },
  );
}
