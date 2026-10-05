import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/settings/presentation/settings_page.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  for (final language in ['en', 'zh']) {
    testWidgets(
      'Settings opens bundled manual and switches language offline ($language)',
      (tester) async {
        // Asset futures must not retain the previous test's fake-async zone.
        rootBundle.evict('docs/USER_GUIDE.md');
        rootBundle.evict('docs/USER_GUIDE.zh-CN.md');
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final l = lookupAppLocalizations(Locale(language));
        Future<void> settle() async {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pumpAndSettle();
        }

        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: SettingsPage(
              database: db,
              locale: Locale(language),
              onLocaleChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(l.userManual),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.userManual));
        await settle();
        final section = language == 'zh' ? '饮食记录与快捷添加' : 'Meals and nutrition';
        await tester.scrollUntilVisible(
          find.text(section),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(section));
        await tester.pumpAndSettle();
        expect(find.byType(SelectableText), findsWidgets);
        expect(tester.takeException(), isNull);
        final other = language == 'zh' ? 'English' : '简体中文';
        await tester.tap(find.text(other));
        await settle();
        await tester.scrollUntilVisible(
          find.text(language == 'zh' ? 'Install and start' : '安装与开始使用'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(
          find.text(language == 'zh' ? 'Install and start' : '安装与开始使用'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  test(
    'both shipped manuals cover all modules and data-safety limitations',
    () {
      for (final path in ['docs/USER_GUIDE.md', 'docs/USER_GUIDE.zh-CN.md']) {
        final text = File(path).readAsStringSync();
        expect(text, contains('1.2'));
        expect(text, contains('P/C/F'));
        expect(text, contains('PR'));
        expect(text, contains('JSON'));
        expect(
          text.split(RegExp(r'^## ', multiLine: true)).length,
          greaterThan(8),
        );
      }
    },
  );
}
