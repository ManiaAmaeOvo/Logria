# Contributing

Issues and pull requests are welcome. Describe the affected screen, language,
Android version, steps to reproduce, expected behavior and actual behavior.
Use synthetic logs in screenshots and examples.

Keep new functionality offline by default. Preserve existing data during schema
changes, keep food notes optional, and distinguish missing measurements from
zero. Update both ARB files and regenerate localization files for UI changes.

Before submitting:

```sh
flutter pub get
flutter gen-l10n
dart run build_runner build
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Do not commit personal databases, exported health logs, signing keys, machine
paths or credentials. Add focused tests for changes to cycle progression,
nutrition aggregation, date selection, migrations and clipboard output.

By contributing, you agree that your contributions use the MIT license.
