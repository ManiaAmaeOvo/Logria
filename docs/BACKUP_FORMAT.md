# Backup and dated export formats

## Restorable backup v1

Settings → Backup and export → Save full backup creates UTF-8 JSON with
`format: logria.backup`, `version: 1`, `database_schema: 7`, UTC `created_at`,
and `tables`: a map from each generated SQLite table name to all of its raw rows.
It includes plans, cycles, workouts/sets, variants, PRs, cardio, foods and ingredient
snapshots, nutrition targets/overrides, body types/measurements, sleep, reviews,
locale, drafts and undo recovery. Internal SQLite metadata is not exported.
Raw SQLite timestamp columns use epoch seconds; booleans use 0/1.

Files are **unencrypted** and limited to 32 MiB. The current reader accepts only
backup version 1 with database schema 7 and a complete, exact table/column set.
Future/incompatible schemas, invalid types, broken references, duplicate keys or
invalid nested JSON are rejected. Do not edit backup files. Restoration is a full
replacement, not a merge; schema/type validation precedes the confirmation and
all deletes/inserts plus reference/snapshot checks share one rollback transaction.
On success, the app reloads its saved locale and returns to a fresh Today page.
Always save the current data to another backup before replacing it.

Legacy installs may contain workout exercises/sets whose parent session was
already removed. Backup creation does not change the source database: it preserves
these complete raw rows in the inert `backup.orphanedWorkoutRows` AppSettings
archive inside the file and excludes them from live workout tables. Restoration
explicitly warns when this archive is present, keeps the archive, and does not
invent completed sessions or PRs. Export/read the JSON to inspect archived rows.
Other unsupported source-reference violations block backup creation rather than
silently producing an unrestorable file. Do not uninstall/clear storage on error.

Android's system document picker grants access only to the selected document.
The app adds no network or broad storage permissions. Choose local storage for
offline use; document providers installed by the user may offer cloud locations.
Cancellation writes no database records. Failed writes may leave an incomplete
document; the app reports failure and does not describe it as a successful backup.

## Dated analysis export v2

Settings → Backup and export → Export dated logs includes an inclusive date range
(maximum 3661 calendar dates) and optionally body measurements/sleep. Unchecking
Body omits the entire `body` object; it does not export measurement-type metadata.
The export has `format: logria.health_log`, `schema_version: 2` and a random export
ID. It is **not accepted by the restore action**. The original v1 schema was an
unimplemented design draft and is retained for reference, not as the current API.

Schema: [logria-health-log-v2.schema.json](export/logria-health-log-v2.schema.json).
Each day has explicit fitness actions, completed session/exercise/set snapshots,
cardio, manual PR entries, food/ingredient snapshots, effective daily nutrition,
and its review. No strength action means `implicit_rest: true`, not a fabricated
plan execution. Both manual daily overrides and calculated meal totals retain their
source. Unknown nutrition values remain null/absent, never invented zero.

Database row properties retain their Dart JSON names (e.g. `localDate`, `startedAt`,
`proteinGrams`). Row timestamps are Unix **milliseconds**; envelope `exported_at`
is ISO 8601 UTC. Set `rir` is string/null, `notes` is the independent set feeling;
exercise `notes` is separate variant metadata. Old numeric RIR becomes readable
text in the export without rewriting the database's old numeric column.
Composition ingredients have names, original units, quantity and scaled nutrient
snapshots; entry totals may be manually overridden and need not equal ingredients.
`time_zone` and current `utc_offset_minutes` describe the exporting device, not
an IANA historical timezone guarantee; explicit local date labels are authoritative.
The default journal cutoff is 04:00. Manually chosen and legacy dates stay unchanged.
