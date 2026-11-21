---
title: CSV paste and import
order: 91
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: CSV paste and import"/>
<EuiSpacer @size="l" />

<EuiText>

CSV in with `parseCsv`, `importMatrix` and `api.appendRows`: the lines
go through the same path as a paste on the add row, and one Ctrl/Cmd+Z
removes them.

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

## Related

- [The import screen](/docs/sheet/docs/sheet/import-export/import-screen)
- [Validation while pasting and importing](/docs/sheet/docs/sheet/validation/paste-and-import)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
