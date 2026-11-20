# 06. CSV export: `toCsv`

## Why

"Download what I see." AG Grid Community, RevoGrid and Handsontable
export CSV (`../FEATURE-RESEARCH.md` row 7). The sheet has no toolbar, so
this is a helper: the app calls it from its own button.

## API

```ts
import { toCsv } from '@ember-eui/sheet/core';

const text = toCsv({ types, messages }, records, fields, {
  delimiter: ',',    // default ','; ';' for Excel in Spanish-speaking locales
  headers: true,     // default true: a first line with the labels
  escapeFormulas: true // default true (see below)
});
```

- The first argument is the same `{ types, messages }` context that
  `summarize` takes (`core/summary.ts:40`); `types` is the merged registry,
  as the sheet has it.
- `records`: whatever the app wants exported, usually all of them, not
  only the loaded page.
- `fields`: the columns in order. The block API's `fields` and
  `hiddenFields` give the view's.

## Behaviour

- Each cell is the type's `copyText(value)` (default `format`), the same
  text a copy gives:
  - dates as ISO;
  - a multi-select as its labels joined by `, `;
  - attachments as their URLs.
- Quoting follows RFC 4180. A cell with the delimiter, a `"`, a `\r` or a
  `\n` is quoted, and a `"` inside it is doubled. Lines end with `\r\n`.
- **Formula injection.** With `escapeFormulas` (default true), a cell gets
  a leading `'` when its text starts with `=`, `@`, a tab or a `\r`, or
  with `+` or `-` **and** it is not a number as written (`/^[+-]?[\d.,\s]+%?$/`).
  So `=SUM(A1)` and `-cmd|…` are escaped, while `-5`, `+52 81 1234 5678`
  (a phone) and `-12.5%` are not. The rule looks only at the text, so it
  is the same for every type, an app's too. This stops a spreadsheet from
  running the cell (a CSV injection). The docs explain the option.
- Downloading is the app's: the docs show the five lines (a `Blob`, an
  `<a download>`). There is no DOM helper.
- Excel files are not covered: that needs a dependency. An app can pass
  `rangeMatrix`'s output to its own library.

## Code

- `src/core/csv.ts` (new; also holds 07's parser). `toCsv` is about
  50 lines. It reuses `rangeMatrix` (`core/change-set.ts:64`) with a
  context built from the arguments, and `headerLine` (05).
- `core/index.ts`: the export.

## Tests (`tests/unit/csv-test.ts`)

- **CX1:** text, number, date and multi-select fields give the expected
  CSV, with a header line.
- **CX2:** quoting: a comma, a quote and a line break.
- **CX3:** `delimiter: ';'` quotes cells with `;` and not cells with `,`.
- **CX4:** `=SUM(A1)` and `@x` in a text field get the `'`. `-5` in a
  number field, `+52 81 1234 5678` in a phone field and `-12.5%` stay as
  they are. `-a` in a text field gets the `'`.
- **CX5:** `headers: false` leaves out the first line.
- **CX6:** an app type's `copyText` is used.

## Docs

A section "Export to CSV", with the toolbar button example.

## Risks

- The `'` prefix changes the text that is exported. That is why it is an
  option. The default is the safe one.
