import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/core/record_day.dart';
import 'package:logria/features/nutrition/data/nutrition_repository.dart';
import 'package:logria/features/nutrition/domain/meal_ingredient.dart';
import 'package:logria/features/today/data/today_repository.dart';
import 'package:logria/features/today/presentation/today_log_formatter.dart';
import 'package:logria/features/today/presentation/today_page.dart';
import 'package:logria/l10n/app_localizations.dart';

const ingredients = [
  MealIngredient(
    presetId: 'rice',
    name: 'Rice|饭',
    unit: 'g',
    quantity: 100,
    nutrients: {
      'protein': 2.69,
      'carbohydrate': 28.17,
      'fat': .28,
      'calories': 130,
      'sodium': 1,
    },
  ),
  MealIngredient(
    presetId: 'chicken',
    name: 'Chicken\n鸡胸',
    unit: 'g',
    quantity: 100,
    nutrients: {
      'protein': 22.5,
      'carbohydrate': 0,
      'fat': 2.62,
      'calories': 120,
    },
  ),
];

Future<void> seed(AppDatabase db) async {
  final nutrition = NutritionRepository(db);
  await nutrition.addFoodEntry(
    RecordDay.today(),
    'Lunch',
    proteinGrams: 30,
    carbohydrateGrams: 40,
    fatGrams: 5,
    caloriesKcal: 280,
    caloriesEstimated: false,
    mealItemsJson: jsonEncode(ingredients.map((i) => i.toJson()).toList()),
  );
  await nutrition.addFoodEntry(RecordDay.today(), 'Legacy note');
  await nutrition.saveDailyIntake(
    date: RecordDay.today(),
    proteinGrams: 160,
    carbohydrateGrams: 200,
    fatGrams: 60,
    caloriesKcal: 2000,
  );
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('zh');
  });
  for (final language in ['en', 'zh']) {
    final l = lookupAppLocalizations(Locale(language));
    test(
      'ingredient rows preserve snapshots and manually edited totals ($language)',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await seed(db);
        final before = (await db.select(db.foodLogEntries).get())
            .map((e) => e.toJson())
            .toList();
        final f = TodayLogFormatter(
          await TodayRepository(db).loadDay(RecordDay.today()),
          l,
        );
        final rows = f.foodRows;
        expect(rows, hasLength(5));
        final meal = rows.indexWhere(
          (r) => r.first.contains(l.mealRecordedSubtotal),
        );
        expect(meal, greaterThanOrEqualTo(0));
        expect(rows[meal].sublist(1, 5), ['30', '40', '5', '280']);
        expect(rows[meal + 1].first, '↳ Rice|饭 · 100 g');
        expect(rows[meal + 1].sublist(1), [
          '2.69',
          '28.17',
          '0.28',
          '130',
          '1',
        ]);
        expect(rows[meal + 2].first, '↳ Chicken\n鸡胸 · 100 g');
        expect(rows[meal + 2].sublist(1), ['22.5', '0', '2.62', '120', '—']);
        expect(
          rows.singleWhere((r) => r.first.contains('Legacy note')).sublist(1),
          everyElement('—'),
        );
        expect(rows.last.first, contains(l.manualTotalLabel));
        expect(rows.last.sublist(1, 5), ['160', '200', '60', '2000']);
        expect(rows.every((r) => r.length == f.foodColumns.length), isTrue);
        expect(
          f.food,
          contains('| ↳ Rice\\|饭 · 100 g | 2.69 | 28.17 | 0.28 | 130 | 1 |'),
        );
        expect(
          f.food,
          contains('| ↳ Chicken<br>鸡胸 · 100 g | 22.5 | 0 | 2.62 | 120 | — |'),
        );
        expect(f.food, contains(l.mealIngredientTableHint));
        expect(
          (await db.select(db.foodLogEntries).get())
              .map((e) => e.toJson())
              .toList(),
          before,
        );
      },
    );

    testWidgets(
      'Today table and clipboard show ingredients separately on a narrow phone ($language)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await seed(db);
        String? clipboard;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: TodayPage(database: db, onOpenModule: (_) {}),
            ),
          ),
        );
        await settle(tester);
        await tester.scrollUntilVisible(
          find.byTooltip(l.copyTodaySection(l.nutrition)),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final table = tester.widget<DataTable>(find.byType(DataTable));
        expect(table.rows, hasLength(5));
        expect(find.byTooltip('↳ Rice|饭 · 100 g'), findsOneWidget);
        expect(find.byTooltip('↳ Chicken\n鸡胸 · 100 g'), findsOneWidget);
        await tester.tap(find.byTooltip(l.copyTodaySection(l.nutrition)));
        await settle(tester);
        expect(clipboard, contains('| ↳ Rice\\|饭 · 100 g | 2.69 |'));
        expect(clipboard, contains('| ↳ Chicken<br>鸡胸 · 100 g | 22.5 |'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
