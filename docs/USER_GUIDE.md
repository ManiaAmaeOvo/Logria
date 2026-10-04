# Using Logria 1.1

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

## Body measurements

Select a date, then tap a metric chip to record just that measurement, or use the
plus button to enter several measurements. Existing measurements can be edited
or deleted. Blank editor fields preserve values; use Delete to remove them.

Select a metric in Trends & history and choose 30 days, 90 days or All. Dates
without measurements are not filled in. Tap a historical value to jump to its date.

## Daily review and sharing

Today combines complete workout sets, meal notes/nutrients, daily nutrition totals
and measurements recorded today. Copy everything with the top button or use the
copy icon on a section. The arrow opens its corresponding module.

Calendar marks recorded activity by icon and training-round spans by color. Tap
a date and scroll to its logs below the calendar. The cycle selector locates its
start and dims dates outside that round. Dimmed past dates are still selectable.
Tap Today to return to the current month/date and clear the cycle highlight.

Copying from Calendar uses the selected date, not today. Both copy flows re-read
the database first, include units/date and label unknown values with a dash.

## Settings and data safety

Settings contains English, Simplified Chinese and system-language options. Your
choice is saved. About shows version, developers, source/profile links, privacy
information and license notices.

Version 1.1 has no restorable backup or JSON file export/import. Keep that limit
in mind before uninstalling or clearing app data. Clipboard logs are convenient
for review but cannot be imported to restore the database.
