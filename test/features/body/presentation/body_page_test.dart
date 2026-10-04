import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/body/data/body_repository.dart';
import 'package:logria/features/body/presentation/body_page.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  testWidgets('body history renders a chart and opens a single-metric editor', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = BodyRepository(db);
    final today = DateUtils.dateOnly(DateTime.now());
    await tester.runAsync(() async {
      final day = await repo.loadDay(today);
      await repo.saveDay(today.subtract(const Duration(days: 3)), {
        day.types.first.id: 81,
      });
      await repo.saveDay(today, {day.types.first.id: 80});
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BodyPage(database: db)),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final weightTile = find.widgetWithText(ListTile, 'Weight').first;
    expect(
      find.descendant(of: weightTile, matching: find.text('80 kg')),
      findsOneWidget,
    );
    await tester.tap(weightTile);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Trends & history'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
