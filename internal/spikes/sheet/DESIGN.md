# EuiSheet spike: design

Status: design only, nothing implemented. Written 2026-11-19 against
`master` at `13303391`. Line numbers refer to that commit.

## 1. Goal and hypothesis

Goal: find out how little `EuiDataGrid` has to change for an Airtable-like
editable grid (`EuiSheet`, future `@ember-eui/sheet`) to be built on top of
it, so re-porting upstream EUI stays cheap.

**Hypothesis (H1):** the sheet needs only the grid's existing public API
(`@columns`, `@rowCount`, `@renderCellValue`, `@cellContext`,
`@columnVisibility`, `@registerApi`, `setCellProps`, the `data-gridcell-*`
attributes) plus one marked extension, `cell-api`.

**Stronger variant (H0), found while reading the code:** the sheet may need
no extension at all. Every key, copy and paste event the sheet handles has a
cell as its target, and the cell carries its position in `data-gridcell-*`.
The spike therefore reads the focused cell through one function with two
implementations (`api` and `dom`) and runs the core tests with both.

**What disproves H1:** any required behaviour in section 7 that can only pass
by adding logic to a ported grid file beyond the `cell-api` lines in
section 4. The likely candidates are listed in section 6 (R2, R5, R9, R12).
Each failure must be reported as "needs hook X in file Y", not worked around
inside the grid.

Out of scope: undo, formulas, column types other than text, fill handle,
mouse drag selection, sorting/filtering/pagination, fullscreen, row
insertion UI, IME input.

## 2. Findings in the grid code that shape the design

| # | Finding | Where |
| --- | --- | --- |
| F1 | `focusedCell` is `[colIndex, visibleRowIndex]`; the header row is `-1`. The API's `setFocusedCell` takes the **data** `rowIndex` and maps it with `findVisibleRowIndex`. | `eui-data-grid.gts:726`, `:1120-1126`, `utils/data-grid/types.ts:373-379` |
| F2 | `api.setFocusedCell` is forced (re-focuses a cell that is already the grid's focused cell) and throws when `rowIndex >= dataRowCount`. | `eui-data-grid.gts:1082-1095`, `:1120-1126` |
| F3 | Grid keys: `onContentKeyDown` on the `role=grid` element (bubble phase) calls `handleGridKeyDown`, which ignores `shiftKey` and returns early when `document.activeElement` is outside the grid content. | `eui-data-grid.gts:1037-1052`, `utils/data-grid/focus.ts:36-54` |
| F4 | Cell keys: `onKeyDown` on the cell (bubble phase) opens the popover on Enter/F2 when `isExpandable`. `onKeyUp` only acts for non-expandable cells with interactive children. | `eui-data-grid/cell.gts:536-563`, `:573-586` |
| F5 | Copy: two **document-level, bubble-phase** listeners. `copyFocusedDataGridCell` returns when `event.defaultPrevented`; `onTabularCopy` does **not** check it. | `eui-data-grid.gts:715-718`, `utils/retain-document-listener.ts:14`, `utils/data-grid/focus.ts:166-181`, `utils/data-grid/tabular-copy.ts:47-67` |
| F6 | A cell calls `cell.focus()` when the grid's focused cell changes to it (`onFocusUpdate` → `takeFocus`) **and whenever the grid-focused cell mounts** (`setupCell` → `takeFocus(true)`), unless focus is inside `.euiPopover__panel`. | `eui-data-grid/cell.gts:462-507` |
| F7 | The cell updates the grid's focus from a capture-phase `focus` listener on the cell element itself. | `eui-data-grid/cell.gts:519-521` |
| F8 | `setCellProps` state lives in the cell component, keyed `columnId:rowIndex`, applied one `afterRender` after the renderer calls it; "Renderers may call this during render". Rows are keyed by visible row index, so a scrolled-away cell is destroyed and its state with it. | `eui-data-grid/cell.gts:273-298`, `eui-data-grid/body.gts:943` |
| F9 | Interactive elements inside cells get `tabindex=-1` (`disableInteractives` on mount, `preventTabbing` from a `MutationObserver` on the content element). Both only look inside the grid content. | `eui-data-grid/cell.gts:508-518`, `eui-data-grid.gts:1018-1027`, `utils/data-grid/focus.ts:113-160` |
| F10 | `eui-data-grid-api-test.gts:301-304` asserts the exact `Object.keys(api)`. It is the only such assertion in `tests/`. | `tests/integration/components/eui-data-grid-api-test.gts` |
| F11 | `grid.columns` are the **visible** columns in display order; `colIndex` also counts leading control columns. | `eui-data-grid.gts:457-473`, `eui-data-grid/cell.gts:207-210` |
| F12 | Only `components/`, `helpers/`, `modifiers/` and `services/` get `package.json` app-js entries; `utils/` does not. | `packages/core/rollup.config.mjs:99-104` |

## 3. Where the code lives

No new package, no workspace or install change.

| Path (under `packages/core/`) | Responsibility | ~Lines |
| --- | --- | --- |
| `tests/spikes/sheet/eui-sheet.gts` | `EuiSheet` component: state, capture listeners, grid wiring, overlay. | 220 |
| `tests/spikes/sheet/sheet-editor.gts` | Overlay editor: one `<input>`, focuses itself on insert, reports `@onInput` / `@onBlur`. | 40 |
| `tests/spikes/sheet/sheet-cell-value.gts` | `@renderCellValue` component: shows the value, sets the selection class with `setCellProps`. | 35 |
| `tests/spikes/sheet/change-set.ts` | Pure: types, TSV parse/serialize, change-set builders. | 110 |
| `tests/spikes/sheet/local-records.ts` | `localRecords()`: tracked array that applies change sets. | 40 |
| `tests/integration/spikes/eui-sheet-spike-test.gts` | Integration tests (section 7). Module `Integration \| Spike \| EuiSheet`. | 330 |
| `tests/unit/spikes/sheet-change-set-test.ts` | Unit tests of `change-set.ts` and `local-records.ts`. Module `Unit \| Spike \| EuiSheet change sets`. | 90 |
| `src/utils/data-grid/cell-api.ts` | The `cell-api` extension logic (section 4). | 25 |
| `tests/integration/components/eui-data-grid-cell-api-test.gts` | Contract test of the hook. Stays if the hook stays. | 50 |
| `internal/spikes/sheet/RESULTS.md` | Written by the implementer at the end: answers to section 9. | — |

Why `tests/`:

- `tests/index.html` loads `./**/*.{js,ts,gjs,gts}` eagerly, so files under
  `tests/spikes/` and `tests/integration/spikes/` are built and run with no
  config change.
- Nothing in `tests/` is published (`files` in `package.json`) or re-exported.
- Spike code imports the grid as `#src/components/eui-data-grid.gts`, like
  the existing tests.

Consequences to know:

- `tsconfig.json` includes only `src/`, so `ember-tsc --noEmit` does **not**
  type-check the spike files. ESLint (`tsconfig.eslint.json`) does cover
  `tests/`.
- The hook file is in `src/utils/data-grid/` and not `src/components/eui-data-grid/`
  so the build adds no `package.json` app-js entry (F12).

## 4. The `cell-api` extension

### 4.1 New file `src/utils/data-grid/cell-api.ts`

```ts
/**
 * Ember EUI extension (cell-api), not in upstream EUI: read access to the
 * grid's focused cell for layers built on top of the grid.
 * See internal/spikes/eui-latest/data-grid-extensions.md.
 */
import type {
  EuiDataGridFocusedCell,
  EuiDataGridFocusedCellLocation
} from './types.ts';

interface CellApiGrid {
  focusedCell: EuiDataGridFocusedCell | undefined;
  getCorrectRowIndex(visibleRowIndex: number): number;
}

export function cellApi(grid: CellApiGrid): {
  getFocusedCell: () => EuiDataGridFocusedCellLocation | undefined;
} {
  return {
    getFocusedCell() {
      const focused = grid.focusedCell;
      if (!focused) return undefined;
      const [colIndex, visibleRowIndex] = focused;
      return {
        colIndex,
        visibleRowIndex,
        rowIndex: visibleRowIndex < 0 ? -1 : grid.getCorrectRowIndex(visibleRowIndex)
      };
    }
  };
}
```

Semantics:

- `{ rowIndex, colIndex }` round-trips through `api.setFocusedCell` (data row
  index, F1). `visibleRowIndex` is the page-relative index the cell markup
  uses.
- Header row: `rowIndex` and `visibleRowIndex` are `-1`.
- Footer row: not distinguished (`visibleRowIndex === visibleRowCount`); the
  spike has no footer.
- It is the grid's **last focused** cell: it stays set after DOM focus leaves
  the grid, and is `undefined` until a cell was focused.

### 4.2 Marked lines in ported files (3 lines, 2 files)

`src/components/eui-data-grid.gts`:

1. After line 48 (the row-tree imports):

   ```ts
   import { cellApi } from '../utils/data-grid/cell-api.ts'; // ember-eui extension (cell-api): focused cell getter
   ```

2. In the `api` literal, after `scrollToItem` (line 1134):

   ```ts
       scrollToItem: (params) => this.body?.scrollToItem?.(params),
       ...cellApi(this) // ember-eui extension (cell-api): getFocusedCell
   ```

   `cellApi(this)` runs in the field initializer; it only closes over the
   grid and reads `focusedCell` when called. The row-tree merge in the
   `registerApi` modifier (`{ ...this.api, ...this.rowTreeModel.api }`,
   line 1157) keeps the method.

`src/utils/data-grid/types.ts`:

3. In `EuiDataGridRefProps`, after `collapseAll` (line 423):

   ```ts
     /** Ember EUI extension (cell-api): the grid's last focused cell, if any. */
     getFocusedCell?: () => EuiDataGridFocusedCellLocation | undefined; // ember-eui extension (cell-api)
   ```

   and, appended at the end of the file (own block, like the row-tree types):

   ```ts
   /* Focused cell getter (Ember EUI extension cell-api, not in upstream EUI) */
   export interface EuiDataGridFocusedCellLocation extends EuiDataGridCellLocationProps {
     /** Page-relative row index used by the cell markup; -1 for the header row. */
     visibleRowIndex: number;
   }
   ```

### 4.3 Conflict with the convention (must be reported)

`eui-data-grid-api-test.gts:301-304` lists the API keys, so adding the method
breaks a ported test, and the convention says those tests "must keep passing
unchanged". The spike changes that one expectation and marks it:

```ts
        // ember-eui extension (cell-api): getFocusedCell
        ['closeCellPopover', 'getFocusedCell', 'openCellPopover', 'scrollTo', 'scrollToItem', 'setFocusedCell', 'setIsFullScreen']
```

This cost goes into `RESULTS.md`. If H0 holds (section 1), the cheaper
answer is to drop the hook and this edit.

### 4.4 `@onFocusedCellChange`: designed, NOT implemented unless needed

The sheet learns about focus moves from a `focusin` listener on its wrapper
(section 5.4). Only if that proves insufficient, add:

- `Args` in `eui-data-grid.gts` (after `registerApi`, line 294):
  `onFocusedCellChange?: (cell: EuiDataGridFocusedCellLocation) => void; // ember-eui extension (cell-api)`
- In `setFocusedCell`, after line 758 (`this.body?.onFocusedCellChange(...)`):
  `notifyFocusedCellChange(this); // ember-eui extension (cell-api): @onFocusedCellChange`
- `notifyFocusedCellChange(grid)` in `cell-api.ts` calls
  `grid.args.onFocusedCellChange?.(cellApi(grid).getFocusedCell()!)`.

Adding it means the answer to "is one hook enough?" is "one extension, two
touchpoints in `eui-data-grid.gts`".

### 4.5 Section to add to `internal/spikes/eui-latest/data-grid-extensions.md`

Add after the `row-tree` section, only if the hook survives the spike:

```md
## `cell-api`: focused cell getter on the imperative API

For layers built on top of the grid (EuiSheet). Design and results:
`internal/spikes/sheet/DESIGN.md`, `RESULTS.md`.

### Extension files (own code, no upstream counterpart)

| File | Contents |
| --- | --- |
| `src/utils/data-grid/cell-api.ts` | `cellApi(grid)`: `getFocusedCell()` → `{ rowIndex, colIndex, visibleRowIndex }` or `undefined`. |
| `src/utils/data-grid/types.ts` (appended block) | `EuiDataGridFocusedCellLocation`. |

### Touchpoints in ported upstream files

3 marked lines in 2 files.

| File | Symbol | Hook | Delegates to |
| --- | --- | --- | --- |
| `eui-data-grid.gts` | imports | `cellApi` | cell-api.ts |
| `eui-data-grid.gts` | `api` | `...cellApi(this)` (last entry) | `cellApi` |
| `utils/data-grid/types.ts` | `EuiDataGridRefProps` | `getFocusedCell?` | — (type) |

A ported test changed: `eui-data-grid-api-test.gts` lists `getFocusedCell`
among the API keys (marked).

### Tests guarding the contract

| File | Covers |
| --- | --- |
| `tests/integration/components/eui-data-grid-cell-api-test.gts` | `undefined` before focus, data cell, header row (-1), still set after blur, row index with `@sorting`. |

### Re-porting upstream

Re-apply the three marked lines. If upstream renames `focusedCell` or
`getCorrectRowIndex`, adapt `cell-api.ts`, not the hook.
```

## 5. Component and module design

### 5.1 Coordinates (decision)

A sheet position is `{ row, col }`: `row` is the visible row index, `col` the
grid `colIndex`.

- The spike passes **no** `@sorting`, `@inMemory`, `@pagination`, `@rowTree`
  or control columns, so `row` is also the index into `@records` and `col`
  the index into the visible fields. The sheet asserts this in development
  (`data-gridcell-row-index === data-gridcell-visible-row-index` on the
  event's cell).
- The sheet owns column order: it passes a controlled `@columnVisibility`
  built from its own tracked `visibleFieldIds`, so `col → field` works for
  columns that are not rendered (columns are virtualized too).
- A range can extend past the rendered window, so positions must never be
  read from the DOM for cells other than the event's target.
- Product direction this implies (for the plan doc): the sheet sorts and
  filters `@records` itself and gives the grid the ordered array. If the
  grid's own sorting were used instead, the sheet would need
  `getCorrectRowIndex` exposed for arbitrary rows: a second API method.

### 5.2 `change-set.ts` (pure)

```ts
export type RecordId = string | number;
export interface EuiSheetField {
  id: string;
  label?: string;
  readOnly?: boolean;
  isExpandable?: boolean;            // spike knob, default false (R4)
  format?: (value: unknown) => string;   // default: value == null ? '' : String(value)
  parse?: (text: string) => unknown;     // default: text
}
export interface CellPatch { recordId: RecordId; fieldId: string; from: unknown; to: unknown }
export interface RecordInsert { tempId: string; index: number; values: Record<string, unknown> }
export interface ChangeSet {
  source: 'edit' | 'paste' | 'clear';
  patches: CellPatch[];
  inserts: RecordInsert[];
}
export interface Pos { row: number; col: number }
export interface Range { top: number; left: number; bottom: number; right: number } // inclusive
export interface SheetContext<T> {
  records: readonly T[];
  fields: readonly EuiSheetField[];      // visible fields, display order
  getRecordId: (record: T) => RecordId;
}
```

| Function | Behaviour |
| --- | --- |
| `toRange(anchor, head): Range` | Normalizes two positions. |
| `parseTsv(text): string[][]` | Splits on `\r?\n`, drops one trailing empty line, splits on `\t`. No quoted cells (Excel quotes cells holding newlines): noted limitation. |
| `toTsv(matrix): string` | Joins with `\t` and `\n`, no trailing newline. |
| `rangeMatrix(ctx, range): string[][]` | Formatted values of the range, clamped to existing rows and fields. |
| `commitPatch(ctx, pos, text): ChangeSet \| null` | One patch; `null` when the field is read-only or `parse(text)` equals the current value (`Object.is`). |
| `clearRange(ctx, range): ChangeSet \| null` | A patch `to: parse('')` per non-read-only cell whose value differs; `null` when empty. |
| `pasteMatrix(ctx, anchor, matrix): ChangeSet \| null` | Cell `[i][j]` goes to `{ row: anchor.row + i, col: anchor.col + j }`. Columns past the last field are dropped. Read-only fields are skipped. Rows `< records.length` give patches (unchanged values omitted). Rows `>= records.length` give one insert each: `tempId: 'new-' + n`, `index: records.length + k`, `values` of the pasted fields only. `null` when nothing results. |

Patches carry `from`, so undo is an inversion of patches plus removal of
inserts. The spike does not implement it.

### 5.3 `local-records.ts`

```ts
export function localRecords<T extends object>(
  initial: T[],
  options: {
    getRecordId: (record: T) => RecordId;
    createRecord?: (values: Record<string, unknown>, tempId: string) => T; // default { id: tempId, ...values }
  }
): { readonly records: T[]; apply(changeSet: ChangeSet): void; readonly log: ChangeSet[] };
```

A small class with `@tracked records`. `apply` builds a new array: patched
records are replaced by `{ ...record, [fieldId]: to }` (matched by id through
a `Map`), inserts are appended in `index` order. `log` keeps every applied
change set for the tests.

### 5.4 `EuiSheet` (`eui-sheet.gts`)

Args:

| Arg | Type | Notes |
| --- | --- | --- |
| `@records` | `T[]` | Controlled. |
| `@fields` | `EuiSheetField[]` | |
| `@getRecordId` | `(record: T) => RecordId` | |
| `@onChange` | `(changeSet: ChangeSet) => void` | The only way data changes. |
| `@height` | `number \| string` | Passed to the grid; needed for virtualization tests. |
| `@cursorSource` | `'api' \| 'dom'` | Spike only, default `'api'` (section 1, H0). |

State (all `@tracked` unless noted):

| Field | Type | Meaning |
| --- | --- | --- |
| `anchor`, `head` | `Pos \| null` | Selection corners. `head` is where DOM focus is. |
| `editing` | `{ pos: Pos; rect: { top, left, width, height } } \| null` | Cell being edited and the overlay box, relative to the wrapper. |
| `draft` | `string` | Editor text. |
| `visibleFieldIds` | `string[]` | Controlled column order. |
| `api` (plain) | `EuiDataGridRefProps \| null` | From `@registerApi`. |
| `domCursor` (plain) | `Pos \| null` | Last data cell seen by `focusin` (the `dom` cursor source). |
| `extending` (plain) | `boolean` | The next focus move extends the range. |

Derived: `columns` (`{ id, displayAsText: label ?? id, isExpandable: field.isExpandable ?? false }`),
`columnVisibility`, `range` (`toRange(anchor, head)` or `null`), `context`
(`SheetContext`), `cellContext` (`{ sheet: this }`, a stable object).

Methods the renderer calls: `isSelected(row, col)`, `displayValue(row, fieldId)`.

Template:

```gts
<div
  class="euiSheetSpike"
  style="position:relative"
  data-test-subj="euiSheet"
  {{on "keydown" this.onKeyDown capture=true}}
  {{on "copy" this.onCopy capture=true}}
  {{on "paste" this.onPaste capture=true}}
  {{on "scroll" this.onScroll capture=true}}
  {{on "mousedown" this.onMouseDown capture=true}}
  {{on "focusin" this.onFocusIn}}
  {{on "dblclick" this.onDoubleClick}}
>
  <EuiDataGrid
    aria-label="Sheet"
    @columns={{this.columns}}
    @columnVisibility={{this.columnVisibility}}
    @rowCount={{@records.length}}
    @renderCellValue={{SheetCellValue}}
    @cellContext={{this.cellContext}}
    @registerApi={{this.registerApi}}
    @toolbarVisibility={{false}}
    @height={{@height}}
  />
  {{#if this.editing}}
    <SheetEditor
      @rect={{this.editing.rect}}
      @value={{this.draft}}
      @onInput={{this.setDraft}}
      @onBlur={{this.onEditorBlur}}
    />
  {{/if}}
</div>
```

The editor is a **sibling of the grid inside the wrapper**, not a portal
under `<body>`. Reasons:

- It is outside the grid's content element, so F9 never touches it and its
  key events never reach the grid's handlers (F3, F4).
- Its events still pass through the wrapper, so one capture listener serves
  both modes. A portal under `<body>` would need its own key handling.
- It must not carry the class `euiPopover__panel`: `takeFocus` and
  `onContentKeyDown` special-case that class.

Cost: it sits outside the grid's fullscreen focus trap and can be clipped by
an ancestor with `overflow: hidden`. The spike hides the toolbar, so
fullscreen is unreachable. Listed as an open question (section 9).

Helper used by every listener:

```ts
// The data cell an event belongs to, or null (header, footer, control column, toolbar, editor).
dataCell(target: EventTarget | null): HTMLElement | null
//   = (target as Element).closest('[role=gridcell][data-gridcell-visible-row-index]')
//   rejected when it has .euiDataGridFooterCell or .euiDataGridRowCell--controlColumn
// The focused position: 'api' → api.getFocusedCell() mapped to { row: visibleRowIndex, col: colIndex }
//                       'dom' → dataset of dataCell(event.target)
cursor(event: Event): Pos | null
```

Header cells use `role=columnheader`, so the selector excludes them.

Focus tracking:

- `onFocusIn`: when `dataCell(event.target)` exists, `pos = cursor(event)`.
  If `pos` equals `domCursor` (the last position seen), do nothing: the
  grid re-focuses the same cell when it re-mounts after a scroll (F6) and
  after `cancel()`, and that must not collapse a range. Otherwise, if
  `extending`, set `head = pos`, else `anchor = head = pos`; store
  `domCursor = pos`. It must be `focusin` (bubble), not a capture `focus`
  listener: the cell updates the grid's `focusedCell` from its own `focus`
  listener (F7), and `focusin` is dispatched after `focus`.
- `onMouseDown`: `extending = event.shiftKey` (Shift+click extends for free).
- `onDoubleClick`: on a data cell, `startEdit(pos, currentText)`.

### 5.5 Key and clipboard controller

Mode is `edit` when `editing` is set and the event target is inside the
editor, `nav` when the target **is** a data cell (`event.target === dataCell`,
so interactive children of a cell keep their keys). Anything else: ignore.
Every `keydown` first sets `extending = event.shiftKey && key is an arrow`.
"Stop" means `preventDefault()` and `stopPropagation()`.

| Mode | Key | Condition | Action | Stop |
| --- | --- | --- | --- | --- |
| nav | Enter, F2 | field not read-only | `startEdit(pos, displayValue)` | yes (keeps F4's popover closed) |
| nav | printable (`key.length === 1`) | no Ctrl/Meta/Alt, not `isComposing`, field not read-only | `startEdit(pos, event.key)` | yes (`preventDefault` stops the character being typed twice) |
| nav | Delete, Backspace | range exists | `emit(clearRange(ctx, range))` | yes |
| nav | Shift+Arrow | — | none: the grid moves focus (F3), `onFocusIn` moves `head` only | no |
| nav | Arrow, Home, End, PageUp/Down | — | none: the grid moves focus, `onFocusIn` collapses the selection | no |
| nav | Tab, Escape, Ctrl/Meta combos | — | none (upstream behaviour) | no |
| edit | Enter | — | `commit({ move: [1, 0] })` | yes |
| edit | Tab / Shift+Tab | — | `commit({ move: [0, 1] })` / `[0, -1]` | yes |
| edit | Escape | — | `cancel()` | yes |
| edit | anything else | — | none: the input handles it | no |
| nav | `copy` event | range exists | `clipboardData.setData('text/plain', toTsv(rangeMatrix(ctx, range)))` | yes (`stopPropagation` is required: F5) |
| nav | `paste` event | `clipboardData` has `text/plain` | `emit(pasteMatrix(ctx, topLeft(range), parseTsv(text)))`, then `head = bottom-right of the pasted block` (columns clamped) | yes |
| edit | `copy` / `paste` | — | none: native input behaviour | no |

Shift+Arrow consequence: DOM focus (and the focus ring) is on the moving end
of the range, the anchor stays. Excel keeps the active cell on the anchor.
Letting the grid move focus gives scrolling into view and virtualization for
free; changing it later is a sheet-only change.

Edit lifecycle:

- `startEdit(pos, text)`: `rect` = the cell's `getBoundingClientRect()` minus
  the wrapper's; `draft = text`; `editing = { pos, rect }`. `SheetEditor`
  focuses its input on insert and puts the caret at the end.
- `commit({ move, refocus = true })`:
  1. `const { pos } = this.editing; this.editing = null;` **first**. This is
     the re-entrancy guard: the blur caused by step 3 or by the input
     leaving the DOM finds `editing === null` and returns.
  2. `emit(commitPatch(ctx, pos, draft))` (no call when `null`).
  3. If `refocus`: target = `pos + move`, clamped to
     `[0, records.length - 1]` and `[0, fields.length - 1]`, then
     `api.setFocusedCell({ rowIndex: target.row, colIndex: target.col })`.
     Synchronous is safe: the target row already exists (F2).
- `cancel()`: `editing = null`, then
  `api.setFocusedCell({ rowIndex: pos.row, colIndex: pos.col })`.
- `onEditorBlur`: if `editing`, `commit({ refocus: false })`. Not refocusing
  matters: when the user clicks another cell, that cell must keep focus.
- `onScroll` (capture; the grid's scroller is a descendant): if `editing`,
  `commit({ refocus: false })`. This removes the overlay before a stale
  position shows, and before F6 can pull focus (R2).
- `emit(changeSet)`: `if (changeSet) this.args.onChange(changeSet)`.

After a paste that inserts rows the sheet does **not** call
`api.setFocusedCell`: the new rows exist only after the next render and the
call would throw (F2). Focus stays on the anchor cell.

### 5.6 `SheetCellValue` (`sheet-cell-value.gts`)

Receives the grid's renderer args. `sheet = this.args.cellContext.sheet`.

```gts
get selection(): string {
  const selected = this.sheet.isSelected(this.args.rowIndex, this.args.colIndex);
  this.args.setCellProps(
    selected ? { className: 'euiSheetSpike__cell--selected', 'aria-selected': 'true' } : {}
  );
  return '';
}
<template>{{this.selection}}{{this.text}}</template>
```

- The getter reads the sheet's tracked `anchor`/`head`, so it re-runs on
  every selection change and when the cell is re-created after scrolling.
- `setCellProps` only schedules (F8), so calling it from a getter is allowed.
  `{}` when unselected clears the class.
- The class appears one `afterRender` later: tests `await settled()`.
- The style is a `<style>` element in `eui-sheet.gts`
  (`.euiSheetSpike__cell--selected { background: rgba(0, 119, 204, 0.12); }`).

### 5.7 `SheetEditor` (`sheet-editor.gts`)

```gts
<div class="euiSheetSpike__editor" data-test-subj="euiSheetEditor" style={{this.style}}>
  <input
    aria-label="Edit cell"
    value={{@value}}
    {{on "input" this.onInput}}
    {{on "blur" @onBlur}}
    {{this.focusOnInsert}}
  />
</div>
```

`style`: `position:absolute; z-index:2; top/left/width/height` from `@rect`.
The input fills the box. No EUI form components: the spike is about focus.

## 6. Risks: what could break the hypothesis

| # | Risk | Expected behaviour | How the design avoids it | Proof |
| --- | --- | --- | --- | --- |
| R1 | The grid sets `tabindex=-1` on the editor (F9). | Editor stays tabbable and focused. | Editor is outside the grid content. | T11 |
| R2 | The grid pulls focus back while editing: the focused cell re-mounts after a scroll (F6). | No focus fight; the edit is saved. | Scroll while editing commits without refocus; blur commits. | T10 |
| R3 | Blur commit and `setFocusedCell` trigger each other (double commit, or focus stolen from a clicked cell). | One change set; the clicked cell keeps focus. | `editing = null` before anything else; blur commits with `refocus: false`. | T1 (one change set), T9 |
| R4 | Enter/F2 opens the cell popover (F4). | Popover never opens from a key the sheet handles. | Capture listener stops propagation before the cell's handler. Columns are also `isExpandable: false` by default to hide the expand button, but the test turns that off. | T8 (fields with `isExpandable: true`) |
| R5 | The grid's document copy handlers overwrite the clipboard (F5). | Clipboard holds the range as TSV. | `stopPropagation` on the wrapper; both grid handlers are bubble-phase on `document`. | T5 |
| R6 | Arrow keys in the editor move grid focus (F3). | Caret moves, grid focus does not. | Editor events do not pass through the grid; `handleGridKeyDown` also returns when focus is outside. | T12 |
| R7 | Escape in the editor reaches other handlers (grid fullscreen exit, an enclosing modal). | Only the edit is cancelled. | Stop in capture phase. Fullscreen is unreachable in the spike. | T2 |
| R8 | The selection is lost when cells are re-created: the class (F8), or the range itself when the re-mounted focused cell takes focus again (F6). | Range and class are back after scrolling away and back, one render later. | The renderer calls `setCellProps` on every render from sheet state; `onFocusIn` ignores a focus on the position it already has. | T7 |
| R9 | `setCellProps` on every rendered cell is slow for large ranges. | Extending a range over ~200 rendered cells stays under a frame or two. | Not avoided: measured and logged, not asserted. If slow, the fallback is toggling the class on the cell element from the sheet (still no grid change). | T7 logs the time |
| R10 | Focus restore timing: `setFocusedCell` runs before the target cell exists (row below the rendered window, or inserted rows). | Focus lands on the target after the grid scrolls. | Target is clamped to existing rows; a cell outside the window focuses itself on mount (F6). No call after inserts. | T1, T6, T15 |
| R11 | `focusin` runs before the grid updated `focusedCell` (F7), so `getFocusedCell` is one step behind. | `cursor()` returns the cell that just got focus, with both sources. | `focusin`, not capture `focus`. | T4, T5 run with `api` and `dom` |
| R12 | Trusted-event behaviour that synthetic tests cannot show: `paste`/`copy` firing on a non-editable focused cell, the typed character appearing twice, IME. | `paste` and `copy` fire on the focused cell in Chrome, Firefox and Safari; no duplicate character. IME does not work with `event.key` seeding. | `preventDefault` on the opening key. IME is a known limit of the spike; the product answer is an always-mounted hidden input, still outside the grid. | Manual check, section 8.4 |
| R13 | Header cells, footer, control columns, toolbar inputs get sheet behaviour. | Their own keys keep working. | `dataCell()` gating; `event.target === dataCell`. | T13 |
| R14 | The API key list test (F10). | — | Cannot be avoided with the hook; section 4.3. | `?filter=EuiDataGrid` run |
| R15 | Sorting or pagination make visible and data row indexes differ (F1). | — | Out of scope: the sheet owns order (section 5.1). | Reported, not tested |

## 7. Test plan

Style: as `tests/integration/components/eui-data-grid-keyboard-test.gts`
(`.gts`, `setupRenderingTest`, `render(<template>…</template>)`,
`triggerKeyEvent`, `waitUntil`, `settled`, `assert.dom`).

### 7.1 Shared fixture and helpers (top of `eui-sheet-spike-test.gts`)

```ts
const FIELDS = [{ id: 'name' }, { id: 'city' }, { id: 'qty' }];
const people = () => [0, 1, 2, 3, 4].map((i) => ({ id: `r${i}`, name: `name${i}`, city: `city${i}`, qty: `${i}` }));
const getId = (record: { id: string }) => record.id;

function cell(row: number, col: number): HTMLElement   // as in the keyboard test
function text(row: number, col: number): string        // cell(...).querySelector('[data-datagrid-cellcontent]').textContent.trim()
function editor(): HTMLInputElement | null             // '[data-test-subj=euiSheetEditor] input'
function selected(): string[]                          // 'row:col' of every .euiSheetSpike__cell--selected, sorted
async function press(key: string, modifiers = {})      // triggerKeyEvent(document.activeElement, 'keydown', key, modifiers); named keys only
async function type(char: string)                      // triggerKeyEvent(document.activeElement, 'keydown', char.toUpperCase().charCodeAt(0))
async function focusCell(row: number, col: number)     // await focus(cell(row, col)); await settled()
async function clipboard(type: 'copy' | 'paste', text = '') {
  const clipboardData = new DataTransfer();
  if (text) clipboardData.setData('text/plain', text);
  const event = new ClipboardEvent(type, { clipboardData, bubbles: true, cancelable: true });
  document.activeElement!.dispatchEvent(event);
  await settled();
  return { text: clipboardData.getData('text/plain'), prevented: event.defaultPrevented };
}
async function scrollTo(top: number)                   // as in eui-data-grid-virtualization-test.gts:37-42
```

`new ClipboardEvent(type, { clipboardData: new DataTransfer(), … })` is the
pattern already used in `eui-data-grid-api-test.gts:738-741`.

`type()` exists because `triggerKeyEvent` throws on a string key that starts
with a lowercase character (`@ember/test-helpers`
`dist/dom/trigger-key-event.js:159`). With a numeric key code and no Shift it
builds the event with the lowercase `key` (`88` → `'x'`), which is what a
real key press gives. It does not type into the input: the sheet seeds the
draft from `event.key`.

Each test renders:

```gts
const store = localRecords(people(), { getRecordId: getId });
<div style="width:600px">
  <EuiSheet @records={{store.records}} @fields={{FIELDS}} @getRecordId={{getId}}
            @onChange={{store.apply}} @cursorSource={{source}} />
</div>
```

T1 to T6 are declared inside `for (const source of ['api', 'dom'] as const)`
with the source in the test name. The rest run with `'api'` only.

### 7.2 Integration cases

| # | Name | Actions | Assertions |
| --- | --- | --- | --- |
| T1 | type-to-edit, Enter saves and moves down | `focusCell(1, 0)`; `type('x')`; `fillIn(editor(), 'xy')`; `press('Enter')` | After `type('x')`: editor exists, value `x`, `document.activeElement === editor()`. After Enter: no editor; `text(1, 0) === 'xy'`; `store.log` has exactly one change set `{ source: 'edit', patches: [{ recordId: 'r1', fieldId: 'name', from: 'name1', to: 'xy' }], inserts: [] }`; `waitUntil` focus is `cell(2, 0)`; `selected()` is `['2:0']`. |
| T2 | Enter and F2 edit the current value, Esc cancels | `focusCell(0, 1)`; `press('Enter')`; `fillIn(editor(), 'zzz')`; `press('Escape')`; then `press('F2')`, `press('Escape')` | Editor value is `city0` on open; after Esc: no editor, `text(0, 1) === 'city0'`, `store.log.length === 0`, focus is `cell(0, 1)` with `tabindex="0"`. The Escape `keydown` does not reach a listener added on `document` by the test (R7). |
| T3 | Tab saves and moves right, Shift+Tab left, clamps | `focusCell(0, 1)`; `type('a')`; `press('Tab')`; `type('b')`; `press('Tab')`; `type('c')`; `press('Tab')`; `type('d')`; `press('Tab', { shiftKey: true })` | Focus after each: `cell(0, 2)`, `cell(0, 2)` (last column), `cell(0, 2)`, `cell(0, 1)`. Texts: `(0,1)` = `a`, `(0,2)` = `d`. Four change sets. |
| T4 | Shift+arrows select a range, Delete clears it | `focusCell(1, 0)`; `press('ArrowDown', { shiftKey: true })`; `press('ArrowRight', { shiftKey: true })`; `press('Delete')` | Before Delete: `selected()` is `['1:0', '1:1', '2:0', '2:1']`, focus is `cell(2, 1)`. After: the four texts are `''`, one change set `source: 'clear'` with 4 patches (each `from` the old value, `to: ''`), `(3, 0)` unchanged. Then `press('ArrowDown')`: `selected()` is `['3:1']`. |
| T5 | copy gives the range as TSV | Select `(1,0)`–`(2,1)` as in T4; `clipboard('copy')`. Second part: select the cell content text with a `Range` (as `eui-data-grid-api-test.gts:744-750`), `clipboard('copy')` again. | `text === 'name1\tcity1\nname2\tcity2'`, `prevented === true`, both times (the grid's `onTabularCopy` did not overwrite it). |
| T6 | paste a 2×3 block at the last row inserts a row | `focusCell(4, 0)`; `clipboard('paste', 'a\tb\tc\r\nd\te\tf\r\n')` | `prevented`; one change set `source: 'paste'`, 3 patches on `r4` (`a`, `b`, `c`), 1 insert `{ index: 5, values: { name: 'd', city: 'e', qty: 'f' } }`; after `settled()` the grid has `aria-rowcount="6"`, row 5 texts are `d`, `e`, `f`; `selected()` covers rows 4–5, cols 0–2; focus still `cell(4, 0)`. Second part: `focusCell(0, 1)`, paste `'p\tq\tr'`: 2 patches (`city`, `qty`), nothing for `r`. |
| T7 | the selection class survives virtualization | 200 records, `@height={{300}}`. `focusCell(2, 0)`; Shift+ArrowDown ×2, Shift+ArrowRight; then `press('Control')` (a key that moves nothing, so `extending` is false again). `rowHeight = el('.euiDataGridRow').offsetHeight`; `scrollTo(rowHeight * 100)`; `scrollTo(0)`; `settled()`. | Before: 6 selected cells. While scrolled: `document.querySelector('[data-gridcell-visible-row-index="2"]')` is `null` (the `cell()` helper throws, do not use it here) and `selected()` is empty. After: `selected()` is the same 6 cells, although the focused cell `(4, 1)` re-mounted and took focus again. Also log (`console.info`) the ms between a Shift+ArrowDown and `settled()` (R9). |
| T8 | the grid's Enter/F2 popover stays closed | Fields with `isExpandable: true`. `focusCell(1, 1)`; `press('Enter')`; `press('Escape')`; `press('F2')` | After Enter and after F2: editor exists; `[data-test-subj=euiDataGridExpansionPopover]` does not exist in `document.body`; `cell(1, 1)` lacks `euiDataGridRowCell--open`. (That Enter opens the popover without the sheet is already proven by `eui-data-grid-keyboard-test.gts:94`.) |
| T9 | clicking another cell commits and does not steal focus | `focusCell(0, 0)`; `type('q')`; `fillIn(editor(), 'q1')`; `click(cell(3, 2))` | No editor; `text(0, 0) === 'q1'`; exactly one change set; focus is `cell(3, 2)` after `settled()`; `selected()` is `['3:2']`. |
| T10 | scrolling while editing commits without a focus fight | 200 records, `@height={{300}}`. `focusCell(1, 0)`; `type('k')`; `scrollTo(rowHeight * 100)`; `scrollTo(0)` | After the first scroll: no editor, one change set (`to: 'k'`). After scrolling back: `text(1, 0) === 'k'`, no second change set, no error. |
| T11 | the editor is outside the grid and tabbable | `focusCell(0, 0)`; `press('Enter')`; `settled()` | `el('.euiDataGrid').contains(editor())` is false; `el('[data-test-subj=euiSheet]').contains(editor())` is true; the input has no `tabindex="-1"` and no `data-euigrid-tab-managed`; it is `document.activeElement`; its box matches `cell(0, 0).getBoundingClientRect()` within 1px. |
| T12 | arrows while editing do not move grid focus | `focusCell(1, 1)`; `press('Enter')`; `press('ArrowDown')`; `press('ArrowRight')` | Editor still focused; `[role=gridcell][tabindex="0"]` is still `cell(1, 1)`; `store.log` empty. |
| T13 | header cells keep their keys | Focus the header (`[role=columnheader][data-gridcell-column-index="0"]`); `type('x')`; `press('Delete')`; `clipboard('paste', 'a')` | No editor, `store.log` empty, `paste` not prevented. |
| T14 | read-only fields | `FIELDS` with `{ id: 'city', readOnly: true }`. `focusCell(0, 1)`; `type('x')`; `press('Enter')`; `press('Delete')`; then `focusCell(0, 0)`, paste `'a\tb\tc'` | No editor; no clear; the paste gives 2 patches (`name`, `qty`). |
| T15 | Enter on the last row keeps focus there | `focusCell(4, 0)`; `type('z')`; `press('Enter')` | `text(4, 0) === 'z'`; focus is `cell(4, 0)`; no error thrown (F2). |

### 7.3 Unit cases (`sheet-change-set-test.ts`)

- `parseTsv`: `\n` and `\r\n`, one trailing newline dropped, empty cells
  kept, single value → `[['v']]`.
- `toTsv(parseTsv(x)) === x` for a block without trailing newline.
- `commitPatch`: patch shape; `null` for an unchanged value and for a
  read-only field; `parse` applied.
- `clearRange`: skips empty and read-only cells; `null` when nothing changes.
- `pasteMatrix`: clip at the last field, inserts past the end with
  increasing `index`, ragged rows, unchanged values omitted.
- `rangeMatrix`: `format` applied, clamped to existing rows.
- `localRecords().apply`: patched records are new objects, others keep
  identity, inserts appended, `log` grows.

### 7.4 Hook contract (`eui-data-grid-cell-api-test.gts`)

One test on a plain `EuiDataGrid` (3 columns, `@rowCount={{4}}`):
`getFocusedCell()` is `undefined` after render; after
`api.setFocusedCell({ rowIndex: 2, colIndex: 1 })` it is
`{ rowIndex: 2, colIndex: 1, visibleRowIndex: 2 }`; after ArrowUp to the
header from row 0 it has `rowIndex: -1`; after `blur()` it is unchanged. A
second test with `@sorting` (desc on a column, `@inMemory` level `sorting`)
checks `rowIndex !== visibleRowIndex` and that passing the result to
`setFocusedCell` focuses the same cell.

## 8. Running the tests from the Linux sandbox

The repo's `node_modules` are macOS-only: never run `pnpm`, `npm` or a build
inside `/Users/betocantu93/prysmex/ember-eui`. Edit files there, run in a
scratch copy. Core tests import `#src/*`, so `pnpm build:js` (`dist`) is
**not** needed for `packages/core`.

### 8.1 Disk first

```bash
df -h /        # 3.4 GB free on 2026-11-19; the copy with node_modules is about 0.8 GB
```

An old copy of this repo sits at
`/tmp/claude-1000/-Users-betocantu93-prysmex/fa5e7066-8c73-49f8-a9f1-5a379e01c89b/scratchpad/ember-eui`
(810 MB; it looked stale, but only its top level was checked). `~/prysmex/CLAUDE.md`
allows deleting a session folder with no file modified in the last 3 days:
re-check the whole folder with its `find … -mtime -3` command, then delete
it if space is short. One scratch copy, reused for every run.

### 8.2 Copy, install, build, run

```bash
S=<your scratchpad>
cd /Users/betocantu93/prysmex/ember-eui
git ls-files -co --exclude-standard -z | rsync -a --from0 --files-from=- ./ "$S/ember-eui/"
cd "$S/ember-eui" && pnpm install --frozen-lockfile --store-dir "$S/pnpm-store"

cd "$S/ember-eui/packages/core"
pnpm exec vite build --mode=development --out-dir dist-tests > "$S/build.log" 2>&1
CI=1 pnpm exec testem --file testem.cjs ci --port 0 \
  --test_page 'tests/index.html?hidepassed&filter=Spike' > "$S/test.log" 2>&1
```

- `pnpm test` is these two commands without the filter (`package.json:78`).
  The `--test_page …?filter=` form is the one
  `data-grid-extensions.md` already documents.
- `CI=1` makes `testem.cjs` pass `--no-sandbox` to Chrome
  (`/usr/local/bin/google-chrome` exists in the sandbox).
- Filters: `Spike` (both spike modules), `cell-api` (name the hook module
  `Integration | Component | EuiDataGrid cell-api`), `EuiDataGrid` (all grid
  tests, the regression run for the hook), no filter (full core suite, last).
- After each edit in the repo: repeat the `rsync` line (it copies only what
  changed), the build and the run.
- Run the build and anything longer than a couple of minutes in the
  background and wait for the notification. For the `EuiDataGrid` and full
  runs, use a scratch config so a Mac sleep does not fail the run:

  ```js
  // $S/testem-long.cjs, used with --file "$S/testem-long.cjs" from packages/core
  module.exports = { ...require(process.cwd() + '/testem.cjs'), browser_disconnect_timeout: 86400 };
  ```

- A failure with only `Browser timeout exceeded`: compare `date` before and
  after before suspecting the code.
- `No space left on device` or rolldown's `UNHANDLEABLE_ERROR` means the
  disk is full: section 8.1.

### 8.3 Static checks (in the scratch copy)

```bash
cd "$S/ember-eui/packages/core"
pnpm exec ember-tsc --noEmit                      # covers src/ only (the hook)
pnpm exec eslint tests/spikes tests/integration/spikes tests/unit/spikes \
  tests/integration/components/eui-data-grid-cell-api-test.gts \
  src/utils/data-grid/cell-api.ts src/components/eui-data-grid.gts
grep -rn "ember-eui extension (cell-api)" src tests   # 3 lines in src, 1 in the API test
```

### 8.4 Manual check on the Mac (R12, cannot run in the sandbox)

Add one test, `demo (manual)`, that renders the fixture and calls
`await this.pauseTest()` only when `location.search` contains `sheetdemo`
(otherwise it asserts `true` and returns). On the Mac:
`pnpm test:dev` in `packages/core`, open
`/tests/index.html?filter=demo&sheetdemo`, then check in Chrome, Firefox and
Safari: typing a letter gives one character; Cmd+C on a range then paste
into a spreadsheet; copy a block from a spreadsheet and Cmd+V on a cell;
Esc and Enter return focus to the cell. Record the results in `RESULTS.md`.

### 8.5 Clean up before ending

`rm -rf "$S/ember-eui" "$S/pnpm-store"`; keep the logs. Do not commit.

## 9. Success criteria and questions to answer

The spike succeeds when:

1. T1 to T15, the unit tests and the hook contract test pass in the sandbox.
2. `?filter=EuiDataGrid` passes with only the one marked expectation changed
   (section 4.3).
3. `grep "ember-eui extension (cell-api)"` shows the 3 source lines of
   section 4.2 and no other change in ported files.
4. `RESULTS.md` answers the questions below, with the test that backs each
   answer.

Questions for the plan doc:

1. **Is one hook enough?** Did every test pass with the lines of section 4.2
   only?
2. **Is even one hook needed?** Did T1 to T6 pass with `@cursorSource="dom"`?
   If yes, say what `getFocusedCell` still buys (position while the cell is
   scrolled out of the DOM, no dependence on markup attributes) against its
   cost (3 lines and one changed ported test).
3. **Which extra hooks were needed, if any?** File, line, marker name and the
   failing test that forced each. Was `@onFocusedCellChange` (section 4.4)
   needed, or was `focusin` enough?
4. **Does any upstream behaviour force a grid change?** In particular F6
   (focus on re-mount), F5 (`onTabularCopy` ignoring `defaultPrevented`) and
   F9.
5. **Does `setCellProps` scale for the selection?** The T7 timing, and
   whether the class-toggle fallback is needed.
6. **Does the sibling overlay hold?** Position accuracy (T11), and what
   fullscreen mode and clipping ancestors would require (a portal plus its
   own key handler, or a grid slot).
7. **What did the manual check (8.4) show** for real paste, copy and typing?
8. **Left for the product version:** IME (always-mounted hidden input), sheet-owned
   sorting versus exposing `getCorrectRowIndex`, Tab in nav mode, Excel-style
   active cell on the anchor, quoted TSV cells, undo from `from`/`to`
   patches, control columns (row numbers, checkboxes) shifting `colIndex`.

## 10. Summary

- The sheet wraps `EuiDataGrid` in a `div` with capture-phase `keydown`,
  `copy`, `paste` and `scroll` listeners and a `focusin` listener. The editor
  is a sibling of the grid inside that wrapper, positioned from the cell's
  rect, so the grid's tab management and key handlers never see it.
- Arrow navigation, including Shift+arrows, stays with the grid; the sheet
  only decides whether a focus move collapses or extends its range.
- Selection is drawn by the cell renderer through `setCellProps`; data is
  controlled through `@onChange(changeSet)` and a `localRecords()` owner.
- The `cell-api` hook is 3 marked lines plus a 25-line file. It breaks one
  ported test that lists the API keys, which must change by one word.
- Reading the code suggests the sheet may not need the hook at all; the
  tests run with both cursor sources to settle it.
- No blocker found. Not provable in the sandbox: trusted `paste`/`copy`
  events and IME (manual check on the Mac).
