# Privacy and local data

Logria stores records in SQLite on the current Android device. It has no user
accounts, cloud synchronization, advertising, analytics or built-in LLM calls.
The release app does not declare the Android INTERNET permission. Flutter debug
and profile builds use network permission for development tooling.

Workout drafts also remain in local SQLite, including incomplete raw input.
Drafts are keyed by date and workout/day and removed when that workout is saved.
Cardio logs, manual PR entries and selected tracking preferences are local only.
Daily review notes are also local and are included when copying whole-day logs.
Food/meal presets, ingredient quantities and optional mineral/fiber entries stay
in local SQLite. Built-in USDA values are bundled and never fetched at runtime.
Changing/deleting a food preset does not remove logged food snapshots. Exercise
variant notes create separate local presets; no account or network call is involved.
Restarting a cycle retains health history but discards its unfinished day drafts
and clears undo recovery after explicit confirmation.
Undo keeps one local snapshot of the removed action so it can be restored on the
same date. An unavailable snapshot may remain in SQLite until replaced or cleared
by a new strength-cycle action. Nothing is transmitted for undo or redo.

The app requests that Android automatic backup be disabled. No backup or restore
UI is provided in the current version. Uninstalling the app or clearing its storage can
remove its records. Clipboard copying is text sharing, not a restorable backup.

Copy buttons place selected logs on Android's system clipboard. You decide
whether to paste them into another app or send them to an LLM. Other apps and
the operating system apply their own clipboard and privacy rules.

GitHub links open the external browser only when selected. Any subsequent
network traffic belongs to the browser and GitHub, not log storage.

Please use synthetic data in public bug reports. The app's storage is protected
by Android's app sandbox; Logria does not add database encryption in this version.
