import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/fitness/presentation/fitness_page.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  for (final language in ['en', 'zh']) {
    testWidgets(
      'starting day and redo controls work with large $language text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = FitnessRepository(db);
        await repo.activateTemplate(builtInTrainingPlanTemplates[1]);
        Future<void> settle() async {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)),
          );
          await tester.pumpAndSettle();
        }

        Widget app(Key key) => MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FitnessPage(key: key, database: db),
          ),
        );
        await tester.pumpWidget(app(const ValueKey('start')));
        await settle();
        // Cancel is harmless; confirmation opens a fresh selectable cycle.
        final restart = find.text(
          language == 'en' ? 'Restart training cycle' : '重新开始训练轮次',
        );
        await tester.tap(find.byType(PopupMenuButton<String>));
        await settle();
        await tester.tap(restart);
        await settle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(language == 'en' ? 'Cancel' : '取消'));
        await settle();
        expect((await repo.loadDashboard())!.cycle.cycleNumber, 1);
        await tester.tap(find.byType(PopupMenuButton<String>));
        await settle();
        await tester.tap(restart);
        await settle();
        await tester.tap(
          find.descendant(of: find.byType(AlertDialog), matching: restart).last,
        );
        await settle();
        expect((await repo.loadDashboard())!.cycle.cycleNumber, 2);
        expect((await repo.loadDashboard())!.canChooseStart, isTrue);
        expect(tester.takeException(), isNull);
        final choose = find.text(
          language == 'en' ? 'Choose starting day' : '选择起始训练日',
        );
        await tester.tap(choose);
        await settle();
        expect(tester.takeException(), isNull);
        final sheet = find.byType(BottomSheet);
        final push2 = find.descendant(of: sheet, matching: find.text('Push 2'));
        await tester.scrollUntilVisible(
          push2,
          150,
          scrollable: find
              .descendant(of: sheet, matching: find.byType(Scrollable))
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(push2);
        await settle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(language == 'en' ? 'Save' : '保存'));
        await settle();
        expect((await repo.loadDashboard())!.progress.nextDay!.name, 'Push 2');
        expect(tester.takeException(), isNull);
        await repo.takeRest();
        await repo.undoLatestFitnessActionToday();
        await tester.pumpWidget(app(const ValueKey('redo')));
        await settle();
        final redo = find.text(
          language == 'en' ? "Restore today's action" : '恢复今日操作',
        );
        await tester.scrollUntilVisible(
          redo,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(redo);
        await settle();
        expect((await repo.loadDashboard())!.hasActionToday, isTrue);
        expect((await repo.loadDashboard())!.canRedo, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
