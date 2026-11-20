# 07. CSV import: `parseCsv`, `importMatrix`, `api.appendRows`

## Why

"Start from my spreadsheet." Handsontable imports files, RevoGrid Pro
imports Excel, and NocoDB imports CSV (`../FEATURE-RESEARCH.md` row 8).
The sheet already reads pasted text through each type's `parse`, resolves
linked records and users, shows what it could not read, and undoes a paste
as one step. An import should do exactly that, so it goes through the same
path.

## API

There are three small steps. The app does the file picking.

```ts
import { parseCsv, importMatrix } from '@ember-eui/sheet/core';

const text = await file.text();
const matrix = parseCsv(text);                 // string[][]
const { rows, fieldIds, unmatched } = importMatrix(matrix, fields);
// rows: the lines, header line removed, one column per entry of fieldIds
// fieldIds: the field each column goes to
// unmatched: header texts that match no field
api.appendRows(rows, fieldIds);                // like a paste on the add row
```

- `parseCsv(text, { delimiter? })`. Without `delimiter`, it takes whichever
  of `,`, `;` and a tab appears most often in the first line, outside
  quotes.
- `importMatrix(matrix, fields, { headers = true, mapping? })`:
  - With `headers`, the first line is matched to the fields: by label,
    then by id, ignoring case and surrounding spaces.
  - `mapping` (`{ [columnIndex]: fieldId | null }`) overrides the match,
    for an app that shows its own "map columns" step.
  - A column with no field is dropped and listed in `unmatched`.
  - `fields` may include hidden fields (the block API's `fields` and
    `hiddenFields` together), so a file can fill a hidden column.
- `api.appendRows(rows, fieldIds)`: pastes the rows as new records after
  the last one, the way a paste on the add row does. The columns go to
  `fieldIds`, **not** to the visible columns by position, so a local
  column order or a hidden field cannot shift the values. The sheet builds
  the paste's context from those fields (visible or hidden); an unknown id
  is skipped. A field the file does not have is left out of the insert, so
  `@newRecordValues` gives it a value.

## Behaviour

- **`appendRows` is the paste path** (`buildPaste`,
  `core/paste-plan.ts:59`, anchored at the first new row, with a context
  whose `fields` are `fieldIds`' fields in that order):
  - one change set with one insert per line;
  - `@onResolve` for linked records and users;
  - texts that could not be read show as rejections in the new rows;
  - one undo step;
  - `source: 'paste'`.
- With `@canInsert` false, `appendRows` does nothing and returns `false`.
- Read-only fields are skipped, as in a paste.
- **Groups:** the rows become inserts in the last group, as lines pasted
  past the last record do (V03 8.5, D14). The group's values win over the
  file's, as for an add row (V03 8.4), so a grouped view would overwrite
  the file's group column. The docs say to import with no group by; AR5
  pins the rule.
- **Large files.** 10,000 lines is one change set and one undo entry. The
  docs say to call `appendRows` in chunks of 1,000 for files that size;
  each chunk is then its own undo step.
- **Not covered:**
  - Excel files: an app with SheetJS passes its matrix to
    `importMatrix`;
  - guessing field types from the data (a "maybe" in the research).

## Code

- `src/core/csv.ts`:
  - `parseCsv` is about 40 lines. It reuses `parseTsv`'s quoting rules
    (`core/tsv.ts:10`) with the delimiter as a parameter, so `parseTsv`
    becomes `parseCsv(text, { delimiter: '\t' })` inside;
  - `importMatrix` is about 40 lines.
- The API module: `appendRows`, about 20 lines. It calls the code that the
  add row's paste calls.
- `core/index.ts`: the exports.

## Tests

`tests/unit/csv-test.ts`:

- **CI1:** quoted cells with commas and line breaks, `\r\n` line ends, and
  a trailing empty line dropped.
- **CI2:** the delimiter is detected for `,`, `;` and tab files.
- **CI3:** headers are matched by label, by id, and case-insensitively; an
  extra column is in `unmatched`; `fieldIds` follows the file's column
  order.
- **CI4:** `mapping` overrides a header match.
- **CI5:** a round trip: `parseCsv(toCsv(ctx, records, fields, {
  escapeFormulas: false }))`, through `importMatrix`, gives the same texts
  (with escaping on, an escaped cell keeps its `'`, by design).

`tests/integration/components/eui-sheet-append-rows-test.gts`:

- **AR1:** `appendRows` emits one change set with one insert per row.
  Ctrl/Cmd+Z removes them all.
- **AR2:** a bad number is a rejection in the new row, shown as in a
  paste.
- **AR3:** a user column goes through `@onResolve`.
- **AR4:** with `@canInsert={{false}}`, nothing is emitted and it returns
  `false`.
- **AR5:** with the columns in another order than the sheet's and one of
  them a hidden field, every value lands in its own field. In a grouped
  view, the group field takes the last group's value.

## Docs

A section "Import from CSV": the three steps, with a file input in the
toolbar, and the chunking advice.

## Risks

- **Delimiter detection can guess wrong** on a one-column file with commas
  in the text. The app can pass `delimiter`. The docs say so.
- **Header matching by label** fails on translated labels. `mapping` is
  the way out.
