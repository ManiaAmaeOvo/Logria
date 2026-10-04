import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logria/core/database/app_database.dart';
import 'package:logria/features/body/data/body_repository.dart';

void main() {
  late AppDatabase db;
  late BodyRepository repo;
  final today = DateTime(2026, 10, 4), yesterday = DateTime(2026, 10, 3);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = BodyRepository(db);
  });
  tearDown(() => db.close());

  test(
    'partial updates preserve other metrics and edit without duplicates',
    () async {
      final initial = await repo.loadDay(today);
      final weight = initial.types.firstWhere((t) => t.keyName == 'weight').id;
      final waist = initial.types.firstWhere((t) => t.keyName == 'waist').id;
      await repo.saveDay(today, {weight: 80, waist: 85});
      await repo.saveDay(today, {weight: 79.5});
      final day = await repo.loadDay(today);
      expect(day.types.length, 8);
      expect(day.measurements[weight]!.value, 79.5);
      expect(day.measurements[waist]!.value, 85);
      expect(day.history.length, 2);
      await repo.deleteMeasurement(day.measurements[weight]!.id);
      expect((await repo.loadDay(today)).measurements.keys, [waist]);
    },
  );

  test(
    'history excludes future dates and missing days are not filled',
    () async {
      final initial = await repo.loadDay(today);
      final weight = initial.types.first.id;
      await repo.saveDay(yesterday, {weight: 80});
      await repo.saveDay(today, {weight: 79});
      final past = await repo.loadDay(yesterday);
      expect(past.history.length, 1);
      expect(past.measurements[weight]!.value, 80);
      final empty = await repo.loadDay(DateTime(2026, 10, 2));
      expect(empty.history, isEmpty);
      expect(empty.measurements, isEmpty);
    },
  );

  test('invalid body fat rolls back the entire batch', () async {
    final initial = await repo.loadDay(today);
    final weight = initial.types.first.id;
    final fat = initial.types.firstWhere((t) => t.keyName == 'body_fat').id;
    await expectLater(
      repo.saveDay(today, {weight: 80, fat: 101}),
      throwsArgumentError,
    );
    expect((await repo.loadDay(today)).measurements, isEmpty);
    await expectLater(
      repo.saveDay(today, {weight: double.nan}),
      throwsArgumentError,
    );
  });
}
