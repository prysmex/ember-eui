---
title: The import screen
order: 92
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: the import screen"/>
<EuiSpacer @size="l" />

<EuiText>

`<EuiSheetImport>`: the step between a file and `appendRows`, with the
mapping of columns to fields, transforms, value maps, new fields and a
preview.

## The import screen

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
result has every line, so call `appendRows` per 1,000 rows as [CSV paste and import](/docs/sheet/docs/sheet/import-export/csv-import#import-from-csv) shows.
The preview and the guesses read samples; the dry run reads every line
once per change of a column, 250 ms after the last change (a
10,000-line, 20-column dry run took about 70 ms in Chromium). A new
file's first dry run waits until its preview is on screen: meanwhile the
totals read "Checking the lines…", each column's status is empty and its
badge shows the type without the share, and "Import N lines" counts
every line (the import reads the lines itself, so it can start before
the run).

## Related

- [CSV paste and import](/docs/sheet/docs/sheet/import-export/csv-import)
- [The example app](/docs/sheet/docs/sheet/example-app): a supplier's file
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
