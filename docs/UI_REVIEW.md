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
