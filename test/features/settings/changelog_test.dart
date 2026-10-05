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
      'offline changelog follows system and live app locale ($language)',
      (tester) async {
        rootBundle.evict('CHANGELOG.md');
        rootBundle.evict('CHANGELOG.zh-CN.md');
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        tester.platformDispatcher.localesTestValue = [Locale(language)];
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final locale = ValueNotifier<Locale?>(null);
        addTearDown(locale.dispose);
        Future<void> settle() async {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pumpAndSettle();
        }

        await tester.pumpWidget(
          ValueListenableBuilder<Locale?>(
            valueListenable: locale,
            builder: (_, value, _) => MaterialApp(
              locale: value,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: SettingsPage(
                database: db,
                locale: value,
                onLocaleChanged: (v) => locale.value = v,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = lookupAppLocalizations(Locale(language));
        await tester.scrollUntilVisible(
          find.text(l.changelog),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.changelog));
        await settle();
        final title = language == 'zh'
            ? '尚未发布 — 本地 Android build 8'
            : 'Unreleased — local Android build 8';
        expect(find.text(title), findsOneWidget);
        expect(find.byType(SegmentedButton<String>), findsNothing);
        const oldTitle = '1.1.0 — 2026-10-04';
        await tester.scrollUntilVisible(
          find.text(oldTitle),
          220,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(oldTitle));
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is SelectableText &&
                (w.data?.contains(language == 'zh' ? '外键约束' : 'foreign-key') ??
                    false),
          ),
          findsOneWidget,
        );
        final other = language == 'zh' ? 'en' : 'zh';
        locale.value = Locale(other);
        await tester.pump();
        await settle();
        expect(find.text(other == 'zh' ? '更新日志' : 'Changelog'), findsOneWidget);
        final otherTitle = other == 'zh'
            ? '尚未发布 — 本地 Android build 8'
            : 'Unreleased — local Android build 8';
        expect(find.text(otherTitle), findsOneWidget);
        expect(tester.getTopLeft(find.text(otherTitle)).dy, lessThan(650));
        expect(find.text(title), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  test('Chinese reader docs exist, link correctly and cover all changelog versions', () {
    final paths = [
      'README.zh-CN.md',
      'CHANGELOG.zh-CN.md',
      'CONTRIBUTING.zh-CN.md',
      'docs/USER_GUIDE.zh-CN.md',
      'docs/PRIVACY.zh-CN.md',
      'docs/FOOD_DATA.zh-CN.md',
      'docs/TESTING.zh-CN.md',
    ];
    for (final path in paths) {
      final file = File(path);
      final text = file.readAsStringSync();
      expect(text, isNotEmpty);
      for (final match in RegExp(r'\[[^\]]+\]\(([^)]+)\)').allMatches(text)) {
        final target = match[1]!;
        if (target.startsWith('http') || target.startsWith('#')) continue;
        expect(
          File('${file.parent.path}/$target').existsSync(),
          isTrue,
          reason: '$path → $target',
        );
      }
    }
    final english = File('CHANGELOG.md').readAsStringSync();
    final chinese = File('CHANGELOG.zh-CN.md').readAsStringSync();
    for (final version in ['1.0.0', '1.1.0', '1.2.0']) {
      expect(english, contains('## $version'));
      expect(chinese, contains('## $version'));
    }
    expect(chinese, contains('build 8'));
  });
}
