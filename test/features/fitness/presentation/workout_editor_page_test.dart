import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/fitness/presentation/workout_editor_page.dart';
import 'package:logria/l10n/app_localizations.dart';

void main() {
  testWidgets('new exercise dialog can close without controller errors', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = FitnessRepository(database);
    await repository.activateTemplate(builtInTrainingPlanTemplates.first);
    final dashboard = (await repository.loadDashboard())!;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorkoutEditorPage(repository: repository, dashboard: dashboard),
      ),
    );
    await tester.tap(find.text('添加动作'));
    await tester.pumpAndSettle();

    expect(find.text('输入新动作'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('输入新动作'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
