import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/nutrition/data/food_preset_repository.dart';
import 'package:logria/features/nutrition/domain/nutrient_values.dart';
import 'package:logria/features/nutrition/presentation/food_library_page.dart';
import 'package:logria/l10n/app_localizations.dart';

Future<void> settleFood(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 70)),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['en', 'zh']) {
    testWidgets(
      'preset editor binds kJ/kcal and preserves label energy ($language)',
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
        final l = lookupAppLocalizations(Locale(language));
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FoodPresetEditorPage(repository: repo),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await settleFood(tester);
        final controllers = <String, TextEditingController>{};
        Future<void> enter(String key, String value) async {
          FocusManager.instance.primaryFocus?.unfocus();
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
          final field = find.byKey(ValueKey(key));
          await tester.scrollUntilVisible(
            field,
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          controllers[key] = tester.widget<TextField>(field).controller!;
          await tester.enterText(field, value);
          await tester.pump();
        }

        String text(String key) {
          final finder = find.byKey(ValueKey(key));
          if (finder.evaluate().isNotEmpty) {
            controllers[key] = tester.widget<TextField>(finder).controller!;
          }
          return controllers[key]!.text;
        }

        await enter('food-preset-name', 'Protein powder');
        await enter('food-reference-quantity', '30');
        await enter('preset-protein', '20');
        await enter('preset-carbohydrate', '3');
        await enter('preset-fat', '2');
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('preset-calories')),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(text('preset-calories'), '110');
        await enter('preset-kilojoules', '418.4');
        expect(text('preset-calories'), '100');
        await enter('preset-protein', '25');
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('preset-calories')),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(text('preset-calories'), '100');
        await enter('preset-calories', '120');
        expect(text('preset-kilojoules'), '502.08');
        await enter('preset-sodium', '80');
        await tester.scrollUntilVisible(
          find.text(l.save),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(l.save));
        await settleFood(tester);
        final custom = (await repo.list()).singleWhere((p) => !p.isBuiltIn);
        expect(custom.referenceQuantity, 30);
        expect(custom.unit, 'g');
        expect(decodeNutrients(custom.nutrientsJson)['protein'], 25);
        expect(decodeNutrients(custom.nutrientsJson)['calories'], 120);
        expect(custom.caloriesEstimated, isFalse);
        expect(decodeNutrients(custom.nutrientsJson)['sodium'], 80);
        expect(
          decodeNutrients(custom.nutrientsJson).containsKey('iron'),
          isFalse,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
    testWidgets('quantity preview and food list fit larger $language text', (
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
      final food = (await FoodPresetRepository(
        db,
      ).list()).firstWhere((p) => p.id == 'usda:171077');
      final l = lookupAppLocalizations(Locale(language));
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Builder(
              builder: (c) => TextButton(
                onPressed: () => showDialog(
                  context: c,
                  builder: (_) => FoodQuantityDialog(preset: food),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('food-quantity')),
        '150',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('33.75'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('67.5'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('67.5'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: FoodLibraryPage(database: db, date: DateTime(2026, 10, 5)),
        ),
      );
      await settleFood(tester);
      await tester.enterText(find.byType(TextField), 'Chicken');
      FocusManager.instance.primaryFocus?.unfocus();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(foodName(food, l)),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text(foodName(food, l)), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
