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

## Batch 3: view intents

Built 2026-11-19 on `9222ff25` (uncommitted when this was written). Scope as
`V02-DESIGN.md` 6: sort arrows and the header menu (sort, hide, move, filter),
presentation state controlled with a handler and local without one, the
`<:toolbar>` and `<:footer>` blocks, `@highlight`, `@isLoading`, field
descriptions, the owner-provided summary bar with the core's `summarize`, and
the frozen primary field (9.2). `packages/core/src` was not changed. Nothing of
batch 4 was started.

### The frozen field gate (9.3): passed

The acceptance test was written and run first, against a first cut of the
9.2 mechanism plus the minimal widths and summary plumbing it needs, filtered
to its module. Headless Chrome 155:

- First run (`b3-fz1.log`): FZ1, FZ2, FZ4, FZ6–FZ9 passed. FZ3, FZ5 and FZ10
  failed, all three on test errors, not the mechanism: FZ3 asserted that the
  header of column `f5` was in view at `scrollLeft = 700`, but it sits under
  the frozen columns there (64 + 5 × 150 − 700 = 114 px, inside the 214 px
  frozen edge); FZ5 passed `pageX` to `triggerEvent`, which is not an event
  init field (the drag went the wrong way); FZ10's position checks passed
  and only `hasText` failed on the footer cell's copy marker (`↦`). Fixed
  in the tests (FZ3 checks `f7`, FZ5 uses `clientX`, FZ10 reads
  `.euiSheet__summary`).
- Second run (`b3-fz2.log`): FZ1–FZ5, FZ7–FZ10 passed. FZ6 failed on an
  assertion I added beyond 9.3: after a focus on the frozen cell while
  scrolled to 700, the grid's `scrollCellIntoView` scrolled back to 64 (the
  frozen column's own left edge). The editor did cover the cell. See
  deviation 1 for the sheet-side fix.
- With that fix, `b3-fz3.log` had 9/10. FZ4 failed on another assertion I
  had added ("still scrolled" after ArrowLeft down to column 1). Its premise
  was wrong: column 1 starts at the frozen edge, so the correction rightly
  scrolls to 0. The test now scrolls to 400 first. `b3-fz4.log`: 10/10, and
  the full suite since.

So FZ1–FZ4 and FZ10 pass in headless Chrome and the sheet-only mechanism of
9.2 was kept; the 9.4 grid extension was not needed. Firefox and Safari were
not checked (9.3 makes them a manual check).

What the gate showed about the mechanism, read from the passing assertions:
two sticky floated cells (row number at `left:0`, the first field at
`left:64px`) stay at their x and at the row's y at `scrollLeft = 700`; the
frozen cell is what `elementFromPoint` returns over it; the frozen header
cells stay at their x and y over a vertical scroll of 2000 px and paint over
the body; the footer row is `width: fit-content` (generated styles), so its
sticky cells stay too (FZ10); a drag on the frozen field's resizer widens it
(by more than 10 screen px, as asserted), moves the next cell by the same
amount and keeps it frozen (FZ5); with
`@frozenFields={{0}}` cells are `position:absolute` again and the last column
is not rendered at `scrollLeft = 0` (column window back, FZ8).

### What was built (files, under `packages/sheet/`)

| File | Change |
| --- | --- |
| `src/components/eui-sheet.gts` | Fields: `visibleFields` (with the local hidden set and order), `hiddenFields`, `canHide`, `hideField`/`showField`/`setFieldOrder`, `setVisibleColumns` turning the grid's calls into intents; widths (`givenWidth`, `resizedWidths`, `frozenWidth`, `onColumnResize`); `sorting`/`onGridSort`/`setSort`; row heights; `columns` (initial width, schema, `isSortable`, `actions`, `display`, frozen header class); the frozen field (`frozenCount`, `frozenLayout`, `frozenCellProps`, `frozenStyle`, `virtualizationOptions`, `clearFrozenOverlap`, `keepFrozenScroll`); `blockApi`; the dev warning `expectUpdate`; template: `<:toolbar>`, `div.euiSheet__grid` (frozen custom properties, `EuiProgress`), the grid's new arguments, `<:controlFooterCell>`, `<:footer>`, `euiSheet--scrolledX`. |
| `src/-private/footer-cell.gts` (new) | `SheetFooterCell` (`@renderFooterCellValue`) and `SheetControlFooterCell` (`@summary['']`), frozen footer props. |
| `src/-private/sheet-cell.gts` | Frozen style and class; `@highlight` to cell components; `EuiHighlight` for plain text. |
| `src/-private/row-number-cell.gts` | Frozen style and class. |
| `src/-private/record-form-field.gts` | The field's description under its label. |
| `src/-private/styles.ts` | Toolbar, footer, loading bar, header tip, form description; frozen cells (opaque base, hover and selection as an image over it), frozen headers (sticky, `left` from `--euiSheetFrozenLeft-<i>`, rules for indexes 0–51), footer cells, the edge shadow while scrolled. |
| `src/core/summary.ts` (new) | `summarize`, `SheetSummaryKind`. |
| `src/core/types.ts` | `EuiSheetField.description`, `width`, `sortable`, `hideable`; `FieldType.toNumber`. |
| `src/core/field-types/number.ts` | `toNumber`. |
| `src/core/messages.ts` | `filterByField` (`euiSheet.filterByField`, "Filter by this field"). |
| `src/core/index.ts`, `src/index.ts` | Export `summary.ts`; types `SheetBlockApi`, `SheetSort`, `SheetRowHeight`. |
| `src/types.ts` | `EuiSheetFieldType.schema`; `SheetCellSignature.Args.highlight`; `SheetSort`, `SheetRowHeight`, `SheetBlockApi`; the new arguments; `Blocks` (`toolbar`, `footer`). |
| `src/field-types.ts` | `schema`: number `'numeric'`, checkbox `'boolean'`, date `'datetime'`. |
| Tests, docs | Below. |

### API changes

Additive: arguments `@sort` + `@onSortChange`, `@onFilterByField`,
`@highlight`, `@isLoading`, `@summary`, `@onHiddenFieldsChange`,
`@onFieldOrderChange`, `@fieldWidths` + `@onFieldWidthChange`, `@rowHeight` +
`@onRowHeightChange`, `@frozenFields`; blocks `<:toolbar>` and `<:footer>`
yielding `SheetBlockApi` (`api`, `fields`, `hiddenFields`, `sort`,
`rowHeight`, `checkedRecords`, `hideField`, `showField`, `setRowHeight`,
`setSort`); field options `description`, `width`, `sortable`, `hideable`;
`FieldType.toNumber`; `EuiSheetFieldType.schema`; cell argument `@highlight`;
core `summarize` and `SheetSummaryKind`; types `SheetBlockApi`, `SheetSort`,
`SheetRowHeight`; message `filterByField`.

Not purely additive, as the design lists them: **C6** ("Hide column" really
hides; with the handlers the menu only calls them) and **C7** (the first field
is frozen by default: a 200 px first column unless a width is given, sticky
cells, every column of the rendered rows rendered). Also, not in 3.7:

- The first field has no column menu at all unless `@onSortChange` or
  `@onFilterByField` is passed: its other items (hide, move) are off by 6.3,
  and the grid hides the button when every item is off. In v0.1 and batch 2
  it had "Hide column" and "Move right".
- The second field has no "Move left" (nothing moves before the first).
- Number columns are right-aligned, and number, date and checkbox headers get
  the grid's schema class and alignment, because the built-ins now have a
  `schema` (6.2).
- Focusing a frozen cell by a key or a press keeps the horizontal scroll, and
  Home scrolls to the left edge (deviation 1).

### Verification items (section 12)

| # | Item | Outcome |
| --- | --- | --- |
| N5 | The grid's sort labels per schema, and whether a column `schema` alone (no `@inMemory`) is enough. | Enough: `column-actions.gts` reads `grid.schema[column.id]`, and `grid.schema` is `mergeSchema(detectSchema(...), columns)`, which keeps a column's own `schema` without `@inMemory`. VW3 sees "Sort Low-High" and calls "Sort High-Low" on the number field; VW2 sees "Sort A-Z" on a text field. The date and checkbox labels ("Old-New", "False-True") are read from `utils/data-grid/schema.ts`, not run. The header class half was batch 2. |
| N6 | Whether a changed `initialWidth` re-applies to an existing column; `EuiProgress` and `EuiIconTip` arguments. | It re-applies when the sheet passes a new `@columns` array: `body-base.ts` keeps resized widths only while `grid.columns` is the same array, and `initialColumnWidths` is cached on it. The sheet's `columns` depends on `@fieldWidths`, so a new value is a new array. VW8 checks 150 → 240 on `name`. The same rule drops resized widths whenever the columns change for another reason (a hide, a move): VW8 checks that a resize without `@onFieldWidthChange` is dropped by a later hide. As 6.4 and 10 say ("the grid keeps them"), the sheet does not keep them itself; an owner keeps them with `@fieldWidths` and the handler. The sheet mirrors the grid's kept widths only for the frozen offsets. `EuiProgress`: `@size="xs" @position="absolute" @color="primary"`, with attributes (VW12). `EuiIconTip`: `@content`, `@type`, `@size`, `@color`. It renders a `tabindex="0"` icon in the header cell, which already has a tabbable child (its actions button), so the cell's focus trap was there before. |
| N7 | Section 9 on the real grid, and in Firefox and Safari. | Headless Chrome: FZ1–FZ11 pass. Firefox and Safari not run. |
| N14 | Performance. | FZ9, 10,000 rows × 30 fields at 600 × 400 px, 20 vertical scroll steps of 600 px (each replaces the whole row window), in a `?report` run (`b3-fz9-report.log`): frozen on **195.6 ms per step, 372 cells rendered**; frozen off **49.6 ms, 72 cells**. A second report run on the final code, with nothing else running (`b3-fz9-report2.log`): 196.6 ms and 47.3 ms. Each step includes `settled()` and one animation frame, in headless Chrome with software rendering, so these are comparisons, not frame times. The cost is linear in the rendered cells (about 5× the cells, 4× the time). Not measured on the Mac or in d08. |

### Tests

Baseline at HEAD in the scratch copy: 195/195 (`b3-baseline.log`). The first
full run (`b3-run1.log`) had the 195 existing tests and the 10 FZ tests: 203
passed, and 2 failed (TH3 and TH5, below). Final: **229/229**, 0 failed
(`b3-c2.log`, 08:37 UTC, after the last source and test edit). An earlier
228/228 (`b3-c1.log`) was before FZ12 and the width change (deviation 6). Logs are in the session scratchpad
(`/tmp/claude-1000/-Users-betocantu93-prysmex/df04f7e2-a347-4eab-a276-4d9974f4dbc1/scratchpad/`).

New (34):

- `tests/integration/components/eui-sheet-frozen-test.gts` (new, 12): FZ1–FZ10
  as in 9.3, plus:
  - FZ11: 51 visible fields are not frozen; 50 are.
  - FZ12: `@frozenFields={{2}}` with `@rowNumbers={{false}}`. Both fields
    stay, the edge class is on the second, the header follows, and ArrowLeft
    never lands under them. A drag that starts on a frozen cell while
    scrolled keeps the scroll (simulated `pointerdown`/`pointerup`, so the
    grid's pointerup scroll runs). FZ4 also
  checks that ArrowLeft into the frozen field while scrolled keeps the scroll,
  and that Home scrolls to 0. FZ6 opens the editor after a **click** on the
  frozen cell and checks the scroll is kept. FZ9 measures frozen on and off.
- `tests/integration/components/eui-sheet-view-test.gts` (new, 13): VW1–VW13 as
  in 6.9. VW3 also covers `sortable: false`; VW4 `hideable: false`; VW6 that
  the first field has no menu and the second no "Move left"; VW8 the N6 cases (and, without the handler, that
  the other columns keep their widths and a hide drops the resized one);
  VW10 the block API both local and with handlers, and that `hideField` on the
  first field does nothing.
- `tests/integration/components/eui-sheet-summary-test.gts` (new, 4): SU1–SU4.
- `tests/unit/summary-test.ts` (new, 5): SM1–SM5.

Changed on purpose:

- **TH5** (`eui-sheet-theme-test.gts`): it checked the focused cell (0, 0)'s
  `background-color` for the app's `--euiSheet-selected`. That cell is now
  frozen (C7), so its selection is drawn as
  `background-image: linear-gradient(rgb(4, 5, 6), rgb(4, 5, 6))` over an
  opaque base. The test now checks that exact value: same cell, same colour,
  another property.
- **TH3** was not changed. It failed because the frozen styles first read
  `--euiSheet-frozenBase` and `--euiSheet-frozen-left-<i>`, which are not theme
  colours. They were renamed instead (deviation 2).

Not executed by any test:
- the dev warning (6.11);
- a resize while an editor is open (6.8);
- the edge shadow (`euiSheet--scrolledX`);
- hover over frozen cells, and dark mode for frozen cells;
- that a wheel or scrollbar scroll after a key is not undone (deviation 1);
- the date and checkbox sort labels;
- Firefox and Safari;
- the d12, d13 and new d08 demos at runtime (built, not run).

Lint (`pnpm lint`: `ember-tsc --noEmit`, ESLint, stylelint): exit 0
(`b3-lint-c2.log`). Prettier `--check src tests/integration tests/unit
tests/helpers README.md`: everything batch 3 touched is clean. The one warning
is `tests/helpers/index.js`, which is not Prettier-clean at HEAD and was not
touched (`b3-prettier-c2.log`, exit 1 for that file only). The sources were
formatted with `--write` in the scratch copy and copied back
(`b3-prettier-write.log`). Docs Markdown is not Prettier-formatted here.

### Deviations from the design

1. **A frozen cell keeps the horizontal scroll when it gets focus.** This is
   added beyond 9.2. The grid's `scrollCellIntoView` only knows a column's
   own left edge, so focusing the first field while scrolled (ArrowLeft into
   it, a click on it, the sheet's own `setFocusedCell`) scrolled the grid back
   to `left = 64` (FZ6, `b3-fz2.log`). The fix is sheet-only, in the same
   spirit as 9.1's focus correction. A keydown, a mousedown or the sheet's own
   focus call records `scrollLeft`. When focus lands on a frozen cell, the
   sheet scrolls back to it once: after the render for a key, or on the click
   for a press, because the grid scrolls on pointerup. A drag that starts on
   a frozen cell also scrolls back on release (FZ12). A later scroll event
   drops the recorded value; the intent is that a stale one never undoes a
   wheel scroll, but no test checks it. Home records 0, so it goes to the
   left edge. Removing this brings back the jump left. Limits:
   - A focus with no key or press first (a script's `element.focus()`, or
     the grid re-focusing a re-mounted cell) is not corrected.
   - The grid's scroll and the sheet's restore happen in the same task
     (keys) or in consecutive events (press); no flicker was looked for.

   The 9.4 extension would do this inside `scrollCellIntoView`.
2. **Internal custom properties** are `--euiSheetFrozenLeft-<i>` and
   `--euiSheetFrozenBase`, not `--euiSheet-frozen-left-<i>` (9.2). TH3 requires
   every `--euiSheet-*` property the CSS reads to be a theme colour, and these
   are layout values. They are set on a new `div.euiSheet__grid` around the
   grid, not on the wrapper: the wrapper's `style` attribute is the app's
   (TH5 sets one), and a bound `style` would clash with it.
3. **The loading bar is over the grid**, inside `div.euiSheet__grid`, not at
   the top of the wrapper (6.4). 3.5 says "over the grid", and with a toolbar
   the wrapper's top is the toolbar.
4. **Frozen cells' hover and selection** are a `background-image` gradient
   over an opaque `background-color`. The sheet's colours are translucent, so
   as a plain `background-color` the scrolled cells showed through. Frozen
   header and footer cells use `background-color: inherit` (their rows have
   the opaque colour).
5. **The local hide fallback also covers `@hiddenFields`.** Without
   `@onHiddenFieldsChange`, `showField` on a field of `@hiddenFields` shows it,
   after the others, not only fields of `@fields`. 6.4 says "applied over
   `@fields`". The block API's `showField` needs it to do anything on a bare
   sheet with hidden fields.
6. **Widths without a handler** are the grid's, as designed: it drops them
   when its columns change, for example on a hide or a move (N6, VW8). The
   sheet mirrors them for the frozen offsets only. A first version fed
   resized widths back as `initialWidth`, so that they survived a hide. It
   was dropped: it changed the grid's fill. Columns without a width share
   the space the sized ones leave, so widening one column shrank the others
   instead of widening the grid.
7. **The dev warning** (6.11) covers only the presentation handlers: hidden
   fields, order, widths and row height. Sort is excluded, because an owner's
   sort is often an async query and would warn wrongly. It runs one `next()`
   after the handler, uses `@ember/debug`'s `warn` (dropped in production),
   and fires once per argument. Untested.
8. **`@highlight`** marks every match (`@highlightAll={{true}}`; `EuiHighlight`
   marks only the first by default), ignoring case and accents (its default).
   The built-in single-select cell does not mark its badge; custom cells get
   `@highlight`.
9. **The description in the expanded record** is help text under the label,
   as 6.2 says. VW13's "tooltip ... in the form" was read as that.
10. **Sort items** are turned off (`showSortAsc/Desc: false`) without
    `@onSortChange`, not only left without `@sorting`, so they do not count
    toward the grid's "has column actions". Otherwise the first field would
    show an empty menu.
11. **`summarize`** rounds `percentFilled` to a whole percent and does not
    round `average` (`format(3.375)` is "3.375"). Min and max use `toNumber`
    when the type has it, else `compare`, so text has a min and a max.
    `unique` compares `copyText` and is case-sensitive.
12. **FZ9's numbers** reach the log only in a run with `report` in the page's
    query: the test then pushes a failing assertion that carries them,
    because TAP prints only failures. A normal run checks only that they are
    numbers. `b3-fz9-report.log` is such a run.
13. **Open questions** took the design's defaults. Q2 is the sheet-only
    frozen field, gated by 9.3, which passed. Q15 is no sorter in the sheet:
    d12's owner sorts with the built-in types' `compare`.

### Docs

- `docs/sheet.md`: the arguments table (11 new rows, the new field options);
  new sections "The owner" (what the sheet never does, the intents table, the
  blocks), "Presentation state" (controlled with a handler, local without),
  "Summary bar" (`summarize`, the kinds), "Frozen field" (with its limit). A
  paragraph on `schema`, `toNumber` and `@highlight` for types. "Not yet" lost
  sorting/filtering UI, frozen columns and hiding columns, and now says that
  sorting, filtering, search and paging are the owner's; grouping is listed as
  later.
- `README.md`: the same, shorter: argument rows, the blocks, "The owner:
  queries and presentation", the `toNumber`, `schema` and `@highlight` rows
  for custom types, the `filterByField` token, and "Limits".
- New `d12-view-intents.md`: an owner component that sorts its array (300 ms
  fake latency with `@isLoading`) and keeps visible fields, order, widths and
  row height. Its `<:toolbar>` has a search box (it filters and passes
  `@highlight`), a row-height button group (`setRowHeight`) and a field picker
  (`hideField`/`showField`). It also has `@onFilterByField` (logged), two
  descriptions, a `<:footer>` line and an intents log.
- New `d13-summary.md`: `@summary` computed with `summarize` over every
  record, with two button groups in `<:toolbar>` choosing what to summarize.
- `d08-large-data.md`: 30 fields (24 numeric "Week" columns), the first
  frozen, a "Freeze the first field" switch to compare, and a paragraph on the
  cost.
- `d07-translations.md`: the Spanish `filterByField`.

### Docs site build

In the scratch copy: `build:js` of core, sheet, flatpickr, pikaday,
changeset-form and validated-form, then in `site` `pnpm clean:docfy && node
../scripts/generate-llms-txt.mjs && pnpm exec vite build --mode production`:
exit 0 (`b3-site.log`, `b3-site-summary.log`, 08:39 UTC, after the last source
and docs edit; a first build at 08:27 was overwritten). d13 has its own chunk (`docfy-demo-docs-sheet-d13-summary-*.js`);
d12 has none by that name. Texts of d12 ("Search name, city, notes"), d13
("Hours summary"), d08 ("Freeze the first field") and d07's
"Filtrar por este campo" are in the sheet route's chunk
(`-embroider-route-entrypoint.js_route_docs.sheet.docs.sheet-*.js`). The log
has the same seven docfy `getRepoEditUrl` TypeErrors as batches 1 and 2 (no
`.git` in the scratch copy). The demos were built, not run; `site/dist` is left
in the scratch copy.

### For the orchestrator to check with real input (docs site, Sheet page)

- **d12 View intents**:
  - Sorting: City's ⋯ menu → "Sort A-Z": a thin bar for about 300 ms, then
    the rows sorted by city and an up arrow on City. Hours' menu → "Sort
    Low-High": a second key, and the footer says "sorted by City asc, then
    Hours asc". The same item again unsorts.
  - Hiding and moving: City's menu → "Hide column": the column goes and its
    switch turns off; switch it back on (it comes back last). City → "Move
    right". Name's ⋯ menu has only sort and "Filter by this field" (no hide,
    no move), and its switch is disabled.
  - Widths and row height: drag Name's right edge (the log shows
    `onFieldWidthChange`), and check that the other columns keep their
    widths. Then "Tall", then "Short".
  - Search: type `an`: the rows are filtered and "an" is marked in names and
    cities. Clear it.
  - Filter and descriptions: "Filter by this field" is logged. Hover the
    info icons of Name and Notes (Notes is hidden by default: switch it on).
    Space on a cell: the flyout shows the descriptions under the labels.
  - Scroll right: Name and the row numbers stay, with a shadow on their
    right edge.
- **d13 Summary bar**:
  - The footer shows the record count, "Filled 40", "Sum …", "Earliest …",
    "Checked …", "Unique 3".
  - Switch Hours to Average, then Max. Edit an hour: the sum or average
    follows.
  - Delete a record (row menu): the count drops. Ctrl/Cmd+Z restores it.
  - Scroll right: the count and Name's summary stay in place over the
    scrolled ones.
- **d01 Basics** (no handlers): resize a column, then hide another from its
  menu. The resized width resets, which is the grid's rule (deviation 6).
- **d08 Large data** (30 fields):
  - Scroll right: Code and the row numbers stay, and the header stays too
    on vertical scroll.
  - Focus a far-right cell and hold ArrowLeft to Code: no focused cell is
    hidden under Code.
  - Scroll right, click a Code cell: the grid does not jump left. Home goes
    to the left edge.
  - Type on a Code cell while scrolled: the editor covers it.
  - Drag across Code and Name: both are drawn selected.
  - Turn "Freeze the first field" off and compare the vertical scroll's
    smoothness (FZ9 measured about 4× the time per full-window step frozen).
- **d01 with the Dark switch**: the frozen cells and headers are opaque and
  dark, not white. Check which focus ring shows on a frozen cell (batch 1's
  TH1 note: the grid draws its own).
- **Firefox and Safari** (if Playwright has them): d08's frozen column and
  header on horizontal and vertical scroll (9.3 makes them a manual check).

### Notes for batch 4

- The connector maps these:
  - `@sort`/`@onSortChange` to the driver's sort. The sheet appends a new key
    to the existing ones; keep the last item for single-key backends.
  - `@highlight` to the query text, and `@isLoading` to the search state.
  - `@summary` to `SearchResult.aggregations`, and `@rowNumberOffset` to the
    page.
  - `@onFilterByField` to the app's filter UI.
  - The pager goes in `<:footer>` (the block yields `api` and
    `checkedRecords`). The search box and views go in `<:toolbar>`.
- An async sort replaces `@records` after the intent. C14 then moves the
  selection and focus to their record. The dev warning does not cover sort,
  so a slow driver does not warn.
- FZ9: with many fields, frozen costs about 4× per scrolled row window. A
  connector demo with wide records may want `@frozenFields={{0}}` (Q2: the
  9.4 extension keeps column virtualization).
- A column menu now exists only for fields with an item. Sort and filter
  items come with their handlers, so a connector that passes
  `@onSortChange` gives every sortable field a menu.

### Batch 3: real input in Chromium (orchestrator, 2026-11-19)

Production docs build, Playwright keyboard and mouse:
- d12: Enter on the City header opens its menu (Hide column, Sort A-Z,
  Sort Z-A, Move right, Filter by this field); "Sort A-Z" goes to the owner
  and the rows come back sorted (Bogotá first). Typing `an` in the demo's
  search filters the rows (Ana 7, Ana 19, …) and marks the match with
  `EuiMark`. Row height Tall: rows go from 36 to 108 px.
- d08 (10,000 × 30): scrolled 900 px right, Code keeps its place (left edge
  353 px before and after) with an edge shadow; a click on a Code cell while
  scrolled keeps the scroll (no jump left) (`v02-b3-frozen.png`). Rough
  timing of 20 vertical scroll steps (two frames each, headless, relative
  only): 128 ms per step frozen, 65 ms unfrozen.
- d01 Dark: the frozen Name column has the dark background like the other
  cells (`v02-b3-dark-frozen.png`); numbers are right-aligned.

## Batch 4: EmberSearchUi connector

Built 2026-11-19 on `92733b31` (uncommitted when this was written). Scope as
`V02-DESIGN.md` 7: the optional entry `@ember-eui/sheet/search-ui`
(`SearchRecords`/`searchRecords`, `fieldsFromSchema`, `EuiSheetSearch`), its
tests, the docs and the "Sheet with EmberSearchUi" demo. Group by stays
deferred (7.6). `packages/core/src` was not changed. Nothing of batch 5 was
started. The EmberSearchUi repository was read, not edited.

### What was built

| File | Change |
| --- | --- |
| `packages/sheet/src/search-ui/index.ts` (new) | Barrel of the entry. |
| `packages/sheet/src/search-ui/search-records.ts` (new) | `SheetSearchDriver` (structural), `SheetSearchSnapshot`, `SheetSearchPage`, `SheetSearchFieldDefinition`, `SearchRecordsOptions`, `SearchRecords`, `searchRecords`. Imports nothing from EmberSearchUi. |
| `packages/sheet/src/search-ui/fields-from-schema.ts` (new) | `fieldsFromSchema`. |
| `packages/sheet/src/search-ui/eui-sheet-search.gts` (new) | `EuiSheetSearch`, `EuiSheetSearchSignature`, `SheetSearchBlockApi`. Not app-re-exported. |
| `packages/sheet/src/core/messages.ts` | Token `euiSheet.reapply` ("Re-apply"). |
| `packages/sheet/src/components/eui-sheet.gts` | Undo/redo keep a skipped entry on its stack when none of its records is in `@records` (deviation 1): `touchesRecords`, `applyHistory` returns whether it did something. |
| `packages/sheet/src/-private/styles.ts` | Three rules: the connector's toolbar row, its footer column, and hiding its empty toolbar/footer. |
| `packages/sheet/package.json` | `exports["./search-ui"]` (`declarations/search-ui/index.d.ts`, `dist/search-ui/index.js`); devDependency `ember-search-ui-driver` `2.0.0-beta.2`. No peer, no dependency. |
| `site/package.json` | devDependencies `ember-search-ui` `2.0.0-beta.2`, `ember-search-ui-driver` `2.0.0-beta.2`, `ember-search-ui-views` `2.0.0`, `@elastic/search-ui` `^1.24.2`, `tracked-built-ins` `^4.1.2`. |
| `pnpm-lock.yaml` | Additions only (below). |
| `packages/sheet/tests/unit/search-records-test.ts` (new), `search-driver-types-test.ts` (new), `tests/integration/components/eui-sheet-search-test.gts` (new), `tests/unit/core-boundary-test.ts` (B2) | Tests. |
| `packages/sheet/docs/sheet.md`, `README.md`, `docs/sheet-demo/d07-translations.md`, new `docs/sheet-demo/d14-search-ui.md` | Docs. |

### API

Additive, all from `@ember-eui/sheet/search-ui`:

- `searchRecords(owner, driver, { getRecordId, onChange, createRecord?, refreshOnChange? })`
  → `SearchRecords`: `records`, `sort`, `term`, `isLoading`, `error`,
  `total`, `page` (`{ page, perPage, pageCount }`, offset paging only),
  `rowNumberOffset`, `isStale`, `apply`, `setSort`, `setPage` (1-based,
  no-op under cursor paging), `setPerPage`, `reapply`, and `disconnect()`
  (deviation 3). Unsubscribes when `owner` is destroyed; never destroys the
  driver.
- `fieldsFromSchema(schema)`.
- `EuiSheetSearch`: `@driver`, `@getRecordId`, `@onChange`, `@createRecord`,
  `@refreshOnChange`, `@fields` (default `fieldsFromSchema(driver.schema)`),
  `@paging` (default true), and these `EuiSheet` arguments passed as they
  are: `@hiddenFields`, `@onHiddenFieldsChange`, `@onFieldOrderChange`,
  `@fieldWidths`, `@onFieldWidthChange`, `@rowHeight`, `@onRowHeightChange`,
  `@frozenFields`, `@summary`, `@onFilterByField`, `@readOnly`, `@canInsert`,
  `@canDelete`, `@cellErrors`, `@validate`, `@fieldTypes`, `@messages`,
  `@height`, `@rowNumbers`, `@rowLabel`, `@rowActions`, `@newRecordValues`,
  `@expandedRecord`, `@expandedRecordId`, `@onExpandedRecordChange`,
  `@checkedRecordIds`, `@onCheckedChange`, `@registerApi`, `@ariaLabel`
  (`@onResolve` does not exist yet: batch 5). Blocks `<:toolbar>` and
  `<:footer>` yield `SheetBlockApi & { search }`.
- Types `SheetSearchDriver`, `SheetSearchSnapshot`, `SheetSearchPage`,
  `SheetSearchFieldDefinition`, `SearchRecordsOptions`,
  `EuiSheetSearchSignature`, `SheetSearchBlockApi`.
- Message `reapply` (`euiSheet.reapply`), also in `SheetMessages`.

Not purely additive: an undo or redo that finds nothing to do because none of
the entry's records is in `@records` now leaves the entry on its stack
(before, it moved to the other stack). This affects every sheet, not only
the connector (deviation 1).

### Dependencies and the lockfile

Registry (`npm view`, 2026-11-19): `ember-search-ui-driver` 2.0.0-beta.2,
`ember-search-ui` 2.0.0-beta.2 and `ember-search-ui-views` 2.0.0 are
published, all three under the dist-tag `next`. The `latest` tags point to
older versions (beta.1, 1.0.2, 1.0.0), so the specifiers are exact pins. The
site already had the views' peers `ember-power-select` 9.0.2,
`ember-basic-dropdown` 9.0.0 and `ember-concurrency` 5.3.0. It also needs
`@elastic/search-ui`, because `ember-search-ui`'s index re-exports
`SearchProvider`, which imports it at run time (`dist/components/search-provider.js`),
and `tracked-built-ins` (`WithSearch`). Both are peers of `ember-search-ui`.

In the scratch copy, a control `pnpm install` with no package change left
the lockfile identical (`b4-install-control.log`, `b4-lock-control.diff`:
0 lines). After the `package.json` edits, one non-frozen `pnpm install`
(`b4-install.log`: "+20" packages, 1 downloaded; peer warnings are about
packages that were there before, `b4-peers.log`) changed the lockfile by
**197 added lines and 0 removed** (`b4-lock.diff`): the five site importer
entries and the sheet's devDependency, and the packages `@elastic/search-ui`
1.24.2, `date-fns` 1.30.1, `deep-equal` 1.1.2 and 2.2.3, `ember-search-ui`,
`ember-search-ui-driver`, `ember-search-ui-views`, `es-get-iterator`,
`history` 4.10.1, `is-arguments`, `object-is`, `resolve-pathname`,
`tiny-warning`, `tracked-built-ins` 4.1.2, `value-equal`. Nothing else
changed. Only `pnpm-lock.yaml` was copied back to the repository.

In the scratch copy, `pnpm install --frozen-lockfile` with the copied-back
lockfile passed ("Lockfile is up to date", `b4-install-frozen.log`).

On the Mac, in `~/prysmex/ember-eui`:

```sh
pnpm install --frozen-lockfile   # the lockfile already has the new entries
pnpm --filter @ember-eui/sheet test
pnpm start                        # docs site: Sheet page, "Sheet with EmberSearchUi"
```

### Verification items (section 12)

| # | Item | Outcome |
| --- | --- | --- |
| N8 | What `snapshot.result.results` holds while loading; whether `EuiTablePagination`'s `activePage` is 0-based. | Read in `driver.ts`. A command emits the new state with the **same result object**. The loading emit is `{ ...previous result, status: 'loading' }` (the previous results stay), and an error keeps the results too. So the connector replaces its rows only on a `'success'` result whose object is new (SR1b covers state-only, loading and error snapshots with an overlay). `activePage` is 0-based (`eui-table-pagination.gts`: "The current page, from `0`"; `onChangePage` gets the 0-based index). SS4 checks that page 2 of the driver is `pagination-button-1` with `aria-current="page"`. |
| N9 | `ember-search-ui-views` on npm; it and its peers build in the docs site. | Published (2.0.0, dist-tag `next`). It installed with the peers the site already had. The production site build passed (`b4-site.log`), and the d14 chunk was emitted. In a headless smoke run of the built site (`b4-smoke.mjs`, `b4-smoke.log`, 10/10), d14 rendered its rows, `SearchBox`, `Sorting`, `FilterBar` and the pager, and `PagingInfo` read "Showing 1 - 50 out of 2000". A DOM click on page 2 showed row number 51 and "Marta 51". There were no exceptions or console errors. That run used DOM calls, not trusted input. |
| N10 | The views' arguments and that they work under `Search` with the demo's driver. | Read in the views' sources. `SearchBox`, `Sorting`, `Facet` and `PagingInfo` take a search-ui-style `@driver` (`SearchUiDriver \| SearchUiCompat`): the demo passes `searchUiCompat(driver)` (from the driver package). `FilterBar` and `FilterChips` take `@search` (the `TrackedSearch` that `<Search @driver>` yields) and `@properties` (`defineProperty`). `Facet` was left out: it reads facets from `result.aggregations['facets']` (`compat/search-ui.ts`), and `memoryBackend` returns only `{ results, total }`, so it would have nothing to show. That conclusion comes from the source; `Facet` was not rendered (deviation 8). These views ran only in the smoke check above, without real input. |
| N14 | Performance. | Not measured. The demo's `write` runs `applyChangeSet` over 2,000 docs per change set, and the overlay applies one change set over the page per edit. |

### Tests

Baseline: 229/229 at HEAD (batch 3's `b3-c2.log`). Filtered runs while
building:
- `b4-run1.log`: 24/26. SR1 asserted offset 0 before any result. SS3 assumed
  focus stayed on the edited row, but Enter moves down a row. Both were
  test premises, fixed in the tests (`b4-dbg1.log` showed the second).
- `b4-run2.log`: 25/26. SS3 found DOM focus on `body` after "Re-apply"
  (deviation 7).
- `b4-run3.log`: 26/26.

Full runs: `b4-c1.log` 256/256, with ESLint failing on the new tests. `b4-c2.log`
256/256 with lint clean. Final: **256/256**, 0 failed (`b4-c3.log`, 09:14 UTC, after the last source
and test edit; lint `b4-lint-c3.log`, Prettier `b4-prettier-c3.log`). Logs are in the session
scratchpad
(`/tmp/claude-1000/-Users-betocantu93-prysmex/df04f7e2-a347-4eab-a276-4d9974f4dbc1/scratchpad/`).

New (27):

- `tests/unit/search-records-test.ts` (13, fake driver): SR1–SR10 as in 7.4.
  Added:
  - SR1b: state-only, loading and error snapshots keep the rows and the
    overlay.
  - SR11: a rejected `onChange` keeps the edit shown, reaches
    `unhandledrejection`, and nothing is undone or re-queried.
  - SR12: `disconnect()` without `searchRecords`.
  - SR6 also checks that a search finishing during the save plus
    `refreshOnChange` gives one refresh, not two.
- `tests/unit/search-driver-types-test.ts` (3, real `SearchDriver` +
  `memoryBackend`): SR1 (records, sort, page, offset, query; `settled()`
  waits for the driver's searches), SR2/SR3, SR9 on a real `FieldSchema`.
  The compile-time half is described below.
- `tests/integration/components/eui-sheet-search-test.gts` (10, real
  driver): SS1–SS9 as in 7.4, plus SS3b (a re-query while a data cell has
  focus moves focus with its record).
  - SS1 also renders the default fields from the schema.
  - SS7 also checks that the empty toolbar and footer are `display: none`.
  - SS8 needed deviation 1.
- `tests/unit/core-boundary-test.ts` B2: no file under `src` imports
  `ember-search-ui*` or `@elastic/search-ui`.

The type test: `tsconfig.json` includes only `src`, so `pnpm lint` does not
check tests. `ember-tsc --noEmit -p tsconfig.eslint.json` reports no error
in the new files (`b4-tsc-tests-c3.log`; the errors it lists are in older
test files and were there before, e.g. `.at` on arrays and
`ember-keyboard` types). It checks that a real `SearchDriver<Doc>` is
assignable to `SheetSearchDriver<Doc>`. It also checks a negative case under
`@ts-expect-error`: an `Omit<SearchDriver, 'setSort'>` is not assignable.
With that directive removed, the check fails with TS2345
(`b4-tsc-negative.log`), so the test is not vacuous.

No existing test changed.

Not executed by any test:
- d14 with real input;
- `@refreshOnChange` through the component (unit only);
- a new `@driver` on a rendered `EuiSheetSearch` (reconnect);
- cursor paging in the component (no pager; unit only);
- `search.error` in a UI (the component shows no error);
- `Facet`.

Lint (`pnpm lint`: `ember-tsc --noEmit`, ESLint, stylelint): exit 0
(`b4-lint-c3.log`). Prettier `--check src tests/integration tests/unit
tests/helpers README.md`: everything batch 4 touched is clean. The only
warning is `tests/helpers/index.js`, unclean at HEAD (`b4-prettier-c3.log`).
Sources, tests and `README.md` were formatted with `--write` in the scratch
copy and copied back (`b4-prettier-write.log`). One README code block was
then rewritten by hand into a layout Prettier also accepts. Docs Markdown is
not Prettier-formatted here.

Root checks after `build:js` of the packages: `node --test
scripts/dist-hygiene.test.mjs` 9/9 (`b4-dist-hygiene.log`; the new modules
do only registration on import), and `pnpm docs:api:check` exit 0
(`b4-docs-api-check.log`; the sheet has no API-docs page).

### Deviations from the design

1. **A skipped undo entry stays on the stack: a sheet change.** 7.3 says an
   entry whose record is not on the current page "is skipped (3.4), and
   stays on the stack", and SS8 tests it. Batch 1's `undo()`/`redo()` moved
   the entry to the other stack even when nothing was emitted, so SS8 could
   not pass with the connector alone. Now, when undo or redo emits nothing
   and changes no rejected text, and none of the entry's records (patched,
   inserted `tempId`s, deleted, rejected) is in `@records`, the entry goes
   back on its stack. An entry skipped for another reason (its cells were
   changed since, U3) still moves, as before. Side effect, as Q17 warns:
   such an entry at the top blocks the older ones until its records are
   back.
2. **`SheetSearchDriver` has two optional members**, `isSettled` and
   `settled()` (`SearchDriver` has both). Without them the test waiter would
   miss the time between a command and the start of its search (the
   driver's debounce timer), and `await settled()` would return too early.
   The connector checks again in a microtask after each snapshot, because
   the driver sets its timer after emitting. Drivers without these members
   get a waiter while `status` is `'loading'` or a save runs. The snapshot
   and page shapes have names (`SheetSearchSnapshot`, `SheetSearchPage`),
   and `SheetSearchFieldDefinition` has `nested` (it is a flag on
   `FieldDefinition`, not a type).
3. **`SearchRecords.disconnect()` is public**, so the class works without
   `searchRecords` (as `TrackedSearch.disconnect()`).
4. **`rowNumberOffset` comes from the page of the last successful result**,
   not from the requested page. Row numbers change with the rows, not 150
   ms before them. `page` is the requested page, so the pager responds at
   once.
5. **The connector reads `driver.snapshot` and subscribes without
   `immediate`**, as `TrackedSearch` does. A snapshot that is still loading
   shows the results it holds.
6. **`fieldsFromSchema`:**
   - It leaves out dotted paths too (`custom.due`), because a sheet field
     reads one key (`valueOf` is `record[id]`).
   - Options whose value is not a string or a number are dropped, and a
     keyword left with no options is `text`.
   - "`label` → `label`" in 7.3 was read as the field's label (default: the
     path); the sheet has no `label` type.
   - `nested` is the flag or the type.
7. **`EuiSheetSearch` details:**
   - `@onResolve` is not forwarded (batch 5 adds it to the sheet).
   - "Re-apply" moves focus back to the grid's tab-stop cell before it
     re-queries. The result removes the button, and SS3 found DOM focus on
     `body` (`b4-run2.log`). With focus on a cell, the sheet's 3.2 rule
     moves it with the record (SS3, SS3b).
   - A new `@driver` connects again; the old connection only unsubscribes.
   - The component always passes both blocks to `EuiSheet`, so an empty
     toolbar or footer is hidden with CSS (`.euiSheetSearch >
     .euiSheet__toolbar:not(:has(> *))`), which needs a browser with
     `:has()`.
8. **The demo's toolbar has no `Facet`.** It uses `FilterBar` and
   `FilterChips`, which also come from the views, for the select field,
   because `memoryBackend` gives no aggregations (N10). The other views
   follow the design: `SearchBox`, `Sorting` and `PagingInfo` (through
   `searchUiCompat`) inside `Search`. The Q16 fallback (EUI controls) was
   not needed. Its `Sorting` options are single-key (the compat API), and
   the header's sort sets the same driver state.
9. **Exact versions** (`2.0.0-beta.2`, `2.0.0`) instead of ranges, because
   `latest` points to older majors.
10. **Open questions** took the design's defaults:
    - Q16: the views, since they install and build.
    - Q17: keep the history.
    - Q19: the button and the pager are rendered, `@paging={{false}}` drops
      the pager, and `search.isStale` is yielded.
    - Q18: group by stays deferred.

### Docs

- `docs/sheet.md`:
  - A new section "EmberSearchUi": what it maps, "stable while editing",
    inserts and `remapIds`, rejected saves, undo across pages, the blocks,
    `fieldsFromSchema`, `@summary` not mapped, and `searchRecords` with an
    own `<EuiSheet>`.
  - "Undo and redo": a skipped change stays on the stack.
  - "Not yet": grouping is planned for later, and the owner's queries
    include the connector.
- `README.md`: the same, shorter. Also the `reapply` token and "Limits".
- `d07-translations.md`: Spanish `reapply`.
- New `d14-search-ui.md` "Sheet with EmberSearchUi", as 7.5:
  - 2,000 docs in a tracked store and `memoryBackend(() => store.docs, {
    latencyMs: 150 })`, 50 per page.
  - `@onChange` writes the store with `applyChangeSet`.
  - The toolbar has `SearchBox`, `Sorting`, `FilterBar` and `FilterChips`;
    the footer has the pager and `PagingInfo`.
  - A walkthrough.

### Docs site build

In the scratch copy: `build:js` of core, sheet, flatpickr, pikaday,
changeset-form and validated-form, then in `site` `pnpm clean:docfy && node
../scripts/generate-llms-txt.mjs && pnpm exec vite build --mode production`:
exit 0 (`b4-site.log`, `b4-site-summary.log`, 09:12 UTC; rebuilt after the
last demo text edit: `b4-site2.log`, `b4-site2-summary.log`, 09:17 UTC, whose
`dist` is the one left, smoke `b4-smoke2.log` 10/10 on it). d14 has its own chunk
(`docfy-demo-docs-sheet-d14-search-ui-*.js` and a `.css` with the views'
styles). The log has the same seven docfy `getRepoEditUrl` TypeErrors as
the earlier batches (no `.git` in the scratch copy). `site/dist` is left in
the scratch copy. In the scratch copy the site links the packages
(symlinks). On the Mac it uses injected copies, which `pnpm start` syncs
(`sync-injected.mjs`).

### For the orchestrator to check with real input (docs site, Sheet page, "Sheet with EmberSearchUi")

1. On load: a thin loading bar for about 150 ms, then 50 rows ("Ana 1"
   first) and the pager "Rows per page: 50", pages 1…40. Under it, "Showing
   1 - 50 out of 2000".
2. Name's ⋯ menu → "Sort A-Z": after about 150 ms the rows are sorted, the
   arrow is on Name, and the toolbar's sort menu shows "Name A-Z". Then pick
   "Most hours" in the toolbar menu: the arrow moves to Hours.
3. With Name A-Z, type `Zz` over the first name and press Enter. The row
   stays first and "Re-apply" appears at the top left. Click it: the row
   leaves page 1 and focus stays on a cell in the grid, not lost. Then
   page 40: "Zz" is last.
4. Do the same with the keyboard: Tab to "Re-apply" and press Enter. Focus
   must land back in the grid.
5. Type `ana` in the search box: only Anas, with "ana" marked in the cells;
   back on page 1.
6. Page 2: the row numbers go 51…100. Ctrl/Cmd+Z there does nothing if the
   last edit was on page 1. Back on page 1, Ctrl/Cmd+Z undoes it.
7. "+ Add record" (last row of the page): type a name. The row shows at
   once with "Re-apply"; after Re-apply it is where the sort puts it.
8. Filter bar: add a Status filter (e.g. Done). The rows and the chips
   follow, and the chip's × removes it.
9. Rows per page → 25: back to page 1, 80 pages.
10. Look at the toolbar's layout: the views are unstyled `sui-*` markup
    inside an EUI page; check that it is legible.
11. Dark mode was not looked at.

### Notes for batch 5

- `@onResolve`: add it to `ForwardedArgs` and to the template in
  `eui-sheet-search.gts`. A `'resolve'` change set goes through
  `search.apply` like any other (pending, `onChange`, shown at once).
- `fieldsFromSchema` maps only the v0.1 types. Batch 5's types (a keyword
  list → multiSelect, url/email) could get rules there.
- The undo rule of deviation 1 reads patch ids, insert `tempId`s, deletes and
  rejection ids. The `'resolve'` merge does not change which records an
  entry touches.
- Pending saves are tracked by promise identity; batch 5's async resolve
  in the sheet is separate from them.

### Batch 4: real input in Chromium (orchestrator, 2026-11-19)

The docs site was a production build served by `vite preview`. The checks ran on the "Sheet with EmberSearchUi" demo, the 14th grid on the page, using Playwright real input (clicks, typing, keys). Screenshot: `v02-b4-search-ui.png`.

- **Load:** the page shows "Showing 1 - 50 out of 2000", and the row numbers are 1–50.
- **Header sort:** focus the Name header, press Enter, choose "Sort A-Z". The rows come back sorted from the driver ("Ana 1", "Ana 1001", "Ana 1009", …), and the toolbar's sort select follows ("Name A-Z").
- **Stable rows and Re-apply:** with Name sorted, typing `Zz` and Enter in the first row leaves the row in place and shows "Re-apply". Clicking it moves the row off page 1, and focus stays in the grid.
- **Search:** searching `ana` gives "Showing 1 - 50 out of 249 for: ana", and the matches are highlighted with `<mark>` (12 in the rendered rows). Clearing the search brings back all 2000.
- **Paging:** page 2 shows row numbers 51–100 ("Showing 51 - 100 out of 2000"). On page 2, Ctrl+Z changes nothing, because the edited record is not on that page.
- **Off-page undo stays on its stack:** back on page 1, Ctrl+Z also changes nothing, because after Re-apply the "Zz" record sorts to the last page. Searching `Zz` shows that record alone. Ctrl+Z there gives "Ana 1" (the row stays, and "Re-apply" shows), and Ctrl+Shift+Z gives "Zz" again.

Not checked with real input: adding a record, the Status filter chips, rows per page, Firefox, Safari.
