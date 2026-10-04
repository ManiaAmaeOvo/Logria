import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/calendar/presentation/calendar_page.dart';
import 'package:logria/features/nutrition/data/nutrition_repository.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'changing month and selecting a date copies that date, not today',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final now = DateTime.now();
      final older = DateTime(now.year, now.month - 1, 28);
      final dateKey = DateFormat('yyyy-MM-dd').format(older);
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.runAsync(() async {
        final repo = NutritionRepository(db);
        await repo.addFoodEntry(now, 'Today meal');
        await repo.addFoodEntry(older, 'Historical meal');
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: CalendarPage(database: db)),
        ),
      );
      Future<void> settle() async {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
      }

      await settle();
      await tester.tap(find.byTooltip('Previous month'));
      await settle();
      final cell = find.byKey(ValueKey('calendar-$dateKey'));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      await settle();
      await tester.ensureVisible(find.text("Copy this date's log"));
      await tester.tap(find.text("Copy this date's log"));
      await settle();
      expect(copied, contains(dateKey));
      expect(copied, contains('Historical meal'));
      expect(copied, isNot(contains('Today meal')));
      expect(copied, contains('No body measurements recorded on this date.'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
