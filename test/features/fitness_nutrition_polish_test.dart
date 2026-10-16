import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/fitness/presentation/fitness_page.dart';
import 'package:logria/features/nutrition/data/nutrition_repository.dart';
import 'package:logria/features/nutrition/presentation/food_equivalence_hint.dart';
import 'package:logria/l10n/app_localizations.dart';

Widget app(Widget page, String language) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: page),
);

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

NutritionDayData day({double? protein, double? carbs, bool limit = false}) =>
    NutritionDayData(
      localDate: '2026-10-16',
      foodEntries: const [],
      record: DailyNutritionRecord(
        id: 'test',
        localDate: '2026-10-16',
        source: 'manual',
        proteinGrams: protein,
        carbohydrateGrams: carbs,
        updatedAt: DateTime(2026, 10, 16),
      ),
      targets: NutritionTargets(
        proteinGoalGrams: 100,
        carbohydrateGoalGrams: 100,
        proteinIsLimit: limit,
        carbohydrateIsLimit: limit,
      ),
    );

void main() {
  for (final language in ['en', 'zh']) {
    final l = lookupAppLocalizations(Locale(language));
    for (final action in ['workout', 'rest', 'skip']) {
      testWidgets(
        'locked $action shows pending day, no dead actions ($language)',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = AppDatabase(NativeDatabase.memory());
          addTearDown(db.close);
          final repo = FitnessRepository(db);
          await repo.activateTemplate(builtInTrainingPlanTemplates.first);
          final dashboard = (await repo.loadDashboard())!;
          if (action == 'workout') {
            await repo.completeWorkout(dashboard, const [
              WorkoutDraftExercise(
                name: 'Bench',
                saveAsPreset: false,
                sets: [WorkoutDraftSet(weight: 40, reps: 8, rir: null)],
              ),
            ]);
          } else if (action == 'rest') {
            await repo.takeRest();
          } else {
            await repo.skipCurrentTraining();
          }
          await tester.pumpWidget(app(FitnessPage(database: db), language));
          await settle(tester);
          final toolbar = [l.prTitle, l.cardioTitle, l.toolbarBackfill]
              .map(
                (s) => tester.getRect(find.widgetWithText(OutlinedButton, s)),
              )
              .toList();
          expect(toolbar[0].width, closeTo(toolbar[1].width, .1));
          expect(toolbar[1].width, closeTo(toolbar[2].width, .1));
          expect(toolbar[1].left - toolbar[0].right, closeTo(8, .1));
          expect(toolbar[2].left - toolbar[1].right, closeTo(8, .1));
          expect(toolbar.map((r) => r.top).toSet(), hasLength(1));
          await tester.scrollUntilVisible(
            find.text(l.nextPlannedDay),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          expect(find.text(l.current), findsNothing);
          expect(find.text(l.startWorkout), findsNothing);
          expect(find.text(l.takeRest), findsNothing);
          expect(find.text(l.skipTrainingDay), findsNothing);
          expect(find.text(l.nextPlannedDayHint), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
    for (final limit in [false, true]) {
      testWidgets(
        'food equivalents use known intake and target mode ($language/$limit)',
        (tester) async {
          await tester.pumpWidget(
            app(
              FoodEquivalenceHint(
                day: day(protein: 77.5, carbs: 71.83, limit: limit),
              ),
              language,
            ),
          );
          expect(find.text(l.foodEquivalenceRice('100')), findsOneWidget);
          expect(
            find.text(l.foodEquivalenceProtein('3.6', '100')),
            findsOneWidget,
          );
          final label = limit
              ? l.foodEquivalenceLimit('22.5', l.foodEquivalenceProteinLabel)
              : l.foodEquivalenceGoal('22.5', l.foodEquivalenceProteinLabel);
          expect(find.text(label), findsOneWidget);
          expect(find.text(l.foodEquivalenceBasis), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets(
      'unknown, met or exceeded intake never suggests extra food ($language)',
      (tester) async {
        for (final data in [
          day(),
          day(protein: 100, carbs: 110),
          day(protein: 101, carbs: 100, limit: true),
        ]) {
          await tester.pumpWidget(
            app(FoodEquivalenceHint(day: data), language),
          );
          expect(find.text(l.foodEquivalenceTitle), findsNothing);
        }
        await tester.pumpWidget(
          app(FoodEquivalenceHint(day: day(protein: 0)), language),
        );
        expect(find.text(l.foodEquivalenceTitle), findsOneWidget);
        expect(find.text(l.foodEquivalenceRice('355')), findsNothing);
      },
    );
  }
}
