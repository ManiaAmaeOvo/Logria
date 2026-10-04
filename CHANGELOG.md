# Changelog

## 1.1.0 — 2026-10-04

### Added

- Opt-in exercise tracking, daily maximum-load curves and manual dated PR logs.
- Independent cardio recording/editing/deletion with duration, optional distance
  and notes; included in Today/Calendar logs and clipboard output.
- Common strength exercise presets and quick-pick cardio activities.
- Debounced persistent workout drafts, flushed on back navigation/backgrounding,
  with raw partial input restored on resume. Drafts do not advance training cycles.
- Text weights retain their original label and explicitly map to numeric 0 or
  null (default). Unknown weights are excluded from PR calculations.
- Optional reps/RIR during final recording; empty sets are omitted.

### Data compatibility

- Additive database schema 3 preserves previous numeric sets and food records.
- Android build number 3; the development signing identity remains unchanged.
- Drafts are keyed by local date and workout/day. Editing a completed workout
  keeps its saved record unchanged until Save changes is selected.
- PR curves show daily maximum recorded load, not estimated 1RM. Manual records
  remain separate and can be deleted without changing a workout.

### Fixed

- Enable SQLite foreign-key enforcement so replacing/deleting exercises also
  deletes their dependent sets instead of leaving orphan rows.

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
