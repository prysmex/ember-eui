# `@ember-eui/sheet` v0.3 batch 3c: split of `eui-sheet.gts` into feature modules

Written 2026-11-20, design only. Nothing here is built. It is the design
the 3c row of `V03-DESIGN.md` section 3 asks for. Base: `feat/sheet` at
`5fa723d2`.

`packages/sheet/src/components/eui-sheet.gts` is 7,895 lines: 674 lines of
imports, types, constants and helper functions, one class of 6,960 lines
(about 350 methods, getters and callbacks, and about 90 fields), and a
259-line template. This batch moves the class body into 33 small modules.
The component keeps its arguments, the wiring and the template.

Section 9 lists what the user has to decide.

## 1. Goal and rules

Goal: each feature of the sheet in its own small file, so v0.4 and later
work change one small file per feature.

Rules, as decided by the user:

1. **No behaviour change.** Every method body moves as it is. Only the
   path in front of a member changes (`this.x` becomes `this.sheet.x` or
   `this.sheet.rows.x`).
2. **No public API change.** `src/types.ts`, `src/index.ts`, the
   component's arguments and blocks stay exactly as they are.
3. **The unchanged test suite is the check.** No file under `tests/` is
   edited.
4. **Small modules.** No file over about 800 lines. The component stays
   under about 1,500 lines.
5. **No registries, base classes, plugin hooks or event bus.** Composition
   only.
6. **Nothing new runs per cell or per scroll step.** `@cached` and
   `@tracked` keep their invalidation.
7. **`packages/core/src` does not change.**

Rules this design adds, to keep rule 1 checkable:

8. **A move is verbatim.** No rename, no reordering inside a method, no
   "while we are here" cleanup. A script checks it (section 5).
9. **No field changes kind.** A `@tracked` field stays tracked, a plain
   field stays plain, a `@cached` getter stays cached, a plain getter stays
   plain. Several fields are plain on purpose (`keptWidths`: "Plain, so a
   resize does not rebuild the columns").
10. **Each field has one owner**: the module that declares it. Other
    modules still write it, as other methods of the class do today
    (section 6.2 lists them).

## 2. The pattern

### 2.1 One pattern: a plain class that takes the component as its host

A module is a plain TypeScript class in `src/-private/sheet/`. It gets the
component in its constructor and keeps it as `sheet`. It declares its own
state, tracked or plain. The component creates each module once, as a
field.

```ts
// src/-private/sheet/checked.ts
import { cached, tracked } from '@glimmer/tracking';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { RecordId } from '../../core/index.ts';

/** Checked rows: controlled with `@onCheckedChange`, else local. */
export default class SheetChecked<T extends object> {
  sheet: EuiSheet<T>;

  /** Checked rows without `@onCheckedChange`: record ids as strings. */
  @tracked localChecked: ReadonlySet<string> = new Set();
  /** The row whose checkbox was toggled last. */
  lastToggledRow: number | null = null;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  @cached
  get checkedIds(): ReadonlySet<string> {
    if (!this.sheet.args.onCheckedChange) return this.localChecked;
    return new Set((this.sheet.args.checkedRecordIds ?? []).map(String));
  }

  isChecked(row: number): boolean {
    const record = this.sheet.rows.recordAt(row);
    return (
      record !== undefined &&
      this.checkedIds.has(String(this.sheet.args.getRecordId(record)))
    );
  }
  // checkedRecords, checkedState, setChecked, toggleChecked, ...
}
```

The bodies are today's, with only the paths changed (rule 8):
`this.args` is `this.sheet.args`, `this.recordAt` is
`this.sheet.rows.recordAt`, and `this.localChecked` and `this.checkedIds`
stay, because this module owns them.

In the component:

```ts
readonly rows = new SheetRows<T>(this);
readonly checked = new SheetChecked<T>(this);
```

### 2.2 The rules of a module

- **Host type.** `sheet: EuiSheet<T>`, a type-only import. Every
  `-private` component already types its `@sheet` this way, so this is the
  package's existing convention. The module import cycle is types only.
  ESLint has no cycle rule here (checked). It must be `import type`: the
  Babel config keeps any other import at run time
  (`onlyRemoveTypeImports`), which would make a real cycle.
- **State.** A field moves with the feature that owns it, with its
  decorator and its comment. `@tracked` and `@cached` work on a plain
  class: `Editing` and `FieldEditorState` in this file already use
  `@tracked` that way.
- **Reading other modules.** Always through the host:
  `this.sheet.rows.recordAt(row)`. A module never stores another module,
  never copies `sheet.args`, and never destructures a tracked value into a
  field.
- **Construction.** A constructor only stores `sheet`. No constructor and
  no field initialiser reads `this.sheet.<anything>` at once. Closures are
  fine (`autoScroll = new AutoScroll({ bounds: () => this.sheet.scroll.scrollBounds() })`).
  So the order of the module fields in the component does not matter. No
  TypeScript parameter properties (`constructor(readonly sheet)`): their
  order against field initialisers differs between compilers.
- **Template-bound handlers.** The 20 `@action` methods keep `@action`.
  The 39 arrow fields and modifiers stay arrow fields and modifiers. Both
  give one bound function per instance, as now, so `{{on}}` never
  re-installs. The template calls them by path: `{{on "keydown"
  this.keys.onKeyDown capture=true}}`.
- **Functions the template calls as helpers** (`growOf`, `editorValue`,
  `editorRecord`, `isAddFieldColumn`) must stay arrow fields: a helper
  call does not bind `this`. `isModal` stays a function in the component
  file, in the template's scope.
- **The component as an owner.** Five things need the real component, not
  a module. In a module they take `this.sheet`:
  `isDestroying(...)`, `isDestroyed(...)`, `afterRender(...)`. Two stay on
  the component: `guidFor(this)` (`sheetId`) and
  `getEuiThemeContext(this)` (`themeClass`). `later(this, ...)` and
  `debounce(this, ...)` keep the module as their target, which is correct:
  the run loop only needs a stable object. Section 6.1 has the list.
- **Teardown.** `willDestroy` stays in the component, with the same
  statements in the same order, pointed at the modules. No module has a
  destroy hook.

### 2.3 Why this one

| Alternative | Why not |
| --- | --- |
| Plain functions that take the sheet (`undo(sheet)`) | The state (about 90 fields) has to stay on the component, or move to bags that are classes again. Every template handler needs a bound wrapper on the component. The component stays large. |
| Private sub-components that own parts of the template | It changes the render tree, the order modifiers run in, and when focus handlers are installed. That is behaviour. See 3.3. |
| A chain of base classes or mixins | Forbidden, and it is still one `this` with 440 members. |
| A narrow `Host` interface per module | 33 hand-kept interfaces that repeat signatures, generic over `T`. The section 3 table lists what each module needs instead; `ember-tsc` checks the real types. |
| Keep delegating methods on the component (a facade) | About 600 more lines in the component and one more call per cell read. See section 4. |

The helper functions and constants above the class (`samePos`, `stop`,
`clamp`, `afterRender`, `ROW_COLUMN_ID`, ...) are already plain functions,
not methods. They stay functions, in `util.ts`, or move next to their only
user. That is not a second pattern.

## 3. The module map

### 3.1 The component after the split

`src/components/eui-sheet.gts`, about 560 lines:

- imports and the module fields (about 130 lines);
- `@service euiI18n`, `translatedMessages`, `constructor`, `willDestroy`;
- what nearly every module reads: `types`, `messages`, `context`,
  `themeClass`, `sheetId`, `ariaLabel`, `showRowNumbers`, `canInsert`,
  `canDelete`, `colOffset`, `hasSummary`, `showEmpty`;
- the wiring: `wrapper`, `gridApi`, `cellContext`, `registerGridApi`,
  `registerSheetApi`, `setupWrapper`;
- `isModal`, and the template (259 lines), whole.

It still exports `default`, `EuiSheetSignature` and `CellView`
(`src/index.ts` imports both from this path; it does not change).
`WrapperBox` and `FieldEditorState` are also exported today, for
`field-editor.gts` only; they move, and that import follows.

"Only args, wiring and the template" is not fully met: the 12 small
getters above stay, because 20 or more modules read them and they are
derived from arguments only.

### 3.2 The modules

All in `packages/sheet/src/-private/sheet/`. Not under `src/components/`:
the build re-exports `components/**` as app components. "Property" is the
field on the component. `@` marks a tracked field. "Lines" is the moved
members plus about 30 for imports and the class header, rounded.

Six property names avoid a member that exists today with the same name:
`gridColumns` (`columns`), `groupHeaders` (`groups`), `filling` (`fill()`),
`edit` (`editing`), `validate` (`validation`), `rowMenu` (`menu`).

| # | File, property | Banner sections | What moves in | State | Reads | Lines |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `fields.ts`, `fields` | Fields; part of Field management; "A handler was called…" | `visibleFields`, `visibleFieldIds`, `hiddenFields`, `allFields`, `canHide`, `hideField`, `hideFields`, `showField`, `setFieldOrder`, `fieldDrag`, `columnVisibility`, `setVisibleColumns`, `checkOrderShown`, `typeOf`, `fieldById`, `valueEquals`, `expectUpdate` | `@localOrder`, `@localHidden`, `@orderEpoch`, `warnedUnchanged` | `args`, `types` | 260 |
| 2 | `grid-columns.ts`, `gridColumns` | Widths; Sort; Columns | `givenWidth`, `frozenWidth`, `keptWidth`, `onColumnResize`, `sorting`, `onGridSort`, `setSort`, `displayFor`, `columns`, `rowColumnWidth`, `leadingControlColumns`, `hasAddFieldColumn`, `trailingControlColumns`, `isAddFieldColumn`, `gridIndexOf`, `headerLinesClass` | `@resizedWidths`, `keptWidths`, `headerDisplays` | `fields`, `frozen`, `headerMenu`, `rows`, `scroll.layoutTick` | 290 |
| 3 | `header-menu.ts`, `headerMenu` | Columns (the menu items) | `groupMenuItems`, `fieldMenuItems` | none | `fieldEditor`, `args`, `messages` | 120 |
| 4 | `frozen.ts`, `frozen` | The frozen field | `frozenCount`, `frozenLayout`, `frozenHeaderClass`, `frozenCellProps`, `frozenStyle`, `clearFrozenOverlap`, `noteScrollLeft`, `keepFrozenScroll`, `onFrozenFocus` | `scrollLeftBeforeFocus`, `pressing` | `fields`, `gridColumns`, `scroll`, `dom`, `gridApi` | 165 |
| 5 | `grid-options.ts`, `gridOptions` | Row height; parts of The frozen field and Derived state | `rowHeight`, `setRowHeight`, `rowHeightsOptions`, `gridVars`, `firstColumnWidth`, `measureGroupWidth`, `virtualizationOptions`, `gridStyle`, `pinsAddRow` | `@localRowHeight`, `@groupMaxWidth` | `gridColumns`, `rows`, `frozen`, `fields`, `scroll` | 165 |
| 6 | `scroll.ts`, `scroll` | scroll helpers of The frozen field; `onScroll` | `onScroll`, `scrollElement`, `scrollBounds`, `cellInView`, `scrollGridBy`, `revealCell`, `pageRows` | `@layoutTick`, `@scrolledX` | `dom`, `frozen`, `ime`, `focus`, `edit`, `rowMenu`, `fieldEditor`, `selection`, `wrapper`, `gridApi` | 250 |
| 7 | `dom.ts`, `dom` | Grid wiring (lookups) | `cellElement`, `dataCell`, `rowNumberCell`, `headerCell`, `addFieldHeader`, `addFieldCell`, `headerElement`, `rowIndexOf`, `rowNumberElement`, `cursor`, `rectOf`, `pointInWrapper`, `toViewport`, `ownsNode`, `isInMenu`, `isInEditor`, `isInFieldEditor`, `isInGrid`, `isClipboardTarget`, `focusGridCell`, `focusRowNumberCell`, `focusHeader` | none | `wrapper`, `gridApi`, `colOffset`, `sheetId`, `frozen.noteScrollLeft`, `gridColumns.hasAddFieldColumn` | 255 |
| 8 | `rows.ts`, `rows` | Rows; row numbers | `groups`, `isGrouped`, `rowModel`, `rowCount`, `recordAt`, `recordRowAt`, `gridRowOf`, `recordRange`, `recordPos`, `coreRowOf`, `gridPos`, `rowKind`, `isRecordRow`, `clampToRecordRow`, `landingRow`, `firstLandingRow`, `lastLandingRow`, `recordRunOf`, `edgeFromGap`, `hasAddRow`, `isAddRow`, `addRowGroupAt`, `rowOf`, `hintOf`, `rowNumberOffset`, `numberOf`, `rowNumbers`, `positionOf`, `rowLabelOf` | none | `args`, `context`, `canInsert` | 325 |
| 9 | `group-headers.ts`, `groupHeaders` | Group headers | `groupHeaderAt`, `canToggleGroups`, `groupFieldOf`, `groupTitleOf`, `groupCellProps`, `toggleGroup`, `setGroupBy`, `toggleGroupByKey`, `noteGroupFocus`, `followGroupFocus`, `onGroupKeyDown`, `onGroupToggleClick`, `groupValuesOf`, `groupInsertOf`, `isGroupHeaderTarget` | `focusedGroup`, `groupFocusDropped` | `rows`, `dom`, `fields`, `frozen` | 235 |
| 10 | `selection.ts`, `selection` | selection parts of Derived state, Focus tracking and Keys | `range`, `isSelected`, `isRowSelected`, `isRowMarked`, `headerMarkCss`, `selectRows`, `selectColumns`, `extendHead`, `moveFocus`, `clampSelection`, `selectionRecords`, `touchedAt`, `touchedIn`, `touchedInRecords`, `clearSelection`, `focusRecordCell` | `@anchor`, `@head`, `@rangeKind` | `rows`, `fields`, `focus.domCursor`, `dom`, `checked`, `scroll`, `changes` | 265 |
| 11 | `outline.ts`, `outline` | The range outline; copy mark and flash | `rangeOutline`, `placeRangeOutline`, `copiedOutline`, `flashOutline`, `flashCells` | `@copied`, `@flash`, `flashTimer` | `rows`, `selection`, `edit`, `scroll`, `frozen`, `fields` | 235 |
| 12 | `checked.ts`, `checked` | Checked rows | `checkedIds`, `isChecked`, `checkedRecords`, `checkedState`, `setChecked`, `toggleChecked`, `toggleAllChecked`, `isCheckedRowsTarget` | `@localChecked`, `lastToggledRow` | `rows`, `dom`, `args` | 140 |
| 13 | `cells.ts`, `cells` | Called by the cell renderer | `cellView`, `cellViewFor`, `linkOf`, `openLink`, `liveRejection`, `validatedErrors`, `commitCellValue`, `canEdit` | `@rejections` | `fields`, `rows`, `selection`, `validate`, `resolve`, `uploads.dropPos`, `changes`, `context` | 160 |
| 14 | `focus.ts`, `focus` | Focus tracking | `onFocusIn`, `onRowNumberFocus`, `onFocusOut`, `trackFocusedCell`, `cellError`, `parkFocus`, `isParked`, `onPagePress` | `@focused`, `@readOnlyCue`, `domCursor`, `rowCursor`, `extending`, `keepRangeOnFocus`, `gridHadFocus`, `focusDropped`, `pagePressed` | `dom`, `selection`, `frozen`, `groupHeaders`, `rows`, `fields`, `cells`, `edit`, `ime`, `rowMenu` | 295 |
| 15 | `drag.ts`, `drag` | Focus tracking (press and drag) | `onMouseDown`, `watchRelease`, `onDragMove`, `feedAutoScroll`, `dragTo`, `onMouseOver`, `dragOver`, `onRelease`, `endDrag`, `stopWatchingRelease` | `@dragging`, `dragFrom`, `dragKind`, `dragPointer`, `autoScroll`, `suppressClick`, `pressOnFocusedCell` | `dom`, `selection`, `focus`, `rows`, `frozen`, `scroll`, `filling`, `rowMenu`, `touch`, `edit` | 300 |
| 16 | `touch.ts`, `touch` | Touch | `onPointerDown`, `onPointerMove`, `onPointerEnd`, `cancelLongPress`, `onLongPress`, `onClickCapture` | `lastPointerType`, `longPress`, `longPressOpened` | `edit`, `rowMenu`, `dom` | 100 |
| 17 | `clicks.ts`, `clicks` | `@editIn` (the clicks) | `onClick`, `onControlClick`, `onDoubleClick` | none | `dom`, `edit`, `cells`, `rows`, `frozen`, `fields`, `records`, `drag`, `checked`, `focus`, `groupHeaders`, `fieldEditor`, `expanded`, `selection` | 150 |
| 18 | `filling.ts`, `filling` | The fill handle; Ctrl+D and Ctrl+R | `fillHandleRange`, `placeFillHandle`, `onFillHandlePress`, `onFillMove`, `fillTo`, `fillWritten`, `onFillRelease`, `onFillKeyDown`, `stopFillDrag`, `isFillPreview`, `fill`, `fillRightSelection` | `fillSource`, `@fillTarget` | `rows`, `selection`, `dom`, `drag`, `frozen`, `changes`, `scroll`, `focus`, `edit` | 295 |
| 19 | `ime.ts`, `ime` | Composition | `startIme`, `placeIme`, `onImeCompositionStart`, `onImeCompositionEnd`, `onImeInput`, `onImeKeyDown`, `endIme`, `finishIme` | `imeInput`, `imePos`, `imeComposing`, `@imeActive` | `dom`, `fields`, `cells`, `edit` | 125 |
| 20 | `keys.ts`, `keys` | Keys and clipboard (the keys); The shortcut list | `onKeyDown`, `handleCommandKey`, `handleNavKey`, `onParkedKeyDown`, `handleLastFieldKey`, `handleGroupedEndKey`, `handleHomeKey`, `onAddRowKeyDown`, `handleGroupedRowNumberKey`, `onRowNumberKeyDown`, `onEditKeyDown`, `showShortcuts`, `closeShortcuts`, `shortcutContext` | `@shortcutsOpen` | 21 modules: mostly `rows`, `selection`, `dom`, `edit`, `fields`, `rowMenu`, `focus`, `frozen` | 560 |
| 21 | `clipboard.ts`, `clipboard` | Keys and clipboard (copy, cut, paste); copy of Records | `onCopy`, `rangeTsv`, `onCut`, `onPaste`, `pasteInsert`, `pasteHeadRow`, `isRangeTarget`, `copyRows`, `rowsTsv` | none | `rows`, `selection`, `dom`, `edit`, `groupHeaders`, `checked`, `outline`, `changes`, `uploads`, `resolve`, `focus` | 290 |
| 22 | `history.ts`, `history` | Undo and redo; part of Emitting change sets | `historyOptions`, `undo`, `redo`, `clearHistory`, `touchesRecords`, `applyHistory`, `selectChanged`, `recordHistory`, `replaceEntry`, `remapIds` | `undoStack`, `redoStack`, `remapped` | `changes`, `resolve`, `cells.rejections`, `records`, `selection`, `checked`, `expanded`, `follow`, `edit`, `fields`, `rows` | 405 |
| 23 | `changes.ts`, `changes` | Emitting change sets | `emit`, `emitText` | `pendingOwn` | `cells.rejections`, `resolve`, `checked`, `history`, `validate`, `outline`, `args.onChange` | 145 |
| 24 | `validate.ts`, `validate` | `@validate` | `scheduleValidate`, `endValidateWaiter`, `runValidate` | `@validation`, `validateTimer`, `validateSeq`, `validateController`, `validateToken`, `changedSinceRun` | `args` | 95 |
| 25 | `resolve.ts`, `resolve` | Bulk resolve | `startResolve`, `finishResolve`, `endCall`, `endCallsOf`, `dropPending` | `@pendingCells`, `pendingCalls` | `changes`, `fields`, `context`, `messages` | 185 |
| 26 | `uploads.ts`, `uploads` | uploads; Dragging files over an attachment cell | `pasteFiles`, `uploadFiles`, `dropCellAt`, `onDragOver`, `onDragLeave`, `onDrop` | `@dropPos` | `resolve`, `rows`, `dom`, `fields`, `selection`, `changes` | 200 |
| 27 | `edit.ts`, `edit` | Edit lifecycle; Editor callbacks; `@editIn` | the `Editing` class; `startEdit`, `editingList`, `editorRecord`, `editorValue`, `commit`, `cancel`, `onDraftChange`, `onDraftValue`, `onEditorSave`, `onEditorCommit`, `onEditorFocusOut`, `growOf`, `onDragStart`, `editsInRecord`, `editInRecord`, `takePendingFormEdit` | `@editing`, `draft`, `draftDirty`, `draftValue`, `draftKind`, `pendingFormEdit` | `rows`, `fields`, `dom`, `changes`, `cells`, `expanded`, `outline`, `uploads`, `frozen`, `scroll` | 330 |
| 28 | `records.ts`, `records` | Records: insert, delete, duplicate | `newValues`, `insertOne`, `insertNear`, `appendRecord`, `appendToGroup`, `firstEditableField`, `insertFromApi`, `deleteRecordIds`, `duplicate`, `applyPendingFocus` | `pendingFocus` | `rows`, `selection`, `fields`, `edit`, `changes`, `groupHeaders`, `follow`, `focus`, `dom` | 275 |
| 29 | `row-menu.ts`, `rowMenu` | The row menu; the context menu | `openMenuAt`, `openMenu`, `closeMenu`, `onDocumentMouseDown`, `menuItems`, `menuLink`, `menuFieldId`, `onMenuSelect`, `menuAnchor`, `onContextMenu`, `openContextMenu`, `menuRowOf` | `@menu` | `dom`, `selection`, `rows`, `focus`, `edit`, `touch`, `records`, `fields`, `cells`, `checked`, `clipboard`, `expanded` | 310 |
| 30 | `expanded.ts`, `expanded` | The expanded record | `expandedId`, `setExpanded`, `expandedRecordValue`, `expandedShell`, `expandRecord`, `closeExpanded`, `expandedStep`, `stepExpanded`, `recordTitleOf`, `formContext`, `commitFormValue`, `commitFormText`, `clearFormField`, `commitForm`, `afterFormRender` | `@formEditorOpen`, `@localExpandedId`, `expandedFrom` | `rows`, `fields`, `selection`, `edit`, `changes`, `dom`, `focus` | 190 |
| 31 | `follow.ts`, `follow` | Following `@records` | `watchRecords`, `recordsRendered`, `groupsRendered`, `endTransients`, `refindRow`, `followRows`, `followRecords` | `lastRecords`, `lastIds`, `lastRowModel`, `lastGroups`, `lastGroupsArg` | 18 modules: mostly `rows`, `dom`, `drag`, `selection`, `rowMenu`, `ime`, `focus` | 335 |
| 32 | `field-editor.ts`, `fieldEditor` | Field management | the `FieldEditorState` class; `addingField`, `fieldEditorList`, `fieldEditorTypes`, `fieldEditorPlace`, `openFieldEditor`, `addField`, `editField`, `duplicateField`, `askDeleteField`, `saveFieldEditor`, `confirmDeleteField`, `runFieldHandler`, `closeFieldEditor`, `noteCreatedAfter`, `watchFields`, `fieldsRendered`, `placeCreated`, `forgetFields` | `@fieldEditorState`, `lastFieldTypes`, `createdAfter` | `fields`, `gridColumns`, `dom`, `edit`, `history`, `rowMenu`, `resolve`, `selection`, `cells` | 420 |
| 33 | `api.ts`, `api` | Blocks; the `SheetApi` object | `sheetApi`, `blockApi` | `sheetApi` (one object, built once) | `history`, `fields`, `fieldEditor`, `expanded`, `records`, `keys`, `gridOptions`, `groupHeaders`, `selection`, `checked`, `gridColumns` | 70 |

Three files without a class:

| File | Holds | Lines |
| --- | --- | --- |
| `types.ts` | `CellView`, `WrapperBox`, `PendingEntry`, `PendingCall`, `HistoryEntry`, `PendingFocus`, `PendingOwn`, `Validation`, `Touched`, `FocusedCell`, `FrozenLayout`, `RangeKind`, `MenuState`, `ExpandedFrom`, `UploadField` | 150 |
| `util.ts` | functions and constants more than one module uses: `stop`, `samePos`, `sameRange`, `sameIds`, `sameLayout`, `clamp`, `isPromise`, `afterRender`, `uploadOf`, `nextTempId`, `resolveWaiter`, `ROW_COLUMN_ID`, `ADD_FIELD_COLUMN_ID`, `ADD_FIELD_WIDTH`, `EMPTY_CHANGE_SET` | 130 |
| `header-display.gts` | `headerDisplay` (it has a `<template>`) | 25 |

A constant or function with one user moves into that module's file, above
its class: `ROW_HEIGHTS` (grid-options), `LONG_PRESS_MS` (touch),
`isMenuKey`, `ARROW_STEPS` (keys), `writeClipboard` (clipboard),
`isOwnChange` (follow), `FLASH_SOURCES` (changes), `HISTORY_LIMIT`
(history), `validateWaiter` (validate), and so on.

Totals: 33 modules, the largest `keys.ts` at about 560 lines (its
`onKeyDown` alone is 193 lines and is not split: rule 8). About 7,300
lines move. `tempIdCounter` stays one counter per page: `nextTempId` is
defined once, in `util.ts`.

### 3.3 The template stays whole, in the component

No part of the template moves to a sub-component. Only paths change:
`this.columns` becomes `this.gridColumns.columns`, `this.onKeyDown`
becomes `this.keys.onKeyDown`, and so on (about 75 paths).

Why: the wrapper `<div>` carries 4 modifiers and 21 `{{on}}` listeners in
an order that matters (capture listeners, `setupWrapper` before
`watchRecords`), and the grid's `<div>` one more modifier. The overlays (`RangeOutline`, `FillHandle`, `RowMenu`,
`EditorFrame`, ...) are already private components. What is left is
wiring. Splitting it would change when things render and gain nothing.

v0.4's two template features (02 full screen, 04 `<:recordFooter>`) each
add a few lines to this template, as their designs say.

## 4. The cell-facing interface

### 4.1 Today

Every `-private` component gets the component as `@sheet` (the grid's
cells get it through `cellContext`). `sheet` is typed as the class in all
of them: `EuiSheet<object>` in the two grid cells, `EuiSheet<any>` in the
others (`any` is only the record type; optional in `editor-frame.gts`).
So a member that moved away is a type error at every caller, and
`ember-tsc` finds it.

| File | Members of the component it uses |
| --- | --- |
| `sheet-cell.gts` (per cell) | `colOffset`, `groupHeaderAt`, `cellView`, `groupCellProps`, `frozenCellProps`, `isChecked`, `isFillPreview`, `isAddRow`, `messages`, `args.highlight`, `pinsAddRow`, `commitCellValue` |
| `row-number-cell.gts` (per row) | `isAddRow`, `groupHeaderAt`, `recordAt`, `rowLabelOf`, `isChecked`, `isRowSelected`, `isRowMarked`, `positionOf`, `groupCellProps`, `frozenCellProps`, `pinsAddRow`, `messages`; the header: `checkedState` |
| `footer-cell.gts` | `args.summary`, `frozenCellProps` |
| `group-label.gts` | `groupTitleOf`, `canToggleGroups`, `messages` |
| `add-pinned.gts` | none (it gets a label) |
| `fill-handle.gts` | `placeFillHandle` |
| `range-outline.gts` | `placeRangeOutline` |
| `ime-catcher.gts` | writes `imeInput`; `onImeCompositionStart`, `onImeCompositionEnd`, `onImeInput`, `onImeKeyDown`, `endIme` |
| `layer.gts` | `wrapper`, `sheetId`, `themeClass`; binds `onKeyDown`, `onMouseDown`, `onPointerDown`, `onPointerMove`, `onPointerEnd`, `onClickCapture`, `onFocusIn`, `onFocusOut`, `onClick`, `onContextMenu` |
| `editor-frame.gts` | `toViewport`, `wrapper` |
| `row-menu.gts` | `wrapper` only (no edit needed) |
| `field-editor.gts` | `fieldById`, `fieldEditorTypes`, `saveFieldEditor`, `closeFieldEditor`, `confirmDeleteField`, `toViewport`, `wrapper`, `messages`, `themeClass`, `args.fieldEditor` |
| `record-shells.gts` | `recordTitleOf`, `expandedStep`, `stepExpanded`, `closeExpanded`, reads `formEditorOpen`, `messages`, `themeClass` |
| `record-form.gts` | `takePendingFormEdit`, `cellViewFor`, `allFields`, `typeOf`, `context`, `commitFormValue`, `commitFormText`, `clearFormField`, `afterFormRender`, `undo`, `redo`, writes `formEditorOpen` |
| `record-form-field.gts` | `cellViewFor`, `commitFormValue`, `uploadFiles`, `openLink`, `args.getRecordId`, `messages`, `themeClass` |
| `shortcut-list.gts` | `shortcutContext`, `closeShortcuts`, `messages`, `themeClass` |

### 4.2 After the split

The components still get `@sheet`. They call the module that owns the
member: `this.sheet.rows.isAddRow(row)`, `this.sheet.cells.cellView(...)`,
`@sheet.keys.onKeyDown`. `messages`, `themeClass`, `colOffset`, `wrapper`,
`sheetId`, `context` and `args` stay on the component, so those reads do
not change.

`cellContext` stays `{ sheet: this }`, one stable object.

Each `-private` file is edited in the stage that moves what it calls
(section 5 names them). The edit is the path only.

The alternative is a facade: the component keeps `isAddRow(row) { return
this.rows.isAddRow(row); }` for the about 60 members above, and no
`-private` file changes. It costs about 600 lines in the component and one
more call per cell read, and the next reader has two places to look. This
design does not take it. It is open question 2.

### 4.3 Cost per cell

What a cell reads per render, and where it is after the split:

- `sheet-cell.gts`: `cells.cellView` (inside it: `rows.recordAt`,
  `fields.visibleFields`, `selection.isSelected`, `uploads.dropPos`,
  `fields.typeOf`, `cells.liveRejection`, `resolve.pendingCells`,
  `validate.validation`, `cells.linkOf`), `groupHeaders.groupHeaderAt`,
  `groupHeaders.groupCellProps`, `frozen.frozenCellProps`,
  `checked.isChecked`, `filling.isFillPreview`, `rows.isAddRow`,
  `gridOptions.pinsAddRow`.
- `row-number-cell.gts`: `rows.isAddRow`, `rows.recordAt`,
  `rows.rowLabelOf`, `rows.positionOf`, `checked.isChecked`,
  `selection.isRowSelected`, `selection.isRowMarked`, and the three group
  and frozen reads above.

Each of these gains one property load: `sheet.rows`, a plain field that
is set once and never tracked. It adds no call, no allocation and no
autotracking tag. A data cell's render gains about 15 such loads, next to
a `Map` lookup, an array `find` and `type.format`. Nothing new runs per
cell.

Per scroll step: `onScroll`, and the `placeFillHandle` and
`placeRangeOutline` calls `layoutTick` triggers, are the same code in a
new file. Nothing is added.

## 5. Stages

Eight stages, numbered 0 to 7. Order: the leaves first (`fields`, the
columns, `dom`), then the row model alone, then selection and focus. What
reads the most modules moves last (`keys` reads 21, `follow` 18), so its
body is rewritten once, against final paths. What moved early is touched
again only where it reads something that moves later: the stage 1 modules
read `rowModel` and a few others as `this.sheet.x`, and stage 2 re-points
those lines.

A member that has not moved yet is read as `this.sheet.x`; when it moves,
`ember-tsc` lists every reader to re-point.

### The checks, after every stage

1. `pnpm lint:types` in `packages/sheet`: no error. This is the main net:
   a missed caller in a module, a `-private` component or a template is a
   type error.
2. The tests' `ember-tsc` (`tsconfig.eslint.json`): the baseline's 19
   errors, in the same files.
3. `pnpm lint:js` (ESLint with the repo's formatting rules): clean.
4. The full suite, `pnpm test` in `packages/sheet`: the baseline count,
   all green.
5. `pnpm docs:api:check` at the repo root.
6. **The verbatim check** (a scratch script, not committed): for every
   moved member, take its body before and after, replace `this.sheet.<module>.`,
   `this.sheet.` and `this.` by one token, drop whitespace, and compare.
   They must be equal. It also compares the decorator (`@tracked`,
   `@cached`, `@action`, none) and the kind (method, getter, arrow field).
7. **The owner gate**: in `src/-private/sheet/*.ts`, no `this` passed as a
   value (`grep -nE "[(,] ?this ?[,)]"`), except the targets of `later`
   and `debounce`; no `this.isDestroying` or `this.isDestroyed` (a type
   error anyway).
8. In `src/-private/sheet/`, every import of `components/eui-sheet.gts`
   is `import type` (a grep).
9. `git diff --stat` against the stage's start: nothing under `tests/`,
   `packages/core/`, `src/core/`, `src/types.ts`, `src/index.ts`,
   `src/search-ui/`.

One commit per stage on `feat/sheet`, with the results in
`V03-RESULTS.md`.

### Stage 0: baseline and the shared top of the file (about 300 lines)

- Record the baseline: the suite's count (the brief says 527; a text count
  of `test(` in `tests/` gives 532, so take the runner's number), the 19
  `ember-tsc` errors by file, and `declarations/` of a `pnpm build` (kept
  in scratch, for the last stage).
- New: `types.ts`, `util.ts`, `header-display.gts`. Of lines 164 to 673,
  only what those three files hold moves now (3.2). The component imports
  it and re-exports `CellView`. `field-editor.gts` imports `WrapperBox`
  from `types.ts`.
- What has one user stays in the component file until that user's stage:
  the `Editing` and `FieldEditorState` classes (stage 5) and the
  single-module constants and functions (`ROW_HEIGHTS`, `LONG_PRESS_MS`,
  `isMenuKey`, `writeClipboard`, `isOwnChange`, ...). So each later stage
  carries a few dozen lines more than its heading says; the largest,
  stage 5, stays under 1,500.
- Write the verbatim script and the owner gate.
- Probe: a plain class with one `@action` method, one `@cached` getter and
  one `@tracked` field, used from a template in a scratch test (not
  committed). If `@action` does not bind there, stages 3 to 7 use arrow
  fields for the 20 handlers instead; the verbatim script then allows that
  one change of kind.
- Can go wrong: a constant used by one module is put in `util.ts` and the
  other way round. Harmless; the type checker finds a missing import.

### Stage 1: fields, columns and the grid's options (about 1,050 lines)

- New: `fields.ts`, `grid-columns.ts`, `header-menu.ts`, `frozen.ts`,
  `grid-options.ts`, `dom.ts`.
- Also edited: the template (the grid's arguments, `gridVars`,
  `measureGroupWidth`, `headerLinesClass`, `pinsAddRow`,
  `isAddFieldColumn`); `sheet-cell.gts`, `row-number-cell.gts`,
  `footer-cell.gts` (`frozenCellProps`, `pinsAddRow`); `field-editor.gts`,
  `editor-frame.gts` (`toViewport`, `fieldById`); `record-form.gts`
  (`allFields`, `typeOf`).
- Can go wrong:
  - `columns` must not gain a dependency: a new array makes the grid drop
    its resized widths. Its reads stay what they are: `orderEpoch`,
    `frozenCount`, `colOffset`, `args.onSortChange`,
    `args.onFilterByField`, `args.fieldWidths`, `args.onFieldWidthChange`,
    `messages`, `types`, `visibleFields` (and each field's `width`,
    `label`, `description`), and what `groupMenuItems` and
    `fieldMenuItems` read. `keptWidths` and `headerDisplays` stay plain.
  - `resizedWidths.columns === this.columns` compares array identity: the
    getter must stay `@cached` on one instance.
  - `measureGroupWidth` is a modifier that closes over `this`: its
    `isDestroying(this)` becomes `this.sheet`.
  - Caught by: the view, frozen, fields and polish tests; check 6 and 7.

### Stage 2: the row model and the cells (about 740 lines)

Kept small on purpose: this is the per-cell path.

- New: `rows.ts`, `group-headers.ts`, `checked.ts`, `cells.ts`.
- Also edited: the template (`rowCount`, `isGrouped`); `sheet-cell.gts`,
  `row-number-cell.gts`, `group-label.gts`, `record-form.gts`,
  `record-form-field.gts`.
- Can go wrong:
  - `rowModel` is `@cached` on `args.records.length`, `args.groups` and
    `hasAddRow`. Read through any other path (a copy in a field) it would
    go stale.
  - `sheet.groups` is today the `@groups` getter. After this stage it is
    `sheet.rows.groups`, and `sheet.groupHeaders` is the module: a missed
    `sheet.groups.length` is a type error.
  - The warning `ember-eui.sheet.groups-loaded-mismatch` is raised inside
    the `rowModel` getter, and the groups tests look for it. One cached
    getter, one evaluation per change, as now.
  - Caught by: the groups, group-header, rows, add-pinned and frozen
    tests.
- Extra check, once: a temporary counter in `cellView` (not committed),
  one scroll step of the large-data demo before and after the stage: the
  same number of calls.

### Stage 3: selection, focus, scroll (about 1,010 lines)

The first risky one: the plain focus flags.

- New: `selection.ts`, `outline.ts`, `scroll.ts`, `ime.ts`, `focus.ts`.
- Also edited: the template (`onScroll`, `onFocusIn`, `onFocusOut`, the
  four `RangeOutline` blocks, `layoutTick`, `scrolledX`, `headerMarkCss`,
  `cellError`); `setupWrapper` (`this.focus.onPagePress`, the same
  function for add and remove); `willDestroy` (`flashTimer`);
  `row-number-cell.gts`, `range-outline.gts`, `ime-catcher.gts`,
  `layer.gts` (two handlers).
- Can go wrong:
  - `anchor`, `head` and `rangeKind` are written by 9 modules-to-be, and
    `domCursor`, `keepRangeOnFocus`, `scrollLeftBeforeFocus`, `pressing`
    by 5 to 8. Each must end up as one field on one module. A second
    copy (a leftover field on the component) would compile if nothing
    else read it. Check 6 does not catch a leftover; so the stage ends
    with a grep that the moved field names are gone from the component.
  - `parkFocus` is passed as a value (`afterRender(this, this.parkFocus)`,
    `next(this.parkFocus)`): it must stay an arrow field.
  - `ime-catcher.gts` writes `sheet.imeInput`: it becomes
    `sheet.ime.imeInput`.
  - Caught by: the range, click, layers, ime, polish and groups-nav
    tests.

### Stage 4: writes and history (about 1,120 lines)

- New: `changes.ts`, `validate.ts`, `resolve.ts`, `uploads.ts`,
  `history.ts`, `records.ts`.
- Also edited: the template (`onDragOver`, `onDragLeave`, `onDrop`);
  `willDestroy` (the validate lines, `endCall` loop); `record-form.gts`
  (`undo`, `redo`); `record-form-field.gts` (`uploadFiles`).
- Can go wrong:
  - `debounce(this, this.runValidate, ...)`: the run loop keys the
    debounce on the target and the method. Inside the module both are
    stable, so it still coalesces. `willDestroy` cancels
    `this.validate.validateTimer`.
  - `finishResolve`, `uploadFiles` and `runValidate` read
    `this.isDestroying`: it becomes `this.sheet.isDestroying` (a type
    error if missed).
  - The test waiters (`validateWaiter`, `resolveWaiter`) are built once
    per page, at module scope: each must be defined in one file only.
  - `emit` is the hub: its order (rejections, `dropPending`, checked,
    history, `pendingOwn`, `changedSinceRun`, `onChange`,
    `scheduleValidate`, copy mark, flash) is fixed by check 6.
  - Caught by: the history, resolve, validate, rows, types and
    custom-type tests.

### Stage 5: editing, the expanded record, fields, the menu, following (about 1,360 lines)

- New: `edit.ts`, `expanded.ts`, `field-editor.ts`, `row-menu.ts`,
  `follow.ts`.
- Also edited: the template (`watchRecords`, `watchFields`, the menu, the
  field editor, the record shells, the editor block and its 9 callbacks,
  `addingField`, `onDragStart`, `onContextMenu`); `willDestroy`
  (`onDocumentMouseDown`); `record-form.gts`, `record-shells.gts`,
  `field-editor.gts`, `layer.gts` (`onContextMenu`).
- Can go wrong:
  - `commit` sets `editing = null` first, as a re-entrancy guard against
    the `focusout` it causes. Verbatim keeps it.
  - `editingList` is `@cached` and keyed by identity in `{{#each}}`: it
    must stay cached on the module.
  - `onDocumentMouseDown` is added in `openMenu` and removed in
    `closeMenu` and in `willDestroy`: all three must name the same field
    of `rowMenu`.
  - `watchRecords` and `watchFields` are modifiers on the wrapper. Their
    position in the template does not change.
  - `record-form.gts` writes `sheet.formEditorOpen`: it becomes
    `sheet.expanded.formEditorOpen`.
  - Caught by: the record, fields, rows, touch, layers and groups-intents
    tests.

### Stage 6: the pointer (about 720 lines)

- New: `drag.ts`, `touch.ts`, `clicks.ts`, `filling.ts`.
- Also edited: the template (9 mouse, pointer and click listeners,
  `dragging`, `fillTarget`, `FillHandle`); `willDestroy`
  (`stopWatchingRelease`, `stopFillDrag`, `autoScroll.stop`,
  `cancelLongPress`); `fill-handle.gts`, `sheet-cell.gts`
  (`isFillPreview`), `layer.gts` (7 handlers).
- Can go wrong:
  - Document listeners: `onRelease`, `onDragMove`, `onFillMove`,
    `onFillRelease`, `onFillKeyDown` are added and removed by identity.
    They stay arrow fields on one module.
  - `later(this, this.onLongPress, LONG_PRESS_MS)`: `onLongPress` is a
    plain method called with the module as `this`. Correct as it is; do
    not change the target to the sheet.
  - `stopFillDrag` has `isDestroying(this)`: it becomes `this.sheet`, or
    the fill target would be written during destroy.
  - Caught by: the range, touch, click, frozen and polish tests.

### Stage 7: keys, clipboard, the API (about 815 lines)

- New: `keys.ts`, `clipboard.ts`, `api.ts`.
- Also edited: the template (`onKeyDown`, `onCopy`, `onCut`, `onPaste`,
  `blockApi`, `shortcutsOpen`); `registerSheetApi`; `layer.gts`
  (`onKeyDown`); `shortcut-list.gts`.
- Then the end checks:
  - the component holds only what 3.1 lists;
  - `pnpm build`, and `declarations/index.d.ts`, `declarations/types.d.ts`
    and `declarations/core/**` are the same as the stage 0 copies;
  - a pass by hand through the docs demos (large data, groups, frozen
    fields, the expanded record), as after the earlier batches.
- Can go wrong:
  - `sheetApi` must stay one object created once: `@registerApi` gets it
    once and tests keep it.
  - `blockApi` is `@cached`: its reads must stay `visibleFields`,
    `hiddenFields`, `args.sort`, `rowHeight`, `checkedRecords`,
    `args.groupBy`, `args.groups`. Reading a module field does not add a
    dependency (module fields are not tracked).
  - Caught by: every keyboard test (most files), the search and view
    tests for the block API.

## 6. Risks and how each is caught

### 6.1 `this` as the owner

A plain object passed to `isDestroying`, `isDestroyed` or `afterRender`
compiles and is never "destroying": the callback would run after the
component is gone. There are 31 such lines today:

- `isDestroying(this)` / `isDestroyed(this)`: `checkOrderShown`,
  `measureGroupWidth`, `expectUpdate`, `stopFillDrag`, `revealCell`,
  `parkFocus`, `runFieldHandler` (twice), `flashCells`;
- `afterRender(this, ...)`: `onFrozenFocus`, `registerSheetApi`,
  `watchRecords`, `insertOne`, `duplicate`, `closeExpanded`,
  `afterFormRender`, `onFocusIn`, `editInRecord`, `selectChanged`,
  `onScroll`, `closeFieldEditor`, `watchFields`;
- `this.isDestroying` / `this.isDestroyed`: `onContextMenu`,
  `finishResolve`, `uploadFiles`, `runValidate` (a type error on a module,
  so caught by check 1);
- `later(this, ...)` in `onPointerDown`, `debounce(this, ...)` in
  `scheduleValidate`: stay as they are;
- `guidFor(this)`, `getEuiThemeContext(this)`, `cellContext = { sheet:
  this }`: stay on the component.

Caught by check 7 (the grep gate) in every stage. Check 6 treats
`(this)` and `(this.sheet)` as different, so it flags each of these lines
for a look.

### 6.2 State written from more than one module

Rule 10 gives each field one owner. These are written from other modules
too (the same writes as today):

| Field (owner) | Also written by |
| --- | --- |
| `@anchor`, `@head`, `@rangeKind` (`selection`) | `clipboard`, `drag`, `filling`, `focus`, `follow`, `history`, `keys`, `records`, `rowMenu` |
| `domCursor` (`focus`) | `drag`, `filling`, `follow`, `history`, `keys`, `records`, `rowMenu`, `selection` |
| `keepRangeOnFocus` (`focus`) | `clicks`, `drag`, `expanded`, `keys`, `rowMenu` |
| `extending`, `rowCursor`, `@readOnlyCue`, `@focused` (`focus`) | `drag`, `keys`, `follow`, `scroll` |
| `scrollLeftBeforeFocus`, `pressing` (`frozen`) | `clicks`, `drag`, `filling`, `focus`, `keys`, `scroll` |
| `suppressClick`, `pressOnFocusedCell`, `dragPointer` (`drag`) | `clicks`, `filling` |
| `@copied` (`outline`) | `changes`, `clipboard`, `edit`, `follow`, `keys` |
| `@rejections` (`cells`) | `changes`, `fieldEditor`, `history` |
| `@pendingCells`, `pendingCalls` (`resolve`) | `history`, `uploads` |
| `undoStack`, `redoStack` (`history`) | `fieldEditor` |
| `pendingOwn` (`changes`) | `follow`, `history` |
| `changedSinceRun` (`validate`) | `changes` |
| `@editing` (`edit`) | `fieldEditor`, `follow` |
| `@formEditorOpen`, `@localExpandedId`, `expandedFrom` (`expanded`) | `edit`, `history`, `follow`, `record-form.gts` |
| `@localOrder` (`fields`) | `fieldEditor` |
| `@layoutTick` (`scroll`) | `gridColumns` |
| `lastIds` (`follow`), `pendingFocus` (`records`), `lastToggledRow` (`checked`), `@dropPos` (`uploads`), `focusedGroup`, `groupFocusDropped` (`groupHeaders`) | `history`, `follow`, `focus` |

The risk is a field declared twice (once on the old owner, once on the
new), each side writing its own. Caught by: the type checker for readers,
and the end-of-stage grep that a moved field's name is no longer declared
in the component.

This table is also the honest picture of the coupling: selection and
focus state is shared by a third of the modules. The split does not
change that. It makes it visible.

### 6.3 The other risks

| Risk | Where | How it is caught |
| --- | --- | --- |
| `this` binding of a handler | 20 `@action` methods, 39 arrow fields and modifiers | Rule: no change of kind (check 6). The stage 0 probe for `@action` on a plain class. `@action` on a Glimmer component already runs on a class that is not an `EmberObject`, so it is expected to work; not run yet. |
| A helper call losing `this` | `growOf`, `editorValue`, `editorRecord`, `isAddFieldColumn` | They stay arrow fields (check 6). The editor tests fail at once otherwise. |
| A `@tracked` field moving owner | 29 tracked fields | Tracking is per field of an object, wherever the object is. Rule 9 and check 6 keep the decorator. |
| A `@cached` getter gaining or losing a dependency | 26 cached getters, most of all `columns`, `rowModel`, `blockApi`, `context`, `visibleFields`, `gridStyle`, `editingList` | A module field (`sheet.rows`) is plain and set once: reading it adds no dependency. Bodies are verbatim. A rebuilt `columns` array makes the grid drop a resized width, which the view and fields tests would show. |
| A module read too early | a field initialiser that reads `this.sheet.x` | The rule in 2.2, and a review of each new file's initialisers. A crash at construction, so every test fails. |
| The destructor | `willDestroy`: `flashTimer`, `validateTimer`, `validateController`, `endValidateWaiter`, `stopWatchingRelease`, `stopFillDrag`, `autoScroll.stop`, `cancelLongPress`, `onDocumentMouseDown`, `endCall` for each pending call | It stays in the component, same order, new paths. A leaked waiter makes `settled()` hang: the suite catches it. |
| Listener cleanup | `document`: `onPagePress` (two events), `onDocumentMouseDown`, `onRelease`, `onDragMove`, `onFillMove`, `onFillRelease`, `onFillKeyDown`; `window`: the `mouseup` in `onContextMenu` | Each add and remove names the same arrow field of the same module. Reviewed per stage with a grep for `addEventListener` and `removeEventListener` pairs. |
| `registerApi` | `registerSheetApi` (stays), `sheetApi` (moves to `api.ts`) | One object, built once in a field initialiser whose closures read the sheet lazily. The tests that hold the API across renders. |
| Modifiers in the template | `setupWrapper`, `watchRecords`, `watchFields`, `registerSheetApi`, `measureGroupWidth` | Same elements, same order, same arguments; only the path to the modifier changes. A modifier's function is a stable field, so it is not re-installed. |
| Test access | see 6.4 | |
| The exported class's shape | `declarations/components/eui-sheet.d.ts` | Open question 1. |
| A page-wide singleton defined twice | `tempIdCounter`, `validateWaiter`, `resolveWaiter` | Each lives in one file, at module scope, as now. Reviewed in stages 0 and 4. |
| Line reflow hiding a change | Prettier re-wraps lines once `this.` becomes `this.sheet.rows.` | Check 6 ignores whitespace, so a reflow is not noise and a real change still shows. |
| A long run failing for an unrelated reason | the Mac sleeping pauses the sandbox | Run the suite as the earlier batches did (background, the long disconnect timeout). |

### 6.4 Test access

No test reaches into the component. Checked in `tests/`:

- no owner lookup of the component (the two `owner.lookup` calls are for
  the Emotion cache and the `eui-i18n` service);
- no `this.sheet`, `cellContext` or `sheetApi` read from a test; the API
  is taken through `@registerApi`;
- 27 files import the component by `#src/components/eui-sheet.gts`: the
  path and the default export stay;
- three private files are imported by path and stay where they are:
  `#src/-private/rejections.ts`, `#src/-private/theme.ts`,
  `#src/-private/auto-scroll.ts`;
- `-private/styles.ts` is read as text by a glob: it stays;
- `core-boundary-test.ts` reads every file under `src/` as text and fails
  on an import of `ember-search-ui`. The new modules are read too and
  import nothing of the kind.

So no test needs an edit, and none constrains the module layout.

## 7. v0.4 fit

v0.4's README names five module areas: the header menu, the row menu, the
cells, the API, the grid options. All five exist here under those names.

| # | Feature | Lands in |
| --- | --- | --- |
| 01 | Fit a column to its content | new `-private/fit-width.ts`; the menu items in `sheet/header-menu.ts`; the width is applied next to `onColumnResize` in `sheet/grid-columns.ts`; `fitField`, `fitFields` in `sheet/api.ts` |
| 02 | Full screen | new `-private/full-screen.ts`; the wrapper's class in the component template; `setFullScreen`, `isFullScreen` in `sheet/api.ts` |
| 03 | App items in the header menu | `sheet/header-menu.ts` (a third items method, pushed in `columns` after `fieldMenuItems`) |
| 04 | `<:recordFooter>` | `record-shells.gts` and the component template; nothing in `sheet/expanded.ts` |
| 05 | Copy with field names | the item in `sheet/row-menu.ts` (`menuItems`); the text next to `rowsTsv` in `sheet/clipboard.ts`; `headerLine` in `core/tsv.ts` |
| 06 | `toCsv` | `core/csv.ts` only |
| 07 | `parseCsv`, `importMatrix`, `api.appendRows` | `core/csv.ts`; `appendRows` in `sheet/api.ts`, calling a method next to `insertFromApi` in `sheet/records.ts` |
| 08 | `@cellColor` | `cellViewFor` in `sheet/cells.ts` (the one place a cell's view is built; batch 4's row colour goes there too); drawn in `sheet-cell.gts` |
| 09 | `@onVisibleRangeChange` | new `-private/visible-range.ts`; `virtualizationOptions` in `sheet/grid-options.ts` |

One note for 03 and 01: the "Filter by this field" item is built inside
the `columns` getter today and stays there (rule 8). v0.4 can move it
into `header-menu.ts` when it adds its own items.

## 8. What was checked and what was not

Checked:

- `eui-sheet.gts` was read in full, lines 1 to 7,895.
- Every member of the class (444, counted by a script) is assigned to
  exactly one module or to the component; the script fails on a member
  that is missing or assigned twice. The line counts, the "Reads" columns
  and the table in 6.2 come from that script, not from memory.
- Every use of the component from `src/-private/**` and `src/search-ui/**`
  (section 4.1), by grep of every form (`this.sheet.`, `this.args.sheet.`,
  `@sheet.`, `sheet.`).
- How `sheet` is typed in the cells: `EuiSheet<object>`, through one cast
  of `cellContext` to an interface. No `any`.
- `src/types.ts` does not refer to the component or its instance.
- The tests' access to internals (section 6.4).
- ESLint has no import-cycle rule for this package.
- The build publishes `components/**` as app re-exports: the modules are
  not put there.
- The 31 lines that pass `this` as an owner (6.1).
- `V03-DESIGN.md` section 3 (the 3c row) and `v04/README.md`.

Not checked:

- **Nothing was run.** No test, no `ember-tsc`, no build. The 527 tests
  and the 19 baseline errors are taken from the brief and from
  `V03-RESULTS.md`.
- `@action` on a plain class was reasoned about, not tried (the stage 0
  probe).
- The script's parser is line-based. Its line counts include the comment
  above the next member, so a module's count can be off by a few lines.
  Two entries it mislabelled were corrected by hand (modifiers shown as
  methods). The totals add up to the class's 6,960 lines.
- The per-cell cost in 4.3 is an argument, not a measurement. Stage 2 has
  the measurement.
- `V03-RESULTS.md` was only searched for the baseline numbers, not read.
- The docs: one grep of `packages/sheet/README.md` and `docs/**` for
  calls on a sheet instance found only block-API calls
  (`sheet.showField` on the yielded block value). They were not read.
- The v0.4 feature files (`01-fit-width.md` to `09-visible-range.md`)
  were not read, only the README.

## 9. For the user to decide

Rule conflicts, each with the smallest exception:

1. **"No public API change" against the exported class.** `EuiSheet` is
   exported, and its about 440 members are public in its `.d.ts`. After
   the split most of them are on modules, so the class's declared shape
   changes. No app can get an instance (there is no ref API; `SheetApi`
   is the API), the members are not documented, and `src/types.ts` and
   `src/index.ts` do not change. Proposed exception: the instance members
   of the class are internal and may move. The alternative is the facade
   of 4.2 for all of them, which defeats the split.
2. **"Nothing new per cell" against any split at all.** A cell's reads go
   through one more plain property load each (4.3). Proposed: accept it;
   stage 2 measures the call count. The alternative is to keep the about
   25 per-cell members on the component.
3. **"The component keeps only args, wiring and the template."** It also
   keeps 12 small derived getters (`messages`, `context`, `types`,
   `colOffset`, `canInsert`, ...; 3.1). Proposed: accept; a `core`-style
   module only for them would be a thirty-fourth file that every other
   module reads.

Open questions:

4. **Cells call modules directly** (this design), or through a facade on
   the component (4.2)? Direct edits 14 `-private` files, paths only.
5. **File names.** In `src/-private/sheet/`, seven basenames exist
   elsewhere in the package: `fields.ts`, `rows.ts`, `history.ts`,
   `types.ts` (in `core/`), `row-menu`, `field-editor` (as `.gts` in
   `-private/`), and `cells` (a directory). The directory tells them
   apart. If that is not enough, a prefix (`sheet-rows.ts`) fixes it.
   The directory name `sheet/` is also a proposal.
6. **The test count.** The brief says 527; `test(` occurs 532 times in
   `tests/`. Stage 0 takes the runner's number as the baseline.
7. **The header menu's filter item** stays inside `columns` (rule 8). Is
   that fine until v0.4, or should 3c allow this one 9-line restructure so
   `header-menu.ts` holds every item?
8. **33 modules.** Some are small (`api.ts` 70 lines, `validate.ts` 95,
   `touch.ts` 100). They follow "each feature in its own small module".
   If fewer, larger files are preferred, the natural merges are `touch`
   into `drag`, `uploads` into `resolve`, and `outline` into `selection`.
