# Offline food references and label entry

[简体中文](FOOD_DATA.zh-CN.md)

Logria includes a small, static selection from the public USDA FoodData Central
[SR Legacy dataset, April 2018](https://fdc.nal.usda.gov/download-datasets/).
The CSV archive was checked on 2026-10-05. All values are per **100 g edible
portion**, including milk (by weight, not an assumed gram/mL conversion).

| FDC ID | Reference food | Basis |
| --- | --- | --- |
| 171077 | Skinless, boneless chicken breast, meat only | Raw |
| 171477 | Chicken breast, meat only, roasted | Cooked |
| 169756 | White long-grain rice, regular, unenriched | Raw |
| 169757 | White long-grain rice, unenriched, without salt | Cooked |
| 169705 | Oats | Dry |
| 173424 | Whole egg, hard-boiled | Cooked, peeled |
| 175167 | Atlantic salmon, farmed | Raw |
| 172475 | Firm tofu prepared with calcium sulfate | Raw |
| 171267 | Milk, 2% fat, with added vitamins A/D | Packaged, by weight |
| 173944 | Banana | Raw, peeled |
| 170379 | Broccoli | Raw |
| 170026 | Potato, flesh and skin | Raw |

Selected USDA nutrient IDs are 1003 (protein), 1005 (carbohydrate), 1004 (fat),
1008 (kcal), 1093 (sodium), 1092 (potassium), 1087 (calcium), 1089 (iron), and
1079 (fiber). Canonical quantities use grams for macros/fiber and milligrams for
minerals. The original dataset's energy is kept, not recomputed with 4/4/9 factors.
Each built-in preset displays its source/FDC ID. These are generic estimates,
not exact measurements of a particular brand, recipe, seasoning or cooking yield.

References seed into local SQLite when opening the food library or quick picker. Runtime
does not use the USDA API, fetch updates or require Internet permission. Built-in
records cannot be overwritten; copies are ordinary editable user presets. USDA
food composition data are public domain; this does not imply USDA endorsement.

## Label-based products and homemade meals

Enter nutrients against one explicit reference amount: 100 g, 30 g powder,
250 mL milk, 1 bottle, 1 scoop, or 1 portion of a complete dinner. Units never
convert grams to portions or mL automatically. For a complete meal preset, enter
the combined totals for the stated number of portions; logging half/two portions
scales those totals. There is no automatic ingredient-recipe builder yet.

P/C/F initially calculate kcal using 4P + 4C + 9F. Editing either energy field
switches to manual energy and converts the other using **1 kcal = 4.184 kJ**,
as specified by [NIST](https://www.nist.gov/pml/special-publication-811/nist-guide-si-appendix-b-conversion-factors/nist-guide-si-appendix-b8).
Later macro edits retain manual energy; explicitly turn estimation back on to
recalculate. Display values are rounded; kcal is the canonical stored unit.

Missing nutrients remain unrecorded, not zero. Day totals sum only known values.
Opt-in goal/minimum/limit modes are bookkeeping aids, not personalized medical
recommendations. No mineral/fiber targets or intake standards are prefilled.
