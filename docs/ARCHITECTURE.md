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
Rest can consume a later planned rest slot without advancing pending training.

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

`docs/export/logria-health-log.schema.json` defines a planned, self-contained JSON
contract. No JSON file exporter/importer is wired into version 1.0.0. The current
sharing format is plain-text clipboard output from Today and Calendar.
