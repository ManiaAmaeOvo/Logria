# Release process

Version 1.1.0 (Android build 3) uses Flutter 3.47.2 / Dart 3.13.2 and Android application ID
`com.logria.logria`. The UI version in `lib/core/app_metadata.dart` must match
`pubspec.yaml`. Build numbers must increase for updates.

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

For versions 1.0.0 and 1.1.0, release mode uses the existing local development
signing certificate. This preserves update compatibility with earlier test APKs
from this machine. It is not a production Google Play signing setup. CI-produced
APKs use that runner's development certificate and are not interchangeable
updates to the published APK. Do not publish CI artifacts as official updates.

Keep the signing identity available privately for future updates. A different
certificate cannot update an existing installation in place. Never commit a
keystore or signing credentials to Git.

## Publish

After checks pass, commit the release, tag `v1.1.0`, push the branch and tag, then
create a GitHub release with the APK, its SHA-256 checksum and release notes.
Release attachments should contain binaries/checksums only, never user databases.

The 1.1.0 assets are `logria-v1.1.0-android.apk` and `SHA256SUMS`. Publish only
the corresponding 1.1.0 Changelog section as the release notes, and set it as the
latest stable release. Confirm the uploaded APK digest matches the local checksum.

## Upgrade from 1.0.0

Install over the existing app; do not uninstall or clear storage. Build 3 uses
the same application ID and signing certificate as build 2. Database schema 3
adds text weights, cardio logs and manual PR records without replacing existing
numeric sets or food/body data. Local validation includes 40 tests, English and
Chinese narrow-screen/large-text checks, and emulator upgrade installation.

Existing orphan set rows from older editing behavior are not purged by this
upgrade. Foreign-key enforcement prevents new orphan rows; history/PR queries
only use sets linked to existing workout exercises.

## Icon

The original source is `assets/branding/logria-icon.svg`. The raster versions
are rendered from it. Adaptive and monochrome Android drawables use the same
geometry in a 108-unit viewport and stay within the launcher safe area.

With librsvg installed, regenerate each raster size using:

```sh
rsvg-convert -w 512 -h 512 -o assets/branding/logria-icon.png assets/branding/logria-icon.svg
```

Android mipmap sizes are 48, 72, 96, 144 and 192 pixels for mdpi through xxxhdpi.
