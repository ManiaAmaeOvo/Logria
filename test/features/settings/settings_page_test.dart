import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/app/logria_app.dart';
import 'package:logria/core/app_metadata.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/settings/presentation/settings_page.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  test('About version matches the APK source version', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('version: ${AppMetadata.version}+${AppMetadata.build}'),
    );
  });

  testWidgets(
    'language choice persists and is restored when the app restarts',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      Locale? selected;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SettingsPage(
            database: db,
            locale: null,
            onLocaleChanged: (value) => selected = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('简体中文'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('简体中文'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(selected, const Locale('zh'));
      final setting = await tester.runAsync(
        () => (db.select(
          db.appSettings,
        )..where((row) => row.keyName.equals('app.locale'))).getSingle(),
      );
      expect(setting!.value, 'zh');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(LogriaApp(database: db));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('今日'), findsOneWidget);
      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('ManiaAmaeOvo · gpt6.1sol'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('ManiaAmaeOvo · gpt6.1sol'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('v${AppMetadata.version} (${AppMetadata.build})'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('v${AppMetadata.version} (${AppMetadata.build})'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
