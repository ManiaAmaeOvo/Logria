# Architecture

Logria is a Flutter/Dart application targeting Android. It is independent of
Summa and does not share its data, repository or services.

- `lib/app`: Material theme, language restoration and five-tab shell.
- `lib/core/database`: Drift tables, generated SQLite bindings and migrations.
- `lib/features/fitness`: training-cycle domain logic, plans and workout history.
- `lib/features/nutrition`: optional meal nutrients, daily overrides and targets.
- `lib/features/body`: measurement presets, partial updates and trend rendering.
- `lib/features/today`: transactional day reads and shared human-readable logs.
- `lib/features/calendar`: month markers and training-cycle date attribution.
- `lib/features/settings`: persisted language choice, software details and offline manuals.
- `lib/l10n/arb`: authoritative English and Simplified Chinese localization.

## Data behavior

Workout details retain exercise/day/plan name snapshots. Only one fitness action
may be recorded for a local day; repository transaction guards enforce this.
Independent cardio entries do not consume a cycle day or lock strength actions.
Rest can consume a later planned rest slot without advancing pending training.

Starting-day overrides store earlier plan-day IDs under a cycle-specific setting.
Progress treats those IDs as consumed, but the UI distinguishes them as unrecorded;
no cycle execution or workout history is inserted. An override is restricted to
an unrecorded cycle without a current draft and does not carry to the next cycle.

Undo retains a local JSON snapshot of the execution, workout/exercises/sets,
original cycle and any next-cycle rollover before deleting the live action.
Redo validates the local date, active plan/day/exercise-target signature, unchanged
post-undo cycle and remaining executions, then atomically restores original rows.
A new cycle action clears the snapshot; changing the start or switching plans
also clears it. No schema upgrade is needed for these AppSettings records.

Workout drafts store raw input JSON in AppSettings keyed by date and session/day.
Writes are serialized, debounced and flushed on exit/background. Completion
removes the corresponding draft after committing the workout. Drafts are not
reported as completed activity. Text weights use `weightText` alongside nullable
numeric `weightValue`, with an explicit 0/null choice. PR reads completed sets
live, groups numeric loads by date, and combines separate manual PR entries for
display. Opt-in tracked names are persisted; stopping tracking preserves data.

Food descriptions can exist without nutrients. Automatic daily totals sum known
meal values; missing values remain unrecorded. A manually edited daily total
overrides meal aggregation until explicitly restored. Goal/limit modes are
independent per nutrient and stored in app settings.

FoodPresets stores an explicit reference quantity/unit/preparation and validated
nutrient JSON in canonical units. Built-in IDs are `usda:<FDC ID>` and seed lazily;
user preset IDs are UUIDs. Read-only references are copied rather than overwritten.
Each logged food stores scaled values and quantity/unit/preset-ID provenance.
The preset ID has no destructive foreign-key dependency: editing/deleting a
preset cannot alter an old log. No label densities or cooking yields are assumed.

Optional sodium/potassium/calcium/iron (mg) and fiber (g) maps are stored separately
from nullable P/C/F/kcal columns. Missing keys mean unknown; explicit zero is
retained. Manual daily records override all nutrients. JSON AppSettings retains
extra-nutrient target values and goal/minimum/limit modes. Partial meal totals
suppress accurate remaining-allowance claims, while known over-limit values
still show that recorded intake exceeded the limit.

Exercise variants use independent preset IDs and decorated names. Preset notes
store tagged base/variant metadata; workout notes retain the descriptor snapshot.
Changing a plan item replaces only its preset reference. Old sessions are not
updated. Canonical variant names keep case-only aliases in one PR series.

Body values are recorded independently by type and local date. Partial updates
do not remove other values. Historical views never carry old measurements into
a day that has no measurement.

Dates use local `yyyy-MM-dd` keys. Timestamp-range queries use local-midnight
boundaries. Calendar colors indicate cycle spans and icons indicate real data;
explicit executions win over inferred spans on cycle boundary dates.

Quick food selection is a searchable dialog within the meal log, followed by
the shared quantity preview. It captures the selected date before opening and
uses the same preset snapshot repository as the library. Cancellation writes no
food record. A shared numeric formatter rounds presentation to at most four
decimals; stored calculations are not rounded by that formatter.

English and Chinese manuals are `docs/USER_GUIDE.md` and
`docs/USER_GUIDE.zh-CN.md`, declared as Flutter assets. Settings reads these same
files offline and displays expandable sections with selectable text. The manual
language switch is independent of the saved application locale.

DailyNotes is keyed by local date with review text and update time. Empty saves
delete only that note. Today/Calendar transactional reads include it; whole-day
clipboard output includes saved notes while module-only output does not.

Restart atomically marks the active cycle `interrupted`, sets its end timestamp,
clears this plan's unfinished day drafts and redo state, and opens the next unique
cycle number. History and plan/exercise IDs are preserved. The daily-action guard
still applies; fresh cycle entry overrides remain separate from real executions.

First-set filling uses user-only onChanged events and focus boundaries, separately
for weight and reps. Lower fields track manual edits. Serialized draft flags
treat an in-progress first edit as consumed on restoration. Historical editors
disable filling; imported templates reset flags while copying raw weight mapping
and all recorded set values. Programmatic copying does not mark lower fields edited.

## Migration and exports

Schema 2 adds nullable meal nutrients and calorie-estimation metadata. Tests
cover preservation of older food notes. Any future migration must be additive
or provide a verified conversion; never solve upgrades by clearing storage.
Schema 3 adds nullable weight text, CardioLogs and PersonalRecords. Numeric set
values are not converted or overwritten. Migration tests cover older sets.
Schema 4 adds DailyNotes. Existing tables and their rows are unchanged.
Schema 5 adds FoodPresets, nullable extra-nutrient JSON and food quantity/preset
snapshot metadata. Migration tests retain old meal numbers and daily notes.

`docs/export/logria-health-log.schema.json` defines a planned, self-contained JSON
contract. No JSON file exporter/importer is wired into the current version. The current
sharing format is plain-text clipboard output from Today and Calendar.
