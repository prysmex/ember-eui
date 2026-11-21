# `@ember-eui/sheet` v0.4: results

Results of the batches of `v04/README.md`, on branch `feat/sheet`, in the
order the user chose (D, then A, B, C). Each section says what was built,
what was verified (and how), and what was not.

## Batch D: load more (09)

Built 2026-11-20 on `995f3e5` (v0.3 complete), in this checkout. Design:
`v04/09-visible-range.md`. Its line references (`eui-sheet.gts:1400`)
predate 3c: the feature lives where V03C-DESIGN.md 7 puts it, a new pure
file `src/-private/visible-range.ts` and `virtualizationOptions` in
`src/-private/sheet/grid-options.ts`. No new module class, no change to
the component (570 lines, as before).

### What was built

- **API.** `SheetVisibleRange { first, last, count }` (`src/types.ts`,
  exported from `src/index.ts` next to `SheetSelection`) and the argument
  `onVisibleRangeChange?: (range: SheetVisibleRange) => void`.
- **`src/-private/visible-range.ts` (new, 45 lines, pure).**
  `toRecordRange({ start, stop }, rowModel, count)` is
  `rowModel.recordRange` over the visible grid rows: the first record at
  or after `start`, the last at or before `stop`, as positions in
  `@records`; group headers and add rows are skipped (both row models,
  flat and grouped); null when no record is in the window. `changed(previous, next)`
  compares `first`, `last` and `count`.
- **`virtualizationOptions`** stays `@cached`. Without the handler it is
  what it was: `undefined` without a frozen field, `{ overscanColumnCount }`
  with one (no `onItemsRendered` key). With the handler it adds
  `onItemsRendered`, a stable arrow field of the module, so the grid sees
  a new object only when the frozen count, the visible fields, the
  row-number column, the add-field column or the handler's presence
  changes.
- **Reporting** (`grid-options.ts`, the pattern of batch 5's
  `@onSelectionChange`): the core grid calls `onItemsRendered` after its
  render (`body.gts` `itemsRendered`, `afterRender`). The module maps
  `visibleRowStartIndex`/`StopIndex` to a record range with the row model
  of that render and keeps it (plain fields, nothing tracked); unless a
  report is already pending it schedules `reportRange` with `next`. The
  report clears the flag, returns if `isDestroying(this.sheet)` or
  `isDestroyed(this.sheet)`, skips a null range (headers only) and an
  unchanged one, and only then stores it and calls the owner. So the owner
  is called after render, at most once per run loop, never during a
  render, and can append to `@records` inside the handler.
- **The VR3 risk did not happen.** An append that does not move the
  window is reported with the new `count`: the core's `itemsRendered`
  modifier reads the grid's row count (`computeRowWindow` →
  `visibleRowCount`, tracked) and re-runs. No `watchRecords` fallback was
  added.

### Tests

`tests/integration/components/eui-sheet-visible-range-test.gts` (new),
200 records, `@height={{400}}`, 600 px wide:

- **VR1** the first render: one call, `{ first: 0, last, count: 200 }`
  with `last` the last row in view measured from the layout (rows that
  start between the sticky header and the scroller's client bottom, in
  screen px; the overscan row below it is rendered and not counted). No
  second call after another frame.
- **VR2** with and without the add row (`@canInsert`), 12 fields: a jump
  to the bottom gives `last: 199`; a horizontal-only scroll (700 px) makes
  no call; back up 30 rows and down to the end in 3 px scroll steps: the
  steps report, the last call at rest is `last: 199`, `first` is the top
  row in view, and no two consecutive calls are equal.
- **VR3** an owner whose handler appends 50 records synchronously when
  `last >= count - 3`: no render assertion; a cell focused near the end,
  then ArrowDown until the load: one load, `count: 150` reported, the
  focused cell (the one ArrowDown reached) still `document.activeElement`,
  the scroll unchanged one frame later, no second load. Then an append
  from outside (to 200) that keeps the window: exactly one call, with
  `count: 200`, focus and scroll unchanged.
- **VR4** three groups of 10 (header, 10 records, add row each): at the
  top `first: 0` and `last` the last record row in view; with the second
  header at the top `first: 10`; at the end `last: 29` (not the add row).
- **VR4b** 30 collapsed headers with nothing loaded, then a group of 10:
  no call while only headers are in view; at the end exactly one call,
  with positions in `@records`: `last: 9`, `count: 10`, and `first` the
  first record row in view, from the layout.
- **VR5** 12 fields, `@frozenFields={{1}}`: one call with `first: 0`;
  the cells of a rendered row are the same number as without the handler
  (every column), also after a scroll right; with `@frozenFields={{0}}`
  the columns are virtualized again.
- `tests/unit/visible-range-test.ts` (new): **VR6** `toRecordRange` over
  a grouped model with a collapsed, empty group and add rows (all rows;
  across groups; from an add row; a header then a record; an add row and
  headers only: null; a collapsed header only: null; the last add row
  only: null), the flat model with the add row in view, no records;
  **VR7** `changed`.

The IDs `VR1`-`VR7` were unused (`grep -rn "VR[0-9]" packages/sheet/tests`).

Suite: **592 tests, 592 pass** (584 + 8), one full run, no retries
needed.

### Checks (before the code commit, on the same tree)

- `pnpm lint:types`: no error.
- The tests' `ember-tsc --noEmit -p tsconfig.eslint.json`: the 19
  baseline errors and no other (`diff` against
  `3c-checks/baseline-tests-tsc.log` empty).
- `eslint` and `prettier --check` on the six changed code and test files:
  clean.
- Owner gate: `37 module classes`, OK.
- `node scripts/generate-api-docs.mjs`: "updated 0 of 117 pages";
  `--check` passes.
- Before the docs commit also: `pnpm lint:js` (eslint on the whole
  package) clean, `pnpm lint:css` clean, `pnpm eui:check` at the root
  passes (exit 0), `node --test site/lib/*.test.mjs` 8 pass.
- `packages/core/src` unchanged; no existing test edited; no dependency
  added.

### Deviations

1. **The reporter lives in `grid-options.ts`**, not in a hosted module of
   its own: V03C-DESIGN.md 7 puts 09 in `virtualizationOptions`, and the
   state is three plain fields and two arrow functions. No component
   change was needed.
2. **The range is computed when the grid reports** (with the row model of
   that render) and the latest one is reported in the next run loop
   (`next`, as `@onSelectionChange` since 5f), not inside the grid's
   `afterRender`.
3. **VR3 drives the load with ArrowDown**, not a programmatic scroll
   after focusing: a programmatic grid scroll that changes the core's
   window blurs a focused single cell in the test runner with or without
   this feature (below, "Found"), so it cannot test this feature's
   "focus stays". The append itself keeps focus (VR3's outside append and
   the real-input run).
4. **VR4b and VR6/VR7 are additions** (headers only on screen; the unit
   test split in two IDs). VR5 checks "the frozen overscan is unchanged"
   as the number of rendered cells per row with and without the handler;
   the FZ tests pass unchanged.
5. **The demo keeps its own fetch cursor** (`fetched`), not
   `@records.length` (the fix commit). **It also guards inserting**:
   `@canInsert` is false until all 1,000 records are loaded (an add row at the end of a half-loaded list is
   odd); the docs say so.

### Found (not changed, outside this batch)

- In the test runner, focusing a single cell and then scrolling the grid
  programmatically far enough to change the core's rendered window leaves
  focus on `<body>`: Glimmer's list update moves the focused row node
  (`ListBlockOpcode.moveItem`, the stack of the `focusout`), Chrome blurs
  a moved node, and `focus.parkFocus` refocuses only a range (anchor not
  equal to head) — the P7 note in V03-RESULTS.md. Reproduced without
  `@onVisibleRangeChange` (a throwaway test, removed). With real wheel
  input on the docs site the clicked cell kept focus while the window did
  not move, and lost it once it was scrolled out of the rendered rows
  (virtualization), as before.

### Real input in Chromium

Production docs build of this checkout (the sheet's `pnpm build`, then
`site`'s `pnpm build`; the other packages' `dist` from earlier batches;
turbo not used), served with `vite preview`, Playwright's Chromium
(headless, 1300 × 900), real `page.mouse.wheel`, `page.mouse.click` and
right-clicks on d23 (`/docs/sheet/docs/sheet`). The final run is on the
demo as committed in the fix commit (below). No page errors and no
console errors.

- First render: "100 of 1000 loaded in 1 page · records 1–11 in view"
  (so `{ first: 0, last: 10, count: 100 }`), no fetch.
- A right-click on record 3 and the row menu's "Delete record": 99
  records, row 3 shows Employee 4, no fetch.
- 21 wheel steps of 120 px: the first fetch started at scrollTop 2520
  with "records 71–81 in view" (`last` 80, the first report at or past
  `count - 20` = 79), the progress bar shown.
- While it loaded, a real click on Name of grid row 75 focused it. When
  the page arrived (before the script's next wheels: the 800 ms had
  passed; those wheels went up and down by the same amount, so they show
  nothing): scrollTop still 2520, focus still on that cell, one fetch.
- Wheeling on to the grid's end while each next page loaded (the loop
  keeps wheeling until the scroller is at its maximum, which it reaches
  within a few steps of a fetch starting, well inside the 800 ms): exactly
  **9 fetches for the 9 pages after the first**, each at the first report
  with `last >= count - 20`. That count, not the per-step comparison the script also
  made (a second fetch would also be +1 per step), is the evidence that
  no fetch started while one was pending. At the end: "1000 of 1000
  loaded in 10 pages · records 990–999 in view" (999 records:
  `last: 998` = `count - 1`), scrollTop at its maximum, the add row
  shown, the page itself not scrolled.
- Reading every row afterwards (moving the scroller, no input): 999
  distinct codes, none twice, E-0003 absent.
- A delete of the last record once everything was loaded, then more
  wheels at the end: still 9 fetches.
- **Bug found and fixed (third commit).** The committed demo fetched from
  `store.records.length` and derived "more to load" from it, so a delete
  made the next page start one record early (a record twice) and, after
  everything was loaded, made it fetch again. Found by the advisor review
  from the code, not by the run (the earlier runs deleted nothing). The
  demo now keeps its own `fetched` count, and `docs/sheet.md`'s snippet
  and text say to keep your own cursor. The run above is after the fix.
- An earlier run wheeled on past the grid's end while a page was loading:
  the wheel chained to the page (normal browser scroll chaining), the
  demo scrolled out of view and the later wheels missed the grid. The
  script was changed to stop wheeling at the grid's end.
- Screenshots (not in the repo), of the final run:
  `/tmp/claude-0/-home-user-ember-eui/87cd9e5a-212c-54c3-9d47-30ac398aebd2/scratchpad/v04d/`
  `d23-first.png`, `d23-loading.png`, `d23-after-load.png`,
  `d23-end.png`. The agent looked at an earlier run's `d23-loading.png`
  (progress bar, focused row, the footer line), not a person.

### Open items

- **The core reports only when its overscanned window changes** (and on
  a row count or size change). Near either end the window is clamped, so
  a scroll that moves only the visible edge by a row can go unreported
  until the window moves; at rest at the bottom `last` was `count - 1` in
  every test and in the real run. For "near the end" with a margin this
  does not matter; an owner that shows the range exactly may lag a row.
- **Scroll chaining at the end** of a half-loaded list scrolls the page
  while the next page loads. The sheet sets no `overscroll-behavior`; an
  app can.
- **The EmberSearchUi connector** does not forward
  `@onVisibleRangeChange` (the design calls appending pages there a
  follow-up).
- **Focus after a scroll that moves the focused row node** (Found,
  above): a single focused cell is not refocused; pre-existing.
- **Not verified:** the resize path (a call when the grid's height
  changes is claimed by the docs from the core's code, not tested); "the
  selection stays" on an append (only focus and scroll were checked); the
  suite ran once in full (no repeat runs).
- Not checked: Firefox, Safari, touch scrolling, a screen reader, dark
  mode; the site's testem suite.

### Files

- New: `packages/sheet/src/-private/visible-range.ts`;
  `packages/sheet/tests/integration/components/eui-sheet-visible-range-test.gts`;
  `packages/sheet/tests/unit/visible-range-test.ts`;
  `packages/sheet/docs/sheet-demo/d23-load-more.md`; this file.
- Changed: `packages/sheet/src/-private/sheet/grid-options.ts`
  (`virtualizationOptions`, the reporter); `packages/sheet/src/types.ts`
  (`SheetVisibleRange`, the argument); `packages/sheet/src/index.ts` (the
  type export); `packages/sheet/docs/sheet.md` (Arguments row, the
  owner's table, a new section "Loading more as you scroll");
  `packages/sheet/README.md` (Arguments row, a paragraph with the handler;
  prettier-clean). `docs/sheet.md` and the demo were left in the docs'
  existing style (not prettier-formatted, as before).

### Commits

| Commit | Holds | Suite |
| --- | --- | --- |
| `5e4204a` | `SheetVisibleRange`, `@onVisibleRangeChange`, `visible-range.ts`, `virtualizationOptions` and the reporter, VR1-VR7 | 592 / 592 |
| `5651beb` | docs (`sheet.md`, README, d23), these results | (no code; 592 carried over) |
| the fix commit | d23 and the docs' snippet keep their own fetch cursor (the delete bug above); these results corrected | (no code; 592 carried over) |

Three commits, one more than the brief's "one or two": the demo bug was
found after `5651beb`, and commits are never amended on this branch.

## Batch A: presentation and menus (01-05)

Built 2026-11-20 on `3c887a2` (batch D done), in this checkout. Designs:
`v04/01-fit-width.md` to `v04/05-copy-with-names.md`. Their line
references predate 3c; the features live where V03C-DESIGN.md 7 puts
them. The component grew from 570 to 605 lines (the full-screen wiring,
its body class, the `<:recordFooter>` pass-through, one listener).

### What was built

- **01 Fit a column to its content.** "Fit to content" in the header
  menu, a double-click on a column's resize edge, `api.fitField(fieldId)`
  and `api.fitFields()`. `src/-private/fit-width.ts` (new, 92 lines):
  `fieldWidth(ctx, field, { cell, header }, chrome)` (pure, with the
  measures passed in), `textMeasure(font)` (one canvas), and
  `resizerColumnId(target)`. The width is the larger of the header label
  plus its chrome (padding, border, the sort arrow when shown, and the
  room of the drag icon and menu button, which collapse until hover or
  focus, with the 2 px gap each gets when it shows) and
  the widest of the first 2,000 loaded cells plus the cell's padding (and
  28 px for a type with an opener), clamped to 80-480 px; the fonts and
  paddings are read from a rendered header and cell at the moment of the
  fit (layout px: `offsetWidth` and computed style, not rects).
  `FieldType.contentWidth(value, field, measure, context)` is on
  checkbox (24), rating (`max` × 18), singleSelect (one chip),
  multiSelect, linkedRecord (chips), user (avatar and name) and
  attachment (24 px thumbnails or an icon and the name, at most 120);
  the list types count three items and then "+N", as their cells show
  (`src/core/field-types/content-width.ts`, internal). The width reaches
  the grid the only way it can (the core keeps resized widths privately
  and has no setter): a new `columns` array with the width as
  `initialWidth`, through `@onFieldWidthChange` (the owner's
  `@fieldWidths`), or without it through `keptWidths` and a tracked
  `fitEpoch` that only a fit bumps. The double-click is one capture
  `dblclick` listener on the wrapper (`gridColumns.onResizerDoubleClick`).
- **02 Full screen.** `@fullScreen`, `@onFullScreenChange`, the block
  API's `isFullScreen` (a getter, so `blockApi` does not depend on it)
  and `setFullScreen(on)`, `api.setFullScreen(on)`.
  `src/-private/sheet/full-screen.ts` (new module `SheetFullScreen`):
  `isOn`, `set`, `gridHeight` (`'100%'` while on), `lockPage` (a modifier
  on the wrapper: the body's overflow and the grid's own full-screen body
  class while on, both undone on exit and on destroy; the outlines and
  the fill handle re-placed through `layoutTick`) and `endOnEscape`.
  `euiSheet--fullScreen`: fixed, inset 0, z-index 998 (the grid's own
  full-screen level), the plain background, 8 px padding, a flex column
  in which the grid box takes the room between toolbar and footer.
  Escape on a cell ends it only after an open editor, menu, field editor
  or shortcut list, a lifted column, the copy mark and a range
  (`keys.ts`, after the range collapse).
- **03 `@fieldActions`.** `SheetFieldAction` in `src/types.ts`, exported
  from the package; the items inside `headerMenu.fieldMenuItems`, after
  the sheet's items and before "Delete field";
  `euiSheetFieldAction-<id>-<fieldId>`. `onSelect` runs through
  `headerMenu.afterClose`, which puts focus back on the field's menu
  button first (below, deviation 4). "Fit to content" uses it too.
- **04 `<:recordFooter as |record sheet|>`.** `record-shells.gts`: an
  `@hasFooter` argument and a `footer` block inside
  `euiSheetRecord__footer` (a divider), in the flyout and the modal; the
  component passes `@hasFooter={{has-block "recordFooter"}}` and a
  `<:footer>` that yields `expandedRecordValue` and `blockApi` to
  `recordFooter`. Nothing in `expanded.ts`. An Escape in a text box of the
  block stops at the footer (the flyout's window listener and the
  modal's own would close the record); the record form's keys are on its
  boxes, so the block's other keys are its own.
- **05 Copy with field names.** The row-menu item `copyWithNames`, in
  Copy's group, with the new `@copyWithFieldNames` (deviation 2):
  `clipboard.copyRowsWithNames` writes `toTsv([headerLine(fields),
  ...rowsMatrix(records)])` with the same `writeClipboard`;
  `headerLine(fields)` (`label ?? id`) is exported from the core.
- **Messages:** `fitToContent`, `fitAllFields`, `enterFullScreen`,
  `exitFullScreen`, `copyWithFieldNames` (`euiSheet.<key>`).

### Tests

New files only; no existing test changed. IDs checked first: `FW`, `FS`,
`FA`, `CN` were unused; `RF` is taken (the expanded record's RF1-RF6 and
the polish tests' RF1-RF2), so the record footer's are **RFT**.

- `eui-sheet-fit-width-test.gts`: **FW1** (gate) a double-click on the
  resize edge (two presses, two releases, two clicks, then dblclick)
  emits the fitted width once and the grid shows it; a press that moves
  nothing emits nothing. **FW2** "Fit to content": no cell cut, then a
  very long value: 480. **FW3** no handler, fields with `width`: the
  fit and an earlier drag of another column both survive the fit and a
  later new column. **FW4** a checkbox fits to its header label. **FW5**
  `api.fitFields()`: one call per visible field, each shown; a short
  field gets 80. **FW6** a single select: the chip ends before the
  opener, its label whole. **FW7** the item joins a menu that is there;
  the first field of a bare sheet still has no menu; the API fits it; an
  unknown id does nothing.
- `tests/unit/fit-width-test.ts`: **FW8** `fieldWidth` with a fake
  measure (widest cell, min, max, the header winning, the id as header,
  the opener, rounding up); **FW9** a type's `contentWidth`, `format`
  otherwise, only the first 2,000 records; **FW10** the built-in
  `contentWidth` of checkbox, rating and multiSelect (with "+N").
- `eui-sheet-full-screen-test.gts` (the test container's two transforms
  are lifted, so `position: fixed` fills the window): **FS1** the
  window, the grid ending at the footer, the body's overflow, back in
  the page; **FS2** Escape: an editor, the row menu, the copy mark and a
  range each first, then full screen ends, focus stays; **FS3**
  controlled and local; **FS4** the row menu (an item works), a select
  panel and the expanded record (after its slide-in; its arrows work)
  on top, `elementFromPoint` at their centre; **FS5** the body restored
  on exit and destroy; **FS6** focus, the range and its outline kept
  through enter and exit; **FS7** the header menu, the field editor and
  the shortcut list on top, Escape in the header menu closes only it;
  **FS8** a fixed `EuiHeader` below the sheet, the toolbar on top, the
  record's flyout at the top (in the test; on the site it starts 49 px
  down, below), all undone on exit.
- `eui-sheet-field-actions-test.gts`: **FA1** on every field (the first
  field gets a menu from it), `onSelect` with that field; **FA2**
  `isDisabled` per field; **FA3** order, before "Delete field", Delete
  last; **FA4** focus on the menu button when `onSelect` runs, and focus
  that `onSelect` moves elsewhere stays there past the popover's 250 ms
  closing; **FA5** without it, as before.
- `eui-sheet-record-footer-test.gts`: **RFT1** (flyout and modal) the
  block with the record and the block API, after the hidden fields,
  inside the shell, a divider; **RFT2** the arrows re-render it; **RFT3**
  (both shells) typing types there, no editor, no change set, Escape in
  the input keeps the record, Escape on the block's button closes it
  (checked to fail with the Escape guard removed); **RFT4** no footer
  without the block.
- `eui-sheet-copy-names-test.gts`: **CN1** one row (a label-less field
  copies its id), next to Copy, focus back; **CN2** two checked rows, in
  order; **CN3** a tab, a line break and a quote in labels are quoted;
  **CN4** without the argument the menu is as before.

Suite per commit (a full run on a build of that commit's code, the other
batch A work set aside): 602, 609, 614, 620, 624, 625, 625, all passing.
For 01, 02 and 04 the full run was on the build before a lint and
format tidy (01: `grid-columns.ts` reformatted and a `settled()` dropped
from FW3; 02: a type-only import in the FS test; 04: a `settled()`
dropped from RFT3); after the tidy only that feature's module was
rebuilt and rerun (FW 10/10, FS 7/7, RFT 6/6), not the whole suite. In
the run for 03, FS1 failed once (the grid's body still 200 px one frame
after the toggle: the grid measures in a resize observer) and passed
alone; it now waits for the measure (in the 03 commit), and the next
runs passed.

### Checks (before each code commit, on its tree)

- `pnpm lint:types`: no error. The tests' `ember-tsc -p
  tsconfig.eslint.json`: the 19 baseline errors and no other (one new
  error in a test import was fixed before the 02 commit).
- `eslint` and `prettier --check` on each commit's changed files: clean
  (after fixes: two `settled()` after a helper, formatting).
- Owner gate: OK (37 module classes, 38 from 02 on).
- `node scripts/generate-api-docs.mjs --check`: passes for 01, 03, 04,
  05 and the header fix; not run separately for 02 (the generator reads
  no sheet source; it passed on the next commit's tree, which contains
  02).
- Before the docs commit: `pnpm lint:js`, `pnpm lint:css` (sheet),
  `pnpm eui:check` (root), `node --test site/lib/*.test.mjs`: below.
- `packages/core/src` unchanged; no dependency added.

### Deviations

1. **"Fit to content" is not on every field**: it joins a header menu
   that has other items. VW6 pins that the first field of a bare sheet
   has no menu button at all; an always-present item would create one.
   Such a field is fitted by the double-click or the API.
2. **"Copy with field names" is opt-in, `@copyWithFieldNames`** (a new
   argument, default false). rows-test (RW, around lines 413, 448, 552,
   563) and VP1 pin the row menu's exact items, and the README's "every
   addition is optional; without it the sheet behaves as in v0.3". This
   is a public argument the design did not list: **the user's decision**
   whether it should be on by default (that would mean editing those
   tests).
3. **A bare sheet's kept width now wins over `field.width` and
   `@fieldWidths`** (`keptWidth ?? givenWidth`, in `columns` and
   `frozenWidth`). Before, a given width won, so a fit (or a drag) on a
   field with a `width` snapped back whenever the columns were rebuilt.
   With `@onFieldWidthChange` nothing changes (no kept widths). A bare
   sheet whose app changes `@fieldWidths` later does not override a
   width the user resized.
4. **A press on the resize edge that moves nothing emits nothing**
   (`onColumnResize` returns when the width equals the header's shown
   width, within 0.5 px). The core calls `setColumnWidth` on every
   mouseup, so each click of a double-click emitted the unchanged width;
   FW1 asks for one call.
5. **Focus after a header-menu item.** The popover leaves focus on its
   panel and, once the panel is removed after 250 ms, on `<body>`
   (probed); it never returns it to the menu button. So `afterClose`
   focuses the field's menu button in a `next()` (only when focus is on
   the body or in a popover panel), then runs `onSelect`; "Fit to
   content" uses it too. The sheet's other header items (Edit, Group by,
   Filter, ...) are unchanged.
6. **The full-screen module is `src/-private/sheet/full-screen.ts`**
   (a module class, under the owner gate), not `src/-private/`.
7. **Full screen also adds the grid's own full-screen body class**
   (`euiDataGrid__restrictBody` from the core's
   `euiDataGridFullScreenStyles`), found with real input: the docs
   site's fixed `EuiHeader` (z-index 1001) covered the toolbar and the
   exit button. The design took that to be the grid's own behaviour; the
   grid's own lowers a fixed EUI header to 997 and is meant to move
   flyouts to the top (on the site a flyout's own inline offset still
   wins; the docs promise only the header). A separate commit after 05; FS8.
8. **Escape that ends full screen is the sheet's, on a cell** (`keys.ts`,
   the fall-through after the range collapse), not a bubbling listener
   on the wrapper: a header, the toolbar and app controls keep Escape.
9. **Escape during a fill-handle drag or a row drag** is unaffected by
   step 5: both listen on `document` in the capture phase and stop the
   event, so it never reaches the cell's handler (checked in the code,
   `filling.ts` and `row-drag.ts`; not tested in full screen).
10. Smaller: `contentWidth` takes a fourth `context` argument (a select
   needs the record for its options); singleSelect has one too (FW6
   needs the chip's padding); chips count three and "+N" as the cells
   do; the 8 px padding of the full-screen wrapper; `fitAllFields` is
   only a message (the design lists it; there is no built-in "fit all"
   item).

### Real input in Chromium

Production build of this checkout (the sheet's `pnpm build`, then
`site`'s `pnpm build`), served with `vite preview`, Playwright's Chromium
(headless, 1300 × 900), real `page.mouse` and `page.keyboard`, clipboard
permissions granted, on the new demos d24 ("Full screen and column
tools", with `localRecords`' field handlers) and d25 ("Comments in the
expanded record") on `/docs/sheet/docs/sheet`. The final run is after
the header fix. No page errors, no console errors.

- **Fit from the menu:** Notes 120 px with 5 cut cells → "Fit to
  content" (hover, the menu button, the item) → 397 px, no rendered
  Notes cell cut; focus on Notes' menu button afterwards.
- **Double-click on the resize edge (FW1 held):** the resizer's box is
  0 px wide (the core's style has no width; its hit area is the 3 px
  `::after` strip on the column's edge), so the double-click is on the
  edge itself (`elementFromPoint` there is the resizer). Site (a select)
  110 → 292 px; no chip cut and none overlapping its opener; the longest
  label "Querétaro (north plant, building 3)" shown whole. A first try
  at the resizer's box centre (8 px right of the edge) hit the next
  header and fitted nothing: that is the core's hit area, not the
  feature.
- **"Fit all fields"** (`api.fitFields()` from d24's toolbar; a second
  run, on a fresh page): Item 120 → 84, Site 110 → 292, Notes 120 →
  397, Quantity on hand 90 → 171 (its header was cut before), Unit cost
  90 → 115, Audited 90 → 107; no rendered cell cut, no chip over its
  opener, no header label cut, also while hovering Quantity on hand,
  Unit cost, Audited and Item (Audited's cells were scrolled out of the
  rendered columns, so only its header was checked). The first version
  of this run found the hover cut: 3 px on each hovered label (the 2 px
  gaps, above); fixed in `4cdd90a`, then this run.
- **`@fieldActions`:** Quantity's menu: Hide column, Move left, Move
  right, Fit to content, Edit field, Duplicate field, Insert left, Insert
  right, Summarize, Delete field. "Summarize" wrote "Quantity on hand:
  9860" in the footer; focus back on the menu button; disabled on Notes.
- **Full screen** from the toolbar button: the wrapper 0, 0, 1300 × 900,
  the body's overflow hidden, the button "Exit full screen" and on top,
  the site header at z-index 997 (1001 again after exit), the grid's
  body 820 px. Each opened on top (`elementFromPoint` at its centre) and
  worked: the row menu (Copy with field names, below), the select panel
  (Monterrey → Guadalajara with ArrowDown, Enter), the header menu and
  the field editor (Item renamed to "Part" and saved), the expanded
  record (Space; the next arrow went from Part 006 to Part 007; Escape
  closed it and full screen stayed), the shortcut list (Ctrl+/; Escape
  closed it, full screen stayed). The record's flyout starts 49 px down
  on the site (its own fixed-header offset, inline, wins over the body
  class's `top: 0`); in the test (FS8) it starts at 0; not changed.
- **Escape order:** an editor (typed "x") closed, still full; Ctrl+C,
  the copy mark, Escape cleared it, still full; Shift+ArrowDown twice
  (3 cells), Escape collapsed it to one, still full; Escape ended full
  screen, focus still on Notes row 1. The page: the body's overflow
  back to "", `scrollY` 18950 before and after, the sheet's box the
  same as before (289, 258, 971 × 384), the body class removed.
- **Record footer (d25):** Space on a cell, a click in the comment box,
  "Looks good, ship it" typed (no field editor opened), Enter posted it
  (the list: Luis's comment, then "You: Looks good, ship it"); "draft"
  then Escape in the box: the record stayed open; the next arrow showed
  the next record's title and its two comments; Escape on a record box
  closed it.
- **Copy with field names** (read back with `navigator.clipboard`): on
  row 3, `Item⇥Site⇥Notes⇥Quantity on hand⇥Unit cost⇥Audited` then the
  row; with rows 2 and 5 checked, the names then those two rows, in
  order; focus back on the cell.
- Screenshots (not in the repo):
  `/tmp/claude-0/-home-user-ember-eui/87cd9e5a-212c-54c3-9d47-30ac398aebd2/scratchpad/v04a/`
  `fit-menu.png`, `fit-after-menu.png`, `fit-after-dblclick.png`,
  `field-action-menu.png`, `full-screen.png`, `fs-row-menu.png`,
  `fs-select.png`, `fs-field-editor.png`, `fs-record.png`,
  `fs-shortcuts.png`, `after-exit.png`, `record-footer.png`; the
  script's output in `results.json`. The agent looked at `full-screen.png`
  (before and after the header fix), `fs-select.png`, `fs-record.png` and
  `record-footer.png`, not a person.

### Open items

- **Deviation 2 is the user's decision** (on by default would edit
  rows-test RW and VP1). So are deviations 3 and 4, which change v0.3
  behaviour: a bare sheet's kept width over a given one, and no
  `@onFieldWidthChange` for a press that moves nothing.
- **The EmberSearchUi connector** (`EuiSheetSearch`) forwards none of
  `@fullScreen`, `@onFullScreenChange`, `@fieldActions`,
  `@copyWithFieldNames` or `<:recordFooter>` (as `@onVisibleRangeChange`
  in batch D). Its toolbar block passes the sheet's block API on, so a
  full-screen button there works with the local state.
- **Fitting measures loaded records only** (the first 2,000), at the
  moment of the fit; a font that loads later is not re-measured.
- **The resize edge's hit area is 3 px** (the core's style gives the
  resizer no width): the double-click needs a precise pointer; the menu
  item and the API do not.
- **Full screen and Tab:** no focus trap (as designed): Tab can leave
  the sheet for the page behind.
- **A fixed header that is not `EuiHeader`** at z-index 998 or more
  still covers the full-screen sheet (the docs say so).
- **Not verified:** a touch device, Firefox, Safari, dark mode, a screen
  reader; `@fieldActions` with a real app dialog (only a focus move was
  tested); the header's hover state in a test (CSS `:hover` cannot be
  driven in the runner, so the hover-gap fix below is checked by real
  input only); fitting with `@frozenFields` (the frozen layout follows a new
  width, as a drag-resize, but no test fits a frozen field); the suite
  ran once per commit (no repeat runs).

### Files

- New: `packages/sheet/src/-private/fit-width.ts`,
  `packages/sheet/src/-private/sheet/full-screen.ts`,
  `packages/sheet/src/core/field-types/content-width.ts`, the five
  integration test files and `tests/unit/fit-width-test.ts`,
  `packages/sheet/docs/sheet-demo/d24-full-screen.md`,
  `packages/sheet/docs/sheet-demo/d25-record-footer.md`.
- Changed: `src/components/eui-sheet.gts`; `src/-private/sheet/`
  `grid-columns.ts`, `header-menu.ts`, `api.ts`, `keys.ts`,
  `clipboard.ts`, `row-menu.ts`; `src/-private/record-shells.gts`,
  `row-menu.gts`, `styles.ts`; `src/core/types.ts`, `messages.ts`,
  `tsv.ts` and seven built-in types in `src/core/field-types/`;
  `src/types.ts`, `src/index.ts`; `docs/sheet.md` (Arguments, the
  owner's table, the blocks, "Fit to content", a new "Full screen"
  section, the API table, Records, Fields, Expanded record);
  `README.md` (Arguments, blocks, full screen and fit, the API table,
  Records, Fields, Expanded record, messages, Limits without
  "fullscreen"; prettier-clean). `docs/sheet.md` and the demos are in
  the docs' existing style (not prettier-formatted, as before).

### Commits

| Commit | Holds | Suite |
| --- | --- | --- |
| `fa2dc2b` | 01 fit to content | 602 / 602 |
| `55f8f4c` | 02 full screen | 609 / 609 |
| `5ebb56d` | 03 `@fieldActions` (and FS1 waits for the grid's measure) | 614 / 614 |
| `0083c8f` | 04 `<:recordFooter>` | 620 / 620 |
| `f59491c` | 05 copy with field names | 624 / 624 |
| `10a0121` | full screen puts a fixed EUI header below it (FS8) | 625 / 625 |
| `129cfa6` | docs, d24, d25, these results | (no code; 625 carried over) |
| `4cdd90a` | a fit leaves room for the header's 2 px hover gaps | 625 / 625 |
| the last docs commit | docs corrections (README "Full screen" section, "Fit to content" in the menu lists, no promise about flyouts' top), these results corrected | (no code) |

Two commits in this range are the main session's, not this batch's:
`fdd07dc` (the import screen's design, `v04/10-import-screen.md`, and
`v04/README.md`: feature 10, batch E, the user's decisions 5 and 6;
nothing of batch A changed) before `fa2dc2b`, and `3979f3d` (the
readiness plan, `internal/spikes/sheet/READINESS.md`) between `55f8f4c`
and `5ebb56d`.

## Batch B: CSV in and out (06, 07)

Built 2026-11-21 on `d6b7720` (batch A done), in this checkout. Designs:
`v04/06-csv-export.md`, `v04/07-csv-import.md`, and the section "Changes
to feature 07 (batch B), made when B is built" of
`v04/10-import-screen.md` (with its "Matching" rules). Nothing else of
feature 10 was built. The pure parts are in `src/core/csv.ts` (new) and
`src/core/delimited.ts` (new, internal); `appendRows` is in the
clipboard module next to the paste it reuses. The component did not
change (605 lines).

### What was built

- **06 `toCsv(ctx, records, fields, { delimiter = ',', headers = true,
  escapeFormulas = true })`.** `ctx` is `summarize`'s `{ types, messages
  }`. The cells are `rangeMatrix`'s (the type's `copyText`, else
  `format`), the header line `headerLine` (label, else id). RFC 4180
  quoting: a cell with the delimiter, `"`, `\r` or `\n` is quoted, `"`
  doubled; lines joined with `\r\n`, none after the last. With
  `escapeFormulas` a text starting with `=`, `@`, a tab or `\r`, or with
  `+`/`-` and not matching `/^[+-]?[\d.,\s]+%?$/`, gets a leading `'`,
  escaped first and then quoted; header labels go through the same rule.
  The rule is a private function (not exported).
- **07 `parseCsv(text, { delimiter? })`.** A leading U+FEFF is dropped.
  Without `delimiter`, the first line is scanned up to the first line
  break outside quotes (a `"` toggles), counting `,` `;` and tab; the most
  frequent wins, `,` on a tie or when none appears. The reader is
  `parseTsv`'s, moved to `src/core/delimited.ts` as
  `parseDelimited(text, delimiter)` (deviation 1); `parseTsv` is now
  `parseDelimited(text, '\t')` and its tests (U2, U3, Q…) pass unchanged.
- **07 `importMatrix(matrix, fields, { headers = true, mapping? })`** →
  `{ rows, fieldIds, unmatched }`. Columns are scanned left to right over
  the widest of the header line and the data lines. The fields `mapping`
  names (known ids only; a field mapped twice keeps its first column) are
  taken first; every other column goes to `matchHeader`'s field unless it
  is taken (then it is unmatched: a field takes at most one column, the
  first). Without `headers`, the columns go to `fields` by position
  (deviation 2). `unmatched` lists the header texts of the header line's
  dropped columns. `rows` has one text per kept column, in file order; a
  short line gives a short row (no `''` padding, so `@newRecordValues`
  is not overwritten), and lines whose cells are all blank are dropped
  (deviation 3).
- **`api.appendRows(rows, fieldIds, { fields? })`** (`SheetApi`,
  `src/types.ts`; `clipboard.appendRows`, wired in `api.ts`). It returns
  `false` without `canInsert`, without rows, or when no column has a
  field. The context fields are, per column, `options.fields`' field of
  that id, else `@fields`'/`@hiddenFields`' (`fields.allFields`); a column
  with neither is removed from every row. Then exactly the add row's
  paste: `planPaste` (with `@onResolve`) or `pasteMatrix`, anchored at
  `records.length`, column 0, with `nextTempId`; grouped, with
  `pasteInsert(-1)` (the last record's group: its values and
  `groupKey`). The emitted change set is the paste's (source `'paste'`,
  the inserts chained after the last record, rejections for the new
  rows' temp ids), with `touched` `[]` and no selection or focus change;
  an open editor is committed first, as `insertOne` does. The only
  addition is `@newRecordValues` (deviation 4).
- **Batch E's three additions** (below).

### The three additions for batch E

1. **`appendRows(rows, fieldIds, { fields })`.** `fields` win over
   `@fields` by id, for reading only: an id `@fields` does not have yet,
   or a per-column copy (`{ ...field, dateOrder: 'mdy' }`,
   `{ ...field, decimalSeparator: ',' }`). Nothing stores them; the
   inserts are keyed by field id. **The resolve path needed a change to
   honour this**: `resolve.finishResolve` built its context from
   `fields.allFields` and `resolveCells` skips a cell whose field it does
   not find, so a user or linked-record column of a field given only in
   `fields` lost its resolved value silently. `startResolve(plan, entry,
   fields?)` now keeps the call's fields on the `PendingCall`
   (`fields?`), and `finishResolve` puts them before `allFields`. APR6's
   last part fails without it (checked by removing the argument:
   "Cannot read properties of undefined (reading 'patches')", no resolve
   change set).
2. **`importAliases?: string[]` on `EuiSheetField`** (`src/core/types.ts`).
3. **`matchHeader(header, fields)` → `{ field, by: 'alias' | 'label' |
   'id' } | null`, and `normalizeHeader(text)`**, both exported from
   `@ember-eui/sheet/core`. `normalizeHeader`: NFD with the combining
   marks removed (so `ñ` is `n`), lower case, `_` and `-` as spaces,
   whitespace runs as one space, trimmed. `matchHeader` tries every
   field's aliases, then every label, then every id (the first field in
   `fields` wins within a pass, so an alias beats another field's
   label); an empty or separator-only header matches nothing. It does not
   know which fields are taken: `importMatrix` keeps "a field takes at
   most one column, the first", and batch E's `matchColumns` should do
   the same around it (the saved mapping first, as `importMatrix`'s
   `mapping`). `normalizeHeader` is exported because batch E's mapping
   `signature` is "the file's normalised header line".

### Tests

New files; no existing test changed. IDs checked first (`grep -rnoE`):
`CI` and `CX` were unused; **`AR1`-`AR9` are taken** (the add row's, in
`eui-sheet-rows-test.gts`), so the append tests are **APR1-APR8**.

`tests/unit/csv-test.ts`:

- **CX1** text, number, date (ISO) and multi-select (labels, quoted for
  their `, `) with a header line; a label-less field headed by its id;
  no records gives the header only. **CX2** a comma, a quote, `\n` and
  `\r\n` quoted; a `;` not quoted with `,`. **CX3** `;` quotes `a;b`, not
  `1,5`; a decimal-comma number stays unquoted. **CX4** `=SUM(A1)`, `@x`,
  `-a`, `+cmd|calc` and a leading tab get `'`; `-5`, a phone
  `+52 81 1234 5678` and a percent `-12.5%` do not; `a=b` does not; a
  header label `=Total` is escaped; `escapeFormulas: false`; escaped then
  quoted (`"'=a,b"`). **CX5** `headers: false` (and empty with no
  records). **CX6** an app type's `copyText`, and `format` without it.
- **CI1** quoted cells with commas and `\r\n` line breaks, `""`, `\r\n`
  line ends, one trailing empty line dropped (two: one kept), empty
  cells, a BOM, an unclosed quote as text, a mid-cell quote, `''`.
  **CI2** `,`, `;` (a decimal comma stays in its cell) and tab files;
  delimiters inside quotes not counted; a quoted line break in the
  header; one column; an explicit delimiter; a tie is `,`. **CI3** labels
  in other case and spacing, an id, an extra column in `unmatched`,
  `fieldIds` in file order; the same field three times (the first wins);
  a short line, a blank line, a cell past the header; an empty header;
  `headers: false` by position. **CI4** `mapping` with `null`; a mapped
  field not matched again by its own header; an unknown id and a field
  mapped twice; `mapping` without headers. **CI5** the round trip for
  `,`, `;` and tab, through `importMatrix`, equal to `rangeMatrix`'s
  texts (a comma, quotes and a line break in a cell, a negative number,
  a multi-select, empty cells); with escaping on, the escaped cell keeps
  its `'`. **CI6** `matchHeader`: an alias with `_` and spaces, with `-`
  and upper case, a label, accents both ways (`ano`, `AÑO` for `Año`),
  an id, an alias over another field's label, the `by` of each, empty and
  separator-only headers; `normalizeHeader`; `importMatrix` uses it and
  leaves a second alias of a taken field unmatched.

`tests/integration/components/eui-sheet-append-rows-test.gts` (an owner
applying with `applyChangeSet`, so a change set is applied at once):

- **APR1** three rows: `true`, one change set, source `paste`, three
  inserts with their values, indexes 2-4 and chained anchors; shown;
  focus and the selection unchanged; one Ctrl+Z removes all three.
- **APR2** `abc` for a number: `rejected` with the temp id and
  `notANumber`, the cell invalid and showing `abc`; undo.
- **APR3** a user field without options, `@onResolve`: the inserts at
  once without the pending cells, one call with both texts and temp ids;
  the answer patches one row and rejects the other (shown invalid); one
  undo removes both change sets.
- **APR4** `@canInsert={{false}}`: `false`, nothing emitted; no rows and
  only unknown ids: `false`; and (added with the docs, in the last
  commit) a read-only field is left out of the insert.
- **APR5** columns `code` (hidden), an unknown id, `qty`, `name`, `due`:
  each value in its field, the unknown column dropped, a short row with
  only its cells; then grouped by status: both rows get `status: 'Done'`
  (the last group's, over the file's `Open` and `Later`), its `groupKey`,
  anchored after its last record.
- **APR6** `fields` with a number field `size` not in `@fields`
  (decimal comma) and an M/D/Y copy of the D/M/Y `due`: `12,5` → 12.5,
  `1.234,5` → 1234.5, `11/19/2026` → `2026-11-19`; `@fields` and the
  field object unchanged, the cell shown D/M/Y; without `fields`, `size`
  dropped and `11/19/2026` rejected; a user field given only in
  `fields`, through `@onResolve`: requested and patched.
- **APR7** `@newRecordValues` (`name`, `qty`, `code`): `code` added,
  `name` from the file, `qty` absent on the row whose `qty` was rejected
  (the file's column wins) and read on the other; called once per line
  with `above` the last record.
- **APR8** two calls in a row (chunks): the records in file order, two
  undo steps.

Suite: **645 tests, 645 pass** for the 07 commit (631 for 06), one full
run each, no retries. The docs commit's tree (APR4's added read-only
assertion, no new test): **645 tests, 645 pass**, one full run.

### Checks (before each code commit, on its tree)

- `pnpm lint:types`: no error. The tests' `ember-tsc --noEmit -p
  tsconfig.eslint.json`: the baseline errors and no other (`diff` with
  `3c-checks/baseline-tests-tsc.log` empty).
- `eslint` and `prettier --check` on the changed `.ts`/`.gts` files:
  clean (after `prettier --write` on the new test files).
- Owner gate: OK (38 module classes).
- `node scripts/generate-api-docs.mjs --check`: exit 0.
- Before the docs commit, on its tree, also: `pnpm lint:js` and
  `pnpm lint:css` in `packages/sheet` (exit 0), `pnpm eui:check` at the
  root (exit 0), and the checks above again (same results).
- `packages/core/src` unchanged; no dependency added.

### Deviations

1. **The reader is in `src/core/delimited.ts`**, not inside `parseCsv`
   with `parseTsv` calling it: `csv.ts` imports `headerLine` from
   `tsv.ts`, so `tsv.ts` importing `parseCsv` would be an import cycle.
   Same rules, same code, the delimiter a parameter; `parseTsv` and
   `parseCsv` both call it. Not exported from the core's index.
2. **`importMatrix` without `headers`** (and without `mapping`): the
   design does not say. The columns go to `fields` by position (a file
   written with `headers: false` in the fields' order reads back), CI3
   pins it.
3. **`importMatrix` drops lines whose every cell is blank** (whitespace
   only), not in the design: a spreadsheet's CSV often ends with `,,,`
   lines, which would otherwise be empty records. It also does not pad
   short lines (APR5, CI3).
4. **`@newRecordValues` in `appendRows`.** 07 says "a field the file
   does not have is left out of the insert, so `@newRecordValues` gives
   it a value", but the add row's paste (`pasteText`/`buildPaste`) never
   calls `@newRecordValues`. To keep the design's promise, `appendRows`
   (only it; the paste is unchanged) calls it once per line with
   `{ above: <last record>, below: undefined }` and puts its values under
   the line's, for the fields with no column in the file; the file's
   columns win even when their text is rejected or pending, and a group's
   values win over both (APR7). **The user's decision** whether a paste
   on the add row should do the same (today it does not).
5. **`appendRows` is in the clipboard module** (`clipboard.ts`), not the
   API module: it is the paste path and reuses `pasteInsert`; `api.ts`
   has the one-line entry, as for the other methods.
6. **The resolve change** (addition 1 above): `startResolve` takes the
   call's fields; not in the design, needed for `fields` to work with
   `@onResolve`.
7. **`matchHeader`'s shape** (`{ field, by }`) and the extra export
   `normalizeHeader` are this batch's choice (10 only names the
   matcher). A header whose best field is taken is unmatched; it does not
   fall back to a lower-priority match on another field.
8. **`escapeFormulas` also escapes header labels.** A negative value
   whose text is not a plain number gets the `'` too (a negative
   duration `-1:30`, or `-1e-7` as `String` writes it); the rule looks
   only at the text, as 06 says. Not tested for those types.

### Found (not changed)

- **A rejection on an inserted row is hidden when the owner's
  `createRecord` gives that field a value.** A rejection is shown while
  the cell's value equals the one the sheet saw when it emitted it
  (`cells.liveRejection`, `seenValue`); for a new row that is
  `undefined`, so a store that creates records with defaults (`qty:
  null`) hides it. Found when APR2's first owner did that; the same holds
  for a paste on the add row. `localRecords`' default `createRecord`
  (`{ id: tempId, ...values }`) is not affected. The tests' owner uses
  no defaults.

### Real input in Chromium

Production build of this checkout (the sheet's `pnpm build`, then
`site`'s `pnpm build`), served with `vite preview`, Playwright's
Chromium (headless, 1300 × 900), real `page.mouse` and `page.keyboard`,
`setInputFiles` on the demo's file input, on the new demo d26 ("CSV
export and import", `localRecords`) on `/docs/sheet/docs/sheet`. The
tree was the 07 commit plus the docs and demo of the last commit. No
page errors, no console errors.

- **Export** (a mouse click on "Export CSV", the download saved and
  read): `inventory.csv`, starting with a UTF-8 BOM (the demo's
  `download` adds it), then
  `Item,Unit price,Stock,Next count,Active,Notes` /
  `Bolt M8,0.35,1200,2026-12-01,true,Box of 100` /
  `"Washer, 8 mm",0.05,5400,2026-12-01,true,` /
  `"Cable ""flex"" 2 m",4.2,80,,false,"'=HYPERLINK(""http://example.com"")"`.
- **Import** of a `;` file with a BOM and Spanish headers
  `PRODUCTO;Precio;existencias ;Fecha;Activo;Proveedor` (aliases in
  another case and with a trailing space), three lines, `doce` as a
  price, `Sí`/`No`/`sí`, an empty date, a quoted `"Broca 3/8, cobalto"`:
  the footer "importar.csv: 3 lines into 5 fields; not imported:
  Proveedor"; rows 4-6 Tuerca M8 / Taquete 1/4 / Broca 3/8, cobalto;
  prices 0.12, **`doce` invalid with the title `"doce" is not a
  number`** (the red frame, `rejection.png`), 18.5; stock 900, 300, 40;
  dates 15/12/2026, 20/12/2026, empty; Active checked, unchecked,
  checked.
- **Ctrl+Z** after a mouse click on the first Item cell (focused,
  `item:0`): the three rows gone, no invalid cell left.
- **Round trip**: the exported `inventory.csv` imported back: "3 lines
  into 6 fields", the same items and prices, and the escaped note kept
  as the text `'=HYPERLINK("http://example.com")` (by design); Ctrl+Z
  after a click removed them.
- **Sample file** (a mouse click; a separate short run): `inventario.csv`
  with the BOM and the Spanish lines, which imports as "3 lines into 5
  fields; not imported: Proveedor".
- **windows-1252: not run.** The demo reads the file with `file.text()`
  (UTF-8), so a windows-1252 file would show replacement characters;
  decoding bytes is batch E's `decodeText`. The docs say how to decode
  with `TextDecoder('windows-1252')`.
- Screenshots (not in the repo):
  `/tmp/claude-0/-home-user-ember-eui/87cd9e5a-212c-54c3-9d47-30ac398aebd2/scratchpad/v04b/`
  `before-import.png`, `after-import.png`, `rejection.png`,
  `after-undo.png`, `round-trip.png`; the downloads `inventory.csv`,
  `inventario.csv`; the script's output in `results.json`. The agent
  looked at `rejection.png`, not a person.

### Open items

- **Deviation 4 is the user's decision** (should a paste on the add row
  also get `@newRecordValues`?). So is deviation 3 (blank lines dropped)
  if a blank line should be a record.
- **Chunks need the owner to apply each change set before the next
  call**: each chunk is anchored after the last record of `@records`; an
  owner that applies later would get the second chunk before the first.
  APR8 tests the synchronous case only; the docs say to apply first.
- **The EmberSearchUi connector** has no way to reach `appendRows`
  other than its `@registerApi`, which it forwards (not tested here).
- **Not verified:** a 10,000-line import's time (no measurement; the
  design gives none for 07); Excel's own handling of the exported file
  (only re-read by `parseCsv`); a real Excel or Google Sheets file; the
  formula rule against a real spreadsheet; Firefox, Safari, a screen
  reader, dark mode.

### Files

- New: `packages/sheet/src/core/csv.ts`,
  `packages/sheet/src/core/delimited.ts`,
  `packages/sheet/tests/unit/csv-test.ts`,
  `packages/sheet/tests/integration/components/eui-sheet-append-rows-test.gts`,
  `packages/sheet/docs/sheet-demo/d26-csv.md`.
- Changed: `src/core/index.ts` (the export), `src/core/tsv.ts`
  (`parseTsv` calls the shared reader), `src/core/types.ts`
  (`importAliases`), `src/types.ts` (`SheetApi.appendRows`),
  `src/-private/sheet/clipboard.ts` (`appendRows`), `api.ts`,
  `resolve.ts` and `types.ts` (`PendingCall.fields`) in
  `src/-private/sheet/`; `docs/sheet.md` (new sections "Export to CSV"
  and "Import from CSV" after "Summary bar", the API table, the
  `@fields` keys); `README.md` (a section "CSV export and import", the
  API table, the `@fields` keys; prettier-clean, which realigned the
  Arguments and API tables). `docs/sheet.md` and d26 are in the docs'
  existing style (not prettier-formatted, as before).

### Commits

| Commit | Holds | Suite |
| --- | --- | --- |
| `9610c0f` | 06 `toCsv`, CX1-CX6 | 631 / 631 |
| `a354acc` | 07 `parseCsv`, `importMatrix`, `appendRows`, and the three additions (`fields`, `importAliases`, `matchHeader`/`normalizeHeader`), CI1-CI6, APR1-APR8 | 645 / 645 |
| the docs commit | docs, README, d26, APR4's read-only check, these results | 645 / 645 |

One commit in this range is the main session's: `c773cae` (the user's
decisions 7-9 after batch A in `v04/README.md`) before `9610c0f`.
