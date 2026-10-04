# Changelog

## 1.0.0 — 2026-10-04

First public Android release of Logria, independent of Summa.

### Added

- Offline Drift/SQLite storage for fitness, nutrition and body measurements.
- Editable PPL, PPL × 2 and four-day split plans; custom training days,
  exercise presets, sets, reps, weight and RIR.
- Movable rest days, skipped training, cycle progression, daily action locking
  and undo. Completed workouts appear directly and can be edited.
- Workout history and previous-cycle comparison for the same training day.
- Per-meal text and optional P/C/F/calories, automatic calorie estimates,
  editable daily overrides and independent goal/limit modes.
- Partial body measurements and date-based 30/90-day/all-time trends.
- Today dashboard, full/section clipboard copying and fresh reads before copy.
- Monthly calendar, activity markers, cycle colors and historical-day copying.
- English/Simplified Chinese UI and persisted language selection.
- Original vector icon, adaptive/themed Android launcher icon, refreshed cards
  and inputs, About information, GitHub links and license notices.
- Public JSON export schema (contract only), documentation and automated checks.

### Fixed

- Exercise dialog controller lifetime and template-selection callbacks.
- Repeated daily training/rest actions and workout numeric validation.
- Historical log empty states and cycle attribution at date boundaries.
- Narrow-screen/large-text layout issues discovered during release validation.
- Legacy tests updated for localized labels and stable template keys.

### Release notes

- Database schema 2 preserves version-1 food notes during migration.
- Android build number is 2. The initial APK uses the existing development
  signing certificate for compatibility with earlier test installs; it is not
  a Google Play production-signed release.
- JSON import/export, PR charts, custom body metrics and weight-based nutrition
  templates are not implemented in this release.
