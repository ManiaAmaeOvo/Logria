import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/fitness/presentation/historical_fitness_page.dart';
import 'package:logria/l10n/app_localizations.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final lang in ['en', 'zh']) {
    testWidgets(
      'historical editor fits larger $lang text and saves only selected date',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = FitnessRepository(
          db,
          clock: () => DateTime(2026, 10, 7, 12),
        );
        await tester.runAsync(
          () => repo.activateTemplate(builtInTrainingPlanTemplates.first),
        );
        final l = lookupAppLocalizations(Locale(lang));
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: HistoricalFitnessPage(
              repository: repo,
              date: DateTime(2026, 10, 5),
            ),
          ),
        );
        await settle(tester);
        await settle(tester);
        expect(find.text(l.defaultRest), findsOneWidget);
        expect(find.text(l.historyRest), findsOneWidget);
        expect(find.text(l.restRecorded), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text(l.save),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('save-historical-fitness')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.save));
        await settle(tester);
        expect(find.text(l.replaceDateFitnessWarning), findsOneWidget);
        await tester.tap(find.text(l.cancel));
        await settle(tester);
        expect(await repo.actionsOnDate(DateTime(2026, 10, 5)), isEmpty);
        await tester.tap(find.text(l.save));
        await settle(tester);
        await tester.tap(find.text(l.continueLabel));
        await settle(tester);
        final action = (await repo.actionsOnDate(DateTime(2026, 10, 5))).single;
        expect(action.executionType, 'extraRest');
        expect(await repo.actionsOnDate(DateTime(2026, 10, 7)), isEmpty);
        expect((await repo.loadDashboard())!.progress.consumedDayIds, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
