# Changelog

[简体中文](CHANGELOG.zh-CN.md)

## Unreleased — local Android build 8

- Chinese editions of the README, complete changelog, privacy, food references,
  testing checklist and contribution guide; bilingual navigation links.
- Offline changelog in Settings automatically follows the app's English/Chinese
  language, including system-language resolution and changes while open.
- Source/docs are pushed to main; this local APK does not replace the published
  1.2.0 build 7 release, its assets or tag. Merge into the next release.

## 1.2.0 — 2026-10-05 (Android build 7)

- Quick-add built-in and custom food presets directly inside the daily Food log,
  with searchable selection, amount preview, date-safe logging and cancellation.
- Nutrition totals, energy conversions, food amounts and copied numeric logs
  display at most four decimals without floating-point tails; stored calculations
  retain precision.
- Complete English and Simplified Chinese user manuals, bundled offline in
  Settings with an independent language switch and published in `docs/`.

- Date-bound daily review notes directly in Today, with explicit save/clear,
  historical calendar markers and inclusion in whole-day clipboard logs.
- Non-destructive training-cycle restart: archive interrupted progress, preserve
  history and other health data, discard unfinished plan-day drafts, and enable
  starting-day selection again. Recorded same-day actions must be undone first.
- One-shot first-set weight/reps filling during the first editing focus session.
  Manually edited lower fields are protected independently; later first-set edits
  do not overwrite them. Drafts retain these flags. RIR is never auto-filled.
- Reuse the last completed same-day-of-plan record as a new workout template,
  including exercises, set count, numeric/text weights, reps and RIR. First-set
  filling is available afresh; replacing an existing draft requires confirmation.
- Additive SQLite schema 4 adds DailyNotes without altering existing records.
- Exercise variant notes create independent reusable presets, with separate names
  and PR series. Editing a plan or workout variant never changes the base preset
  or previous workouts.
- Offline food/meal library with 12 verified USDA SR Legacy reference foods;
  raw/cooked weighing bases are separate. Built-ins are read-only and copyable.
- Custom label-based products and homemade meal presets with a reference amount
  in g, mL, portions, bottles, scoops or bags; entered amounts scale all known
  nutrients. Editing/deleting a preset never changes previously logged snapshots.
- Linked kcal/kJ input (1 kcal = 4.184 kJ). P/C/F initially estimate energy;
  manual energy edits disable estimation until explicitly re-enabled.
- Optional sodium, potassium, calcium, iron and dietary fiber in meals, presets,
  daily overrides and shared logs, with opt-in goal/minimum/limit modes. Unknown
  values are absent, not zero, and partial totals are labeled incomplete.
- Additive schema 5 adds FoodPresets and optional extra-nutrient/quantity snapshot
  fields, preserving older meals, measurements, workout drafts and daily reviews.

Build 7 merges the previously local build 5/6 features into the 1.2.0 release.

## 1.1.0 — 2026-10-04

Reissued as Android build 4, merging the starting-day and undo-recovery additions
into the original 1.1.0 release. The GitHub tag and release APK now refer to build 4;
build 3 remains in Git history at commit `52a7826`.

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
- Manual starting-day selection before an unrecorded cycle's first action, with
  earlier days marked unrecorded rather than fabricated workout/skip logs.
- Persistent recovery of an undone same-day fitness action, including original
  set data, identifiers, timestamps and completed-cycle rollover state.
- Explicit draft discard, preserving previously saved workouts.

### Data compatibility

- Additive database schema 3 preserves previous numeric sets and food records.
- Android build number 4; the development signing identity remains unchanged.
- Drafts are keyed by local date and workout/day. Editing a completed workout
  keeps its saved record unchanged until Save changes is selected.
- PR curves show daily maximum recorded load, not estimated 1RM. Manual records
  remain separate and can be deleted without changing a workout.
- The starting-day override applies to one cycle only. It is blocked by existing
  cycle activity or a current draft. The following cycle starts normally.
- Undo recovery is valid for the same local date and unchanged plan/cycle state.
  Recording a replacement action, changing the start or switching plans invalidates
  it. Cardio remains independent and does not invalidate strength undo recovery.

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
