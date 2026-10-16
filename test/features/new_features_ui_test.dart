import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/core/document_files.dart';
import 'package:logria/core/record_day.dart';
import 'package:logria/features/backup/data/backup_repository.dart';
import 'package:logria/features/backup/presentation/backup_page.dart';
import 'package:logria/features/body/presentation/sleep_card.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/fitness/presentation/workout_editor_page.dart';
import 'package:logria/features/nutrition/data/food_preset_repository.dart';
import 'package:logria/features/nutrition/domain/meal_ingredient.dart';
import 'package:logria/features/nutrition/presentation/nutrition_page.dart';
import 'package:logria/features/today/data/today_repository.dart';
import 'package:logria/l10n/app_localizations.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

Widget app(Widget home, String lang) => MaterialApp(
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

void main() {
  for (final language in ['en', 'zh']) {
    testWidgets(
      'per-set notes, free RIR and arithmetic survive draft and save ($language)',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = FitnessRepository(db);
        await repo.activateTemplate(builtInTrainingPlanTemplates.first);
        final dashboard = (await repo.loadDashboard())!;
        final preset = await repo.createExercisePreset('Bench');
        await repo.addPlanExercise(
          planDayId: dashboard.planDays.first.id,
          exerciseId: preset,
          targetSets: 1,
          targetRepsMin: 8,
          targetRepsMax: 12,
        );
        final planned = (await repo.loadPlanExercises(
          dashboard.planDays,
        ))[dashboard.planDays.first.id]!;
        final l = lookupAppLocalizations(Locale(language));
        await tester.pumpWidget(
          app(
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
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
            language,
          ),
        );
        await tester.tap(find.text('Open'));
        await settle(tester);
        await tester.enterText(find.byType(TextField).at(0), 'band');
        await tester.pump();
        final dropdown = find.byWidgetPredicate(
          (w) => w is DropdownButtonFormField<bool>,
        );
        expect(tester.getSize(dropdown).height, lessThan(80));
        await tester.enterText(find.byType(TextField).at(0), '20+2.5*2');
        await tester.enterText(find.byType(TextField).at(1), '16/2');
        await tester.enterText(find.byType(TextField).at(2), '约 2–3');
        await tester.ensureVisible(find.text(l.setNote));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.setNote));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          'Last rep slow',
        );
        await tester.tap(find.text(l.save));
        await settle(tester);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await settle(tester);
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        await tester.tap(find.text('Open'));
        await settle(tester);
        expect(find.text('约 2–3'), findsOneWidget);
        expect(find.text('Last rep slow'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text(l.finishSaveWorkout),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.finishSaveWorkout));
        await settle(tester);
        final set = await db.select(db.workoutSets).getSingle();
        expect(set.rirText, '约 2–3');
        expect(set.notes, 'Last rep slow');
        expect(set.weightValue, 25);
        expect(set.reps, 8);
        expect(await db.select(db.exercises).get(), hasLength(1));
        expect((await db.select(db.exercises).getSingle()).notes, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'one meal combines several foods with formula amounts and a note ($language)',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final foods = FoodPresetRepository(db);
        await foods.save(
          name: 'Whey',
          unit: 'g',
          referenceQuantity: 30,
          preparation: 'packaged',
          nutrients: {'protein': 24, 'calories': 120},
          estimated: false,
        );
        await foods.save(
          name: 'Yogurt',
          unit: 'g',
          referenceQuantity: 100,
          preparation: 'packaged',
          nutrients: {'protein': 10, 'calories': 60},
          estimated: false,
        );
        final l = lookupAppLocalizations(Locale(language));
        await tester.pumpWidget(
          app(Scaffold(body: NutritionPage(database: db)), language),
        );
        await settle(tester);
        await tester.scrollUntilVisible(
          find.byTooltip(l.addFoodNote),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(l.addFoodNote));
        await settle(tester);
        for (final (name, amount) in [('Whey', '15*2'), ('Yogurt', '100+50')]) {
          await tester.ensureVisible(find.text(l.addIngredient));
          await tester.pumpAndSettle();
          await tester.tap(find.text(l.addIngredient));
          await settle(tester);
          await tester.enterText(
            find.byKey(const ValueKey('quick-food-search')),
            name,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(name).last);
          await settle(tester);
          await tester.enterText(
            find.byKey(const ValueKey('food-quantity')),
            amount,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(l.addFoodNote).last);
          await settle(tester);
        }
        final note = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == l.foodLog,
        );
        await tester.ensureVisible(note);
        await tester.pumpAndSettle();
        await tester.enterText(note, 'Post-workout snack');
        expect(await db.select(db.foodLogEntries).get(), isEmpty);
        await tester.tap(find.text(l.save));
        await settle(tester);
        final meal = await db.select(db.foodLogEntries).getSingle();
        expect(meal.textContent, 'Post-workout snack');
        expect(meal.proteinGrams, 39);
        expect(meal.caloriesKcal, 210);
        expect(MealIngredient.decode(meal.mealItemsJson), hasLength(2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'backup picker cancellation and restore confirmation do not change records ($language)',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await TodayRepository(db)
            .saveNote(RecordDay.key(RecordDay.today()), 'Original');
        final backup = await BackupRepository(db).create();
        var opening = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              DocumentFiles.channel,
              (call) async => call.method == 'open' && opening ? backup : null,
            );
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(DocumentFiles.channel, null),
        );
        final l = lookupAppLocalizations(Locale(language));
        await tester.pumpWidget(app(BackupPage(database: db), language));
        await tester.tap(find.text(l.backupCreate));
        await settle(tester);
        expect(find.text(l.fileSaved), findsNothing);
        opening = true;
        await tester.tap(find.text(l.backupRestore));
        await settle(tester);
        expect(find.textContaining(l.restoreWarning), findsOneWidget);
        await tester.tap(find.text(l.cancel));
        await settle(tester);
        expect(
          (await TodayRepository(db).loadDay(RecordDay.today())).note,
          'Original',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'sleep card records an overnight interval and notes ($language)',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final l = lookupAppLocalizations(Locale(language));
        await tester.pumpWidget(
          app(
            Scaffold(
              body: SleepCard(database: db, date: RecordDay.today()),
            ),
            language,
          ),
        );
        await settle(tester);
        await tester.tap(find.byTooltip(l.sleep));
        await settle(tester);
        await tester.enterText(find.byType(TextField), 'Slept well');
        await tester.tap(find.text(l.save));
        await settle(tester);
        expect((await db.select(db.sleepLogs).getSingle()).notes, 'Slept well');
        expect(find.textContaining('8 h'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
