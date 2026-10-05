# Using Logria 1.2

Logria is an offline Android fitness, nutrition and body journal. Data stays on
this device. Start with the Today screen, then use the five bottom tabs.
In Settings → User manual you can read this guide offline and switch between
English and Simplified Chinese independently of the app language.

## Install and start

Download the official APK from GitHub Releases and allow installation from your
browser/file manager when Android asks. Minimum Android version: 7.0 (API 24).
To update, install over the existing app with the same signing identity; do not
uninstall first or clear app storage. The app does not sync between phones.

Settings lets you choose English, Simplified Chinese or system language. Dates
use the device's local time. Nutrition and Body support selecting past dates;
training actions are for today, and past workouts are reviewed through history.

## Start a training plan

Open Fitness and choose PPL, PPL × 2 or the four-day split. The plan menu lets
you edit the plan and switch presets. Changing presets starts a new plan while
preserving previous workout history.

Edit plan days, order, rest slots and exercise targets before training. During
a workout, choose an existing exercise or enter a new name. New names can be
saved as presets or kept for that workout only.

Before this cycle has recorded activity, tap **Choose starting day** on Fitness
and select any training/rest day, for example Push 2. Confirm the change. Earlier
days are marked **Before starting day · not recorded**; no workout/skip entries
are fabricated. This affects only the current cycle; the next cycle starts at
day 1. To change the entry point again, first finish or discard any current draft.
Once this cycle has recorded an action, its starting day cannot be reset.

Enter numeric kilograms as `40` (not `40kg`). You may also enter a text label
such as `bodyweight` or `heavy band`. A text weight defaults to numeric `null`
(unknown/excluded from PR); choose `0` for no measurable external load. Both
choices retain the original text in saved logs. Unit-suffixed input such as
`40kg` is text, not automatically parsed into kilograms.

Inputs are saved as local drafts after a short debounce and flushed when you
leave with the app/system back button or background the app. Partial and invalid
input can be resumed. Tap Continue workout draft or open the same workout again.
Drafts do not advance the cycle or replace completed logs. Finish and save (or
Save changes when editing) commits the record. Blank sets are omitted; missing
weight, reps and RIR remain unknown. Drafts belong to the date and workout/day.
Planned sets start empty: targets are not automatically recorded as performed sets.
Do not rely on an immediate force-stop during input to flush an unsaved keystroke.
The editor's **Discard draft** icon asks for confirmation, removes unsaved inputs
and returns to Fitness. It does not delete or modify the previously saved workout.

## Exercise PR and cardio

In the workout editor, tap **Variant note / separate preset** on an exercise.
For example, add "Overhand · wide grip" to Lat pulldown. This creates a separate
reusable preset named `Lat pulldown [Overhand · wide grip]`, leaving the original
preset and previous records unchanged. Variant names have separate opt-in PR
series. The current set inputs stay in place and the choice persists in the draft.
In a training plan, the same option is in an exercise's overflow menu; only that
plan item switches to the new preset. Clearing the note returns to the base
exercise but does not delete the already-created variant preset.

Open Exercise PR from Fitness. Choose only the exercises you want to track from
presets or your workout history, then select one to review. The curve uses the
maximum numeric logged load per date, not estimated 1RM. Text-null weights are
excluded; text-zero weights contribute zero. Add manual PR to backfill dated
weights and optional reps. The log identifies manual and workout sources; manual
entries can be deleted. Stop tracking hides the exercise without deleting records.
Changing a workout automatically changes its contribution to the curve. Different
exercise names (including translated names) are separate series.

Cardio is independent of the strength cycle and can be recorded on rest days or
before selecting a plan. Choose a common activity or type your own, set a date
and duration in minutes, and optionally add distance in km and notes. Tap a log
to edit; delete uses confirmation. Cardio appears in Today and Calendar copying.

## Rest, skip and undo

Taking rest early uses the next planned rest slot and keeps the pending training
day in place. If no planned rest slot remains, extra rest leaves training position
unchanged. Skipping a training day advances past that day.

After one fitness action, other rest/training actions are locked for the same day.
Undo removes the most recent action and restores cycle position. Historical
workouts remain accessible through History and the previous-round reference.

After undo, **Restore today's action** restores the original workout/rest/skip
action, identifiers, sets, timestamps and cycle position, including a rollover to
the next cycle. This remains available after restarting the app on the same date.
A new recorded action, plan/day/exercise-target changes, start-day changes or a
different date make the old recovery unavailable. Cardio is independent. Only
one undone action is retained; redo itself can be undone again.

## Meals and nutrition

Use Add meal for food text and optional P/C/F values in grams. Calories are
estimated by default; disable automatic estimation to type your own calories.
Text-only meals are valid and can be updated later.

Daily intake automatically sums known meal values. A blank value means unknown,
not zero. A partial meal record therefore produces partial daily information.

Edit Daily intake to set a manual daily total, for example after reviewing copied
food logs with an LLM. Meal changes will not change that override. Select Restore
meal totals to remove the override and resume automatic aggregation.

Set each nutrient’s number and choose Goal or Limit. A goal displays how much is
still needed and whether it is reached. A limit displays remaining allowance and
highlights excess. Leave a number blank to disable that goal/limit.

### Food and meal presets

In the **Food log** card, tap **Quick add from presets**, search a saved food,
choose it, then enter an amount and save. Its P/C/F, energy and recorded extra
nutrients are calculated and added directly to the selected day's food log.
Canceling either dialog records nothing. You can then tap the logged meal to
edit its text/nutrients directly; this does not change its preset. Each addition
is a separate log, so one meal can have several ingredient entries.

To create, copy, edit or delete reusable presets, open **Foods & meal presets**.
You can also log foods there. Search an ingredient, tap it and
enter the eaten amount to preview nutrients before logging. The amount uses the
preset's explicit unit; raw/cooked food weights are not interchangeable. Logs
are saved to the date selected in Nutrition, not necessarily today.

Use the plus button to create a label-based product or complete meal, e.g.
protein powder per 30 g, yogurt per bottle, or dinner per portion. Enter the
label/reference nutrients for that amount. g, mL, portions, bottles, scoops and
bags are supported. Fractional amounts work. A meal preset stores the combined
nutrients you enter; it is not an automatic ingredient-recipe calculator.

P/C/F initially estimate kcal. Entering kcal or kJ manually disables estimation
and updates the other energy field; later macro edits keep your label energy.
Turn estimation back on explicitly to restore 4P + 4C + 9F calculation. This also
works in the ordinary meal editor. Logged meals remain directly editable.

Calculated values and numeric summaries display at most four decimal places,
with trailing zeroes removed. Stored calculations retain their precision; the
display is a rounded estimate. Editing and saving a displayed value uses the
number in the field. User-entered text notes/weight labels are not rounded.

Built-in references are read-only. Use **Copy as a new preset** to customize
them. User presets can be edited/deleted; already logged nutrient snapshots do
not change. See [Food data](FOOD_DATA.md) for source IDs and assumptions.

### Minerals and fiber

Expand **Minerals & fiber (optional)** in a meal, daily intake, or target editor
to record sodium, potassium, calcium, iron and dietary fiber. Minerals use mg;
fiber uses g. Each target can be a Goal, Minimum, or Limit. Leave its value blank
to disable it. No intake standard is filled in automatically.

Unknown values are not zero. Totals sum only recorded values; incomplete totals
are labeled rather than claiming an accurate remaining allowance. Manual daily
intake overrides apply to extra nutrients too; **Restore meal totals** resumes
aggregation. Today/Calendar copied logs include recorded extra nutrients.

## Body measurements

Select a date, then tap a metric chip to record just that measurement, or use the
plus button to enter several measurements. Existing measurements can be edited
or deleted. Blank editor fields preserve values; use Delete to remove them.

Select a metric in Trends & history and choose 30 days, 90 days or All. Dates
without measurements are not filled in. Tap a historical value to jump to its date.

## Daily review and sharing

Enter a reflection directly in Today's **Daily review** card, then tap Save.
Saving an empty note removes only that date's review. Saved reviews appear in
Calendar and whole-day copied logs, not in individual health-module sections.

Today combines complete workout sets, meal notes/nutrients, daily nutrition totals
and measurements recorded today. Copy everything with the top button or use the
copy icon on a section. The arrow opens its corresponding module.

Calendar marks recorded activity by icon and training-round spans by color. Tap
a date and scroll to its logs below the calendar. The cycle selector locates its
start and dims dates outside that round. Dimmed past dates are still selectable.
Tap Today to return to the current month/date and clear the cycle highlight.

Copying from Calendar uses the selected date, not today. Both copy flows re-read
the database first, include units/date and label unknown values with a dash.

## Restarting and reusing workouts

In Fitness, open the top-right menu and select **Restart training cycle**.
Confirming archives the interrupted cycle and starts a fresh one with the same
plan. Historical workouts, PRs, nutrition and measurements stay intact; unfinished
plan-day drafts are discarded. Then use **Choose starting day**, e.g. Push 2.
If today's training/rest/skip is already recorded, undo it before restarting.
Restarting invalidates same-day undo recovery and is not a full data wipe.

For an exercise with multiple sets, the first weight edit and first reps edit
each fill untouched lower fields while that input is focused. After leaving the
field, further edits no longer propagate. Editing a lower weight/reps protects
that field independently and never changes an upper set. These flags survive
draft exit/resume; RIR is independent. Newly added sets after the first edit are
blank. Text labels are supported, including the first 0/null mapping choice.
Editing an already completed workout does not auto-fill other saved sets.

On a later cycle's matching training day, tap **Use last record as template**
on the previous-record card or inside the workout editor. It copies all exercises,
sets, weight labels/mappings, reps and RIR, and resets first-set filling for this
new workout. Existing draft/editor inputs require replacement confirmation.
Review all copied values before finishing; importing is a draft, not completion,
and never changes the historical record. Cardio entries are not copied.

## Settings and data safety

Settings contains English, Simplified Chinese and system-language options. Your
choice is saved. About shows version, developers, source/profile links, privacy
information and license notices.

Version 1.2 has no restorable backup or JSON file export/import. Keep that limit
in mind before uninstalling or clearing app data. Clipboard logs are convenient
for review but cannot be imported to restore the database.

## Testing and troubleshooting

For a food preset, check the reference amount and unit first: nutrients per
100 g must not be entered as nutrients per bottle. Raw and cooked reference
values differ; product labels take precedence over the generic food library.
Blank nutrients remain unknown; enter 0 only when zero is genuinely known.

If meal totals seem unchanged, check whether Daily intake is a manual override.
Use Restore meal totals to return to aggregation. If training actions are locked,
check today's completed/rest/skip action; edit a completed workout or undo that
action before choosing another. A draft is not a completed workout.

To report a bug, use the repository's Issues page and include the app version,
Android version, language, exact steps, expected/actual result and a redacted
screenshot. Never post private food/body logs or a database without intending
to make them public. Nutrient references and PR curves are tracking aids, not
medical advice. See the repository's Food data document for reference sources.
