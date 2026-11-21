# 10. The import screen: `<EuiSheetImport>`

Written 2026-11-20, design only. It builds on feature 07 (`parseCsv`,
`importMatrix`, `api.appendRows`), so it is batch E, after batch B.

## Why

Feature 07 gives an app the three steps of an import, and a `mapping`
option "for an app that shows its own map columns step". Most apps would
build the same step: a file whose `Nombre` column has to go to the field
`Name of product`, a date column written M/D/Y, a "Sí"/"No" column for a
checkbox, a column the app has no field for yet. The user asked for that
step in the package (2026-11-20): a screen that shows a sample of what
will be imported, the type the sheet thinks each column is, a way to map
each column to a field (or to a new field), and a way to correct or
transform the values, all opt-in.

## Decided (the user, 2026-11-20)

1. It lives in `@ember-eui/sheet`, as a reusable component. It is not
   tied to a sheet: anything described as a list of fields with types (a
   Prysmex form, for example) can be the target.
2. v1 can create a field from a column that matches none.
3. v1 has named transforms the app defines. Expressions typed by the user
   are not in v1; the transform hook is shaped so they can be added later
   without an API change.
4. It is opt-in: without the component nothing changes.

Decision 2 also settles "guessing field types on import", a "maybe" in
`README.md`: the guess is used to propose a new field's type, and only as
a suggestion.

## API

### The component

```hbs
<EuiModal @onClose={{this.close}}>
  <EuiSheetImport
    @fields={{this.fields}}
    @file={{this.file}}
    @transforms={{this.transforms}}
    @creatableFieldTypes={{array "text" "number" "date" "singleSelect" "checkbox"}}
    @onCreateFields={{this.createFields}}
    @savedMapping={{this.savedMapping}}
    @onImport={{this.import}}
    @onCancel={{this.close}}
  />
</EuiModal>
```

- `@fields`: the target fields, hidden ones included. Required.
- `@types`: custom field types, as `@types` of the sheet (`types` merged
  over the built-ins).
- The source, one of:
  - `@file` (a `File`): read as bytes, the encoding found (below), then
    `parseCsv`;
  - `@text` (a string): `parseCsv`;
  - `@matrix` (`string[][]`): already parsed (an app with SheetJS gives
    its Excel sheet here).
  The component draws no file picker; the app's toolbar has one.
- `@transforms?: SheetImportTransform[]`: the named transforms a column
  can use (below).
- `@onCreateFields?: (drafts: SheetImportFieldDraft[]) => Promise<EuiSheetField[]>`:
  with it, a column can go to a new field; without it, "New field" is not
  offered. The owner creates the fields (it assigns the ids) and resolves
  with them, in the drafts' order.
- `@creatableFieldTypes?: string[]`: the types a new field may have.
  Default: the field editor's default list.
- `@savedMapping?: SheetImportMapping`: a mapping from an earlier import
  of a file with the same header line; it wins over matching by name.
- `@onImport(result: SheetImportResult)`: called once with the rows to
  append. A returned promise keeps the screen busy; a rejection shows its
  message.
- `@onCancel?`.
- `@sampleSize?`: rows in the preview. Default 20.
- `@messages?`: as the sheet's, through `eui-i18n`.

The component has no sheet argument, renders inline (no layer, no modal:
the app places it in its own modal, flyout or page), and keeps no state
outside itself.

### The result

```ts
interface SheetImportResult<T = any> {
  /** One entry per line kept, one text per entry of `fieldIds`. */
  rows: string[][];
  /** The field each column goes to (fields created on the way included). */
  fieldIds: string[];
  /**
   * The field each column is read with (decision 14): the target, a
   * per-column copy (`{ ...field, dateOrder: 'mdy' }`) or a created
   * field. Pass them as `appendRows`' `fields`.
   */
  fields: EuiSheetField<T>[];
  /** The fields created on the way, as `@onCreateFields` returned them. */
  createdFields: EuiSheetField<T>[];
  /** Lines left out because the user chose "skip lines with errors". */
  skippedLines: number[];
  /** To save and pass back as `@savedMapping` next time. */
  mapping: SheetImportMapping;
}
```

The texts in `rows` are the file's texts after each column's transform:
the values are read by the target type's `parse` when they are appended,
which is the paste path of feature 07 (`api.appendRows`). The app then
does:

```ts
import = (result: SheetImportResult) => {
  this.savedMappings[result.mapping.signature] = result.mapping;
  this.api.appendRows(result.rows, result.fieldIds, {
    fields: result.fields
  });
};
```

For a target that is not a sheet, the helpers below give the parsed
values directly (`runImport`).

### Transforms

```ts
interface SheetImportTransform {
  id: string;
  label: string;
  description?: string;
  /** Text in, text out. `null` is an empty cell. Throwing marks the cell as an error with the message. */
  apply(text: string, context: {
    line: number;
    header: string;
    /** The line's other texts by header, for transforms that combine columns. */
    row: Record<string, string>;
  }): string | null;
}
```

Examples for the docs: "Split full name: first part", "Cents to amount",
"Excel serial date to D/M/Y". A transform returns text, not a value, so
the target type still reads it, and the preview shows exactly what the
import will write. User-typed expressions, later, would be one more
transform built from the text the user writes, with a sandboxed language
(no `eval`).

### Built-in column options (no code)

Each mapped column has these options, shown only where they apply:

- **Trim** (on by default).
- **Empty texts are no value** (on by default; off keeps `''` for text).
- **Date order** D/M/Y or M/D/Y (date and dateTime targets).
- **Decimal separator** `.` or `,` (number, currency, percent targets).
- **Value map** (singleSelect, multiSelect, checkbox targets): a table of
  the column's distinct texts (up to 50) to an option, or to
  true/false, prefilled where a text matches an option's label or a
  common yes/no word (`sí`, `si`, `yes`, `true`, `1`, `x`; `no`, `false`,
  `0`, empty). Texts not in the table are left as they are.

Date order and decimal separator are applied by reading the column with a
copy of the field (`{ ...field, dateOrder: 'mdy' }`,
`{ ...field, decimalSeparator: ',' }`), never by rewriting the text, and
the copy never reaches the owner: the stored field is unchanged. For that,
`appendRows` takes the per-column fields (see "Changes to feature 07").

### Pure helpers (`@ember-eui/sheet/core`, `src/core/import.ts`)

The component is a view over these; an app can use them without it.

```ts
/** Strips a BOM; strict UTF-8, else windows-1252 (Excel's CSV on Windows). */
decodeText(bytes: ArrayBuffer): { text: string; encoding: 'utf-8' | 'windows-1252' };

/** The best types for a column, most likely first. */
guessColumn(ctx, texts: string[], candidates: string[]): SheetColumnGuess[];

/** A proposed mapping: saved mapping, then alias, then label, then id. */
matchColumns(headers: string[], fields, saved?): SheetImportColumn[];

/** The parsed result of the first `size` lines, cell by cell. */
previewImport(ctx, matrix, plan, transforms, { size }): SheetImportPreview;

/** Every line: the texts to append, and the cells that would fail. */
runImport(ctx, matrix, plan, transforms): {
  rows: string[][]; fieldIds: string[];
  values: unknown[][];            // what parse gives, for non-sheet targets
  errors: Array<{ line: number; column: number; text: string; message: string }>;
};

/** The failed lines as CSV, the file's header first, for the user to fix and import again. */
errorsCsv(matrix, errors): string;
```

`SheetImportPlan` is the screen's state, as data: per file column, its
target (`{ field: id }`, `{ newField: draft }` or `'skip'`), its
transform id and options, and its built-in options.
`SheetImportMapping` is that plan keyed by `signature`, the file's
normalised header line, with field ids (not labels).

## Behaviour

### The screen

One screen, in three parts, top to bottom:

1. **The file**: name, encoding found, delimiter (changeable: `,` `;`
   tab), "First line is the header" (on by default), the line count.
2. **Columns**: one row per file column:
   - the header and three sample texts;
   - the guessed type, as a badge with its share ("Date, D/M/Y · 98%");
   - the target: a select of the fields, "New field…" (with
     `@onCreateFields`), and "Skip";
   - the transform (a select of `@transforms`, "None" first);
   - the built-in options that apply;
   - its status: "200 of 200 read", or "3 can't be read" (a link that
     filters the preview to those cells).
3. **Preview**: the first `@sampleSize` lines as a read-only table with
   the target fields as columns. Each cell shows the value as the target
   type formats it, or its state: an error (the type's message), "linked
   on import" for a linked record or user (the preview has no
   `@onResolve`), "new option" for a select value that will create one.
   Then the totals over every line (a dry run): "1,180 lines ready,
   20 with errors", a "Download the lines with errors" link (`errorsCsv`),
   and the choice "Import all (errors stay as rejections)" or "Skip lines
   with errors".

The buttons: Cancel, and "Import N lines".

### Matching

- `importAliases?: string[]` is a new optional key of `EuiSheetField`:
  other names the field has in files (`['nombre', 'producto']`).
- A header matches, in order: the saved mapping's column, an alias, the
  label, the id. Case, accents and surrounding spaces are ignored, and so
  are `_`, `-` and repeated spaces (`Nombre_del producto` matches
  `nombre del producto`). One matcher does this for feature 07's
  `importMatrix` and for this screen (see "Changes to feature 07").
- A field takes at most one column; a second header that matches it
  stays unmapped and says so.
- An unmatched column defaults to "Skip", or to "New field" with the
  guessed type when `@onCreateFields` is passed.

### Guessing a type

- The guess uses the types' own `parse` (`source: 'paste'`), not new
  rules, so a guess never disagrees with what the import will do. Over a
  sample of up to 200 non-empty texts of the column, each candidate type
  is tried with a draft field of that type.
- Candidates, most specific first: `checkbox`, `date` (D/M/Y, then M/D/Y),
  `dateTime`, `percent`, `currency`, `number` (`.`, then `,`), `email`,
  `url`, `phone`, `singleSelect`, `longText`, `text`. Only types in
  `@creatableFieldTypes` are candidates. `singleSelect` is a candidate when
  the column has at most 20 distinct texts and each is used at least
  twice; `longText` when a text has a line break or is over 200
  characters; `text` always.
- The guess is the first candidate whose `parse` reads at least 95% of the
  sample; its share is shown. D/M/Y is the default order: M/D/Y is guessed
  only when a text proves it (a first part over 12).
- The guess only proposes the type of a new field and its options (the
  select's options from the distinct texts; the date order; the decimal
  separator). It never changes a column mapped to an existing field: there
  the badge shows how much of the column that field's type reads.

### Creating fields

- "New field…" opens a small form (label: the header; type: the guess,
  from `@creatableFieldTypes`; the type's options, prefilled from the
  guess). It is the field editor's content, the same `fieldOptions`
  components (V03 6.4).
- Nothing is created until Import. Then `@onCreateFields(drafts)` is
  called once with every new field, the screen waits for it, takes the
  returned fields' ids, and calls `@onImport`. If it rejects, the message
  shows and nothing is imported.

### Large files

- The preview and the guess read samples only. The dry run reads every
  line once when the plan changes, debounced (250 ms), so typing in an
  option does not re-run it per key.
- The docs say what feature 07 says: append in chunks of 1,000 lines for
  big files, each its own undo step. `@onImport` gets all lines; chunking
  stays the app's.
- Measured target: a 10,000-line, 20-column file shows its preview in
  under 300 ms and its dry run in under 1 s in Chromium on the test
  machine. If not, the dry run moves to idle callbacks.

## Changes to feature 07 (batch B), made when B is built

Batch E needs three small additions in batch B's API. They are listed
here so that B is built once:

1. **`api.appendRows(rows, fieldIds, { fields? })`.** `fields` are field
   definitions for ids `@fields` does not have yet (fields just created,
   before the owner's new `@fields` has rendered) and per-column copies
   (an M/D/Y reading of a D/M/Y field). They are used to read the texts
   and are never stored by the sheet; the insert is keyed by field id as
   before. Without `fields`, `appendRows` is exactly as 07 says.
2. **`importAliases` on `EuiSheetField`**, used by `importMatrix`'s header
   match.
3. **One header matcher** in `src/core/csv.ts` (`matchHeader`), with the
   normalisation above (case, accents, spaces, `_`, `-`), used by
   `importMatrix` and by `matchColumns`.

## Code

- `src/core/import.ts` (new, about 300 lines): the helpers above.
- `src/core/csv.ts` (batch B's file): `matchHeader`.
- `src/components/eui-sheet-import.gts` (new, about 350 lines): the screen.
  It is published as an app component like `eui-sheet` (it is under
  `components/`).
- `src/-private/import/*.gts` (new, about 200 lines): the column row, the
  value map table, the new-field form (wrapping the field editor's
  content), the preview table.
- `src/types.ts`: `SheetImportTransform`, `SheetImportResult`,
  `SheetImportMapping`, `SheetImportFieldDraft`, the signature.
- `src/core/messages.ts`: about 30 keys (`importTitle`, `importColumns`,
  `importPreview`, `importSkip`, `importNewField`, `importLinesReady(n)`,
  `importLinesWithErrors(n)`, `importDownloadErrors`, `importLines(n)`,
  `importLinkedOnImport`, `importNewOption`, `importGuess(type, percent)`,
  …).
- `src/index.ts`, `core/index.ts`: the exports.

Two stages, each committed with its tests: (1) the pure helpers and the
batch B additions; (2) the component.

## Tests

Prefixes IG (guess), IP (plan, preview, run), IW (the screen); none is
used today.

`tests/unit/import-test.ts`:

- **IG1:** a column of `19/11/2026` texts guesses `date` D/M/Y; one with a
  `11/19/2026` guesses M/D/Y; a mix under 95% guesses `text`.
- **IG2:** `1.234,5` texts guess `number` with `,`; `Sí`/`No` guess
  `checkbox`; five repeated statuses guess `singleSelect` with those
  options; a text with a line break guesses `longText`.
- **IG3:** only `@creatableFieldTypes` are candidates.
- **IP1:** `decodeText`: a BOM is stripped; windows-1252 bytes of
  `Año` decode to `Año`; valid UTF-8 stays UTF-8.
- **IP2:** `matchColumns`: saved mapping, then alias, then label, then id;
  accents, case, `_` and spaces ignored; a field matched twice keeps the
  first.
- **IP3:** `previewImport` with a transform, a value map and an M/D/Y
  copy: the values are what the target types parse; a throwing transform
  is an error cell with its message; a linked-record text is "linked on
  import".
- **IP4:** `runImport` over 1,000 lines gives the rows, the values and the
  errors; `errorsCsv` lists the failed lines under the header.
- **IP5:** the matcher of `importMatrix` and `matchColumns` is the same
  (an alias works in both).

`tests/integration/components/eui-sheet-import-test.gts`:

- **IW1:** a file with `Nombre`, `Precio`, `Fecha` and a field with alias
  `nombre`: the columns are mapped, the guesses shown, the preview has 20
  lines.
- **IW2:** changing a target, a transform and the date order updates the
  preview and the totals.
- **IW3:** "New field" with `@onCreateFields`: nothing is created before
  Import; on Import it is called once with the drafts, then `@onImport`
  gets `fieldIds` with the new id and `createdFields`.
- **IW4:** without `@onCreateFields`, "New field" is not offered.
- **IW5:** "Skip lines with errors": `rows` leaves them out and
  `skippedLines` lists them; "Import all" keeps them.
- **IW6:** `@savedMapping` with the same header line wins over aliases;
  `result.mapping` round-trips.
- **IW7:** a rejected `@onCreateFields` or `@onImport` shows its message
  and imports nothing.
- **IW8:** end to end with a sheet: `@onImport` → `api.appendRows(rows,
  fieldIds, { fields })` inserts one record per line in one
  change set, the new field's values included, before `@fields` has
  re-rendered; Ctrl/Cmd+Z removes them.
- **IW9:** keyboard: every control is reachable with Tab, the selects
  open with the keyboard, Import is reachable.

## Docs

- `docs/sheet.md`, "Import from CSV": the screen, the result, transforms,
  aliases, saved mappings, and what stays the app's (the file picker,
  creating fields, chunking, saving mappings).
- A demo: a toolbar "Import…" button, a file input and a modal with the
  screen, over a `localRecords` store whose `createField` creates the
  fields; a sample CSV in Spanish with `Nombre`, `Precio` (decimal comma),
  `Fecha` (D/M/Y), `Activo` (`Sí`/`No`), `Estado` (a select), and one
  column with no field; two transforms.
- `README.md`: one paragraph.

## Risks

- **Guesses from a sample** can be wrong on a column whose odd values come
  late. The dry run reads every line, and its count is what the user sees
  before importing.
- **Excel's CSV encodings.** Only UTF-8 and windows-1252 are recognised;
  other encodings are read as windows-1252 and show odd characters in the
  preview. The app can decode itself and pass `@text`.
- **Value maps over many distinct texts**: the table stops at 50; the rest
  go through the type's `parse` unchanged.
- **Transforms are the app's code** and run on every line, in the page.
  The docs say to keep them pure and fast.
- **The new-field form reuses the field editor's content.** If its
  components assume a sheet (`@sheet`), they get a small adapter, or the
  form uses only the label and the type in v1 and says so.
