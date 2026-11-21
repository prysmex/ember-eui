---
title: Import and export
order: 12
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: import and export"/>
<EuiSpacer @size="l" />

<EuiText>

CSV out with `toCsv`, CSV in with `parseCsv`, `importMatrix` and
`api.appendRows`, and the import screen, `<EuiSheetImport>`.

## Export to CSV

The sheet has no export button: put one in `<:toolbar>` and call `toCsv`
with the records you want (usually all of them, not only a loaded page)
and the fields in order (the block's `fields`, plus `hiddenFields` if you
want those too):

```js
import { builtInFieldTypes, defaultMessages, toCsv } from '@ember-eui/sheet';

exportCsv = (sheet) => {
  const ctx = { types: { ...builtInFieldTypes, ...this.fieldTypes }, messages: defaultMessages };
  const text = toCsv(ctx, this.records, sheet.fields, { delimiter: ',' });
  // the BOM tells Excel the file is UTF-8, so accents survive
  const blob = new Blob(['﻿' + text], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = 'records.csv';
  link.click();
  URL.revokeObjectURL(url);
};
```

```hbs
<:toolbar as |sheet|>
  <EuiButtonEmpty @iconType="exportAction" {{on "click" (fn this.exportCsv sheet)}}>Export CSV</EuiButtonEmpty>
</:toolbar>
```

`ctx` is the `{ types, messages }` that `summarize` takes, with your
`@fieldTypes` merged over the built-ins. Each cell is the text a copy
gives (the type's `copyText`, else its `format`): dates as ISO, a
multi-select as its labels joined by `, `, attachments as their URLs.
Cells with the delimiter, a `"` or a line break are quoted (RFC 4180),
lines end with `\r\n`, and the first line has the labels (`headers:
false` leaves it out). `delimiter: ';'` suits Excel where the decimal
mark is a comma.

**Formulas.** A spreadsheet runs a cell that starts with `=`, `@`, `+` or
`-` as a formula, so a value typed as `=HYPERLINK(…)` could do something
when the file is opened (a CSV injection). With `escapeFormulas` (the
default) such a cell gets a leading `'`: a text that starts with `=`,
`@`, a tab or `\r`, or with `+` or `-` and is not a number as written
(`-5`, `+52 81 1234 5678` and `-12.5%` stay as they are). The rule looks only at the text, so it is
the same for every type. Pass `escapeFormulas: false` to write the texts
as they are (for a file that only a program reads).

Excel files (`.xlsx`) are not covered: that needs a library. Give your
library `rangeMatrix`'s texts (the same cells as `toCsv`).

## Import from CSV

An import goes through the same path as a paste on the add row: each
text is read by its field's type, linked records and users go to
`@onResolve`, what cannot be read shows as a rejection in its cell, and
Ctrl/Cmd+Z removes the whole import. There are three steps, and the file
picker is yours:

```js
import { importMatrix, parseCsv } from '@ember-eui/sheet';

importFile = async (sheet, event) => {
  const file = event.target.files[0];
  const matrix = parseCsv(await file.text());
  const { rows, fieldIds, unmatched } = importMatrix(matrix, [...sheet.fields, ...sheet.hiddenFields]);
  this.api.appendRows(rows, fieldIds);
  event.target.value = '';
};
```

```hbs
<:toolbar as |sheet|>
  <label>Import CSV <input type="file" accept=".csv,text/csv" {{on "change" (fn this.importFile sheet)}} /></label>
</:toolbar>
```

- **`parseCsv(text, { delimiter? })`** gives the texts, line by line. A
  leading byte-order mark is dropped; quoted cells can hold the
  delimiter, `""` and line breaks; one trailing empty line is dropped.
  Without `delimiter` it takes whichever of `,`, `;` and a tab appears
  most often in the first line, outside quotes (`,` on a tie). A
  one-column file with commas in its text is read as several columns:
  pass `delimiter` when you know it. `file.text()` reads UTF-8; a file
  Excel saved as windows-1252 shows odd characters (decode it yourself
  with `TextDecoder('windows-1252')`).
- **`importMatrix(matrix, fields, { headers = true, mapping? })`** maps
  the file's columns to fields. With `headers`, each header goes to the
  field with that name among its `importAliases`, else its label, else
  its id, ignoring case, accents, surrounding and repeated spaces, `_`
  and `-` (`Nombre_del producto` matches `nombre del producto`). A field
  takes at most one column: a later header that names a taken field is
  left out. `mapping` (`{ [columnIndex]: fieldId | null }`) overrides the
  match, for your own "map columns" step; `null` drops a column. Without
  `headers`, the columns go to `fields` by position. It returns `rows`
  (the lines, without the header line and blank lines, one text per
  entry of `fieldIds`), `fieldIds` (in the file's column order) and
  `unmatched` (the headers that went nowhere: show them). Pass the hidden
  fields too, so a file can fill a hidden column.
- **`api.appendRows(rows, fieldIds, { fields? })`** emits one change set
  (source `'paste'`, one insert per line, after the last record) and is
  one undo step. Column `j` goes to `fieldIds[j]`, visible or hidden,
  whatever the column order on screen; an id with no field is dropped.
  A field the file has no column for gets its value from
  `@newRecordValues` (called once per line, with the last record as
  `above`); the file's columns win, also when their text is rejected.
  Read-only fields are skipped, as in a paste. It returns `false` and
  emits nothing with `@canInsert={{false}}` (or no rows, or no known
  field). The selection does not move.
- **`fields`** are field definitions to read the texts with, by id,
  over `@fields`: a field you just created and that is not in `@fields`
  yet, or a copy for one column (`{ ...field, dateOrder: 'mdy' }` for a
  file with M/D/Y dates, `{ ...field, decimalSeparator: ',' }` for
  decimal commas). They are only used to read; the sheet stores nothing,
  and the records are keyed by field id as usual.

**Matching by other names.** `importAliases` on a field lists the names
it has in files, in any language:

```js
{ id: 'item', label: 'Item', importAliases: ['Producto', 'Artículo'] }
```

`matchHeader(header, fields)` is the matcher (`{ field, by: 'alias' |
'label' | 'id' }` or `null`) and `normalizeHeader(text)` its
normalisation, for an import step of your own.

**Groups.** Grouped, the lines go into the last record's group, as lines
pasted past the last record do, and that group's values win over the
file's: a file with a group column would have it overwritten. Import
with no group by.

**Large files.** `appendRows` does not split an import: 10,000 lines are
one change set and one undo step. For files that size, call it in chunks
of 1,000; each chunk is then its own undo step. Apply each change set
before the next call (a store that applies in `@onChange`, as
`localRecords`, does), since each chunk goes after the last record of
`@records`:

```js
for (let i = 0; i < rows.length; i += 1000) {
  this.api.appendRows(rows.slice(i, i + 1000), fieldIds);
}
```

Excel files: give `importMatrix` the matrix your library (SheetJS) reads.

### The import screen

`<EuiSheetImport>` is the step between the file and `appendRows` that
most apps would build themselves: it shows the file's columns with
three sample texts each, the type each column looks like, the field
each goes to (or a new field, or nothing), a transform and the column's
options, and a preview of the first lines as the import writes them,
with the totals of a dry run over every line. It is not tied to a
sheet: anything described by fields can be the target. It draws no
file picker and no modal, and keeps no state outside itself: place it
in your own modal, flyout or page.

```hbs
<EuiModal @onClose={{this.close}}>
  <EuiModalBody>
    <EuiSheetImport
      @fields={{this.fields}}
      @file={{this.file}}
      @transforms={{this.transforms}}
      @onCreateFields={{this.createFields}}
      @savedMapping={{this.savedMapping}}
      @onImport={{this.import}}
      @onCancel={{this.close}}
    />
  </EuiModalBody>
</EuiModal>
```

```js
import { EuiSheetImport } from '@ember-eui/sheet';

import = (result) => {
  if (result.mapping) this.savedMappings[result.mapping.signature] = result.mapping;
  this.api.appendRows(result.rows, result.fieldIds, { fields: result.fields });
  this.close();
};
```

| Argument | Description |
| --- | --- |
| `@fields` | The target fields, hidden ones included. Required. Fields with `readOnly: true` and buttons are not offered. |
| `@file` | A `File`: read as bytes, a byte-order mark dropped, decoded as UTF-8, else as windows-1252 (Excel's CSV on Windows), then `parseCsv`. |
| `@text` | The source as text, without `@file`. |
| `@matrix` | The source already parsed (`string[][]`, e.g. an Excel sheet read with SheetJS), without `@file` and `@text`. |
| `@onImport` | `(result) => void \| Promise`. Called once, on Import. A promise keeps the screen busy; a rejection shows its message. |
| `@onCancel` | Shows a Cancel button that calls it. |
| `@onCreateFields` | `(drafts) => fields \| Promise<fields>`. With it, a column can go to "New field…", and a column that matches no field does by default (one with no text, such as a trailing delimiter's, is skipped). Called once, on Import, with every new field's draft (`{ label, type, ...options }`) in column order; create the fields (you give the ids) and resolve with them in the same order. A rejection shows its message and imports nothing. |
| `@creatableFieldTypes` | The types a new field may have, in order. Default: the field editor's list. |
| `@transforms` | The named transforms a column can use (below). |
| `@savedMapping` | A mapping from an earlier import (`result.mapping`). Used when its header line is this file's; it wins over matching by name. |
| `@fieldTypes` | Your field types, merged over the built-ins (as the sheet's). |
| `@sampleSize` | Lines in the preview. Default 20. |
| `@messages` | Overrides of the messages (the `euiSheet.import*` tokens, through `eui-i18n` like the sheet's). |

**The screen**, top to bottom:

- **The file**: its name, the encoding found, the delimiter (`,`, `;` or
  tab; detected, and changeable), "First line is the header" (on), and
  the number of lines.
- **Columns**: for each file column, its header and three samples; a
  badge with its type and share (for a new or skipped column, the
  guess: "Date, D/M/Y · 98%"; for a column going to a field, how much of
  it that field's type reads); where it goes; its transform; its
  options; and its status ("25 of 25 read", or "3 can't be read", which
  shows those lines in the preview). A field takes one column: a header
  whose field another column took stays skipped and says so, and a
  taken field is disabled in the other columns' selects ("Item (in use
  by "Nombre")"); skip that column first to use the field elsewhere.
- **Preview**: the first lines with the target fields as columns, each
  value as the field shows it (a column read as M/D/Y into a D/M/Y field
  shows D/M/Y, as the sheet will), or an error with the type's message,
  "linked on import" (a linked record or user: resolved by
  `@onResolve` when appended), "new option" (a select option the import
  creates). Then the totals over every line ("18 lines ready, 2 with
  errors"), "Download the lines with errors" (the file's header line and
  those lines as CSV, to fix and import again), and the choice "Import
  all (errors stay as rejections)" or "Skip lines with errors".

**A column's options**, shown where they apply: **Trim spaces** (on);
**Empty is no value** (on: an empty text is no value, for a target that
is not a sheet; a sheet reads `''` as its type does); **Date format**
(D/M/Y or M/D/Y, date and date-time targets) and **Decimal separator**
(number, currency, percent). These read the column with a copy of the
field (`{ ...field, dateOrder: 'mdy' }`); the field itself does not
change, and `result.fields` carries the copy for `appendRows`. **Values**
(select and checkbox targets): the column's distinct texts (up to 50)
and what each becomes, prefilled where a text is an option's label or a
yes/no word (`sí`, `yes`, `true`, `1`, `x`; `no`, `false`, `0`). The
texts are the column's after its trim and transform, the ones the map is
applied to; a change of the transform keeps the choices made and
prefills the texts it brings.

The count messages have a form for one (`importLinesOne`, "Import 1
line"; `importLineCountOne`, `importLinesReadyOne`,
`importLinesWithErrorsOne`, `importValuesOne`, `importCantReadOne`,
`importReadOne` and `importPreviewOfOne` for a one-line file). An app
that overrides or translates only the plural one keeps it for one too.

**The result** (`SheetImportResult`):

| Key | |
| --- | --- |
| `rows` | One entry per line kept, one text per entry of `fieldIds`: the file's text after trim, the transform and the value map. A cell whose transform threw is `''`. |
| `fieldIds` | The field each column goes to; created fields by their new ids. |
| `fields` | The field each column was read with: the target, a per-column copy, or a created field. Pass them as `appendRows`' `fields`. |
| `createdFields` | The fields `@onCreateFields` returned. |
| `skippedLines` | The lines left out with "Skip lines with errors" (the header line is 0). |
| `lines`, `values` | Each row's line, and what each field's type reads from it (`undefined` where it cannot): for a target that is not a sheet. |
| `mapping` | To save and pass back as `@savedMapping`; `null` without a header line. |

**Transforms** are the app's, named: text in, text out, so the target
type still reads the result and the preview shows what the import
writes. Return `null` for an empty cell; throw to mark the cell as an
error with your message (its text is then `''`). They run on every
line, in the page: keep them pure and fast.

```js
transforms = [
  { id: 'firstName', label: 'Split full name: first part', apply: (text) => text.trim().split(/\s+/)[0] ?? '' },
  { id: 'cents', label: 'Cents to amount', apply: (text) => (text === '' ? null : String(Number(text) / 100)) },
  {
    id: 'excelDate',
    label: 'Excel serial date to D/M/Y',
    apply: (text) => {
      const date = new Date(Date.UTC(1899, 11, 30) + Number(text) * 86400000);
      if (Number.isNaN(date.getTime())) throw new Error(`"${text}" is not a serial date`);
      return `${date.getUTCDate()}/${date.getUTCMonth() + 1}/${date.getUTCFullYear()}`;
    },
  },
];
```

`apply(text, { line, header, row })` also gets the line's index in the
file, the column's header and the line's texts by header, for a
transform that combines columns.

**Matching and saved mappings.** Each header goes to a field by the
saved mapping, then `importAliases`, then label, then id (the matcher of
`importMatrix`). `result.mapping` is keyed by `signature`, the file's
normalised header line (`importSignature(headers)`): keep the mappings
you want by signature and pass the one for the next file's header line
(or simply the last one: a mapping whose signature is not the file's is
ignored). Without a header line, columns go to the fields by position
and no mapping is returned.

**Guesses.** A column's type is guessed with the types' own `parse`
over up to 200 texts (the first type that reads 95 % of them, most
specific first: checkbox, date, date and time, percent, currency,
number, email, url, phone, single select, long text, text), only among
`@creatableFieldTypes`. A column with a time of day (`2026-11-19T10:30`)
guesses date and time before date, when date and time is among them;
one written as phone numbers (`+52 81 1234 5678`, `(81) 1234-5678`)
guesses phone before number (plain digits stay numbers). The guess proposes a new field's type and
options (a select's options from the texts, the date order, the decimal
separator); it never changes a column going to an existing field. A
guessed currency gets the code its texts name when they all name the
same one (`MXN 300`, `12 €`, `£4`), else `USD` (a `$` alone could be
dollars or pesos); change it in the new field's form.

**New fields.** "Edit the new field" opens the field editor's form
(name, type, the type's options, description, required) under the
column; nothing is created until Import. With `localRecords`:

```js
createFields = (drafts) =>
  drafts.map((draft) => {
    this.store.createField(draft, { index: this.store.fields.length });
    return this.store.fields.at(-1);
  });
```

If `@onImport` rejects after the fields were created, the columns stay
on the created fields, so Import again does not create them twice.

**What stays the app's**: the file picker, the modal, creating fields
(the ids are yours), saving mappings, and chunking a large file: the
result has every line, so call `appendRows` per 1,000 rows as above.
The preview and the guesses read samples; the dry run reads every line
once per change of a column, 250 ms after the last change (a
10,000-line, 20-column dry run took about 70 ms in Chromium).

</EuiText>

<EuiSpacer @size="xl" />

<EuiText>

## Examples

</EuiText>

[[demos-all]]
