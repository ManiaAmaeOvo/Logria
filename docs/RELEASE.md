# Release process

## 1.4.0 build 12

Public release of build 11 features with an incremented Android versionCode.
Release notes: `docs/releases/1.4.0.md`. Publish a new `v1.4.0` tag and assets
`logria-v1.4.0-android.apk` plus `SHA256SUMS`; retain older releases/tags.
VersionName 1.4.0 / versionCode 12, SQLite schema 7, unchanged signing certificate.

Build 12 verification: all 119 tests pass; static analysis, formatting and release
APK build pass. Certificate SHA-256 remains
`d8419bb31e02ad9916fb3ccd57ab4bb59a1fcc6b91e8e4b3e1b47900ea611aa0`.
APK: `build/releases/logria-v1.4.0-android.apk`.
SHA-256: `8ec0fdbd8aa69e9a3ac5ebd969aab7b890b098820cd9ddf5b3d1e1c3f7382885`.

## Previous local 1.4.0 build 11 validation

This workspace includes backup/restore, dated JSON export v2, sleep, per-set notes,
text RIR, multi-ingredient meals, arithmetic numeric inputs and compact nutrition
tables. This local build was superseded by the public build 12.

All 119 tests pass, including full backup/undo round-trip, invalid-backup rollback,
schema 6→7 legacy RIR preservation, bilingual UI flows and existing large-text
layouts. Analysis and formatting are clean. The emulator upgraded from build 10
without clearing data. A system-picker backup was saved locally and inspected as
format `logria.backup`, schema 7, with 19 tables. Certificate unchanged; no Internet
or broad storage permission. APK: `build/releases/logria-v1.4.0-build11-android.apk`.
Legacy orphan workout rows are preserved in an inert archive, not deleted; the
restore confirmation explains this explicitly. Other unsupported integrity errors
block backup creation. Normal restore keeps foreign-key enforcement enabled.
The final emulator smoke test saved and reopened the corrected backup, confirmed
restoration, returned to a fresh Today screen with the saved Chinese locale, and
retained all four orphan rows in the disclosed archive. No crash/migration errors
were observed. The compact nutrition table now keeps P/C/F/kcal visible at normal size.
SHA-256: `99ac3ba62ded07451ca9115283a9306dabfad3ed2364ad7e20d014e8f73a389f`.

Release tooling uses Flutter 3.47.2 / Dart 3.13.2 and Android application ID
`com.logria.logria`. The UI version in `lib/core/app_metadata.dart` must match
`pubspec.yaml`. Build numbers must increase for updates.

Version 1.3.0 combines historical fitness correction, implicit rest and a
device-local 04:00 cutoff with the previously local-only build 8/9 changes.
It was published with its own v1.3.0 tag and release; v1.2.0 assets/tag remain unchanged.
Release notes: `docs/releases/1.3.0.md` (English and Simplified Chinese).

1.3.0 validation: 96 automated tests, static analysis and formatting checks pass;
final bilingual embedded-doc tests also pass. The APK retains certificate SHA-256
`d8419bb31e02ad9916fb3ccd57ab4bb59a1fcc6b91e8e4b3e1b47900ea611aa0`,
versionCode 10 / versionName 1.3.0, and does not request Internet permission.
APK: `build/releases/logria-v1.3.0-android.apk`.
SHA-256: `7e2ebe0a6d694943d7781db285fa62f82b34cd02c8502a7bd02ae66a5444acc1`.

Previous local build 8 validation: all 80 tests, analysis and format checks pass. The
emulator upgraded from build 7 without clearing data; the Settings changelog was
checked in Chinese and English, then the original Chinese preference restored.
Both changelogs and manuals are bundled; certificate unchanged, versionCode 8,
no Internet permission. Local APK: `build/releases/logria-v1.2.0-build8-android.apk`.
SHA-256: `49bd094011b76f3cd31324263379bc82b9f9e8660022aef901d66cc9b4a77571`.

Local build 9 validation: all 96 tests, static analysis and format checks pass.
The emulator upgraded in place with existing PPL × 2 plan retained and no observed
crash/migration errors. VersionCode 9, unchanged signing certificate, no Internet
permission. Local APK: `build/releases/logria-v1.2.0-build9-android.apk`.
SHA-256: `ad20e1a7b4eb84af3a8cd065cf73b4aecb84a9a98354f1badd253c854e5c4238`.
Build 9 was local-only; its changes are included in 1.3.0 build 10.

## Checks and build

```sh
flutter pub get
flutter gen-l10n
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
```

The universal APK is `build/app/outputs/flutter-apk/app-release.apk`. It includes
the supported Android ABIs. A debug APK remains available through
`flutter build apk --debug` for local development.

For versions 1.0.0 through 1.4.0, release mode uses the existing local development
signing certificate. This preserves update compatibility with earlier test APKs
from this machine. It is not a production Google Play signing setup. CI-produced
APKs use that runner's development certificate and are not interchangeable
updates to the published APK. Do not publish CI artifacts as official updates.

Keep the signing identity available privately for future updates. A different
certificate cannot update an existing installation in place. Never commit a
keystore or signing credentials to Git.

## Publish

After checks pass, commit the release, tag `v1.4.0`, push the branch and tag, then
create a GitHub release with the APK, its SHA-256 checksum and release notes.
Release attachments should contain binaries/checksums only, never user databases.

The 1.4.0 assets are `logria-v1.4.0-android.apk` and `SHA256SUMS`. Publish
`docs/releases/1.4.0.md` as the bilingual release notes, and set it as the
latest stable release. Confirm the uploaded APK digest matches the local checksum.

## Upgrade from 1.0.0

Install over the existing app; do not uninstall or clear storage. Build 4 uses
the same application ID and signing certificate as builds 2 and 3. Database schema 3
adds text weights, cardio logs and manual PR records without replacing existing
numeric sets or food/body data. Local validation includes 52 tests, English and
Chinese narrow-screen/large-text checks, and emulator upgrade installation.

Existing orphan set rows from older editing behavior are not purged by this
upgrade. Foreign-key enforcement prevents new orphan rows; history/PR queries
only use sets linked to existing workout exercises.

## 1.1.0 reissue (build 4)

At the owner's request, starting-day selection and undo recovery are merged into
the same 1.1.0 release instead of publishing 1.1.1. Update the existing annotated
tag to the new commit using an explicit expected-old-ref force lease. Replace only
the two named release assets and update its notes; do not delete the release or
rewrite main history. Original build 3 source remains in commit `52a7826`.
Check that the tag, APK build number and uploaded SHA-256 all agree.

## 1.2.0 build 7 verification

77 tests pass; static analysis, formatting and diff checks are clean. Both
English and Chinese guide files are present in the APK and readable offline
from Settings. The quick-food dialog and numeric summaries were inspected on
the emulator. In-place build 6→7 installation succeeded, with existing food
records and body history retained. The certificate matches previous official
APKs, versionCode is 7, and no Internet permission is requested.

Release APK: `logria-v1.2.0-android.apk`.
SHA-256: `6e2e8e5e60a52a903f27806554c29202ef5f442657c5fb7380dbffe9866189a8`.

## Local 1.2.0 build 5

Install over build 4 without clearing storage. Schema 4 adds a date-keyed note
table only. Validate the same certificate, increasing versionCode, preserved
emulator data, no Internet permission, and English/Chinese layout before sharing.
This was a local validation build, superseded by published build 7.

Local validation: 57 tests passed, analysis/format checks clean, matching signing
certificate and no Internet permission verified, in-place build 4→5 emulator
upgrade confirmed with pre-existing body measurements retained.

## Local 1.2.0 build 6

Build 6 includes build 5's daily review/restart/template features plus exercise
variants, food/meal presets and optional mineral/fiber recording and targets.
Schema 5 is additive; install over build 4 or 5 without uninstalling/clearing data.
71 tests pass, including linked energy inputs, bilingual narrow-screen food and
target dialogs, preset snapshot preservation and the schema-4-to-5 migration.
This was a local validation build, superseded by published build 7.

Build 6 emulator smoke check: in-place build 5→6 installation succeeded with the
same signing certificate and no Internet permission. The local food catalog
renders correctly, and the existing body history remains available. APK:
`build/releases/logria-v1.2.0-build6-android.apk`.
SHA-256: `7bf29782441d0edd3637cb81008874af08f242c58f33d46c33707eefdc33bb74`.

## Icon

The original source is `assets/branding/logria-icon.svg`. The raster versions
are rendered from it. Adaptive and monochrome Android drawables use the same
geometry in a 108-unit viewport and stay within the launcher safe area.

With librsvg installed, regenerate each raster size using:

```sh
rsvg-convert -w 512 -h 512 -o assets/branding/logria-icon.png assets/branding/logria-icon.svg
```

Android mipmap sizes are 48, 72, 96, 144 and 192 pixels for mdpi through xxxhdpi.
