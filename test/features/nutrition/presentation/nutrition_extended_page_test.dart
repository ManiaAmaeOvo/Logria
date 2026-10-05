import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/nutrition/data/nutrition_repository.dart';
import 'package:logria/features/nutrition/domain/nutrient_values.dart';
import 'package:logria/features/nutrition/presentation/nutrition_page.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  for (final language in ['en', 'zh']) {
    testWidgets(
      'manual meal energy, extra nutrients and minimum targets ($language)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = NutritionRepository(db);
        final l = lookupAppLocalizations(Locale(language));
        Future<void> settle() async {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 70)),
          );
          await tester.pumpAndSettle();
        }

        Finder field(String label) => find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        Future<void> enter(String label, String value) async {
          await tester.ensureVisible(field(label));
          await tester.pumpAndSettle();
          await tester.enterText(field(label), value);
          await tester.pump();
        }

        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: NutritionPage(database: db)),
          ),
        );
        await settle();
        await tester.scrollUntilVisible(
          find.byTooltip(l.addFoodNote),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(l.addFoodNote));
        await tester.pumpAndSettle();
        await enter(l.foodLog, 'My meal');
        await enter(l.proteinGrams, '20');
        await enter(l.carbohydrateGrams, '5');
        await enter(l.fatGrams, '2');
        expect(
          tester.widget<TextField>(field(l.caloriesKcal)).controller!.text,
          '118',
        );
        await enter(l.energyKilojoules, '418.4');
        expect(
          tester.widget<TextField>(field(l.caloriesKcal)).controller!.text,
          '100',
        );
        await enter(l.proteinGrams, '25');
        expect(
          tester.widget<TextField>(field(l.caloriesKcal)).controller!.text,
          '100',
        );
        await tester.ensureVisible(find.text(l.extraNutrients).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.extraNutrients).last);
        await tester.pumpAndSettle();
        await enter('${l.nutrientSodium} (mg)', '350');
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(l.save));
        await settle();
        final meal = (await repo.loadDay(DateTime.now())).foodEntries.single;
        expect(meal.proteinGrams, 25);
        expect(meal.caloriesKcal, 100);
        expect(meal.caloriesEstimated, isFalse);
        expect(decodeNutrients(meal.extraNutrientsJson), {'sodium': 350});
        FocusManager.instance.primaryFocus?.unfocus();
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(l.setGoals),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.setGoals));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(l.extraNutrients).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.extraNutrients).last);
        await tester.pumpAndSettle();
        await enter('${l.nutrientSodium} (mg)', '2000');
        final mode = find.byType(DropdownButtonFormField<String>).first;
        await tester.ensureVisible(mode);
        await tester.pumpAndSettle();
        await tester.tap(mode);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.nutrientMinimum).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(l.save));
        await settle();
        final target = (await repo.loadDay(DateTime.now()))
            .targets
            .extraTargets['sodium']!;
        expect(target.value, 2000);
        expect(target.mode, 'minimum');
        expect(find.text(l.noNutritionGoals), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
