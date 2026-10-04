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
    'exit immediately preserves partial input; resume and finish only once',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = FitnessRepository(db);
      await repo.activateTemplate(builtInTrainingPlanTemplates.first);
      final dashboard = (await repo.loadDashboard())!;
      final day = dashboard.planDays.first;
      final id = await repo.createExercisePreset('Push-up');
      await repo.addPlanExercise(
        planDayId: day.id,
        exerciseId: id,
        targetSets: 2,
        targetRepsMin: 8,
        targetRepsMax: 12,
      );
      final planned = (await repo.loadPlanExercises([day]))[day.id]!;
      var editing = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final current = await repo.loadDashboard();
                  if (!context.mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutEditorPage(
                        repository: repo,
                        dashboard: current!,
                        plannedExercises: planned,
                        existingWorkout: editing ? current.todayWorkout : null,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      Future<void> settle() async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Open'));
      await settle();
      expect(find.byType(TextField), findsNWidgets(6));
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(
          field.controller!.text,
          isEmpty,
          reason: 'Plan targets are not completed values',
        );
      }
      await tester.enterText(find.byType(TextField).at(0), 'bodyweight + band');
      await tester.enterText(find.byType(TextField).at(1), '');
      await tester.enterText(find.byType(TextField).at(2), '');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle();
      expect(find.text('Open'), findsOneWidget);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect((await repo.loadDashboard())!.hasDraft, isTrue);
      expect((await repo.loadDashboard())!.progress.consumedDayIds, isEmpty);

      await tester.tap(find.text('Open'));
      await settle();
      expect(find.text('bodyweight + band'), findsOneWidget);
      expect(
        (tester.widget<TextField>(find.byType(TextField).at(1)))
            .controller!
            .text,
        '',
      );
      await tester.enterText(find.byType(TextField).at(1), '12');
      // Verify the Android/system back path also flushes before popping.
      await tester.binding.handlePopRoute();
      await settle();
      await tester.tap(find.text('Open'));
      await settle();
      expect(find.text('12'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Finish and save workout'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish and save workout'));
      await settle();
      expect(tester.takeException(), isNull);
      expect(find.text('Open'), findsOneWidget);
      final saved = (await db.select(db.workoutSets).get()).single;
      expect(saved.weightText, 'bodyweight + band');
      expect(saved.weightValue, isNull);
      expect(saved.reps, 12);
      expect(saved.rir, isNull);
      expect((await repo.loadDashboard())!.hasDraft, isFalse);
      expect(
        (await repo.loadDashboard())!.progress.consumedDayIds,
        hasLength(1),
      );

      editing = true;
      await tester.tap(find.text('Open'));
      await settle();
      await tester.enterText(find.byType(TextField).at(0), 'unmeasured load');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle();
      final original = await db.select(db.workoutSets).getSingle();
      expect(original.weightText, 'bodyweight + band');
      await tester.tap(find.text('Open'));
      await settle();
      expect(find.text('unmeasured load'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<bool>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('0 · no measurable external load').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save changes'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await settle();
      final updated = await db.select(db.workoutSets).getSingle();
      expect(updated.weightValue, 0);
      expect(updated.weightText, 'unmeasured load');
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(
        (await repo.loadDashboard())!.progress.consumedDayIds,
        hasLength(1),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
