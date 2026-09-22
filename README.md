# Logria

Logria is a private, fully offline Android app for tracking fitness, nutrition,
and body measurements.

## Current foundation

- Flutter and Dart, Android only
- Drift on SQLite for local relational storage
- Versioned, self-contained JSON export contract
- Training cycles with movable planned rest days
- Separate food text logs and daily nutrition totals

## Development

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

The export contract lives at `docs/export/logria-health-log.schema.json`.
