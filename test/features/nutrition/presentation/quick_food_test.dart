import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/core/number_format.dart';
import 'package:logria/features/nutrition/data/food_preset_repository.dart';
import 'package:logria/features/nutrition/data/nutrition_repository.dart';
import 'package:logria/features/nutrition/presentation/nutrition_page.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  for (final language in ['en', 'zh']) {
    testWidgets(
      'quick food: cancel, search, selected date and precision ($language)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = FoodPresetRepository(db);
        await tester.runAsync(
          () => repo.save(
            name: 'Test yogurt',
            unit: 'g',
            referenceQuantity: 100,
            preparation: 'packaged',
            estimated: false,
            nutrients: {'protein': 10.123456789, 'calories': 123.456789},
          ),
        );
        final l = lookupAppLocalizations(Locale(language));
        Future<void> settle() async {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 70)),
          );
          await tester.pumpAndSettle();
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
        await tester.tap(find.byTooltip(l.previousDay));
        await settle();
        final now = DateTime.now();
        final date = DateTime(now.year, now.month, now.day - 1);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('quick-add-food')),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        Future<void> open() async {
          await tester.tap(find.byKey(const ValueKey('quick-add-food')));
          await settle();
        }

        await open();
        await tester.tap(find.text(l.cancel));
        await settle();
        await open();
        await tester.enterText(
          find.byKey(const ValueKey('quick-food-search')),
          'no such food',
        );
        await tester.pumpAndSettle();
        expect(find.text(l.noFoodMatches), findsOneWidget);
        // Simulate a visible keyboard on the small screen.
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tester.enterText(
          find.byKey(const ValueKey('quick-food-search')),
          'yogurt',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Test yogurt'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.cancel));
        await settle();
        expect(
          await tester.runAsync(() => db.select(db.foodLogEntries).get()),
          isEmpty,
        );
        await open();
        await tester.tap(find.text('Test yogurt'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('food-quantity')),
          '33.3333333',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final expected = 10.123456789 * 33.3333333 / 100;
        expect(find.textContaining(formatNumber(expected)), findsWidgets);
        await tester.tap(find.text(l.addFoodNote));
        await settle();
        final day = await tester.runAsync(
          () => NutritionRepository(db).loadDay(date),
        );
        expect(day!.foodEntries, hasLength(1));
        expect(day.foodEntries.single.proteinGrams, closeTo(expected, 1e-10));
        expect(day.foodEntries.single.quantity, 33.3333333);
        expect(day.foodEntries.single.textContent, contains('33.3333'));
        expect(
          await tester
              .runAsync(() => NutritionRepository(db).loadDay(now))
              .then((v) => v!.foodEntries),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
