import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/exercise_variant.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';

void main() {
  test(
    'variants are independent presets, plan references and PR series',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = FitnessRepository(db);
      await repo.activateTemplate(builtInTrainingPlanTemplates.first);
      final base = await repo.createExercisePreset('Lat pulldown');
      final wide = await repo.createExerciseVariant(
        'Lat pulldown',
        'Overhand wide',
      );
      final narrow = await repo.createExerciseVariant(
        'Lat pulldown',
        'Underhand narrow',
      );
      expect(wide, isNot(base));
      expect(narrow, isNot(wide));
      expect(
        await repo.createExerciseVariant(' lat pulldown ', ' OVERHAND WIDE '),
        wide,
      );
      final original = (await repo.listExercises()).firstWhere(
        (p) => p.id == base,
      );
      expect(original.notes, isNull);
      expect(original.name, 'Lat pulldown');
      final d = (await repo.loadDashboard())!;
      await repo.addPlanExercise(
        planDayId: d.planDays.first.id,
        exerciseId: base,
        targetSets: 2,
        targetRepsMin: 8,
        targetRepsMax: 12,
      );
      final item = (await repo.loadPlanExercises([
        d.planDays.first,
      ]))[d.planDays.first.id]!.single;
      await repo.replacePlanExercisePreset(item.planExercise.id, wide);
      expect(
        (await repo.loadPlanExercises([
          d.planDays.first,
        ]))[d.planDays.first.id]!.single.exercise.id,
        wide,
      );
      final name = variantExerciseName('Lat pulldown', 'Overhand wide');
      await repo.completeWorkout(d, [
        WorkoutDraftExercise(
          name: name,
          baseName: 'Lat pulldown',
          variantNote: 'Overhand wide',
          saveAsPreset: true,
          sets: const [WorkoutDraftSet(weight: 40, reps: 8, rir: 2)],
        ),
      ]);
      final history = (await repo.listWorkoutHistory()).single.exercises.single;
      expect(history.exercise.exerciseId, wide);
      expect(history.exercise.notes, 'Overhand wide');
      expect(
        (await repo.listExercises()).firstWhere((p) => p.id == base).notes,
        isNull,
      );
      expect(
        exerciseVariant(
          name,
          (await repo.listExercises()).firstWhere((p) => p.id == wide).notes,
        ).base,
        'Lat pulldown',
      );
      await expectLater(
        repo.createExerciseVariant('Lat pulldown', ''),
        throwsArgumentError,
      );
    },
  );
  test(
    'a variant never overwrites a pre-existing literal preset of the same name',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = FitnessRepository(db);
      final id = await repo.createExercisePreset('Lat pulldown [Wide]');
      await expectLater(
        repo.createExerciseVariant('Lat pulldown', 'Wide'),
        throwsStateError,
      );
      expect((await repo.listExercises()).single.id, id);
      expect((await repo.listExercises()).single.notes, isNull);
    },
  );
}
