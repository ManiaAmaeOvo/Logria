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
- `lib/features/settings`: persisted language choice and software details.
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

Body values are recorded independently by type and local date. Partial updates
do not remove other values. Historical views never carry old measurements into
a day that has no measurement.

Dates use local `yyyy-MM-dd` keys. Timestamp-range queries use local-midnight
boundaries. Calendar colors indicate cycle spans and icons indicate real data;
explicit executions win over inferred spans on cycle boundary dates.

## Migration and exports

Schema 2 adds nullable meal nutrients and calorie-estimation metadata. Tests
cover preservation of older food notes. Any future migration must be additive
or provide a verified conversion; never solve upgrades by clearing storage.
Schema 3 adds nullable weight text, CardioLogs and PersonalRecords. Numeric set
values are not converted or overwritten. Migration tests cover older sets.

`docs/export/logria-health-log.schema.json` defines a planned, self-contained JSON
contract. No JSON file exporter/importer is wired into version 1.1.0. The current
sharing format is plain-text clipboard output from Today and Calendar.
