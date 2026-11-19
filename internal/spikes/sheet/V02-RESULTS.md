# `@ember-eui/sheet` v0.2: results

Results of the batches of `V02-DESIGN.md`, on branch `feat/sheet`. Each
section says what was built, what was verified (and how), and what was not.

## Batch 1: foundations

Built 2026-11-19 on `7f02013a` (uncommitted when this was written). Scope:
theme tokens, quoted TSV, change set v2, `colOffset` and add-row plumbing
(no add row yet), `pendingFocus`, `SheetApi` (`undo`, `redo`, `focusCell`,
`remapIds`, `clearHistory`). Nothing of batch 2 was started.

### What was built (files, under `packages/sheet/`)

| File | Change |
| --- | --- |
| `src/core/tsv.ts` | Rewritten: quoted cells as Excel and Google Sheets write them (4.2). |
| `src/core/types.ts` | `RecordInsert.anchor`, `RecordInsert.restore`, new `RecordRemoval`, `ChangeSet.removed`, four new `source` values (C1). |
| `src/core/change-set.ts` | `applyChangeSet` positions inserts by anchor, then index, and restores (`restoreRecord` option) (C2); `pasteMatrix` anchors its inserts; new `insertRecords`, `deleteRecords`, `duplicateRecords`. |
| `src/core/history.ts` | `invertChangeSet(set, fieldIds?)` turns `removed` into positioned restores; `withoutConflicts` keeps a re-insert's position (C3) and takes `equals`; `undoChangeSet`/`redoChangeSet` take `options` (`fieldIds`, `equals`); redo carries `deletes` and `removed`; new `mergeChangeSets`. Types `ValueEquals`, `HistoryOptions`. |
| `src/-private/theme.ts` (new) | `sheetThemeVars`: the 14 `--euiSheet-*` custom properties from `euiTheme.colors` (4.3). |
| `src/-private/styles.ts` | Every fixed colour is `var(--euiSheet-x, <v0.1 value>)`; the editor input now has a background and a text colour (it had none). |
| `src/-private/remap.ts` (new) | `remapChangeSet`, `toIdMap`, `composeIdMaps`, `remapId` for `remapIds` (plain TypeScript, not exported). |
| `src/components/eui-sheet.gts` | Theme class on the wrapper and passed to editors as `@themeClass`; `colOffset` (0), `hasAddRow` (false), `rowCount`, `recordAt`, `focusGridCell`; `SheetApi` and `@registerApi`; following `@records` (3.2): own-change detection, `followRecords`, `pendingFocus`; the editor (`Editing`, now a class with tracked `pos`/`rect`/`placement`) finds its record by id; history records delete-only sets and merges a `'resolve'` into the last entry; `emit` drops a deleted record's rejections. The grid's API field is renamed `gridApi`/`registerGridApi` (it clashed with the new `SheetApi`). |
| `src/-private/sheet-cell.gts` | Subtracts `colOffset` from the grid's column index. |
| `src/-private/editors/date-editor.gts` | Passes `@themeClass` to the text editor it wraps. |
| `src/types.ts` | `SheetApi`, `EuiSheetSignature.Args.registerApi`, `SheetEditorSignature.Args.themeClass?`. |
| `src/index.ts` | Exports the `SheetApi` type (the core functions come through `export *`). |
| `src/local-records.ts` | Option `restoreRecord`, passed to `applyChangeSet`. |
| `tests/helpers/sheet.ts` | `COL_OFFSET` (0); `cell(row, col, root?)` adds it; `selected()` subtracts it. |
| Tests | See below. |
| `docs/sheet.md`, `README.md`, `docs/sheet-demo/d01-basics.md`, `d06-date-picker.md`, new `d09-own-store.md` | See "Docs". |

### API changes

Additive: `EuiSheetSignature.Args.registerApi`; type `SheetApi`; core
`insertRecords`, `deleteRecords`, `duplicateRecords`, `mergeChangeSets`,
`RecordRemoval`, `ValueEquals`, `HistoryOptions`; `RecordInsert.anchor`,
`RecordInsert.restore`, `ChangeSet.removed`; optional parameters
`invertChangeSet(set, fieldIds?)`, `undoChangeSet(…, options?)`,
`redoChangeSet(…, options?)`, `withoutConflicts(…, { equals })`;
`applyChangeSet` option `restoreRecord`; `LocalRecordsOptions.restoreRecord`;
`SheetEditorSignature.Args.themeClass` (optional, see deviations).

Not purely additive, as the design lists them: C1 (new `source` values),
C2 (`applyChangeSet` honours `anchor`/`index`), C3 (a re-insert keeps its
position), C4 (quoted TSV), C12 (needs `@ember-eui/core/theming`), and C14
(the selection, focus and an open editor follow their record when the owner
replaces `@records`). Also: pasted inserts now carry `anchor` (3.4), so a
`deepEqual` on a paste's inserts sees one more key.

### Verification items (section 12)

| # | Item | Outcome |
| --- | --- | --- |
| N1 | `@ember-eui/core/theming` in the lowest core the peer allows (`^16.0.0`). | Seen in git only: `packages/core/src/theming.ts` exports `getEuiThemeContext`, `euiClass`, `useEuiBorealisStyles` and the type `EuiThemeStyleContext` at the `@ember-eui/core@16.0.0` tag and at the version bump commit `52e1af5d` ("bump v16.0.0"); `5087be1e` (which added the entry) is an ancestor of it. Oddity: the tag's `package.json` says `15.0.0` (the tag was made before the bump commit). The published npm tarball was not inspected (no network used for it). Core's `exports` has `"./*"` → `dist/*.js`, which serves `./theming`. The peer range was not changed. |
| N2 | The provider's component name and its colour-mode argument. | `EuiEmotionProvider` (`@ember-eui/core/components/eui-emotion-provider`, also in `@ember-eui/core/components`), `@colorMode="light" \| "dark"`; a root provider also has `@globalStyles`. Read from `eui-emotion-provider.gts`. **But** in the sheet's test app a provider is not seen by `getContext`: the strict resolver does not run `ember-provide-consume-context`'s `glimmer-overrides` initializer, which core's own test helper registers by hand (`packages/core/tests/test-helper.ts:49-53`), and the sheet does not depend on that package. A first TH2 with a dark provider got the light class on both sheets (log `b1-run3.log`). TH2 now switches the `eui-emotion` service's `colorMode` (tracked) instead, which also shows the class follows a mode change. The provider path is used by the d01 demo: to check on the docs site. |
| N14 | No performance number was measured. | For 4.9's "10,000 ids under 2 ms": the per-change id work of `recordsRendered` (map to ids, compare, own-change check), as a copy in node 10,000 records: 0.11 ms (same ids), 0.61 ms (own paste of 2 rows), 0.09 ms (reversed) per change (`b1-perf.mjs`, `b1-perf.log`). Not measured in the browser or in d08. |

### Tests

Baseline at HEAD in the scratch copy: 113/113 (`b1-baseline.log`). After
the plumbing and the core, before new tests: 113/113 (`b1-run1.log`).
Final: **149/149**, 0 failed (`b1-final2.log`, 06:45 UTC; an earlier
147/147 in `b1-final.log` before T25 and TH5 were added). Logs are in the session scratchpad
(`/tmp/claude-1000/-Users-betocantu93-prysmex/df04f7e2-a347-4eab-a276-4d9974f4dbc1/scratchpad/`).

New (36): `tests/unit/tsv-test.ts` Q1–Q8; `tests/unit/change-set-test.ts`
S1, S2, S2b, S3–S8; `tests/unit/history-test.ts` H6–H10;
`tests/integration/components/eui-sheet-theme-test.gts` (new) TH1–TH4, and
TH5 (a `--euiSheet-*` property set on the sheet element overrides the
theme; set on a parent it does not, as the docs say);
`tests/integration/components/eui-sheet-test.gts`, new module "v0.2
foundations", T17–T24, and T25 (an insert-only redo focuses the
re-inserted row: the `pendingFocus` path).

Not executed by any test, because batch 1 has no UI that emits them: a
delete-only history entry and its undo (restores) through the sheet, and
the `'resolve'` merge. They are covered by the core unit tests only
(S3, S5, S8, H6–H8).

Changed on purpose (each assertion made exact, none loosened):

- **U6, U13** (`change-set-test.ts`): their `deepEqual` of a paste's
  inserts now includes `anchor` (after the last record, then after the
  previous insert), as 3.4 specifies for `pasteMatrix`.
- **H4** (`history-test.ts`): a re-insert without an anchor keeps its index,
  clamped (`Math.min(1, 2) = 1`), instead of going to the end (`2`): C3.

Design inconsistency: 4.6 says the 113 tests pass unchanged except maybe
`tsv-test.ts` U2. U2 passes unchanged; U6, U13 and H4 had to change,
because 3.4 (anchored paste inserts) and C3 change exactly what they assert.

Test notes:

- TH1 first asserted the focus ring colour; the computed `outline-color` of
  a focused cell is `rgb(0, 0, 0)`: the grid's own cell styles set
  `outline: none` on `:focus-visible` and draw their own ring (an `::after`
  border, `styles.generated/shared/VRGXM52Z.ts`), so the sheet's `:focus`
  outline rule is not what shows. Pre-existing (v0.1 had the same rule), not
  changed; TH1 checks the checked checkbox's background instead.
- T17 first focused the paste target with `focus()` after a Shift+Arrow,
  which extended the range (`extending` stays set after a Shift+arrow
  keydown until the next key or press): a test artefact, fixed with a click.
- T19 uses the `pressed()` helper (`triggerKeyEvent` refuses lower-case
  `z`).

Lint (`pnpm lint`: `ember-tsc --noEmit`, ESLint, stylelint): exit 0
(`b1-lint-final2.log`). Prettier `--check src tests/integration tests/unit
tests/helpers/sheet.ts README.md`: clean (`b1-prettier-final2.log`). `tests/helpers/index.js`
is not Prettier-clean at HEAD and was not touched.

### Deviations from the design

1. **pnpm store**: the install used the sandbox's existing store
   (`~/.local/share/pnpm/store`) instead of a new `scratchpad/pnpm-store`,
   to save disk (3.2 GB free, a fresh store would have downloaded the whole
   tree). `pnpm install --frozen-lockfile` passed; no dependency changed.
2. **`SheetEditorSignature.Args.themeClass` is optional** (`themeClass?:
   string`), not `string`: a required argument breaks the type check of
   every app that renders `SheetInputEditor` itself (the d06 demo, the
   README's flatpickr example, `eui-sheet-custom-type-test.gts`). The sheet
   always passes it; d06 and the README now pass it on.
3. **TSV round trip contract** (4.2): `parseTsv(toTsv(m))` equals `m` for
   matrices with at least one cell per row, whose last row is not `['']`,
   and with no `\r\n` inside a cell: 4.2 also says `\r\n` inside a quoted
   cell becomes `\n` (Q5), so such a cell cannot round-trip. A lone `\r` is
   quoted and round-trips.
4. **`remapIds`** rewrites the history, rejections, `pendingFocus`, the
   editor's record id, the last `@records` ids and the pending own-change
   deletes at once (3.6, "rewritten"), and also keeps the composed map and
   applies it to every later history entry (4.4, "a Map consulted"); both
   texts hold. The helpers are in `src/-private/remap.ts`, not exported, to
   keep the public API as 4.5 lists it.
5. **Restore `values`** (`invertChangeSet`): fields whose value is
   `undefined` are left out. `duplicateRecords` does the same.
6. **Own-change test** (4.4): the new ids must keep the old ids minus the
   pending deletes as an ordered subsequence, with *at most* (not exactly)
   as many new ids as pending inserts, so an owner that drops an insert is
   still "own". Pending inserts/deletes accumulate over the emits since the
   last `@records` change.
7. **Focus after an outside change**: "a data cell had DOM focus" also
   counts a cell whose focus was lost to nowhere in the same run loop
   (`focusDropped`, set on a focusout with no `relatedTarget`, cleared with
   `next()`): when the owner drops the focused row, the render removes the
   cell before the sheet's after-render step runs (T21 failed without it,
   `b1-run3.log`). When the edited record is gone and the editor had focus,
   the head cell is focused too (T23).
8. **`withoutConflicts` re-insert indexes** are computed by placing the kept
   inserts in ascending order over the current ids, as `applyChangeSet`
   does, so chained inserts (a paste) get consecutive indexes after their
   anchor, and an index counts inserts placed before it (H8).
9. **`'resolve'`** merges into the *last* undo entry (no link to "the paste
   that asked for it" exists yet); nothing emits `'resolve'` in batch 1.
10. **Undo `equals`**: no field type has an `equals` yet, so the sheet
    passes only `fieldIds` (`@fields`); batch 5 adds `equals` from types.
11. **TH2 does not use a dark `EuiEmotionProvider`** (4.7 asks for one): the
    sheet's test app does not run `ember-provide-consume-context`'s
    initializer, so a provider is not seen there (N2). TH2 switches the
    `eui-emotion` service's `colorMode`. The provider path, which d01 and
    real apps use, has no automated test: the docs-site check of d01's Dark
    switch is its only verification.
12. The docs' new "Theme" section lists all 14 properties; `subdued`,
    `border` and `highlight` are defined but not used by any style yet.

### Docs

- `docs/sheet.md`: change set block (new sources, `anchor`, `restore`,
  `removed`), where an insert goes (`index`, `anchor`, `restore`,
  `restoreRecord`), `remapIds` in "Undo and redo", `@registerApi` argument,
  new sections "The sheet's API" (including C14) and "Theme"; "Not yet"
  loses quoted cells and dark colours.
- `README.md`: the same, plus `@themeClass` in the editor row and in the
  flatpickr example; "Limits (v0.1)" became "Limits".
- `d01-basics`: a Dark switch wraps the sheet in `EuiEmotionProvider
  @colorMode`; text on multi-line cells.
- `d06-date-picker`: passes `@themeClass` to `SheetInputEditor`.
- New `d09-own-store`: a store on `applyChangeSet` whose "server" renames
  inserted rows after 300 ms (`remapIds` first, then the new records),
  buttons for `undo`, `redo`, `focusCell`, `clearHistory`, and an event log.

### Docs site build

In the scratch copy: `build:js` of sheet, flatpickr, pikaday,
changeset-form and validated-form (core was built first), then in `site`
`pnpm clean:docfy && node ../scripts/generate-llms-txt.mjs && pnpm exec
vite build --mode production`: exit 0 (`b1-site.log`,
`b1-site-summary.log`; rebuilt after a docs wording fix: `b1-site2.log`);
the d09 chunk
(`docfy-demo-docs-sheet-d09-own-store-*.js`) is in `site/dist/assets`. The
log has docfy's `getRepoEditUrl` TypeError (edit URLs; the scratch copy has
no `.git`), which earlier site builds in this scratchpad show too. The demos
were built, not run: `site/dist` is left in the scratch copy.

### For the orchestrator to check with real input (docs site)

- d01: the Dark switch: selection, hover, focused-cell errors, the editor
  input (not white) and checkboxes in dark; switching back.
- d01: copy a cell with a line break from Excel/Sheets (or type one), paste
  it into the sheet and back out: one cell, quoted on the clipboard.
- d09: paste three lines on the last row, wait for the `srv-…` ids, Ctrl/Cmd+Z
  removes them, Ctrl/Cmd+Shift+Z re-inserts them (new ids again); the
  buttons work with focus outside the grid.
- Any sheet: re-sorting `@records` from outside is not in a demo (only
  T20–T24 cover it).

### Open issues for later batches

- The sheet's `:focus` outline is hidden by the grid's own focus ring (see
  TH1 note); batch 3's frozen cells and batch 2's row-number column should
  check which ring shows.
- The test app cannot use `EuiEmotionProvider` (no context initializer);
  batch 2's flyout/modal tests may need theme or context from a provider:
  register `ember-provide-consume-context`'s initializer in
  `tests/test-helper.ts` (needs it as a devDependency, a lockfile change)
  or keep using the service.
- `'resolve'` must find the entry of the paste that asked for it (batch 5);
  `equals` from field types (batch 5); `fieldIds` should include
  `@hiddenFields` (batch 3).
- `pendingFocus` is applied only after a render with a new `@records` (or
  right after an undo that only inserts); batch 2's inserts can reuse it.
- `extending` stays set after a Shift+arrow keydown until the next key or
  press (pre-existing), so a programmatic focus after it extends the range.

### Batch 1: real input in Chromium (orchestrator, 2026-11-19)

Production docs build, Playwright keyboard and mouse:
- d01 Dark switch: the grid, the selected invalid cell's border, the editor
  input and the checkboxes follow the dark theme (screenshot
  `v02-b1-dark.png`); the focused error box shows "Required"; switching off
  restores light.
- d01 multi-line paste: a quoted two-line cell copied from a textarea pastes
  into one cell, the next field gets "Lima", the next row is untouched;
  copying the two cells back gives `"line one\nline two"\tLima` (quoted).
- d09: pasting three lines on the last row's Item: `srv-3` becomes "Vest" and
  two rows appear as `new-1`, `new-2`, then `srv-101`, `srv-102` after the fake
  save; Ctrl/Cmd+Z removes both rows and restores "Goggles"; Ctrl/Cmd+Shift+Z
  re-inserts them (new server ids); the Undo and Redo buttons do the same;
  "Focus last row" focuses the last row's Item cell; after "Clear history",
  Undo does nothing.

## Batch 2: records

Built 2026-11-19 on `f21fac39` (uncommitted when this was written). Scope as
`V02-DESIGN.md` 5: the row-number column (`@rowLabel`, `@rowNumberOffset`),
whole-row and whole-column selection, checkboxes, the add row, Shift+Enter,
the row menu (insert above/below, duplicate, expand, copy, `@rowActions`,
delete), the expanded record in a flyout (default) or a modal with one
shared form. Plus the coordinator's fix "Undo/redo and rejected paste cells"
(below). Nothing of batch 3 was started.

### What was built (files, under `packages/sheet/`)

| File | Change |
| --- | --- |
| `src/components/eui-sheet.gts` | Control column (`leadingControlColumns`, `<:controlHeaderCell>`/`<:controlCell>` blocks), `colOffset` 1, add row (`hasAddRow`, `gridStyle.rowClasses`), `rangeKind`, row/column selection and row drag, checked rows (controlled or local), keys of data, row-number, header and add-row cells, the row menu, insert/delete/duplicate/copy rows, the expanded record (state, shells, form commits), `cellViewFor`, `@hiddenFields`, new `SheetApi` methods, the rejection history. |
| `src/-private/row-number-cell.gts` (new) | `RowNumberCell` (label, checkbox span, expand span; "+" on the add row; `aria-label`, `aria-selected`, classes through `setCellProps`) and `RowNumberHeader` (the "all" checkbox span). Spans only. |
| `src/-private/row-menu.gts` (new) | `EuiPanel` + `EuiContextMenuPanel @hasFocus` + `EuiContextMenuItem`s, absolutely placed in the wrapper. |
| `src/-private/record-form.gts`, `record-form-field.gts` (new) | The form: fields then hidden fields, a box per field (`role="button"` when editable), one inline editor at a time, its keys, its draft. |
| `src/-private/record-shells.gts` (new) | `RecordFlyout` (`EuiFlyout`) and `RecordModal` (`EuiModal`): title, previous/next, the shell's own close button, the form. |
| `src/-private/rejections.ts` (new) | `Rejection` type, `clearRejections`, `restoreRejections`, `remapRejections` (plain TypeScript, not exported). |
| `src/-private/editor-frame.gts` | `@layout="inline"` (no position style; `rect`, `placement` optional). |
| `src/-private/sheet-cell.gts` | The add row's first cell shows "+ Add record". |
| `src/-private/styles.ts` | Row-number column, add row, menu, form; every colour through `--euiSheet-*` with a fallback (TH3 still passes). |
| `src/core/messages.ts` | 17 messages (below). |
| `src/types.ts`, `src/index.ts` | New args, `SheetApi.expandRecord/insertRecord/deleteRecords`, `SheetRowAction` (exported). |
| `tests/helpers/sheet.ts` | `COL_OFFSET = 1`. |
| Tests, docs | Below. |

### API changes

Additive: args `@hiddenFields`, `@rowNumbers`, `@rowLabel`, `@rowNumberOffset`,
`@canInsert`, `@canDelete`, `@newRecordValues`, `@checkedRecordIds` +
`@onCheckedChange`, `@expandedRecordId` + `@onExpandedRecordChange`,
`@expandedRecord`, `@rowActions`; `SheetApi.expandRecord(id | null)`,
`insertRecord({ anchor?, values? })`, `deleteRecords(ids)`; type
`SheetRowAction`; messages (tokens `euiSheet.*`) `addRecord`, `insertAbove`,
`insertBelow`, `duplicateRecord`, `duplicateRecords(count)`, `expandRecord`,
`copyRow`, `copyRows(count)`, `deleteRecord`, `deleteRecords(count)`,
`selectRow`, `selectAllRows`, `rowNumber(n)`, `recordTitle(n)`,
`previousRecord`, `nextRecord`, `close`.

Not purely additive, as the design lists them: C8 (row-number column on by
default; data cells' grid column index +1), C9 (Space on a data cell
expands the record, also on a read-only sheet), C10 (Shift+Enter inserts
below), C13 (ArrowLeft from the first field reaches the row number, which
has no range; the sheet handles Home and Ctrl+Home). Also: the add row is on
by default (`@canInsert` defaults to `!@readOnly`), so the grid has one more
row (`aria-rowcount` + 1, Ctrl+End and ArrowDown reach it); a rejection is
now an undo entry (below).

### Undo/redo and rejected paste cells (coordinator's fix)

The bug as reported was confirmed in the code at `f21fac39`: `applyHistory`
passed only the inverse patches' cells as `touched`, `recordHistory` dropped
a change set with only rejections, and redo emitted `rejected: []`
(PACKAGE-RESULTS 16, E2). Now:

- An undo entry is `{ changeSet, rejections }`: the rejections `emit` stored
  for that change set, each with the value the cell had then (`seenValue`).
  An entry is recorded when the change set has patches, inserts, deletes
  **or** rejections (still not for `undo`/`redo`).
- Undo clears the entry's rejections that are still shown, matched by cell,
  text and message (`clearRejections`). Not by identity: `remapIds` and redo
  re-create the objects, and a rejection with the same cell, text and
  message is the same thing to the user. A different rejection on that cell
  is kept.
- Redo emits patches/inserts/deletes as before and then, after `emit` (the
  owner may have put back the rows), restores each rejection whose record
  exists and still holds `seenValue` (`restoreRejections`). A rejection whose
  record is gone is skipped.
- An entry with only rejections emits no change set; the rejection display
  changes, the entry moves between the stacks and those cells are selected
  and focused (`selectChanged` takes extra cells).
- `remapIds` rewrites the entries' rejection ids too (`remapRejections`), and
  `recordHistory` applies the composed map to new entries' rejections. The
  owner still never receives rejections from undo/redo (U1's exact change
  sets unchanged): this supersedes PACKAGE-RESULTS E2 only for the sheet's
  own display.
- Limits: (1) redo restores rejections on re-inserted (`tempId`) rows only
  when the owner applies the redo synchronously (`localRecords`,
  `applyChangeSet` in `@onChange`); an async owner's rows are not there yet,
  so those rejections are skipped. (2) Undoing a later rejection on a cell
  does not bring back an earlier rejection on that cell; the cell shows its
  value. (3) "A rejection made after the paste on the same cell survives
  undoing the paste" cannot be reached from the UI: every rejection is now
  its own, later entry, so it is always undone first. The guard is covered by
  unit test RJ1; integration test U13 runs the nearest sequence (paste, a
  later rejection on the same cell, undo, undo, redo, redo).

### Verification items (section 12)

| # | Item | Outcome |
| --- | --- | --- |
| N3 | `EuiFlyout`/`EuiModal` focus traps with editors that focus on mount and with wormholed editor surfaces; `EuiModal`'s arguments. | Spike in the test app (scratch only, deleted; `b2-spike.log`, `b2-spike2.log`): both render under the strict resolver without a provider, are portaled to `body`, focus themselves on open, Escape closes them (flyout: a `window` keydown; modal: a keydown on its element) unless an inner handler stops it, and the flyout's trap returns focus to the opener. Editors that focus on mount work inside (RF2, RF3, RF14). **A surface rendered outside the shell did not get focus**: both traps pulled focus back to the editor's input (RF16, first run `b2-run4.log`). Fixed without changing core: while a form editor is open the modal's trap is paused (`@isFocusTrapPaused`) and the flyout's is deactivated (`@isFocusTrapActive`), with `focusTrapOptions` `returnFocusOnDeactivate: false` and an `initialFocus` that keeps the element that has focus, so resuming does not steal it. RF16 passes for both shells. `EuiModal` arguments used: `@onClose`, `@closeButtonAriaLabel`, `@initialFocus`, `@isFocusTrapPaused`. Not checked with flatpickr itself (no flatpickr in the sheet's tests): d06 on the docs site is the real check. |
| N4 | `EuiContextMenuPanel`/`Item` arguments; focus on open. | `@hasFocus={{true}} @initialFocusedItemIndex={{0}}` focuses the first item; ArrowDown moves (the spike pressed ArrowDown only, not ArrowUp); the panel does not handle Escape (spike, RW7), so the sheet does. `EuiContextMenuItem` takes `@icon`, `@color`, `@disabled` (native `disabled`, RW12), `@size`, and `{{on "click"}}` through `...attributes`. |
| N5 | The header content class; the "Sort" labels. | `euiDataGridHeaderCell__content` read in `header-cell.gts` (`contentClass`). Clicking it does not open the column actions; the actions button still does (RW3). The sort-label half is batch 3. |
| N12 | No tabbable element in the new cells. | RW13: no `a[href], button, input, select, textarea, [contenteditable], [tabindex]` (other than `tabindex="-1"`) inside any row-number cell (header, records, add row), and no `aria-describedby` (the grid's focus-trap hint, set only for cells with interactive children). Checked with that selector, not with `tabbable()` (not a dependency of the sheet). |
| N14 | Performance. | Nothing measured for batch 2. `rowColumnWidth` calls `@rowLabel` for every record on each `@records` change (only with `@rowLabel`). |

### Tests

Baseline before batch 2: 149/149 at HEAD (batch 1's `b1-final2.log`). After the
rejection fix alone: 156/156 (`b2-rej1.log`). After the batch with the
existing tests: 154/156 (`b2-run1.log`: T6, N20, both behaviour changes on
purpose). Final: **195/195**, 0 failed (`b2-final2.log`, 07:45 UTC, after the
last source edit; `b2-final.log` at 07:35 was the same count before three
tests were extended and the menu's `contextmenu` guard was added). The tests
ran against batch 1's core build in the scratch copy (core is unchanged;
it was rebuilt only for the site). Logs are in the session scratchpad
(`/tmp/claude-1000/-Users-betocantu93-prysmex/df04f7e2-a347-4eab-a276-4d9974f4dbc1/scratchpad/`).

New (46):

- `tests/integration/components/eui-sheet-rows-test.gts` (new, 19): RW1–RW15
  as in 5.9, plus RW4 "controlled", RW10 "`@canInsert={{false}}`: a paste
  only fills the rows that exist", RW16 (the API: `insertRecord`,
  `deleteRecords`, `expandRecord`), RW17 (copy rows: `navigator.clipboard`
  stubbed; then `writeText` rejects and the textarea + `execCommand('copy')`
  fallback runs, with `execCommand` replaced by a spy). RW3 also covers Delete
  on a selected column's header; RW5 checks that exactly one add row remains
  after an insert; RW7 also picks "Expand record" and checks focus returns
  to the cell on close.
- `tests/integration/components/eui-sheet-record-test.gts` (new, 17): RF1–RF14
  as in 5.9, RF15 (expand icon, Enter on a row number), RF16 × 2 (N3: an
  editor surface outside the flyout / the modal). RF3 also covers Tab and
  Shift+Tab out of the select editor; RF4 also Delete on a box.

Not executed by any test: a date editor inside the form; Escape or a click
outside the menu while an editor was open; the menu's `contextmenu` guard
(the ContextMenu key's own event once focus is in the menu); the form's
deferred save when the shell is closed programmatically with an editor
open; `@rowLabel`'s width on 10,000 records; d10 and d11 at runtime (built,
not run).
- `eui-sheet-history-test.gts`: U9, U10 (5.9); U11–U14 (the rejection fix:
  mixed paste, all-rejected paste plus an owner change before redo, the
  nearest "later rejection" sequence, rejected cells on inserted rows); U15
  (`remapIds` with a rejected cell on an inserted row, undo, redo).
- `tests/unit/rejections-test.ts` (new, 3): RJ1 the guard, RJ2 restore needs
  the record and its old value, RJ3 remap.

Changed on purpose (each still exact):

- **U4** (`eui-sheet-history-test.gts`): "a rejection is not history" became
  "a rejection is its own entry": the first Ctrl+Z clears the rejected text
  and emits nothing, the second undoes B (the coordinator's fix).
- **U8**: its last part pasted `5`, then `abc` (rejected), and expected one
  undo to restore `0`; now the first undo removes the rejection (shows `5`),
  the second restores `0` (the coordinator's fix).
- **T6** (`eui-sheet-test.gts`): `aria-rowcount` 6 → 7 (the add row).
- **N9** (`eui-sheet-types-test.gts`): "Space on a text cell does nothing" →
  it expands the record (C9), still no editor and no change set.
- **N20**: its Space on a read-only checkbox now opens the expanded record
  (C9); the test asserts it has no editable boxes and closes it with Escape
  before going on (the open flyout's focus trap took the later copy event).
- **T13** and **N21**: they used grid column indexes 0 and 3, which are now
  the row-number header and another field (C8): they passed for the wrong
  reason. Both now add `COL_OFFSET`.

Lint (`pnpm lint`: `ember-tsc --noEmit`, ESLint, stylelint): exit 0
(`b2-lint-final2.log`). Prettier `--check src tests/integration tests/unit
tests/helpers/sheet.ts README.md`: clean (`b2-prettier-final2.log`;
`tests/helpers/index.js` is still not Prettier-clean at HEAD and was not
touched). Docs Markdown is not Prettier-formatted here.

### Deviations from the design

1. **`@hiddenFields` in batch 2**, as a read-only input: 5.7 (the form lists
   them), 5.6 (duplicate) and the undo `fieldIds` need it; its handler
   (`onHiddenFieldsChange`) and the toolbar stay in batch 3.
2. **Messages**: three more than 5.2 lists, for singular labels:
   `duplicateRecords(count)`, `copyRow`, `deleteRecord`; `copyRows` takes the
   count. The messages have no plurals.
3. **Files**: both shells are in `record-shells.gts` (5.3 lists
   `record-flyout.gts` and `record-modal.gts`); they share a base class.
4. **Editor frame**: the form reuses `EditorFrame` itself with
   `@layout="inline"` instead of extracting its focus-out logic into a
   class; the logic is shared either way.
5. **`@rowLabel` width** is computed over all records, not the rendered rows
   (the sheet does not know the grid's window; also no width jumps on scroll).
6. **Menu**: a click outside closes it without re-focusing the cell (the
   click's own target takes focus); Escape and the items that do not move
   focus (copy, `@rowActions`) re-focus it. Tab in the menu closes it too.
   Insert above/below act on the row the menu was opened on, also with
   several rows selected. Shift+F10 on a row number with nothing selected
   selects that row first.
7. **Shift+Enter without `@canInsert`** opens the editor, as Enter (v0.1).
8. **The API** (`insertRecord`, `deleteRecords`) does not check `@canInsert`
   and `@canDelete` (the owner calls it on purpose) and does not move focus.
9. **Paste without `@canInsert`** stops at the last record (5.8: "the sheet
   only edits cells").
10. **Focus traps** of the shells are paused (modal) or off (flyout) while a
    form editor is open (N3); meanwhile Tab can leave the shell. The flyout
    does not return focus itself (`returnFocusOnDeactivate: false`): the
    sheet focuses the cell it was opened from; opened by the API with focus
    elsewhere, focus is not returned.
11. **Right-click inside a range** keeps the range while focus moves to the
    clicked cell (so `head` may not be where DOM focus is until the next
    key).
12. **Not done**: a selected look for the headers of a column range;
    Ctrl+End still goes to the add row's last cell (the grid's key); copy on
    the add row puts an empty text on the clipboard.
13. **Form keys**: Space on a box without a `navKey` does nothing (a
    `role="button"` would click); Tab from a select editor (its own key)
    goes to the next box, Shift+Tab to the previous one.
14. **Open questions** used the design's defaults: Q13 (no delete shortcut
    for rows: Delete and Backspace clear cells) and Q6 (undo of a delete is
    always offered; `restore` and `remapIds` documented).
15. **Closing** the shell refocuses the cell only when it is really closed
    (a controlled owner that keeps it open keeps focus in it). An editor
    open when the shell is closed programmatically saves its draft after the
    teardown.

### Docs

- `docs/sheet.md`: change-set sources, new sections "Records" and "Expanded
  record", the arguments and API tables, the keyboard table (Space,
  Shift+Enter, Shift+F10, Home) and the row-number/add-row keys, the theme
  note (shells), undo of rejected texts and of inserts/deletes, "Not yet"
  without row numbers and row buttons.
- `README.md`: the same, shorter; "Limits" and the message token list
  updated. `d07-translations` gets Spanish texts for the 17 new messages.
- New demos `d10-records.md` (add, delete, duplicate, the menu, a
  `@rowActions` item "Mark done", `@newRecordValues`, the "Ids as row labels"
  `@rowLabel` switch, controlled checkboxes, the change-set log) and
  `d11-expanded-record.md` (flyout/modal switch, two hidden fields, one
  read-only). d01–d06, d08 and d09 were not changed; with the defaults they
  should now show the row-number column and the add row (inferred from the
  code, not seen).

### Docs site build

In the scratch copy: `build:js` of core, sheet, flatpickr, pikaday,
changeset-form and validated-form, then in `site` `pnpm clean:docfy && node
../scripts/generate-llms-txt.mjs && pnpm exec vite build --mode production`:
exit 0 (`b2-site2.log`, `b2-site2-summary.log`, 07:46 UTC, after the last
source and docs edit; a first build at 07:37 is `b2-site.log`). The d11 demo
has its own chunk (`docfy-demo-docs-sheet-d11-expanded-record-*.js`); d10's
text "Ids as row labels" is found in that chunk and in the sheet route's
chunk (`-embroider-route-entrypoint.js_route_docs.sheet.docs.sheet-*.js`). The log
has the same seven docfy `getRepoEditUrl` TypeErrors as batch 1 (no `.git` in
the scratch copy). The demos were built, not run; `site/dist` is left in the
scratch copy.

### For the orchestrator to check with real input (docs site, Sheet page)

- **d10 Records**: hover a row (checkbox and expand icon appear); click row
  number 2, Shift+click 4 (three rows highlighted, numbers too); Delete
  clears them; Ctrl/Cmd+Z. Drag from number 1 to 5. Ctrl/Cmd+C with that row
  selection, paste into a text editor (TSV). Click the "City" title
  (column selected), Ctrl/Cmd+C, paste outside; the title's ⋯ button still
  opens its menu. Click the "Add record" row: a record appears with the
  previous row's city, focus on its Name. Shift+Enter on a cell: a record
  below. Right-click a cell inside a multi-cell selection (the selection
  must stay), and outside it (it moves); Shift+F10; in the menu ArrowDown,
  Enter, Escape (focus back on the cell). Check two rows, right-click:
  "Duplicate 2 records", "Mark done", "Delete 2 records"; delete them and
  Ctrl/Cmd+Z (same rows back in place). Switch "Ids as row labels".
- **d11 Expanded record**: Space on a cell opens the flyout; Notes and
  Created by (read-only) are listed; click Hours, type `abc`, Enter (error
  under the box and in the grid), Ctrl/Cmd+Z in the flyout; Status: Enter,
  ArrowDown, Enter; Due: the browser's date input; Urgent: click and Space;
  previous/next arrows; Escape on a box closes and focus returns to the
  cell. Switch "In a modal" and repeat.
- **d06 Date picker** (flatpickr; its calendar is marked
  `euiSheetEditorSurface`): Space on a row to open the flyout, open the date
  field's editor there and pick a day in the flatpickr calendar (N3 with the
  real wormholed surface; only a test surface was checked).
- Open the row menu on the last visible row and the last column: it is
  placed at the pointer with no flip, so it may be cut off or hang out of the
  sheet.
- **d01 Basics** with the Dark switch: the row-number column, the add row,
  the menu and the flyout in dark.
- Which focus ring shows on a focused row-number cell (batch 1's TH1 note:
  the grid draws its own).
- A rejected paste (`abc` into Hours in d01 or d10) then Ctrl/Cmd+Z and
  Ctrl/Cmd+Shift+Z (the red text goes and comes back).

### Notes for later batches

- Batch 3: `@onHiddenFieldsChange` and the toolbar's field picker build on
  `@hiddenFields` (already listed in the form, duplicated, restored);
  `historyOptions.fieldIds` already includes hidden fields. A column range
  has no header highlight yet. The frozen first field must stay beside the
  row-number column (both sticky); a header click now selects the column,
  so the header menu (sort, filter) must keep its own button.
- The expanded record uses the type's `cell` and `editor`: batch 5's types
  (multi-select, linked record, attachment) get the form for free, but each
  one that wormholes must mark its surface (`data-eui-sheet-editor-surface`)
  for the shells' focus-trap rule to matter, and Tab from a type's own
  `handlesKey` should pass a `move`.
- The sheet's state grew: `formEditorOpen` (shell trap), `menu`,
  `rangeKind`, `keepRangeOnFocus` (a press or right-click sets the range
  before `focusin`), `rowCursor`. Batch 6's touch work (long press for the
  menu) goes through `openMenu`.
- Batch 5's `'resolve'` merge must merge the entry's `rejections` too (it
  does by concatenation now); a resolved text should then drop its
  rejection from the entry.

### Batch 2: real input in Chromium (orchestrator, 2026-11-19)

Production docs build, Playwright keyboard and mouse:
- Undo of a paste with invalid cells (the user's case), Basics demo: pasting
  `Paris\tabc / Roma\t5` over City/Hours saves the cities and 5 and shows
  `abc` red; Ctrl/Cmd+Z restores all four cells (Monterrey 0, Madrid 7) with
  nothing red left; Ctrl/Cmd+Shift+Z brings the paste and the red `abc` back.
  An all-invalid paste (`abc\tzzz` on Hours/Active) turns both red; Ctrl/Cmd+Z
  clears both (14, empty); Ctrl/Cmd+Shift+Z shows them red again.
- d10: a click on row number 2 and Shift+click on 4 selects the three rows;
  Delete clears their cells and Ctrl/Cmd+Z restores them. Shift+Enter on a
  cell inserts an empty record below and focuses it. A right-click opens the
  row menu (insert above/below, duplicate, expand, copy row, the demo's "Mark
  done", delete); "Delete record" removes the row and Ctrl/Cmd+Z restores it.
  "Ids as row labels" shows w1…w8; the hovered row shows its checkbox and
  expand icon; the "+ Add record" row is last (`v02-b2-records.png`).
- d11: Space opens the flyout with every field (a read-only "Created by"),
  previous/next arrows (`v02-b2-flyout.png`); Escape closes it and focus is
  back on the cell; with "In a modal" the same opens in a modal and Escape
  closes it.
- d06 in the flyout: the Due field opens the flatpickr calendar; a click on
  day 20 saves 20/11/2026 in the form and the cell, the flyout stays open.
