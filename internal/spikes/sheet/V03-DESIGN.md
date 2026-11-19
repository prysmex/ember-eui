# `@ember-eui/sheet` v0.3: design of the remaining gaps against Airtable's grid

Written 2026-11-19 against branch `feat/sheet`, HEAD `5f659546` (335 tests
passing). Design only: nothing here is implemented. It follows
`V02-DESIGN.md` and `V02-RESULTS.md`, and it was checked against the code;
section 14 lists what was checked and what could not be.

Short names, as in v0.2: **the sheet** is
`packages/sheet/src/components/eui-sheet.gts`, **the grid** is
`packages/core/src/components/eui-data-grid.gts` and `eui-data-grid/*`,
**the owner** is whatever provides `@records`. Paths without a package are
under `packages/sheet/`.

## 1. Goal and rules

v0.3 closes the gaps a user sees when comparing the sheet with Airtable's
grid: a clean add row, managing fields from the grid, dragging columns and
rows, group by, dates with a time, row colours, stepping through search
matches, a summary of the selection, wrapped headers, a shortcut list,
ranges by touch and upload progress.

Group by is the main item. Its contract (sections 2 and 8.1) is what Prysmex
will code against, so it is fixed here for any number of levels, even where
a batch draws the simplest case first.

Rules (the user's decisions, carried over from v0.2 section 1, not reopened):

- **The sheet is a pure view of the rows it is given.** It never sorts,
  filters, searches, groups, pages or aggregates. It draws the owner's state
  (a group header, a count, a current match) and emits intents.
- **Data down, actions up, for presentation too.** The sheet keeps local
  state for a presentation value only when the owner passes no handler for
  it. Fields, groups and record order are data, not presentation: without
  a handler their controls are not shown (as with sort).
- **Every write is a change set.** v0.3 adds record moves to it (4.3).
- **No built-in toolbar.** `<:toolbar>` and `<:footer>` stay the app's.
  Behaviour for a bare app comes from helpers outside the component
  (`summarize`, `localRecords`, and the new `groupRecords`, `findMatches`,
  `convertField`).
- **`packages/core/src` does not change.** One feature (the group header
  row) has a gate and fallbacks in section 9; the first fallback is also
  sheet-only.
- Cells render no tabbable element (P9). Editors, the field editor and the
  shortcut list live beside the grid.
- Additive unless 4.6 lists it. Frozen fields stay opt-in (`@frozenFields`,
  default 0) and column virtualization stays on by default.
- Each batch is complete on its own (code, tests, docs) and committed on
  `feat/sheet`.
## 2. Groups API at a glance

```ts
interface SheetGroupBy { field: string; direction: 'asc' | 'desc' } // one per level, outermost first
interface SheetGroup {
  key: string;        // the owner's id for the group: unique, stable across re-queries
  depth: number;      // 0 = outermost: the level of @groupBy it belongs to
  value: unknown;     // the group field's value; records added or dragged into the group get it
  label?: string;     // default: the field type's format(value), or "(Empty)"
  count: number;      // records in the group in the owner's whole data, never counted from @records
  loaded?: number;    // how many of @records, taken in order, sit under this header (0 when collapsed)
  collapsed?: boolean;
  summary?: Record<string, string>; // text per field id, drawn in the header row under that column
}
// <EuiSheet @records={{view.records}} @groups={{view.groups}} @groupBy={{view.groupBy}}
//   @onGroupByChange={{view.setGroupBy}} @onGroupToggle={{view.toggleGroup}} … />
// A bare app: view = groupRecords(ctx, records, { groupBy, fields, collapsed }) → { records, groups }
```

`@groups` lists every header depth-first in display order; the records of
a collapsed group are not in `@records`. The full shape (two more optional
fields for paging) and the placement rule are in 8.1 and 8.2.

## 3. Batch plan

| # | Batch | Depends on | Source lines (est.) | Test lines (est.) |
| --- | --- | --- | --- | --- |
| 1 | Add row look, drag to reorder columns, header text wrap, shortcut list | v0.2 | 450 | 450 |
| 2 | Field management: "+" column, header menu items, field editor, `convertField`, `localRecords` field operations | 1 (the header menu and the column code it touches) | 900 | 700 |
| 3a | Row model: grid row ↔ record / add row / group header. No behaviour change, no existing test touched | 1, 2 | 500 (about 350 of them rewritten lines) | 250 |
| 3b | Group by: `@groups`, `@groupBy`, header rows, per-group add rows and summaries, `groupRecords`, `localRecords` and connector support | 3a | 1,200 | 1,100 |
| 4 | Drag to reorder rows (change-set `moves`), row colours, `dateTime`, `button` and `barcode` types | 3b (a drag across groups) | 1,300 | 1,100 |
| 5 | Current search match and `findMatches`, selection exposure, ranges by touch, upload progress | 3a (selection in record space) | 800 | 750 |

Why this order. Batch 1 is the visible fixes and changes the header DOM
once (drag), before batch 2 adds a column and menu items to it. Batch 3a
comes after batch 2 so the refactor is done once, over all the code that
will exist, and directly before the feature that needs it. Row drag waits
for groups because a drag across groups writes the group field. Batch 5 is
independent of 3b and 4 and can be done before them if the user wants
search navigation sooner; it needs only 3a. Its two tests that use groups
(SL3, and the group part of SN6) land with whichever of 3b and 5 is done
second.

Batch 3b starts with a gate (9.3), as the frozen field did in v0.2: if the
gate fails, the batch uses fallback 9.4 and says so in its results.
## 4. Shared contracts (decided once, used by every batch)

### 4.1 Decisions

| # | Decision | Reason |
| --- | --- | --- |
| W1 | The grid's rows are no longer only `@records` plus one add row. A **row model** (`src/core/rows.ts`) maps each grid row to a record, an add row or a group header. Without `@groups` it is the identity of v0.2 (V1). | Group headers and per-group add rows are grid rows. The grid's `@grouping` and `@rowTree` stay unused: they group the rows they are given in memory (`eui-data-grid/row-model.ts:108`), so their counts would be per loaded page. |
| W2 | Two row spaces. **Grid rows** are what the component's `anchor`, `head`, `Range`, focus and the DOM use. **Record rows** (indexes into `@records`) are what `SheetContext` and every core builder use. The component converts at the call. | `src/core/{change-set,paste-plan,fill,nav}.ts` index `ctx.records` directly (4.2). A grid range always maps to one contiguous record range, because headers and add rows are only inserted between records, never reorder them, and collapsed records are absent. So the core stays as it is. |
| W3 | Groups are placed by position: each header takes the next `loaded` records (D1). | Section 8.2. |
| W4 | A group header is a row of ordinary grid cells with a class from `gridStyle.rowClasses`. Its label is one cell made sticky and wide by CSS; the other cells show the group's summary texts. Same height as a record row. | Section 9: the grid has no colspan and no row renderer; rows are absolutely positioned boxes of absolutely positioned cells (`row.gts:51-56`, `cell.gts:779-803`). |
| W5 | Column drag uses the grid's own `columnVisibility.canDragAndDropColumns`. | It is a public argument and ends in `setVisibleColumns`, which the sheet already maps to `onFieldOrderChange` (5.3). |
| W6 | Row drag is a sheet-side pointer drag from a grip in the row-number cell, drawn as an insertion line; it emits a change set with `moves`. | Body rows are virtualized, absolutely positioned and owned by the grid, so they cannot be wrapped in `EuiDraggable`. |
| W7 | Field management is three intents. The field editor is a popover the sheet renders beside the grid; `@fieldEditor` replaces its content. Field operations are not undoable by the sheet. | 6.6. |
| W8 | The "+" add-field control is a trailing control column of the grid (`@trailingControlColumns`, public). | It scrolls with the header and needs no measuring. Its body cells are inert: `dataCell()` already ignores control-column cells (`eui-sheet.gts:1853-1866`). |
| W9 | Search navigation is an argument, `@currentMatch`, not a focus call. | The user is typing in the app's search box; `api.focusCell` would take focus from it. |
| W10 | The selection is exposed (blocks, `api.getSelection()`, `@onSelectionChange`); the sheet computes nothing over it. | The rule; `summarize` already exists for the owner. |
| W11 | `dateTime` is a new built-in type next to `date`. | D9. |

### 4.2 Rows and positions (replaces V02-DESIGN.md 3.2, first bullet)

- A **grid row** `g` is `0 … rowModel.length - 1`. `rowModel.at(g)` is
  `{ kind: 'record', record: r }`, `{ kind: 'add', group: i | -1 }` or
  `{ kind: 'group', group: i }` (`i` indexes `@groups`).
- `Pos.row` and `Range.top/bottom` **in the component** are grid rows.
  `Pos` and `Range` **passed to the core** are record rows. The types do not
  change; the component gets three converters: `recordRowAt(g)` (−1 for a
  non-record row), `gridRowOf(r)`, and `recordRange(range)`, which returns
  the range of the records inside a grid range, or `null` when it holds
  none.
- A header or add row inside a range is skipped: nothing is copied from it,
  cleared, filled or pasted over. This is also how "the add row is never
  part of a range" is now implemented (v0.2 clamped to
  `records.length - 1`).
- Without `@groups` the model is the identity: records `0 … n-1`, then the
  add row at `n` when inserting is allowed. Every number v0.2 produced stays
  the same.
- Columns are unchanged (data columns, `colOffset` for the row-number
  column). The add-field column is a trailing control column and is never a
  position.
- When `@records` or `@groups` change and it was not the sheet's own change
  set: as v0.2 3.2, and in addition a head that was on a group header is
  found again by the group's `key` (else its row index, clamped). The
  trigger is the existing `watchRecords` modifier, which in 3b also takes
  `@groups` (`{{this.watchRecords @records @groups}}`, `eui-sheet.gts:5047`),
  because groups can change while `@records` stays the same array (an
  empty group toggled, counts arriving late).

### 4.3 Change set v3 (`src/core/types.ts`)

```ts
export interface RecordMove {
  recordId: RecordId;
  /** Where it goes: next to this record. Moves are listed in their final order; the first is anchored to a record that does not move, each next one after the previous. Absent: into `groupKey` with no loaded record to anchor to. */
  anchor?: { recordId: RecordId; position: 'before' | 'after' };
  /** With `@groups`: the key of the group it lands in. */
  groupKey?: string;
  /** Where it was, for undo: the record before it (absent: it was first) and its group. */
  from: { after?: RecordId; groupKey?: string };
}

export interface RecordInsert {
  // … as today …
  /** With `@groups`: the key of the group whose add row, menu item or paste made it. `values` already carry that group's values. */
  groupKey?: string;
}

export interface ChangeSet {
  source: /* … as today … */ | 'move';
  // … as today …
  /** Records that change place (a row drag, its undo or redo). Optional; with patches when the drag crossed groups. */
  moves?: RecordMove[];
}
```

- `applyChangeSet` (`src/core/change-set.ts`) applies patches, deletes and
  inserts as today, then `moves` in order: take the record out, put it back
  next to its anchor; a move whose anchor is not found is skipped. So
  `localRecords` and the connector's overlay (`search-records.ts`, which
  calls `applyChangeSet`) get row order without new code.
- `invertChangeSet` (`src/core/history.ts:28`) turns a move into the move back
  (`anchor: { recordId: from.after, position: 'after' }`, or before the
  current first record when `from.after` is absent), with the inverse
  patches. The inverse moves are applied **in the same order, not
  reversed**: moved rows are listed top to bottom, and a row's `from.after`
  may be an earlier moved row, which has then already been put back
  (`[A,B,C,D,E]`, B and C dragged after E: undo puts B after A, then C
  after B). Each inverse move's own `from` is where the row is now, for
  redo. Undo's conflict check is unchanged (it reads values).
- An owner that ignores `moves` gets no reorder; that is why row drag is
  opt-in (`@canMove`).
- Field operations (batch 2) are not change sets (W7).

### 4.4 Types and arguments

Core (`src/core/types.ts`), all new:

```ts
export interface SheetGroupBy { field: string; direction: 'asc' | 'desc' }
export interface SheetGroup { /* section 2, in full in 8.1 */ }
export interface RecordMove { /* 4.3 */ }
/** What the field editor produces. `id` is absent on create: the owner assigns it. */
export interface SheetFieldDraft {
  label: string;
  type: string;
  description?: string;
  required?: boolean;
  /** Type options: `options` of a select, `currency`, `precision`, `max`, `dateOrder`, `timeZone`, … */
  [option: string]: unknown;
}
export interface DateTimeField<T = any> extends EuiSheetField<T> { type: 'dateTime'; /* 10.3 */ }
```

`EuiSheetField` gains `groupable?: boolean` (default true: the header menu
offers "Group by this field" with `@onGroupByChange`) and
`manageable?: boolean` (default true: the header menu offers Edit,
Duplicate and Delete with their handlers).

Ember layer (`src/types.ts`): `SheetSelection<T>` (11.2),
`SheetFieldEditorSignature` (6.4), `SheetRowColor` (10.2), and on
`EuiSheetFieldType`: `label?: string` (the type's name in the field editor;
default from messages), `fieldOptions?: ComponentLike<…>` (the type's own
part of the field editor, 6.4).

New arguments of `EuiSheetSignature['Args']`, by batch:

| Batch | Argument | Meaning |
| --- | --- | --- |
| 1 | `fieldDrag?: boolean` | Drag a header to reorder. Default true. |
| 1 | `headerLines?: 1 \| 2 \| 3` | Lines a header label may wrap to. Default 1. |
| 2 | `onFieldCreate?`, `onFieldUpdate?`, `onFieldDelete?` | Field intents (6.2). Each shows its controls. |
| 2 | `fieldEditor?: ComponentLike<SheetFieldEditorSignature>` | Replaces the built-in field editor's content. |
| 2 | `creatableFieldTypes?: string[]` | The types the field editor offers. Default 6.4. |
| 3b | `groups?: SheetGroup[]` | The headers to draw. Absent or empty: no groups. |
| 3b | `groupBy?: SheetGroupBy[]` | The owner's group-by, drawn in the header menu and given to the blocks. |
| 3b | `onGroupByChange?: (groupBy: SheetGroupBy[]) => void` | Shows "Group by this field" / "Remove grouping". |
| 3b | `onGroupToggle?: (key: string, collapsed: boolean) => void` | Shows the header's toggle. |
| 4 | `canMove?: boolean` | Row drag. Default false. |
| 4 | `rowColor?: (record: T) => SheetRowColor \| undefined` | 10.2. |
| 5 | `currentMatch?: { recordId: RecordId; fieldId: string } \| null` | 11.1. |
| 5 | `onSelectionChange?: (selection: SheetSelection<T> \| null) => void` | 11.2. |

`AttachmentField['upload']`'s second parameter gains
`onProgress: (fraction: number) => void` (11.4).

### 4.5 `SheetApi` and blocks

`SheetApi` gains (all no-ops when their feature is off):

```ts
/** Scrolls a cell into view without focusing it. */
scrollToCell(cell: { recordId: RecordId; fieldId: string }): void;
/** The selection now, or null. */
getSelection(): SheetSelection | null;
/** Opens the shortcut list. */
showShortcuts(): void;
/** Opens the field editor on a field, or to create one at `index` (default: the end). */
editField(fieldId: string): void;
addField(options?: { index?: number }): void;
/** Emits the move of these records next to `target` (as a row drag would). */
moveRecords(ids: RecordId[], target: { recordId: RecordId; position: 'before' | 'after' }): void;
```

`focusCell` is unchanged; with groups it still does nothing for a record
that is not in `@records` (a collapsed group): the owner expands first.

`SheetBlockApi` gains `selection`, `groupBy` (`@groupBy` or `[]`),
`groups` (`@groups` or `[]`), `setGroupBy(groupBy)` and `toggleGroup(key)`
(each calls the owner's handler, nothing without it), `showShortcuts()` and
`addField()`.

### 4.6 Messages and theme tokens

New keys of `SheetMessages` (`src/core/messages.ts`, tokens `euiSheet.<key>`,
same shape as the existing entries at lines 106-310):

- Batch 1: `shortcuts`, `shortcutsNavigation`, `shortcutsSelection`,
  `shortcutsEditing`, `shortcutsRecords`, `shortcutsClipboard`, and one
  `shortcut*` key per listed action (about 30; 5.5 lists them).
- Batch 2: `addField`, `editField`, `insertFieldLeft`, `insertFieldRight`,
  `duplicateField`, `duplicateFieldLabel(label)`, `deleteField`, `deleteFieldConfirm(label)`,
  `fieldName`, `fieldType`, `fieldDescription`, `fieldRequired`,
  `fieldOptions`, `addOption`, `removeOption`, `save`, `cancel`,
  `fieldNameRequired`, `fieldTypeChangeWarning`, and `fieldType_<name>` for
  the 17 built-in types.
- Batch 3b: `groupByField`, `removeGrouping`, `groupLabel(field, value)`,
  `groupEmpty`, `groupCount(count)`, `groupContinued`, `expandGroup`,
  `collapseGroup`.
- Batch 4: `moveRecord`, `moveRecords(count)`, `notADateTime(text)`.
- Batch 5: `uploading(percent)`, `selectionHandle`.

New theme properties (`src/-private/theme.ts`, each with a light fallback
in `styles.ts`):

| Property | From `euiTheme.colors` | Used by |
| --- | --- | --- |
| `--euiSheet-group` | `backgroundBaseSubdued` | group header rows (opaque) |
| `--euiSheet-match` | `warning` | the current match's ring |
| `--euiSheet-rowPrimary`, `-rowAccent`, `-rowSuccess`, `-rowWarning`, `-rowDanger`, `-rowNeutral` | `primary`, `accent`, `success`, `warning`, `danger`, `textSubdued` | row colour bars |

The drop line of both drags and the touch handles use `--euiSheet-primary`.

### 4.7 Changes that are not purely additive

| # | Change | Who notices |
| --- | --- | --- |
| X1 | Add row: with row numbers, `[data-test-subj=euiSheetAddRecord]` holds only the text (the "+" is in the row-number cell). | Tests or CSS that look for an icon there. |
| X2 | With `@fieldDrag` on (the default) the data header cells are inside the grid's droppable and draggable wrappers, show a drag icon on hover, and their resizer is a sibling of the header cell, not a child (`header-row.gts:190-232`). | Tests or CSS that reach into header internals. `@fieldDrag={{false}}` gives the v0.2 DOM. |
| X3 | `ChangeSet['source']` gains `'move'`; `ChangeSet` gains `moves?`, `RecordInsert` gains `groupKey?`. | Code that switches exhaustively over `source`. |
| X4 | With `@groups`: per-group add rows replace the add row at the end, and a row's number is no longer always `rowNumberOffset + index + 1` (8.4). | Only apps that pass `@groups`. |
| X5 | Ctrl/Cmd+/ on the sheet opens the shortcut list. | Apps that bound it themselves around the sheet. |
| X6 | A bare sheet keeps a resized width when the column order changes (5.3). v0.2 dropped it. | A fix; listed because behaviour changes. |
| X7 | `rowModel`, `recordRowAt` and friends replace `recordAt(row)` semantics inside the component: `sheet.recordAt(gridRow)` still works, but private cells that read `sheet.args.records[rowIndex]` must not. | The package's own cells only (`row-number-cell.gts`, `sheet-cell.gts`). |
## 5. Batch 1: add row, column drag, header wrap, shortcut list

### 5.1 Scope

1. The add row drawn as one quiet row.
2. Drag a header to reorder fields; emits the existing `onFieldOrderChange`.
3. `@headerLines`: header labels that wrap.
4. A shortcut list on Ctrl/Cmd+/.

Public API of the batch (4.4, 4.5): `@fieldDrag`, `@headerLines`,
`api.showShortcuts()`, the block's `showShortcuts()`. Not additive: X1, X2,
X5, X6.

### 5.2 The add row

What the code does today (the cause of each point of the screenshot):

| Seen | Cause in the code |
| --- | --- |
| Two plus signs | `row-number-cell.gts:87-92` draws a plus in `.euiSheet__rowAdd`; `sheet-cell.gts:107-111` draws another before "Add record". |
| The row-number plus is at the start, not centred | `styles.ts:29`: `.euiSheet__rowCell [data-datagrid-cellcontent]` is `display:flex; justify-content:space-between`, made for label + expand icon; a single child goes to the start. |
| Two backgrounds | `styles.ts:28`: `.euiSheet__rowCell` always has `--euiSheet-subdued`; frozen cells paint an opaque `--euiSheet-plain` (`styles.ts:67-68`); the other cells are the grid's own. `.euiSheet__addRow` (`styles.ts:40-41`) sets only cursor, colour and a hover tint. |
| Column dividers | The grid's cell borders; the add row does not remove them. |
| Pale grey focus box on the row-number cell | Not found in the sheet's CSS: `styles.ts:12` gives every `.euiDataGridRowCell:focus` the blue outline. The grey box is presumably the grid's own control-column focus style showing with or over it. To be seen in Chromium (14). |

The implementer first reproduces each in Chromium (light and dark, frozen
on and off, hover, focus on the row-number cell and on a data cell of the
add row), records the computed styles that cause them in the results, and
then fixes them. Target:

- **One plus.** With row numbers: the plus in the row-number cell, centred
  both ways; the first field shows only the text "Add record"
  (`.euiSheet__addRecord` without an icon), in `--euiSheet-textSubdued`.
  Without row numbers (`@rowNumbers={{false}}`): the first field keeps
  "+ Add record", the only plus.
- **One background** for every cell of the row, frozen or not, the
  row-number cell included: opaque `--euiSheet-plain`. Hover: the same base
  with the hover colour over it as a `background-image` gradient (the way
  frozen cells already draw hover, `styles.ts:69`), so frozen and
  non-frozen cells are the same colour.
- **No inner dividers**: the add row's cells have no visible inline
  borders; the row keeps its top border from the last record.
- **The sheet's focus ring** (2 px `--euiSheet-primary`, offset −2) on any
  focused cell of the row, the row-number cell included, and nothing else.
- The add-field column's cell (batch 2) and group add rows (batch 3b) use
  the same class, so they inherit all of it.

```css
.euiSheet .euiSheet__addRow > .euiDataGridRowCell,
.euiSheet .euiSheet__addRow > .euiDataGridRowCell.euiSheet__rowCell,
.euiSheet .euiSheet__addRow > .euiDataGridRowCell.euiSheet__cell--frozen {
  background-color: var(--euiSheet-plain, #FFF); background-image: none;
  border-inline-color: transparent;   /* the property to be confirmed in Chromium */
  color: var(--euiSheet-textSubdued, #69707D); cursor: pointer;
}
.euiSheet .euiSheet__addRow:hover > .euiDataGridRowCell {
  background-image: linear-gradient(var(--euiSheet-hover), var(--euiSheet-hover));
}
.euiSheet .euiSheet__rowCell--add [data-datagrid-cellcontent] { justify-content: center; }
.euiSheet .euiSheet__addRow > .euiDataGridRowCell:focus {
  outline: 2px solid var(--euiSheet-primary, #0B64DD); outline-offset: -2px; box-shadow: none;
}
```

This is the intended shape, not verified CSS: specificity against the
grid's Emotion classes is settled while reproducing.

### 5.3 Drag to reorder columns

**Reachable without a grid change: yes.** `canDragAndDropColumns` is a
field of the public `@columnVisibility` object
(`utils/data-grid/types.ts:165`), read at `header-row.gts:85-87`. The sheet
already builds that object (`eui-sheet.gts:849-854`), so it adds
`canDragAndDropColumns: this.fieldDrag` (`@fieldDrag ?? true`, and more
than one visible field). The path of a drop:
`header-row.gts:127-144` `onDragEnd` → `grid.switchColumnPos`
(`eui-data-grid.gts:444-453`) → `setSortedColumns` →
`columnVisibility.setVisibleColumns` → the sheet's `setVisibleColumns`
(`eui-sheet.gts:861-871`) → `setFieldOrder` → `@onFieldOrderChange`, or the
sheet's own order. No new intent.

The drag is native HTML5 drag and drop (`@atlaskit/pragmatic-drag-and-drop`,
`eui-draggable.gts:368`), with a keyboard mode: Space on a focused header
lifts the column, the arrows move it, Space drops, Escape cancels
(`header-row.gts:42-49`).

How it coexists with what the sheet has:

| With | Finding | Design |
| --- | --- | --- |
| The first field stays first | Today only the menu enforces it (`showMoveLeft: index > 1`, `eui-sheet.gts:996-999`). A drag can send any order. | `setVisibleColumns` puts the current first id back in front of what it received before comparing. A result equal to the current order is a no-op. |
| The grid's own order state | `switchColumnPos` starts from `sortedColumns`, the grid's private state, which is re-derived only when a new `@columns` array arrives (`eui-data-grid.gts:403-440`). After a drop the sheet did not apply (the no-op above, or an owner that ignores the intent) the next drag would start from an order that is not on screen. | A tracked `orderEpoch` read by `get columns` (`eui-sheet.gts:987`). `setVisibleColumns` checks after the next render whether the visible ids equal the ids the grid sent; if not, `orderEpoch++`, which gives the grid a new array and resets its state. |
| Resized widths | A new `@columns` array makes the grid drop the widths it kept (`eui-sheet.gts:980-985`; `resizedWidths` is tied to the array's identity, 881-903). So a reorder in a bare sheet loses resized widths today, and the epoch would too. | X6: `onColumnResize` also stores the width in a plain (untracked) map; `get columns` uses it as `initialWidth` when `@fieldWidths` and `field.width` give none. Untracked, so a resize does not rebuild the columns. |
| The header menu | The actions button is inside the draggable cell; the draggable is created with `@hasInteractiveChildren` (`header-row.gts:207`), and Enter on the cell opens the menu while Space lifts it (`header-cell.gts:253-262`). | Nothing. The sheet's capture `keydown` handles only Delete and Backspace on a header (`eui-sheet.gts:3493-3505`); CD4 checks Space reaches the grid. |
| Click on a title selects the column (`eui-sheet.gts:3379-3386`) | A native drag starts only after the pointer moves; a click without movement stays a click, and a drop fires no click. | Nothing; CD3. The sheet's capture `mousedown` must not call `preventDefault` on a header (that would cancel the drag): checked in CD1. |
| The resizer | With drag on it is rendered after the header cell, inside the draggable wrapper, so that both work (`header-row.gts:222-232`; `header-cell.gts:167-171`). `@onColumnResize` is the same. | X2. FZ5 (resize of the frozen field) runs with drag on. |
| Sort arrows | Inside the header cell (`header-cell.gts:502-509`). | Nothing. |
| Frozen sticky headers | **Conflict.** The sheet makes the header *cell* sticky (`.euiSheet__frozenHeader`, `styles.ts:72`). With drag on, the cell's parent is the draggable wrapper, `position:relative` and exactly the cell's size (`draggable_columns.styles.ts`, `euiDataGridHeaderCellDraggableWrapper`), so the cell cannot stick outside it and the frozen header would scroll away. | Make the wrapper sticky instead: next to `frozenHeaderLefts()` (`styles.ts:121-130`) generate `.euiSheet .euiDataGridHeaderCellDraggable:has(.euiSheet__frozenHeader--N) { position: sticky; left: var(--euiSheetFrozenLeft-N); z-index: 3; }`. The wrapper's parent is the droppable, a flex box as wide as all data columns inside the sticky header row. Gate: CD6. If it fails, `fieldDrag` is off while a field is frozen (the menu's Move left / right remain) and the results say so. |
| The row-number column, the add-field column | Control columns are rendered outside the droppable (`header-row.gts:174-183, 248-257`). | They cannot be dragged or be a drop target. |
| File drops | The sheet's `dragover` and `drop` handlers return unless the drag carries files (`eui-sheet.gts:4940-4941`). | Nothing. |
| Auto-scroll | The grid scrolls its body sideways while a header is dragged near an edge (`header-row.gts:148-155`). | Nothing. |
| Touch | Native drag does not start from a touch on most phones. | Not supported by touch; Move left / right in the menu. Listed in 14. |

### 5.4 Header text wrap

`@headerLines` (1, 2 or 3; default 1) puts `euiSheet--headerLines2` or `3`
on the wrapper:

```css
.euiSheet--headerLines2 .euiDataGridHeaderCell__content {
  white-space: normal; overflow-wrap: anywhere; overflow: hidden;
  display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 2;
}
```

No grid change is needed for the height: the body measures the header row
with a `ResizeObserver` (`body.gts:532-533, 604-615`) and offsets the rows
by it (`row.gts:53`). It is not tied to `@rowHeight`: a short row height
with long labels is the common case. A cut label keeps its full text in
the cell's `title` (`header-cell.gts:489-492`). A header with a
description renders its own component inside the same content element
(`eui-sheet.gts:968-979`), so it wraps too.

### 5.5 Shortcut list

- Ctrl/Cmd+/ in `handleCommandKey` (`eui-sheet.gts:3582`) while focus is in
  the grid and no editor is open; `api.showShortcuts()` and the block's
  `showShortcuts()` for a toolbar button. Not `?` (D11).
- `src/-private/shortcut-list.gts`: an `EuiModal` with the sheet's theme
  class (as `record-shells.gts` does for the expanded record). Escape
  closes it and focus returns to the cell it came from.
- `src/-private/shortcuts.ts`: a static table of sections (Navigation,
  Selection, Editing, Records, Clipboard and history), each row
  `{ keys: string[][]; message: keyof SheetMessages; when?: (sheet) => boolean }`.
  It lists what `docs/sheet.md` "Keyboard" (line 620) documents, one row
  each. `Mod` is drawn as ⌘ on a Mac and Ctrl elsewhere. A row whose
  feature is off (`@canInsert`, `@canDelete`, `@readOnly`, no
  `@onGroupToggle`) is left out.
- Every text is a messages token (4.6), so `@messages` and `eui-i18n`
  translate it. Key names (Enter, Esc, Tab) are tokens too.
- Later batches add their rows (group toggle, row drag has none).

### 5.6 Files

| File | Change |
| --- | --- |
| `src/-private/styles.ts` | 5.2 rules; `:has()` rules for frozen draggable headers; `headerLines` rules |
| `src/-private/row-number-cell.gts` | nothing but the class (the plus stays) |
| `src/-private/sheet-cell.gts` | the plus only without row numbers (`sheet.colOffset === 0`) |
| `src/components/eui-sheet.gts` | `fieldDrag`, `orderEpoch`, the first-field rule in `setVisibleColumns`, kept widths, `headerLines` class, Ctrl/Cmd+/ |
| `src/-private/shortcuts.ts`, `shortcut-list.gts` (new) | 5.5 |
| `src/core/messages.ts`, `src/types.ts` | tokens, args, `SheetApi.showShortcuts`, block `showShortcuts` |

### 5.7 Tests

`tests/integration/components/eui-sheet-rows-test.gts` (add row):

| # | Check |
| --- | --- |
| AR1 | With row numbers: exactly one plus icon in the add row, in the row-number cell; `[data-test-subj=euiSheetAddRecord]` has the text and no icon. |
| AR2 | The plus's box centre is within 1 px of the row-number cell's centre, both axes. |
| AR3 | Every cell of the add row has the same computed `background-color`, and it is opaque; with `@frozenFields={{1}}` and without. |
| AR4 | AR3 in the dark theme (the theme test's provider, `eui-sheet-theme-test.gts`). |
| AR5 | No cell of the add row has a visible inline border (computed width 0 or transparent colour). |
| AR6 | The focused row-number cell of the add row: computed `outline-color` is `--euiSheet-primary`, `outline-width` 2 px, no `box-shadow`. The same for a focused data cell of the row. |
| AR7 | `@rowNumbers={{false}}`: the first field shows one plus and the text. |
| AR8 | Enter and click on the row still insert (the existing tests, unchanged, plus a click on the text). |

Hover cannot be forced in an integration test; it is in the real-input
list of the results.

`tests/integration/components/eui-sheet-view-test.gts` (column drag,
header wrap):

| # | Check |
| --- | --- |
| CD1 | Default: the droppable and one draggable per field exist; `@fieldDrag={{false}}`: neither. A `mousedown` on a header title is not default-prevented. |
| CD2 | Keyboard drag (Space, ArrowRight, Space) on the third field calls `onFieldOrderChange` with the new order; without the handler the sheet's own order changes. |
| CD3 | A click on a title still selects the column; Shift+click extends. |
| CD4 | Dropping a field on the first position leaves the first field first and emits the order with it in front. Then a second drag gives the order a user would expect from what is on screen (the stale-order case). |
| CD5 | An owner that ignores `onFieldOrderChange`: the columns stay, the dev warning is logged once, and the next drag starts from the shown order. |
| CD6 | Gate. `@frozenFields={{1}}` with drag on: FZ3's checks (the frozen header cells keep their `left` after a horizontal scroll and stay above the body). |
| CD7 | Resize a column, then drag another: the resized width is kept (bare sheet). FZ5 passes with drag on. |
| CD8 | The header menu opens with Enter and its Move left / right still work; the sort arrow is drawn. |
| CD9 | With an editor open, starting a drag commits the edit. |
| HW1 | `@headerLines={{2}}` with a long label: the header row is taller than with 1, the first body row's `top` equals the header's `bottom`, and the label's box is at most two line heights. |
| HW2 | The same with `@frozenFields={{1}}` and with a description icon. |
| HW3 | Default: one line, as today. |

`tests/integration/components/eui-sheet-polish-test.gts` (shortcut list):

| # | Check |
| --- | --- |
| KH1 | Ctrl+/ on a cell opens the list; Escape closes it and the cell has focus again. |
| KH2 | `@canInsert={{false}}`: no insert rows. `@messages` overrides a row's text. |
| KH3 | `api.showShortcuts()` and the block's `showShortcuts` open it. |
| KH4 | `/` and `?` typed on a text cell still open the editor. |

### 5.8 Docs

- `docs/sheet-demo/d12-view-intents.md`: drag a header; a "Header lines"
  select.
- `docs/sheet-demo/d18-editing.md`: a "Shortcuts" button in the toolbar.
- `docs/sheet.md`: "Presentation state" (drag, `@fieldDrag`,
  `@headerLines`), "Keyboard" (Ctrl/Cmd+/, the header's Space drag), the
  arguments table. `README.md`: the same three lines.

### 5.9 Risks

- **Frozen headers with drag on** (CD6): gated, with a fallback.
- **Header DOM change by default** (X2). Existing tests that reach into
  header internals may need `@fieldDrag={{false}}` or a new selector; each
  one changed is listed in the results. If more than a handful break, that
  is the signal to take D8's alternative (off by default).
- **The add row's causes are inferred from CSS**, not seen. The first task
  is to reproduce; if a cause is different, the target of 5.2 stays and
  the rules change.
- The drag icon appears on hover in every header; with narrow columns it
  takes room from the label. Seen in the real-input check.
## 6. Batch 2: field management

### 6.1 Scope

From the grid: add a field (a "+" column at the right, Insert left / right
in the header menu), edit a field (name, type, the type's options,
description, required), duplicate a field, delete a field. The owner owns
`@fields`: each is an intent. The sheet provides the editor UI; an app can
replace its content.

### 6.2 Intents

```ts
onFieldCreate?: (
  draft: SheetFieldDraft,
  position: {
    /** Index among the visible fields where it should appear. */
    index: number;
    /** The visible field before it. */
    after?: string;
    /** Set by "Duplicate field": the field it copies. The owner decides whether values are copied. */
    copyOf?: string;
  }
) => void | Promise<void>;
onFieldUpdate?: (
  fieldId: string,
  draft: SheetFieldDraft,
  context: { previous: EuiSheetField<T> }
) => void | Promise<void>;
onFieldDelete?: (fieldId: string) => void | Promise<void>;
```

- Each handler shows its own controls and nothing else does: no handler,
  no control. There is no local fallback in the component (fields are the
  owner's data model, not presentation); a bare app passes
  `localRecords`' handlers (6.7).
- A returned promise keeps the editor open in a saving state; when it
  rejects, the editor stays open and shows `error.message` (a duplicate
  name refused by a server). Without a promise it closes at once.
- The draft holds plain values only. The owner builds the field
  (`{ ...previous, ...draft }` on update, `{ id: <its id>, ...draft }` on
  create) and passes the new `@fields`.
- `field.manageable === false` removes Edit, Duplicate and Delete for that
  field (system fields). The first field cannot be deleted, and nothing
  can be inserted to its left (it stays first, V02-DESIGN.md 6.3).

### 6.3 Where the controls are

- **Header menu** (`actions.additional` of each column, where "Filter by
  this field" already is, `eui-sheet.gts:1003-1013`): Edit field, Duplicate
  field, Insert left, Insert right, and Delete field last, in the danger
  colour. Duplicate emits `onFieldCreate` at once with the field's draft,
  the label `messages.duplicateFieldLabel(label)` ("Name copy"),
  `index + 1` and `copyOf`.
- **The "+" column** (W8), only with `@onFieldCreate`: a trailing control
  column `{ id: 'euiSheet-addField', width: 40 }`. Its header cell shows a
  plus (a span; the header cell itself is the grid's focusable header).
  Click, Enter or Space on it opens the editor to create a field at the
  end. The sheet's `<:controlHeaderCell>` and `<:controlCell>` blocks
  (`eui-sheet.gts:5103-5112`) switch on the yielded `columnId`.
- Its body cells are empty and inert: no background of their own (the add
  row and group rows paint them like their other cells), no ring.
  `dataCell()` already returns null for them. Keys: on a body row the
  sheet stops ArrowRight on the last field, and handles End and Ctrl+End
  itself to land on the last field, as `handleHomeKey` does for the
  row-number column (`eui-sheet.gts:3702-3711`). In the header row
  ArrowRight reaches the "+" cell, which is how the keyboard gets there.
- `virtualizationOptions.overscanColumnCount` for frozen fields counts the
  extra column (`eui-sheet.gts:1119`).
- `api.addField({ index })` and `api.editField(fieldId)` open the same
  editor, so a toolbar or a field picker can.

### 6.4 The field editor

`src/-private/field-editor.gts`: a panel positioned by the sheet beside
the grid, under the header cell it belongs to (the row menu's way,
`row-menu.gts`), clamped to the wrapper, with the sheet's theme class and a
focus trap. It is not inside the header cell (P9). Escape and Cancel close
it and focus the header cell; a grid scroll or a click outside cancels it.

Built-in content:

| Part | Control | Notes |
| --- | --- | --- |
| Name | text input, focused on open | Required (`fieldNameRequired`). Enter saves. |
| Type | select | The types of `@creatableFieldTypes`, labelled by `type.label ?? messages.fieldType_<name>`. Changing it on an existing field shows `fieldTypeChangeWarning`. |
| Type options | the type's `fieldOptions` component | Below. |
| Description | two-line textarea | |
| Required | switch | Hidden when `field.required` is a function. |
| Save, Cancel | buttons | Save is busy while the handler's promise is pending. |

`EuiSheetFieldType.fieldOptions?: ComponentLike<{ Args: { draft:
SheetFieldDraft; onChange: (patch: Record<string, unknown>) => void;
messages: SheetMessages } }>`. Built-ins that have one: `singleSelect` and
`multiSelect` (the options: label, one of EuiBadge's named colours, add,
remove; hidden when `options` is a function), `currency` (code,
precision), `percent` (precision), `rating` (max), `date` (day/month
order), `duration` (format), and `dateTime` from batch 4. An app type adds
its own the same way.

`@creatableFieldTypes` defaults to the built-ins a draft can fully
describe: text, longText, number, currency, percent, checkbox,
singleSelect, multiSelect, date, duration, rating, url, email, phone.
Not `linkedRecord`, `user` or `attachment`: they need `search` or `upload`
functions. An app lists them and completes the field in its handler.

`@fieldEditor` replaces the content (the sheet keeps the frame, position,
focus return and saving state):

```ts
export interface SheetFieldEditorSignature<T = any> {
  Args: {
    mode: 'create' | 'edit';
    /** The field being edited; absent on create. */
    field?: EuiSheetField<T>;
    /** The starting values. */
    draft: SheetFieldDraft;
    types: Array<{ name: string; label: string }>;
    isSaving: boolean;
    error?: string;
    onSave: (draft: SheetFieldDraft) => void;
    onCancel: () => void;
    messages: SheetMessages;
    themeClass?: string;
  };
}
```

### 6.5 Values on a type change

The sheet changes no value. After `onFieldUpdate` with another type the
cells show the stored values through the new type's `format` and
`validate`, whatever they are. Converting is the owner's, with a helper
(`src/core/convert.ts`, new; the sheet never calls it):

```ts
/** The change set that rewrites `from`'s values as `to`'s. */
export function convertField<T>(
  ctx: Pick<SheetContext<T>, 'types' | 'messages' | 'getRecordId'>,
  records: readonly T[],
  from: EuiSheetField<T>,
  to: EuiSheetField<T>
): ChangeSet;
```

Per record: the old type's `copyText(value)`, then the new type's
`parse(text, to, { source: 'paste' })`. A value gives a patch; an error or
an unresolved text gives a patch to the new type's empty value and a
`rejected` entry with the text and the message, so the owner can report
what was lost. New select options are collected in `newOptions`. This is
the paste path, so "what converts" is exactly "what could be pasted".

### 6.6 Undo

Field operations are **not undoable by the sheet** (D6). The undo stack
holds change sets, which are values by record id and field id. Undoing a
delete would need every value the field had, including in records that are
not loaded, and undoing a type change would need the values before the
owner converted them; only the owner has either. So:

- Delete asks first, in the editor's frame (`deleteFieldConfirm(label)`,
  a danger button).
- When `@fields` loses a field, or a field's `type` changes, the sheet
  drops that field's patches from its undo and redo entries (an entry left
  empty is removed), its rejected texts and its pending cells, and cancels
  an open editor on it. Otherwise Ctrl+Z after a delete would emit patches
  for a field that is gone.
- An owner can make them undoable in its own UI; nothing in the contract
  prevents it.

### 6.7 `localRecords`

`LocalRecords` gains the bound `createField`, `updateField` and
`deleteField`, matching the three intents (it must be given `fields`):

- create: the id is a slug of the label made unique (`estado`,
  `estado-2`); the field is inserted at `position.index`; with `copyOf`
  the values are copied.
- update: `{ ...previous, ...draft }`; on a type change it applies
  `convertField` and keeps the rejected entries in `log`.
- delete: removes the field and the key from every record.

### 6.8 With existing features

| Feature | Behaviour |
| --- | --- |
| Hidden fields | The menu is on visible fields only. `api.editField` works for a hidden field (the panel opens under the "+" cell, or the wrapper's top right without it). |
| Column drag, widths, frozen | A created field has no width (the grid's default). Inserting next to a frozen field does not change `@frozenFields`. |
| Selection | Kept by position after `@fields` changes, clamped, as today when fields change. |
| Expanded record | Shows the new `@fields`; no field management inside it in v0.3. |
| Validation | `@validate` runs again when `@records` change (the owner converted); `required` from the draft is checked by the existing layers. |
| The connector | `EuiSheetSearch` forwards the three arguments. Its fields come from the app or the driver's schema, so the app's handlers change those. |
| Groups (3b) | Deleting or retyping the grouped field is the owner's to react to (it usually clears `@groupBy`). |

### 6.9 Files

| File | Change |
| --- | --- |
| `src/core/types.ts` | `SheetFieldDraft`, `EuiSheetField.manageable` |
| `src/core/convert.ts` (new) | `convertField` |
| `src/core/history.ts` | `withoutField(entry, fieldId)` |
| `src/core/messages.ts` | 4.6 |
| `src/components/eui-sheet.gts` | args, menu items, trailing column, End/ArrowRight rule, editor state, history pruning on `@fields` change |
| `src/-private/field-editor.gts` (new), `src/-private/field-options/*.gts` (new) | the panel, the built-in type option forms |
| `src/-private/styles.ts` | the "+" column, the panel |
| `src/field-types.ts` | `fieldOptions` on the built-ins that have one |
| `src/local-records.ts` | 6.7 |
| `src/search-ui/eui-sheet-search.gts` | forwarded args |
| `src/types.ts`, `src/index.ts` | signature, `SheetApi.addField` / `editField`, exports |

### 6.10 Tests

`tests/unit/core/convert-test.ts`:

| # | Check |
| --- | --- |
| FC1 | text → number: "12" becomes 12; "abc" becomes null with a rejected entry. |
| FC2 | text → singleSelect: matching labels convert; with `createOnPaste` the others become `newOptions`. |
| FC3 | singleSelect → text: the option's label. |
| FC4 | number → currency and back: unchanged values give no patch. |
| FC5 | date → text → date round-trips. |
| FC6 | Empty values give no patch and no rejection. |

`tests/integration/components/eui-sheet-fields-test.gts` (new):

| # | Check |
| --- | --- |
| FM1 | Without the handlers: no "+" column, no menu items. |
| FM2 | With `@onFieldCreate`: the "+" header cell exists; a click opens the editor with the name focused. |
| FM3 | Save calls `onFieldCreate(draft, { index: <count>, after: <last id> })`; the editor closes; focus is on the header. |
| FM4 | Insert left / right from the menu pass the right `index` and `after`; no Insert left on the first field. |
| FM5 | Edit field opens with the field's values; Save calls `onFieldUpdate(id, draft, { previous })`. |
| FM6 | Changing the type shows the warning; the options form follows the type. |
| FM7 | Select options: add, rename, recolour and remove end up in `draft.options`; existing `value`s are kept. |
| FM8 | A handler that returns a promise: Save is busy; a rejection shows the message and keeps the editor open; resolving closes it. |
| FM9 | Delete field asks, then calls `onFieldDelete(id)`; not offered on the first field or with `manageable: false`. |
| FM10 | Duplicate calls `onFieldCreate` with `copyOf` and `index + 1`. |
| FM11 | Escape cancels and focuses the header cell; a click outside cancels. |
| FM12 | ArrowRight and End on the last field stay on it; from the last header, ArrowRight reaches the "+" cell and Enter opens the editor. |
| FM13 | The "+" column with `@frozenFields={{1}}` and with `@summary`: rendered, empty footer cell, FZ1 still holds. |
| FM14 | After an edit of a cell and a delete of its field, Ctrl+Z emits nothing for it (the entry was pruned); an entry that also touched another field emits only that field's patch. |
| FM15 | `@fieldEditor`: the app's component gets `mode`, `draft`, `types`; its `onSave` reaches the handler. |
| FM16 | `@creatableFieldTypes` limits the type select; an app type with `label` and `fieldOptions` is offered and its form shown. |
| FM17 | `localRecords` end to end: create a number field, type in it, change it to text (values converted), duplicate it with values, delete it. |
| FM18 | `api.addField()` and `api.editField(id)`. |
| FM19 | The add row and a selected range look right with the "+" column: its cell in the add row has the add row's background (AR3 with the column). |

### 6.11 Docs

- `docs/sheet-demo/d20-fields.md`: "Fields from the grid", on
  `localRecords`, with a note of what converting keeps and loses.
- `docs/sheet-demo/d04-custom-cells.md`: an app type with `label` and
  `fieldOptions`.
- `docs/sheet.md`: a "Fields" section (the three intents, the draft, what
  the owner does, `convertField`, no undo); arguments table; "Field types"
  gets `label` and `fieldOptions`. `README.md`: feature list and one
  example.

### 6.12 Risks

- **Focus in the trailing column's body cells.** A click there may focus
  the cell (the grid focuses a clicked cell). The design makes it
  invisible and ArrowLeft returns; if it proves confusing, `onFocusIn`
  moves focus to the row's last field.
- **Where `actions.additional` items appear** among the grid's own (hide,
  move, sort) is the grid's order (`column-actions.gts`); Delete may not
  end up last. Unverified; if the order is poor the sheet's items can be
  split with a separator the grid supports, or reordered through the
  action props.
- **Drafts and functions.** A field whose `options`, `required` or
  `validate` are functions is only partly editable; the editor hides those
  parts rather than replace a function with data.
- **A server that renames ids** on create is fine (the owner passes the
  new `@fields`); one that changes an id on update loses the sheet's
  per-field state (widths, undo), as any id change does.
## 7. Batch 3a: the row model (no behaviour change)

### 7.1 Scope

A mapping layer between grid rows and records, add rows and group headers,
used everywhere the component reads a row. In this batch the only model is
the identity one (4.2), so nothing a user or a test can observe changes.
**No existing test file is edited.** If one has to be, the refactor changed
behaviour: fix the refactor.

### 7.2 Core: `src/core/rows.ts` (new, plain TypeScript)

```ts
export type SheetRow =
  | { kind: 'record'; record: number }      // index into @records
  | { kind: 'add'; group: number }          // -1: the add row at the end (no groups)
  | { kind: 'group'; group: number };       // index into @groups

export interface RowModel {
  readonly length: number;
  at(gridRow: number): SheetRow | undefined;
  /** -1 for a header, an add row or a row outside the model. */
  recordRowAt(gridRow: number): number;
  gridRowOf(recordRow: number): number;
  /** The records inside a grid range, as a record range; null when it holds none. */
  recordRange(range: Range): Range | null;
  /** The grid rows of the first and last record; -1 without records. */
  readonly firstRecordRow: number;
  readonly lastRecordRow: number;
  /** The nearest record row at or after (step 1) / at or before (step -1) a grid row; -1 when none. */
  nearestRecordRow(gridRow: number, step: 1 | -1): number;
  /** The group a grid row is in (its header's index in @groups), -1 without groups. */
  groupAt(gridRow: number): number;
  /** The add row of a group (or of the sheet with -1); -1 when it has none. */
  addRowOf(group: number): number;
}

export function buildRowModel(input: {
  recordCount: number;
  addRow: boolean;
  /** Batch 3b. Absent or empty: the identity model. */
  groups?: readonly Pick<SheetGroup, 'depth' | 'loaded' | 'collapsed'>[];
}): RowModel;
```

- The identity model is closed-form (`recordRowAt(g) = g < n ? g : -1`,
  `gridRowOf(r) = r`): no arrays, so 100,000 records cost nothing.
- The grouped model (written in this batch, used by the component in 3b)
  holds two `Int32Array`s, `rowToRecord` and `recordToRow`, and a small
  array of the non-record rows. Building it is one pass over `@groups`.
- `buildRowModel` is written and unit-tested for groups in this batch (the
  RM tests), so 3b starts from a tested mapping.

### 7.3 Component

- `@cached get rowModel()` from `@records.length`, `hasAddRow` (and
  `@groups` in 3b). `rowCount` becomes `rowModel.length`.
- `recordAt(gridRow)` keeps its name and answers through the model. New:
  `recordRowAt`, `gridRowOf`, `recordRange`, `recordPos(pos)`,
  `gridPos(recordPos)`, `rowKind(gridRow)`, `isRecordRow(gridRow)`.
  `isAddRow(gridRow)` asks the model.
- Rule for the rewrite: (1) no `this.args.records[x]` where `x` came from a
  position, a cell or the DOM: use `recordAt(x)`; (2) no
  `records.length - 1` as "the last row": use `rowModel.lastRecordRow`;
  (3) every call into `src/core` gets `recordRange(range)` or
  `recordPos(pos)`, and a position the core returns (`edgeTarget`) goes
  through `gridPos`; (4) a `null` record range means "nothing to do" (what
  the clamps did for a range on the add row).
- The assert in `cursor` (`eui-sheet.gts:2468-2472`) stays: the grid's data
  row index still equals its visible row index. Grid rows are the grid's
  row indexes.

### 7.4 Every place that assumes grid row = record index

From `grep` over the component (about 130 lines in 75 methods) and the
package. "Record" means the site ends up in record space, "grid" that it
stays in grid rows and asks the model for the kind.

| Cluster | Sites (`eui-sheet.gts` line of the method) | After 3a |
| --- | --- | --- |
| Row helpers | `hasAddRow` 1351, `isAddRow` 1355, `rowCount` 1521, `recordAt` 1526 | Model. |
| Add-row class | `gridStyle` 1392: `rowClasses[records.length]` | `rowClasses[rowModel.addRowOf(-1)]`; 3b adds header and group add rows. |
| Row numbers | `positionOf` 1402, `rowLabelOf` 1407, `rowColumnWidth` 1367 (calls `positionOf(i)` per record), `recordTitleOf` 2371 | `positionOf(gridRow)` = `numberOf(recordRowAt(gridRow))`; `numberOf(r) = offset + r + 1` (3b: 8.4). |
| Drawn selection | `isSelected` 1575, `isRowSelected` 1417, `cellView` 1586, `isFillPreview` 3058 | Grid; `cellView` returns null for a non-record row (it already does for `undefined`). |
| Checked rows | `isChecked` 1435, `checkedState` 1453, `toggleChecked` 1478 (loops `records[r]` between `lastToggledRow` and the row, 1489), `selectionRecords` 1509 | The Shift range goes through `recordRange`. |
| Focus and following | `focusGridCell` 1679, `followRecords` 1757 (`lastRow` 1791), `rowOf` 1843 (id → index with a hint), `rowIndexOf` 1889, `focusRowNumberCell` 1903, `cursor` 2465, `onFocusIn` 2513, `onRowNumberFocus` 2559, `focusRecordCell` 3860, `applyPendingFocus` 1815 | `rowOf` stays in record space (it searches `@records`); its callers that focus or select add `gridRowOf`. The others are grid. |
| Insert, delete, duplicate | `insertNear` 1965 (`records[row ± 1]` as neighbours), `appendRecord` 1987, `insertFromApi` 2012, `deleteRecordIds` 2041 (the neighbour to focus), `duplicate` 2077, `copyRows` 2102 | Record: neighbours are records, found with `recordRowAt` then ± 1 in `@records`. |
| Row menu | `openMenu` 2136, `closeMenu` 2155 (`menu.row >= rowCount`), `menuItems` 2179, `menuLink` 2273, `menuRowOf` 3137, `openContextMenu` 3430 | `MenuState.row` is a grid row; the items read `recordAt`. |
| Expanded record | `expandedRecordValue` 2312, `expandRecord` 2323, `closeExpanded` 2331, `expandedStep` 2357 (`records[row + step]`), `formContext` 2385 | Record (they start from `rowOf(id)`); only the refocus on close converts. |
| Touched cells | `touchedAt` 2477, `touchedIn` 2485 (loops `range.top … min(bottom, records.length - 1)`) | `touchedIn` loops the record range. |
| Mouse | `onMouseDown` 2649, `selectRows` 2761 (clamps the anchor to `records.length - 1`), `selectColumns` 2773 (rows `0 … records.length - 1`), `dragOver` 2797, `onRelease` 2830 (`head.row < rowCount`) | Grid. `selectColumns` uses `firstRecordRow … lastRecordRow`; `selectRows` clamps with `nearestRecordRow`. |
| Fill | `fillHandleRange` 2889, `placeFillHandle` 2898, `fillTo` 2954, `fillRightSelection` 3764, `fill` 3773, `onFillRelease` 2993 | The source and target go to `fillRange` / `fillDown` / `fillRight` as record ranges; the handle sits on the range's last record row. |
| Clicks | `editInRecord` 3254, `onClick` 3294, `onControlClick` 3357, `canEdit` 3392, `onDoubleClick` 3402 | Grid; branch on `rowKind`. |
| Keys | `onKeyDown` 3462 (3512), `handleCommandKey` 3582 (Ctrl+A, 3614), `handleNavKey` 3631 (`edgeTarget`; Shift+Ctrl+Home/End rows `0` and `records - 1`; the PageUp/Down clamp at 3648), `moveFocus` 3666, `pageRows` 3680, `handleHomeKey` 3702 (Ctrl+Home to row 0), `onAddRowKeyDown` 3713, `onRowNumberKeyDown` 3724 | `edgeTarget` gets `recordPos` and its result goes through `gridPos`. "Row 0" becomes `firstRecordRow`, "last" `lastRecordRow`; the page clamp is `0 … rowModel.length - 1` (or `lastRecordRow` with Shift). |
| Clipboard | `onCopy` 4129, `onCut` 4150, `onPaste` 4170 (4195-4206), `clearSelection` 3757, `isRangeTarget` 4239 | `rangeMatrix`, `clearRange` get the record range; `buildPaste` gets `recordPos(anchor)`, or `{ row: records.length }` for an add row (what it gets today). |
| History | `applyHistory` 3977 (`records.length` before/after), `selectChanged` 4046 | Record ids; `selectChanged` converts the rows it selects. |
| Editing | `startEdit` 4335, `editorRecord` 4392, `commit` 4398 (4413; the move after commit at 4430), `cancel` 4436, `onEditorSave` 4460, `commitCellValue` 1664 | `editing.pos` is a grid position; `commitText`/`commitValue` get `recordPos`. |
| Files | `pasteFiles` 4820 (`recordAt(range.top)`), `uploadFiles` 4841 (4886), `dropCellAt` 4926 | `pasteFiles` uses the range's first record row. |
| Template | `@rowCount` 5091, `<:controlCell>` `rowIndex` 5109 | `rowModel.length`; the cells get grid rows. |
| Stored positions (fields, not methods) | `anchor`, `head`, `domCursor` 647, `dragFrom` 657, `fillSource` 596, `imePos` 621, `dropPos`, `rowCursor` 632, `lastToggledRow` 628, `menu.row` (`MenuState` 358-366), `editing.pos` | All hold grid rows across renders. In 3a nothing shifts them that did not before. In 3b a change of `@groups` shifts rows without `@records` changing: `anchor`/`head` and `editing.pos` are re-found by record id or group key (4.2, 8.9); `lastToggledRow` and `rowCursor` are kept as record ids instead of rows; a drag, a fill, an IME composition, a file-drop target and an open menu are ended or closed, as `followRecords` already does for a drag. |
| Private cells | `row-number-cell.gts:28-45, 72`, `sheet-cell.gts:35, 64, 79, 103`, `fill-handle.gts` (a range) | They already go through `sheet.isAddRow`, `recordAt`, `rowLabelOf`, `cellView`: no change beyond X7. |
| Core | `change-set.ts:65-68, 97, 133, 158-160`, `paste-plan.ts:74, 159-167`, `fill.ts:20-21, 120, 156-200, 237-238`, `nav.ts:26-48` | **Unchanged.** They index `ctx.records`; the component now hands them record rows. |
| Connector | `src/search-ui/*` | No row index. Unchanged. |

### 7.5 Tests

`tests/unit/core/rows-test.ts` (new):

| # | Check |
| --- | --- |
| RM1 | Identity: 5 records, add row: `length` 6, `at(5)` is the add row, `recordRowAt(5)` −1, `gridRowOf(4)` 4. |
| RM2 | Identity, no add row, and 0 records with an add row (`firstRecordRow` −1). |
| RM3 | `recordRange` of a range that ends on the add row is clamped; of the add row alone is `null`. |
| RM4 | One level, three groups (`loaded` 2, 0 collapsed, 3): rows are header, 2 records, add, header, header, 3 records, add. |
| RM5 | `recordRange` across a header and an add row returns the contiguous records on both sides. |
| RM6 | `nearestRecordRow` from a header (both steps), from the last add row (−1 going down). |
| RM7 | Two levels: a parent header, two child headers with records; `groupAt` of a record is its child. |
| RM8 | A collapsed group and an empty expanded group: no add row for the first, an add row for the second. |
| RM9 | `Σ loaded` smaller than the record count: the rest follow the last group's rows (8.2). |
| RM10 | `Σ loaded` larger than the record count: clamped, no row past the records. |
| RM11 | `addRow: false`: no add rows at all. |
| RM12 | 100,000 records, identity: `buildRowModel` allocates no array (checked by timing under 1 ms, logged). |

Component: the 335 existing tests, unchanged, are the test of this batch.
Run them before the first edit and after the last, with the same seed.

### 7.6 Docs

None for users. `V03-RESULTS.md` records the site count actually changed
against 7.4.

### 7.7 Risks

- **A missed site passes every test**, because with the identity model a
  grid row is a record row. Mitigations: the table of 7.4 is the checklist;
  after the rewrite, `grep -n "args.records\[" src/components/eui-sheet.gts`
  must show only indexes that are record rows by construction (each line
  listed in the results); and batch 3b's GR tests repeat one case per
  cluster under groups (8.10 names the cluster of each).
- `rowOf(id, hint)` takes a hint that today is a grid row and a record row
  at once. Its hint becomes a record row; passing a grid row would only
  make it slower, not wrong, so a mistake there is silent.
- Performance: `recordAt` is called per rendered cell. Identity model: one
  comparison. Grouped: one typed-array read.
## 8. Batch 3b: group by

### 8.1 The contract

```ts
/** One level of the owner's group-by. Outermost first. */
export interface SheetGroupBy {
  field: string;
  direction: 'asc' | 'desc';
}

/** One group header. `@groups` lists them depth-first, in display order. */
export interface SheetGroup {
  /** The owner's id for the group: unique in `@groups`, the same after a re-query. */
  key: string;
  /** 0 for the outermost level; the group belongs to `@groupBy[depth]`. */
  depth: number;
  /** The value of `@groupBy[depth].field` its records share. A record added to the group, or dragged into it, gets it. */
  value: unknown;
  /** Default: `type.format(value)` of that field, or `messages.groupEmpty()` for an empty value. */
  label?: string;
  /** Records in the group in the owner's whole data (all pages, collapsed or not). */
  count: number;
  /** How many of `@records`, taken in order, are directly under this header. Default 0. */
  loaded?: number;
  /** Drawn closed. Its records are not in `@records` and its child groups are not in `@groups`. */
  collapsed?: boolean;
  /** Text per field id, drawn in the header row under that column. */
  summary?: Record<string, string>;
  /** The row number of its first loaded record. Default: one more than the record before it. */
  rowNumberStart?: number;
  /** The group began on an earlier page: the label says so. */
  continued?: boolean;
}
```

The shape supports any depth and v0.3 draws any depth (D13). The cases it
was checked against:

| Case | What the owner passes |
| --- | --- |
| Expanded, fully loaded | `count: 12, loaded: 12` |
| Collapsed | `collapsed: true, count: 12` (no `loaded`); its 12 records are not in `@records` |
| Empty group (the owner chooses to list it) | `count: 0`; drawn as a header and, when inserting is allowed, an add row |
| Records with an empty value | `value: null`; label "(Empty)" |
| Starts on this page, continues on the next | `count: 40, loaded: 15` |
| Continues from the previous page | `count: 40, loaded: 25, continued: true, rowNumberStart: 16` |
| Two levels | parent `{ depth: 0, count: 30 }` (no `loaded`), then its children `{ depth: 1, loaded: … }` |
| Collapsed parent | the parent with `collapsed: true`; its children are not listed |

### 8.2 Placement and what the sheet checks

The row model (7.2) walks `@groups` once:

1. A header row for the group.
2. Its next `loaded` records of `@records`, as record rows.
3. When inserting is allowed, the group is not collapsed and it is a
   **leaf** (the next group is not deeper): an add row for it.

A parent's records are its children's; a parent normally has no `loaded`.
Nothing is read from the records: no value is compared, nothing is counted
or reordered. If `Σ loaded` is less than `@records.length`, the remaining
records are drawn after the last group's rows, in that group, and a debug
`warn` (`ember-eui.sheet.groups-loaded-mismatch`) says so; if it is more,
the walk stops at the last record. Neither loses or hides a record.

Why positions and not a `groupKeyOf(record)` function (D1): the connector
keeps a user's edits "stable" over the last results until Re-apply
(V02-DESIGN.md V4). With a function, editing a record's group field would
at once put a header in the middle of another group. With positions the
sheet keeps showing the owner's last answer, which is the rule.

Without `@onGroupToggle` the headers have no toggle and Enter does nothing
on them: the sheet cannot hide records it was given without breaking W2
(D2).

### 8.3 Intents and the header menu

- `@onGroupToggle(key, collapsed)`: a click on a header's toggle or label,
  or Enter or Space on a focused header row. The owner changes `@groups`
  (and `@records`). Focus stays on the header: the sheet sets a pending
  focus by group `key` (4.2), applied after the render that brings the new
  rows.
- `@onGroupByChange(groupBy)`: the header menu gets "Group by this field"
  (`[{ field, direction: 'asc' }]`, one level) and, on the grouped field,
  "Remove grouping" (`[]`), through the column's `actions.additional` as
  "Filter by this field" does (`eui-sheet.gts:1003-1013`). Shown only with
  the handler and when `field.groupable !== false`. Deeper grouping comes
  from the app's own control through the block's `setGroupBy`.
- `@groupBy` is drawn nowhere in the grid itself except to pick the menu
  item and to build the default header label
  (`messages.groupLabel(fieldLabel, valueText)`, e.g. "Status: Open"). The
  field of a level is looked up in the visible and hidden fields
  (`allFields`), so grouping by a hidden field works.

### 8.4 Header rows, add rows, row numbers, summaries

- **Header row.** Same height as a record row (D3). One opaque background
  (`--euiSheet-group`), no dividers between its cells. The label cell
  (9.1) shows: an indent of `depth × 16px`, a chevron (only with
  `@onGroupToggle`), the label, the count (`messages.groupCount`) and
  "continued" when set. The other cells show `summary[fieldId]`, subdued
  and right-aligned, or nothing.
- **Per-group summary.** `SheetGroup.summary`, texts from the owner like
  `@summary`. `groupRecords` can fill them with `summarize` (8.7).
  `@summary` (the footer bar) stays the whole view's.
- **Add rows.** One per expanded leaf group, after its loaded records,
  drawn like the add row of batch 1. Enter or a click inserts one record:
  `values` are `@newRecordValues({ above: the group's last loaded record,
  below: undefined })` merged with the group's values, which win: for the
  leaf and each ancestor header, `{ [groupBy[depth].field]: group.value }`.
  The insert carries `anchor` (after the group's last loaded record, when
  it has one), `index` (the record row after it) and `groupKey`. The add
  row at the end of the sheet is not drawn while there are groups (D15).
- **Insert above / below, Shift+Enter, duplicate** on a record: as today,
  plus the group values of the record's group and `groupKey`.
- **Row numbers.** `numberOf(recordRow)`: one more than the previous
  record's number, starting at `@rowNumberOffset + 1`; a group with
  `rowNumberStart` restarts the count there. Without `rowNumberStart` this
  is v0.2's `rowNumberOffset + index + 1`, which is wrong after a collapsed
  group, so `groupRecords` always sets it (counting the records of
  collapsed groups: numbers are positions in the whole view, as Airtable's).
  `@rowLabel(record, position)` gets that number. Header and add rows have
  no number. The numbers are computed once per model into an `Int32Array`
  (only when some group has `rowNumberStart`).
- **Checkboxes.** Header rows have none in v0.3. "Select all" checks the
  loaded records, as today.

### 8.5 With existing features

| Feature | With groups |
| --- | --- |
| Ranges (mouse drag, Shift+arrows, Shift+click) | In grid rows; headers and add rows inside are skipped (4.2). The head may rest on a header while extending; the drawn selection is the records. |
| Copy, cut, clear | The records of the range, in order; no line for a header. |
| Paste | From a record: lines fill the following records across group boundaries (D14); lines past the last record become inserts in the last group (its values, `groupKey`, anchored after its last record). From a group's add row: every line is an insert in that group. On a header row: nothing. `buildPaste` (`paste-plan.ts:59`) gains an option `insert?: { anchor?, index, values, groupKey? }` used for the rows past `ctx.records`; without it, today's behaviour. |
| Fill handle, Ctrl+D, Ctrl+R | In record space: a fill dragged over a header continues below it. The preview skips header and add rows. |
| Ctrl+A | All records. |
| Ctrl+arrow edge jumps | `edgeTarget` runs over `@records`, so a jump crosses headers by Excel's rule on the records; the result is mapped back to its grid row. |
| Home, End, PageUp, PageDown | Ctrl+Home goes to the first record's row. Page keys move by grid rows and may land on a header. |
| Auto-scroll while dragging | Pixel-based (`-private/auto-scroll.ts`): unchanged. |
| Undo, redo | By record id, unchanged. A record whose group is collapsed now is not in `@records`: the change set is still emitted (the owner has the record), and nothing is selected, as for a record on another page. |
| Expanded record, previous / next | Over `@records` (`expandedStep`, `eui-sheet.gts:2357`): crosses groups, skips nothing loaded. |
| Frozen fields | A header row's label cell is the sticky one; its other cells get no frozen props (9.1). Record and add rows as today. `onFrozenFocus` is unchanged. |
| Row menu, long press | None on a header row (`menuRowOf` returns −1 for it). |
| Editing, typing, IME | A header row never opens an editor; a printable key on it is swallowed before the IME catcher. |
| File drop | `dropCellAt` returns null for non-record rows (it does already for `undefined`). |
| `@validate`, `@cellErrors` | By record id: unchanged. |
| `@isLoading` | Unchanged. An owner that re-queries on toggle shows it. |
| `@sort` | The owner sorts inside groups. The sheet draws the arrows as before. |
| `@highlight`, `@currentMatch` | Record cells only. A match in a collapsed group is not in `@records`: the owner expands the group first (11.1). |

### 8.6 Keys and mouse on a header row

The grid moves focus with the plain arrows, so ArrowDown from a record in
column `c` lands on the header row's cell in column `c` (it exists: same
column window). The sheet sees the focus (`onFocusIn`), finds a `group`
row, and sets `anchor = head = { row, col: c }` with nothing selected.
ArrowDown again goes to the group's first record in column `c`.

| Input | On a header row |
| --- | --- |
| Enter, Space | `onGroupToggle` (nothing without it) |
| ArrowLeft / ArrowRight | Move the column as on any row (so the column is kept for the next ArrowDown) |
| Shift+arrows | The head passes over the row |
| Printable keys, Delete, F2, paste, Shift+Enter, Shift+Space | Nothing (stopped) |
| Click on the toggle or the label | `onGroupToggle` |
| Click elsewhere on the row | Focuses the row |
| Mouse drag starting on it | No range |
| Right click | The browser's menu |

Focus is drawn on the row, not the cell: `.euiSheet__groupRow:focus-within`
gets the sheet's ring through a `::after` box over the row, and its cells'
own outline is off. Every cell of a header row gets, through
`setCellProps`, `aria-label` (label and count) and, with a toggle,
`aria-expanded`, so whichever cell has focus announces the group.

### 8.7 The reference implementation, outside the component

`src/core/groups.ts` (new, plain TypeScript, exported from the package):

```ts
export function groupRecords<T>(
  ctx: Pick<SheetContext<T>, 'types' | 'messages'>,
  records: readonly T[],
  options: {
    groupBy: readonly SheetGroupBy[];
    /** To find each level's field and its type. */
    fields: readonly EuiSheetField<T>[];
    /** Keys of the collapsed groups. */
    collapsed?: ReadonlySet<string>;
    /** Per field id, the summary to compute for every group (`summarize`). */
    summaries?: Readonly<Record<string, SheetSummaryKind>>;
    rowNumberOffset?: number;
  }
): { records: T[]; groups: SheetGroup[] };

/** Keeps `count` and `loaded` right after a change set, until the owner's next query. */
export function applyChangeSetToGroups(
  groups: readonly SheetGroup[],
  records: readonly unknown[],
  changeSet: ChangeSet,
  getRecordId: (record: any) => RecordId
): SheetGroup[];
```

- `groupRecords` partitions the records by each level's value, stably (the
  input order is kept inside a group). Two values are the same group when
  the type's `copyText` gives the same text (as `summarize`'s `unique`).
  Groups are ordered by the type's `compare` (else by that text), reversed
  for `'desc'`. Keys are `field:text` joined with `/` per level
  (`status:Open/owner:Ana`). It returns the records of the expanded groups
  in display order, and every header with `count`, `loaded`,
  `rowNumberStart`, `collapsed` and `summary`. It is for an owner that has
  every record; an owner that pages gets groups from its backend and must
  not call it on a page.
- `applyChangeSetToGroups`: an insert adds one to `count` and `loaded` of
  its `groupKey` (else of its anchor's group) and of that group's
  ancestors' `count`; a delete subtracts; a move does both. Patches change
  nothing (positions stay until the owner re-queries).
- `localRecords` (`src/local-records.ts`) gains `@tracked groupBy`,
  `@tracked collapsedGroups`, `summaries`, the bound `setGroupBy` and
  `toggleGroup`, and `@cached get view(): { records, groups }`, which is
  `groupRecords` over its records (or `{ records, groups: [] }` without a
  group-by). `apply` is unchanged: `applyChangeSet` positions an insert by
  its anchor in the full list, and the next `view` regroups by value, so an
  insert without an anchor (an empty group) still lands in its group.

A bare grouped sheet:

```gts
<EuiSheet
  @fields={{this.store.fields}}
  @records={{this.store.view.records}}
  @groups={{this.store.view.groups}}
  @groupBy={{this.store.groupBy}}
  @onGroupByChange={{this.store.setGroupBy}}
  @onGroupToggle={{this.store.toggleGroup}}
  @getRecordId={{this.getId}}
  @onChange={{this.store.apply}}
/>
```

### 8.8 The EmberSearchUi connector

`ember-search-ui-driver` 2.0.0-beta.2 has no group-by: `SearchState` is
`query`, `filter`, `sort`, `page`, `extensions` (`src/types.ts:96-107` in
`ember-search-ui`), and `memory-backend.ts` returns `{ results, total }`
(lines 27-28, 86). What it does have is a place to carry one:
`driver.setExtension(key, value)` (`driver.ts:260`) and
`result.aggregations`.

v0.3, without a driver change:

- `EuiSheetSearch` forwards `@groups`, `@groupBy`, `@onGroupByChange` and
  `@onGroupToggle` to the sheet (they join `ForwardedArgs`,
  `eui-sheet-search.gts:74-75`). The app builds `@groups` from the
  snapshot (its backend's group counts in `aggregations`, and the page's
  results for `loaded`), and its handlers write the group-by and the
  collapsed keys with `setExtension`, which its backend reads.
- `SearchRecords` (`search-records.ts`) keeps its "stable" copy of the
  groups next to its copy of the results and runs `applyChangeSetToGroups`
  on it with each change set, so counts follow the user's inserts and
  deletes until Re-apply.
- A helper for the common case, `pageGroups(records, groups, groupKeyOf)`:
  given the backend's headers (with `count`) and the page's records, it
  fills `loaded` and `continued`. It is the owner calling it, not the sheet.

Follow-up in `ember-search-ui` (separate, D16; proposed, not required):
`SearchState.groupBy: readonly SortItem[]` with `setGroupBy`,
`SearchResult.groups`, a `collapsed` list in the state, and
`memoryBackend` computing them. The connector would then map them by
default, as it maps `sort`.

### 8.9 Files

| File | Change |
| --- | --- |
| `src/core/types.ts` | `SheetGroupBy`, `SheetGroup`, `RecordInsert.groupKey`, `EuiSheetField.groupable` |
| `src/core/rows.ts` | The grouped model is used (written in 3a) |
| `src/core/groups.ts` (new) | `groupRecords`, `applyChangeSetToGroups`, `pageGroups` |
| `src/core/paste-plan.ts` | `buildPaste` option `insert` |
| `src/core/change-set.ts` | `insertRecords`, `duplicateRecords` accept `groupKey` and extra values |
| `src/core/messages.ts` | 4.6 |
| `src/components/eui-sheet.gts` | args, `rowModel` from `@groups`, `gridStyle.rowClasses`, `numberOf`, header-row keys and clicks, `watchRecords` also on `@groups` and `followRecords` re-finding stored positions (7.4, last row), group pending focus, menu items, insert values |
| `src/-private/group-cell.gts` (new) | `GroupLabel` (toggle, label, count) and the summary text |
| `src/-private/row-number-cell.gts`, `sheet-cell.gts` | A `group` branch that renders `GroupLabel` / the summary and sets the `aria-*` props |
| `src/-private/styles.ts`, `theme.ts` | 9.1, `--euiSheet-group` |
| `src/local-records.ts` | 8.7 |
| `src/search-ui/eui-sheet-search.gts`, `search-records.ts` | 8.8 |
| `src/types.ts`, `src/index.ts` | args, block API, exports |

### 8.10 Tests

Gate first: GH1 to GH6 (9.3), in
`tests/integration/components/eui-sheet-group-header-test.gts`.

`tests/unit/core/groups-test.ts`:

| # | Check |
| --- | --- |
| GP1 | One level: order by `compare`, `'desc'` reversed, input order kept inside a group. |
| GP2 | Empty values form one group with `value: null`. |
| GP3 | Collapsed keys: their records are left out, `count` kept, `loaded` 0. |
| GP4 | Two levels: depth-first headers, parents without `loaded`, a collapsed parent hides its children. |
| GP5 | `rowNumberStart` counts collapsed groups' records. |
| GP6 | `summaries`: each group's text equals `summarize` over its records. |
| GP7 | A multi-select field groups by the whole set (`copyText`). |
| GP8 | `applyChangeSetToGroups`: insert by `groupKey`, by anchor, delete, a move across groups; ancestors' counts. |
| GP9 | `pageGroups`: a page that starts inside a group marks it `continued`. |

`tests/integration/components/eui-sheet-groups-test.gts` (the cluster of
7.4 each one covers, in brackets):

| # | Check |
| --- | --- |
| GR1 | Three groups render three header rows with label and count, records under each, one add row per group, none at the end. [row helpers, add-row class] |
| GR2 | Without `@groups`, and with `@groups={{(array)}}`: the v0.2 rows. |
| GR3 | Click on a toggle calls `onGroupToggle(key, true)`; the owner drops the records; the header shows collapsed and focus is on it. Enter expands again. [focus and following] |
| GR4 | Without `@onGroupToggle`: no chevron, Enter does nothing. |
| GR5 | ArrowDown from a record to the header to the next record keeps the column. [keys] |
| GR6 | Shift+ArrowDown across a header selects the records on both sides; copy gives their lines only. [drawn selection, clipboard] |
| GR7 | Paste of 3 lines on the last record of a group writes 1 line there and 2 in the next group's first records. [clipboard] |
| GR8 | Paste of 2 lines on a group's add row: 2 inserts with the group's value, `groupKey` and an anchor after its last record. |
| GR9 | Enter on a group's add row: one insert with the group's values (two levels: both fields), over `@newRecordValues`. [insert] |
| GR10 | Fill handle dragged over a header fills the records below it; the preview is not drawn on the header. [fill] |
| GR11 | Ctrl+A selects all records; Delete clears them. Ctrl+ArrowDown from a group's first record jumps by the records' values across a header. [keys] |
| GR12 | Row numbers: continuous across groups; with a collapsed group and `rowNumberStart`, the next group starts after it; `@rowLabel` gets that position. [row numbers] |
| GR13 | Checking with Shift across a header checks the records between. Select-all checks the loaded records. [checked rows] |
| GR14 | Row menu on a record of the second group: insert below carries the group value; delete focuses the neighbour; no menu on a header. [row menu, insert/delete] |
| GR15 | Expanded record: next from a group's last record opens the next group's first. [expanded record] |
| GR16 | Undo of an edit in a group that was collapsed since: the change set is emitted, no error. [history] |
| GR17 | Typing on a header row opens no editor; typing on a record below one edits that record. [editing] |
| GR18 | Header menu: "Group by this field" calls `onGroupByChange([{ field, direction: 'asc' }])`; on the grouped field "Remove grouping" calls it with `[]`; no item without the handler or with `groupable: false`. |
| GR19 | `@summary` and group `summary` together: the header row shows its text under the right column, the footer its own. |
| GR20 | Two levels: indentation, a collapsed parent, an add row only under leaves. |
| GR21 | `Σ loaded` smaller than the records: all records are drawn, the warning is logged. |
| GR22 | `localRecords` end to end: group by a select field, collapse, add in a group, edit the group field (the record moves on the next `view`), ungroup. |
| GR23 | A re-query that reorders groups while a record cell is focused: focus follows the record (v0.2 3.2). |

In `tests/integration/components/eui-sheet-frozen-test.gts`, next to FZ9:

| # | Check |
| --- | --- |
| FZ13 | Vertical scroll over 10,000 records in 200 groups with 30 fields: time per scroll step and cells rendered, grouped against ungrouped, frozen off and on. Logged with `?report`, not asserted. |

In `tests/integration/components/eui-sheet-search-test.gts`: GC1 the
connector forwards the four arguments; GC2 an insert in a group between
searches raises that group's count in the stable copy.

### 8.11 Docs

- `docs/sheet-demo/d19-groups.md`: "Group by": a local store grouped by a
  select field, with a toolbar select for the field and a second level, a
  per-group sum, collapse all / expand all.
- `docs/sheet-demo/d14-search-ui.md`: a short "Grouping" part showing the
  `setExtension` wiring with a mock backend that returns group counts.
- `docs/sheet.md`: a "Groups" section (the contract of 8.1 with the cases
  table, the rule that counts come from the owner, the helpers); the
  arguments table; remove "Grouping rows" from "Not yet".
- `README.md`: the feature list and a ten-line example.

### 8.12 Risks

- **The header row mechanism** (section 9): gated, with a sheet-only
  fallback.
- **Owners that pass a wrong `loaded`.** The sheet stays usable (8.2) but
  shows records under the wrong header. The warning names the two numbers.
- **Async owners and toggles.** Between the click and the new `@records`
  the header still shows the old state. An owner that wants it instant
  flips `collapsed` at once and delivers the records later, with
  `loaded: 0` meanwhile; the contract allows it.
- **Row numbers with paging** depend on the owner passing `rowNumberStart`
  and `@rowNumberOffset`; without them numbers restart per page, as today.
- **Cost of `rowClasses`**: one entry per header and add row, rebuilt when
  `@groups` change; 200 groups is 400 entries.
- **Screen readers.** The header is a row of `gridcell`s with `aria-label`
  and `aria-expanded`, not a `treegrid` row: the grid owns the row's
  attributes (`row.gts:58-70`). Unverified with a screen reader.
## 9. Group header rows in the grid: mechanism, gate, fallbacks

### 9.1 What the grid gives, and the mechanism

Read in the grid's code:

- **No colspan and no row renderer.** A row is
  `position:absolute; left:0; right:0; top; height` (`row.gts:51-56`) with
  one `EuiDataGridCell` per rendered column (`row.gts:72-84`); there is no
  hook to render something else in a row. `renderCustomGridBody` replaces
  the whole virtualized body, which the sheet's frozen fields, scrolling
  and focus all depend on.
- **Column 0 unmounts.** The rendered columns are one contiguous window
  over all columns, control columns included (`body.gts:365-370`,
  `computeColumnWindow` at 321-338, `visibleColCount` at
  `eui-data-grid.gts:467`), with an overscan of 1 by default. Scrolled two
  columns to the right, the row-number cell and the first field's cell of
  every row are gone. So a label cannot simply live in column 0.
- **A cell's style can be overridden.** The inline style is
  `position:absolute; left; top:0; height; width`, then the `setCellProps`
  style last (`cell.gts:779-803`). A class comes from `setCellProps` too,
  and a row class from `gridStyle.rowClasses[rowIndex]` (`row.gts:33-44`).
- **Per-row heights exist** (`rowHeightsOptions.rowHeights`,
  `utils/data-grid/types.ts:36-48`), but one entry makes the body leave its
  uniform path and build prefix sums over every row
  (`body-base.ts:177-184`, `body.gts:175-183`). Not used (D3).
- **Sticky cells work in the real grid**: the frozen field is exactly a
  cell with `position:sticky; float:left; left; z-index` inside the
  absolute row, and FZ1 to FZ4 pass.

Mechanism (W4): a header row is a normal row whose cells are restyled, and
whose **first rendered cell** carries the label, made sticky and wide by
CSS. "First rendered" is `:first-child` of the row element, which is
always the lowest rendered column because the row's only children are its
cells, in column order. When the column window moves, another cell becomes
`:first-child` and takes the label in the same style recalculation: no
script, no frame of delay.

```css
.euiSheet .euiSheet__groupRow > .euiDataGridRowCell {
  background-color: var(--euiSheet-group, #F7F8FC);
  border-inline: 0;               /* the property is confirmed in Chromium first (5.2) */
  cursor: default;
  outline: none;
}
.euiSheet .euiSheet__groupRow > .euiDataGridRowCell:first-child {
  position: sticky !important;    /* over the inline position:absolute */
  left: 0 !important;
  float: left;
  width: max-content !important;
  min-width: var(--euiSheetGroupMin);   /* row numbers + first field */
  max-width: var(--euiSheetGroupMax);   /* the grid's visible width */
  z-index: 2;
}
.euiSheet .euiSheet__groupRow > .euiDataGridRowCell:not(:first-child) .euiSheet__groupLabel,
.euiSheet .euiSheet__groupRow > .euiDataGridRowCell:first-child .euiSheet__groupSummary { display: none; }
.euiSheet .euiSheet__groupRow:focus-within::after {
  content: ''; position: absolute; inset: 0; z-index: 3; pointer-events: none;
  outline: 2px solid var(--euiSheet-primary, #0B64DD); outline-offset: -2px;
}
```

- Every cell of a header row renders the same small `GroupLabel` and its
  own summary text; CSS shows the label in the first cell only and the
  summary in the others. Hidden with `display: none`, the copies are not
  in the accessibility tree.
- `!important` is needed because the values to override are inline. It is
  confined to this one selector.
- The sheet sets `--euiSheetGroupMin` and `--euiSheetGroupMax` on
  `.euiSheet__grid` (it already sets the frozen offsets there,
  `frozenStyle`).
- With `@frozenFields`: every column is rendered, so `:first-child` is
  always column 0. In a header row the sheet passes the frozen props to no
  cell (the CSS above makes the first one sticky), so the frozen first
  field's cell does not paint over the label.
- Row class: `gridStyle.rowClasses` gets `euiSheet__groupRow
  euiSheet__groupRow--depthN` for each header's grid row, and
  `euiSheet__addRow` for each add row.
- While scrolled sideways the label covers the group summaries of the
  leftmost visible columns, as a frozen column would cover cells (D4).

### 9.2 What is not established

- Whether the row's sticky child behaves when `position` and `left` come
  from a stylesheet with `!important` rather than inline. It should (the
  computed style is the same as the frozen cell's), but it has not been
  run.
- Stacking against the sticky column header and the frozen header cells
  (`z-index: 3`) on vertical scroll.
- Whether `width: max-content` on a cell is honoured through the cell's
  inner wrappers, some of which may clip.

- The selector `.euiSheet__groupRow > .euiDataGridRowCell:first-child`
  assumes the cell component's root element is the `role="gridcell"`
  element with that class, a direct child of the row. The template starts
  that way (`cell.gts:920-924`) but it was not read to its end.

Hence the gate.

### 9.3 Gate (binary; first task of batch 3b)

`eui-sheet-group-header-test.gts`: 12 fields of 150 px at a 600 px width,
60 records in 3 groups, headless Chrome.

| # | Check |
| --- | --- |
| GH1 | At `scrollLeft` 0: in each header row exactly one label is displayed, in the row's first cell; its left edge is the scroll element's left edge. |
| GH2 | After `scrollTo({ scrollLeft: 700 })`: the row has no row-number cell (column 0 is unmounted), and still exactly one displayed label, at the scroll element's left edge and at the row's `top`; `document.elementFromPoint` at its centre is inside it. |
| GH3 | After a vertical scroll that puts a header row under the column header: `elementFromPoint` on the column header returns the column header. |
| GH4 | With `@frozenFields={{1}}` and `scrollLeft` 700: GH2's checks, and `elementFromPoint` at the label's right half is the label, not the frozen first-field cell. |
| GH5 | ArrowDown from a record onto the header row at `scrollLeft` 700: a cell of that row has DOM focus, the row's ring is drawn (`::after` outline colour is `--euiSheet-primary`), and ArrowDown again focuses the next record in the same column. |
| GH6 | All cells of a header row have the same computed `background-color`, opaque, in the light and the dark theme; none has a visible inline border. |

If GH1 to GH5 cannot be made to pass in headless Chrome, **stop and
report**; use 9.4. Firefox and Safari are a manual check (sticky inside an
absolute row is what the frozen field already relies on there).

### 9.4 Fallbacks

**A. Render every column while grouped (sheet-only; the frozen field's
proven path).** While `@groups` is not empty the sheet passes
`virtualizationOptions={ overscanColumnCount: <all columns> }`, as it does
for frozen fields (`eui-sheet.gts:1116-1121`), so column 0 never unmounts,
and it makes the header row's first cell sticky and wide through
`setCellProps` (`{ position: 'sticky', float: 'left', left: 0, zIndex: 2,
width: … }`), exactly what FZ1 to FZ4 prove. No `:first-child`, no
`!important`. Cost: FZ9's, 2 to 4 times the work per vertical scroll step
(182 to 196 ms against 38 to 49 ms at 10,000 × 30, V02-RESULTS.md), and
above `FROZEN_MAX_COLUMNS` (50) fields the label is not sticky. FZ13
measures it. The docs would then say grouping costs what freezing costs.

**B. A label that is not sticky (sheet-only).** The label is in the
row-number cell and overflows over the first field's cell; it scrolls away
with them unless `@frozenFields` is set (D4's alternative). Needs nothing
unproven. Used only if A also fails.

**C. A grid extension** (`@renderFullWidthRow`, a hook in `row.gts`) is
not planned. It would also have to give the row a focus stop the grid's
keyboard navigation knows, which is more than the one-line hooks of
`internal/spikes/eui-latest/data-grid-extensions.md`. If A's cost is not
acceptable, this is the question to bring back to the user.
## 10. Batch 4: row drag, row colours, date with time

Public API of the batch (4.3 to 4.5): `@canMove`, `ChangeSet.moves` and
source `'move'`, `api.moveRecords`, `@rowColor`, `colorByOption`, the
`dateTime` type and `DateTimeField`, the `button` type with
`@onButtonPress`, the `barcode` type. Not additive: X3.

### 10.1 Drag to reorder rows

**Decision (D5): a change set, not an intent.** A row drag emits
`{ source: 'move', moves: [...], patches: [...] }` (4.3). Reasons: a drag
across groups writes the group field, and every write is a change set, so
an intent would split one gesture into two calls the owner must keep
together; and as a change set the move is undoable with the code that
exists (`invertChangeSet`), where an intent would not be. Order still
belongs to the owner: the sheet moves nothing, it shows `@records` in the
order given.

- **Enabled** when `@canMove` is true, the sheet is not `@readOnly`, and
  `@sort` is empty or absent (with a sort, the order is the sort's; the
  grip is not drawn). `@canMove` defaults to false because an owner that
  ignores `moves` would show nothing happening.
- **Grip.** The row-number cell shows a grab icon at its start on hover
  and on focus (a span, `data-eui-sheet-row-grip`; `(hover: none)` shows it
  always). Without row numbers there is no row drag.
- **What moves.** The pressed row; when it is among the checked rows or in
  a `'rows'` range, all of those, in their order.
- **Mechanism (W6).** A press on the grip starts a sheet-side drag with
  the mouse events the range drag uses (`onMouseDown` /
  `watchRelease` / `onDragMove`, `eui-sheet.gts:2649-2760`) and the same
  `AutoScroll` (`-private/auto-scroll.ts`). The target is found with
  `document.elementFromPoint` → row → upper or lower half. An insertion
  line (an absolutely positioned element in `.euiSheet__grid`, 2 px
  `--euiSheet-primary`) is placed from that row's rect; the moved rows get
  `euiSheet__rowCell--moving` (dimmed). Escape cancels. Release emits.
- **Keyboard.** Alt+Shift+ArrowUp / ArrowDown on a row-number cell or with
  a `'rows'` range moves the rows one record up or down (one change set
  per press).
- **Targets.** Between two records: anchor `after` the upper one. With
  groups: on a header row or a group's add row, into that group (at its
  start for a header, its end for an add row); on a collapsed header, into
  that group with no anchor (`groupKey` only). A drop that changes nothing
  emits nothing.
- **Across groups.** When the target's leaf group differs from a moved
  record's: the set also carries patches of each level's field to the
  target group's values (as an insert there would get, 8.4), with `from`
  the old values. Not allowed, and drawn with a "not allowed" cursor, when
  one of those fields is read-only for the record.
- **Paged owners** get anchors by record id, as with inserts. A drag
  cannot leave the page.
- `api.moveRecords(ids, target)` emits the same set.
- `localRecords`: nothing to add (`applyChangeSet` applies `moves`); when
  grouped, the patch regroups and the anchor orders inside the group.
- Touch: not in v0.3 (a touch drag scrolls, a long press is the menu).
  The keyboard move and `api.moveRecords` are the way on a phone.

### 10.2 Row colours

```ts
/** A named colour of the theme, or any CSS colour. */
export type SheetRowColor =
  | 'primary' | 'accent' | 'success' | 'warning' | 'danger' | 'neutral'
  | (string & {});

rowColor?: (record: T) => SheetRowColor | undefined;
```

- Drawn as a 4 px bar at the row's left edge (D10): an inset `box-shadow`
  on the row-number cell through `setCellProps`, or on the first field's
  cell without row numbers. Both are sticky when frozen, so the bar stays.
- Named colours resolve to `--euiSheet-row<Name>` (4.6), defined from the
  theme, so dark mode follows. A CSS colour is used as given (the app's
  responsibility in dark mode).
- A helper for the common case, colouring by a select field's option:
  `colorByOption(field)` returns `(record) => option.color` (the same
  `SheetOption.color` the badge uses, `core/types.ts:13-14`).
- The row-number cell's `aria-label` is unchanged: colour alone carries no
  name. An app that needs one puts the meaning in a field.
- `@rowColor` is called per rendered row-number cell; keep it cheap.

### 10.3 `dateTime`

A new built-in type; `date` (`src/core/field-types/date.ts`) is not
touched (D9).

```ts
export interface DateTimeField<T = any> extends EuiSheetField<T> {
  type: 'dateTime';
  /** The zone values are shown and typed in: 'local' (the browser's, default), 'utc', or an IANA name ('America/Mexico_City'). */
  timeZone?: 'local' | 'utc' | (string & {});
  /** As `DateField`. Default 'dmy'. */
  dateOrder?: 'dmy' | 'mdy';
  /** 12-hour clock with am/pm. Default false. */
  hour12?: boolean;
  /** Show and keep seconds. Default false (minutes). */
  seconds?: boolean;
  /** Instants (the stored format), inclusive. */
  min?: string;
  max?: string;
}
```

- **Stored value**: an instant as a UTC ISO string,
  `YYYY-MM-DDTHH:mm:ss.sssZ` (what `Date.prototype.toISOString` gives), or
  `null`. One format, so string comparison orders it and any backend reads
  it. The zone is a property of the field, not of the value.
- **Format**: `DD/MM/YYYY HH:mm` (or the field's order, clock and seconds)
  in the field's zone. `copyText`: the stored ISO string, so
  `parse(copyText(v))` gives `v` (the rule of `FieldType.copyText`).
- **Parse** (typed and pasted): an ISO string with `Z` or an offset is
  that instant; an ISO string without one, `D/M/YYYY H:mm[:ss] [am|pm]`
  (also with `-` or `.`), and a date alone (midnight) are wall-clock times
  in the field's zone. Anything else: `messages.notADateTime(text)`.
- **Zones.** `'local'` and `'utc'` use `Date`'s own getters. An IANA zone
  uses `Intl.DateTimeFormat(…, { timeZone }).formatToParts` to read the
  zone's wall clock for an instant, and two passes of it to find the
  instant for a wall clock. A wall clock that does not exist (the spring
  DST gap) resolves forward; one that exists twice resolves to the first.
  An unknown zone name is a `validate` error on every value, not a throw.
- **Editor**: the input editor with the formatted text, and a native
  `<input type="datetime-local">` picker behind the opener icon, as the
  date editor does with the native date picker
  (`-private/editors/date-editor.gts`). The picker works in the field's
  zone's wall clock.
- `compare`: string order. `series`: one value continues by a day, two or
  more by their constant step in milliseconds. `validate`: a real instant,
  `min`, `max`. `schema: 'datetime'`. `fieldOptions` (batch 2's form):
  zone, clock, seconds.
- `summarize`'s `min` and `max` work through `compare`.

### 10.3.1 `button` (added 2026-11-19 at the user's request)

A cell that runs an action of the app on its record, like Airtable's
button field. The sheet draws the button and says which record was
pressed; what the press does (open a URL, run a workflow, call an API) is
the app's. The field stores no value.

```ts
export interface ButtonField<T = any> extends EuiSheetField<T> {
  type: 'button';
  /** The button's text. Default: the field's label. */
  buttonLabel?: string | ((record: T) => string);
  /** An EUI icon type drawn before the text. */
  icon?: string;
  /** EUI button colour: 'primary' (default), 'success', 'warning', 'danger', 'text'. */
  color?: string;
  /** No press for this record (drawn disabled). */
  disabled?: (record: T) => boolean;
  /** A link instead of an action: the press opens it in a new tab, no handler needed. */
  url?: (record: T) => string | undefined;
}

// the sheet's intent, one handler for every button field:
@onButtonPress: (press: { recordId; fieldId; record }, options: { signal: AbortSignal }) => void | Promise<unknown>
```

- **No value.** `parse` returns `{ rejected: messages.buttonNoValue() }` (new token
  `euiSheet.buttonNoValue`, "A button has no value")
  for any text, so paste, fill, clear and cut skip the column (a reason in
  the paste summary, as for read-only cells). `format` and `copyText` give
  the button's text, so a copied range still lines up. `isEmpty` is always
  true, `compare` none (no sort items), `schema` none.
- **Drawn as** a compact `EuiButtonEmpty`-styled span with
  `role="button"`, `tabindex="-1"` and `data-eui-sheet-button` (cells
  render no tabbable element, P9; the same pattern as the link cells,
  `span[role=link][data-eui-sheet-link]`).
- **Pressing.** A click on the button presses it in one click, selected or
  not, through the type's `onCellClick` (`src/types.ts:44`) widened to let
  a type return `{ press: true }` instead of a value; a click elsewhere in
  the cell selects it. Enter or Space on the selected cell presses it (no
  editor). Disabled: no press, `aria-disabled`.
- **Pending and errors.** A promise from `@onButtonPress` makes the cell
  pending (the existing `pendingCells`, a spinner in place of the icon),
  and a second press on it is ignored until it settles. A rejection shows
  its message as the cell's error until the next press; a resolve clears
  it. Leaving the page aborts the signal.
- `url` without `@onButtonPress`: the press is `window.open(url, '_blank',
  'noopener')`. With both, the handler wins. Without either, the button
  is drawn disabled and a dev warning is logged once.
- In the expanded record the field is a real `EuiButton` (the form is not
  a cell, so it may be tabbable). Field editor (batch 2): label, icon,
  colour.

### 10.3.2 `barcode` (added 2026-11-19 at the user's request)

A text value shown as a code, typed, pasted or scanned. Airtable stores
`{ text, type }`; the sheet keeps the value a plain string (what a scanner
or a backend gives) and the symbology, if the app wants it, as a field
option.

```ts
export interface BarcodeField<T = any> extends EuiSheetField<T> {
  type: 'barcode';
  /** Formats a scan may read ('qr_code', 'ean_13', 'code_128', …, the BarcodeDetector names). Default: all the device supports. */
  formats?: string[];
  /** A pattern the text must match, as text fields have. */
  pattern?: string;
  /** The app's scanner, for browsers without BarcodeDetector (e.g. a zxing wrapper). */
  scan?: (options: { formats?: string[]; signal: AbortSignal }) => Promise<string | null>;
}
```

- **Value**: a string or `null`. `parse` trims; `format`, `copyText`:
  the text. `compare`: string order. Drawn in the monospace font with a
  small barcode icon. Paste, fill, undo: as text.
- **Editor**: the input editor plus, behind the opener icon (a camera),
  a scan panel. The panel uses `field.scan` when given, else the browser's
  `BarcodeDetector` on a `getUserMedia({ video: { facingMode:
  'environment' } })` stream, reading frames until one decodes; the first
  code read is committed and the panel closes. Escape or Cancel stops the
  stream. Without `field.scan` and without `BarcodeDetector` (Firefox,
  Safari today) or without a camera, there is no camera icon: typing and
  pasting still work, and a USB or Bluetooth scanner types into the cell
  like a keyboard (it ends with Enter, which commits and moves down, so a
  column can be scanned in a row).
- The camera needs a secure context and the user's permission; a refusal
  shows `messages.cameraDenied()` in the panel. New tokens:
  `euiSheet.cameraDenied`, `euiSheet.scanBarcode`, `euiSheet.cancel`.

### 10.4 Files

| File | Change |
| --- | --- |
| `src/core/types.ts` | `RecordMove`, `ChangeSet.moves`, source `'move'`, `DateTimeField` |
| `src/core/change-set.ts` | `applyChangeSet` moves; `moveRecords(ctx, ids, target, options)` builder |
| `src/core/history.ts` | `invertChangeSet` and `mergeChangeSets` for moves |
| `src/core/field-types/date-time.ts` (new), `index.ts` | the type |
| `src/-private/editors/date-time-editor.gts` (new) | the editor |
| `src/core/field-types/button.ts`, `barcode.ts` (new); `src/-private/cells/button-cell.gts`, `barcode-cell.gts`, `src/-private/editors/barcode-scan.gts` (new) | 10.3.1, 10.3.2; `onCellClick` may return `{ press: true }` (`src/types.ts`) |
| `src/-private/row-number-cell.gts` | grip, colour bar |
| `src/-private/drop-line.gts` (new) | the insertion line |
| `src/components/eui-sheet.gts` | `canMove`, the drag, Alt+Shift+arrows, `rowColor` |
| `src/core/groups.ts` | `applyChangeSetToGroups` for moves |
| `src/-private/styles.ts`, `theme.ts`, `src/core/messages.ts`, `src/types.ts`, `src/field-types.ts`, `src/index.ts` | tokens, exports, `colorByOption` |

### 10.5 Tests

| # | Check |
| --- | --- |
| RD1 | No grip by default; with `@canMove`; none with a non-empty `@sort` or `@readOnly`. |
| RD2 | Drag row 2 below row 5: one change set, source `'move'`, one move anchored after row 5's record, `from.after` row 1's record. |
| RD3 | `localRecords` applies it; Ctrl+Z moves it back; redo again. |
| RD4 | Three checked rows drag together and keep their order (anchors chain). Undo restores the original order when the three were adjacent, when they were not, and when one was the first record. |
| RD5 | A drop on its own place emits nothing; Escape cancels. |
| RD6 | Alt+Shift+ArrowDown on a row number moves it one down; at the last record nothing. |
| RD7 | With groups: a drag into another group adds the patch of the group field and `groupKey`; undo restores both. |
| RD8 | With groups: a drop on a collapsed header has `groupKey` and no anchor. |
| RD9 | With groups: a record whose group field is read-only cannot be dropped in another group. |
| RD10 | The insertion line is drawn between the rows under the pointer and auto-scroll runs near the edge (frames stubbed as in the range tests). |
| RD11 | Unit: `applyChangeSet` with moves (before, after, missing anchor, chained); `invertChangeSet` round-trips. |
| RD12 | `api.moveRecords`. |
| RC1 | `@rowColor` returning `'danger'` draws the bar in `--euiSheet-rowDanger`; `undefined` none; a CSS colour as given. |
| RC2 | Dark theme: the named colour's computed value changes with the theme. |
| RC3 | Frozen and scrolled: the bar is visible on the frozen row-number cell. |
| RC4 | `colorByOption(field)` returns the option's colour, `undefined` for no value. |
| DT1 | Unit: parse of ISO with `Z`, with an offset, without (field zone), `D/M/YYYY H:mm`, am/pm, a date alone; errors. |
| DT2 | Unit: format in `'utc'`, in `'America/Mexico_City'`, 12-hour, seconds; `parse(copyText(v))` is `v`. |
| DT3 | Unit: a wall clock in a DST gap and in a DST overlap, in `'America/New_York'`. |
| DT4 | Unit: `compare`, `series` (one value, a weekly step), `validate` with `min`/`max` and an unknown zone. |
| DT5 | Component: type "19/11/2026 15:30" in a `'utc'` field; the patch is `2026-11-19T15:30:00.000Z`; the cell shows it; copy gives the ISO string and paste of it elsewhere writes the same value. |
| DT6 | A `date` field next to it behaves as before (the existing date tests, unchanged). |
| BT1 | A click on a button cell (selected or not) calls `@onButtonPress` once with the record id, field id and record; a click on the cell's padding only selects. Enter and Space on the selected cell press it. |
| BT2 | A promise makes the cell pending and a second press is ignored; a rejection shows its message as the cell's error; the next resolve clears it. |
| BT3 | `disabled(record)`: no call, `aria-disabled`. `url` without the handler opens it (stubbed `window.open`). Neither: disabled and one dev warning. |
| BT4 | Paste, fill, clear and cut over a button column change nothing in it and report it; copy gives the button texts. |
| BC1 | Unit: parse trims, `pattern` validates, copy/paste round-trip. |
| BC2 | The scan panel with a stubbed `field.scan` resolving `'7501234567890'` commits it and closes; Escape aborts the signal. |
| BC3 | No `field.scan` and no `BarcodeDetector` (stubbed away): no camera opener; typing then Enter commits and moves down. |

DT tests use `'utc'` and named zones, never `'local'`, so they do not
depend on the machine's zone.

### 10.6 Docs

- `docs/sheet-demo/d21-row-order.md`: manual order on `localRecords`,
  with and without groups, and a row colour by a status field.
- `docs/sheet-demo/d15-more-field-types.md`: a `dateTime` field in two
  zones, a `button` ("Send reminder", a fake 800 ms action that fails for
  one row) and a `barcode` field (scan on a phone, type or paste elsewhere).
- `docs/sheet.md`: "Records" (row drag, `@canMove`, `moves` in the change
  set section with what an owner does with them), "Field types"
  (`dateTime`: the stored format, the zone, DST), "Theme" (row colours).
  `README.md`.

### 10.7 Risks

- **Owners that accept `@canMove` but do not persist an order**: rows
  jump back on the next query. The docs say what `moves` needs (an order
  column, or fractional positions).
- **The grip crowds the row-number cell** (grip, number or checkbox,
  expand icon in 64 px). The column widens by 12 px with `@canMove`.
- **IANA zones through `Intl`** depend on the browser's zone data; DT2 and
  DT3 use zones every current browser has.
- **BarcodeDetector** exists only in Chromium-based browsers (and not on
  every desktop OS); elsewhere the scan needs `field.scan`. The camera
  path is checked on a real phone, not in CI (BC2 stubs it).
- **Button actions are side effects**: not undoable, and a press is not a
  change set. A double click is two clicks to the grid; the pending rule
  (BT2) is what stops a second call.
- **`Date` parsing is not used** for typed text (it is locale-dependent);
  only for ISO strings with a designator.
## 11. Batch 5: search navigation, selection exposure, touch ranges, upload progress

Public API of the batch (4.4, 4.5): `@currentMatch`, `api.scrollToCell`,
`findMatches`, `@onSelectionChange`, the block's `selection`,
`api.getSelection`, `summarizeCells`, and `onProgress` in `upload`'s
options. All additive.

### 11.1 Search next / previous

The sheet does not search: matches can be on another page or in a
collapsed group, and only the owner knows. What it adds is a way to
**show** the owner's current match without taking focus from the search
box (W9).

- `@currentMatch?: { recordId, fieldId } | null`. When it changes to a
  cell that is in `@records` and in the visible fields, the sheet scrolls
  it into view (`gridApi.scrollToItem`, `eui-data-grid.gts:1134`; then
  clear of the frozen columns, the correction `onFrozenFocus` already
  makes) and draws it with `euiSheet__cell--match` (a 2 px
  `--euiSheet-match` ring inside the cell, over `@highlight`'s marks).
  Focus and the selection do not move. A match that is not in `@records`
  or whose field is hidden draws nothing: the owner changes the page,
  expands the group or shows the field first.
- `api.scrollToCell(cell)` does the scroll alone. `api.focusCell` (v0.2)
  is for when the user leaves the search box (Escape, or Enter on a
  "go to" button).
- A helper for owners that hold every record (`src/core/search.ts`, new;
  the sheet never calls it):

  ```ts
  /** The cells whose shown text contains `term`, by row then field. */
  export function findMatches<T>(
    ctx: Pick<SheetContext<T>, 'types' | 'messages' | 'getRecordId'>,
    records: readonly T[],
    fields: readonly EuiSheetField<T>[],
    term: string
  ): Array<{ recordId: RecordId; fieldId: string }>;
  ```

  It matches what `@highlight` marks: the type's `format` text, without
  case. An owner that pages gets its matches from its backend instead.
- The docs demo's toolbar: a search input (its value is `@highlight`),
  "3 of 12", and ‹ › buttons; Enter and Shift+Enter in the input step.
  The app keeps `matches = findMatches(…)` and an index, and passes
  `matches[index]` as `@currentMatch`. With groups it expands the match's
  group first (`localRecords.toggleGroup`).

### 11.2 The selection, exposed

```ts
export interface SheetSelection<T = any> {
  kind: 'cells' | 'rows' | 'columns';
  /** The selection's records, in the order shown. */
  records: T[];
  recordIds: RecordId[];
  /** Its visible fields, in display order. */
  fields: EuiSheetField<T>[];
  /** records.length × fields.length. */
  cellCount: number;
}
```

- `SheetBlockApi.selection` (a cached getter over the range, `@records`
  and the visible fields; `null` with no range), `api.getSelection()`, and
  `@onSelectionChange(selection | null)`, called after render when the
  record ids, field ids or kind changed (at most once per run loop, so a
  drag reports each new rectangle once).
- A focused single cell is a selection of one cell. Header and add rows
  inside a range are not in it (4.2). The checked rows stay separate
  (`checkedRecords`).
- The sheet aggregates nothing. The owner calls
  `summarize(ctx, selection.records, field, 'sum')` per field, or the new
  `summarizeCells(ctx, selection, kind)` (`src/core/summary.ts`) for
  Airtable's bar over a rectangle: `count`, `filled`, `sum`, `average`,
  `min`, `max` over every cell of the selection, numbers through each
  type's `toNumber`; formatted with the field's `format` when the
  selection is one field, as a plain number otherwise; `''` when no cell
  has a number.
- A selection is of loaded records only. The docs say that a summary of a
  selection is exact, and a summary of "all" is the owner's (`@summary`).

### 11.3 Ranges by touch

Today a touch press never drags a range (`lastPointerType`,
`eui-sheet.gts:608`; a moving touch is a scroll, 3098-3103) and a long
press opens the menu (3119-3127). Both stay (D12).

- After a touch tap selects a cell, the sheet draws two handles at the
  range's top-left and bottom-right corners
  (`src/-private/selection-handles.gts`): 20 px circles with a 44 px hit
  area, `touch-action: none`. They are placed like the fill handle
  (`placeFillHandle`, `eui-sheet.gts:2898`) and re-placed on the same
  events (selection, scroll, column resize, `@records`, row height). The
  fill handle stays hidden on coarse pointers (`styles.ts:105`).
- `pointerdown` on a handle captures the pointer; `pointermove` finds the
  cell under it (`document.elementFromPoint`) and moves that corner (the
  bottom-right handle moves the head, the top-left the anchor);
  `AutoScroll` runs near the edges; `pointerup` ends. The handles show
  only while the last press was a touch, so a mouse on a hybrid device
  never sees them.
- A handle whose corner cell is not rendered (scrolled out, or under the
  frozen columns) is hidden until it is.
- Copy, cut and paste by touch go through the row menu, which already has
  "Copy rows"; the menu gains "Copy" and "Paste" for a `'cells'` range
  when opened by a long press.

### 11.4 Upload progress

- `upload(files, { record, field, signal, onProgress })`: `onProgress` is
  a new key of the existing options object (`core/types.ts:128-135`,
  called at `eui-sheet.gts:4882`), so an uploader that ignores it works as
  before. `onProgress(fraction)` takes 0 to 1 for the whole call; the
  sheet clamps it and ignores calls after the upload settled or was
  aborted.
- The cell's pending entry (`PendingEntry`, `eui-sheet.gts:163-170`) gets
  `progress`; `CellView` gets `progress?: number`. A pending cell with a
  progress draws a 2 px bar along its bottom edge
  (`.euiSheet__cellProgress`, width in percent, `--euiSheet-primary`) and
  its `title` is `messages.uploading(percent)`. Without any `onProgress`
  call the cell is only pending, as today.
- The attachment editor and the expanded record's box show the same value
  in an `EuiProgress` under the file list.

### 11.5 Files

| File | Change |
| --- | --- |
| `src/core/search.ts` (new) | `findMatches` |
| `src/core/summary.ts` | `summarizeCells` |
| `src/core/types.ts` | `upload`'s `onProgress` |
| `src/-private/selection-handles.gts` (new) | 11.3 |
| `src/-private/sheet-cell.gts` | match class, progress bar |
| `src/-private/editors/attachment-editor.gts`, `record-form-field.gts` | progress |
| `src/components/eui-sheet.gts` | `currentMatch`, `scrollToCell`, `selection`, `onSelectionChange`, handle drag, progress state, menu items |
| `src/-private/styles.ts`, `theme.ts`, `src/core/messages.ts`, `src/types.ts`, `src/index.ts` | tokens, exports |
| `src/search-ui/eui-sheet-search.gts` | forwards `@currentMatch`, `@onSelectionChange` |

### 11.6 Tests

| # | Check |
| --- | --- |
| SN1 | `@currentMatch` on a rendered cell: it has the match class; `document.activeElement` is unchanged (an input in `<:toolbar>` keeps focus). |
| SN2 | On a cell far down and right (10,000 records, 30 fields): it is rendered and inside the scroll element's box; focus unchanged. |
| SN3 | With `@frozenFields={{1}}`: the match's left edge is right of the frozen columns. |
| SN4 | A record that is not in `@records`, a hidden field, `null`: nothing drawn, no error. |
| SN5 | Unit: `findMatches` order, case, a select's label, an empty term (no matches). |
| SN6 | The demo's wiring as a test: Enter steps to the next match and wraps; with groups, the match's collapsed group is expanded by the app and then shown. |
| SN7 | `api.scrollToCell`. |
| SL1 | The block's `selection` for a single cell, a rectangle, rows, columns. |
| SL2 | `@onSelectionChange` is called once per change, with `null` when the range is gone, and not again when `@records` re-renders without a change. |
| SL3 | With groups: a range across a header lists the records on both sides only. |
| SL4 | Unit: `summarizeCells` sum, average, min, max over two numeric fields; one field uses its format; text only gives `''`. |
| SL5 | `api.getSelection()`. |
| TR1 | A touch tap (`pointerType: 'touch'`) shows two handles on the cell; a mouse click shows none. |
| TR2 | Dragging the bottom-right handle to another cell extends the range; the top-left handle moves the anchor. |
| TR3 | A touch move on the grid (not on a handle) selects nothing (the v0.2 touch tests, unchanged). |
| TR4 | Near the bottom edge the drag feeds auto-scroll. |
| TR5 | Long press with a range: the menu has Copy; it copies the range. |
| UP1 | An uploader that calls `onProgress(0.4)`: the cell shows a bar at 40% and the title; at resolve the bar is gone and the files are saved. |
| UP2 | An uploader that never calls it: pending as today (the v0.2 attachment tests, unchanged). |
| UP3 | Calls after an abort or after the promise settled are ignored. |
| UP4 | The editor and the expanded record show the progress. |

### 11.7 Docs

- `docs/sheet-demo/d22-search-navigation.md`: 11.1's toolbar.
- `docs/sheet-demo/d13-summary.md`: a footer line with the selection's
  count, sum and average.
- `docs/sheet-demo/d17-attachments.md`: the fake uploader reports
  progress.
- `docs/sheet.md`: "Touch" (handles), "The sheet's API", "Summary bar"
  (selection), field types (attachment `onProgress`), and **"Not yet"**
  rewritten: remove range by touch, grouping and upload progress; what
  remains is listed in 14.3. `README.md`.

### 11.8 Risks

- **Touch handles cannot be verified here**: synthetic pointer events
  test the logic, not a finger. Real devices are in the manual list, with
  v0.2's long press.
- **`scrollToItem` alignment** may leave the match at an edge, under the
  sticky header or the summary bar. SN2 checks the box; the fix, if
  needed, is an explicit `scrollTo` from the cell's offsets (the sheet
  already computes them for the frozen correction).
- **`@onSelectionChange` during a fast drag** runs the owner's code per
  rectangle; the docs tell owners to keep it cheap or debounce.
## 12. Data down, actions up: what v0.3 adds to the surface

| Feature | In | Out | Without a handler |
| --- | --- | --- | --- |
| Field order by drag | `@fields`, `@fieldDrag` | `@onFieldOrderChange` (existing) | the sheet's own order (existing) |
| Header lines | `@headerLines` | none | |
| Shortcut list | none | none (`api.showShortcuts`) | |
| Add, edit, duplicate, delete a field | `@fields`, `field.manageable`, `@creatableFieldTypes`, `@fieldEditor` | `@onFieldCreate`, `@onFieldUpdate`, `@onFieldDelete` | no controls |
| Groups | `@groups` (headers, counts, `loaded`, summaries), `@groupBy` | `@onGroupToggle`, `@onGroupByChange`; inserts carry `groupKey` and the group's values in `@onChange` | headers without a toggle; no menu item |
| Row order | `@records` (their order), `@canMove`, `@sort` (turns it off) | `@onChange` with `moves` | `@onChange` is required |
| Row colour | `@rowColor` | none | |
| Date with time | a `dateTime` field | `@onChange` (patches with UTC ISO strings) | |
| Current search match | `@currentMatch`, `@highlight` | none (the owner's search box) | |
| Selection | none | `@onSelectionChange`; blocks' `selection`; `api.getSelection()` | |
| Upload progress | `field.upload`'s `onProgress` | none | pending only |

Helpers outside the component, for owners that hold every record:
`groupRecords`, `applyChangeSetToGroups`, `pageGroups`, `convertField`,
`findMatches`, `summarizeCells`, `colorByOption`, and `localRecords`'
`view`, `setGroupBy`, `toggleGroup`, `createField`, `updateField`,
`deleteField`.
## 13. Open decisions for the user

Each has a recommendation; the design above is written with the
recommendation taken. A different answer changes only the section named.

| # | Decision | Recommendation | Alternative, and what it costs |
| --- | --- | --- | --- |
| D1 | How the owner says where a group's rows are (8.2) | `loaded`: a count per header, records taken in order. Plain data, no lookup, and it keeps showing the owner's last answer while edits are "stable" in the connector. | `groupKeyOf(record)`: one function, more forgiving on optimistic inserts, but an edit of the group field would move a record under another header before the owner re-queries. Or `firstRecordId` anchors: break when the anchor record is deleted. |
| D2 | Records of a collapsed group (8.2) | Absent from `@records`; no collapsing without `@onGroupToggle`. | Present but hidden, with a local fallback: ranges stop being contiguous in `@records`, which every core builder assumes. |
| D3 | Height of a group header row (9.1) | The same as a record row. Keeps the grid's uniform-height path. | Taller headers through `rowHeightsOptions.rowHeights`: possible without a grid change, costs a prefix-sum over all rows on each change (measured by FZ13). |
| D4 | Group label on horizontal scroll (9.1) | Sticky at the left edge, over the leftmost columns and their group summaries, like a frozen column. | The label scrolls away with the first field unless `@frozenFields` is set: simpler (no gate), but a wide grouped table loses its group names when scrolled. |
| D5 | Manual row order (10.1) | Part of the change set (`moves`, source `'move'`), opt-in with `@canMove`. One gesture is one undoable set, and a drag across groups carries its patch with it. | An intent `@onRecordMove`: not undoable from the sheet, and a drag across groups becomes two calls (`onChange` for the patch, then the move). |
| D6 | Undo of field operations (6.6) | Not on the sheet's undo stack. Delete asks for confirmation. | Undoable through the owner: needs the owner to keep every deleted value, also of records that are not loaded. |
| D7 | Shape of the field intents (6.2) | Three handlers (`@onFieldCreate`, `@onFieldUpdate`, `@onFieldDelete`); each one's menu items appear only with it. No local fallback in the component; `localRecords` has them. | One `@onFieldChange(change)` union: one argument, but all-or-nothing. |
| D8 | Column drag by default (5.3) | On. `@fieldDrag={{false}}` turns it off. | Off by default: no header DOM change for existing apps, but the feature is hidden. |
| D9 | Date with time (10.3) | A separate type `dateTime`. Stored as a UTC ISO string (`2026-11-19T15:30:00.000Z`). Shown and typed in `field.timeZone` (default: the browser's). Plain `date` is untouched. | An option on `date`: mixes two stored formats in one type. A "floating" time without a zone (`2026-11-19T15:30`): not in v0.3. |
| D10 | How a row colour is drawn (10.2) | A 4 px bar at the row's left edge. | A tint of the whole row: fights with hover, selection and the frozen cells' opaque backgrounds, and needs a contrast check per theme. |
| D11 | Key of the shortcut list (5.5) | Ctrl/Cmd+/ only. | Also `?`: it is a printable key and opens the editor on a cell today. |
| D12 | Ranges by touch (11.3) | Two drag handles on the selected cell's corners (as Google Sheets on a phone). A drag on the grid stays a scroll, a long press stays the menu. | Long press then drag: collides with the long-press menu of v0.2. |
| D13 | Group levels (8.1) | The contract and the rendering support any depth; tested with two. The header menu's "Group by this field" sets one level; more levels come from the owner's own control. | Draw one level only in v0.3: saves about 80 lines, and Prysmex would need a later change to nest. |
| D14 | Paste and fill at a group's end (8.5) | They continue into the next group's records (header rows are skipped). Lines past the last record become inserts in the last group touched. | Stop at the group's end: safer against writing into another group, but unlike Airtable and unlike v0.2's ungrouped paste. |
| D15 | With groups, the add row (8.4) | One add row per expanded group; the single add row at the end is not drawn. | Keep also the row at the end: the sheet would not know which group it adds to. |
| D16 | Group by in EmberSearchUi | A separate follow-up in `ember-search-ui` (driver state `groupBy`, `memoryBackend` returning groups). v0.3 does not depend on it: the connector takes `@groups` from the app (8.8). | Wait for the driver: blocks the batch on another repository. |
| D17 | Button actions (10.3.1) | One sheet-level `@onButtonPress` for every button field, plus `field.url` for plain links. The sheet stays data-agnostic and the app routes by `fieldId`. | A function on the field (`field.onPress`): convenient, but fields stop being plain data the owner can serialize. |
| D18 | Barcode value (10.3.2) | A plain string; the symbology is not stored. | Airtable's `{ text, type }`: keeps the symbology, but every consumer has to unwrap it. |
## 14. What was verified in code, and what was not

### 14.1 Verified by reading the code at HEAD `5f659546`

- `columnVisibility.canDragAndDropColumns` is public and its drop ends in
  `setVisibleColumns` (5.3, with lines). The drag is native HTML5 drag
  (`eui-draggable.gts:368`). With it on, the header cell sits inside
  `droppable > draggable (position:relative) > item`, and the resizer is a
  sibling of the cell.
- The grid's column order state survives until a new `@columns` array
  (`eui-data-grid.gts:403-440`), and `switchColumnPos` starts from it.
- The first-field rule is enforced only by menu flags
  (`eui-sheet.gts:996-999`); `setVisibleColumns` (861-871) accepts any
  order.
- The rendered columns are one contiguous window over all columns, control
  columns included; column 0 unmounts under column virtualization
  (`body.gts:321-338, 365-370`; `eui-data-grid.gts:467`).
- There is no colspan and no row renderer; a row's children are only its
  cells (`row.gts:58-84`). A row class comes from `gridStyle.rowClasses`
  by row index (`row.gts:33-44`); a cell's `setCellProps` style is applied
  last (`cell.gts:779-803`).
- Per-row heights exist and make the body non-uniform
  (`body-base.ts:177-184`, `body.gts:175-183`).
- The header row's height is measured and the rows are offset by it
  (`body.gts:532-533, 604-615`).
- `trailingControlColumns` is a public argument, rendered outside the
  droppable (`header-row.gts:248-257`); `dataCell()` ignores control-column
  cells (`eui-sheet.gts:1853-1866`).
- The sheet's `keydown`, `mousedown`, clipboard and drag handlers are on
  the wrapper in the capture phase (`eui-sheet.gts:5049-5067`), so it sees
  keys before the grid.
- The core builders index `ctx.records` directly (the lines in 7.4);
  `history.ts` works by record id; inserts past the last record are made
  in `buildPaste` (`paste-plan.ts:150-170`).
- The grid's `@grouping` groups the given rows in memory
  (`row-model.ts:108`), so its counts are per loaded page.
- `ember-search-ui-driver` at `b9fc1dc` (2.0.0-beta.2): `SearchState` has
  no group-by (`types.ts:96-107`); `SearchResult` has `aggregations`
  (line 121); `driver.setExtension` exists (`driver.ts:260`);
  `memory-backend.ts` returns `{ results, total }` (lines 27-28, 86), and
  a search of that file for "group" and "aggregations" found nothing.
- The existing test-id prefixes (A, B, C, E, ED, F, FZ, H, I, IM, K, L,
  LK, LT, M, N, NU, NV, P, Q, R, RA, RF, RJ, RS, RV, RW, S, SM, SR, SS,
  SU, T, TC, TH, U, US, VA, VW); the new ones (AR, CD, HW, KH, FM, FC, RM,
  GH, GP, GR, GC, RD, RC, DT, SN, SL, TR, UP) collide with none, and the
  frozen module ends at FZ12, so the new timing test is FZ13.

### 14.2 Not verified

Nothing was run: no test, no browser. In particular:

1. **The add row** (5.2). The causes are read from the sheet's CSS. Not
   seen: where the pale grey focus box comes from, which property draws
   the column dividers, why the plus sits at the top, and anything about
   hover (which also cannot be forced in an integration test).
2. **The group header mechanism** (9.2): sticky through a stylesheet
   `!important` on `:first-child`, its stacking against the sticky
   headers, `max-content` through the cell's inner wrappers. Gate GH1 to
   GH6.
3. **Frozen headers with column drag on** (5.3): that making the
   draggable wrapper sticky with `:has()` works. Gate CD6.
4. Whether the sheet's capture `mousedown` calls `preventDefault` on a
   header target (only the start of `onMouseDown` was read). CD1.
5. That a bare sheet loses resized widths on a reorder today: inferred
   from the comment at `eui-sheet.gts:980-985` and the identity check at
   881-903, not observed.
6. Where `actions.additional` items appear in the column menu
   (`column-actions.gts` was not read), and whether the menu supports a
   separator.
7. What the grid does when a trailing control column's body cell is
   clicked or reached with End, Ctrl+End or Tab (the grid's keyboard code
   was not read). FM12.
8. Touch: native column drag from a touch, the selection handles on a real
   finger, `datetime-local` pickers on phones.
9. How undo treats a patch whose field no longer exists
   (`withoutConflicts`, `history.ts:82`, was not read); 6.6 prunes
   regardless.
10. `followRecords`, `isOwnChange` and `selectChanged` were read in part.
    A group toggle changes `@records` and is not an "own change"; the
    pending focus by group key (4.2) is designed against that reading.
11. How backends and codecs of EmberSearchUi read `state.extensions`
    (only the setter was read).
12. `--euiSheet-group` from `backgroundBaseSubdued` is the colour the
    row-number column already has (`theme.ts`); whether a header row then
    reads as a header is a visual check. The token may need to change.
13. The theme colour names used for row colours (`accent`, `success`,
    `warning`, `danger`) are EUI's standard ones; not looked up in the
    Borealis theme object.
14. `gridApi.scrollToItem`'s parameters and alignment (only that it
    exists, `eui-data-grid.gts:1134`).
15. The IANA zone conversion with `Intl` (10.3) is not prototyped; the
    date editor was only skimmed.
16. Whether a new `gridStyle` object (new `rowClasses` on each `@groups`
    change) makes the grid re-render every row.
17. Which existing tests reach into header internals and will need
    `@fieldDrag={{false}}` (X2); FZ5 is known by name only.
18. The contents of `docs/sheet.md` "Keyboard" (only its heading, line
    620), which the shortcut list mirrors.
19. `EuiModal` and a focus trap for the shortcut list and the field
    editor are assumed available because the expanded record uses a modal
    (`record-shells.gts`, not read).
20. Group header rows with a screen reader.
21. Firefox and Safari for every item; the line estimates of section 3.

### 14.3 Still out after v0.3 (the next "Not yet")

- Row drag and column drag by touch.
- Field management inside the expanded record; reordering select options
  in the field editor.
- Checkboxes on group headers; collapsing groups without the owner;
  taller group headers; per-level group colours.
- Date-times without a zone ("floating").
- A full-row colour tint.
- Undo of field operations.
- Group by in EmberSearchUi's driver and memory backend (the follow-up of
  8.8).
- Carried over from v0.2: dead keys and IMEs in the expanded record's
  boxes, re-measuring the fill handle on window resize, a keyboard way to
  choose copy over series, a cell larger than the visible body, one
  `@onResolve` answer per text, `maxFiles` without a message; and the Mac
  and real-device checks of V02-RESULTS.md.
- Out of scope, as before: formulas, rollups and lookups, comments,
  co-editing, other kinds of views.
