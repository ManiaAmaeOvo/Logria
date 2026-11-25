import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/core/record_day.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/fitness/presentation/workout_editor_page.dart';
import 'package:logria/features/fitness/presentation/plan_editor_page.dart';
import 'package:logria/l10n/app_localizations.dart';

Future<void> settle(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await t.pumpAndSettle();
}

Future<void> open(
  WidgetTester t,
  FitnessRepository repo,
  String language,
) async {
  final d = (await repo.loadDashboard())!;
  final planned =
      (await repo.loadPlanExercises(d.planDays))[d.progress.nextDay!.id] ?? [];
  await t.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (c) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) => WorkoutEditorPage(
                  repository: repo,
                  dashboard: d,
                  plannedExercises: planned,
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('Open'));
  await settle(t);
}

Future<String> draft(FitnessRepository repo, List<String> names) async {
  final d = (await repo.loadDashboard())!;
  final key =
      'fitness.draft.${RecordDay.key(repo.recordingDate)}.${d.progress.nextDay!.id}';
  await repo.writeSetting(
    key,
    jsonEncode([
      for (final name in names)
        {
          'name': name,
          'preset': false,
          'sets': [
            {
              'weight': '40',
              'reps': '8',
              'rir': '',
              'notes': '',
              'zero': false,
            },
          ],
        },
    ]),
  );
  return key;
}

void main() {
  for (final language in ['en', 'zh']) {
    final l = lookupAppLocalizations(Locale(language));
    for (final choice in ['template', 'log', 'cancel']) {
      testWidgets('empty day template offers explicit $choice ($language)', (
        t,
      ) async {
        t.view.physicalSize = const Size(360, 800);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = FitnessRepository(db);
        await repo.activateTemplate(builtInTrainingPlanTemplates.first);
        final day = (await repo.loadDashboard())!.progress.nextDay!.id;
        final key = await draft(repo, ['Bench']);
        await open(t, repo, language);
        await t.scrollUntilVisible(
          find.text(l.finishSaveWorkout),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await t.ensureVisible(find.text(l.finishSaveWorkout));
        await t.pumpAndSettle();
        await t.tap(find.text(l.finishSaveWorkout));
        await settle(t);
        expect(find.text(l.saveDayTemplateHint), findsOneWidget);
        final label = choice == 'template'
            ? l.saveDayTemplate
            : choice == 'log'
            ? l.workoutOnly
            : l.cancel;
        await t.tap(
          find
              .descendant(
                of: find.byType(AlertDialog),
                matching: find.text(label),
              )
              .last,
        );
        await settle(t);
        expect(await repo.hasDayTemplate(day), choice == 'template');
        expect(
          await db.select(db.workoutSessions).get(),
          hasLength(choice == 'cancel' ? 0 : 1),
        );
        expect(
          await repo.readSetting(key),
          choice == 'cancel' ? isNotNull : isNull,
        );
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      });
    }

    testWidgets(
      'per-exercise history copies loads/reps only and resets one-shot fill ($language)',
      (t) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        var now = DateTime(2026, 10, 30, 12);
        final repo = FitnessRepository(db, clock: () => now);
        await repo.activateTemplate(builtInTrainingPlanTemplates.first);
        await repo.completeWorkout((await repo.loadDashboard())!, const [
          WorkoutDraftExercise(
            name: 'Bench',
            saveAsPreset: true,
            sets: [
              WorkoutDraftSet(
                weight: 40,
                reps: 10,
                rir: '~2',
                notes: 'old feeling',
              ),
              WorkoutDraftSet(
                weight: null,
                weightText: 'bodyweight',
                reps: 8,
                rir: '1–2',
              ),
            ],
          ),
        ]);
        now = now.add(const Duration(days: 1));
        await repo.restartTrainingCycle();
        final d = (await repo.loadDashboard())!;
        final id = await repo.createExercisePreset('Bench');
        await repo.addPlanExercise(
          planDayId: d.progress.nextDay!.id,
          exerciseId: id,
          targetSets: 2,
          targetRepsMin: 8,
          targetRepsMax: 10,
        );
        await open(t, repo, language);
        await t.ensureVisible(find.text(l.useLastExercise));
        await t.pumpAndSettle();
        await t.tap(find.text(l.useLastExercise));
        await settle(t);
        String value(int i) =>
            t.widget<TextField>(find.byType(TextField).at(i)).controller!.text;
        expect(value(0), '40');
        expect(value(1), '10');
        expect(value(2), '');
        expect(value(3), 'bodyweight');
        expect(value(4), '8');
        expect(value(5), '');
        expect(find.text('old feeling'), findsNothing);
        await t.enterText(find.byType(TextField).at(0), '60');
        expect(value(3), '60');
        await t.enterText(find.byType(TextField).at(3), '70');
        await t.enterText(find.byType(TextField).at(0), '65');
        expect(value(3), '70');
        await t.ensureVisible(find.text(l.useLastExercise));
        await t.pumpAndSettle();
        await t.tap(find.text(l.useLastExercise));
        await settle(t);
        expect(find.text(l.replaceLastExerciseHint), findsOneWidget);
        await t.tap(find.text(l.cancel));
        await settle(t);
        expect(value(0), '65');
        expect(value(3), '70');
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('plan exercise drag persists without disturbing other days', (
    t,
  ) async {
    t.view.physicalSize = const Size(420, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = FitnessRepository(db);
    await repo.activateTemplate(builtInTrainingPlanTemplates.first);
    final d = (await repo.loadDashboard())!;
    const exercises = [
      WorkoutDraftExercise(
        name: 'Bench',
        saveAsPreset: true,
        sets: [WorkoutDraftSet(weight: 40, reps: 8, rir: null)],
      ),
      WorkoutDraftExercise(
        name: 'Row',
        saveAsPreset: true,
        sets: [WorkoutDraftSet(weight: 30, reps: 10, rir: null)],
      ),
    ];
    await repo.saveDayTemplateIfEmpty(d.planDays.first.id, exercises);
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: PlanEditorPage(repository: repo),
      ),
    );
    await settle(t);
    await t.ensureVisible(find.text('Drag to reorder exercises'));
    await t.tap(find.text('Drag to reorder exercises'));
    await settle(t);
    final handles = find.byType(ReorderableDragStartListener);
    expect(handles.hitTestable(), findsNWidgets(2));
    final start = t.getCenter(handles.first), end = t.getCenter(handles.last);
    final gesture = await t.startGesture(start);
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 24));
    await t.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(end);
    await t.pump(const Duration(milliseconds: 300));
    await gesture.moveTo(end + const Offset(0, 100));
    await t.pump(const Duration(seconds: 1));
    await gesture.up();
    await settle(t);
    await settle(t);
    await t.tap(find.text('Save'));
    await settle(t);
    await settle(t);
    final order = (await repo.loadPlanExercises(
      d.planDays,
    ))[d.planDays.first.id]!;
    expect(order.map((e) => e.exercise.name), ['Row', 'Bench']);
    expect(
      (await repo.loadPlanExercises(d.planDays))[d.planDays[1].id],
      isEmpty,
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
    'dragging an exercise keeps its controllers and persists reordered draft',
    (t) async {
      t.view.physicalSize = const Size(600, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = FitnessRepository(db);
      await repo.activateTemplate(builtInTrainingPlanTemplates.first);
      final key = await draft(repo, ['Bench', 'Row']);
      await open(t, repo, 'en');
      final handles = find.byType(ReorderableDragStartListener);
      final start = t.getCenter(handles.first);
      final gesture = await t.startGesture(start);
      await t.pump();
      expect(find.byType(TextField), findsNothing);
      final end = t.getCenter(find.text('Row'));
      expect(end.dy - t.getCenter(find.text('Bench')).dy, lessThan(80));
      await gesture.moveBy(const Offset(0, 24));
      await t.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(Offset(start.dx, end.dy));
      await t.pump(const Duration(milliseconds: 300));
      await gesture.moveTo(Offset(start.dx, end.dy + 100));
      await t.pump(const Duration(seconds: 1));
      await gesture.up();
      await t.pump(const Duration(milliseconds: 500));
      await settle(t);
      await t.pump(const Duration(milliseconds: 500));
      await settle(t);
      final saved = jsonDecode((await repo.readSetting(key))!) as List;
      expect(find.byType(TextField), findsNWidgets(6));
      expect(saved.map((e) => e['name']), ['Row', 'Bench']);
      expect(saved.first['sets'][0]['weight'], '40');
      await t.binding.handlePopRoute();
      await settle(t);
      await t.tap(find.text('Open'));
      await settle(t);
      expect(
        t.getTopLeft(find.text('Row')).dy,
        lessThan(t.getTopLeft(find.text('Bench')).dy),
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
