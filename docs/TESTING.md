# 1.3.0 testing guide

[简体中文](TESTING.zh-CN.md)

Version 1.3.0 (build 10) adds historical fitness correction, implicit rest and a
04:00 journal cutoff, including local build 8/9's docs and changelog.
The old v1.2.0 APK and tag are preserved. See RELEASE.md for release validation.
Added coverage includes legacy-date migration, 04:00 boundary and pinned editors,
historical action replacement/rollback, duplicate-day protection, stale revisions,
closed rounds, current-round rollover/undo/redo, start overrides and bilingual forms.

## Journal-date regression checklist (build 9)

- At 03:59, default strength, cardio, PR, nutrition/body and Today dates are
  yesterday; at 04:00 they are today. Verify foreground refresh and app resume.
- A calendar-selected date and an already-open editor never shift implicitly.
- Backfill training, then change it to rest/skip and back again. Later sessions,
  meals, body data and independent manual PR must remain unchanged.
- Verify occupied slots cannot be duplicated, cancelled edits preserve records,
  live progress recalculates, closed rounds remain closed and partial drafts resume.
- Blank past dates show rest without creating executions or consuming rest slots.
- Upgrade an old database: old 02:00 entries must retain their old date.

Use Android build 10 for shared testing. Install the official release APK over an
existing installation rather than uninstalling or clearing data. A fresh install
starts without private logs. There is no restorable backup/import yet.

## Automated validation

96 tests pass locally. Analysis and Dart formatting checks are clean. Coverage
includes additive schema migrations; exercise variants and PR snapshots; daily
reviews; cycle restart/undo/redo; draft persistence and one-shot set filling;
previous-record templates; food references and custom units; unknown versus zero
nutrients; daily overrides; manual energy; extra-nutrient target modes; quick-food
cancellation/date/precision; bilingual offline manuals; and all main screens at
360×800 with 1.6× English/Chinese text.

Historical 1.2.0 APK smoke checks confirmed in-place build 6→7 upgrade, matching signing
identity, versionCode 7, no Internet permission, both bundled manuals, the
quick-food picker, rounded summaries and preservation of existing food/body data.

## Suggested friend-testing checklist

- Choose a plan, edit a day and select Push 2 as the first recorded day.
- Record a partial set, leave and resume; complete it and edit the saved workout.
- Manually change a lower set, then edit the first set; verify protected values.
- Record rest, attempt another daily action, undo and restore it.
- Add an exercise variant and confirm the original preset/history is unchanged.
- Track one PR, add/delete a manual value and record an independent cardio entry.
- Restart an interrupted cycle and reuse the previous matching day's record.
- Write and save a daily review; copy Today and a historical Calendar day.
- Add a text-only meal, then fill nutrients and override/restore daily totals.
- Quick-add a built-in and custom food using a fractional amount. Test cancel,
  search with no results and a past selected date; inspect the calculated values.
- Create a label-based bottle/portion preset. Change kJ, kcal and P/C/F, checking
  that manual energy remains until automatic estimation is re-enabled.
- Set sodium to a limit and another optional nutrient to a minimum; leave some
  values unknown and confirm the partial-total warning rather than a false zero.
- Record only weight on one date and another metric on a different date; inspect
  their curves and verify missing measurements are not fabricated.
- Open Settings → User manual. Expand sections, copy text and switch languages
  while the phone is offline; repeat with large system text and the keyboard.
- On local build 8, open Settings → Changelog and expand older versions. Verify
  automatic English/Chinese/system language matching and readable large text.
- Close/reopen the app and verify saved records and language preference remain.

## Reporting

Use GitHub Issues. Include app build, Android/device version, app language,
minimal steps, expected/actual result and a redacted screenshot if helpful.
Use synthetic examples and never upload private databases or health records.
The English and Chinese manuals in `docs/` are also available offline in Settings.
