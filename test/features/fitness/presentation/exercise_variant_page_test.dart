import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/fitness/presentation/workout_editor_page.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'variant note changes only the editor copy and persists in draft',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = FitnessRepository(db);
      await repo.activateTemplate(builtInTrainingPlanTemplates.first);
      final dashboard = (await repo.loadDashboard())!;
      final day = dashboard.planDays.first;
      final base = await repo.createExercisePreset('Lat pulldown');
      await repo.addPlanExercise(
        planDayId: day.id,
        exerciseId: base,
        targetSets: 2,
        targetRepsMin: 8,
        targetRepsMax: 12,
      );
      final planned = (await repo.loadPlanExercises([day]))[day.id]!;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (c) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  c,
                  MaterialPageRoute(
                    builder: (_) => WorkoutEditorPage(
                      repository: repo,
                      dashboard: dashboard,
                      plannedExercises: planned,
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      Future<void> settle() async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 70)),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Open'));
      await settle();
      await tester.tap(find.text('Variant note / separate preset'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('exercise-variant-note')),
        'Underhand narrow',
      );
      await tester.tap(find.text('Save'));
      await settle();
      expect(find.text('Lat pulldown [Underhand narrow]'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '40');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle();
      await tester.tap(find.text('Open'));
      await settle();
      expect(find.text('Lat pulldown [Underhand narrow]'), findsOneWidget);
      expect(
        (await repo.loadPlanExercises([day]))[day.id]!.single.exercise.id,
        base,
      );
      expect(
        (await repo.listExercises()).firstWhere((e) => e.id == base).notes,
        isNull,
      );
      expect(await repo.listExercises(), hasLength(2));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle();
      await tester.pumpWidget(const SizedBox());
    },
  );
}
