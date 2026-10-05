<img src="assets/branding/logria-icon.png" width="96" alt="Logria icon">

# Logria

[简体中文](README.zh-CN.md)

**Three parts. One daily log.** A private, fully offline Android journal for
fitness, nutrition and body measurements, built with Flutter and Dart.

Logria is an independent project and does not share a repository or data with Summa.

[Download the latest APK](https://github.com/ManiaAmaeOvo/Logria/releases/latest) ·
[Changelog](CHANGELOG.md) · [English manual](docs/USER_GUIDE.md) ·
[中文使用说明](docs/USER_GUIDE.zh-CN.md) · [MIT License](LICENSE)

## Version 1.2.0 (Android build 7)

The published release/tag/APK remains build 7. Main now includes Chinese reader
docs and an offline, app-language-aware changelog as **local build 8**. Its APK
is shared manually only; these changes will join the next release without
replacing the existing v1.2.0 assets or tag.

This release adds daily review notes, non-destructive cycle restart, first-set
filling and previous-record workout templates, independent exercise variants,
offline food/meal presets, linked kJ/kcal editing and opt-in mineral/fiber targets.
Quick-add foods directly in the meal log. Calculated nutrition values display at
most four decimal places. English and Chinese manuals are bundled in Settings
and published in this repository. See [food data sources](docs/FOOD_DATA.md).

| Screen | What you can do |
| --- | --- |
| Today | Save daily review notes, review complete daily logs and copy all records or one section. |
| Fitness | Restart cycles without deleting history, reuse past workout templates, fill sets faster, resume drafts, track PRs and log cardio. |
| Nutrition | Log meals with optional P/C/F/kcal, estimate calories, edit daily totals and set goals or limits. |
| Body | Record any subset of eight measurements and review date-based trends. |
| Calendar | Browse month activity, locate training rounds and copy historical logs. |
| Settings | Read bilingual offline manuals, choose English/简体中文, review software details and open GitHub links. |

### Fitness

- Editable PPL, PPL × 2 and four-day split presets; custom days and rest slots.
- Exercise presets or one-off exercise names; sets, reps, kilograms and RIR.
- Planned rest can be moved earlier without skipping pending training.
- One strength-cycle action per local day, with undo and direct editing of completed workouts. Cardio is independent.
- Workout history and previous-round reference for the same training day.
- Resumable local workout drafts, including partial and not-yet-valid input.
- Numeric kg or text weights; text retains its label and maps explicitly to 0 or null.
- Opt-in exercise PR logs and date-based daily maximum load curves, with manual entries.
- Independent cardio logs with activity, duration, optional distance and notes.
- Common strength and cardio activity presets.
- Choose an unrecorded cycle's starting day (for example Push 2); earlier days
  are marked unrecorded, and the next cycle starts at day 1.
- Restore an undone same-day action with its original workout and cycle state.
- Explicitly discard a draft without changing saved workouts.
- Restart interrupted progress while keeping historical workouts and reselecting
  the starting day; unfinished plan-day drafts are discarded after confirmation.
- First weight/reps editing fills untouched later sets until leaving the field.
  Subsequent edits remain independent. Reusing a previous record resets this opportunity.

### Nutrition

- Record food text first and add optional nutrition numbers later.
- Per-meal calories default to `4P + 4C + 9F`; switch to manual calories when needed.
- Blank nutrients are unrecorded. Only calorie estimation treats missing macros as zero.
- Daily totals sum known meal values and can be partial.
- Editing a daily total creates a manual override. **Restore meal totals** resumes aggregation.
- Each P/C/F/kcal value has an independent **Goal** or **Limit** mode.
- Search 12 built-in reference foods, then enter grams to scale nutrients. Raw
  and cooked food bases are distinct. Copy read-only references to customize them.
- Quick-add built-in or custom foods directly from the Food log card, without
  opening library management; calculation previews use at most four decimals.
- Create products or complete meal presets per g, mL, portion, bottle, scoop or bag.
- Energy input binds kJ and kcal; manually editing either preserves label energy
  instead of overwriting it with macro estimates.
- Optional sodium, potassium, calcium, iron and fiber with **Goal**, **Minimum**
  or **Limit** modes. No intake standards are supplied automatically.

### Body and calendar

- Weight, height, body fat, waist, arm, chest, hip and thigh measurements.
- Partial date-based updates; blank fields preserve existing values, deletion is explicit.
- Trends for 30 days, 90 days or all history, with actual-date spacing.
- Calendar icons mark workouts, rest, skipped training, nutrition and body records.
- Cycle colors show spans rather than future scheduled workouts.

## Install

Download the APK from [Releases](https://github.com/ManiaAmaeOvo/Logria/releases).
Transfer it to an Android phone, open it and allow installation from that source.
Android 7.0/API 24 or later is required. Android 16/arm64 has been checked locally.

The published APK runs in release mode but uses the existing development
signing certificate to allow updates from earlier test APKs from this machine.
It is not a production Google Play release. See [release details](docs/RELEASE.md).
To upgrade from 1.0.0, 1.1.0 or local 1.2.0 builds, install **1.2.0 build 7** over
the existing app without uninstalling or clearing storage. The signing identity
is unchanged; schema 5 migrations preserve existing records. Keep your data on
the device: restorable backup/export/import is not available yet.

## Local data and privacy

No account, cloud sync, analytics, ads or built-in LLM calls. Records live in
SQLite on your device; the release app does not request Internet permission.
GitHub links open the external browser only when tapped. Copying puts selected
logs on the system clipboard, where you decide how to share them.

There is **no restorable backup/import/export UI yet**. Uninstalling or clearing
storage can remove records. Plain-text copying is not a database backup.
Read [Privacy](docs/PRIVACY.md) before relying on the app for long-term storage.

## Build and develop

Validated toolchain: **Flutter 3.47.2 / Dart 3.13.2**, JDK 17 and Android SDK.
The development host is a MacBook Pro M4 Pro; Android is the only supported target.

```sh
git clone https://github.com/ManiaAmaeOvo/Logria.git
cd Logria
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter analyze
flutter test
flutter run
```

```sh
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

Generated database and localization files are included. After changing tables or
ARB strings, regenerate their files. CI checks formatting, analysis, tests and
an Android debug build. CI APKs are not signed with the published release identity.

## Roadmap and current limits

Not implemented in the current version:

- JSON file import/export and restorable backups.
- Estimated 1RM, PR notifications and broader training statistics.
- Weight-based nutrition templates, weekly/monthly template updates and carb cycling.
- Custom body metric types and cloud/platform integrations.

A planned JSON contract is available at
[the export schema](docs/export/logria-health-log.schema.json); this is a schema,
not a working exporter. Current log sharing uses the clipboard.

## Contributing and credits

See [Contributing](CONTRIBUTING.md) and [Architecture](docs/ARCHITECTURE.md).
Report bugs with reproduction steps and synthetic examples.

- Product and development: [ManiaAmaeOvo](https://github.com/ManiaAmaeOvo).
- AI development collaborator: **gpt6.1sol**.
- Original Logria icon: an L and three progress columns representing its three modules.

MIT licensed. Flutter, Drift/SQLite and other dependencies retain their own licenses.
