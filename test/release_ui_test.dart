import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/app/logria_app.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/body/data/body_repository.dart';
import 'package:logria/features/fitness/data/fitness_repository.dart';
import 'package:logria/features/fitness/domain/training_plan_template.dart';
import 'package:logria/features/nutrition/data/nutrition_repository.dart';

void main() {
  for (final language in ['en', 'zh']) {
    testWidgets(
      'release screens fit a narrow phone with larger $language text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await tester.runAsync(() async {
          await db
              .into(db.appSettings)
              .insert(
                AppSettingsCompanion.insert(
                  keyName: 'app.locale',
                  value: language,
                  updatedAt: DateTime.now(),
                ),
              );
          await FitnessRepository(db)
              .activateTemplate(builtInTrainingPlanTemplates.first);
          final nutrition = NutritionRepository(db);
          await nutrition.addFoodEntry(
            DateTime.now(),
            'Lunch / 午餐',
            proteinGrams: 30,
            carbohydrateGrams: 50,
            fatGrams: 10,
            caloriesKcal: 410,
          );
          await nutrition.saveTargets(
            const NutritionTargets(
              proteinGoalGrams: 150,
              carbohydrateGoalGrams: 250,
              fatGoalGrams: 70,
              calorieLimitKcal: 2300,
            ),
          );
          final body = BodyRepository(db);
          final types = (await body.loadDay(DateTime.now())).types;
          await body.saveDay(DateTime.now(), {types.first.id: 80});
        });
        await tester.pumpWidget(LogriaApp(database: db));
        Future<void> settle() async {
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pumpAndSettle();
        }

        await settle();
        expect(tester.takeException(), isNull);
        for (var index = 1; index < 5; index++) {
          await tester.tap(find.byType(NavigationDestination).at(index));
          await settle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$language module $index must fit',
          );
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -500),
          );
          await settle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$language module $index lower content must fit',
          );
        }
        await tester.tap(find.byTooltip(language == 'en' ? 'Settings' : '设置'));
        await settle();
        await tester.scrollUntilVisible(
          find.text('ManiaAmaeOvo · gpt6.1sol'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('ManiaAmaeOvo · gpt6.1sol'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
