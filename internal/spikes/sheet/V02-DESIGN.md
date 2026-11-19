# `@ember-eui/sheet` v0.2: design of the Airtable-parity backlog

Written 2026-11-19 against branch `feat/sheet`, HEAD `7f02013a`
(113 tests passing), and revised the same day after the user's review
(section 14 lists what the review changed). Design only: nothing here is
implemented. It follows `DESIGN.md`, `PACKAGE-DESIGN.md` (v0.1) and
`PACKAGE-RESULTS.md` sections 1 to 16, and it was checked against the
code; section 12 lists what could not be checked.

Short names used below: **the sheet** is `packages/sheet/src/components/eui-sheet.gts`,
**the grid** is `packages/core/src/components/eui-data-grid.gts` and
`eui-data-grid/*`, **the owner** is whatever provides `@records`:
ideally an EmberSearchUi driver through the connector of section 7.

## 1. Goal

v0.2 adds the rest of the Airtable-like behaviour that belongs to a
grid: records (row numbers, add, delete, duplicate, expanded record),
presentation (hidden fields, order, widths, row height, frozen primary
field, summary bar, highlighted search term), ten more field types with
bulk resolve on paste, editing polish (fill handle, cut, fill right, edge
jumps, auto-scroll, quoted TSV), theme colours, IME and touch, and a
connector that renders the sheet as an EmberSearchUi results view.

Rules:

- **The sheet is a pure view of the rows it is given.** It never sorts,
  filters, searches, groups, pages or aggregates. Those are data queries
  and belong to the owner. The sheet only draws their state (a sort
  arrow, a highlighted term, a summary value) and emits intents.
- **Data down, actions up, for presentation too.** The owner passes the
  visible fields in display order, widths and row height; the sheet emits
  `onHiddenFieldsChange`, `onFieldOrderChange`, `onFieldWidthChange`,
  `onRowHeightChange`. The sheet keeps local state for one of these only
  when the owner passes no handler for it (a bare sheet).
- Every write goes out as a change set.
- There is no built-in toolbar. The sheet has a `<:toolbar>` and a
  `<:footer>` block where the app puts its own controls (EmberSearchUi
  views, a field picker, paging).
- `packages/core/src` is not changed by this design. One feature (the
  frozen field) has a grid-extension fallback, specified in section 9, to
  be used only if its acceptance test fails.
- Cells render no tabbable element (P9). Editors live beside the grid.
- Everything is additive unless section 3.7 lists it.
- Each verified batch is committed on `feat/sheet`, so each must be
  complete on its own (code, tests, docs).

## 2. Batch plan

| # | Batch | Depends on | Source lines (est.) | Test lines (est.) |
| --- | --- | --- | --- | --- |
| 1 | Foundations: theme tokens, quoted TSV, change set v2, add-row plumbing, `SheetApi` | v0.1 | 700 | 700 |
| 2 | Records: row numbers, row/column selection, add, delete, duplicate, context menu, expanded record (flyout or modal) | 1 | 1,500 | 1,400 |
| 3 | View intents: sort arrows and header menu, presentation intents, `<:toolbar>`/`<:footer>` blocks, highlight, loading, summary bar, frozen primary field | 1, 2 | 900 | 900 |
| 4 | EmberSearchUi connector (`@ember-eui/sheet/search-ui`) and its docs demo | 1 to 3 | 500 | 600 |
| 5 | Field types and `@onResolve` | 1 to 4 (the form of 2; `@highlight`, `toNumber`, `schema` of 3; it adds `@onResolve` to the connector of 4) | 2,100 | 1,700 |
| 6 | Editing polish, IME and dead keys, touch | 1 to 5 | 1,100 | 900 |

Why this order: theme tokens first, so later batches add colours as
tokens once; quoted TSV first, because long text and multi-select
(batch 5) produce cells with line breaks and commas and `toTsv` joins raw
today (`src/core/tsv.ts`); the change-set contract first, because every
later feature reads it; the connector right after the intents it maps;
IME last because it can only be verified with real input on the Mac
(its mechanism is fixed in 8.6).

Group by is **deferred to v0.3** (7.6 says why). The in-memory sort,
filter, search and group logic of the first version of this design is
gone from the sheet (3.5).

## 3. Shared contracts (decided once, used by every batch)

### 3.1 Decisions

| # | Decision | Reason |
| --- | --- | --- |
| V1 | The grid's rows are `@records` in the order given, plus one "add" row at the end when inserting is allowed. `@rowCount = records.length + (addRow ? 1 : 0)`. The grid's `@grouping`, `@rowTree`, `@pagination` and `@inMemory` are not used. | The grid's row index stays equal to its visible row index and to the record's index, so the sheet's assert (`eui-sheet.gts:457-461`), `setFocusedCell` and every core builder stay as they are. |
| V2 | The grid's `@sorting` is passed only so the header shows sort arrows and the built-in "Sort A-Z / Z-A" column actions, and only when the owner passes `@onSortChange`. | `computeSortedRowMap` returns `[]` without `inMemory.level === 'sorting'` (`utils/data-grid/sorting.ts`), so the grid never reorders rows. The owner does. |
| V3 | No in-memory query logic in the sheet package: no filter evaluator, no sort, no search, no `localView()`. Local data that needs them is owned by an EmberSearchUi driver with `memoryBackend`. | 3.5. |
| V4 | "Stable while editing" lives in the connector: after the user's own edits it does not re-query; it shows the edits over the last results and offers "Re-apply" (`driver.refresh()`). | The user's decision. The sheet cannot re-query anything. |
| V5 | The frozen primary field is done in the sheet, with sticky cells through `setCellProps`, and with column virtualization turned off while a field is frozen. No grid change. | Section 9: mechanics checked in headless Chrome on a mock; the fallback extension is specified. |
| V6 | Theme: one Emotion class on the wrapper defines `--euiSheet-*` custom properties from the resolved `euiTheme`; the static CSS reads them with light fallbacks. The same class goes on every portaled root. | The way core components get colours (`@ember-eui/core/theming`), and it works without a provider. |
| V7 | The expanded record reuses `type.cell` and `type.editor`: each field shows its cell in a focusable box; activating it mounts the type's editor inline, one at a time. It renders in an `EuiFlyout` or an `EuiModal`, by argument. | The editor contract already fits; editors focus themselves on mount (`input-editor.gts` `setup`), so mounting all at once would fight for focus. |
| V8 | IME and dead keys: an always-mounted, normally unfocused "composition catcher" input beside the grid. The sheet focuses it synchronously on a `keydown` that starts a composition, and opens the real editor with the composed text. | Focus stays on grid cells in nav mode, so `handleGridKeyDown`'s `gridElement.contains(document.activeElement)` check and the sheet's `target === cell` gate keep working. |
| V9 | Bulk resolve emits the synchronous part of a paste at once and the resolved part as a second change set (`source: 'resolve'`); both are one undo entry. | A paste should not wait for the network. Deviation from `PACKAGE-DESIGN.md` 9.2 ("one change set"), which this replaces. |
| V10 | The connector is an optional entry of the sheet package, `@ember-eui/sheet/search-ui`, typed against a structural interface of the driver. Neither package depends on the other. | 7.1. |

### 3.2 Rows and positions

- `Pos.row` is an index into `@records`, or `records.length` for the add
  row. `anchor`, `head` and `Range` use it. `SheetContext.records` stays
  `@records`. No mapping layer is needed.
- Columns: `anchor`/`head`/`Range` use data-column indexes (0 = first
  field of `@fields`). The grid's column index is the data column plus
  `colOffset`, the number of leading control columns (`cell.gts:868-871`
  passes the grid's `colIndex`, control columns included). `cursor(cell)`
  subtracts it, `focusCell(pos)` adds it, and `SheetCell` calls
  `sheet.cellView(row, colIndex - colOffset, columnId)`.
- The add row is never part of a range: a range's `bottom` is clamped to
  the last record for copy, clear and fill (the core builders already
  clamp to `ctx.records.length - 1`). Paste may start on it (inserts).
- When `@records` changes and it was not the sheet's own change set
  being applied (the previous and new arrays differ in ids or order): the
  selection collapses to the head's cell, found again by record id; when
  that record is gone the head keeps its row index, clamped. If a data
  cell had DOM focus, the sheet re-focuses the new position after render
  (`pendingFocus`, 4.4). This is what happens on an owner's re-query (new
  sort, new page, "Re-apply"), and with an async owner it can happen
  while the user types.
- An open editor survives such a change. `commit()` and `cancel()` use
  `editing.pos.row` today (`eui-sheet.gts:1086-1128`), which after a
  re-query can be another record. So `editing.pos.row` is found again
  from `editing.recordId` whenever `@records` changes: when the record is
  still there the editor stays open on it (its frame is re-positioned
  from the cell's new rect after render; if the row is not rendered the
  editor commits, as on scroll); when the record is gone the edit is
  cancelled without a change set. `editorRecord`/`editorValue` read by
  `recordId` too.
- A select drag in progress ends (`endDrag()`), keeping no range.

### 3.3 `pendingFocus`

`pendingFocus: { id: string; fieldId: string } | null`, a plain field. A
function modifier on the wrapper that takes `@records` runs after each
render: when `pendingFocus` is set and its record is in `@records`, it
clears it and calls `api.setFocusedCell`. Used for inserted rows, which
"exist only after the next render" (`eui-sheet.gts:971`), and for 3.2.

### 3.4 Change set v2 (`src/core/types.ts`)

```ts
export interface RecordInsert {
  tempId: string;
  /**
   * Position in the records the sheet was given (`@records`, which may be
   * one page of the owner's data): the record's index in the result, after
   * the set's deletes are applied and with inserts applied in ascending
   * `index` order. An index past the end appends.
   */
  index: number;
  values: Record<string, unknown>;
  /** NEW. The neighbour in `@records` when the insert was made. Owners whose data is larger than `@records` (paged, sorted elsewhere) position by this. */
  anchor?: { recordId: RecordId; position: 'before' | 'after' };
  /** NEW. Set when an undo re-creates a deleted record: its id and the object it was. */
  restore?: { recordId: RecordId; record: unknown };
}

/** NEW. What a delete removed, so it can be undone. */
export interface RecordRemoval {
  recordId: RecordId;
  /** Index in `@records` when it was removed. */
  index: number;
  /** The neighbour before it in `@records` then, if any. */
  after?: RecordId;
  record: unknown;
}

export interface ChangeSet {
  source:
    | 'edit' | 'paste' | 'clear' | 'fill' | 'undo' | 'redo'
    | 'insert' | 'delete' | 'cut' | 'resolve';          // NEW: the last four
  patches: CellPatch[];
  inserts: RecordInsert[];
  /** Ids of records to remove. Now also emitted by user deletes (source 'delete'). */
  deletes?: RecordId[];
  /** NEW. Present whenever `deletes` comes from a user delete or its redo: same order as `deletes`. */
  removed?: RecordRemoval[];
  rejected: CellRejection[];
  newOptions: NewOption[];
}
```

Core functions, with every behaviour change:

| Function | v0.1 | v0.2 |
| --- | --- | --- |
| `applyChangeSet` | Removes `deletes`, patches, then **appends** inserts in `index` order. | Removes `deletes`, patches, then for each insert in ascending `index`: when `anchor` is set and that record is in the array, right before or after it; else `splice(Math.min(index, length), 0, record)`. An insert with `restore` puts back `restore.record` as it is, unless the new option `restoreRecord(insert) => T` is given. Paste inserts have `index >= length` and an anchor after the last record, so they still append in order: existing tests U8, H2 and H5 keep their results. Because the anchor wins, the same call works on an array larger than the page the sheet saw (the connector's demo, 7.5). An anchor that names the `tempId` of an insert earlier in the same call resolves through a local map (`tempId` → the record just created), so it works when `createRecord` gives the record another id. |
| `pasteMatrix` | Insert `index` is `ctx.records.length + n`. | Same index. Inserts get `anchor: { recordId: <last record>, position: 'after' }` when there is one (each later insert anchors after the previous insert's `tempId`). |
| `invertChangeSet` | Patches swapped; inserts become `deletes`. | Also: each `removed` entry becomes an insert `{ tempId: String(recordId), index, anchor: after && { recordId: after, position: 'after' }, values, restore: { recordId, record } }`, ascending `index`. `values` are the record's values for the new optional second parameter `fieldIds?: readonly string[]` (without it `{}`; `restore` carries the record). |
| `withoutConflicts` | Re-inserts go to the end (`index: records.length + i`). | A re-insert keeps its position: the anchor's current index when the anchor exists (+1 for `'after'`), else `Math.min(index, records.length)`. A delete being redone is kept when the record exists. New optional option `equals?: (fieldId: string, a: unknown, b: unknown) => boolean` (default `Object.is`), used for the "cell still holds its `from`" check (array values, batch 5). |
| `undoChangeSet` | `(entry, records, getRecordId)` | New optional fourth parameter `options?: { fieldIds?: readonly string[]; equals?: (fieldId, a, b) => boolean }`, passed on to `invertChangeSet` and `withoutConflicts`. The sheet passes the ids of `@fields` and `@hiddenFields` and an `equals` built from the field types. |
| `redoChangeSet` | Patches and inserts again. | Also `deletes` and `removed` again (the entry's own), for a redone delete. The same optional `options` parameter (`equals`). |
| new `insertRecords` | none | `insertRecords(ctx, { at: number; anchor?: RecordInsert['anchor']; values?: Record<string, unknown>[]; nextTempId?: () => string }): ChangeSet`. One insert per entry of `values` (default one, `{}`), indexes `at`, `at + 1`, ...; the first has `anchor`, each next one anchors after the previous `tempId`; source `'insert'`. Never `null`. |
| new `deleteRecords` | none | `deleteRecords<T>(records: readonly T[], ids: readonly RecordId[], getRecordId): ChangeSet \| null`. `deletes` and `removed` in ascending index; ids that match nothing are dropped; `null` when none is left; source `'delete'`. |
| new `duplicateRecords` | none | `duplicateRecords(ctx, recordIndexes: readonly number[], options: { nextTempId?: () => string }): ChangeSet \| null`. For each record listed: an insert right after it, `values` = its value for every field of `ctx.fields` that is not read-only for that record (the sheet passes visible and hidden fields, with sheet-level `readOnly: false`); source `'insert'`. |
| new `mergeChangeSets` | none | `mergeChangeSets(first: ChangeSet, second: ChangeSet): ChangeSet`. For history only: patches of the same cell collapse to `first.from` → `second.to`; a patch of `second` on a `tempId` inserted by `first` is folded into that insert's `values`; inserts, deletes, removed concatenated; `source` of `first`. |

Sheet-side changes that follow (`eui-sheet.gts`):

- `recordHistory` (line 1216) also records a change set that has only
  `deletes`. A `'resolve'` change set is merged into the entry of the
  paste that asked for it (`mergeChangeSets`) instead of being pushed.
- `selectChanged` (line 864): after patches, as today. Otherwise, when
  the emitted change set has inserts, the sheet sets `pendingFocus` to
  the first inserted id and the previous head's field. Otherwise (rows
  removed) as today.
- `emit` drops the removed records' ids from `rejections`, the checked
  rows (batch 2) and pending resolves (batch 5).
- Undo and redo work on the records the sheet has now. After an owner's
  re-query, a history entry whose record is not in `@records` (another
  page, filtered out) is skipped by the existing conflict rule (the
  record is not there). Section 7.3 says what the connector does about
  it.

An owner whose server cannot give a restored record its old id creates a
new record from `values`. The redo of that delete then names an id that
no longer exists and is skipped (unknown ids are ignored, as in v0.1).
`SheetApi.remapIds` (3.6) lets such an owner tell the sheet the new id.
Open question Q6.

### 3.5 Queries belong to the owner; intents

What the sheet takes and emits, all optional:

```ts
// Query state: drawn, never applied
sort?: SheetSort[];                 onSortChange?: (sort: SheetSort[]) => void;
/** A term the owner searched for; matching text is highlighted in cells. */
highlight?: string;
/** The header menu's "Filter by this field". The item shows only with a handler. */
onFilterByField?: (fieldId: string) => void;
/** Shows a thin progress bar over the grid (EuiProgress). */
isLoading?: boolean;
/** Position of the first record (paged data): row numbers start at offset + 1. */
rowNumberOffset?: number;
/** Owner-computed text per field id; passing it shows the summary bar (6.6). */
summary?: Record<string, string>;

// Presentation state: data down, actions up
fields: EuiSheetField<T>[];         // the VISIBLE fields, in display order (as in v0.1)
/** Fields that exist but are not shown: listed in the expanded record and given to the toolbar block. */
hiddenFields?: EuiSheetField<T>[];  onHiddenFieldsChange?: (fieldIds: string[]) => void;
                                    onFieldOrderChange?: (fieldIds: string[]) => void;
fieldWidths?: Record<string, number>;
                                    onFieldWidthChange?: (fieldId: string, width: number) => void;
rowHeight?: SheetRowHeight;         onRowHeightChange?: (rowHeight: SheetRowHeight) => void;
frozenFields?: number;              // default 1

/** Same shape as EmberSearchUi's SortItem (ember-search-ui-driver/src/types.ts:83). */
export interface SheetSort { field: string; direction: 'asc' | 'desc' }
export type SheetRowHeight = 'short' | 'medium' | 'tall' | 'extraTall';
```

Rules:

- **With a handler, the sheet is controlled for that piece**: it renders
  exactly the argument and only calls the handler. If the owner does not
  update the argument, nothing changes on screen.
- **Without a handler, the sheet keeps a local fallback** for hidden
  fields, order, widths and row height (the bare sheet of v0.1 keeps
  working: its header "Hide column" and "Move" actions act locally).
- **Sort has no fallback.** Without `@onSortChange` the header has no
  sort items and no arrows, because nothing would sort.
- `onHiddenFieldsChange` gets the full new list of hidden ids (the ids of
  `@hiddenFields` plus or minus one). `onFieldOrderChange` gets the
  visible ids in the new order.

Why no `localView()` helper beside `localRecords`: EmberSearchUi's
driver already has an in-memory backend (`memoryBackend(docs | () =>
docs, options)`, `ember-search-ui-driver/src/memory-backend.ts`) with
filter, text search, multi-key sort and paging, one evaluator shared with
its server codecs. A second evaluator in the sheet would have its own
semantics (empty values, diacritics, operators) and would have to be kept
equal by hand. So: local data that needs sorting or filtering (an import
draft) is owned by a driver with `memoryBackend` and shown through the
connector; a bare `localRecords` sheet shows its rows as they are. The
cost is that sorting a local sheet needs EmberSearchUi installed (Q15).

### 3.6 `SheetApi` and blocks

```ts
export interface SheetApi {
  undo(): void;
  redo(): void;
  /** Focuses a cell by record and field. No-op when the record is not in `@records`. */
  focusCell(cell: { recordId: RecordId; fieldId: string }): void;
  /** Tells the sheet the ids the owner gave to inserted (or restored) records: history, rejections, checked rows, pending focus and pending resolves are rewritten. */
  remapIds(ids: Record<string, RecordId>): void;
  /** Drops the undo and redo stacks (an owner calls it when its data changed wholesale). */
  clearHistory(): void;
  /** Batch 2. */
  expandRecord(recordId: RecordId | null): void;
  insertRecord(options?: { anchor?: RecordInsert['anchor']; values?: Record<string, unknown> }): void;
  deleteRecords(ids: RecordId[]): void;
}

// Args
registerApi?: (api: SheetApi) => void;   // called once, after the first render

// Blocks (batch 3)
toolbar: [SheetBlockApi];   // above the grid, inside the wrapper
footer: [SheetBlockApi];    // below the grid

export interface SheetBlockApi<T = any> {
  api: SheetApi;
  fields: EuiSheetField<T>[];
  hiddenFields: EuiSheetField<T>[];
  sort: SheetSort[];
  rowHeight: SheetRowHeight;
  checkedRecords: T[];
  /** Each calls the matching handler, or the local fallback. */
  hideField(fieldId: string): void;
  showField(fieldId: string): void;
  setRowHeight(rowHeight: SheetRowHeight): void;
  setSort(sort: SheetSort[]): void;      // no-op without @onSortChange
}
```

### 3.7 Changes that are not purely additive

| # | Change | Who notices |
| --- | --- | --- |
| C1 | `ChangeSet['source']` gains `'insert'`, `'delete'`, `'cut'`, `'resolve'`. | TypeScript code with an exhaustive `switch` on `source`. |
| C2 | `applyChangeSet` honours `RecordInsert.anchor` and `index` (3.4). | Only a hand-written change set with an `index` inside the array; v0.1 never emitted one. |
| C3 | `withoutConflicts` keeps a re-insert's position instead of moving it to the end. | A redo of an undone paste: same result, since paste indexes are past the end. |
| C4 | `parseTsv` reads quoted cells; `toTsv` quotes cells with tabs or line breaks or a leading `"` (4.2). | Pasted text whose cell starts with `"`. |
| C5 | A user delete emits `deletes` (v0.1: only an undo did). | An owner that ignored `deletes`. |
| C6 | With `@onHiddenFieldsChange` or `@onFieldOrderChange`, the header's "Hide" and "Move" actions only call the handler. Without them they act locally, and "Hide" now really hides: in v0.1 the field moves to the end instead (from the source, not run: `visibleFieldIds`, `eui-sheet.gts:260-265`, re-adds the ids missing from the grid's list). | A v0.1 bug fixed; owners that pass the handlers must update `@fields`. |
| C7 | The first field is frozen by default (batch 3); `@frozenFields={{0}}` turns it off. | Sheets with horizontal scroll. |
| C8 | A leading row-number column shows by default (batch 2); `@rowNumbers={{false}}` hides it. Grid column indexes of data cells shift by one (`data-gridcell-column-index`). | Tests or CSS that read the grid's column index. The sheet's test helper `cell(row, col)` adds the offset. |
| C9 | Space on a data cell opens the expanded record (it did nothing, P8). | Nobody relied on it. |
| C10 | Shift+Enter on a data cell inserts a record below (batch 2). In v0.1 it opens the editor, like Enter (`eui-sheet.gts:784` does not look at Shift). | Anyone who used Shift+Enter to edit. |
| C11 | Ctrl/Cmd+R is taken by the sheet while a data cell has focus (batch 6). | Reload from inside the grid. |
| C12 | Minimum `@ember-eui/core` peer must have `@ember-eui/core/theming` (`euiClass`, `getEuiThemeContext`, `useEuiBorealisStyles`). | To check in batch 1 (section 12). |
| C14 | When the owner replaces `@records`, the selection, focus and an open editor follow their record by id (3.2). In v0.1 they stayed on the same row index. | Owners that re-order or reload records while the sheet has focus. |
| C13 | With row numbers, ArrowLeft from the first field moves focus to the row-number cell. The sheet handles Home and Ctrl/Cmd+Home on data cells itself so they still land on the first field (the grid would go to column 0, the row-number cell: `focus.ts`). Focus on a row-number cell reached by keyboard clears the range (`anchor = head = null`), so Delete, copy and paste do nothing there; only the keys of 5.5 work. | Keyboard users at the first column. |

## 4. Batch 1: foundations

### 4.1 Scope

Theme tokens (dark mode), quoted TSV, change set v2, `colOffset` and
add-row plumbing (no add row yet), `pendingFocus`, `SheetApi` (`undo`,
`redo`, `focusCell`, `remapIds`, `clearHistory`). Visible results: the
sheet follows light/dark, and cells with tabs or line breaks copy and
paste.

| File | Change |
| --- | --- |
| `src/core/tsv.ts` | Rewritten (4.2). |
| `src/core/types.ts`, `change-set.ts`, `history.ts` | Change set v2 (3.4). |
| `src/core/index.ts`, `src/index.ts` | New exports. |
| `src/-private/theme.ts` (new), `src/-private/styles.ts` | Theme (4.3). |
| `src/components/eui-sheet.gts`, `src/-private/sheet-cell.gts` | Plumbing (4.4), the theme class. |
| `src/types.ts` | `registerApi`, `SheetApi`, `themeClass` on editors. |
| `src/local-records.ts` | Option `restoreRecord`, passed to `applyChangeSet`. |
| `tests/helpers/sheet.ts` | `cell(row, col)` adds the column offset (0 for now). |

### 4.2 Core

`src/core/tsv.ts` (rewritten):

```ts
/**
 * TSV as Excel and Google Sheets write it. A cell that starts with `"` is
 * quoted up to the next `"` that is followed by a tab, a line break or the
 * end; inside, `""` is one `"`, and tabs and line breaks are part of the
 * cell (`\r\n` becomes `\n`). A cell that starts with `"` and has no
 * closing quote is read as plain text. A `"` elsewhere is plain. One
 * trailing empty line is dropped, as before.
 */
export function parseTsv(text: string): string[][];
/** Quotes a cell when it has a tab, `\n`, `\r`, or starts with `"`; `"` inside a quoted cell is doubled. */
export function toTsv(matrix: readonly (readonly string[])[]): string;
```

Contract: `parseTsv(toTsv(m))` deep-equals `m` for every string matrix
whose last row is not the single cell `''`.

`src/core/change-set.ts`, `src/core/history.ts`: 3.4.

### 4.3 Theme (`src/-private/theme.ts`, new; `src/-private/styles.ts`)

```ts
import type { EuiThemeStyleContext } from '@ember-eui/core/theming';
/** Module scope, so `useEuiBorealisStyles` memoizes it per resolved theme. */
export const sheetThemeVars = ({ euiTheme }: EuiThemeStyleContext) => ({
  '--euiSheet-primary': euiTheme.colors.primary,
  /* ...the table below */
});
```

The sheet gets `@cached get themeClass()`:
`euiClass(context, useEuiBorealisStyles(context, sheetThemeVars))` with
`context = getEuiThemeContext(this)`, all from `@ember-eui/core/theming`
(the pattern in `packages/core/src/theming.ts:6-27`). The class goes on
the wrapper next to `euiSheet`. Custom properties in an Emotion object
are already used by core (`eui-emotion-provider.gts:213-218`).

Every fixed colour of `styles.ts` becomes `var(--euiSheet-x, <today's value>)`:

| Custom property | Token (`euiTheme.`) | Used for (today's value) |
| --- | --- | --- |
| `--euiSheet-primary` | `colors.primary` | focus ring, input border, checked checkbox (`#0B64DD`) |
| `--euiSheet-selected` | `colors.backgroundBaseInteractiveSelect` | selected cells (`rgba(0,119,204,.12)`) |
| `--euiSheet-hover` | `colors.backgroundBaseInteractiveHover` | row hover, opener hover |
| `--euiSheet-plain` | `colors.backgroundBasePlain` | input and checkbox background (`#FFF`; the input has none today, so it is white in dark mode), frozen cells |
| `--euiSheet-subdued` | `colors.backgroundBaseSubdued` | add row, row-number column |
| `--euiSheet-text` | `colors.textParagraph` | input text, opener hover (`#343741`) |
| `--euiSheet-textSubdued` | `colors.textSubdued` | opener, checkbox border, row numbers (`#69707D`) |
| `--euiSheet-danger` | `colors.danger` | invalid cell border (`#BD271E`) |
| `--euiSheet-textDanger` | `colors.textDanger` | invalid cell text |
| `--euiSheet-dangerFilled` | `colors.backgroundFilledDanger` | error box background |
| `--euiSheet-textInverse` | `colors.textInverse` | error box text, checkbox tick (`#FFF`) |
| `--euiSheet-border` | `colors.borderBaseSubdued` | frozen column edge, form boxes |
| `--euiSheet-shadow` | `colors.shadow` | error box and menu shadow |
| `--euiSheet-highlight` | `colors.backgroundLightText` | highlighted term (batch 3) |

All token names above exist in core's source (grep of `euiTheme.colors.*`
under `packages/core/src`). The static CSS stays one `<style
data-eui-sheet>` element. A selected cell on a frozen (opaque) cell is
drawn with `background-image: linear-gradient(var(--euiSheet-selected),
var(--euiSheet-selected))` over `background-color: var(--euiSheet-plain)`.

Portaled content does not inherit the wrapper's properties. So
`SheetEditorSignature['Args']` gains `themeClass: string` (additive): an
editor that renders a surface elsewhere adds it to that surface. The
record flyout or modal and the menus of batch 2 add it themselves.

### 4.4 Component plumbing (`eui-sheet.gts`)

- `colOffset` (0 in batch 1) and `hasAddRow` (false in batch 1), 3.2.
  `recordAt(row)` returns `@records[row]`, `undefined` for the add row.
- `pendingFocus`, 3.3. The 3.2 rule for an outside change of `@records`:
  the sheet remembers the ids of the last `@records` and whether its last
  `emit` is still waiting to be applied; a new array with the same ids in
  the same order, or one that differs only by that change set's inserts
  and deletes, is the sheet's own change.
- `api`: one stable object, passed to `@registerApi` after the first
  render.
- `remapIds`: a `Map<string, RecordId>` consulted wherever history,
  rejections and `pendingFocus` look a record up by a `tempId`.

### 4.5 Public API

Additive: `EuiSheetSignature.Args.registerApi`; exports `SheetApi`,
`insertRecords`, `deleteRecords`, `duplicateRecords`, `mergeChangeSets`,
`RecordRemoval`; `SheetEditorSignature.Args.themeClass`;
`LocalRecordsOptions.restoreRecord`. Changes: C1 to C4, C12.

### 4.6 Interaction with existing features

Undo/redo, selection, clicks, validation and the error box behave as in
v0.1; the 113 tests pass unchanged except `tsv-test.ts` U2 if it asserts
a leading-quote cell (check). Copy and paste now round-trip multi-line
cells. New: the selection survives an owner replacing `@records` (3.2);
in v0.1 it stayed on the same indexes.

### 4.7 Tests

| File | Cases |
| --- | --- |
| `tests/unit/tsv-test.ts` (extend) | Q1 quoted cell with a tab and a line break; Q2 `""` inside; Q3 unterminated quote is plain; Q4 a quote in the middle is plain; Q5 `\r\n` inside a quoted cell; Q6 `toTsv` quotes only when needed; Q7 round trip of 6 awkward matrices; Q8 an Excel sample (a cell with two lines, as a text fixture). |
| `tests/unit/change-set-test.ts` (extend) | S1 `applyChangeSet` inserts at an index, clamps, keeps paste appends; S2 anchor wins over index, on an array larger than the page; S2b three chained inserts with a `createRecord` that assigns new ids land in order after the anchor; S3 `restore` puts the object back, `restoreRecord` overrides; S4 `insertRecords`; S5 `deleteRecords` (order, `after`, unknown ids, `null`); S6 `duplicateRecords` skips read-only fields; S7 `pasteMatrix` anchors; S8 `mergeChangeSets`. |
| `tests/unit/history-test.ts` (extend) | H6 invert of a delete gives positioned restores; H7 undo then redo of a delete round-trips through `applyChangeSet`; H8 re-insert position follows the anchor when it moved; H9 `equals` option; H10 an entry whose record is not in the records is skipped. |
| `tests/integration/components/eui-sheet-theme-test.gts` (new) | TH1 the wrapper has an Emotion class and `--euiSheet-primary` resolves to the theme's primary; TH2 inside a dark provider (component name to check) the computed selected-cell background differs from light and the input background is not white; TH3 no fixed hex colour is left in `styles.ts` outside a `var(…, fallback)` (source scan, like B1). |
| `eui-sheet-test.gts` (extend) | T17 copy of a cell with a line break is quoted, pasting it back gives one cell; T18 `@registerApi` gives `undo`/`redo`/`focusCell`/`clearHistory`; T19 `remapIds` then Ctrl+Z of a paste that inserted rows removes the remapped records; T20 the owner replaces `@records` with the same records in another order: the selection and focus follow the head's record; T21 the head's record is gone: the row index is kept, clamped; T22 `@records` is re-ordered while an editor is open with a typed draft: the editor stays on its record, Enter saves to that record (not to the row index); T23 the edited record is removed from `@records`: the editor closes and nothing is emitted; T24 a select drag in progress ends. |

### 4.8 Docs

`sheet.md`: "Not yet" loses dark colours and quoted cells; new section
"Theme"; the change-set section documents `index`, `anchor`, `restore`,
`removed` and `remapIds`. README: same. Demo `d01-basics`: add a
dark/light switch around the sheet. New demo `d09-own-store.md`: a store
with server-style ids (an insert gets a new id after 300 ms, then
`remapIds`), undo across it.

### 4.9 Risks

- **Emotion class and portals**: a surface outside the wrapper without
  the class falls back to light colours (the `var()` fallbacks), not to
  broken ones.
- **Performance**: the id comparison of 4.4 is one pass over `@records`
  per change (10,000 ids: target under 2 ms, measure in d08).
- **Regression**: `colOffset` touches every position conversion. The
  existing 113 tests are the guard; do the plumbing first, run them, then
  add features.

## 5. Batch 2: records

### 5.1 Scope

Row-number column (position, checkbox, expand icon), whole-row and
whole-column selection, add row, Shift+Enter, context menu (insert
above/below, duplicate, expand, copy, delete), expanded record in a
flyout or a modal.

### 5.2 Public API (additive except C8 to C10, C13)

```ts
// Args
rowNumbers?: boolean;                 // default true
/** What the row-number cell shows. Default: the position, `rowNumberOffset + index + 1`. */
rowLabel?: (record: T, position: number) => string;
canInsert?: boolean;                  // default !@readOnly
canDelete?: boolean;                  // default !@readOnly
/** Values of a new record. */
newRecordValues?: (context: { above: T | undefined; below: T | undefined }) => Record<string, unknown>;
checkedRecordIds?: RecordId[];        onCheckedChange?: (ids: RecordId[]) => void;
expandedRecordId?: RecordId | null;   onExpandedRecordChange?: (id: RecordId | null) => void;
/** How the expanded record is shown. Default 'flyout'. */
expandedRecord?: 'flyout' | 'modal';
/** Extra items of the row menu. */
rowActions?: SheetRowAction<T>[];

export interface SheetRowAction<T = any> {
  id: string;
  label: string;
  icon?: string;
  color?: 'danger';
  isDisabled?: (records: T[]) => boolean;
  onSelect: (records: T[]) => void;
}
```

The row-number column shows the row's **position**, not its id. An app
that wants the id visible passes `@rowLabel` (for example
`(record) => String(record.id)`), or adds the id as a normal field (the
first field is frozen by default). `@rowNumberOffset` (3.5) keeps
positions right on page 2 and later. The checked ids and the expanded id
follow the rule of 3.5: controlled with a handler, local without one.

New messages (tokens `euiSheet.*`): `addRecord`, `insertAbove`,
`insertBelow`, `duplicateRecord`, `expandRecord`, `copyRows`,
`deleteRecords(count)`, `selectRow`, `selectAllRows`, `rowNumber(n)`,
`recordTitle(n)`, `previousRecord`, `nextRecord`, `close`.

### 5.3 Files

| File | What |
| --- | --- |
| `src/-private/row-number-cell.gts` (new) | Body cell of the control column: the label, or on hover/checked a checkbox span `[data-eui-sheet-row-check]`, and an expand span `[data-eui-sheet-row-expand]`. No tabbable element. |
| `src/-private/row-menu.gts` (new) | `EuiPanel` + `EuiContextMenuPanel` + `EuiContextMenuItem` (all exist in core), positioned in the wrapper at the pointer, like the editor frame. |
| `src/-private/record-form.gts`, `record-form-field.gts` (new) | The expanded record's content, used inside the flyout and the modal. |
| `src/-private/record-flyout.gts`, `record-modal.gts` (new) | The two shells. |
| `src/-private/editor-frame.gts` | The focus-out logic moves to an exported class or function both the frame and the form field use; new `@layout="inline"` (static position). |
| `src/components/eui-sheet.gts` | Control column, selection kinds, add row, menu, insert/delete/duplicate, form wiring. |

The control column is `leadingControlColumns=[{ id: 'euiSheetRow',
width: 64 }]`, rendered with the grid's `<:controlHeaderCell>` and
`<:controlCell>` blocks (the grid renders `headerCellRender` without
arguments, `header-cell.gts:471`, so a block is the way to reach the
sheet's state). `@rowNumbers={{false}}` passes no control column. The
width grows to fit the widest label of the rendered rows only when
`@rowLabel` is passed (`max(64, 24 + 8 × longest label length)`,
recomputed on `@records` change).

### 5.4 Selection kinds

`rangeKind: 'cells' | 'rows' | 'columns'` (tracked, default `'cells'`),
set with the range and reset to `'cells'` by any cell click, arrow or
paste.

| Action | Result |
| --- | --- |
| Click a row number (not the checkbox or expand icon) | `anchor = (row, 0)`, `head = (row, lastCol)`, `rangeKind = 'rows'`; focus goes to the row-number cell. |
| Shift+click a row number, or drag over row numbers | Extends the rows. |
| Click a column header's content (`.euiDataGridHeaderCell__content`, not the actions button or the resizer) | `anchor = (0, col)`, `head = (lastRecordRow, col)`, `rangeKind = 'columns'`; focus stays on the header cell. |
| Shift+click another header | Extends the columns. |
| Click the checkbox span | Toggles the record in the checked set. Shift+click checks the rows between the last toggled one and this one. |
| Click the header checkbox | Checks every record of `@records`, or none when all are checked. |
| Ctrl/Cmd+A | As v0.1: all record rows and columns, `'cells'`. |

Delete, copy, cut, fill and paste use the range whatever its kind. The
"records of the selection" (for the menu and `rowActions`) are the
checked records when any is checked, else the record rows of the range.
All of this is about the rows the sheet has (one page, with a paging
owner); the docs say so.

### 5.5 Keys and mouse

| Where | Key / gesture | Result |
| --- | --- | --- |
| Data cell | Space (no navKey took it) | Expands the record (C9). |
| Data cell | Shift+Enter | Inserts a record below this row; focus goes to the same field of the new row (C10). |
| Data cell or row-number cell | Shift+F10, ContextMenu key, right-click | Opens the row menu. A right-click outside the range first selects that cell. |
| Row-number cell | Space | Toggles the row's checkbox. |
| Row-number cell | Enter | Expands the record. |
| Row-number cell | Shift+ArrowUp/Down | Extends a `'rows'` range. |
| Add row, any cell | Click, Enter | Inserts a record at the end; focus goes to the first editable field of the new row. |
| Add row | Paste | Pastes from the first new row on (inserts, as v0.1 past the end). |
| Add row | Typing, Delete, Space | Nothing. |
| Row menu | ArrowUp/Down, Enter, Escape | `EuiContextMenuPanel`'s own; Escape or a click outside closes and re-focuses the cell with `api.setFocusedCell`. |

Row menu items, in order: Insert record above, Insert record below,
Duplicate record(s), Expand record (one record only), Copy row(s),
`@rowActions`, Delete record(s) (danger). Insert and duplicate need
`canInsert`; delete needs `canDelete`. There is no delete shortcut:
Delete and Backspace always clear cells (Q13).

The add row: the first data cell shows a "+" icon and
`messages.addRecord()`, the row-number cell a "+", the other cells
nothing; it gets a class through `gridStyle.rowClasses` (`types.ts`:
`rowClasses?: Record<number, string>`, one entry).

Copy rows writes `toTsv` of the rows' visible fields with
`navigator.clipboard.writeText`; when that is missing or rejects, a
hidden `<textarea>` and `document.execCommand('copy')`.

### 5.6 Insert, delete, duplicate as change sets

- Insert below row `r`: `insertRecords(ctx, { at: r + 1, anchor: {
  recordId: id(r), position: 'after' }, values: [@newRecordValues?.(…) ?? {}] })`.
  Above: `at: r`, `position: 'before'`. Add row: `at: records.length`,
  anchor after the last record.
- Delete: `deleteRecords(@records, ids, getRecordId)`.
- Duplicate: `duplicateRecords`.
- All three go through `emit`, so they are undo entries. Undo of an
  insert emits `deletes` (v0.1 rule: found by `tempId`, or the remapped
  id). Undo of a delete emits positioned `restore` inserts (3.4).
- Where the new row ends up is the owner's call: `localRecords` and the
  connector put it at its index; a re-query may move or drop it.

### 5.7 Expanded record

- State: `@expandedRecordId`. Opened by Space, the expand icon, the menu,
  or `api.expandRecord(id)`.
- Shell, by `@expandedRecord`: `'flyout'` (default) is `EuiFlyout`
  (`@onClose`, `@size="m"`, `@ownFocus={{true}}`: arguments exist in
  `eui-flyout.gts`); `'modal'` is `EuiModal` with `EuiModalHeader`,
  `EuiModalBody` (exist in core; arguments to check). Both get
  `class={{sheet.themeClass}} euiSheetRecord` and render the same
  `record-form`. The header (title, previous/next, close) is part of the
  shell; the body is `record-form`.
- Title: the first field's formatted text, or `messages.recordTitle(n)`;
  previous/next step through `@records`.
- Body: the fields of `@fields`, then those of `@hiddenFields`, each a
  `record-form-field`: the label (and `description`, batch 3), then a box.
- The box shows `type.cell` (or the text) with the same
  `SheetCellSignature` arguments as the grid cell. It is `tabindex="0"`
  with `role="button"` when the field can be edited (tabbable is fine
  here: it is not in the grid).

| In the form | Key / gesture | Result |
| --- | --- | --- |
| Box | Click, Enter, F2, a printable key the type opens on | Mounts `type.editor` inside the box (`EditorFrame @layout="inline"`), with `draft`, `initialKey`, `onDraftChange`, `onCommit`, `onCancel`, `messages`, `themeClass` as in the grid. A `'panel'` editor renders in flow under the box. |
| Box | Space, or a key `type.navKey` accepts | The navKey result is saved. |
| Box | Click, when the type has `onCellClick` | Its result is saved (the checkbox toggles). |
| Box | Delete, Backspace | Clears the field. |
| Box | Ctrl/Cmd+Z, Ctrl/Cmd+Shift+Z, Ctrl+Y | The sheet's undo and redo. |
| Editor | Enter (unless `handlesKey`), `onCommit({ move: [1, 0] })` | Commits; focus goes to the next field's box. |
| Editor | Tab / Shift+Tab | Commits; the browser's own tab order moves on. |
| Editor | Escape | Cancels; focus back on the box. (The shell closes only on an Escape pressed on a box or elsewhere.) |
| Editor | Focus leaves it | Commits (the shared focus-out logic). |

- Every commit builds its change set with `commitText`/`commitValue` on
  a one-record context (`records: [record]`, `fields`: visible and
  hidden), source `'edit'`, and goes through `emit`: undoable, validated,
  rejections stored and shown under the box with the field's other errors
  (the same merge as `cellView`, refactored to `cellViewFor(record, field)`).
- Read-only fields show the box without the button role.
- When the record leaves `@records` (deleted, or an owner's re-query) the
  shell closes (`onExpandedRecordChange(null)`).
- On close, `api.setFocusedCell` returns focus to the cell it was opened
  from when that row still exists (the grid's own advice, `types.ts`
  `setFocusedCell` comment).

### 5.8 Interaction with existing features

- **Undo/redo**: 5.6. A later undo of an older edit on a deleted record
  is skipped by the conflict rule (the record is gone) and works again
  if the delete is undone first.
- **Selection and drag**: a press on a row number starts the same drag
  logic as a cell press (`dragFrom`, `onRelease`, `suppressClick`), with
  `rangeKind = 'rows'`. A press on the checkbox or expand span never
  starts a drag (like the opener: `eui-sheet.gts:595`).
- **Clicks**: the Airtable-style rules are unchanged on data cells. The
  add row and the row-number cells are handled before them in `onClick`.
- **Validation**: `@validate` runs after inserts and deletes as after any
  change set; `changed` lists an inserted row's fields (already the case
  for paste inserts, `eui-sheet.gts:1202-1206`). A new empty row shows
  `required` errors at once, as a pasted row does.
- **Rejections and the error box**: rejections of deleted records are
  dropped by `emit`. Focus on a row-number cell, the add row or a menu
  hides the error box (`onFocusIn` on a non-data cell already does).
- **Editor frame**: opening the menu or the form moves focus out of an
  open editor, which commits it first (existing focus-out rule).
- **As a results view**: with `@canInsert={{false}}` and
  `@canDelete={{false}}` the sheet only edits cells. Inserts and deletes
  are change sets the owner applies through its API.

### 5.9 Tests

| File | Cases |
| --- | --- |
| `eui-sheet-rows-test.gts` (new) | RW1 row numbers show positions, `@rowNumberOffset` shifts them, `@rowLabel` replaces them, `@rowNumbers={{false}}` removes the column, data cells still report the right fields; RW2 click a row number selects the row, Shift+click extends, Delete clears those cells; RW3 header click selects the column, copy gives one column, the actions button still opens its menu; RW4 checkbox toggles, Shift+click range, header checkbox, `@checkedRecordIds` controlled; RW5 add row: click inserts at the end with focus on the new row's first editable cell, the exact change set; RW6 Shift+Enter inserts below with `anchor`, focus on the new row; RW7 menu: each item's change set; right-click outside the range moves the selection; Escape re-focuses the cell; RW8 delete then Ctrl+Z restores the same objects at the same indexes, Ctrl+Shift+Z deletes again; RW9 duplicate copies writable fields only; RW10 `@readOnly`, `canInsert`, `canDelete` hide the add row and the items; RW11 paste on the add row inserts; RW12 `@rowActions` gets the records; RW13 the control cells contain no tabbable element (`tabbable(cell).length === 0`); RW14 `@newRecordValues`; RW15 Home and Ctrl+Home land on the first field, ArrowLeft reaches the row-number cell and clears the range (C13). |
| `eui-sheet-record-test.gts` (new) | RF1 Space opens the flyout with the visible then the hidden fields; RF2 type in a text box: editor inline, Enter saves and focuses the next box, one change set; RF3 select field: panel in flow, pick with the keyboard; RF4 checkbox box: click and Space toggle; RF5 a rejected text shows under the box and in the grid cell; RF6 `@validate` and `@cellErrors` show; RF7 read-only field; RF8 previous/next; RF9 close returns focus to the cell; RF10 controlled `@expandedRecordId`; RF11 Ctrl+Z in the form undoes; RF12 only one editor is mounted at a time; RF13 the record leaves `@records`: the form closes; RF14 `@expandedRecord="modal"` renders the same form in a modal, RF2 and RF9 again. |
| `eui-sheet-history-test.gts` (extend) | U9 insert → undo → redo; U10 delete of 3 rows in the middle → undo keeps their order. |

### 5.10 Docs

`sheet.md`: sections "Records" (row numbers and `@rowLabel`, selection
kinds, menu), "Expanded record" (flyout or modal); keyboard and mouse
tables; arguments table. Demos: `d10-records.md` (add, delete,
duplicate, menu, a `@rowActions` item, `@rowLabel` switch, the change-set
log) and `d11-expanded-record.md` (flyout/modal switch, hidden fields in
the form). README: same sections, shorter.

### 5.11 Risks

- **Focus**: the row-number cell is a grid cell; the grid adds a focus
  trap to cells with tabbable children (`cell.gts:505`, `renderFocusTrap`).
  RW13 guards it.
- **Flyout and modal focus**: their focus traps and the editors' own
  `focus()` on mount; an editor surface rendered in a wormhole from
  inside them (flatpickr) must still count as "in the editor"
  (`EDITOR_SURFACE_SELECTOR` already covers it). Not run here; two shells
  double this check.
- **Virtualization**: `pendingFocus` on a row far from the viewport
  relies on `setFocusedCell` scrolling it into view (the grid does:
  `body.onFocusedCellChange`).
- **Performance**: the checked set is a `Set<string>`; the row-number
  cell reads one `has`.
- **a11y**: checkbox and expand spans are not focusable; the keys of 5.5
  on the row-number cell are their keyboard path, and the cell gets
  `aria-label` (`messages.rowNumber(n)`) and `aria-selected` through
  `setCellProps`.

## 6. Batch 3: view intents, blocks, summary bar, frozen field

### 6.1 Scope

Everything of 3.5 and the blocks of 3.6: sort arrows and the header
menu, presentation intents with their local fallbacks, the `<:toolbar>`
and `<:footer>` blocks, the highlighted term, the loading bar, field
descriptions, the owner-provided summary bar, and the frozen primary
field (section 9). No toolbar, no filter builder, no search box.

| File | Change |
| --- | --- |
| `src/components/eui-sheet.gts` | The arguments, fallbacks, `@sorting`, column `actions`, blocks, footer wiring, `columnWidths`, frozen styles and focus correction, `virtualizationOptions`. |
| `src/-private/sheet-cell.gts` | Highlight, frozen style. |
| `src/-private/footer-cell.gts` (new) | Summary cell. |
| `src/-private/row-number-cell.gts` | Frozen style. |
| `src/core/summary.ts` (new) | `summarize` helper (6.6). |
| `src/core/types.ts`, `src/types.ts` | Field and type additions (6.2), `SheetBlockApi`. |
| `src/-private/styles.ts`, `theme.ts` | Highlight, footer, frozen classes. |

### 6.2 Field and field-type additions (additive)

```ts
// EuiSheetField
description?: string;      // header tooltip, form help text
width?: number;            // default width; `@fieldWidths[id]` wins
sortable?: boolean;        // default true: shows the sort items when @onSortChange is passed
hideable?: boolean;        // default true; the first field is never hideable

// EuiSheetFieldType (Ember layer)
/** The grid schema of the column ('numeric', 'datetime', 'boolean', 'currency'): sort labels and header icon. */
schema?: string;

// SheetCellSignature.Args
highlight?: string;        // `@highlight`, for cells that mark matches themselves
```

Built-ins: number `schema: 'numeric'`, checkbox `'boolean'`, date
`'datetime'` (names exist in `utils/data-grid/schema.ts`).

### 6.3 Sort and the header menu

- With `@onSortChange`: the sheet passes `@sorting={ columns:
  sort.map(({ field, direction }) => ({ id: field, direction })), onSort
  }`; `onSort` maps back to `SheetSort[]` and calls `@onSortChange`. The
  grid appends a sort when one exists (`column-actions.gts:292-311`), so
  a multi-key sort goes out as the full list; an owner that wants one key
  keeps the last item.
- Column `actions` (`EuiDataGridColumnActions`, `types.ts`):

| Item | Shown when | Does |
| --- | --- | --- |
| Sort A-Z / Z-A (grid built-in, `showSortAsc`/`showSortDesc`) | `@onSortChange` and `field.sortable !== false` | `@onSortChange` |
| Hide (`showHide`) | not the first field, `field.hideable !== false` | `@onHiddenFieldsChange(ids)`, or the local fallback |
| Move left / right (`showMoveLeft`/`showMoveRight`) | not the first field, and not past it | `@onFieldOrderChange(ids)`, or the local fallback |
| Filter by this field (`additional`, icon `filter`) | `@onFilterByField` | `@onFilterByField(fieldId)` |

  The grid calls `columnVisibility.setVisibleColumns(ids)` for hide and
  move. The sheet compares `ids` with the current visible ids: an id
  missing → hide intent; a different order → order intent.
- Description: a column with `field.description` gets `display`: a
  template-only component made per field (a closure, cached by field id,
  label and description, since the grid renders `<Display />` without
  arguments, `header-cell.gts:498`). It renders the label and
  `EuiIconTip @content={{description}}` (exists in core). The header cell
  already has a tabbable child (the actions button), so this adds no new
  focus behaviour.

### 6.4 Presentation state

- Visible fields: `@fields`, as given. Hidden fields: `@hiddenFields`.
  Local fallback (no handler): a tracked hidden-id set and order, applied
  over `@fields` as v0.1's `order` did.
- Widths: column `initialWidth = @fieldWidths[id] ?? field.width`. The
  grid keeps a column's width itself once rendered (`body-base.ts`
  `columnWidths` reads `initialWidth` when the columns change), and calls
  `@onColumnResize`, which the sheet forwards as `@onFieldWidthChange`.
  Whether a changed `@fieldWidths` value re-applies to an existing column
  was not read; if it does not, the sheet gives the column a new object
  when its width argument changes (to check: N6).
- Row height → grid `@rowHeightsOptions`: `short` none; `medium`
  `{ defaultHeight: { lineCount: 2 } }`; `tall` 4; `extraTall` 6. Only
  the block API's `setRowHeight` changes it (there is no built-in
  control): it calls `@onRowHeightChange`, or sets the local value.
- Blocks: `<:toolbar>` renders in a `div.euiSheet__toolbar` above the
  grid, `<:footer>` in `div.euiSheet__footer` below it, both inside the
  wrapper (so they get the theme class) and outside the grid (their
  controls are normal tabbable elements). Each yields `SheetBlockApi`
  (3.6). Nothing renders without the block.
- `@isLoading`: `EuiProgress @size="xs" @position="absolute"` (exists in
  core; arguments to check) at the top of the wrapper. The grid stays
  interactive.

### 6.5 Highlight

`@highlight` is a string. A cell without a cell component renders its
text with `EuiHighlight @search={{@highlight}}` (exists in core;
case-insensitive by default); cell components receive `@highlight` and
may use it. Nothing else: no match list, no navigation, no Ctrl/Cmd+F.
With an empty or missing value the text renders as today.

### 6.6 Summary bar (owner-provided)

- `@summary: Record<fieldId, string>`. Passing it (even `{}`) shows the
  grid's footer row; each footer cell shows its field's text, or nothing.
  The control column's footer cell shows `@summary['']` if given (the
  owner may put the total count there).
- The sheet computes nothing: with a paging backend an aggregate over the
  loaded page is wrong. The owner takes values from its backend's
  aggregations (`SearchResult.aggregations`), or computes them when it
  has every record.
- For the second case the core exports a pure helper, which the sheet
  never calls:

```ts
export type SheetSummaryKind =
  | 'count' | 'filled' | 'empty' | 'percentFilled' | 'unique'
  | 'sum' | 'average' | 'min' | 'max' | 'checked' | 'unchecked';
/** The text of one summary over `records`, formatted with the field's type. */
export function summarize<T>(ctx: Pick<SheetContext<T>, 'types' | 'messages'>, records: readonly T[], field: EuiSheetField<T>, kind: SheetSummaryKind): string;
// FieldType
toNumber?(value: V | null | undefined, field: F): number | null;   // for sum, average, min, max
```

  `count` is the number of records; `filled`/`empty` by `isEmptyValue`;
  `unique` by `copyText`; `sum`/`average`/`min`/`max` over `toNumber`
  (dates: `compare`) of non-empty values, formatted with `type.format`;
  `checked`/`unchecked` count `value === true`.
- UI: `@renderFooterCellValue={{SheetFooterCell}}` and
  `<:controlFooterCell>`; sticky by default
  (`startingStyles.stickyFooter`). Footer cells are already ignored by
  `dataCell()` (`eui-sheet.gts:423-428`): no edits, no range. They are
  plain text; choosing what to summarize is the app's control in
  `<:toolbar>` or `<:footer>`.

### 6.7 Frozen primary field

`@frozenFields?: number` (default 1; 0 off). The row-number column is
frozen too whenever any field is. The first field cannot be hidden or
moved (6.3). Mechanism, acceptance test and fallback: section 9.

### 6.8 Interaction with existing features

- **Undo/redo, paste, fill, clear**: unchanged; they work on `@records`.
- **An owner's re-query** (sort intent answered, page change): 3.2.
- **Hidden fields**: copy, paste and ranges use `@fields` only. The
  expanded record edits hidden fields too. Rejections and errors of a
  hidden field show in the form only.
- **Editing and widths**: resizing a column while an editor is open
  blurs the editor (commit), as any click outside does.
- **Error box and editor frame over frozen cells**: frozen cells use
  `z-index: 2` inside the grid's scroll element, which is its own
  stacking context (`will-change:transform`, `body.gts` `outerStyle`), so
  they should stay under the frame and the box, which are siblings of the
  grid. Not run: FZ6 checks the editor.
- **Validation**: unchanged.

### 6.9 Tests

| File | Cases |
| --- | --- |
| `eui-sheet-view-test.gts` (new) | VW1 without `@onSortChange` the header menu has no sort items and no arrow even with `@sort`; VW2 with it: "Sort A-Z" calls it with `[{ field, direction: 'asc' }]`, the rows do not move, the arrow shows only once `@sort` is updated; VW3 a second sort goes out as two items; VW4 hide with `@onHiddenFieldsChange`: called with the ids, the column stays until `@fields` changes; VW5 hide without a handler: the column goes (C6), copy excludes it; VW6 move left/right: `@onFieldOrderChange`, and the local fallback; the first field has neither item; VW7 `@onFilterByField` shows the item and gets the id; VW8 `@fieldWidths` sets widths, a resize calls `@onFieldWidthChange`; VW9 `@rowHeight` changes the row's and the editor's height; the block's `setRowHeight` calls the handler or the fallback; VW10 `<:toolbar>` and `<:footer>` render with the block API (`hideField`, `showField`, `checkedRecords`); nothing without the blocks; VW11 `@highlight` marks the text in plain cells and reaches a custom cell; VW12 `@isLoading` shows the bar and editing still works; VW13 description tooltip in the header and in the form. |
| `tests/unit/summary-test.ts` (new) | SM1 each kind on numbers with empties; SM2 date min/max; SM3 checkbox; SM4 unique; SM5 formatted through the type. |
| `eui-sheet-summary-test.gts` (new) | SU1 `@summary` shows a footer with the texts under their fields; SU2 no `@summary`, no footer; SU3 footer cells take no edits and no range; SU4 the owner updates the object: the cells update. |
| `eui-sheet-frozen-test.gts` (new) | Section 9.3. |

### 6.10 Docs

`sheet.md`: "The owner" (what the sheet never does, the intents table of
3.5, the blocks), "Presentation state" (controlled with a handler, local
without), "Summary bar", "Frozen field" with its limit. Demos:
`d12-view-intents.md`: a sheet owned by a small demo class that answers
`onSortChange` by sorting its array, keeps hidden fields, order, widths
and row height, with a field picker and a row-height control in
`<:toolbar>` and an intents log; `d13-summary.md`: `@summary` computed
with `summarize` over all records. `d08-large-data.md` gains a frozen
field with 30 columns to show the cost. "Not yet" loses frozen columns
and row numbers, and says that sorting, filtering, search and grouping
are the owner's.

### 6.11 Risks

- **Controlled arguments not updated**: an owner that passes a handler
  and forgets to update the argument sees nothing happen. The docs say
  so, and in development the sheet warns once when a handler was called
  and its argument is unchanged on the next render.
- **Sort labels**: the grid's sort item labels depend on the column
  schema (N5).
- **Performance**: `EuiHighlight` per plain cell only while `@highlight`
  is non-empty.
- **a11y**: sort state is announced by the grid's own header
  (`aria-sort`).
- Frozen field: section 9.

## 7. Batch 4: the EmberSearchUi connector

### 7.1 Where it lives

An optional entry of the sheet package: **`@ember-eui/sheet/search-ui`**.
The package's `./*` export maps it to `dist/search-ui.js`, not to
`dist/search-ui/index.js`, so it gets its own `exports` entry, like
`./core` (`packages/sheet/package.json:45-48`). The rollup config needs
no change: `addon.publicEntrypoints(['**/*.js', …])` already emits every
source file (`rollup.config.mjs`).

| File | Change |
| --- | --- |
| `src/search-ui/index.ts` (new) | Barrel: `searchRecords`, `SearchRecords`, `fieldsFromSchema`, `EuiSheetSearch`, the types. |
| `src/search-ui/search-records.ts` (new) | The class of 7.2 and 7.3 (`@glimmer/tracking`, `@ember/destroyable`, `@ember/test-waiters`). |
| `src/search-ui/fields-from-schema.ts` (new) | Plain function. |
| `src/search-ui/eui-sheet-search.gts` (new) | The component. Not app-re-exported (`appReexports` covers `components/**` only); it is imported in `.gts`. |
| `src/core/messages.ts` | New token `euiSheet.reapply` ("Re-apply"), in `sheetMessageTokens` with the others. |
| `package.json` | `exports["./search-ui"] = { types: "./declarations/search-ui/index.d.ts", default: "./dist/search-ui/index.js" }`; devDependency `ember-search-ui-driver` (7.5). No peer, no dependency. |
| `pnpm-lock.yaml` | Changes with the devDependency. As in v0.1, the implementer reports the diff instead of committing it (the install runs on the Mac). |
| `scripts/dist-hygiene.test.mjs` | Lists `'sheet'` already (line 106); what it checks about entries was not read: run it after the build. |
| `site/package.json`, `site` demo files | 7.5. |

The connector
It imports nothing from EmberSearchUi at run time or in its types: it is
written against a structural interface (7.2) that `SearchDriver`
satisfies. So `@ember-eui/sheet` gains no dependency and no peer, and
EmberSearchUi does not learn about the sheet.

Why not in `ember-search-ui-views`: that package would need
`@ember-eui/sheet` and `@ember-eui/core` as peers; its other views have
no EUI dependency (its peers are `ember-power-select`,
`ember-basic-dropdown`, `ember-concurrency`: `ember-search-ui-views/package.json`).
Why not docs only: the mapping has rules that are easy to get wrong
(below) and the "stable + Re-apply" behaviour needs code.

`ember-search-ui-driver` is a **devDependency** of the sheet package,
for one type test (`SearchDriver` is assignable to the interface) and for
integration tests with the real `memoryBackend`. Version 2.0.0-beta.2
resolves from a registry in another local project's lockfile (7.5).

### 7.2 Contract

```ts
// @ember-eui/sheet/search-ui

/** The part of ember-search-ui-driver's SearchDriver the connector uses. */
export interface SheetSearchDriver<Doc = unknown> {
  readonly snapshot: {
    readonly state: {
      readonly query: { readonly term: string };
      readonly sort: readonly SheetSort[];
      readonly page:
        | { readonly kind: 'offset'; readonly page: number; readonly perPage: number }
        | { readonly kind: 'cursor'; readonly cursor: string | null; readonly size: number };
    };
    readonly result: {
      readonly status: 'idle' | 'loading' | 'success' | 'error';
      readonly results: readonly Doc[];
      readonly total: number;
      readonly pageCount: number;
      readonly aggregations: Readonly<Record<string, unknown>>;
      readonly error?: unknown;
    };
  };
  readonly schema?: Readonly<Record<string, SheetSearchFieldDefinition>>;
  subscribe(listener: (snapshot: SheetSearchDriver<Doc>['snapshot']) => void, options?: { immediate?: boolean }): () => void;
  setSort(sort: readonly SheetSort[]): void;
  setPage(page: number): void;
  setPerPage(perPage: number): void;
  refresh(): Promise<void>;
}
export interface SheetSearchFieldDefinition {
  path: string; type: string; label?: string;
  options?: readonly { value: string | number | boolean | null; label: string }[];
}

export interface SearchRecordsOptions<Doc> {
  getRecordId: (record: Doc) => RecordId;
  /** Persists a change set (API call, or writing the memory backend's docs). May return a promise. */
  onChange: (changeSet: ChangeSet) => void | Promise<void>;
  /** For the rows shown before the next search. Default: `{ id: tempId, ...values }`. */
  createRecord?: (values: Record<string, unknown>, tempId: string) => Doc;
  /** Re-query after every change set instead of waiting for "Re-apply". Default false. */
  refreshOnChange?: boolean;
}

/** The driver as sheet arguments. Tied to `owner`'s lifetime (unsubscribes on destroy; never destroys the driver). */
export function searchRecords<Doc extends object>(owner: object, driver: SheetSearchDriver<Doc>, options: SearchRecordsOptions<Doc>): SearchRecords<Doc>;

export class SearchRecords<Doc extends object> {
  /** The last results with the user's change sets since then applied on top. */
  get records(): Doc[];
  get sort(): SheetSort[];
  get term(): string;                 // for @highlight
  get isLoading(): boolean;
  get error(): unknown;
  get total(): number;
  /** Offset paging only; undefined under cursor paging. */
  get page(): { page: number; perPage: number; pageCount: number } | undefined;
  /** (page - 1) * perPage, or 0. */
  get rowNumberOffset(): number;
  /** Edits were made since the last search: the rows may no longer match the query. */
  get isStale(): boolean;
  apply: (changeSet: ChangeSet) => void;       // @onChange
  setSort: (sort: SheetSort[]) => void;        // @onSortChange
  setPage: (page: number) => void;             // 1-based; no-op under cursor paging
  setPerPage: (perPage: number) => void;
  /** Waits for pending `onChange` promises, then `driver.refresh()`. */
  reapply: () => Promise<void>;
}

/** Default fields from the driver's schema, for an owner that passes none. */
export function fieldsFromSchema(schema: SheetSearchDriver['schema']): EuiSheetField[];
```

Component `EuiSheetSearch` (`src/search-ui/eui-sheet-search.gts`):

```ts
Args: {
  driver: SheetSearchDriver<Doc>;
  getRecordId: (record: Doc) => RecordId;
  onChange: SearchRecordsOptions<Doc>['onChange'];
  createRecord?: SearchRecordsOptions<Doc>['createRecord'];
  refreshOnChange?: boolean;
  /** Default: fieldsFromSchema(driver.schema). */
  fields?: EuiSheetField<Doc>[];
  /** Shows EuiTablePagination in the footer under offset paging. Default true. */
  paging?: boolean;
  /** Passed to EuiSheet as they are: */
  hiddenFields?; onHiddenFieldsChange?; onFieldOrderChange?; fieldWidths?; onFieldWidthChange?;
  rowHeight?; onRowHeightChange?; frozenFields?; summary?; onFilterByField?;
  readOnly?; canInsert?; canDelete?; cellErrors?; validate?; fieldTypes?; messages?; height?;
  rowNumbers?; rowLabel?; rowActions?; newRecordValues?; expandedRecord?; expandedRecordId?;
  onExpandedRecordChange?; checkedRecordIds?; onCheckedChange?; onResolve?; registerApi?; ariaLabel?;
}
Blocks: {
  toolbar: [SheetBlockApi & { search: SearchRecords<Doc> }];
  footer: [SheetBlockApi & { search: SearchRecords<Doc> }];
}
```

It renders `EuiSheet` with `@records={{search.records}}`, `@sort`,
`@onSortChange`, `@onChange={{search.apply}}`, `@highlight={{search.term}}`,
`@isLoading`, `@rowNumberOffset`, and:

- in the toolbar area, before the app's `<:toolbar>` content: when
  `search.isStale`, an `EuiButtonEmpty @iconType="refresh"` "Re-apply"
  (`messages.reapply()`), which calls `search.reapply`;
- in the footer area, before the app's `<:footer>` content: under offset
  paging and `@paging` not false, `EuiTablePagination` (`@activePage`,
  `@pageCount`, `@itemsPerPage`, `@onChangePage`, `@onChangeItemsPerPage`:
  arguments exist in `eui-table-pagination.gts`; whether `activePage` is
  0-based is to check).

An app that needs an `EuiSheet` argument the component does not forward
uses `searchRecords` with its own `<EuiSheet>`; the component is that
plus the two default controls.

### 7.3 Mapping rules

| Sheet | Driver | Rule |
| --- | --- | --- |
| `@records` | `snapshot.result.results` | Plus the overlay below. While `status` is `'loading'` the previous results stay (the driver keeps them in the snapshot or not: to check, N8; the connector keeps its own last successful results). |
| `@sort` | `snapshot.state.sort` | Same shape (`SortItem`, `types.ts:83-86`). |
| `onSortChange` | `driver.setSort(sort)` | Resets to page 1 (`driver.ts` `setSort`: `page: firstPage(...)`). |
| `@highlight` | `snapshot.state.query.term` | |
| `@isLoading` | `result.status === 'loading'` | |
| `@rowNumberOffset` | `(page.page - 1) * page.perPage` | 0 under cursor paging. |
| paging | `driver.setPage(n)`, `driver.setPerPage(n)` | `setPage` is 1-based (`Math.max(1, page)`) and throws under cursor paging (`driver.ts:232-236`), so the connector never calls it then and renders no pager; the app pages in `<:footer>`. |
| `@summary` | nothing by default | The app maps `result.aggregations` to texts and passes `@summary`. |
| `@fields` | `driver.schema` | `fieldsFromSchema`: `keyword` with `options` → `singleSelect`; `keyword`, `text`, unknown → `text`; `number` → `number`; `date` → `date`; `boolean` → `checkbox`; `label` → `label`; `nested` and `geo` fields are left out. The schema gives only default fields (no widths, no validation, no read-only): an app with real requirements passes `@fields`. |
| `onChange` | `options.onChange`, then nothing | The driver has no patch method. The connector does not re-query (V4). |

The overlay and "stable + Re-apply":

- `apply(changeSet)`: pushes the change set on `pending`, calls
  `options.onChange` and keeps its promise if it returns one.
  `records` is a tracked array: each `apply` sets it to
  `applyChangeSet(records, changeSet, { getRecordId, createRecord })`
  (one change set over the previous overlay, not all of them again), and
  a new result resets it. So an edit shows at once and rows do not move,
  vanish or re-sort.
- New ids: a server-backed app that gives inserted records real ids
  tells the sheet with `api.remapIds` (from `@registerApi`), as with any
  owner. The connector adds nothing here: after "Re-apply" the results
  carry the real ids, and until then the overlay shows the rows under
  their `tempId`.
- `isStale` is `pending.length > 0`.
- When the driver delivers a new successful result (any reason: sort,
  filter, page, `refresh`), `lastResults` is replaced and `pending` is
  emptied: the backend is the truth again. If an `onChange` promise is
  still running at that moment the result may be older than the edit;
  `reapply` avoids that by waiting for them, and the connector also calls
  `driver.refresh()` once after such a promise settles when a search
  completed while it was running.
- `refreshOnChange: true` calls `reapply()` after each change set
  (the live behaviour).
- A rejected `onChange` promise: the change set stays in the overlay and
  the error is re-thrown to the app's error handling; the connector does
  not undo anything (the app may call the sheet's `api.undo()`).
- Undo history: by record id, kept across searches. An entry whose
  record is not on the current page is skipped (3.4), and stays on the
  stack. The connector does not clear history; an app that prefers that
  calls `api.clearHistory()` on a page change.
- Inserted rows show at their index in the overlay; after "Re-apply"
  they are wherever the backend's query puts them, or nowhere.
- Reactivity: `SearchRecords` holds the snapshot in one `@tracked` field
  set from `driver.subscribe` (as `TrackedSearch` does,
  `ember-search-ui/src/tracked-search.ts`), and registers a test waiter
  while `status` is `'loading'` or an `onChange` promise runs.

### 7.4 Tests

| File | Cases |
| --- | --- |
| `tests/unit/search-records-test.ts` (new; a hand-written fake driver that implements `SheetSearchDriver`) | SR1 `records`, `sort`, `term`, `isLoading`, `total`, `page`, `rowNumberOffset` from snapshots; SR2 `apply` shows the edit over the results, `isStale` true, `onChange` called once, no `refresh`; SR3 a new result empties the overlay; SR4 `reapply` waits for a pending `onChange` promise before `refresh`; SR5 a search that completes while `onChange` runs is followed by one refresh; SR6 `refreshOnChange`; SR7 cursor paging: `page` undefined, `setPage` does not call the driver; SR8 inserts and deletes in the overlay (index, anchor, `createRecord`); SR9 `fieldsFromSchema` per type; SR10 unsubscribes on destroy and does not destroy the driver. |
| `tests/unit/search-driver-types-test.ts` (new; needs the devDependency) | A real `SearchDriver` with `memoryBackend` is assignable to `SheetSearchDriver` (compile-time), and SR1 to SR3 again against it. |
| `tests/integration/components/eui-sheet-search-test.gts` (new) | SS1 renders the results; SS2 header "Sort A-Z" calls `setSort`, new results render, the arrow shows; SS3 an edit stays in place under a sort on that field, "Re-apply" appears, clicking it re-queries and the row moves, focus follows the record (3.2); SS4 pagination: page 2 shows row numbers from `perPage + 1`; SS5 the query term is highlighted; SS6 the app's `<:toolbar>` and `<:footer>` content render after the default controls and get `search`; SS7 `@paging={{false}}`; SS8 an edit, then a page change and Ctrl+Z: skipped, nothing emitted, back on page 1 Ctrl+Z works; SS9 results arrive (a slow search) while an editor is open with a draft: the editor stays on its record and Enter saves to it; when the record is not in the new results the editor closes without a change set. |

If the devDependency cannot be installed (7.5), the second file is left
out and reported; the first and third run on the fake driver.

### 7.5 Docs demo "Sheet with EmberSearchUi"

`docs/sheet-demo/d14-search-ui.md`:

- 2,000 generated docs in a tracked store; `new SearchDriver({ backend:
  memoryBackend(() => store.docs, { latencyMs: 150 }), schema,
  initialState: { page: { kind: 'offset', page: 1, perPage: 50 } } })`
  (`memoryBackend` takes a function, `memory-backend.ts:36-38`, so it
  reads the docs at each search).
- `<EuiSheetSearch @driver @getRecordId @onChange={{this.write}} @fields>`
  where `write` is `store.docs = applyChangeSet(store.docs, changeSet,
  …)`: the anchors of 3.4 put inserts at the right place in the full
  array, although the sheet only saw one page.
- `<:toolbar>`: EmberSearchUi views bound to the same driver: `SearchBox`,
  `Sorting`, a `Facet` on the select field and `FilterChips`
  (`ember-search-ui-views/src/components/`), inside the `Search` provider
  of `ember-search-ui`. Plus the default "Re-apply".
- `<:footer>`: the default pagination, and `PagingInfo`.
- A text under the demo walks through: sort by a column from the header
  (the driver sorts), edit a cell in the sorted column (the row stays;
  "Re-apply" moves it), search a term (highlighted), go to page 2 (row
  numbers continue), insert a row (it appears; after "Re-apply" it is
  where the sort puts it).

What the site needs, and what could not be verified:

- `site/package.json` today depends only on the workspace packages and
  has no EmberSearchUi entry; `pnpm-lock.yaml` has none either.
- The EmberSearchUi packages are in another repository
  (`~/prysmex/ember-search-ui/packages/`): `ember-search-ui-driver`
  2.0.0-beta.2 (plain TypeScript, no Ember, no peers), `ember-search-ui`
  2.0.0-beta.2 (peers `@elastic/search-ui`, `@glimmer/component`,
  `tracked-built-ins`), `ember-search-ui-views` 2.0.0 (peers
  `ember-power-select`, `ember-basic-dropdown`, `ember-concurrency`, the
  other two). None is marked `private`, and their `repository` is
  `bengala-tech/ember-search-ui`. No network was used. Offline evidence:
  `~/prysmex/m3-refactor/pnpm-lock.yaml` resolves
  `ember-search-ui@2.0.0-beta.2` and `ember-search-ui-driver@2.0.0-beta.2`
  with integrity hashes and no tarball or link (lines 8772-8782), and
  both are in its `node_modules/.pnpm`, so those two were installed from
  a registry. **`ember-search-ui-views` appears in no local lockfile**:
  whether it is published, and whether its peers build in the docs site,
  is not verified.
- Plan: the site adds `ember-search-ui-driver` and `ember-search-ui`
  (and `@elastic/search-ui`, `tracked-built-ins`, its peers), then
  `ember-search-ui-views` and its peers. If the views are not published,
  too heavy, or do not build in the site, the demo's toolbar uses small
  EUI controls wired to the driver instead (`EuiFieldSearch` →
  `driver.setQuery`, an `EuiSelect` for sort, `EuiFilterGroup` buttons
  that call `driver.add`/`remove`), and says so (Q16). Either way the
  lockfile changes, which the earlier batches reported instead of
  committing.

### 7.6 Group by: deferred to v0.3, and why

Grouping only the loaded page is wrong once the backend pages: counts
are per page, a group is split across pages, and collapsing hides rows
the next page continues. So the owner must provide the groups, and today
no owner can: the driver's state has no group-by, `memoryBackend` returns
only `{ results, total }` (no aggregations, `memory-backend.ts:27-30`),
and the server codecs expose facets, not grouped pages. Designing
`@groups` now would fix a contract with no implementation on the other
side to test it against.

What v0.3 would need, so nothing in v0.2 blocks it: an owner-provided
list of group headers interleaved with the records (`@groups: Array<{
key, label, count, beforeRecordId, collapsed }>`), an
`onGroupToggle(key)` intent, group rows as a third row kind next to
records and the add row (positions then stop being record indexes: the
mapping layer this design dropped comes back), and group-by support in
the driver and at least the memory backend. The summary bar is not
deferred, because an owner can already provide its values (6.6).

### 7.7 Risks

- **Stale overlay**: the overlay shows what the user typed, not what the
  server stored (a server that normalizes a value). "Re-apply" or the
  next search corrects it.
- **Races**: a search result arriving between an edit and its
  persistence (7.3). SR4 and SR5 cover the two orders.
- **Structural typing**: a driver release that renames a member breaks
  the connector at the app's compile time, not the sheet's. The type test
  catches it when the devDependency is updated.
- **Performance**: the overlay re-applies every pending change set over
  the page on each new one (page of 50 to 500 rows, tens of change sets:
  small). Merge them with `mergeChangeSets` if it shows up.
- **Undo across pages**: skipped entries stay on the stack, which can
  surprise (Ctrl+Z "does nothing" on another page). Q17.

## 8. Batches 5 and 6

### 8.1 Batch 5: field types

All are built in and registered in `builtInSheetFieldTypes` under the
names below (an app type of the same name in `@fieldTypes` still wins).
Core part in `src/core/field-types/<name>.ts`, cell in
`src/-private/cells/`, editor in `src/-private/editors/`.

Contract additions (additive):

```ts
// ParseResult: the value variant gains newOptions
| { value: V; newOption?: SheetOption; newOptions?: SheetOption[] }

// FieldType
/** Value equality, for "unchanged" checks. Default Object.is. Used by commitText, commitValue, clearRange, pasteMatrix, fillDown and withoutConflicts instead of Object.is. */
equals?(a: V | null | undefined, b: V | null | undefined): boolean;
/** For a type whose parse returns { unresolved }. */
resolve?: {
  /** The texts of one cell to resolve. Default: [text]. */
  parts(text: string, field: F, context: ParseContext): string[];
  /** The cell's value from its resolved parts (value null: no match). */
  combine(parts: Array<{ text: string; value: unknown | null }>, field: F, context: ParseContext): ParseResult<V>;
};
/** The link a value opens (url, email, phone). Only http:, https:, mailto: and tel: are opened. */
link?(value: V | null | undefined, field: F): string | undefined;

// EuiSheetFieldType
editorLayout?: 'cell' | 'panel' | 'expand';   // 'expand': starts at the cell, grows (long text)
```

| Type (name) | Stored value | Field options | Cell | Editor | Parse / paste | copyText | In the form |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `multiSelect` | `Array<string \| number>` | `options`, `createOnPaste` | `EuiBadge` chips, clipped, "+N" | `EuiSelectable` (multi, searchable) in a panel; Enter toggles the current option; Tab or blur commits; Escape cancels | Split on `,` (a part in double quotes keeps its commas), trim; each part as singleSelect (label, then value); unknown part: `newOptions` with `createOnPaste`, else error `notAnOption(part)`; `''` → `[]` | Labels joined by `, ` | Same editor, in flow |
| `linkedRecord` | `Array<{ id: RecordId; label: string }>` | `search(query, { record, signal }): Promise<Array<{ id, label }>>`, `multiple?` (default true) | Chips from `label` | Async `EuiSelectable` (`@isPreFiltered`, `@isLoading`, `@errorMessage`, as demo d04), chosen ones first | `{ unresolved: text }`; `resolve.parts` splits on `,`; `combine` builds the array, error `unresolved(part)` for a `null` | Labels joined by `, ` | Same |
| `user` | `{ id, label, avatarUrl? }`, or an array with `multiple: true` | `options?` (sync list) or `search`, `multiple?` | `EuiAvatar @size="s"` + name | As linkedRecord (sync list when `options`) | With `options`: match by label or `email`, else error; without: unresolved | Labels | Same |
| `attachment` | `Array<{ id: string; name: string; url: string; type?: string; size?: number; thumbnailUrl?: string }>` | `upload(files: File[], context: { record, field, signal }): Promise<SheetAttachment[]>`, `accept?`, `maxFiles?` | Thumbnails (`thumbnailUrl`, or `url` when `type` starts with `image/`), else a file icon and the name; "+N" | Panel: the list with open links (`target="_blank" rel="noopener noreferrer"`), remove buttons, `EuiFilePicker`; each upload or removal commits `{ value }` and stays open | Text: error `notAnAttachment()`. Files in the clipboard on an attachment cell: uploaded. `''` → `[]` | URLs joined by `, ` (the one type where `parse(copyText(v))` does not give `v`) | Same panel, in flow |
| `currency` | `number \| null` | `currency` (ISO code), `locale?`, `precision?` (default 2), `min`, `max` | `Intl.NumberFormat` currency text | `InputEditor` | Strips the symbol, code and spaces, then as number | Plain number | Same |
| `percent` | `number \| null`, a fraction (`0.25` shows `25%`) | `precision?` (default 0), `min`, `max` | `25%` | `InputEditor` | `25%` or `25` → `0.25` | `25%` | Same |
| `duration` | `number \| null`, seconds | `durationFormat?: 'h:mm' \| 'h:mm:ss'` (default `'h:mm'`) | `1:30` | `InputEditor` | `1:30`, `1:30:00`, `1h 30m`, `90` (minutes with `'h:mm'`, seconds with `'h:mm:ss'`) | The formatted text | Same |
| `rating` | `number \| null` | `max?` (default 5) | Star spans `[data-eui-sheet-star="n"]`; a click calls `@onCommit(n)`, on the current value `@onCommit(null)` | None | As number, whole, 0..max; `navKey`: digits 0..max | The number | The same cell |
| `url`, `email`, `phone` | `string` | text options | The text as a link-styled `<span role="link" data-eui-sheet-link>` | `InputEditor` | Text; `validate`: `url` parses with `new URL` (after adding `https://` when there is no scheme), `email` a simple `x@y.z` pattern, `phone` digits, spaces, `+ ( ) -` | The text | Same, plus an "open" icon button next to the box |
| `longText` | `string` | `maxLength` | Lines clamped to the row height | `<textarea>` with `editorLayout: 'expand'` (min the cell's box, width at least 240 px, height grows to 240 px, then scrolls); Enter commits and moves down; Shift+Enter and Alt+Enter insert a line break (`handlesKey`) | Text as it is | The text (quoted by `toTsv` when it has line breaks) | The textarea, 4 rows, grows |

`toNumber` (6.6) is set on currency, percent, duration and rating;
`schema` on currency (`'currency'`) and the other numeric ones
(`'numeric'`). Every new type has `compare`, for owners that sort.

Links without tabbable elements: the cell renders a span, never
`<a href>` (an anchor is tabbable, and the grid would add a focus trap:
`focus.ts` `disableInteractives`). The sheet's `onClick` opens
`type.link(value, field)` with `window.open(href, '_blank', 'noopener')`
when the click is on `[data-eui-sheet-link]` and the scheme is allowed;
a click elsewhere in the cell selects and edits as usual. The row menu
gets "Open link" when the focused cell has one.

Attachments, drag and drop: `dragover` on the wrapper (capture) with
`Files` in `dataTransfer.types` over an editable attachment cell sets
`dropPos` (tracked) and `preventDefault`; the cell gets
`euiSheet__cell--dropTarget`. `drop` calls `field.upload(files, …)`,
shows the cell as pending, and on success emits `commitValue` with the
old value plus the new files (source `'edit'`); on failure the cell gets
a rejection with `messages.uploadFailed()`. Open question Q8.

### 8.2 Batch 5: `@onResolve`

```ts
// Args
onResolve?: (requests: ResolveRequest[], options: { signal: AbortSignal }) => Promise<ResolveResult>;

export interface ResolveRequest<T = any> {
  fieldId: string;
  /** Distinct texts to resolve for this field. */
  texts: string[];
  cells: Array<{ text: string; recordId?: RecordId; tempId?: string; record: T | undefined }>;
}
/** Per field: text → the value to store, or null when nothing matches. */
export type ResolveResult = Record<string, Record<string, unknown | null>>;

// core
export interface PendingCell { recordId?: RecordId; tempId?: string; fieldId: string; text: string; parts: string[] }
export function planPaste<T>(ctx, anchor: Pos, matrix, options?): { changeSet: ChangeSet | null; pending: PendingCell[]; requests: ResolveRequest<T>[] };
export function planCommit<T>(ctx, pos: Pos, text: string): { changeSet: ChangeSet | null; pending: PendingCell[]; requests: ResolveRequest<T>[] };
/** Patches for resolved cells (`from` read from `records` now), rejections for failed ones. Source 'resolve'. */
export function resolveCells<T>(ctx, pending: readonly PendingCell[], result: ResolveResult): ChangeSet | null;
```

Flow (V9): without `@onResolve`, an unresolved cell is a rejection, as
v0.1. With it:

1. `planPaste` returns the synchronous change set (unresolved cells left
   out, but a row past the end still gets its insert) and the pending
   cells. The sheet emits the change set at once.
2. Pending cells are stored (`pendingCells: Map<cellKey, { text, token }>`)
   and shown with their text and `euiSheet__cell--pending`.
3. `@onResolve` is called once per paste (or per typed commit), one
   request per field. A test waiter is held.
4. On success `resolveCells` builds the second change set from the cells
   still pending under the same token; it is emitted and merged into the
   paste's undo entry (`mergeChangeSets`). A patch may name a `tempId`
   inserted in step 1.
5. A newer write to a pending cell (it is in `touched` of an `emit`)
   removes it from the map. A pending cell whose record leaves `@records`
   (an owner's re-query) is dropped too. When no cell of a call is left
   pending, or the sheet is destroyed, its `signal` is aborted. A
   rejected promise turns every remaining cell of the call into a
   rejection with `messages.unresolved(text)`.

### 8.2.1 Batch 5: files and interaction with existing features

| File | Change |
| --- | --- |
| `src/core/field-types/{multi-select,linked-record,user,attachment,currency,percent,duration,rating,link,long-text}.ts` (new) | Core types (`link.ts` holds url, email and phone). |
| `src/core/resolve.ts` (new) | `planPaste`, `planCommit`, `resolveCells`. |
| `src/core/change-set.ts`, `fill.ts`, `history.ts` | `equals` instead of `Object.is`; `newOptions` from `ParseResult`. |
| `src/core/messages.ts` | New tokens (`notAnAttachment`, `uploadFailed`, `notAUrl`, `notAnEmail`, `notAPhone`, `notADuration`, `openLink`, `removeFile`, `addFiles`, `loading`, `noMatches`). |
| `src/-private/cells/{chips,avatar,attachment,rating,link,long-text}-cell.gts` (new) | Cells. |
| `src/-private/editors/{multi-select,record-picker,attachment,textarea}-editor.gts` (new) | Editors (`record-picker` serves linkedRecord and user). |
| `src/-private/editor-frame.gts` | `'expand'` layout. |
| `src/field-types.ts`, `src/index.ts` | Registration and exports (`multiSelectType`, …). |
| `src/components/eui-sheet.gts` | `@onResolve`, pending cells, drop handling, link clicks. |
| `src/search-ui/eui-sheet-search.gts` | Forwards `@onResolve` (already in 7.2's list). |

- **Values are never mutated**: fill down, paste tiling and duplicate
  copy a value by reference, so two records can hold the same array. The
  sheet and its editors always build a new array for a new value; the
  docs tell owners to do the same.
- **Undo/redo**: the conflict check uses `equals`, so an array that a
  server round trip replaced by an equal one is not a conflict.
- **Clicks**: a star or link click acts on the first click (through
  `@onCommit` and the sheet's link handling) and does not start an edit.
  After a drag that ends on a link, `suppressClick` keeps it from opening.
- **Validation**: `required` uses the type's `isEmpty` (`[]` is empty).
- **Rejections and the error box**: a failed resolve or upload is an
  ordinary rejection (text shown in the cell, message in the box). A
  pending cell shows no error until it settles.
- **Editor frame**: the `'expand'` frame commits on scroll and on focus
  leaving, like the others.
- **Highlight**: the chip, avatar and link cells pass `@highlight` to
  `EuiHighlight` around their labels.
- **Expanded record**: the table's "In the form" column.

### 8.3 Batch 5: tests, docs, risks

| File | Cases |
| --- | --- |
| `tests/unit/field-types-test.ts` (extend) | F8 to F17: one per new type (parse, format, copyText, validate, compare, isEmpty, equals, navKey, toNumber); F18 `parse(copyText(v))` round trip for all but attachment; F19 multiSelect quoted parts and `newOptions`; F20 link schemes (a `javascript:` value gives no link). |
| `tests/unit/resolve-test.ts` (new) | RS1 `planPaste` splits sync and pending; RS2 requests have distinct texts per field; RS3 `resolveCells`: values, `null` → rejection, multi-part combine; RS4 a pending cell in an inserted row patches its `tempId`. |
| `eui-sheet-types2-test.gts` (new) | M1 to M4 multiSelect (chips, editor toggle and commit, paste with a new option, clear); L1 to L3 linked record (async search, pick two, chips); US1 user with options; A1 attachment editor uploads through a fake `upload`; A2 drop a `File` on a cell; A3 failed upload; A4 the cell never holds a tabbable element; NU1 currency, percent, duration typing and paste; RA1 rating click, same-star clear, digit keys; LK1 a click on the link span calls `window.open` (stubbed) once and a click beside it selects; LK2 no `<a>` in cells; LT1 long text: Shift+Enter adds a line, Enter saves, the frame grows, copy is quoted. |
| `eui-sheet-resolve-test.gts` (new) | RV1 paste of names: sync patches at once, pending class, then resolved patches; one Ctrl+Z undoes both; RV2 `null` gives a rejection; RV3 a newer edit on a pending cell discards its result; RV4 destroy aborts the signal; RV5 without `@onResolve`: rejections as v0.1; RV6 typed text in a linked-record cell resolves too; RV7 the record leaves `@records` while pending: dropped. |
| `eui-sheet-record-test.gts` (extend) | RF15: each new type in the form. |

Docs: the field types table in `sheet.md` and the README; demos
`d15-more-field-types.md`, `d16-linked-records.md` (fake API, bulk
resolve log), `d17-attachments.md` (fake upload with a delay and a
failing file name); `d04-custom-cells.md` gains `@onResolve` for its zone
picker. "Not yet" loses these types and bulk resolve.

Risks:

- **Focus**: the multi-select editor stays open across toggles; the
  `EuiSelectable` quirks of `PACKAGE-RESULTS.md` V5 (no current option
  when opened with a seeded search) apply again; reuse `SelectEditor`'s
  capture handler.
- **Array values**: every "unchanged" check must go through `equals`, or
  each paste writes every multi-value cell. F-tests and RV1 cover it.
- **Uploads**: a drop while another upload runs on the same cell: the
  second result is appended to the value read at that time.
- **Performance**: chips and avatars per cell are components; at 25
  rows × 10 such columns, 250 `EuiBadge`/`EuiAvatar`. Measure in d08;
  clip at three chips plus "+N".
- **Security**: link schemes are an allow-list; attachment URLs are
  rendered as `src`/`href` only when they start with `http:`, `https:`,
  `blob:` or `data:image/`.

### 8.4 Batch 6: editing polish

Core (`src/core/fill.ts`, `src/core/nav.ts` new):

```ts
/** Mirror of fillDown: each row's left value to the cells right of it; one column: from the cell to the left. */
export function fillRight<T>(ctx, range: Range): ChangeSet | null;
/** Fills `target` (which contains `source` and extends it along one axis) from `source`. Source 'fill'. */
export function fillRange<T>(ctx, source: Range, target: Range, options?: { copy?: boolean }): ChangeSet | null;
// FieldType
/** Continues `samples` by `count` values, or undefined to repeat them. */
series?(samples: V[], count: number, field: F, direction: 1 | -1): V[] | undefined;
/** The cell Ctrl/Cmd+arrow jumps to (Excel's rule: the next edge between empty and non-empty cells, else the last cell). */
export function edgeTarget<T>(ctx, pos: Pos, direction: 'up' | 'down' | 'left' | 'right'): Pos;
```

Series rules, per column for a vertical fill (per row for a horizontal
one): `number`, `currency`, `percent`, `duration`, `rating`: two or more
samples with a constant step continue it, one sample is copied. `date`:
one sample continues by one day; two or more with a constant day step
continue it. Anything else, or samples without a constant step: the
samples repeat in order. `copy: true` (Ctrl/Alt held at release) always
repeats. Read-only cells are skipped; values go through `equals`.

| Feature | Trigger | Behaviour |
| --- | --- | --- |
| Fill handle | A square (`euiSheet__fillHandle`, 8 px) the sheet draws in the wrapper at the bottom-right corner of the range's last cell, when that cell is rendered, the sheet is not read-only, no editor is open and the pointer is fine (`@media (pointer: fine)`). Press it and drag. | The drag extends along the dominant axis; target cells get `euiSheet__cell--fillPreview`; release emits `fillRange` and selects the union. Escape during the drag cancels. Its position is recomputed on selection change and on scroll (hidden while the corner cell is not rendered). |
| Cut | The `cut` event (capture), same target rule as copy | Copies the range as TSV, then `clearRange` with source `'cut'`. Stopped like copy. |
| Fill right | Ctrl/Cmd+R on a data cell (C11) | `fillRight`. |
| Edge jump | Ctrl/Cmd+Arrow on a data cell | `edgeTarget`; `api.setFocusedCell`. With Shift: extends the range to it. It looks only at the rows the sheet has. |
| Range keys | Shift+Home/End, Ctrl/Cmd+Shift+Home/End, Shift+PageUp/Down | `extending` is set for these keys too (today only arrows: `eui-sheet.gts:720`). |
| Page keys | PageUp/PageDown on a data cell | Moves focus by the number of fully visible rows (the grid only pages with `@pagination`, `focus.ts`). |
| Auto-scroll | A select drag or a fill drag with the pointer within 24 px of an edge of the grid's scroll element, or past it | A `requestAnimationFrame` loop calls `api.scrollTo` (speed grows with the distance, at most 20 px per frame) and sets the head from `document.elementFromPoint` at the pointer clamped inside the element. Stops on release, on destroy, and when the edge is reached. |

The scroll element is the grid body's outer element (the element with
`overflow:auto` in `body.gts` `outerStyle`); the sheet finds it as the
scroll parent of a data cell.

### 8.5 Batch 6: touch

| Behaviour | Design |
| --- | --- |
| Tap | The browser's synthesized mouse events already select; a tap on the selected cell edits. |
| Drag | Scrolls natively (the select drag uses `mouseover`, which touch does not fire). No range drag on touch in v0.2; Ctrl/Cmd+A, row numbers and column headers still select. |
| Long press | `contextmenu` (Android Chrome is expected to fire it on a long press and iOS Safari not to: from general knowledge, not checked on devices). For iOS Safari: a 500 ms timer started on `touchstart` on a cell, cancelled by `touchmove` beyond 10 px or `touchend`; it opens the row menu and sets a flag that swallows the following click. |
| Hover-only parts | Under `@media (hover: none)` the opener, the row checkbox and the expand icon are always visible; hit areas at least 32 px. |
| Editing on phones | `@editIn?: 'cell' \| 'record' \| 'auto'` (default `'auto'`): with a coarse pointer and a wrapper narrower than 600 px, a tap on the selected cell (or Enter) opens the expanded record with that field's editor mounted, instead of the in-grid editor. |
| Zoom delay | `touch-action: manipulation` on the wrapper. |

### 8.6 Batch 6: IME and dead keys

Today a composition never opens an editor: `onKeyDown` requires
`key.length === 1 && !event.isComposing` (`eui-sheet.gts:790`), and a
dead key reports `key === 'Dead'`. Expected from that code, not run: on
a Mac keyboard, typing `´` then `e` on a cell opens the editor with `e`,
not `é`. Confirm it on the Mac before building the fix.

Mechanism (V8):

- The sheet always renders `<input class="euiSheet__ime"
  data-eui-sheet-editor-surface aria-hidden="true" tabindex="-1">` beside
  the grid (not inside it), visually hidden until used.
- On a `keydown` on an editable data cell with `event.key === 'Dead'`,
  `event.key === 'Process'`, `event.keyCode === 229` or
  `event.isComposing`: the sheet does **not** prevent the event, stores
  the cell's position and rect, moves the input over the cell (same
  styles as `euiSheet__input`) and focuses it synchronously, inside the
  handler. The composition then happens in the input.
- `compositionend` (or the first `input` event that is not composing, for
  dead keys that do not fire composition events): the sheet calls
  `startEdit(pos, cell, text)` with the input's text as `initialKey`
  (multi-character is allowed; `InputEditor` already seeds `draft` from
  it), then clears and hides the input. The editor takes focus on mount.
  A type whose `opensOnKey(text)` is false: focus returns to the cell and
  nothing opens.
- Escape or an empty `compositionend`: `api.setFocusedCell` back to the
  cell.
- While the input has focus the grid ignores keys (focus is outside its
  content element) and the sheet's handler returns for composing events.

This can only be confirmed with real input on the Mac (Chrome, Safari,
Firefox; Spanish dead keys, Japanese and Pinyin IMEs). If focusing the
input during the `keydown` does not carry the composition over in one
browser, the fallback for that browser is: the first composition is lost
and the editor opens empty on `compositionstart` (still better than
today); report it.

### 8.6.1 Batch 6: files and interaction with existing features

| File | Change |
| --- | --- |
| `src/core/fill.ts` | `fillRight`, `fillRange`; `series` on number, currency, percent, duration, rating, date. |
| `src/core/nav.ts` (new) | `edgeTarget`. |
| `src/-private/fill-handle.gts` (new) | The handle. |
| `src/-private/auto-scroll.ts` (new) | The frame loop (plain class: start, update pointer, stop). |
| `src/-private/ime-catcher.gts` (new) | The composition input. |
| `src/-private/styles.ts` | Handle, preview, touch media queries, catcher. |
| `src/components/eui-sheet.gts` | Keys, `cut`, fill drag, long press, `@editIn`. |
| `src/search-ui/eui-sheet-search.gts` | Forwards `@editIn`. |

- **Fill drag and select drag**: the handle is a sibling of the grid, so
  the sheet's `onMouseDown` sees no data cell and does not set
  `dragFrom`. The fill drag has its own state (`fillFrom`, `fillTo`) and
  reuses the document `mouseup` listener pattern and `suppressClick`.
  Only one of the two drags can be active.
- **Undo/redo**: a fill, a fill right and a cut are each one entry.
- **Edge jumps and range keys**: they set `extending` before
  `setFocusedCell`, as the select drag's release does
  (`eui-sheet.gts:634-639`), so `onFocusIn` keeps the anchor.
- **Scroll**: auto-scroll fires the sheet's `onScroll`; no editor is open
  during a drag, and the error box follows its cell as today.
- **IME catcher and the editor frame**: the catcher counts as an editor
  surface for `isInEditor`, but `editing` is null while it has focus, so
  `onKeyDown` takes neither the edit branch nor the cell branch.
- **Touch and clicks**: the long-press flag swallows one click, like
  `suppressClick`.
- **Read-only**: `@readOnly` hides the handle and disables cut (it
  copies only), fill right and the catcher.
- **The add row and frozen cells**: a fill never reaches the add row; the
  handle on a frozen cell is drawn above it (it is a sibling of the grid).

### 8.7 Batch 6: tests, docs, risks

| File | Cases |
| --- | --- |
| `tests/unit/fill-test.ts` (extend) | F4 `fillRight`; F5 `fillRange` down, up, right, left; F6 number series (1, 2 → 3, 4; one sample copies; 1, 2, 4 repeats); F7 date series (one sample by day; weekly step); F8 `copy: true`; F9 read-only cells skipped. |
| `tests/unit/nav-test.ts` (new) | NV1 `edgeTarget` in the four directions, over gaps, at the edges. |
| `eui-sheet-polish-test.gts` (new) | P1 fill handle drag down fills a series, one undo; P2 the handle hides while editing and with `@readOnly`; P3 cut puts TSV on the clipboard and clears, source `'cut'`; P4 Ctrl+R; P5 Ctrl+ArrowDown jumps, Ctrl+Shift+ArrowDown extends; P6 Shift+End and Ctrl+Shift+End extend; P7 PageDown moves a page; P8 auto-scroll: a drag held under the grid scrolls and the head follows (drive the rAF loop with a stubbed `requestAnimationFrame`); P9 the loop stops on release and on destroy. |
| `eui-sheet-ime-test.gts` (new) | IM1 a `keydown` with `key: 'Dead'` focuses the catcher over the cell; an `input` event with `é` opens the editor with `é`; IM2 `compositionstart`/`compositionend` with `日本` opens the editor with it; IM3 Escape returns focus to the cell; IM4 a read-only cell ignores it; IM5 the catcher is not tabbable. (Synthetic events: they prove the wiring, not the browsers.) |
| `eui-sheet-touch-test.gts` (new) | TC1 long press (fake timers) opens the menu and swallows the click; TC2 a move cancels it; TC3 `@editIn="record"` opens the form on the second tap with the editor mounted. |

Manual checks on the Mac, to list in the results: dead keys and IMEs
(8.6), touch on an iPhone and an Android phone, the fill handle and
auto-scroll with a real mouse, Firefox and Safari for the frozen field.

Docs: keyboard and mouse tables; "Touch" and "IME" notes; demo
`d18-editing.md` (fill handle, series, cut). "Not yet" keeps group by
(v0.3), range selection by touch, and what is out of scope (formulas,
rollups, lookups, comments, co-editing, other view kinds).

Risks:

- **Focus**: the fill handle and the catcher are outside the grid; a
  press on the handle must not blur the focused cell (`mousedown`
  `preventDefault`).
- **Virtualization**: auto-scroll renders new rows under a fixed pointer;
  the head must come from `elementFromPoint`, not from `mouseover` (the
  pointer does not move).
- **Performance**: the fill preview class goes through `setCellProps` on
  each cell of the target; a drag over thousands of rows only touches
  rendered cells.
- **a11y**: the fill handle is mouse-only; Ctrl+D and Ctrl+R are its
  keyboard path.

## 9. Frozen primary field: decision, mechanism, fallback

### 9.1 Decision

No grid change. The frozen cells become sticky through the `style` that
`setCellProps` already accepts, and column virtualization is turned off
while a field is frozen.

Why it can work without the grid:

- A body cell's inline style is built as `position:absolute; left; top;
  height`, then width, then the `setCellProps` style **last**
  (`cell.gts:779-803`), so `position` and `left` can be overridden per
  cell.
- Rows are `position:absolute; left:0; right:0` inside one scroll
  element with `overflow:auto` (`row.gts:52-56`, `body.gts` `outerStyle`),
  so a sticky cell sticks to that element.
- Header cells are flex items (`euiDataGridHeaderCell`: `flex:0 0 auto`
  in the generated styles; that their row is the flex container was not
  read) of the sticky header row; all of them are always rendered
  (`header-row.gts`, `{{#each @grid.columns}}`), and they take classes
  through `displayHeaderCellProps.className` and `headerCellProps.className`.

Checked on paper and on a mock:

- **Two sticky cells in one row** (the row number and the primary
  field). Sticky cells are in normal flow, so two block cells would
  stack. With `float: left` they sit side by side. Checked in headless
  Chrome on a static page with the grid's layout (absolute rows, absolute
  cells, a sticky flex header; two cells overridden with
  `position:sticky; float:left; left:0 / 40px; z-index:2`): at
  `scrollLeft = 700` both cells stay at x = 0 and 40 and at the row's y,
  the header cells too, and `elementFromPoint` over them returns the
  frozen cell. The mock is not the grid: section 9.3 is the real test.
- **Keyboard focus under the frozen columns**. `scrollCellIntoView`
  (`body.gts:694-735`) only knows the scroll element's left edge, so
  ArrowLeft can focus a cell hidden under the frozen columns. The sheet
  fixes it in `onFocusIn`: for a non-frozen data cell whose left edge is
  left of the frozen columns' right edge, it calls `api.scrollTo({
  scrollLeft: current - overlap })`. One frame late, sheet-only.
- **Virtualization cost**. The grid renders a contiguous column window
  (`body.gts:320-339`, `renderedColumns`), so a frozen column would
  unmount once scrolled past. While `frozenFields > 0` the sheet passes
  `virtualizationOptions={ overscanColumnCount: <column count> }`, so
  every column of every rendered row is rendered. Rows stay virtualized.
  Cost: rendered cells = visible rows × all columns (25 rows × 30 fields
  = 750 cell components). Above `FROZEN_MAX_COLUMNS = 50` visible fields
  the sheet turns freezing off by itself and logs a debug warning.

### 9.2 Mechanism

- A frozen field always has an explicit width: `initialWidth =
  @fieldWidths[id] ?? field.width ?? 200`. The sheet tracks its width
  through `@onColumnResize` (`columnWidths`, tracked). Left offsets: the
  control column's width (64, or 0 without row numbers) plus the widths
  of the frozen fields before it.
- Body cells (`SheetCell`, and the row-number cell): `setCellProps`
  style `{ position: 'sticky', float: 'left', left: <offset>, zIndex: 2 }`
  (the grid's `styleString` adds `px` to numbers except unitless
  properties, and `z-index` is in its `UNITLESS` set: `cell.gts:118-131`)
  and class `euiSheet__cell--frozen` (opaque background
  `var(--euiSheet-plain)`; the last frozen one also `--frozenEdge`, a
  right border and a shadow shown only when scrolled).
- Header cells: classes `euiSheet__frozenHeader euiSheet__frozenHeader--<i>`
  (`position: sticky; left: var(--euiSheet-frozen-left-<i>); z-index: 3`);
  the wrapper's inline style sets `--euiSheet-frozen-left-<i>`.
- Footer cells (summary bar): the footer row is a flex row
  (`euiDataGridFooter`: `display:flex`, in the generated styles), outside
  the inner element and sticky at the bottom; its cells are not absolute
  (`cell.gts:787-796` skips the absolute position for `isFooter`). So
  they are frozen like header cells: `{ position: 'sticky', left:
  <offset>, zIndex: 2 }` through their `setCellProps`, without the float.
  Not checked on the mock: FZ10.
- The wrapper gets `euiSheet--scrolledX` from `onScroll` (it already
  listens) when `scrollLeft > 0`, for the edge shadow.
- The editor frame takes the cell's rect, so editing a frozen cell works
  unchanged. An editor over a non-frozen cell that is partly under the
  frozen columns cannot happen: focus scrolls it clear first.
- The first field cannot be hidden or moved (6.3).

### 9.3 Acceptance test (binary; first task of the feature in batch 3)

`eui-sheet-frozen-test.gts`, 12 fields of 150 px at a 600 px width, 200
records:

| # | Check |
| --- | --- |
| FZ1 | After `scrollTo({ scrollLeft: 700 })`: the row-number cell and the first field's cell of row 3 have the same `getBoundingClientRect().left` as before the scroll, and their `top` equals a non-frozen cell's `top` in that row. |
| FZ2 | `document.elementFromPoint` at the centre of the frozen cell is inside it (it paints over the scrolled cells). |
| FZ3 | The frozen header cells stay too, and stay above the body on vertical scroll. |
| FZ4 | From the last field, ArrowLeft until the second field: at each step the focused cell's left edge is at or right of the frozen columns' right edge. |
| FZ5 | Resizing the frozen field moves the next cells and keeps FZ1. |
| FZ6 | Type-to-edit on the frozen cell while scrolled: the editor covers it. |
| FZ7 | A range over frozen and non-frozen cells is drawn selected on both. |
| FZ8 | `@frozenFields={{0}}`: no `overscanColumnCount`, cells are absolute again. |
| FZ9 | Vertical scroll over 10,000 rows with 30 fields frozen-on: time per scroll frame logged (not asserted). |
| FZ10 | With `@summary`: after the horizontal scroll, the footer cells of the row-number column and the first field keep their `left`, and paint over the scrolled footer cells. |

If FZ1 to FZ4 or FZ10 cannot be made to pass in headless Chrome, **stop
and report**; do not add workarounds. The fallback is 9.4. Firefox and
Safari are a manual check.

### 9.4 Fallback: grid extension `frozen-columns` (only if 9.3 fails)

Following `internal/spikes/eui-latest/data-grid-extensions.md`: marked
one-line hooks, logic in separate files, a touchpoints table added to
that document, and the grid's existing tests passing unchanged.

New argument: `@frozenColumns?: number` (leading data columns to freeze;
leading control columns freeze with them). Extension files:
`src/components/eui-data-grid/frozen-columns-hooks.ts` (pure helpers) and
tests `tests/integration/components/eui-data-grid-frozen-test.gts`.

| File | Symbol | Hook | Delegates to |
| --- | --- | --- | --- |
| `eui-data-grid.gts` | `Args` | `frozenColumns?: number` | type |
| `eui-data-grid/body.gts` | `renderedColumns` | `return withFrozenColumns(this.grid, columns)` (adds the frozen indexes before the window) | `withFrozenColumns` |
| `eui-data-grid/body.gts` | `scrollCellIntoView` | `leftWidthOutOfView` uses `scrollLeft + frozenWidth(this)` for non-frozen cells | `frozenWidth` |
| `eui-data-grid/cell.gts` | `style` | `parts.push(frozenCellStyle(this.grid, body, colIndex))` after the absolute position | `frozenCellStyle` (sticky, float, left, z-index) |
| `eui-data-grid/cell.gts` | `classes` | frozen class | `frozenCellClass` |
| `eui-data-grid/header-cell.gts` | `style`, `classes` | sticky left for frozen header cells | `frozenHeaderStyle` |
| `eui-data-grid/cell.gts` (footer branch) | style | sticky left, no float | `frozenCellStyle` |

About 8 marked lines in 4 files. With it the sheet passes
`@frozenColumns` and drops its own sticky styles, the focus correction
and the overscan; column virtualization stays on. This is the better
long-term shape, but it changes ported files, so it is the fallback, not
the plan. Open question Q2.

## 10. Data down, actions up: the whole surface

| Feature | In | Out | Without a handler |
| --- | --- | --- | --- |
| Rows | `@records` (the owner's rows, in its order; maybe one page) | n/a | n/a |
| Cell edits, paste, clear, fill, cut | `@records` | `@onChange` (patches) | `@onChange` is required |
| Insert, duplicate | `@canInsert`, `@newRecordValues` | `@onChange` (`inserts` with `index`, `anchor`) | |
| Delete | `@canDelete` | `@onChange` (`deletes`, `removed`) | |
| Undo, redo | the sheet's own stacks | `@onChange` (`'undo'`, `'redo'`) | |
| Sort | `@sort` (arrows) | `@onSortChange` | no sort items |
| Filter | nothing | `@onFilterByField` | no item |
| Search | `@highlight` | nothing (the owner's search box) | |
| Paging | `@rowNumberOffset`, `<:footer>` | the owner's pager | |
| Loading | `@isLoading` | | |
| Summary | `@summary` | the owner's control | no footer |
| Visible fields and order | `@fields` | `@onHiddenFieldsChange`, `@onFieldOrderChange` | local hidden set and order |
| Hidden fields | `@hiddenFields` | `@onHiddenFieldsChange` | local |
| Widths | `@fieldWidths` | `@onFieldWidthChange` | the grid keeps them |
| Row height | `@rowHeight` | `@onRowHeightChange` | local |
| Frozen fields | `@frozenFields` | none | |
| Checked rows | `@checkedRecordIds` | `@onCheckedChange` | local set |
| Expanded record | `@expandedRecordId`, `@expandedRecord` | `@onExpandedRecordChange` | local id |
| Bulk resolve | `@onResolve` | `@onChange` (`'resolve'`) | unresolved texts are rejections |
| Uploads | `field.upload` | `@onChange` (`'edit'`) | no picker in the attachment editor |

## 11. Questions

### 11.1 Resolved by the user's review

| # | Question | Decision |
| --- | --- | --- |
| Q1 | Expanded record: flyout or modal? | Both, by `@expandedRecord`, default `'flyout'` (5.7). |
| Q3 | Built-in toolbar? | No. `<:toolbar>` and `<:footer>` blocks; filter, sort and search controls are the owner's (3.5, 3.6). |
| Q4 | Stable or live view while editing? | Stable, and it lives in the connector: no re-query after the user's edits, a "Re-apply" action calls `driver.refresh()` (7.3). |
| Q5 | Filter builder depth? | No builder in the sheet. The header emits `onFilterByField`. |
| Q9 | `@ownerApplies`? | Gone: the owner always applies. The sheet has no in-memory query logic (V3). |
| Q10 | Row numbers and a frozen first field on by default? | Yes. The row number shows the position; `@rowLabel` changes it (5.2). |
| Q11 | Search: highlight or filter? | Neither is the sheet's. It highlights a term the owner passes (`@highlight`, 6.5). |
| Q7 | Group rows: sheet-owned or the grid's `@grouping`? | Moot for v0.2: group by is deferred (7.6). |

### 11.2 Open

| # | Question | Recommended default |
| --- | --- | --- |
| Q2 | Frozen field: sheet-only sticky cells (no column virtualization while frozen, off above 50 fields), or the `frozen-columns` grid extension (9.4)? | Sheet-only, with 9.3 as the gate. Choose the extension now if sheets with more than about 40 fields are expected. |
| Q6 | Undo of a delete when the server cannot reuse ids: is a new record plus `api.remapIds` acceptable, or should undo of deletes need an opt-in? | Offer it always; document `restore` and `remapIds`. |
| Q8 | Attachment upload callback: `field.upload(files, { record, field, signal }) => Promise<SheetAttachment[]>` on the field, or one sheet-level `@onUpload`? With or without progress? | On the field, no progress in v0.2 (the cell shows pending). |
| Q12 | Percent storage: fraction (`0.25`) or whole number (`25`)? | Fraction, as Airtable and Excel. |
| Q13 | A delete shortcut for rows? | None in v0.2 (Delete always clears cells); the menu deletes. |
| Q14 | Bulk resolve as two change sets and one undo entry (V9) instead of one delayed change set? | Two change sets. |
| Q15 | No `localView()` helper: a local sheet that needs sorting or filtering must be owned by an EmberSearchUi driver with `memoryBackend`. Acceptable, or should the sheet package ship a small sorter for bare sheets? | Acceptable: one evaluator. The demo d12 shows a ten-line owner that sorts its own array for the simplest case. |
| Q16 | The connector lives in `@ember-eui/sheet/search-ui`, typed structurally, with `ember-search-ui-driver` only as a devDependency. For the demo's toolbar: EmberSearchUi views (needs `ember-search-ui-views` published and its power-select peers in the docs site), or small EUI controls wired to the driver? | The location as designed. Views if they install and build; else EUI controls, said in the demo. |
| Q17 | After a page or query change, keep the undo history (entries for records not on the page are skipped) or clear it? | Keep; apps that prefer clearing call `api.clearHistory()`. |
| Q18 | Group by deferred to v0.3, with the summary bar kept as owner-provided values? | Yes (7.6). |
| Q19 | The connector's defaults: a "Re-apply" button and `EuiTablePagination` rendered by the component, or only yielded for the app to render? | Rendered by default, `@paging={{false}}` to drop the pager; the stale state is also yielded (`search.isStale`). |

## 12. What was verified, and what was not

Verified by reading the code:

- The sheet (`packages/sheet`): `src/components/eui-sheet.gts`
  (row/visible-row assert 457-461, `visibleFieldIds` 260-265, `dataCell`
  417-430, key handling 719-806, `selectChanged` 864-903, paste 942-974,
  `emit` 1158-1209, `recordHistory` 1216-1222, grid invocation
  1303-1313), the core files, the cell, the editor frame and the editors.
- The grid (`packages/core/src`): `components/eui-data-grid.gts`
  (arguments, blocks, `setFocusedCell`, API, `getCorrectRowIndex`),
  `eui-data-grid/cell.gts` (style order 779-803, `styleString` 118-131,
  `cellValueProps` 868-882, focus trap 505-592), `row.gts`, `body.gts`
  (column window 320-339, `scrollCellIntoView` 694-735, outer and inner
  styles), `header-row.gts`, `header-cell.gts` (template 440-535),
  `column-actions.gts` (sorting 292-311), `utils/data-grid/{types,focus,sorting}.ts`.
- Theme: `theming.ts`, `utils/eui/styles.ts`, `utils/eui/css-variables.ts`,
  `components/eui-emotion-provider.gts` (root variables at 170, scoped at
  213-218), and that every token of 4.3 is used somewhere in core.
- Components named in this design exist in `core/src/components`:
  flyout, modal (with header, body, footer), context menu (panel, item),
  popover, panel, selectable, select, button empty, button icon, field
  search, file picker, avatar, badge, highlight, icon tip, progress,
  table pagination, filter group.
- EmberSearchUi (`~/prysmex/ember-search-ui/packages`):
  `ember-search-ui-driver/src/types.ts` (`SortItem` 83-86, `PageState`,
  `SearchState`, `SearchResult`), `driver.ts` (`snapshot`, `schema`,
  `subscribe` with `immediate`, `setSort` and `setQuery` reset to the
  first page, `setPage` 1-based and throwing under cursor paging,
  `setPerPage`, `refresh`, no method that patches results),
  `memory-backend.ts` (docs or a function, filter, text search, sort,
  offset and cursor paging, `{ results, total }` only), `codec.ts`
  (`FieldDefinition`), `ember-search-ui/src/tracked-search.ts`, the three
  `package.json` files (names, versions, peers, none private), the list
  of view components.
- `site/package.json` and `pnpm-lock.yaml` have no EmberSearchUi entry.
- The sticky mechanics of 9.1, in headless Chrome on a static mock
  (scratchpad, deleted).

Not verified (each is a first step of its batch):

| # | Item | Batch |
| --- | --- | --- |
| N1 | `@ember-eui/core/theming` exists in the lowest core version the peer range allows (`^16.0.0`); else raise the peer (C12). | 1 |
| N2 | The provider's component name and its colour-mode argument, for test TH2. | 1 |
| N3 | `EuiFlyout`'s and `EuiModal`'s focus traps together with editors that focus on mount and with wormholed editor surfaces; `EuiModal`'s arguments. | 2 |
| N4 | `EuiContextMenuPanel`/`Item` arguments beyond the ones read (`disabled`, `href`); focus on open. | 2 |
| N5 | The class of the header's content element is `euiDataGridHeaderCell__content` (it comes from a `contentClass` getter not read in full); the grid's "Sort" labels per schema, and that a column `schema` alone (no `@inMemory`) is enough for them. | 2, 3 |
| N6 | Whether a changed `initialWidth` re-applies to an existing column (6.4); `EuiProgress` and `EuiIconTip` arguments. | 3 |
| N7 | The whole of section 9 on the real grid, and in Firefox and Safari. | 3 |
| N8 | What `snapshot.result.results` holds while a search is loading (the connector keeps its own last results either way); whether `EuiTablePagination`'s `activePage` is 0-based. | 4 |
| N9 | That `ember-search-ui-views` is on npm and that it and its peers build in the docs site. (`ember-search-ui` and `ember-search-ui-driver` 2.0.0-beta.2 resolve from a registry in `m3-refactor`'s lockfile; no network was used.) | 4 |
| N10 | The views' arguments (`SearchBox`, `Sorting`, `Facet`, `FilterChips`, `PagingInfo`) and that they work under the `Search` provider with a driver created by the demo. | 4 |
| N11 | `EuiSelectable` in multi-selection mode with a search field focused (V5 quirks again); `EuiFilePicker` and `EuiAvatar` arguments. | 5 |
| N12 | That `tabbable()` reports nothing for the new cells (spans only). | 2, 5 |
| N13 | The IME mechanism with real input (8.6); touch on real devices (8.5). | 6 |
| N14 | No performance number in this document was measured. | all |

## 13. Summary

1. **Foundations**: theme tokens, quoted TSV, change set v2 (positioned
   and anchored inserts, undoable deletes), `SheetApi`.
2. **Records**: row numbers (position, `@rowLabel`), row/column
   selection, add row, Shift+Enter, context menu, expanded record in a
   flyout or a modal.
3. **View intents**: sort arrows and header menu, presentation state as
   data down and actions up, `<:toolbar>`/`<:footer>` blocks, highlight,
   owner-provided summary bar, frozen field (gate 9.3, fallback 9.4).
4. **Connector**: `@ember-eui/sheet/search-ui` (`searchRecords`,
   `EuiSheetSearch`), stable overlay with "Re-apply", docs demo on
   `memoryBackend`.
5. **Field types**: multiSelect, linkedRecord, user, attachment,
   currency, percent, duration, rating, url/email/phone, longText;
   `@onResolve`.
6. **Polish**: fill handle, cut, fill right, edge jumps, auto-scroll;
   touch; IME and dead keys.

The sheet never sorts, filters, searches, groups or pages. Group by is
deferred to v0.3. Open: Q2, Q6, Q8, Q12 to Q19 (11.2).

## 14. What the review changed

- No built-in toolbar, filter builder or search UI: `<:toolbar>` and
  `<:footer>` blocks; search is a term the owner passes (`@highlight`).
- No in-memory query logic in the sheet (no view model, `@ownerApplies`
  or `localView()`): rows are `@records` as given.
- Presentation state (`@fields`, `@hiddenFields`, `@fieldWidths`,
  `@rowHeight`) is controlled with a handler, local only without one.
- "Stable + Re-apply" moved to the connector (the user's change sets
  shown over the last results until `driver.refresh()`).
- The connector is batch 4: `@ember-eui/sheet/search-ui`, typed
  structurally (no dependency either way), with a `memoryBackend` demo.
- Expanded record: flyout or modal. Row numbers: position, `@rowLabel`.
- Summary bar: owner-provided `@summary`. Group by: deferred to v0.3.
- Selection, focus and an open editor follow their record when the owner
  replaces `@records`; inserts carry a neighbour anchor.
- Sections 3.7, 11 (resolved and open), risks and 12 updated to match.
