# Version 1 UI review

## Findings and changes

| Finding | Release change |
| --- | --- |
| Calendar numerals could wrap to two lines in narrow cells with larger text. | Single-line numerals scale down within the cell; row height follows text scale. |
| Long calendar legend labels could overflow horizontally. | Legend text now wraps inside its available width. |
| Nutrition values could push progress labels outside the card. | Progress values and labels use flexible widths and right-aligned wrapping. |
| Settings was a small language-only sheet with no software information. | A scrollable Settings page now groups branding, language and About details. |
| Language choice was lost after app restart. | Persisted local preference and restoration checks. |
| Flutter's stock launcher icon did not identify the project. | Original L/three-column artwork plus adaptive and monochrome Android variants. |
| Cards, inputs and top-level branding lacked consistency. | Shared soft-green cards, restrained borders, rounded outlined fields and app icon. |

Release validation uses a 360×800 logical-pixel phone at 1.6× text scale in both
English and Simplified Chinese. Checks cover all five modules, lower scroll
content and About information. The Android emulator is also inspected visually.

## Design direction

Keep a calm journal-style layout: warm off-white background, deep green for
primary actions, muted green surfaces and a small amber accent in branding.
Preserve clear text and large touch targets. Do not use color alone to convey
activity; calendar icons and descriptive accessibility labels remain present.

For later releases:

- Replace long log paragraphs with structured, expandable day-detail cards,
  while keeping clipboard output complete.
- Add an optional bottom-sheet date review to reduce calendar scrolling.
- Improve chart inspection with date/value tooltips and comparison summaries.
- Refine goal/limit visuals without hiding unknown or manually overridden values.
- Add dark mode and broader screen-reader/2× text-scale coverage.

The first release prioritizes legible recording and review over animations.

## Local 1.2.0 review

Daily review is an inline multiline field in Today with an explicit Save action;
its hint explains that saved notes join whole-day copying. Restart sits in the
Fitness overflow menu with a preservation/discard confirmation. Previous-record
cards retain history navigation and add a separate template action. The editor
explains one-shot filling rather than silently changing later sets indefinitely.

Calendar activity indicators wrap to accommodate note markers on narrow phones.
57 local tests pass, including English/Chinese restart confirmation and starting
day selection at 360×800 / 1.6× text scale, protected lower-set fields, imported
templates, draft restoration, date-bound notes and additive schema migration.
The Today note card was visually inspected on the upgraded Android emulator.

Build 6 adds a searchable food library, explicit amount preview, and separate
food label/reference editors. Long preparation dropdown values wrap rather than
overflow at 360×800 / 1.6× text scale. Energy editing retains the user's explicit
label values; optional extra nutrients are collapsed in ordinary meal/target
dialogs. The full 71-test suite covers both English and Simplified Chinese flows.

Build 7 adds quick selection directly in the Food log card. Search and amount
dialogs reuse existing presets without navigating into management. Cancellation,
no-match search, visible keyboard, selected-date logging and fractional amounts
are checked at 360×800 with 1.6× English/Chinese text. All 77 tests pass.
Nutrition summaries/conversions and numeric shared logs use at most four decimal
places. Settings links to section-based, bilingual offline manuals; switching
manual language resets scroll to the introduction.
