# 1.2.0 testing guide

Use Android build 7 for shared testing. Install the official release APK over an
existing installation rather than uninstalling or clearing data. A fresh install
starts without private logs. There is no restorable backup/import yet.

## Automated validation

77 tests pass locally. Analysis and Dart formatting checks are clean. Coverage
includes additive schema migrations; exercise variants and PR snapshots; daily
reviews; cycle restart/undo/redo; draft persistence and one-shot set filling;
previous-record templates; food references and custom units; unknown versus zero
nutrients; daily overrides; manual energy; extra-nutrient target modes; quick-food
cancellation/date/precision; bilingual offline manuals; and all main screens at
360×800 with 1.6× English/Chinese text.

Release APK smoke checks confirmed in-place build 6→7 upgrade, matching signing
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
- Close/reopen the app and verify saved records and language preference remain.

## Reporting

Use GitHub Issues. Include app build, Android/device version, app language,
minimal steps, expected/actual result and a redacted screenshot if helpful.
Use synthetic examples and never upload private databases or health records.
The English and Chinese manuals in `docs/` are also available offline in Settings.
