import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/nutrition/data/nutrition_repository.dart';
import 'package:logria/features/today/presentation/today_page.dart';
import 'package:logria/features/today/data/today_repository.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  testWidgets('copy uses fresh logs and supports individual sections', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final copied = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    int? opened;
    await tester.runAsync(() async {
      await NutritionRepository(db).loadDay(DateTime.now());
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: TodayPage(
            database: db,
            onOpenModule: (index) => opened = index,
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('daily-review')),
      'Today felt strong',
    );
    await tester.tap(find.text('Save'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(
      (await TodayRepository(db).loadDay(DateTime.now())).note,
      'Today felt strong',
    );
    await tester.runAsync(() async {
      await NutritionRepository(db).addFoodEntry(DateTime.now(), 'Fresh meal');
    });
    await tester.tap(find.text("Copy today's log"));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(copied.single, contains('Fresh meal'));
    expect(copied.single, contains('Today felt strong'));
    expect(copied.single, contains('Fitness'));
    expect(copied.single, contains('Body'));
    await tester.ensureVisible(find.byTooltip('Copy Nutrition'));
    await tester.tap(find.byTooltip('Copy Nutrition'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(copied.last, startsWith('Nutrition · '));
    expect(copied.last, isNot(contains('No training')));
    await tester.tap(find.byTooltip('Open Nutrition'));
    expect(opened, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
