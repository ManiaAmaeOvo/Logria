import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';

void main() {
  test('restart preserves history, discards only plan drafts, and enables entry selection', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = FitnessRepository(db);
    await repo.activateTemplate(builtInTrainingPlanTemplates[1]);
    final old = (await repo.loadDashboard())!;
    await repo.completeWorkout(old, const [
      WorkoutDraftExercise(
        name: 'Bench',
        saveAsPreset: true,
        sets: [WorkoutDraftSet(weight: 40, reps: 10, rir: 2)],
      ),
    ]);
    await expectLater(
      repo.restartTrainingCycle(),
      throwsA(isA<FitnessDayActionLockedException>()),
    );
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await db
        .update(db.workoutSessions)
        .write(
          WorkoutSessionsCompanion(
            localDate: Value(DateFormat('yyyy-MM-dd').format(yesterday)),
          ),
        );
    await db
        .update(db.cycleDayExecutions)
        .write(CycleDayExecutionsCompanion(occurredAt: Value(yesterday)));
    final history = (await repo.listWorkoutHistory()).single;
    final key =
        'fitness.draft.${DateFormat('yyyy-MM-dd').format(DateTime.now())}.${old.planDays[1].id}';
    await repo.writeSetting(key, '[]');
    await repo.writeSetting('fitness.draft.2026-01-01.unrelated', 'keep');
    await repo.restartTrainingCycle();
    final fresh = (await repo.loadDashboard())!;
    expect(fresh.plan.id, old.plan.id);
    expect(fresh.cycle.cycleNumber, 2);
    expect(fresh.canChooseStart, isTrue);
    expect(fresh.executions, isEmpty);
    expect(
      (await repo.listWorkoutHistory()).single.session.id,
      history.session.id,
    );
    expect(await repo.readSetting(key), isNull);
    expect(
      await repo.readSetting('fitness.draft.2026-01-01.unrelated'),
      'keep',
    );
    final archived = await (db.select(
      db.cycleInstances,
    )..where((c) => c.id.equals(old.cycle.id))).getSingle();
    expect(archived.status, 'interrupted');
    await repo.chooseCycleStart(fresh.planDays[4].id);
    expect(
      (await repo.loadDashboard())!.progress.nextDay!.id,
      fresh.planDays[4].id,
    );
    expect(
      (await repo.previousSessionForDay(
        planDayId: fresh.planDays.first.id,
        beforeCycleNumber: 2,
      ))!.session.id,
      history.session.id,
    );
  });
}
