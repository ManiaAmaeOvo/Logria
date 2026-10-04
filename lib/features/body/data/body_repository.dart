import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

class BodyDayData {
  const BodyDayData(this.types, this.measurements, this.history);
  final List<BodyMeasurementType> types;
  final Map<String, BodyMeasurement> measurements;
  final List<BodyMeasurement> history;
}

class BodyRepository {
  BodyRepository(this.database);
  final AppDatabase database;
  static const _uuid = Uuid();
  static const builtIns = [
    ('weight', 'Weight', 'kg'),
    ('height', 'Height', 'cm'),
    ('body_fat', 'Body fat', '%'),
    ('waist', 'Waist', 'cm'),
    ('arm', 'Arm', 'cm'),
    ('chest', 'Chest', 'cm'),
    ('hip', 'Hip', 'cm'),
    ('thigh', 'Thigh', 'cm'),
  ];

  String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<BodyDayData> loadDay(DateTime date) async {
    await database.transaction(() async {
      for (final (key, name, unit) in builtIns) {
        final existing = await (database.select(
          database.bodyMeasurementTypes,
        )..where((t) => t.keyName.equals(key))).getSingleOrNull();
        if (existing == null) {
          await database
              .into(database.bodyMeasurementTypes)
              .insert(
                BodyMeasurementTypesCompanion.insert(
                  id: _uuid.v4(),
                  keyName: key,
                  displayName: name,
                  defaultUnit: unit,
                  isBuiltIn: const Value(true),
                ),
              );
        }
      }
    });
    final types = await (database.select(
      database.bodyMeasurementTypes,
    )..where((t) => t.isArchived.equals(false))).get();
    types.sort((a, b) {
      int index(String key) {
        final i = builtIns.indexWhere((item) => item.$1 == key);
        return i < 0 ? builtIns.length : i;
      }

      return index(a.keyName).compareTo(index(b.keyName));
    });
    final history =
        await (database.select(database.bodyMeasurements)
              ..where((m) => m.localDate.isSmallerOrEqualValue(dateKey(date)))
              ..orderBy([
                (m) => OrderingTerm.asc(m.localDate),
                (m) => OrderingTerm.asc(m.recordedAt),
              ]))
            .get();
    return BodyDayData(types, {
      for (final m in history.where((m) => m.localDate == dateKey(date)))
        m.measurementTypeId: m,
    }, history);
  }

  Future<void> saveDay(DateTime date, Map<String, double> values) async {
    if (values.values.any((v) => !v.isFinite || v <= 0)) {
      throw ArgumentError('Measurements must be positive finite numbers.');
    }
    await database.transaction(() async {
      for (final entry in values.entries) {
        final type = await (database.select(
          database.bodyMeasurementTypes,
        )..where((t) => t.id.equals(entry.key))).getSingle();
        if (type.keyName == 'body_fat' && entry.value > 100) {
          throw ArgumentError('Body fat must not exceed 100%.');
        }
        final existing =
            await (database.select(database.bodyMeasurements)..where(
                  (m) =>
                      m.measurementTypeId.equals(entry.key) &
                      m.localDate.equals(dateKey(date)),
                ))
                .get();
        if (existing.isEmpty) {
          await database
              .into(database.bodyMeasurements)
              .insert(
                BodyMeasurementsCompanion.insert(
                  id: _uuid.v4(),
                  measurementTypeId: entry.key,
                  localDate: dateKey(date),
                  value: entry.value,
                  unit: type.defaultUnit,
                  recordedAt: DateTime.now(),
                ),
              );
        } else {
          await (database.update(
            database.bodyMeasurements,
          )..where((m) => m.id.equals(existing.last.id))).write(
            BodyMeasurementsCompanion(
              value: Value(entry.value),
              recordedAt: Value(DateTime.now()),
            ),
          );
        }
      }
    });
  }

  Future<void> deleteMeasurement(String id) => (database.delete(
    database.bodyMeasurements,
  )..where((m) => m.id.equals(id))).go();
}
