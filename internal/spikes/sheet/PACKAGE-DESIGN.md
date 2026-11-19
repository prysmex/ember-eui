# `@ember-eui/sheet` v0.1: package design

Status: design only, nothing implemented. Written 2026-11-19 on branch
`feat/sheet` at `bfd80461`. Line numbers refer to that commit. Read
`DESIGN.md` and `RESULTS.md` (sections 5, 6, 7) in this folder first: this
document only says what changes when the spike becomes a package.

Words used here:

- **Owner**: the app code that holds the records and applies change sets.
- **Rejection**: a text the user typed or pasted that a field type could not
  turn into a value (for example `abc` in a number field).
- **Validation error**: a stored value that breaks a rule (for example an
  empty required cell).
- **Nav mode / edit mode**: focus is on a grid cell / inside an editor.

## 1. Goal and scope

Goal: `packages/sheet`, published later as `@ember-eui/sheet` (MIT): an
Airtable-like data-entry grid on top of `EuiDataGrid`, controlled and
data-agnostic. `EuiDataGrid` and everything under `packages/core/src/` stay
unchanged.

v0.1 implements:

1. The package skeleton (section 3, 4).
2. A plain TypeScript core with no Ember imports (section 5): change sets,
   TSV, a field-type registry, five built-in types (`text`, `number`,
   `checkbox`, `singleSelect`, `date`), the error model.
3. `EuiSheet` and the cell and editor components for the five types
   (section 7, 8). The built-in cells and editors use the same public
   contract an app uses for a custom type (section 9).
4. Tests: the spike's 16 integration cases and 8 unit tests, plus the new
   cases (section 10).
5. A README (section 13).

v0.1 defines but does not implement (section 9): async option sources, bulk
resolve on paste, record-level, cross-row and async validation hooks, and the
types multiSelect, linked record, user, attachment, rating.

Out of scope, unchanged from the spike: undo, fill handle, mouse drag
selection, sorting and filtering UI, fullscreen, row insert/delete UI, IME,
quoted TSV cells, control columns.

Size target: about 1,700 lines of source (core 750, Ember 950) plus tests.

## 2. Decisions in one table

| # | Decision | Why |
| --- | --- | --- |
| P1 | A rejected text gives **no patch**. The sheet keeps the rejected text for that cell, shows it in the cell marked invalid, and reports it in `changeSet.rejected`. | One rule for typing, paste, blur and scroll commits. Nothing the user pasted is lost or silently blanked, and the record never holds a value of the wrong type. Section 6. |
| P2 | A validation error **does not block** the patch. Errors are derived from the current `@records` on every render. | No state to keep in sync; works on load, after paste, after the owner changes a record. |
| P3 | A field type is a plain object (core) plus optional `cell` and `editor` components (Ember layer). Built-ins are registered the same way as app types. | Requirement: custom cells are first-class. Section 9. |
| P4 | The wrapper's capture `keydown` asks the type `handlesKey(event)` first; if it returns `true` the event is left to the editor. | `EuiSelectable` handles Enter and arrows in the bubble phase (`eui-selectable.gts:624`); the spike's `onEditKeyDown` would stop Enter before it. |
| P5 | Select editor: `EuiSelectable` (`searchable`, `singleSelection="always"`) inside a panel beside the grid. Not `EuiComboBox`. | `EuiComboBox` renders its list through ember-basic-dropdown in `#ember-basic-dropdown-wormhole`, outside the wrapper: its events would bypass the controller and moving focus there would look like a blur. `EuiSelectable` renders in place. |
| P6 | Date editor: a native `<input type="date">` when opened with Enter, F2 or double-click; the plain text input, seeded with the typed character, when opened by typing a digit. | Core has no calendar (`eui-date-picker-range.gts` only does layout and its doc suggests `<EuiFieldText type="date">`). `@ember-eui/flatpickr` would add a peer (`flatpickr`), its CSS and a calendar appended to `<body>`. The native input gives the ISO value directly and adds no dependency, so the lockfile only gains the new importer. A date input cannot be seeded with one character, hence the text path. |
| P7 | Checkbox: **Space toggles** in nav mode, a click on the box toggles, there is no editor. Enter, F2 and letters do nothing on a checkbox cell. | One behaviour. |
| P8 | Space is never a type-to-edit key. On a non-checkbox data cell it is stopped and does nothing. | Reserved (Airtable uses Space to expand a record; v0.1 has no record view). Also keeps the page from scrolling. |
| P9 | Cells render no tabbable element. The checkbox is a `<span>`; the error message is the cell's `title`, set through `setCellProps`. | A tabbable child makes the grid add a focus trap and react to Enter/F2 on `keyup` (`eui-data-grid/cell.gts:560-586`, `utils/data-grid/focus.ts:147`), and breaks the sheet's `event.target === cell` gate. |
| P10 | `localRecords` lives outside `src/core/` (it imports `@glimmer/tracking`); the pure part is `applyChangeSet` in core. An ESLint rule forbids Ember imports in `src/core/`. | The "no Ember imports" decision. |
| P11 | Spike knobs removed: `@cursorSource` (always the DOM), the field's `isExpandable`, the field's `format`/`parse` (now the type's). | Section 7 of `RESULTS.md`; types replace per-field functions. |
| P12 | Package starts as `"private": true`, version `0.0.0`, with a `minor` changeset. | `pnpm release` (`changeset publish`) publishes every non-private package whose version is not on npm. Removing `private` is the release switch. Question Q1. |
| P13 | Delete the spike code from `packages/core/tests` once the package's tests pass. | Section 12. |

## 3. Files

All paths under `packages/sheet/` unless they start with `/`.

### 3.1 Skeleton: copy from `packages/validated-form/`

| File | Action |
| --- | --- |
| `.env.development`, `.gitignore`, `.npmignore`, `.stylelintignore`, `.stylelintrc.cjs`, `LICENSE.md`, `addon-main.cjs`, `babel.config.cjs`, `babel.publish.config.cjs`, `config/ember-cli-update.json`, `testem.cjs`, `tsconfig.json`, `tsconfig.eslint.json`, `vite.config.mjs`, `tests/deprecations.ts`, `tests/helpers/index.js`, `unpublished-development-types/**` | Copy unchanged. |
| `rollup.config.mjs` | Copy unchanged. `addon.appReexports(['components/**/*.js'])` then re-exports only `components/eui-sheet.js`: everything else lives in `-private/` or `core/`. |
| `eslint.config.mjs` | Copy, then add the block in 3.2. |
| `tests/index.html` | Copy; change `<title>` to `@ember-eui/sheet Tests`. |
| `tests/test-helper.ts` | Copy. See verification V3 (section 15) before adding anything. |
| `package.json` | Section 4. |
| `README.md` | Section 13. |
| `CHANGELOG.md` | Not created: `changeset version` writes it. |

`flatpickr` and `validated-form` have the same configs; they differ only in
`rollup.config.mjs` (`appReexports` list) and the test page title.

### 3.2 ESLint block to add (after the `src/**/*` import block)

```js
  // src/core is plain TypeScript: no Ember, no DOM components
  {
    files: ['src/core/**/*'],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          patterns: [
            { group: ['@ember/*', '@glimmer/*', 'ember-*', '@ember-eui/*', '@embroider/*'], message: 'src/core has no Ember imports.' },
            { group: ['../components/*', '../-private/*', '../local-records*', '../field-types*'], message: 'src/core does not import the Ember layer.' }
          ]
        }
      ]
    }
  },
```

### 3.3 Source

| File | Contents | ~Lines |
| --- | --- | --- |
| `src/index.ts` | Public barrel: `export * from './core/index.ts'`, `EuiSheet` (default re-export as a named export), `localRecords`, `LocalRecords`, `builtInSheetFieldTypes`, the Ember-layer types. | 25 |
| `src/core/index.ts` | Barrel of the core. Also importable as `@ember-eui/sheet/core`. | 15 |
| `src/core/types.ts` | Every core type (section 5.1). | 150 |
| `src/core/messages.ts` | `SheetMessages`, `defaultMessages`. | 30 |
| `src/core/tsv.ts` | `parseTsv`, `toTsv` (moved unchanged from the spike's `change-set.ts:83-92`). | 15 |
| `src/core/fields.ts` | `resolveType`, `isReadOnly`, `isRequired`, `fieldOptions`, `cellKey`. | 50 |
| `src/core/field-types/text.ts`, `number.ts`, `checkbox.ts`, `single-select.ts`, `date.ts` | One built-in type each (section 5.4). | 210 |
| `src/core/field-types/index.ts` | `builtInFieldTypes`, `createRegistry(extra?)`. | 20 |
| `src/core/change-set.ts` | `toRange`, `rangeMatrix`, `commitText`, `commitValue`, `clearRange`, `pasteMatrix`, `applyChangeSet`, `applyNewOptions`. | 210 |
| `src/core/errors.ts` | `validateCell`, `mergeErrors`, `compareValues`. | 50 |
| `src/local-records.ts` | `LocalRecords`, `localRecords()` (section 5.6). | 45 |
| `src/field-types.ts` | `builtInSheetFieldTypes`: the core types plus their `cell`/`editor` components and key rules. | 45 |
| `src/types.ts` | Ember-layer types: `EuiSheetFieldType`, `SheetCellSignature`, `SheetEditorSignature`, `EuiSheetSignature`. | 80 |
| `src/components/eui-sheet.gts` | `EuiSheet` (section 7). | 430 |
| `src/-private/sheet-cell.gts` | The grid's `@renderCellValue`: selection, errors, picks the type's cell component. | 80 |
| `src/-private/cells/checkbox-cell.gts`, `select-cell.gts` | Built-in cell displays. | 55 |
| `src/-private/editor-frame.gts` | Positions the editor, owns `focusout`. | 60 |
| `src/-private/editors/input-editor.gts`, `select-editor.gts`, `date-editor.gts` | Built-in editors. | 170 |
| `src/-private/styles.ts` | `ensureStyles()`: appends one `<style data-eui-sheet>` to `document.head`, once. | 35 |

Styles: the spike's `<style>` element in the template would repeat per
sheet. `ensureStyles()` is called from `EuiSheet`'s constructor. It has the
same CSP posture as core, which injects style elements through
`@emotion/css`. Classes: `euiSheet`, `euiSheet__cell--selected`,
`euiSheet__cell--invalid`, `euiSheet__editor`, `euiSheet__editor--panel`,
`euiSheet__input`, `euiSheet__checkbox`, `euiSheet__checkbox--checked`.
Colours are fixed values in v0.1 (selection `rgba(0, 119, 204, 0.12)` as in
the spike, invalid `#BD271E` text plus an inset 1px outline). Theming with
EUI tokens is question Q5.

### 3.4 Tests

| File | Module name | Contents |
| --- | --- | --- |
| `tests/helpers/sheet.ts` | — | The spike test's helpers (`eui-sheet-spike-test.gts:45-128`): `el`, `cell`, `text`, `editor`, `selected`, `press`, `type`, `focusCell`, `clipboard`, `scrollTo`; plus `cellTitle(row, col)`, `isInvalid(row, col)`, `changeSet(partial)` (fills `rejected: []`, `newOptions: []`). |
| `tests/unit/tsv-test.ts` | `Unit \| Sheet \| tsv` | U2, U3 |
| `tests/unit/change-set-test.ts` | `Unit \| Sheet \| change sets` | U1, U4–U8, U9–U14 |
| `tests/unit/field-types-test.ts` | `Unit \| Sheet \| field types` | F1–F7 |
| `tests/unit/errors-test.ts` | `Unit \| Sheet \| errors` | E1–E3 |
| `tests/unit/core-boundary-test.ts` | `Unit \| Sheet \| core boundary` | B1 |
| `tests/integration/components/eui-sheet-test.gts` | `Integration \| Component \| EuiSheet` | T1–T16, demo |
| `tests/integration/components/eui-sheet-types-test.gts` | `Integration \| Component \| EuiSheet field types` | N1–N20 |
| `tests/integration/components/eui-sheet-custom-type-test.gts` | `Integration \| Component \| EuiSheet custom type` | C1–C3 |

All module names contain `Sheet`, so the testem filter is `Sheet`.

### 3.5 Files outside the package

| File | Change |
| --- | --- |
| `/pnpm-lock.yaml` | Gains the `packages/sheet` importer (section 11.2). `pnpm-workspace.yaml` needs no change (`packages/*`). `turbo.json` needs no change. |
| `/.changeset/sheet-initial-release.md` | New (section 14). |
| `/scripts/dist-hygiene.test.mjs:99-105` | Add `'sheet'` to `PACKAGES`. |
| `/scripts/generate-llms-txt.mjs:21` | No change now: the package has no `docs/` folder yet (section 13). |
| `/packages/core/tests/spikes/**`, `tests/integration/spikes/**`, `tests/unit/spikes/**` | Deleted (section 12). |
| `/internal/spikes/sheet/RESULTS.md` | Append a section 8: the code moved to `packages/sheet`, with the commit. |

## 4. `package.json`

Start from `packages/validated-form/package.json` and change only this:

```jsonc
{
  "name": "@ember-eui/sheet",
  "version": "0.0.0",
  "private": true,                       // P12, question Q1
  "description": "Airtable-like data-entry grid for @ember-eui/core",
  "keywords": ["ember-addon", "@ember-eui", "sheet", "spreadsheet", "data-grid"],
  "repository": "https://github.com/prysmex/ember-eui",
  "author": "Alberto Cantu <betocantu93@gmail.com> (https://betocantu93.com)",
  // scripts, imports, files, sideEffects, engines, publishConfig, volta: unchanged
  "exports": {
    ".": { "types": "./declarations/index.d.ts", "default": "./dist/index.js" },
    // added: "./*" would map @ember-eui/sheet/core to dist/core.js, which does not exist
    // (same pattern as core's "./utils/color")
    "./core": { "types": "./declarations/core/index.d.ts", "default": "./dist/core/index.js" },
    "./*": { "types": "./declarations/*.d.ts", "default": "./dist/*.js" },
    "./addon-main.js": "./addon-main.cjs"
  },
  "dependencies": {
    "@babel/core": "^7.26.7",
    "@embroider/addon-shim": "^1.10.3",
    "decorator-transforms": "^2.3.0",
    "ember-modifier": "^4.2.0"
  },
  "peerDependencies": {
    "@ember-eui/core": "^16.1.4",
    "@glimmer/component": "^2.0.0",
    "ember-source": ">= 7.1.0"
  },
  // devDependencies: copied verbatim (same specifiers). Do not add any.
  "ember-addon": {
    "version": 2,
    "type": "addon",
    "main": "addon-main.cjs",
    "app-js": {
      "./components/eui-sheet.js": "./dist/_app_/components/eui-sheet.js"
    }
  }
}
```

Notes:

- Dependencies removed from the sibling's list because the sheet does not
  use them: `@ember/render-modifiers`, `@ember/test-waiters`,
  `@nullvoxpopuli/ember-composable-helpers`, `ember-truth-helpers`,
  `ember-validators`. Removing them adds nothing to the lockfile.
- `@ember-eui/core` is a peer and a `workspace:*` devDependency, as in the
  siblings. In a package's `node_modules` it is a symlink to
  `packages/core` (checked: `packages/validated-form/node_modules/@ember-eui/core -> ../../../core`),
  so imports resolve to core's `dist/` and `declarations/`: **core must be
  built before the sheet's tests, lint or type check** (section 11.3).
- Peer range `^16.1.4`: `EuiDataGrid` exists since `@ember-eui/core@16.0.0`
  (the tag contains `464707bf`), but the sheet is only tested against the
  current code. The siblings use `^16.0.0`.
- `exports["."]` points at `dist/index.js`. The siblings have no
  `src/index.*`; the sheet has one.
- Imports from core use the published paths, for example
  `@ember-eui/core/components/eui-data-grid`,
  `@ember-eui/core/components/eui-selectable`,
  `@ember-eui/core/components/eui-badge`,
  `@ember-eui/core/components/eui-panel`, and the types from
  `@ember-eui/core/utils/data-grid/types` (present in
  `packages/core/declarations/utils/data-grid/types.d.ts`).

## 5. Core (plain TypeScript)

### 5.1 Types (`src/core/types.ts`)

```ts
export type RecordId = string | number;

/** One option of a select-like field. */
export interface SheetOption {
  value: string | number;
  label: string;
  /** Anything EuiBadge's @color accepts: a named colour or a CSS colour. */
  color?: string;
}

/** A boolean, or a function of the record (undefined values for a row being inserted). */
export type RecordFlag<T> = boolean | ((record: T) => boolean);

export interface EuiSheetField<T = any> {
  id: string;
  label?: string;
  /** Name in the registry. Default 'text'. */
  type?: string;
  readOnly?: RecordFlag<T>;
  required?: RecordFlag<T>;
  /** Extra sync rule for this field. Runs on non-empty values. */
  validate?: (value: unknown, record: T) => string | string[] | undefined;
  /** Options of the field's type (below) and of app types. */
  [option: string]: unknown;
}

export interface TextField<T = any> extends EuiSheetField<T> {
  type?: 'text';
  maxLength?: number;
  pattern?: RegExp;
  /** Message when `pattern` fails. Default messages.pattern(). */
  patternMessage?: string;
}
export interface NumberField<T = any> extends EuiSheetField<T> {
  type: 'number';
  min?: number;
  max?: number;
  /** Default '.'. The other of '.' and ',' is read as a thousands separator. */
  decimalSeparator?: '.' | ',';
}
export interface CheckboxField<T = any> extends EuiSheetField<T> { type: 'checkbox' }
export interface SingleSelectField<T = any> extends EuiSheetField<T> {
  type: 'singleSelect';
  options: SheetOption[] | ((record: T) => SheetOption[]);
  /** A pasted text that matches no option becomes a new option. Default false. */
  createOnPaste?: boolean;
}
export interface DateField<T = any> extends EuiSheetField<T> {
  type: 'date';
  /** Order of day and month in typed, pasted and displayed dates. Default 'dmy'. */
  dateOrder?: 'dmy' | 'mdy';
  /** ISO dates, inclusive. */
  min?: string;
  max?: string;
}

export interface TypeContext<T = any> {
  /** The record the cell belongs to. For a row being inserted: the values accepted so far. */
  record: T | undefined;
  messages: SheetMessages;
}
export interface ParseContext<T = any> extends TypeContext<T> {
  source: 'edit' | 'paste' | 'clear';
}

export type ParseResult<V> =
  | { value: V; newOption?: SheetOption }
  | { error: string }
  /** Reserved (section 9.2): the text needs the owner's bulk resolve. v0.1 treats it as an error. */
  | { unresolved: string };

export interface FieldType<V = unknown, F extends EuiSheetField = EuiSheetField> {
  /** Text → value. `parse('')` with source 'clear' must return a value (the empty value). */
  parse(text: string, field: F, context: ParseContext): ParseResult<V>;
  /** Value → the text shown in the cell. */
  format(value: V | null | undefined, field: F, context: TypeContext): string;
  /** Value → the text put on the clipboard. Default: `format`. `parse(copyText(v))` must give `v`. */
  copyText?(value: V | null | undefined, field: F, context: TypeContext): string;
  /** Rules on a stored, non-empty value. */
  validate?(value: V, field: F, context: TypeContext): string[];
  /** For owners that sort their records. The sheet does not call it in v0.1. */
  compare?(a: V | null | undefined, b: V | null | undefined, field: F): number;
  /** Default: `value == null || value === ''`. */
  isEmpty?(value: unknown): boolean;
  /** A key pressed on the cell in nav mode that changes the value without an editor. */
  navKey?(key: string, value: V | null | undefined, field: F): { value: V } | undefined;
}

export type FieldTypeRegistry = Readonly<Record<string, FieldType<any, any>>>;

export interface CellPatch { recordId: RecordId; fieldId: string; from: unknown; to: unknown }
export interface RecordInsert { tempId: string; index: number; values: Record<string, unknown> }
/** A text that could not become a value. Exactly one of recordId / tempId is set. */
export interface CellRejection {
  recordId?: RecordId;
  tempId?: string;
  fieldId: string;
  text: string;
  message: string;
}
export interface NewOption { fieldId: string; option: SheetOption }

export interface ChangeSet {
  source: 'edit' | 'paste' | 'clear';
  patches: CellPatch[];
  inserts: RecordInsert[];
  rejected: CellRejection[];
  newOptions: NewOption[];
}

export interface Pos { row: number; col: number }
export interface Range { top: number; left: number; bottom: number; right: number } // inclusive

export interface SheetContext<T> {
  records: readonly T[];
  fields: readonly EuiSheetField<T>[];      // visible fields, display order
  getRecordId: (record: T) => RecordId;
  types: FieldTypeRegistry;
  messages: SheetMessages;
  /** Sheet-level @readOnly. */
  readOnly?: boolean;
}

/** Owner-supplied errors: recordId (as a string) → fieldId → message(s). */
export type CellErrors = Readonly<Record<string, Readonly<Record<string, string | string[]>>>>;
```

Differences from the spike's types (`tests/spikes/sheet/change-set.ts:6-58`):
`EuiSheetField` loses `isExpandable`, `format`, `parse` and gains `type`,
`required`, `validate`, function-valued `readOnly`; `ChangeSet` gains
`rejected` and `newOptions` (always present, possibly empty);
`SheetContext` gains `types`, `messages`, `readOnly`.

### 5.2 Messages (`src/core/messages.ts`)

```ts
export interface SheetMessages {
  required: () => string;                          // 'Required'
  notANumber: (text: string) => string;            // '"abc" is not a number'
  notACheckbox: (text: string) => string;          // '"maybe" is not a checkbox value'
  notAnOption: (text: string) => string;           // '"Purple" is not an option'
  notADate: (text: string) => string;              // '"31/02/2026" is not a date'
  min: (min: number | string) => string;           // 'Must be 0 or more'
  max: (max: number | string) => string;           // 'Must be 10 or less'
  maxLength: (max: number) => string;              // 'Must be 5 characters or fewer'
  pattern: () => string;                           // 'Invalid format'
  unresolved: (text: string) => string;            // '"x" could not be resolved'
}
export const defaultMessages: SheetMessages;
```

English defaults. `EuiSheet` takes `@messages` (a `Partial<SheetMessages>`
merged over the defaults). The core never reads a locale.

### 5.3 Helpers (`src/core/fields.ts`)

```ts
export function resolveType(types: FieldTypeRegistry, field: EuiSheetField): FieldType<any, any>;
//   types[field.type ?? 'text']; throws Error(`EuiSheet: unknown field type "x" (field "id")`)
export function isReadOnly<T>(ctx: Pick<SheetContext<T>, 'readOnly'>, field: EuiSheetField<T>, record: T | undefined): boolean;
//   ctx.readOnly || (typeof field.readOnly === 'function' ? field.readOnly(record ?? {}) : !!field.readOnly)
export function isRequired<T>(field: EuiSheetField<T>, record: T | undefined): boolean;
export function fieldOptions<T>(field: EuiSheetField<T>, record: T | undefined): SheetOption[];
//   field.options as an array, or field.options(record ?? {}), or []
export function isEmptyValue(type: FieldType, value: unknown): boolean;
export function cellKey(id: RecordId | string, fieldId: string): string;   // `${id}\u0000${fieldId}`
```

### 5.4 Built-in types

Common rules: `parse` trims the text for every type except `text`. An empty
(trimmed) text gives the type's empty value and never an error.

**`text`** — value `string`.

| | Rule |
| --- | --- |
| parse | The text unchanged. Never an error. |
| empty value | `''` (so the spike's T4 expectation `to: ''` holds). |
| format / copyText | `value == null ? '' : String(value)`. |
| validate | `maxLength` → `messages.maxLength(n)`; `pattern` fails → `field.patternMessage ?? messages.pattern()`. |
| compare | `String(a ?? '').localeCompare(String(b ?? ''))`. |

**`number`** — value `number | null`.

| | Rule |
| --- | --- |
| parse | `''` → `null`. Let `d = field.decimalSeparator ?? '.'` and `g` the other one. Remove spaces. If the text contains `g`, it must match `^[-+]?\d{1,3}(g\d{3})+(d\d+)?$`; then remove every `g`. Replace `d` by `.`. The result must match `^[-+]?(\d+\.?\d*|\.\d+)$`; value `Number(result)`. Anything else → `{ error: messages.notANumber(text) }`. No exponent, currency or percent sign. |
| examples (`d = '.'`) | `12` → 12; `-1.5` → -1.5; `1,234.5` → 1234.5; `1,23` → error; `abc` → error; `1e3` → error. |
| empty value | `null`. |
| format / copyText | `''` for `null`; else `String(value)` with `.` replaced by `d`. No grouping, so `parse(copyText(v)) === v`. |
| validate | `min`, `max` → `messages.min(min)`, `messages.max(max)`; a stored value that is not a finite number → `messages.notANumber(String(value))`. |
| compare | Numeric; `null` first. |

**`checkbox`** — value `boolean`.

| | Rule |
| --- | --- |
| parse | Lower-cased. True: `true`, `1`, `yes`, `y`, `x`, `✓`, `si`, `sí`. False: `false`, `0`, `no`, `n`, `''`. Anything else → `{ error: messages.notACheckbox(text) }`. |
| empty value | `false`. |
| format / copyText | `'true'` / `'false'` (`false` for `null`/`undefined`). |
| isEmpty | `value !== true` (so a required checkbox must be checked). |
| navKey | `' '` → `{ value: !value }`. Any other key → `undefined`. |
| compare | `false` before `true`. |

**`singleSelect`** — value `SheetOption['value'] | null` (the option's `value`).

| | Rule |
| --- | --- |
| options | `fieldOptions(field, context.record)` (array or function of the record). |
| parse | `''` → `null`. First option whose `label`, trimmed and lower-cased, equals the text lower-cased; else the first whose `String(value) === text`; → `{ value: option.value }`. No match: if `field.createOnPaste` and `source === 'paste'` → `{ value: text, newOption: { value: text, label: text } }`; else `{ error: messages.notAnOption(text) }`. |
| empty value | `null`. |
| format / copyText | The matching option's `label`; `''` for empty; `String(value)` when no option matches. |
| validate | Value matches no option → `messages.notAnOption(String(value))`. This is what shows when a record-dependent option list changes (section 9.3) or when the owner ignored `newOptions`. |
| compare | By option index; unknown values last. |

**`date`** — value ISO `YYYY-MM-DD` string `| null`.

| | Rule |
| --- | --- |
| parse | `''` → `null`. Accepted, in this order: `YYYY-MM-DD`; `YYYY-MM-DD` followed by `T` or a space and anything (the date part is kept: Excel and APIs paste date-times); `YYYY/MM/DD`; `A/B/YYYY`, `A-B-YYYY`, `A.B.YYYY` with 1 or 2 digits for A and B, read as day/month when `dateOrder` is `'dmy'` (the default) and month/day when `'mdy'`. The result must be a real calendar date (checked with `new Date(Date.UTC(y, m - 1, d))` round-trip). Two-digit years, month names and anything else → `{ error: messages.notADate(text) }`. |
| examples (`dmy`) | `2026-11-19` → `2026-11-19`; `19/11/2026` → `2026-11-19`; `1-2-2026` → `2026-02-01`; `31/02/2026` → error; `11/19/2026` → error (month 19); `19/11/26` → error. |
| empty value | `null`. |
| format | `DD/MM/YYYY` for `dmy`, `MM/DD/YYYY` for `mdy`; `''` for empty; the raw string when it is not an ISO date. |
| copyText | The ISO value (unambiguous; spreadsheets read it in any locale). |
| validate | Not `^\d{4}-\d{2}-\d{2}$` or not a real date → `messages.notADate(value)`; `min`/`max` (string comparison of ISO dates) → `messages.min`/`messages.max` with the formatted bound. |
| compare | String comparison; `null` first. |

No `moment`, no `Intl`: the output is the same in every environment.

Registry (`src/core/field-types/index.ts`):

```ts
export const builtInFieldTypes: FieldTypeRegistry; // { text, number, checkbox, singleSelect, date }
export function createRegistry(extra?: FieldTypeRegistry): FieldTypeRegistry; // { ...builtIn, ...extra }
```

An app type with a built-in name replaces the built-in.

### 5.5 Change sets (`src/core/change-set.ts`)

```ts
export function toRange(anchor: Pos, head: Pos): Range;
export function rangeMatrix<T>(ctx: SheetContext<T>, range: Range): string[][];   // copyText of each cell
export function commitText<T>(ctx: SheetContext<T>, pos: Pos, text: string): ChangeSet | null;
export function commitValue<T>(ctx: SheetContext<T>, pos: Pos, value: unknown): ChangeSet | null;
export function clearRange<T>(ctx: SheetContext<T>, range: Range): ChangeSet | null;
export function pasteMatrix<T>(ctx: SheetContext<T>, anchor: Pos, matrix: readonly (readonly string[])[],
  options?: { nextTempId?: () => string }): ChangeSet | null;
export function applyChangeSet<T extends object>(records: readonly T[], changeSet: ChangeSet,
  options: { getRecordId: (record: T) => RecordId; createRecord?: (values: Record<string, unknown>, tempId: string) => T }): T[];
export function applyNewOptions<F extends EuiSheetField>(fields: readonly F[], changeSet: ChangeSet): F[];
```

| Function | Behaviour (changes from the spike in bold) |
| --- | --- |
| `rangeMatrix` | As the spike, **with `type.copyText ?? type.format`**. |
| `commitText` | The spike's `commitPatch`, renamed. `null` when the cell is read-only (`isReadOnly`) or does not exist. **`type.parse(text, field, { record, messages, source: 'edit' })`:** a value equal to the current one (`Object.is`) → `null`; a value → one patch (plus `newOptions` if any); `error` or `unresolved` → **no patch, one `rejected` entry** `{ recordId, fieldId, text, message }` (`messages.unresolved(text)` for `unresolved`). |
| `commitValue` | **New.** A value that needs no parsing (a picked option, a toggled checkbox, an editor's `onCommit({ value })`). `null` when read-only or unchanged; else one patch, source `'edit'`. |
| `clearRange` | As the spike: per non-read-only cell, `to = parse('', …, source 'clear').value`, omitted when equal. |
| `pasteMatrix` | As the spike, plus: **read-only is evaluated per record**; **each cell is parsed with `source: 'paste'` and a context record of the existing record merged with the values accepted so far in that pasted row, left to right** (so a pasted `position` is checked against the `area` pasted in the same row); **an `error`/`unresolved` cell gives no patch and a `rejected` entry** (`recordId` for an existing row, `tempId` for an inserted one); **`newOption`s are collected, one per `fieldId` + `value`**; **a row past the end is inserted when it has at least one accepted or rejected cell** (`values` holds only the accepted ones). Returns `null` only when patches, inserts, rejected and newOptions are all empty. **`tempId` comes from `options.nextTempId()`; the default is the spike's `new-0`, `new-1`, … per call.** That default repeats in the next paste, and `localRecords` uses the `tempId` as the record id, so `EuiSheet` always passes a generator backed by one module-level counter in `eui-sheet.gts` (`new-1`, `new-2`, … never reused in the page). An owner that calls `pasteMatrix` itself must pass its own. |
| `applyChangeSet` | **New, pure:** the body of the spike's `LocalRecords.apply` (`local-records.ts:28-48`). Patched records are new objects, others keep identity, inserts are appended in `index` order with `createRecord` (default `{ id: tempId, ...values }`). `rejected` and `newOptions` do not touch records. |
| `applyNewOptions` | **New, pure:** returns `fields` itself when `changeSet.newOptions` is empty; else a new array where each affected field with an **array** `options` is a new object with the options appended (skipping values already present). A field whose `options` is a function is left alone: its owner must add the option to its own source. |

### 5.6 `localRecords` (`src/local-records.ts`, Ember layer)

```ts
export interface LocalRecordsOptions<T, F extends EuiSheetField<T> = EuiSheetField<T>> {
  getRecordId: (record: T) => RecordId;
  createRecord?: (values: Record<string, unknown>, tempId: string) => T;
  /** Optional: lets the store add options created on paste. */
  fields?: F[];
}
export class LocalRecords<T extends object, F extends EuiSheetField<T> = EuiSheetField<T>> {
  @tracked records: T[];
  @tracked fields: F[];          // options.fields ?? []
  readonly log: ChangeSet[];
  apply: (changeSet: ChangeSet) => void;   // arrow property, so @onChange={{store.apply}} is bound
}
export function localRecords<T extends object, F extends EuiSheetField<T> = EuiSheetField<T>>(
  initial: T[], options: LocalRecordsOptions<T, F>): LocalRecords<T, F>;
```

`apply`: `records = applyChangeSet(records, changeSet, options)`;
`fields = applyNewOptions(fields, changeSet)`; `log.push(changeSet)`.
With `createOnPaste`, pass `@fields={{store.fields}}`; otherwise the created
value has no option and the cell shows "is not an option".

## 6. Error model

Two kinds, kept apart.

| | Rejection | Validation error |
| --- | --- | --- |
| What | A text `type.parse` could not turn into a value. | A stored value that breaks a rule. |
| Patch | None. The record keeps its old value. | Emitted as usual. |
| Where it lives | Sheet state: `rejections`, a map `cellKey(recordId or tempId, fieldId) → { text, message }`. Also in `changeSet.rejected`. | Nowhere: derived from `@records` at render. |
| Cell shows | The rejected text, as plain text (whatever the type's cell component is), invalid style, `title` = message. | The value, invalid style, `title` = messages. |
| Sources | `parse` → `error`; `parse` → `unresolved` (v0.1). | `required`; `type.validate`; `field.validate`; owner `@cellErrors`. |

Why P1 and not "blank the cell" (Airtable blanks a pasted `abc` in a number
field): the main use is pasting many rows from a spreadsheet. Blanking loses
what was pasted and does not tell the user which cells failed; writing the
text into the record would store a string in a number field. Keeping the
text beside the record does neither, and it is the same mechanism the user
already chose for a select value with no matching option.

Rejection rules:

| Case | Behaviour |
| --- | --- |
| Single-cell edit of an invalid text, committed with Enter or Tab | No patch. The rejection is stored, `onChange` gets a change set with one `rejected` entry. Focus moves as for a valid commit. |
| Commit by blur or by scroll | The same. (This is why the editor is never kept open on an error: these commits cannot keep it open.) |
| Paste | Per cell, as above. Valid cells of the same paste are patched. |
| Editing a cell that has a rejection | The editor's `@draft` is the rejected text. Exception: the native date input (a date cell opened with Enter, F2 or double-click) cannot show a text that is not a date; it opens empty. |
| Lifetime | Removed when the cell is next written by the sheet (a commit, a paste over it or a Delete over it, valid or not; a new rejection replaces it) and when the cell's value changes from outside (the stored `seenValue` differs from the record's current value). Entries whose record is gone are dropped the next time the map is written. Not kept across a re-creation of the component. |
| Inserted row | The entry carries `tempId`, and the sheet stores it under the `tempId`. It shows when the owner creates the record with the `tempId` as its id (what `localRecords` does by default). An owner that assigns other ids does not see it in the sheet; it has it in `changeSet.rejected` and can show it through `@cellErrors`. Documented limit; question Q4. |
| `onChange` with only `rejected` | Called. `applyChangeSet` changes no record. |

Validation, in `src/core/errors.ts`:

```ts
/** Errors of one stored value, in order: required, type.validate, field.validate. */
export function validateCell<T>(ctx: SheetContext<T>, field: EuiSheetField<T>, record: T): string[];
/** Concatenates, drops duplicates and empty strings. */
export function mergeErrors(...lists: (readonly string[] | string | undefined)[]): string[];
export function compareValues(types: FieldTypeRegistry, field: EuiSheetField, a: unknown, b: unknown): number;
```

`validateCell`: if the value is empty (`type.isEmpty`), the result is
`[messages.required()]` when `isRequired(field, record)`, else `[]`. For a
non-empty value: `type.validate` then `field.validate`.

The cell's errors, computed by the sheet for each rendered cell (not for the
whole data set):

```
errors(row, field) = mergeErrors(
  rejection?.message,                       // 1
  rejection ? [] : validateCell(...),       // 2  (a rejected cell shows only its rejection and owner errors)
  @cellErrors?.[String(recordId)]?.[field.id]   // 3
)
```

A cell with at least one error gets the class `euiSheet__cell--invalid`,
`aria-invalid="true"` and `title` = the messages joined with a newline. An
`EuiToolTip` per cell is not used (P9, and one tooltip component per
rendered cell).

## 7. `EuiSheet`

### 7.1 Public API

```ts
export interface EuiSheetSignature<T> {
  Element: HTMLDivElement;                 // the wrapper
  Args: {
    fields: EuiSheetField<T>[];
    records: T[];
    getRecordId: (record: T) => RecordId;
    onChange: (changeSet: ChangeSet) => void;
    cellErrors?: CellErrors;
    height?: number | string;
    /** App field types, merged over the built-ins. Keep the object stable (not created in a template). */
    fieldTypes?: Record<string, EuiSheetFieldType<any, any>>;
    /** Every field read-only. */
    readOnly?: boolean;
    messages?: Partial<SheetMessages>;
    /** The grid's aria-label. Default 'Sheet'. */
    ariaLabel?: string;
  };
}
export default class EuiSheet<T extends object> extends Component<EuiSheetSignature<T>> {}
```

`package.json` exports give: `@ember-eui/sheet` (everything),
`@ember-eui/sheet/components/eui-sheet` (the component),
`@ember-eui/sheet/core` (the Ember-free core).

### 7.2 What is kept from the spike component

`tests/spikes/sheet/eui-sheet.gts` is the starting point. Kept as is: the
wrapper with capture `keydown`, `copy`, `paste`, `scroll`, `mousedown` and
bubble `focusin`, `dblclick` (lines 485-497); `dataCell` (190-204);
`isClipboardTarget` (213-219); `onFocusIn` with `domCursor` and `extending`
(249-264); the scale-corrected rect in `startEdit` (392-413); `editing = null`
first in `commit` (428-431); `setFocusedCell` after commit and cancel
(432-457); no `setFocusedCell` after a paste (382); the stable
`cellContext = { sheet: this }` (108); the grid args (499-508) with
`@toolbarVisibility={{false}}`.

Changed:

| Spike | Package |
| --- | --- |
| `cursorSource`, `source`, the `api` branch of `cursor()`, `SheetGridApi.getFocusedCell` (60-68, 114-116, 228-232) | Removed. `cursor()` reads the event's cell. |
| `columns` with `field.isExpandable` (119-125) | Always `isExpandable: false`. |
| `visibleFieldIds` set once from `@fields` (97-99) | `@tracked order: string[] \| null` (set by `setVisibleColumns`); `visibleFieldIds` = `order` filtered to ids still in `@fields`, then the ids of `@fields` not in it; `@fields` order when `order` is `null`. |
| `context` (150-156) | Adds `types` (`@cached`: `{ ...builtInSheetFieldTypes, ...@fieldTypes }`), `messages` (`@cached`), `readOnly`. |
| `displayValue` (173-178) | `cellView(row, fieldId)` (7.3). |
| `field.readOnly` checks (275, 300, 311) | `isReadOnly(ctx, field, record)`. |
| `draft` tracked, input controlled by the sheet (93, 415-417) | `draft` is a plain field; the editor owns its input (8.2). |
| `commitPatch` | `commitText` / `commitValue`. |
| `emit` (465-467) | Also updates `rejections` (7.5). |
| Class `euiSheetSpike*`, `<style>` in the template | `euiSheet*`, `ensureStyles()`. |
| `SheetEditor` rendered directly (510-517) | `EditorFrame` + the type's editor (8.2). |

### 7.3 Cell rendering (`-private/sheet-cell.gts`)

The grid's `@renderCellValue`. For its `rowIndex`, `colIndex`, `columnId` it
asks the sheet for one view object:

```ts
interface CellView {
  record: unknown; field: EuiSheetField; type: EuiSheetFieldType;
  value: unknown;
  text: string;            // rejection text, else type.format(value)
  rejected: boolean;
  errors: string[];
  selected: boolean;
  readOnly: boolean;
}
```

- One `setCellProps` call with everything (the grid replaces the whole
  props object, `eui-data-grid/cell.gts:289-298`):
  `{ className: 'euiSheet__cell--selected euiSheet__cell--invalid' (those that apply), 'aria-selected': 'true' | undefined, 'aria-invalid': 'true' | undefined, title: errors.join('\n') | undefined }`,
  and `{}` when nothing applies.
- Content: when `rejected` or the type has no `cell` component, the text.
  Otherwise `<type.cell @value @text @field @record @errors @readOnly @onCommit />`
  (signature in 9.1). `@onCommit(value)` is
  `sheet.commitCellValue(row, col, value)` → `emit(commitValue(...))`.

Built-in cells:

| Type | Cell |
| --- | --- |
| text, number, date | No component: the formatted text. |
| checkbox | `<span class="euiSheet__checkbox {{if @value 'euiSheet__checkbox--checked'}}" role="img" aria-label={{@text}} data-test-subj="euiSheetCheckbox" {{on "click" this.toggle}}>` with a check drawn in CSS. Not focusable. `toggle` calls `@onCommit(!@value)` unless `@readOnly`. |
| singleSelect | Empty value: nothing. Else `<EuiBadge @color={{option.color}}>{{@text}}</EuiBadge>` (`'hollow'` when the option has no colour or the value matches no option). No `@onClick`, so the badge is a `<span>`. `data-test-subj="euiSheetChip"`. |

### 7.4 Controller: nav mode

The spike's table (`DESIGN.md` 5.5) with these rows changed or added. `pos`,
`field`, `record`, `type` come from the event's cell.

| Key (target is a data cell) | Condition | Action | Stop |
| --- | --- | --- | --- |
| any key for which `type.navKey?.(key, value, field)` returns a result | not read-only, no Ctrl/Meta/Alt | `emit(commitValue(ctx, pos, result.value))` | yes |
| `' '` | not handled above | nothing (P8) | yes |
| Enter, F2 | type has an `editor`, not read-only | `startEdit(pos, cell, null)` | yes |
| Enter, F2 | otherwise | nothing | no |
| printable (`key.length === 1`, no Ctrl/Meta/Alt, not composing) | type has an `editor`, not read-only, `type.opensOnKey?.(key) ?? true` | `startEdit(pos, cell, key)` | yes |
| Delete, Backspace | range exists | `emit(clearRange(ctx, range))`, and the range's rejections are removed | yes |
| arrows, Home, End, PageUp/Down, Tab, Escape, Ctrl/Meta combos | — | the grid's | no |
| `dblclick` | type has an `editor`, not read-only | `startEdit(pos, cell, null)` | — |
| `copy` | range exists, `isClipboardTarget` | `toTsv(rangeMatrix(ctx, range))` | yes |
| `paste` | `text/plain` present, `isClipboardTarget`, not sheet `@readOnly` | `emit(pasteMatrix(ctx, topLeft, parseTsv(text)))`; selection = the pasted block | yes |

The order of the first rows matters: `navKey` is asked before the Space rule
and before type-to-edit.

### 7.5 `emit` and rejections

```ts
@tracked rejections: ReadonlyMap<string, { text: string; message: string; seenValue: unknown }> = new Map();

emit(changeSet: ChangeSet | null, touched: Array<{ id: RecordId; fieldId: string }>): void
```

`touched` is every cell the action wrote or tried to write: the edited cell;
every non-read-only cell of a cleared range; every existing target cell of a
paste. `emit` builds a new map: drops the `touched` keys, drops entries
whose record id is no longer in `@records` (ids that look like a pending
`tempId` are kept until the next write), adds `changeSet.rejected` (key from
`recordId ?? tempId`, `seenValue` = the record's current value), assigns it
only if something changed, then calls `@onChange(changeSet)` when the change
set is not `null`. `cellView` ignores an entry whose `seenValue` is not
`Object.is`-equal to the record's current value (the owner changed it).

### 7.6 Edit lifecycle

```ts
@tracked editing: {
  pos: Pos; recordId: RecordId; field: EuiSheetField; type: EuiSheetFieldType;
  rect: SheetEditorRect;                  // the cell's box, relative to the wrapper (spike D1)
  layout: 'cell' | 'panel';
  placement: 'below' | 'above';           // panel only
  initialKey: string | null;
  draft: string;                          // initial text for the editor
} | null;
draft = '';            // plain: last text reported by the editor
draftDirty = false;    // plain: the editor called onDraftChange
```

- `startEdit(pos, cell, initialKey)`: `draft` = `initialKey` if not null,
  else the cell's rejection text if any, else `type.format(value)`.
  `draftDirty = false`. `layout = type.editorLayout ?? 'cell'`. For a panel:
  `placement = 'above'` when the space below the cell inside the wrapper is
  under 280px and the space above is larger; else `'below'`.
- `commit({ move = [0, 0], refocus = true, result })`, where `result` is
  `{ value } | { text } | undefined`:
  1. `editing = null` first (the re-entrancy guard, unchanged).
  2. `{ value }` → `commitValue`; `{ text }` → `commitText`; `undefined` →
     `commitText(ctx, pos, draft)` **only if `draftDirty`**, else no change.
  3. `emit(...)` with the cell as `touched` (only when step 2 ran a commit).
  4. If `refocus`: `api.setFocusedCell` on `pos + move`, clamped (unchanged).
- `cancel()`: unchanged.
- Editor callbacks (bound once, passed to every editor):
  `onDraftChange(text)` → `draft = text; draftDirty = true`;
  `onCommit(result?, { move }?)` → `commit({ result, move })`;
  `onCancel()` → `cancel()`.
- `onEditorFocusOut` (from `EditorFrame`) → `commit({ refocus: false })`.
- `onScroll` → `commit({ refocus: false })` unless `isInEditor(event.target)`.
- `isInEditor(target)`: inside `.euiSheet__editor`, **or inside any element
  with the class `euiSheetEditorSurface` or the attribute
  `data-eui-sheet-editor-surface`** (for an editor that renders part of
  itself elsewhere, section 9.1). Selector constant:
  `'.euiSheet__editor, .euiSheetEditorSurface, [data-eui-sheet-editor-surface]'`.

### 7.7 Controller: edit mode

In the wrapper's capture `keydown`, when `editing` and `isInEditor(target)`:

1. If `editing.type.handlesKey?.(event)` returns `true`: return. The sheet
   does not prevent, stop or act; the key is the editor's.
2. Else: Enter → `commit({ move: [1, 0] })`; Tab / Shift+Tab →
   `commit({ move: [0, ±1] })`; Escape → `cancel()`; each stopped. Any other
   key: nothing.

`copy`, `paste`: ignored in edit mode (native), as in the spike.

## 8. Editors

### 8.1 `EditorFrame` (`-private/editor-frame.gts`)

```gts
<div class="euiSheet__editor {{this.layoutClass}}"
     data-test-subj="euiSheetEditor" style={{this.style}}
     {{on "focusout" this.onFocusOut}}>
  {{yield}}
</div>
```

- `layout: 'cell'`: `position:absolute; z-index:2; top/left/width/height`
  from the rect (the spike's box).
- `layout: 'panel'`: `position:absolute; z-index:3; left` = the cell's left;
  `min-width` = `max(cell width, 240)`px; `top` = the cell's bottom for
  `'below'`, or `bottom` = wrapper height − the cell's top for `'above'`. The
  cell stays visible.
- `onFocusOut(event)`: return when `event.relatedTarget` is inside the frame
  or inside an editor surface (the selector of 7.6); else
  `@onFocusOut()`. This replaces the spike's `blur` on the input
  (`sheet-editor.gts:56`): an editor may move focus between its own
  elements.
- It is a sibling of the grid inside the wrapper (unchanged). It must not
  carry the class `euiPopover__panel` (`DESIGN.md` 5.4).

In `eui-sheet.gts`:

```gts
{{#if this.editing}}
  <EditorFrame @rect={{this.editing.rect}} @layout={{this.editing.layout}}
               @placement={{this.editing.placement}} @onFocusOut={{this.onEditorFocusOut}}>
    <this.editing.type.editor
      @value={{this.editingValue}} @field={{this.editing.field}} @record={{this.editingRecord}}
      @draft={{this.editing.draft}} @initialKey={{this.editing.initialKey}}
      @onDraftChange={{this.onDraftChange}} @onCommit={{this.onCommit}} @onCancel={{this.cancel}}
      @messages={{this.context.messages}} />
  </EditorFrame>
{{/if}}
```

### 8.2 Built-in editors

**`InputEditor`** (text, number; date when opened by typing). Layout `cell`.

- `<input type="text" class="euiSheet__input" aria-label={{label}} value={{@draft}}>`,
  filling the frame. For `number`: `inputmode="decimal"`. It stays
  `type="text"`: a `type="number"` input reports `''` for `abc` (the
  rejection could not show the text) and `setSelectionRange` throws on it.
- On insert: `focus()`, caret at the end (`setSelectionRange`). If
  `@initialKey` is not null, it calls `@onDraftChange(@draft)` once, so a
  blur right after opening commits the typed character.
- `input` event → `@onDraftChange(value)`.
- No `handlesKey`: the sheet handles Enter, Tab, Escape.

| Key | Action |
| --- | --- |
| Enter | Commit the text, focus the cell below (same cell on the last row). |
| Tab / Shift+Tab | Commit, focus the cell to the right / left (clamped). |
| Escape | Discard, focus the cell. |
| Arrows, Home, End, others | The input's own. Grid focus does not move. |
| Blur, grid scroll | Commit the text if it changed; focus is not moved. |

**`SelectEditor`** (singleSelect). Layout `panel`. `opensOnKey`: any
printable key except Space. `handlesKey`: `Enter`, `ArrowUp`, `ArrowDown`,
`Tab`.

```gts
<div {{on "keydown" this.onKeyDown capture=true}} {{on "mousedown" this.keepFocus}}>
  <EuiPanel @paddingSize="s" @hasShadow={{true}}>
    <EuiSelectable
      aria-label={{label}}
      @options={{this.options}} @singleSelection="always" @searchable={{true}}
      @searchProps={{this.searchProps}} @onChange={{this.onChange}}
      @onActiveOptionChange={{this.setActive}} />
  </EuiPanel>
</div>
```

- `options` (`@cached`): `fieldOptions(@field, @record)` mapped to
  `{ label, key: String(value), checked: value === @value ? 'on' : undefined, data: { value } }`.
- `searchProps` (stable object): `{ compressed: true, defaultValue: @initialKey ?? '', inputRef: (input) => input.focus(), 'data-test-subj': 'euiSheetSelectSearch' }`.
  Focus stays in the search field; the list is driven from it
  (`eui-selectable.gts:571-590`).
- `onChange(options, event, changed)`: `@onCommit({ value: changed.data.value }, { move: event instanceof KeyboardEvent ? [1, 0] : [0, 0] })`.
  With `singleSelection="always"`, picking the current option gives the same
  value, so `commitValue` returns `null` and the editor just closes.
- `setActive(option)`: stores the current option (plain field).
- `onKeyDown` (capture, on the editor's root, so it runs before
  `EuiSelectable`'s bubble handler, whose default branch would reset the
  current option): only `Tab`: `preventDefault`, `stopPropagation`, then
  `@onCommit(active ? { value: active.data.value } : undefined, { move: [0, shift ? -1 : 1] })`.
- `keepFocus(event)`: `preventDefault()` unless the target is an `<input>`.
  A mouse press on an option then keeps focus in the search field, so no
  `focusout` closes the editor before the `click` picks.
- It never calls `@onDraftChange`: a blur or a scroll closes it without a
  change.
- v0.1 does not create options from the editor (`createOnPaste` is paste
  only).

| Key | Action |
| --- | --- |
| typing | Filters the options; the first match becomes current. |
| ArrowDown / ArrowUp | Moves the current option (wraps). |
| Enter | Picks the current option, saves, focuses the cell below. With no current option: nothing. |
| Tab / Shift+Tab | Saves the current option if there is one, focuses the cell to the right / left. |
| Escape | Closes without change, focuses the cell. |
| Click on an option | Saves it, focus returns to the same cell. |
| Blur, grid scroll | Closes without change. |

**`DateEditor`** (date). Layout `cell`. `opensOnKey`: digits only
(`/^\d$/`). No `handlesKey`.

- `@initialKey` is not null → renders `InputEditor` with the same args: the
  user types a date in any accepted format; it is parsed on commit, and an
  invalid text becomes a rejection.
- `@initialKey` is null → `<input type="date" class="euiSheet__input" value={{isoValue}}>`
  where `isoValue` is `@value` if it is a valid ISO date, else `''`. On
  insert: `focus()` only (no `setSelectionRange`, it throws on this input
  type; no `showPicker()`, it needs a user gesture). `input` event →
  `@onDraftChange(input.value)` (an ISO date or `''`, both accepted by the
  type's `parse`).

| Key | Action |
| --- | --- |
| a digit on the cell | Opens the text input with that digit. |
| Enter, F2, double-click on the cell | Opens the native date input on the current value. |
| Enter / Tab / Shift+Tab / Escape in either input | As `InputEditor`. |
| Arrows in the native input | The browser's (change the day, month, year). |

**Checkbox**: no editor (P7). `opensOnKey` is irrelevant: without an
`editor`, Enter, F2, typing and double-click do nothing.

`src/field-types.ts`:

```ts
export const builtInSheetFieldTypes: Record<string, EuiSheetFieldType<any, any>> = {
  text: { ...text, editor: InputEditor },
  number: { ...number, editor: InputEditor },
  checkbox: { ...checkbox, cell: CheckboxCell },
  singleSelect: { ...singleSelect, cell: SelectCell, editor: SelectEditor, editorLayout: 'panel',
                  handlesKey: (e) => e.key === 'Enter' || e.key === 'ArrowUp' || e.key === 'ArrowDown' || e.key === 'Tab' },
  date: { ...date, editor: DateEditor, opensOnKey: (key) => /^\d$/.test(key) }
};
```

## 9. Extension contract

The requirement: v0.1 implements five types, but its contracts must carry
the items below **without changing `EuiSheet`'s structure**. For each: the
signatures, and what v0.1 implements.

### 9.1 Custom cells and editors

```ts
// src/types.ts (Ember layer)
export interface EuiSheetFieldType<V = unknown, F extends EuiSheetField = EuiSheetField>
  extends FieldType<V, F> {
  /** Display component. Default: the formatted text. */
  cell?: ComponentLike<SheetCellSignature<V, F>>;
  /** Editor component. Without one the type has no edit mode (navKey and the cell's @onCommit still work). */
  editor?: ComponentLike<SheetEditorSignature<V, F>>;
  /** 'cell': the editor covers the cell. 'panel': a panel under (or above) the cell. Default 'cell'. */
  editorLayout?: 'cell' | 'panel';
  /** Whether a printable key opens the editor. Default: yes. Space never does. */
  opensOnKey?: (key: string) => boolean;
  /** Keys the editor handles itself while it is open. Default: none. */
  handlesKey?: (event: KeyboardEvent) => boolean;
}

export interface SheetCellSignature<V = unknown, F extends EuiSheetField = EuiSheetField, T = any> {
  Args: {
    value: V | null | undefined;
    /** type.format(value). */
    text: string;
    field: F;
    record: T;
    errors: string[];
    readOnly: boolean;
    /** Saves a value from the cell itself (a checkbox, a rating star). */
    onCommit: (value: V) => void;
  };
}

export interface SheetEditorSignature<V = unknown, F extends EuiSheetField = EuiSheetField, T = any> {
  Args: {
    value: V | null | undefined;
    field: F;
    record: T;
    /** Initial text: the typed character, else the cell's rejected text, else type.format(value). */
    draft: string;
    /** The printable key that opened the editor, or null (Enter, F2, double-click). */
    initialKey: string | null;
    /** Reports the text to parse if the editor is closed by blur, scroll, or a key the sheet handles. */
    onDraftChange: (text: string) => void;
    /** Closes the editor. `{ value }` is saved as is, `{ text }` goes through type.parse, nothing saves the reported draft. `move` is [rows, cols]; default [0, 0]. */
    onCommit: (result?: { value: V } | { text: string }, options?: { move?: [number, number] }) => void;
    /** Closes the editor without a change and focuses the cell. */
    onCancel: () => void;
    messages: SheetMessages;
  };
}
```

Rules of the contract:

| Topic | Rule |
| --- | --- |
| Registration | `@fieldTypes={{this.fieldTypes}}`, a stable object `{ name: EuiSheetFieldType }`; a field uses it with `type: 'name'`. |
| Cell | Must not render a tabbable element (P9). A click target calls `@onCommit`. |
| Focus | The editor owns focus inside itself: it must focus one of its elements when inserted. The sheet owns focus on the way out: after `onCommit`/`onCancel` it calls `setFocusedCell`. |
| Leaving | The frame's `focusout` to anywhere outside the editor commits the reported draft (or nothing) without moving focus. |
| Keys | The wrapper's capture listener sees every key first. It calls `handlesKey(event)`; `true` means the sheet does nothing with that event. Otherwise the sheet handles Enter, Tab, Shift+Tab, Escape and leaves the rest. An editor that claims Tab or Enter must call `@onCommit` itself, with the `move` it wants. `handlesKey` can depend on the event only; an editor whose needs change (list open or closed) claims the key and decides inside. |
| Content rendered elsewhere | An editor built on a component that renders in a wormhole (`EuiComboBox`, `EuiPopover`, `EuiSuperSelect`) marks that panel with the class `euiSheetEditorSurface` (or the attribute `data-eui-sheet-editor-surface`). A class is accepted because some components only let a class through: `EuiComboBox`'s `@inputPopoverProps` has `panelClassName` and sends other keys to its root (`eui-combo-box.gts:80-96`). Focus moving there is not a blur, and its scroll does not commit. Keys pressed there do not pass through the wrapper: the editor handles them and calls `@onCommit`/`@onCancel`. |
| Editor inside the wrapper | Preferred (`EuiSelectable`, inputs): keys, blur and scroll need nothing extra. |

**v0.1 implements all of 9.1**: the built-in types are registered through
it, and tests C1–C3 register an app type.

Example, a Prysmex `zone` picker with async search. The value is
`{ id, label }`, so the cell needs no lookup:

```ts
// app/sheet/zone-type.ts
import type { EuiSheetFieldType } from '@ember-eui/sheet';
import ZoneEditor from './zone-editor.gts';

type Zone = { id: string; label: string };

export const zoneType: EuiSheetFieldType<Zone | null> = {
  parse: (text) => (text.trim() === '' ? { value: null } : { unresolved: text.trim() }),
  format: (value) => value?.label ?? '',
  isEmpty: (value) => value == null,
  compare: (a, b) => (a?.label ?? '').localeCompare(b?.label ?? ''),
  editor: ZoneEditor,
  editorLayout: 'panel',
  handlesKey: (e) => ['Enter', 'ArrowUp', 'ArrowDown'].includes(e.key)
};
```

```gts
// app/sheet/zone-editor.gts
export default class ZoneEditor extends Component<SheetEditorSignature<Zone | null>> {
  @service declare store: Store;
  @tracked options: EuiSelectableOption[] = [];
  @tracked isLoading = false;
  @tracked error: string | null = null;
  request = 0;

  searchProps = {
    defaultValue: this.args.initialKey ?? '',
    inputRef: (input: HTMLInputElement) => input.focus(),
    onChange: (query: string) => void this.search(query)   // also called once after the first render
  };

  async search(query: string) {
    const request = ++this.request;
    this.isLoading = true;
    this.error = null;
    try {
      const zones = await this.store.query('zone', { q: query, site: this.args.record.siteId });
      if (request !== this.request) return;               // a newer search is running
      this.options = zones.map((z) => ({ label: z.name, key: z.id, data: { value: { id: z.id, label: z.name } } }));
    } catch {
      if (request === this.request) this.error = 'Could not load zones';
    } finally {
      if (request === this.request) this.isLoading = false;
    }
  }

  pick = (_options: unknown, event: Event | undefined, changed: EuiSelectableOption) =>
    this.args.onCommit({ value: changed.data!.value as Zone }, { move: event instanceof KeyboardEvent ? [1, 0] : [0, 0] });

  keepFocus = (event: MouseEvent) => {
    if (!(event.target instanceof HTMLInputElement)) event.preventDefault();
  };

  <template>
    <div {{on "mousedown" this.keepFocus}}>
      <EuiPanel @paddingSize="s" @hasShadow={{true}}>
        <EuiSelectable aria-label="Zone" @options={{this.options}} @singleSelection="always"
          @searchable={{true}} @isPreFiltered={{true}} @isLoading={{this.isLoading}}
          @errorMessage={{this.error}} @searchProps={{this.searchProps}} @onChange={{this.pick}} />
      </EuiPanel>
    </div>
  </template>
}
```

```gts
<EuiSheet @fields={{this.fields}} @records={{this.store.records}} @getRecordId={{this.getId}}
  @onChange={{this.store.apply}} @fieldTypes={{this.fieldTypes}} />
// this.fieldTypes = { zone: zoneType };  a field: { id: 'zone', label: 'Zone', type: 'zone' }
```

In v0.1, pasting text into this field gives a rejection ("could not be
resolved"): the bulk resolve of 9.2 is not implemented.

### 9.2 Async option sources and bulk resolve on paste

Editor side: nothing to add. The editor is a component, so it loads on
demand, shows `EuiSelectable`'s `@isLoading` and `@errorMessage`, and
discards stale responses itself (the example above).

Paste side, contract (not implemented in v0.1):

```ts
// ParseResult already has:  | { unresolved: string }

export interface ResolveRequest<T = any> {
  fieldId: string;
  /** Distinct texts to resolve for this field. */
  texts: string[];
  /** The cells that asked, for sources that depend on the record. */
  cells: Array<{ text: string; recordId?: RecordId; tempId?: string; record: T | undefined }>;
}
/** Per field: text → the value to store, or null when nothing matches. */
export type ResolveResult = Record<string, Record<string, unknown | null>>;

// future EuiSheet arg
onResolve?: (requests: ResolveRequest[], options: { signal: AbortSignal }) => Promise<ResolveResult>;
```

How it fits: `pasteMatrix` gets a sibling, `planPaste`, that returns the
sync change set plus the unresolved cells. The sheet calls `@onResolve`
**once per paste** with one request per field, then emits **one** change
set: resolved cells as patches (their `from` read from the records at that
moment), `null` results as rejections. While waiting, the unresolved cells
show their text as pending. A newer write to a cell, or a newer paste over
it, discards that cell's result; the `signal` is aborted when no cell is
left waiting. This is the same call the plan names `onResolveLinked`.

v0.1 implements: the `unresolved` variant in the type, treated as a
rejection with `messages.unresolved(text)`. Sync sources resolve in `parse`
(the built-in `singleSelect`).

### 9.3 Options that depend on the record

```ts
options: SheetOption[] | ((record: T) => SheetOption[]);   // SingleSelectField
```

- `fieldOptions(field, record)` is the only reader: the editor, `parse`,
  `format` and `validate` all go through it.
- When the dependency changes (the user changes `area`), the `position`
  value is **kept** and its cell shows `"Supervisor" is not an option`,
  because `validate` is derived on render (P2). Nothing is cleared silently:
  the user sees what was there and picks again, and one change set never
  writes cells the user did not touch. An owner that prefers clearing adds
  the patch itself when it applies the change set.
- In a paste, a row's cells are parsed left to right against the row's
  accepted values (5.5), so `area` and `position` pasted together are
  checked consistently when `area` is to the left.
- Return the same array for the same input when possible (the select editor
  caches by `@field` and `@record`).

v0.1 implements all of 9.3 (tests F5, N13).

### 9.4 Validation layers

| # | Layer | Contract | Runs | v0.1 |
| --- | --- | --- | --- | --- |
| 1 | Parse | `FieldType.parse` → `{ error }` | On commit and paste, per cell | Yes |
| 2 | Type rules | `FieldType.validate(value, field, ctx)` | Derived at render from `@records`: so on load, after a commit, after a paste | Yes |
| 3 | Field rules | `required`; `min`/`max`/`pattern`/`maxLength` read by the type's `validate`; `field.validate(value, record)` | As 2 | Yes |
| 4 | Record rules | `recordRules?: Array<(record: T) => Record<string, string \| string[]> \| undefined>` (future arg). The rule names the cells: `(r) => r.end < r.start ? { end: 'Must be after the start date' } : undefined` | As 2, for rendered rows | No |
| 5 | Cross-row rules | `validate?: (context: ValidateContext<T>) => CellErrors \| Promise<CellErrors>` (future arg, below). Example: unique email → an error on every duplicate cell | After each emitted change set and when `@records` changes; debounced | No |
| 6 | Async (server) | The same `validate`, returning a promise | As 5 | No |
| 7 | Owner errors | `@cellErrors` | Whenever the owner changes it | Yes |

```ts
export interface ValidateContext<T> {
  records: readonly T[];
  /** Cells written since the last run; empty on load. */
  changed: Array<{ recordId: RecordId; fieldId: string }>;
  signal: AbortSignal;
}
```

Merge: one list per cell in the order rejection, 2, 3, 4, 5/6, 7, without
duplicates (`mergeErrors`). A cell with a rejection skips 2–4 (they would
describe the old value). No layer blocks a patch except 1.

Stale async results: each run has a sequence number and an `AbortSignal`.
Starting a run aborts the previous one. A result is applied only if its
number is the latest; within it, an error is dropped for a cell whose record
object is not the one the run started with (the owner replaces a patched
record, so identity is enough).

In v0.1 the owner does layers 4, 5 and 6 itself and passes the result as
`@cellErrors`. That input is the universal layer; the future args are
conveniences that produce the same shape, so adding them changes no existing
contract.

To be exact about "without changing `EuiSheet`": 9.1, 9.3, 9.5 and 9.6 need
no change at all. Bulk resolve (9.2) and layers 4–6 as built-in conveniences
each add **one optional argument** to `EuiSheet` later (`@onResolve`,
`@recordRules`, `@validate`) plus the code behind it; no existing argument,
type or change-set field changes. They are sheet-level and not on the field
type because one paste must give one call across fields, and a cross-row
rule has no single field. Question Q10.

### 9.5 Conditional field state

```ts
readOnly?: boolean | ((record: T) => boolean);
required?: boolean | ((record: T) => boolean);
```

Read only through `isReadOnly` and `isRequired`. For a row being inserted by
a paste, the function gets the values accepted so far. A read-only cell
ignores Enter, F2, typing, `navKey`, the cell's `@onCommit`, Delete and
paste; it can be copied. **v0.1 implements it** (tests U11, N17).

### 9.6 Future types

None is implemented in v0.1. Each fits `EuiSheetFieldType` as it is.

| Type | Value | Cell | Editor | Parse / paste |
| --- | --- | --- | --- | --- |
| multiSelect | `Array<option value>` | Chips | `EuiSelectable` without `singleSelection`, panel; commits on Tab/blur through `onCommit({ value })` | Split on `,`; each part as singleSelect; `newOption` per part needs `newOption` to become `newOptions[]` in `ParseResult` (additive). `isEmpty`: empty array. |
| linked record | `Array<{ id, label }>` | Chips from `label` | Async search editor (as 9.1's example), panel | `unresolved` per name → the bulk `@onResolve` (9.2). |
| user / collaborator | `{ id, label, avatarUrl? }` or an array | Avatar + name | As linked record | As linked record (resolve by name or email). |
| attachment | `Array<{ id, name, url }>` | File names / thumbnails | A panel with the owner's upload component; the owner uploads and the editor calls `onCommit({ value })` | `parse` returns an error for non-empty text; `copyText` gives the URLs. |
| rating | `number \| null` | Stars drawn in CSS; a click calls `@onCommit(n)` | None | `navKey`: digits `0`–`max` set the value; `parse` as number with `min`/`max`. |

## 10. Test plan

Harness: the files copied in 3.1 (`tests/index.html`, `test-helper.ts`,
`deprecations.ts`, `helpers/index.js`, `testem.cjs`, `vite.config.mjs`), as
`packages/validated-form`. Style as the spike test (`.gts`,
`setupRenderingTest` from `ember-qunit`, `render(<template>…</template>)`).
Tests import the package's source as `#src/...` (for example
`#src/components/eui-sheet.gts`, `#src/core/index.ts`,
`#src/local-records.ts`).

### 10.1 Ported from the spike

Integration (`eui-sheet-test.gts`), from
`packages/core/tests/integration/spikes/eui-sheet-spike-test.gts`. Port
T1–T16 with their assertions; the porting changes are only:

- No `SOURCES` loop, no `@cursorSource`, no `(source)` in the names.
- Class `euiSheet__cell--selected`; fields are `{ id }` (type `text`).
- Expected change sets go through the `changeSet()` helper (adds
  `rejected: []`, `newOptions: []`).
- **T8** (`:443`): the field knob `isExpandable` is gone. The case becomes:
  no `[data-test-subj=euiDataGridCellExpandButton]` in `cell(1, 1)` (the spike asserted that it exists, `:449`); after
  Enter and after F2 the editor exists, `[data-test-subj=euiDataGridExpansionPopover]`
  does not, the cell lacks `euiDataGridRowCell--open`.
- **T11** (`:503`): unchanged assertions; the input is `.euiSheet__input`.
- **T9** (`:469`) now also proves the `focusout` path of `EditorFrame`.
- `demo (manual)` (`:639`): kept, with one field of each type, 50 records,
  `@height={{400}}`, `pauseTest()` only when `location.search` has
  `sheetdemo`.

Unit, from `packages/core/tests/unit/spikes/sheet-change-set-test.ts`:

| # | Case | Change |
| --- | --- | --- |
| U1 | `toRange` | None. |
| U2 | `parseTsv` | None. |
| U3 | `toTsv(parseTsv(x))` round-trip | None. |
| U4 | `commitText` (was `commitPatch`) | "`parse` applied" uses a `number` field: `'7'` → `to: 7`. Read-only and unchanged → `null`. |
| U5 | `clearRange` | A `number` cell clears to `null`, a `text` cell to `''`. |
| U6 | `pasteMatrix` | Same cases; change sets carry the two new arrays. |
| U7 | `rangeMatrix` | "`format` applied" uses a `date` field: the matrix holds the ISO value (`copyText`), not the display format. |
| U8 | `localRecords().apply` | Plus: `applyChangeSet` gives the same result as a pure call. |

### 10.2 New unit cases

`change-set-test.ts`:

| # | Case |
| --- | --- |
| U9 | `commitText` of `abc` in a number field: `patches: []`, `rejected: [{ recordId, fieldId, text: 'abc', message: '"abc" is not a number' }]`. |
| U10 | `commitValue`: one patch; `null` when unchanged or read-only. |
| U11 | `readOnly` as a function: `(r) => r.locked` skips only the locked record in `clearRange` and `pasteMatrix`; sheet-level `ctx.readOnly` skips everything. |
| U12 | `pasteMatrix` with `createOnPaste`: `Purple` twice in one column → two patches `to: 'Purple'`, one `newOptions` entry `{ fieldId, option: { value: 'Purple', label: 'Purple' } }`. Without `createOnPaste`: two `rejected`, no `newOptions`. |
| U13 | `pasteMatrix` past the end with a rejected cell: the insert exists, `values` lacks that field, `rejected` has `{ tempId: 'new-0', fieldId, text, message }`. A pasted row with only rejected cells is still inserted. |
| U14 | `applyNewOptions`: same array when there is nothing; the field object replaced and the option appended; an existing value not duplicated; a function `options` untouched. `localRecords({ fields })`: `store.fields` updated by `apply`. |

`field-types-test.ts`:

| # | Case |
| --- | --- |
| F1 | text: parse keeps spaces; format of `null` is `''`; `maxLength` and `pattern` errors; `patternMessage`. |
| F2 | number: every example of 5.4, with `decimalSeparator: ','` too (`1.234,5` → 1234.5, `1,5` → 1.5); `''` → `null`; `min`/`max`. |
| F3 | checkbox: each word of the two lists, upper and lower case; `maybe` → error; `navKey(' ', false)` → `{ value: true }`; `navKey('a')` → `undefined`; `isEmpty(false)` is true. |
| F4 | singleSelect: match by label (case-insensitive), then by value; `''` → `null`; unknown → error; unknown with `createOnPaste` and source `paste` → value + `newOption`; with source `edit` → error; `format` of an unknown value is the value; `validate` of an unknown value. |
| F5 | singleSelect with `options` as a function of the record: `parse`, `format`, `validate` use `context.record`. |
| F6 | date: every example of 5.4; `mdy`; `2026-11-19T10:00:00Z` → `2026-11-19`; `format` in both orders; `copyText` is ISO; `min`/`max`; `validate('2026-02-30')`. |
| F7 | For each built-in type and a list of values: `parse(copyText(v))` gives `v`. `createRegistry({ text: custom })` replaces the built-in; `resolveType` throws on an unknown name. |

`errors-test.ts`:

| # | Case |
| --- | --- |
| E1 | `validateCell`: required + empty → `['Required']` and the type's `validate` is not called; `required` as a function. |
| E2 | `validateCell`: order is type, then `field.validate` (string and array results). |
| E3 | `mergeErrors` drops duplicates and empty values; `compareValues` for number and date with `null`. |

`core-boundary-test.ts`:

| # | Case |
| --- | --- |
| B1 | `import.meta.glob('../../src/core/**/*.ts', { query: '?raw', import: 'default', eager: true })`: no file contains `from '@ember`, `from '@glimmer`, `from 'ember-`, `from '@ember-eui`. (ESLint enforces it too; this fails in the test run.) |

### 10.3 New integration cases (`eui-sheet-types-test.gts`)

Fixture: fields `name` (text, `required: true`), `qty` (number), `done`
(checkbox), `status` (singleSelect: `Open` `open`, `Closed` `closed`
colour `success`, `On hold` `hold`), `due` (date); 5 records `r0`–`r4`,
each `{ name: 'name<i>', qty: i, done: false, status: 'open', due: null }`;
`localRecords(records, { getRecordId, fields })`; the sheet gets
`@fields={{store.fields}}`. Columns: 0 name, 1 qty, 2 done, 3 status, 4 due.

| # | Case | Actions | Assertions |
| --- | --- | --- | --- |
| N1 | number: typing saves a number | `focusCell(0,1)`, `type('7')`, Enter | Patch `to: 7` (a number); the editor input had `inputmode="decimal"` and `type="text"`. |
| N2 | number: paste of `abc` gives a cell error | `focusCell(0,1)`, paste `abc` | No patch; `store.log[0].rejected` has the entry; `text(0,1) === 'abc'`; `isInvalid(0,1)`; `cellTitle(0,1) === '"abc" is not a number'`; the record's `qty` unchanged. |
| N3 | number: typing an invalid text | `type('a')`, `fillIn(editor(), 'abc')`, Enter | As N2; focus on `cell(1,1)`. Then Enter on `cell(0,1)`: the editor's value is `abc`. `fillIn('12')`, Enter: patch `to: 12`, the cell is no longer invalid. |
| N4 | a rejection is cleared by Delete | After N2's paste, Delete on the cell | Not invalid; text is the old value's clear result (`''`); one `clear` change set if the old value was not empty. |
| N5 | a mixed paste | Paste `x\tabc` at `(1,0)` | Patch for `name`, rejection for `qty`, one change set. |
| N6 | checkbox: Space toggles | `focusCell(0,2)`, `press(' ')` twice | Patches `to: true` then `to: false`; no editor; the box has/lacks `euiSheet__checkbox--checked`; the events were `defaultPrevented`. |
| N7 | checkbox: click toggles, other keys do nothing | Click `[data-test-subj=euiSheetCheckbox]` in `cell(1,2)`; then Enter, F2, `type('x')`, double-click | One patch from the click; no editor and no further change set. The box is not tabbable (`tabindex` absent, no `data-euigrid-tab-managed` in the cell). |
| N8 | checkbox: paste | Paste `true\n1\nyes\nx\nno` at `(0,2)` (records all `false`) | Four patches `to: true` (rows 0–3), none for row 4. Then paste `false\n0\nmaybe` at `(0,2)`: two patches `to: false`, one rejection for `maybe`. |
| N9 | Space on a text cell does nothing | `focusCell(0,0)`, `press(' ')` | No editor, no change set, `defaultPrevented`. |
| N10 | select: the cell shows a chip | — | `cell(0,3)` has `[data-test-subj=euiSheetChip]` with the label; the `closed` chip carries the success colour class. |
| N11 | select: pick with the keyboard | `focusCell(0,3)`, Enter, then ArrowDown until the option `Closed` is the current one (read `aria-activedescendant` of the search input; expected 2 presses, since no option is current when the search field gets focus: `eui-selectable.gts:571-590`, see V5), Enter | The editor is a panel outside `.euiDataGrid`, inside the wrapper; the search input has focus; after: patch `from: 'open'`, `to: 'closed'`, no editor, focus on `cell(1,3)`. Then on `(1,3)`: Enter, ArrowDown to `Open` (the current value), Enter → no change set, the editor is closed (with `singleSelection="always"`, `toggleOptionWithChange` still reports the option, `-private/selectable-options.ts:131-167`). |
| N12 | select: type to filter, Tab, Escape, click (the "first match is current" step depends on V5) | `type('h')` → search value `h`, the list shows `On hold`; Tab → patch `to: 'hold'`, focus on `cell(0,4)`. Then on `(1,3)`: Enter, Escape → no change set, focus on `cell(1,3)`. Then Enter, click the `Open` option → patch, focus back on `cell(1,3)`. Then Enter, `click(cell(3,0))` → no change set, focus on `cell(3,0)`. |
| N13 | select: options that depend on the record | Field `position` with `options: (r) => byArea[r.area]`; record 0 has `area: 'a'`, `position: 'a1'` | The editor on `(0, position)` lists only area `a`'s options. After the owner changes `area` to `b` (through a paste on the `area` cell): `position` still `a1`, its cell invalid with `"a1" is not an option`, no patch for `position`. |
| N14 | select: paste of an unknown value | Paste `Purple` at `(0,3)` | Rejection, cell invalid, title `"Purple" is not an option`, no `newOptions`. Paste `closed` and paste `Closed`: both patch `to: 'closed'`. |
| N15 | select: `createOnPaste` | Same with `createOnPaste: true` on the field | `store.log[0].newOptions` is `[{ fieldId: 'status', option: { value: 'Purple', label: 'Purple' } }]`; patch `to: 'Purple'`; after `settled()` the cell shows a `Purple` chip and is not invalid; the editor lists `Purple`. |
| N16 | date: paste | Paste `2026-11-19` at `(0,4)`, `19/11/2026` at `(1,4)`, `31/02/2026` at `(2,4)` | Patches `to: '2026-11-19'` for rows 0 and 1; the cells show `19/11/2026`; row 2 rejected, title `"31/02/2026" is not a date`. Copy of `(0,4)` gives `2026-11-19`. |
| N17 | date: editors | `focusCell(0,4)`, Enter → the editor is `input[type=date]` with the ISO value; `fillIn('2026-12-01')`, Enter → patch. `type('1')` → the editor is a text input with value `1`; `fillIn('1/2/2026')`, Tab → patch `to: '2026-02-01'`. `type('a')` → no editor. |
| N18 | required field cleared | `focusCell(0,0)`, Delete | Patch `to: ''` is emitted; the cell is invalid with title `Required`. A record that starts with an empty `name` is invalid on first render. With `required: (r) => r.done`, only records with `done` are flagged. |
| N19 | owner `@cellErrors` | `@cellErrors={{hash r1=(hash qty="Too many")}}`, then an object that also adds `name` on a required-empty cell | `cell(1,1)` invalid, title `Too many`; the second cell's title is `Required\n<owner message>`; removing the arg clears the first. |
| N20 | `@readOnly` and a read-only function | `@readOnly={{true}}` | Enter, typing, Space on a checkbox, a click on the box, Delete and paste change nothing; copy still works. With `readOnly: (r) => r.id === 'r1'` on `qty`, only that cell is locked. |

### 10.4 Custom type (`eui-sheet-custom-type-test.gts`)

| # | Case | Assertions |
| --- | --- | --- |
| C1 | An app type `rating` with a `cell` component and `navKey` (digits) | The cell component renders with `@value`, `@text`, `@field`; pressing `3` gives a patch `to: 3` without an editor; a click on a star calls `@onCommit`. |
| C2 | An app type with an `editor` component that claims ArrowDown and Enter through `handlesKey`, counts the keydowns it receives, and commits with `@onCommit({ value }, { move: [0, 1] })` | The editor gets `@draft`, `@initialKey` (`'x'` after typing, `null` after Enter), `@record`; ArrowDown and Enter reach the editor's own listener and do not close it; its commit gives a patch and moves focus right; Escape (not claimed) cancels through the sheet; `@onCommit({ text })` goes through `parse`. |
| C3 | An editor with a second element marked `data-eui-sheet-editor-surface`, rendered in `#ember-testing` outside the wrapper | Moving focus to a button there does not close the editor; focusing a grid cell does. |

## 11. Build, lockfile and test procedure

Nothing runs `pnpm`, `npm`, `vite` or `testem` inside
`/Users/betocantu93/prysmex/ember-eui` (its `node_modules` are macOS-only).
One scratch copy, reused.

### 11.1 Disk and the copy

```bash
df -h /        # 3.3 GB free on 2026-11-19
S=<your scratchpad>
cd /Users/betocantu93/prysmex/ember-eui
git ls-files -co --exclude-standard -z | rsync -a --from0 --files-from=- ./ "$S/ember-eui/"
```

The spike's scratch copy and store are gone (only its logs remain in the
spike's scratchpad), so this is a fresh copy: about 0.8 GB with
`node_modules`, plus about 40 MB for core's build. `rsync` does not delete:
after removing a file in the checkout (section 12), remove it in the copy
too.

### 11.2 Lockfile (once, after `packages/sheet/package.json` exists)

```bash
cd "$S/ember-eui"
cp pnpm-lock.yaml "$S/pnpm-lock.before.yaml"
pnpm install --no-frozen-lockfile --store-dir "$S/pnpm-store" > "$S/install.log" 2>&1   # background
diff "$S/pnpm-lock.before.yaml" pnpm-lock.yaml > "$S/lock.diff"; grep -c '^<' "$S/lock.diff"
```

- `--no-frozen-lockfile` is needed explicitly: with `CI=1` pnpm defaults to
  a frozen lockfile. The sandbox has pnpm 12.6.0, the version in
  `packageManager`.
- Expected diff: **only added lines** (`grep -c '^<'` prints `0`), forming
  one `packages/sheet:` importer block next to the other importers, because
  every specifier is copied from `packages/validated-form` and already
  resolved. If any line is removed or changed elsewhere (a re-resolved
  version, a changed `settings` block), **stop**: do not copy the lockfile
  back, report the diff.
- Then copy **only** the lockfile back:
  `cp "$S/ember-eui/pnpm-lock.yaml" /Users/betocantu93/prysmex/ember-eui/pnpm-lock.yaml`.
- After that, every later install in scratch uses `--frozen-lockfile`.
- If the registry is blocked (HTTP 403 from the sandbox proxy), follow the
  network section of `~/CLAUDE.md`; do not work around it.

What the user runs on the Mac afterwards:

```bash
cd ~/prysmex/ember-eui
pnpm install                       # links packages/sheet into the workspace; must not change pnpm-lock.yaml
git status --short pnpm-lock.yaml  # expect no further change
pnpm --filter @ember-eui/core build
pnpm --filter @ember-eui/sheet lint
pnpm --filter @ember-eui/sheet test
pnpm --filter @ember-eui/sheet build      # dist + declarations
pnpm test:dist                            # scripts/dist-hygiene.test.mjs, needs the builds
pnpm docs:api:check
```

### 11.3 Build core, then run the sheet's tests

The sheet imports `@ember-eui/core/...`, which resolves to
`packages/core/dist` and `packages/core/declarations` through the workspace
symlink. Both are git-ignored, so the copy does not have them. The spike
never needed this (core's tests import `#src/*`).

```bash
cd "$S/ember-eui/packages/core"
pnpm build:js    > "$S/core-build-js.log" 2>&1      # rollup → dist (25 MB). Background; not timed before.
pnpm build:types > "$S/core-build-types.log" 2>&1   # ember-tsc → declarations (15 MB). Needed for lint and types only.

cd "$S/ember-eui/packages/sheet"
pnpm exec vite build --mode=development --out-dir dist-tests --emptyOutDir > "$S/build.log" 2>&1
CI=1 pnpm exec testem --file testem.cjs ci --port 0 \
  --test_page 'tests/index.html?hidepassed&filter=Sheet' > "$S/test.log" 2>&1
```

- Core is built once; rebuild it only if `packages/core/src` changes (it
  must not).
- `CI=1` makes `testem.cjs` pass `--no-sandbox` to Chrome.
- The package's own `pnpm test` also runs `node ../../scripts/sync-injected.mjs`
  first; the two commands above skip it (see V1).
- After each edit: the `rsync` line, the `vite build`, the run.
- The sheet's suite is short. If a run is long (or fails only with
  `Browser timeout exceeded`), use the spike's long config and compare
  `date` before and after:
  `module.exports = { ...require(process.cwd() + '/testem.cjs'), browser_disconnect_timeout: 86400 };`
  in `$S/testem-long.cjs`, with `--file "$S/testem-long.cjs"`.
- Anything longer than a couple of minutes runs in the background.
- `No space left on device` or rolldown's `UNHANDLEABLE_ERROR`: the disk is
  full, see `~/prysmex/CLAUDE.md`.

Static checks, in `$S/ember-eui/packages/sheet` (need core's declarations):

```bash
pnpm exec ember-tsc --noEmit
pnpm exec eslint .
pnpm exec prettier --check src tests
```

Package build, to check the published shape:

```bash
pnpm build      # rollup + ember-tsc → dist, declarations
ls dist/index.js dist/core/index.js dist/components/eui-sheet.js dist/_app_/components/eui-sheet.js
git -C /Users/betocantu93/prysmex/ember-eui diff --stat packages/sheet/package.json   # after copying package.json back: app-js must be unchanged
```

`addon.appReexports` rewrites `ember-addon.app-js` in `package.json` during
the build. It must come out as written in section 4; if the build changes
it, copy the built `package.json` back.

Core regression: the sheet does not touch `packages/core/src`. After
deleting the spike tests (section 12), run core's `EuiDataGrid` filter once
(`RESULTS.md` section 5; 88 tests) to confirm nothing else depended on them.

### 11.4 Real input

Synthetic events cannot show where the browser sends keys and clipboard
events (`RESULTS.md` section 6). Repeat that pass on the package's demo test
with Playwright:

```bash
cd "$S/ember-eui/packages/sheet"
pnpm exec vite preview --outDir dist-tests --port 4173 --host 0.0.0.0     # background
# open /tests/index.html?filter=demo&sheetdemo
```

`vite dev` failed for core's test page because of a type-only import inside
core's `src`; the sheet consumes core's `dist`, so `pnpm test:dev` may work
here. Not verified: use `vite preview` if it does not.

Check with trusted events: the seven rows of `RESULTS.md` section 6, plus:
Space toggles a checkbox and the page does not scroll; typing a letter on a
select cell opens the list filtered by it, once; ArrowDown and Enter pick;
a click on an option picks (focus stayed in the search field); a digit on a
date cell opens the text input with that digit once; Enter on a date cell
opens the native input and the typed date is saved; a paste of a 3-column
block from a spreadsheet over number, select and date columns. Firefox,
Safari and IME still need the Mac.

### 11.5 Clean up

`rm -rf "$S/ember-eui" "$S/pnpm-store"` before ending; keep the logs.

## 12. The spike code in core

Recommendation: **delete** `packages/core/tests/spikes/`,
`packages/core/tests/integration/spikes/` and
`packages/core/tests/unit/spikes/` in the same branch, as its own commit,
after the package's `Sheet` filter passes.

- The package's T1–T16 and U1–U8 cover the same behaviour; two copies would
  drift.
- They run in core's suite on every CI run (`tests/index.html` loads every
  file).
- The spike component still carries the `api` cursor path for a hook that
  was dropped.

Kept: `internal/spikes/sheet/DESIGN.md`, `RESULTS.md`, `cell-api.patch`
(the patch's contract test is inside the patch, not in the tree). Append to
`RESULTS.md` a short section 8 with the commit that moved the code.

## 13. README and docs

`packages/sheet/README.md` (the siblings' READMEs are the blueprint
placeholder; this one is real). Contents:

1. One paragraph: what it is, that it is controlled (records in, change sets
   out), that it needs `@ember-eui/core`.
2. Install: `pnpm add @ember-eui/sheet` (peer: `@ember-eui/core`).
3. Usage:

```gts
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import type { EuiSheetField } from '@ember-eui/sheet';

interface Task { id: string; name: string; hours: number | null; done: boolean; status: string | null; due: string | null }

const FIELDS: EuiSheetField<Task>[] = [
  { id: 'name', label: 'Task', required: true },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
  { id: 'done', label: 'Done', type: 'checkbox' },
  { id: 'status', label: 'Status', type: 'singleSelect', createOnPaste: true,
    options: [{ value: 'open', label: 'Open' }, { value: 'closed', label: 'Closed', color: 'success' }] },
  { id: 'due', label: 'Due', type: 'date' }
];

export default class Tasks extends Component {
  getId = (task: Task) => task.id;
  store = localRecords<Task>(
    [{ id: 't1', name: 'Inspect line 3', hours: 2, done: false, status: 'open', due: '2026-11-19' }],
    { getRecordId: this.getId, fields: FIELDS }
  );

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{400}}
    />
  </template>
}
```

4. "Your own store": the `ChangeSet` shape, `applyChangeSet`,
   `applyNewOptions`, what `rejected` and `tempId` mean.
5. Field types table (value, accepted text, options) from section 5.4.
6. Keyboard table (sections 7.4, 8.2), including: Space toggles a checkbox
   and does nothing elsewhere.
7. Errors: rejections versus validation, `@cellErrors`.
8. Custom field types: the contract of 9.1 in short, with the `zone`
   example.
9. Limits: the out-of-scope list of section 1.

Docs-site page: **later**. It needs `@ember-eui/sheet` in
`site/package.json` (an injected workspace dependency, so another lockfile
change), a `packages/sheet/docs/` folder, an entry in
`scripts/api-docs-pages.json` and in `scripts/generate-llms-txt.mjs:21`. Do
it when the v0.1 API has been used once in Prysmex.

## 14. Changeset

`.changeset/config.json` has no `fixed` or `linked` groups and
`"access": "restricted"` (each package sets `publishConfig.access: public`).
Add `/.changeset/sheet-initial-release.md`:

```md
---
'@ember-eui/sheet': minor
---

New package: `EuiSheet`, an Airtable-like data-entry grid built on `EuiDataGrid`. Controlled data (`@records` in, `@onChange(changeSet)` out), keyboard editing, range selection, copy and paste as TSV, five field types (text, number, checkbox, single select, date), cell errors, and a contract for custom cells and editors.
```

With the package at `0.0.0`, `changeset version` makes it `0.1.0` and writes
its `CHANGELOG.md`. While `"private": true` is set, `changeset publish`
skips it. Not verified here (it cannot run in the sandbox): that
`changeset version` handles a private package with the repo's
`@changesets/cli` `^2.31.1` defaults (V4).

## 15. To verify during implementation (could not be run for this design)

| # | Check | If it fails |
| --- | --- | --- |
| V1 | `node scripts/sync-injected.mjs` (part of the package's `test` script) with a package no one injects. It loops over every folder in `packages/`. | Remove that step from the sheet's `test` script and say so. |
| V2 | `pnpm docs:api:check` with a component that has no docs page (`scripts/generate-api-docs.mjs` walks `packages/`). | Report; do not add a docs page to make it pass. |
| V3 | The grid and `EuiSelectable` render with `validated-form`'s `tests/test-helper.ts`. Core's own helper registers more (`packages/core/tests/test-helper.ts:37-53`, `tests/addon-app-modules.ts`): the `ember-provide-consume-context` initializer and components. | Add only the missing registrations, importing them from their packages as core's `addon-app-modules.ts` does. |
| V4 | `changeset version` with the private package. | Drop `private`, or ask (Q1). |
| V5 | `EuiSelectable`: after opening with a seeded search (`searchProps.defaultValue`), the first match is current and Enter picks it; the changed option passed to `@onChange` keeps its `data` (`-private/selectable-options.ts`, `toggleOptionWithChange` spreads the option); `inputRef` runs once the input exists. From reading `eui-selectable.gts:571-701` this holds, but it was not run. | Make the first option current from the editor (dispatching nothing: keep an index and commit on Enter in the editor's capture listener), still without touching core. |
| V6 | The panel layout is not clipped by the wrapper or the test container, and flips above near the bottom. | Adjust `EditorFrame`; report what clips. |
| V7 | `setCellProps({ title, 'aria-invalid' })` reaches the cell element as attributes. Read in `eui-data-grid/cell.gts:301-312` (`cellPropsAttributes` sets every key except `className`, `style`, `isExpandable`, `data-test-subj`; `undefined` values are skipped), not run. | Report; a grid change is not allowed. |
| V8 | Trusted events for the new editors (11.4). | Report as the spike did for D22. |

## 16. Open questions for the user

| # | Question | Default in this design |
| --- | --- | --- |
| Q1 | Version and release. The siblings share `16.1.4` and are released together. Should the sheet start at `0.1.0` and stay `private` until you decide to publish, or join the shared version? | `0.0.0` → `0.1.0`, `"private": true`. |
| Q2 | The date editor (P6): native `<input type="date">` for Enter/F2/double-click and a text input when typing. The alternative is a text input only (simpler, no browser calendar) or an EUI-styled calendar later through a custom editor. | The hybrid. |
| Q3 | Default date order `dmy` (`19/11/2026`), display `DD/MM/YYYY`, copy as ISO. | As stated. |
| Q4 | Rejections of rows inserted by a paste are shown only when the owner keeps the `tempId` as the record id. Acceptable for v0.1, or should `@onChange` be allowed to return a `tempId → id` map? | Accept the limit. |
| Q5 | Colours are fixed values in v0.1. Use EUI theme tokens (dark mode) now or later? | Later. |
| Q6 | Messages are English by default with `@messages` to override. Should the package ship Spanish messages or read core's `eui-i18n` service? | Override only. |
| Q7 | Space is reserved and does nothing outside checkboxes (P8). Airtable expands the record with Space. Keep it reserved for a future record view? | Yes. |
| Q8 | After picking a select option with Enter, focus moves down (like a text cell); after a mouse pick it stays. | As stated. |
| Q9 | Peer range on core `^16.1.4` (siblings: `^16.0.0`). | `^16.1.4`. |
| Q10 | Bulk resolve on paste and the built-in record, cross-row and async validation hooks are defined (9.2, 9.4) but each will add one optional `EuiSheet` argument when implemented. Until then the owner covers validation through `@cellErrors`, and pasted text in an async field is a rejection. Is that acceptable, or should one of them be in v0.1? | Not in v0.1. |

## 17. Summary

- New `packages/sheet` (`@ember-eui/sheet`), configs copied from `validated-form`, no new third-party dependency; the lockfile gains one importer block, made in scratch and copied back alone.
- `src/core/` is plain TypeScript (an ESLint rule and a test forbid Ember imports): change sets, TSV, five field types, errors. `localRecords` sits outside it.
- A field type is a plain object plus optional `cell` and `editor` components; built-in and app types use the same contract, and editors claim keys with `handlesKey(event)`.
- Invalid text gives no patch: the sheet keeps and shows it as a rejection and reports it in `changeSet.rejected`. Validation errors are derived at render and never block a patch; `@cellErrors` merges last.
- Editors: text input (text, number); `EuiSelectable` in a panel beside the grid (select); native date input, or the text input when typing (date); checkbox toggles with Space or a click.
- `createOnPaste` puts new options in `changeSet.newOptions`; `localRecords({ fields })` applies them.
- Extension contract (section 9): custom cells/editors, record-dependent options and conditional `readOnly`/`required` are implemented; async bulk resolve and validation layers 4–6 are defined only and will each add one optional argument.
- Core must be built in the scratch copy before the sheet's tests. `EuiDataGrid` stays unchanged.
- Delete the spike code from core's tests once the package passes. The package starts private with a `minor` changeset.
- Not run for this design: V1–V8, above all `EuiSelectable`'s seeded search (V5) and trusted events for the new editors (V8).
