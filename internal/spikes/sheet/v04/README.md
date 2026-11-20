# `@ember-eui/sheet` v0.4: design of the recommended features

Written 2026-11-19, design only. Nothing here is built. The features are
the "worth it" rows of `../FEATURE-RESEARCH.md`; that file has the
evidence and the reasons.

There is one short file per feature. Each file has the same parts:
why, API, behaviour, code, tests, docs, risks.

## When

Only after every v0.3 batch is finished: 3b, 3c, 4 and 5 (the user's
decision, 2026-11-19). Nothing of v0.4 is built before that, not even the
pure helpers.

- Seven of the nine features change the component, and they are placed in
  the modules 3c makes.
- Feature 08 (cell colour) reuses batch 4's row-colour tokens.

## Rules

V03-DESIGN.md section 1 applies unchanged:

- the sheet is a pure view of the owner's rows;
- data goes down and actions go up;
- every write is a change set;
- there is no built-in toolbar;
- `packages/core/src` does not change.

On top of that, for this version:

- **One feature, one place.** Each feature lives in its own small file, or
  in the one module 3c makes for its area (the header menu, the row menu,
  the cells). The component only passes its arguments in and wires the
  result. No new base classes, registries or plugin hooks.
- **Pure parts in `src/core`, DOM parts in `src/-private`.** A helper an
  app can call without a sheet is pure and exported from
  `@ember-eui/sheet/core`.
- **Per-cell hooks return data and are measured** (decided 2026-11-19).
  Feature 08 is the only one, and its file sets the measurement.

## The features

| # | File | Feature | Area | Source lines (est.) | Test lines (est.) |
| --- | --- | --- | --- | --- | --- |
| 01 | `01-fit-width.md` | Fit a column to its content | header menu, resizer | 160 | 160 |
| 02 | `02-full-screen.md` | Full screen | wrapper | 100 | 120 |
| 03 | `03-field-actions.md` | App items in the header menu | header menu | 40 | 60 |
| 04 | `04-record-footer.md` | A block below the fields of the expanded record | expanded record | 30 | 60 |
| 05 | `05-copy-with-names.md` | Copy with field names | row menu | 30 | 50 |
| 06 | `06-csv-export.md` | `toCsv` | `src/core/csv.ts` | 70 | 90 |
| 07 | `07-csv-import.md` | `parseCsv`, `importMatrix`, `api.appendRows` (the research's `importRows`, split in two) | `src/core/csv.ts`, API | 110 | 140 |
| 08 | `08-cell-color.md` | `@cellColor` | cells | 60 | 90 |
| 09 | `09-visible-range.md` | `@onVisibleRangeChange` (load more) | grid options | 70 | 100 |
| 10 | `10-import-screen.md` | `<EuiSheetImport>`: map columns, guess types, preview, transforms, create fields (added 2026-11-20) | new component, `src/core/import.ts` | 850 | 600 |

The total is about 670 source lines. Line counts are estimates, scaled
against the V03 batch table.

## Batches

Each batch is complete on its own (code, tests, docs) and committed on
`feat/sheet`, as before.

The letters are the ones in `../FEATURE-RESEARCH.md`.

| Order | Batch | Features |
| --- | --- | --- |
| 1 | D | 09 load more |
| 2 | A | 01, 02, 03, 04, 05 (presentation and menus) |
| 3 | B | 06, 07 (CSV in and out) |
| 4 | C | 08 cell colour |
| 5 | E | 10 the import screen (after B: it builds on 07, and 10 lists three small additions to B) |

The user chose this order: load more first. After D, the batches are
independent of each other, so the order of A, B and C can change if
needed.

## Where the code goes

3c's design names the modules. If its names differ from these, follow 3c.

| Feature | New file | Small additions to |
| --- | --- | --- |
| 01 | `src/-private/fit-width.ts` | the header-menu module; `contentWidth` on 5 built-in types |
| 02 | `src/-private/full-screen.ts` | `styles.ts`; the wrapper template |
| 03 | none | `types.ts` (`SheetFieldAction`); the header-menu module |
| 04 | none | `record-shells.gts`; the component template |
| 05 | none | the row-menu module; `core/tsv.ts` (`headerLine`) |
| 06 | `src/core/csv.ts` | `core/index.ts` export |
| 07 | (same `csv.ts`) | the API module (`appendRows`) |
| 08 | none | the cells module (where batch 4's row colour lives) |
| 09 | `src/-private/visible-range.ts` | the grid-options getter (`virtualizationOptions`) |

Tests: one integration file per component feature
(`tests/integration/components/eui-sheet-<feature>-test.gts`), and one unit
file per pure module (`csv-test.ts`, `fit-width-test.ts`,
`visible-range-test.ts` in `tests/unit/`). No existing test changes.

## Shared additions

- **Messages** (tokens in `core/messages.ts`, translated through
  `eui-i18n` like the others): `fitToContent`, `fitAllFields`,
  `enterFullScreen`, `exitFullScreen`, `copyWithFieldNames`.
- **`SheetApi`**: `fitField(fieldId)`, `fitFields()`,
  `setFullScreen(on)`, `appendRows(rows, fieldIds)`.
- **Block API**: `isFullScreen`, `setFullScreen(on)`.
- **Arguments**: `@fullScreen`, `@onFullScreenChange`, `@fieldActions`,
  `@cellColor`, `@onVisibleRangeChange`.
- **Blocks**: `<:recordFooter>`.
- Every addition is optional. Without it, the sheet behaves exactly as in
  v0.3.

## Not in this version

These are the "maybe" rows of `../FEATURE-RESEARCH.md`. Each needs a
measurement or a user decision first:

- auto row height (measure the scroll cost first, like FZ9);
- custom fill series;
- cell tooltips;
- a `time` type;
- a paste that adds fields;
- a bulk-edit form;
- `api.flash`;
- undo of field operations;
- markdown long text;
- tree data.

## Decided (the user, 2026-11-19)

1. Feature 08 is drawn as a bar along the bottom edge of the cell, not as
   coloured text.
2. Batch D (load more) comes first.
3. `api.appendRows` (07) does not split large imports. Chunking is the
   app's job, and the docs say how.
4. v0.4 starts only after batches 3b, 3c, 4 and 5 are finished.

## Decided (the user, 2026-11-20)

5. An import screen (10) in the package, reusable for any target described
   by fields (not only a sheet). v1 creates fields from unmatched columns
   and has named transforms defined by the app; user-typed expressions
   are not in v1. It is batch E, after B, and B is built with the three
   additions 10 lists.
6. Guessing field types on import is in, as a suggestion for a new
   field's type (10, "Guessing a type").
