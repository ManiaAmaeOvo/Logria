# Privacy and local data

Logria stores records in SQLite on the current Android device. It has no user
accounts, cloud synchronization, advertising, analytics or built-in LLM calls.
The release app does not declare the Android INTERNET permission. Flutter debug
and profile builds use network permission for development tooling.

The app requests that Android automatic backup be disabled. No backup or restore
UI is provided in version 1.0.0. Uninstalling the app or clearing its storage can
remove its records. Clipboard copying is text sharing, not a restorable backup.

Copy buttons place selected logs on Android's system clipboard. You decide
whether to paste them into another app or send them to an LLM. Other apps and
the operating system apply their own clipboard and privacy rules.

GitHub links open the external browser only when selected. Any subsequent
network traffic belongs to the browser and GitHub, not log storage.

Please use synthetic data in public bug reports. The app's storage is protected
by Android's app sandbox; Logria does not add database encryption in this version.
