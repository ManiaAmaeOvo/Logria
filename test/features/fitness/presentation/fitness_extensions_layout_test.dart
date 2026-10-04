import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/presentation/fitness_extras_page.dart';
import 'package:logria/features/fitness/presentation/workout_editor_page.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  for (final language in ['en', 'zh']) {
    testWidgets('PR, cardio and text weights fit large $language text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = FitnessRepository(db);
      await repo.activateTemplate(builtInTrainingPlanTemplates.first);
      await repo.trackExercise('Bench press', true);
      await repo.addPr('Bench press', DateTime(2026, 9, 1), 40, 8);
      await repo.addPr('Bench press', DateTime(2026, 10, 1), 50, 4);
      await repo.saveCardio(
        date: DateTime.now(),
        activity: 'Running',
        minutes: 30,
        distance: 5,
      );
      final dashboard = (await repo.loadDashboard())!;
      await repo.completeWorkout(dashboard, const [
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
          ],
        ),
      ]);
      final current = (await repo.loadDashboard())!;
      Future<void> show(Widget page) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: page,
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();
      }

      await show(FitnessExtrasPage(repository: repo, cardio: false));
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await show(FitnessExtrasPage(repository: repo, cardio: true));
      await tester.tap(find.text(language == 'en' ? 'Add cardio' : '添加有氧'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(language == 'en' ? 'Cancel' : '取消'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await show(
        WorkoutEditorPage(
          repository: repo,
          dashboard: current,
          existingWorkout: current.todayWorkout,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(DropdownButtonFormField<bool>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<bool>));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
