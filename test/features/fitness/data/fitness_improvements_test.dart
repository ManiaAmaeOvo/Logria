import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';

const drafts = [
  WorkoutDraftExercise(
    name: 'Bench',
    saveAsPreset: false,
    sets: [
      WorkoutDraftSet(weight: 40, reps: 10, rir: '2', notes: 'old feeling'),
      WorkoutDraftSet(weight: 0, weightText: 'band', reps: 8, rir: null),
    ],
  ),
];

void main() {
  late AppDatabase db;
  late FitnessRepository repo;
  late DateTime now;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 10, 28, 12);
    repo = FitnessRepository(db, clock: () => now);
    await repo.activateTemplate(builtInTrainingPlanTemplates.first);
  });
  tearDown(() => db.close());

  test('today progress stays on the finished round at rollover, then clears next day', () async {
    final first = (await repo.loadDashboard())!;
    await repo.chooseCycleStart(first.planDays.last.id);
    await repo.takeRest();
    final d = (await repo.loadDashboard())!;
    expect(d.cycle.cycleNumber, 2);
    expect(d.todayProgress!.cycle.id, first.cycle.id);
    expect(d.todayProgress!.highlightedDayId, first.planDays.last.id);
    expect(d.todayProgress!.unrecorded, hasLength(3));
    expect(d.todayProgress!.consumed, hasLength(4));
    await repo.undoLatestFitnessActionToday();
    expect((await repo.loadDashboard())!.todayProgress, isNull);
    await repo.redoLatestFitnessActionToday();
    expect(
      (await repo.loadDashboard())!.todayProgress!.highlightedDayId,
      first.planDays.last.id,
    );
    now = now.add(const Duration(days: 1));
    expect((await repo.loadDashboard())!.todayProgress, isNull);
  });

  test('new template preserves order and ranges but not feelings/text loads; never overwrites', () async {
    final day = (await repo.loadDashboard())!.planDays.first;
    expect(await repo.hasDayTemplate(day.id), isFalse);
    await repo.saveDayTemplateIfEmpty(day.id, drafts);
    final items = (await repo.loadPlanExercises([day]))[day.id]!;
    expect(items.single.exercise.name, 'Bench');
    expect(items.single.planExercise.targetSets, 2);
    expect(items.single.planExercise.targetRepsMin, 8);
    expect(items.single.planExercise.targetRepsMax, 10);
    expect(items.single.planExercise.targetWeight, 40);
    expect(items.single.planExercise.notes, isNull);
    await expectLater(
      repo.saveDayTemplateIfEmpty(day.id, drafts),
      throwsStateError,
    );
    expect((await repo.loadPlanExercises([day]))[day.id], hasLength(1));
  });

  test('template and workout writes roll back together if the template became occupied', () async {
    final d = (await repo.loadDashboard())!;
    await repo.saveDayTemplateIfEmpty(d.planDays.first.id, drafts);
    await expectLater(
      db.transaction(() async {
        await repo.completeWorkout(d, drafts);
        await repo.saveDayTemplateIfEmpty(d.planDays.first.id, drafts);
      }),
      throwsStateError,
    );
    expect(await db.select(db.workoutSessions).get(), isEmpty);
    expect((await repo.loadDashboard())!.hasActionToday, isFalse);
  });

  test(
    'plan reorder is constrained to the exact day and survives a fresh read',
    () async {
      final d = (await repo.loadDashboard())!;
      final day = d.planDays.first;
      await repo.saveDayTemplateIfEmpty(day.id, [
        ...drafts,
        const WorkoutDraftExercise(
          name: 'Row',
          saveAsPreset: true,
          sets: [WorkoutDraftSet(weight: null, reps: 8, rir: null)],
        ),
      ]);
      final original = (await repo.loadPlanExercises([day]))[day.id]!;
      final ids = original
          .map((i) => i.planExercise.id)
          .toList()
          .reversed
          .toList();
      await repo.reorderPlanExercises(day.id, ids);
      expect(
        (await repo.loadPlanExercises([
          day,
        ]))[day.id]!.map((e) => e.exercise.name),
        ['Row', 'Bench'],
      );
      await expectLater(
        repo.reorderPlanExercises(day.id, [ids.first, ids.first]),
        throwsStateError,
      );
      await expectLater(
        repo.reorderPlanExercises(d.planDays[1].id, ids),
        throwsStateError,
      );
      expect(
        (await repo.loadPlanExercises([
          day,
        ]))[day.id]!.map((e) => e.planExercise.position),
        [0, 1],
      );
    },
  );

  test('last exercise excludes same/future dates, skipped sets and independent variants', () async {
    await repo.completeWorkout((await repo.loadDashboard())!, drafts);
    final source = (await repo.listWorkoutHistory()).single;
    expect(await repo.latestExerciseRecord('Bench', now), isNull);
    now = now.add(const Duration(days: 1));
    final last = (await repo.latestExerciseRecord('  BENCH  ', now))!;
    expect(last.sets.map((s) => s.weightText), [null, 'band']);
    expect(last.sets.last.weightValue, 0);
    expect(await repo.latestExerciseRecord('Bench [wide]', now), isNull);
    await repo.completeWorkout((await repo.loadDashboard())!, const [
      WorkoutDraftExercise(
        name: 'Bench [wide]',
        baseName: 'Bench',
        variantNote: 'wide',
        saveAsPreset: true,
        sets: [WorkoutDraftSet(weight: 90, reps: 3, rir: null)],
      ),
    ]);
    now = now.add(const Duration(days: 1));
    expect(
      (await repo.latestExerciseRecord('Bench', now))!.exercise.id,
      last.exercise.id,
    );
    expect(
      (await repo.latestExerciseRecord(
        'Bench [wide]',
        now,
      ))!.sets.single.weightValue,
      90,
    );
    await (db.update(db.workoutSets)
          ..where((s) => s.workoutExerciseId.equals(last.exercise.id)))
        .write(const WorkoutSetsCompanion(isCompleted: Value(false)));
    expect(await repo.latestExerciseRecord('Bench', now), isNull);
    expect(source.exercises.single.exercise.exerciseNameSnapshot, 'Bench');
  });
}
