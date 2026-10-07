import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/fitness/presentation/workout_editor_page.dart';
import 'package:logria/l10n/app_localizations.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 70)),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final template in [false, true]) {
    testWidgets(
      'one-shot filling protects manual edits and persists flags (template=$template)',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = FitnessRepository(db);
        await repo.activateTemplate(builtInTrainingPlanTemplates.first);
        var dashboard = (await repo.loadDashboard())!;
        final day = dashboard.planDays.first;
        final preset = await repo.createExercisePreset('Bench');
        await repo.addPlanExercise(
          planDayId: day.id,
          exerciseId: preset,
          targetSets: 3,
          targetRepsMin: 8,
          targetRepsMax: 12,
        );
        WorkoutHistoryItem? previous;
        if (template) {
          await repo.completeWorkout(dashboard, const [
            WorkoutDraftExercise(
              name: 'Bench',
              saveAsPreset: true,
              sets: [
                WorkoutDraftSet(weight: 40, reps: 10, rir: 2),
                WorkoutDraftSet(weight: 0, weightText: 'band', reps: 8, rir: 1),
                WorkoutDraftSet(
                  weight: null,
                  weightText: 'bodyweight',
                  reps: 6,
                  rir: null,
                ),
              ],
            ),
          ]);
          previous = (await repo.listWorkoutHistory()).single;
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
              .write(
                CycleDayExecutionsCompanion(
                  occurredAt: Value(yesterday),
                  localDate: Value(DateFormat('yyyy-MM-dd').format(yesterday)),
                ),
              );
          await repo.restartTrainingCycle();
          dashboard = (await repo.loadDashboard())!;
        }
        final planned = (await repo.loadPlanExercises([day]))[day.id]!;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutEditorPage(
                        repository: repo,
                        dashboard: dashboard,
                        plannedExercises: planned,
                        previousWorkout: previous,
                        usePreviousOnOpen: template,
                      ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await settle(tester);
        String value(int index) => tester
            .widget<TextField>(find.byType(TextField).at(index))
            .controller!
            .text;
        if (template) {
          expect(value(0), '40.0');
          expect(value(3), 'band');
          expect(value(6), 'bodyweight');
          expect(value(2), '2.0');
          expect(value(4), '8');
        }
        // Edit a lower set first: each field is protected independently.
        await tester.enterText(find.byType(TextField).at(6), '55');
        await tester.enterText(find.byType(TextField).at(4), '7');
        await tester.enterText(find.byType(TextField).at(0), '4');
        await tester.enterText(find.byType(TextField).at(0), '40');
        expect(value(3), '40');
        expect(value(6), '55');
        await tester.enterText(find.byType(TextField).at(1), '11');
        expect(value(4), '7');
        expect(value(7), '11');
        await tester.enterText(find.byType(TextField).at(2), '3');
        await tester.enterText(find.byType(TextField).at(0), '60');
        await tester.enterText(find.byType(TextField).at(1), '12');
        expect(value(3), '40');
        expect(value(7), '11');
        expect(value(5), template ? '1.0' : '');
        await tester.tap(find.byIcon(Icons.arrow_back));
        await settle(tester);
        await tester.tap(find.text('Open'));
        await settle(tester);
        // A pre-existing draft wins over automatic template import; cancel replacement.
        if (template) {
          await tester.tap(find.text('Cancel'));
          await settle(tester);
        }
        await tester.enterText(find.byType(TextField).at(0), '70');
        expect(value(3), '40');
        expect(value(6), '55');
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await settle(tester);
        if (template) {
          final history = (await repo.listWorkoutHistory()).single;
          expect(history.exercises.single.sets[0].weightValue, 40);
          expect(history.exercises.single.sets[1].weightText, 'band');
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
