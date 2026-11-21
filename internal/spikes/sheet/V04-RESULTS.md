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

## Batch C: cell colour (08)

Built 2026-11-21 on `6f0f7da` (batches D, A, B done), in this checkout.
Design: `v04/08-cell-color.md`, with decision 1 of `v04/README.md` (a bar
along the cell's bottom edge, not coloured text). The component did not
change (605 lines); the feature is in the cells module, the cell
renderer, the row-colour module and `styles.ts`.

### What was built

- **`@cellColor?: (record, field) => SheetRowColor | undefined`**
  (`src/types.ts`, next to `@rowColor`). The same colours as
  `@rowColor`: a theme name or any CSS colour; `undefined` draws nothing.
- **Where it runs.** `cells.cellView(row, col, fieldId)` (the grid's cell
  view, behind `SheetCell`'s `@cached view`) calls `cells.markOf(record,
  field)` after the view is built, and sets `view.mark = { className,
  style }` (`CellView.mark`, `src/-private/sheet/types.ts`). Only the
  grid's cells: `cellViewFor` (shared with the expanded record's boxes)
  does not call it, so the expanded record shows no colour. Rows that are
  not records (group headers, the add row) get no view, so no call.
- **Colours.** `colorProps(color)` (new, exported from `row-colors.ts`)
  is batch 4's logic taken out of `barProps`, which now calls it: a named
  colour is the class `euiSheet__rowColor--<name>` (which sets
  `--euiSheetRowColor` from `--euiSheet-row<Name>`, so dark mode
  follows), any other colour is the inline `--euiSheetRowColor: <colour>`;
  a colour with `;`, `{`, `}`, `<` or `>` is dropped, as for rows. The row
  bar's output is unchanged (RC1-RC4 pass).
- **Drawing (the mechanism, below).** `sheet-cell.gts` renders, in a data
  cell's content and only when `view.mark` is set,
  `<span class="euiSheet__cellMark euiSheet__rowColor--<name>"
  style="--euiSheetRowColor: …" aria-hidden="true">` (the style only for
  a CSS colour, through `htmlSafe`). `styles.ts` (9 lines): the span is
  absolute, 3 px high, along the bottom of the cell's padding box,
  `background-color: var(--euiSheetRowColor)` (from the follow-up commit;
  `background` before), `pointer-events: none`, and
  placed inside the cell's inner frames by two custom properties
  (`--euiSheetMarkInset` for the sides and bottom, `--euiSheetMarkBottom`
  for the bottom alone):

  | The cell also has | Drawn as | The bar |
  | --- | --- | --- |
  | nothing | | left 0, right 0, bottom 0 |
  | an error (`--invalid`) | 1 px inset `box-shadow` | 1 px in on the sides and bottom |
  | the current match (`--match`) | `::after`, 2 px inset ring, z-index 1 | 2 px in |
  | an upload's progress (`__cellProgress`) | `::before`, 2 px bar at the bottom, z-index 1 | bottom 2 px: just above the progress bar, never under it |
  | the selection (`--selected`) | a background; on a range, the 3 px range outline (an overlay) on its edges | bottom 3 px (on every selected cell, so a range's bottom row is clear of the outline) |
  | focus (`:focus`) | 3 px outline at -3 px | 3 px in |
  | focus and an error | 5 px inset band | 5 px in |
  | the row bar (first field, no row numbers) | 4 px inset `box-shadow` at the left | left 4 px |
  | frozen (sticky), the frozen edge | position sticky; an outer shadow on the right | unchanged: the span moves with the cell |

  So the bar and each frame occupy different pixels: no frame covers it
  and it covers none, whatever the paint order. With several, the larger
  inset wins (rules in increasing order, the focused-and-invalid one more
  specific).
- **Label.** The cell's `aria-label`, `title`, text and classes do not
  change; the span is empty and `aria-hidden`.

### The mechanism, and why

The design draws the bar with the cell's `::after`. On the current code
both pseudo-elements of a data cell are taken (batch 5: `::after` is the
current-match ring, `::before` the upload progress bar) and so are its
`box-shadow`s (error border, row bar, frozen edge). The two candidates:

1. **A small element of its own** (chosen). It collides with nothing that
   exists: no pseudo-element, no shadow, no background. It costs one
   empty `span` per coloured cell, only while the cell has a colour.
2. **A bottom gradient as the cell's `background-image`.** Ruled out:
   `styles.ts` sets `background-image` on data cells in several rules that
   are more specific than a mark rule would be: `none` on selected cells
   (line 19) and on the active cell of a range (139), the hover tint on
   checked cells (18), and the opaque base plus tint on frozen cells
   (131-135). The bar would vanish on selection and be replaced on frozen
   and hovered checked cells; each would need its own combined rule.

The containing block is the grid cell itself (`offsetParent` is the cell
in every test; the content `div` is `overflow: hidden` but not
positioned, as the opener's icon already relies on).

### The performance gate

**1. Call counts** (a temporary counter in `cellView` and in the
callback, and a scratch test, both removed before the commit; `git diff`
of `cells.ts` checked). The large-data case: 10,000 records, d08's 30
fields, `@height={{420}}`, 1,000 px wide; `@cellColor` colours every
third cell (`(id + fieldIndex) % 3 === 0`, a `Map` lookup). Two runs,
the same numbers:

| Step | `cellView` without | `cellView` with | `@cellColor` calls | Bars rendered |
| --- | --- | --- | --- | --- |
| First render | 130 | 130 | 130 | 36 |
| Scroll down to 100 px | 30 | 30 | 30 | 43 |
| Scroll down to 200 px | 20 | 20 | 20 | 40 |
| Scroll down to 300 px | 30 | 30 | 30 | 43 |
| Scroll right to 300 px | 39 | 39 | 39 | 52 |
| Focus a cell (`focus()`) | 171 | 171 | 171 | 43 |
| ArrowDown | 131 | 131 | 131 | 43 |

The "without" column is V03C stage 2's (130 / 30 / 20 / 30 / 39).
`@cellColor` is called exactly once per `cellView` call and nowhere else.
The last two rows (not in V03C's table) show that a selection move
re-runs `cellView`, and so `@cellColor`, on every rendered cell (171 and
131): that is the existing per-cell path, not new, and it is why the docs
say to keep the callback cheap.

**2. CC-perf** (`eui-sheet-cell-color-test.gts`, logged with `?report`
like FZ9, not asserted). FZ9's case (600 px wide, 30 fields of 150 px,
10,000 rows, 20 scroll steps of 600 px, a frame after each), every third
cell coloured, run with frozen fields on (FZ9's case: every column of a
rendered row, 372 cells) and off (72 cells). FZ13's method: the four
variants interleaved over 3 rounds, the fastest round of each. Headless
Chrome 153 under testem, ms per scroll step, seven runs with
`filter=CC-perf` alone:

| Run | Frozen on: without | with | ratio | Frozen off: without | with | ratio |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 366.2 | 373.3 | 1.02 | 76.8 | 78.4 | 1.02 |
| 2 | 400.4 | 382.1 | 0.95 | 73.5 | 75.5 | 1.03 |
| 3 | 374.7 | 390.4 | 1.04 | 67.6 | 75.8 | 1.12 |
| 4 | 371.1 | 384.0 | 1.03 | 74.1 | 69.0 | 0.93 |
| 5 | 385.7 | 385.5 | 1.00 | 74.1 | 69.5 | 0.94 |
| 6 | 358.7 | 386.2 | 1.08 | 80.4 | 79.4 | 0.99 |
| 7 | 402.0 | 403.1 | 1.00 | 79.0 | 79.1 | 1.00 |

Median ratio 1.02 (frozen on) and 1.00 (frozen off); 13 of 14 within
10 %. The one above (run 3, frozen off, 1.12) is within the noise of the
baseline itself: the "without" runs alone spread from 67.6 to 80.4 ms
(±9 %) and run 4 went 0.93 the other way. FZ9 in the same session:
frozen on 393.4 ms, off 80.0 ms (372 and 72 cells). **The gate passes;
no cache was built.** A per-record-and-field cache would save only the
callback (called as often as `cellView`, which already runs only for
re-rendered cells); the rest of the cost is the bar elements themselves.

### Tests

`tests/integration/components/eui-sheet-cell-color-test.gts` (new). The
prefix `CC` was free (`grep -rnE "\bCC[0-9]" tests`: nothing). Geometry
is read in layout px (`offsetLeft/Top/Width/Height` against the cell's
`clientWidth/Height`, and `offsetParent === cell`), as the test container
is scaled.

- **CC1** a named colour (the design's overdue rule): the span with
  `euiSheet__rowColor--danger`, `aria-hidden`, no inline style, the
  token's computed colour, absolute, `pointer-events: none`, 3 px high
  with gaps 0/0/0, on screen at the cell's bottom; only the two overdue
  cells have one; the cell's text, `aria-label` and `title` as without.
- **CC2** CSS colours as given (`rgb(1, 2, 3)`, `#123456`, `oklch(…)`),
  the inline property, no named class; `red; background: blue` dropped;
  a `url(…)` paints nothing (no image, a transparent colour; added in the
  follow-up commit).
- **CC3** no `@cellColor`, then a rule: cells whose colour is
  `undefined` keep exactly their classes, style, title, label and content
  HTML; a coloured cell's classes are unchanged too.
- **CC4** called with the record and its field; a new `@records` with
  changed dates moves the bars; a new `@cellColor` replaces the rule.
- **CC5** dark theme: the token changes and the bar follows; a CSS colour
  stays.
- **CC6** (error border) `@cellErrors` on a coloured cell: the 1 px red
  inset shadow and the title, the bar 1 px in; focused: the 5 px band and
  the 3 px outline, the bar 5 px in.
- **CC7** (row bar) `@rowColor` `success`, `@rowNumbers={{false}}`, the
  cell `danger`: the cell's 4 px inset shadow in the row's colour, the
  bar in the cell's own colour (not inherited), 4 px from the left, at
  the bottom; with a CSS row colour the cell keeps its named colour;
  without a row bar, from the left edge.
- **CC8** (match ring) `@currentMatch` on a coloured cell: the 2 px
  `::after` ring, the bar 2 px in.
- **CC9** (frozen) `@frozenFields={{1}}`, scrolled 700 px: the sticky
  cell's bar at 0/0/0, moving with it on screen, in the token's colour,
  and the frozen cell is what is painted on the bar's row.
- **CC10** (selected, focused) a click: selected and focused, the 3 px
  outline at -3 px, the bar 3 px in; Shift+click to a 2 × 2 range: the
  range outline, the selected background, every selected bar 3 px up;
  the active cell 3 px in; a click elsewhere: back to the edge.
- **CC11** (upload progress) an attachment cell coloured `accent`, a
  pasted file at 50 %: the `::before` progress bar at the bottom (2 px),
  the bar 2 px up (focus moved away, so only the upload frames it); the
  other row's cell at the edge; resolved: back to the edge.
- **CC-perf** above.

Suite: **657 tests, 657 pass** (645 + 12) for the feature commit, one
full run, no retries. The docs commit's tree (no source or test change):
**657 tests, 657 pass**, one full run.

### Checks (before each commit, on its tree)

- `pnpm lint:types`: no error. The tests' `ember-tsc --noEmit -p
  tsconfig.eslint.json`: the baseline errors and no other (`diff` with
  `3c-checks/baseline-tests-tsc.log` empty; a first draft had two TS1206
  errors for decorators on a class expression in CC-perf, fixed by a
  named class before the commit).
- `eslint` and `prettier --check` on the changed `.ts`/`.gts` files:
  clean (after `prettier --write` on the new test file).
- Owner gate: OK (38 module classes; `colorProps` is a module-level
  function, `markOf` a member of `SheetCells`).
- `node scripts/generate-api-docs.mjs --check`: exit 0 (it updated 0 of
  117 pages: it reads no sheet source).
- The scratch counter and test: removed before the commit (`grep -rn
  "SCRATCH\|__cv" src tests`: nothing; `git diff` of `cells.ts` read).
- Before the docs commit, on its tree: `pnpm lint:js` and `pnpm lint:css`
  in `packages/sheet` (exit 0), `pnpm eui:check` at the root (exit 0),
  and the checks above again (same results); README `prettier --check`
  clean.
- `packages/core/src` unchanged; no dependency added; the component
  unchanged.

### Deviations

1. **The bar is an element, not the cell's `::after`** (the design): both
   pseudo-elements and the box-shadows are taken since batch 5 (above).
   `span.euiSheet__cellMark`, `aria-hidden`, `pointer-events: none`,
   rendered only for a coloured cell.
2. **The bar is placed inside the cell's frames**, not always at the
   very edge: 1 px in with an error, 2 px with the match ring, 3 px when
   focused, 5 px focused and invalid; 2 px up while an upload's progress
   shows (above it rather than under it), 3 px up on selected cells (clear
   of a range's outline), 4 px from the left with the row bar. The design
   expected an `::after` with nothing to share the bottom edge with; on
   this code six things draw there, so each would otherwise hide part of
   the bar or be hidden by it.
3. **The colour property is the row colours' `--euiSheetRowColor`**, set
   by the same `euiSheet__rowColor--<name>` classes (on the span, not the
   cell), not a new `--euiSheet-cellMark`: no second set of six token
   rules. The span always sets it itself (class or inline), so a row's
   colour on the first field's cell is never inherited (CC7 checks it).
4. **`colorProps` taken out of `barProps`** in `row-colors.ts` (the same
   output for rows), so the cell mark shares the named colours and the
   dropped-value filter.
5. **The design's CC7 is kept; CC8-CC11 are added** for the pairs the
   brief lists (match ring, frozen, selected/focused, upload progress).
   CC6's "computed styles of the cell and of its `::after`" are the cell's
   shadow and the span's geometry (there is no `::after` bar).
6. **Not in the expanded record.** `@cellColor` is called from
   `cellView` only (the measured path); the expanded record's boxes use
   `cellViewFor` and show no colour. The design does not say.
7. **The docs demo is new (d27 "Cell colours")**, not added to d21:
   d21 is about row order, and the checks need an error, a frozen field
   and every row height next to the colours.

### Real input in Chromium

Production build of this checkout (the sheet's `pnpm build`, then
`site`'s `pnpm build`), served with `vite preview` (port 4183: 4173 was
held by an older preview server, left alone), Playwright's Chromium
(headless, 1300 × 900, `deviceScaleFactor` 2), real `page.mouse` clicks
and wheel, `page.keyboard`, on the new demo d27 ("Cell colours",
`localRecords`) on `/docs/sheet/docs/sheet`, in light and then dark (the
header's theme switch). The tree was the feature commit plus the docs
and demo of the docs commit. **No page errors, no console errors.**
Today on the page: 2026-11-21. Geometry below is layout px (`offset*`
against the cell's `client*`); "on screen" is the rendered rect.

- **First render** (short rows): bars on Task of the two done tasks
  (`success`, `rgb(0, 138, 94)`), on Due of the three overdue open tasks
  (rows 2, 3 and 8; `danger`, `rgb(198, 30, 37)`) and on Spent where it
  exceeds the estimate (`warning`, `rgb(250, 203, 61)`); each 3 px high,
  gaps 0/0/0, its `offsetParent` the cell, the bar's bottom 1 px (CSS)
  above the cell's rect bottom: the cell's `border-bottom-width` is 1 px
  (read in a second run: rect 36, `clientHeight` 35).
- **Error border:** the two overdue tasks with no owner (rows 3 and 8)
  have the 1 px red inset shadow and the bar 1 px in (gaps 1/1/1);
  clicked (focused, invalid): the 5 px band, the 3 px outline, the bar
  5 px in.
- **Focused / selected:** a click on an overdue Due (row 2): selected
  and focused, the 3 px outline, the bar 3 px in. Shift+click (real
  Shift held) to row 4 Spent: a 3 × 4 range with its outline; the
  selected coloured cells' bars 3 px up (row 2 Spent: 0/0/3; row 3 Due,
  invalid: 1/1/3), the active cell's 3/3/3.
- **Frozen, scrolled sideways:** six real wheel steps of 120 px
  (horizontal) over the grid: `scrollLeft` 113 (its maximum at this
  width); the frozen Task cells stay at the same screen x (353) with
  their bars (0/0/0) and the frozen edge's shadow; a click on a frozen
  coloured cell: the outline and the bar 3 px in.
- **A range ending on coloured cells** (a second, short run on the same
  build): a click on row 1 Due, Shift+click on row 2 Spent: the range
  outline's bottom at the cells' bottom (370.2), the bars of row 2 Due
  and Spent 3 px up (gaps 0/0/3, bottom 366.2), so above the outline
  (`light-8-range-bottom.png`, looked at by the agent). The range's
  right edge covers the last 3 px of the Spent bar's right end (the
  sides are not inset on selected cells); the bar still reads.
- **Every row height** (a click on each of the toolbar's four buttons):
  Medium, Tall, Extra tall, Short: every bar 3 px high at the cell's
  bottom (gaps unchanged), also on the tall cells.
- **Data:** a click on row 2's Done checkbox: Due's bar goes and Task's
  `success` bar appears; Ctrl+Z: back.
- **Dark:** the same steps; `danger` is `rgb(246, 114, 106)` (the dark
  token), `warning` unchanged, the same geometry.
- Screenshots (not in the repo):
  `/tmp/claude-0/-home-user-ember-eui/87cd9e5a-212c-54c3-9d47-30ac398aebd2/scratchpad/v04c/`
  `light-1-initial.png` to `light-5-frozen-scrolled.png`,
  `light-6-height-{Medium,Tall,Extratall,Short}.png`,
  `light-7-done-ticked.png`, `light-8-range-bottom.png`,
  `dark-1-initial.png` to
  `dark-5-frozen-scrolled.png`; the measurements in `results.json`. The
  agent looked at `light-3-range.png`, `dark-4-invalid.png`,
  `light-5-frozen-scrolled.png`, `light-6-height-Extratall.png` and
  `light-8-range-bottom.png` (one of them dark), not a person: the bars read clearly at the bottom of each coloured cell, next
  to the red border, inside the focus ring and the range, on the frozen
  cell.
- **Seen, not this batch's:** in `light-6-height-Extratall.png` the fill
  handle of the selected Task cell is drawn about 90 CSS px above the
  cell's bottom corner, 600 ms after the row-height change. Possibly the
  handle not re-placed after a row-height change, possibly a screenshot
  taken too early; not investigated.

### Open items

- **Decision for the user:** whether the expanded record should show the
  cell colour too (deviation 6), and whether a selected cell's bar should
  rise 3 px only on a range's bottom row (today every selected cell's
  does, which is simpler; the difference is visible only inside a range).
- **The EmberSearchUi connector** (`EuiSheetSearch`) forwards its
  arguments by name and forwards neither `@cellColor` nor `@rowColor` (nor
  batch D's and A's new arguments). Not changed here; whether it should is
  a follow-up for all of them.
- A selection move re-runs `@cellColor` on every rendered cell (the
  existing `cellView` path: 171 calls for one focus, 131 for one
  ArrowDown in the large case). Not new, and not measured in ms here.
- **Not verified:** Firefox, Safari, a screen reader, high-contrast
  mode, touch; the bar at a 125 % or 150 % zoom (a 3 px bar may round to
  2 or 4 device px); a cell with a long text wrapping at "tall" heights
  over the bar (text is above it in the content box, not measured).

### Files

- New: `packages/sheet/tests/integration/components/eui-sheet-cell-color-test.gts`,
  `packages/sheet/docs/sheet-demo/d27-cell-color.md`.
- Changed: `src/types.ts` (`cellColor`), `src/-private/sheet/cells.ts`
  (`markOf`, the call in `cellView`), `src/-private/sheet/row-colors.ts`
  (`colorProps`), `src/-private/sheet/types.ts` (`CellView.mark`),
  `src/-private/sheet-cell.gts` (the span, `markStyle`),
  `src/-private/styles.ts` (9 lines); `docs/sheet.md` (the Arguments row
  after `@rowColor`, "Cell colours" in Theme); `README.md` (the summary,
  an Arguments row `@rowColor`, `@cellColor`, a sentence in Theme;
  prettier-clean). `node scripts/generate-api-docs.mjs` updated nothing:
  it reads no sheet source (as in batches A and B).

### Commits

| Commit | Holds | Suite |
| --- | --- | --- |
| `32cfe62` | `@cellColor`: `types.ts`, `cells.ts` (`markOf`), `row-colors.ts` (`colorProps`), `CellView.mark`, the span in `sheet-cell.gts`, 9 lines of `styles.ts`; CC1-CC11, CC-perf | 657 / 657 |
| `a549b15` | `docs/sheet.md`, README, d27, these results | 657 / 657 |
| the follow-up commit | the bar's `background` → `background-color` (a `url(…)` value is not fetched; CC2's new assertion fails with `background`, checked), corrections to these results (three overdue Due bars, not four; the 1 px is the border, measured), the range-bottom real-input run, the connector note | 657 / 657 |

One commit in this range is the main session's: `4d35560` (the user's
decisions 10-13 after batch B in `v04/README.md`) before `32cfe62`.

## The paste fix (decision 10)

Built 2026-11-21 on `c5ca46f` (batches D, A, B, C done; `c5ca46f` is the
main session's readiness docs on top of `f360376`), in this checkout.
Decision 10 of `v04/README.md`: "A paste on the add row also
fills the fields the pasted text has no column for from
`@newRecordValues`, as `appendRows` does" (batch B's deviation 4).

### What was built

- **One helper, `records.fillNewValues(inserts, columns, above)`**
  (`src/-private/sheet/records.ts`): for each insert, `@newRecordValues`
  is called once with `{ above, below: undefined }`, and its values for
  the fields not in `columns` go under the insert's values. The insert's
  own values win (the text's read cells; a group's values, which
  `buildPaste` already put in them); a column whose text was rejected or
  is pending keeps no value, so the default does not hide the rejection.
  Without `@newRecordValues` it does nothing.
- **`appendRows`** now calls it (the loop it had moved there; same
  behaviour: APR7 unchanged and passing).
- **`pasteText`** calls it when the paste's anchor is an add row
  (`rows.isAddRow`: the sheet's, or a group's), on both paths
  (`pasteMatrix`, and `planPaste` with `@onResolve`), before the emit.
  The columns are the visible fields the pasted block covers
  (`visibleFields[anchor.col .. right]`), so a field left of the anchor,
  right of the block, or hidden gets the default. `above` is the record
  above the add row: the last record, or on a group's add row the
  group's last loaded record (what Enter on that add row passes,
  `appendToGroup`).

### Tests

New file `tests/integration/components/eui-sheet-paste-new-values-test.gts`
(prefix PNV, unused before: checked with `grep -rnoE`); no existing test
changed.

- **PNV1** a paste at the add row's second column, two lines, a rejected
  `abc` for `qty`: `name` (left of the block) and `code` (hidden) from the
  defaults, `qty` absent on the rejected row (not the default `0`), an
  empty `due` stays empty; one call per line with `above` the last
  record; the rejection shown; one undo step.
- **PNV2** without `@newRecordValues`: only the pasted values.
- **PNV3** `@onResolve` with a user column: the pending column is not
  filled from the defaults (the owner's default user is not used), the
  resolve patches it after.
- **PNV4** a group's add row: the group's `status` wins over the pasted
  `Later` and the default `Elsewhere`; a column the block covers (`qty`)
  is not filled from the defaults on a line too short for it (as
  `appendRows` with a short row); `above` is the group's last record.
- **PNV5** a paste on a record row running past the end: no call; the
  line past the end has only its pasted values (unchanged behaviour,
  pinned).

Suite: **662 tests, 662 pass** (baseline 657, +5 PNV), one full run on the
commit's tree. An earlier run, before PNV3 used `pasteNow`, had PNV3
time out (deviation 3); nothing else failed in it.

### Checks (on the commit's tree)

- `pnpm lint:types`: no error. The tests' `ember-tsc`: the baseline
  errors and no other (`diff` empty).
- `eslint` and `prettier --check` on the three changed files: clean.
- Owner gate: OK (38 module classes).
- `node scripts/generate-api-docs.mjs --check`: exit 0.
- These ran before PNV3's switch to `pasteNow` (a test-only change);
  after it, the tests' `ember-tsc` (same baseline), `eslint` and
  `prettier --check` on the test file were run again, not `lint:types`,
  the owner gate or the API-docs check (they read no test file).
- The first full run was **661 / 662** (PNV3 timed out at 60 s on the
  shared `clipboard` helper's `settled()`, deviation 3); the run after
  the fix, on the committed tree, was 662 / 662. A second Chromium (a
  scratch build of stage 1's unit tests and its first measurement) ran
  during part of that second run.

### Deviations

1. **`above` on a group's add row** is the group's last loaded record,
   not "the last record" as `appendRows` says (`appendRows` inserts after
   the last record; a group's add row inserts after the group's last
   one). The same `above` as Enter on that add row.
2. **A field the block covers is never filled from the defaults**, also
   on a line too short to reach it (PNV4): "the text has a column for
   it", as `appendRows` treats a short row.
3. **PNV3 pastes without `settled()`** (a pending resolve holds the test
   waiter), as `eui-sheet-resolve-test.gts`' `pasteNow`; the first run
   with the shared `clipboard` helper timed out (60 s) on that, not on
   the code.

### Open items

- **Decision for the user:** a paste from a record row whose lines run
  past the last record inserts those lines too. They still get only the
  pasted values (decision 10 names the add row only); PNV5 pins that. If
  they should get `@newRecordValues` as well, it is the same call with
  `above` the last record.
- `docs/sheet.md` says it in "Adding" and in the groups section; README
  unchanged (it describes `@newRecordValues` in one line).

## Batch E, stage 1: the import helpers (10)

Built 2026-11-21 on `a365483` (the paste fix), in this checkout. Design:
`v04/10-import-screen.md`, its "Pure helpers" section with "Guessing a
type", "Built-in column options", "Transforms" and "Matching", and
decisions 5, 6 and 11-13 of `v04/README.md`. Only the pure helpers and
their types: the component (`eui-sheet-import.gts`, stage 2) was not
started. Everything is in `src/core/import.ts` (new, 861 lines with its
doc comments), exported from `@ember-eui/sheet/core`; it imports
nothing from Ember (the core-boundary test passes).

### What was built

- **`decodeText(bytes)`** → `{ text, encoding }`: a UTF-8 BOM is
  stripped; strict UTF-8 (`TextDecoder('utf-8', { fatal: true })`), else
  windows-1252. With a BOM, bad bytes stay UTF-8 (U+FFFD). Takes an
  `ArrayBuffer` or a `Uint8Array`.
- **`matchColumns(headers, fields, saved?, { headers? })`** →
  `SheetImportColumn[]`, one per header. A saved mapping is used only when
  its `signature` equals this header line's; its fields are taken first
  (as `importMatrix`'s `mapping`), each column keeps its saved target,
  transform and options (`matchedBy: 'saved'`); a saved field id that no
  longer exists falls back to the header. Then batch B's `matchHeader`
  (alias, label, id; `normalizeHeader`: case, accents, spaces, `_`, `-`).
  A field takes one column; a header whose field is taken stays `'skip'`
  with `taken: <id>` (decision 12, no fallback). `{ headers: false }`:
  by position (decision 11). Unmatched: `'skip'` (the screen turns it
  into "New field" when it has `@onCreateFields`).
- **`importSignature(headers)`**: `JSON.stringify` of the normalised
  headers (`normalizeHeader`), the `SheetImportMapping.signature`.
- **`guessColumn(ctx, texts, candidates = CREATABLE_FIELD_TYPES)`** →
  `SheetColumnGuess[]` (`{ type, share, options }`), every candidate that
  reads at least 95 % of the sample, in the design's order; the first is
  the guess. The sample: the first 200 non-blank texts. Each candidate is
  read by its own type in `ctx.types` (`parse` with `source: 'paste'`)
  with a draft field `{ id, type, ...options }`. Candidates: `checkbox`,
  `date`, `dateTime` (D/M/Y unless proven M/D/Y), `percent`, `currency`,
  `number` (each `.` then `,`), `email`, `url`, `phone`, `singleSelect`
  (at most 20 distinct texts, each used twice; its `options` are those
  texts), `longText` (a line break or over 200 characters), `text`. Only
  names in `candidates` that `ctx.types` has. `options` are the new
  field's: `dateOrder`, `decimalSeparator`, a select's `options`. An
  all-blank sample gives `text` only (deviations 1-5).
- **`CREATABLE_FIELD_TYPES`** moved from `field-editor.ts` to
  `src/core/fields.ts` (exported); the field editor imports it, same list,
  same behaviour.
- **The plan** (`SheetImportPlan { headers?, columns }`;
  `SheetImportColumn { index, header, target, matchedBy?, taken?,
  transform?, trim?, emptyIsNull?, dateOrder?, decimalSeparator?,
  valueMap? }`; `SheetImportTarget = { field } | { newField: draft } |
  'skip'`). A new field's column is read with `{ ...draft, id:
  importFieldId(index) }` (`'new:<index>'`) until it exists.
- **Reading a cell** (one function for the preview and the run): the
  file text → trim (default on) → the transform (`null` is `''`; a throw
  is an error cell with its message) → the value map → empty and
  `emptyIsNull` (default on: `null`, no parse) → the type's `parse`
  (`source: 'paste'`, the line's values so far as the record, as
  `buildPaste`), with the column's field: the target, or a copy with the
  column's `dateOrder` (date, dateTime) or `decimalSeparator` (number,
  currency, percent). The copy is never written back: the field object is
  unchanged (IP3).
- **The value map**: text → the value to write (an option's value, an
  array for a multi-select, `true`/`false`, `null`); it is written as the
  text the column's field reads back as that value (the type's
  `copyText`, else `format`, checked by parsing it; else the value as
  text). **`suggestValueMap(texts, field)`** gives the table: the distinct
  trimmed texts (up to 50) and the prefill (option labels, case and
  accents ignored; the yes/no words for a checkbox). Texts not in the map
  are left as they are.
- **`previewImport(ctx, matrix, plan, transforms, { size = 20 })`** →
  `{ columns, fields, lines, cells }`: it takes its lines first (the first
  `size` non-blank data lines), then reads only those. A cell is
  `{ state: 'value', text, value, display }` (`display`: the type's
  `format` with the column's field), `'newOption'` (with the `options` a
  select creates), `'linked'` (an `unresolved` text: "linked on import")
  or `'error'` with the type's or the transform's message.
- **`runImport(ctx, matrix, plan, transforms, { skipLinesWithErrors? })`**
  → `{ rows, fieldIds, fields, lines, values, errors, unresolved,
  skippedLines }`. `rows` are the texts to append (one per `fieldIds`
  entry), `fields` the fields they were read with (copies and drafts
  included: pass them as `appendRows`' `fields`), `values` what `parse`
  gave (`undefined` for an error or unresolved cell), `errors`
  `{ line, column, fieldId, text, message }`, `unresolved` the cells for
  `@onResolve` (not errors). Lines whose cells are all blank are dropped
  (decision 11). `line` is always the index in `matrix` (the header line
  is 0), `column` the file column.
- **`errorsCsv(matrix, errors, { headers = true, delimiter = ',' })`**:
  the header line, then each failed line once, in file order, as the file
  has it (RFC 4180 quoting; no formula escaping: the user's own texts go
  back to the user). The quoting function moved from `csv.ts` to
  `delimited.ts` (`quoteDelimitedCell`, not exported from the index), and
  `toCsv` calls it there.
- **Types** (all exported): `SheetImportPlan`, `SheetImportColumn`,
  `SheetImportMapping` (`{ signature, columns }`), `SheetColumnGuess`,
  `SheetImportPreview`, `SheetImportTransform` (as the design),
  `SheetImportFieldDraft` (= `SheetFieldDraft`), and
  `SheetImportContext` (`{ types, messages, fields }`),
  `SheetImportTypeContext` (`{ types, messages }`), `SheetImportTarget`,
  `SheetImportCell`, `SheetImportError`, `SheetImportUnresolved`,
  `SheetImportRun`.

### Tests

New file `tests/unit/import-test.ts` (prefixes IG and IP unused before:
`grep -rnoE '\b(PNV|IG|IP|IW)[0-9]+\b'` found nothing). No existing test
changed (CI1-CI6 and CX1-CX6 pass with the moved quoting).

- **IG1** `19/11/2026`-style texts: `date` D/M/Y, share 1; ambiguous
  texts: D/M/Y; one `11/19/2026`: M/D/Y; one proof among 30 still gives
  M/D/Y (D/M/Y would read 96.7 %); texts proving both orders: `text`
  (not `date`, not `url`).
- **IG2** `1.234,5`/`12,5`/`3`/`1.000`: `number` with `,`; `1,234.5`:
  with `.`; `Sí`/`No`: `checkbox`; five statuses twice each:
  `singleSelect` with those options in order; a text used once: not a
  select; a line break and 201 characters: `longText`; `25%`, `30 %`,
  `7.5%`: `percent`; plain numbers: `number`, not `percent`;
  `$1,200.00`, `MXN 300`, `45.5 €`: `currency`; `Calle 5`: `text`;
  emails, urls, phones.
- **IG3** only the candidates: `Sí`/`No` with `text`, `number` is
  `text`; none reads it: `[]`; an unknown name ignored; a candidate
  missing from `ctx.types` not tried; an app type not a candidate; a
  blank sample: `text` only, or `[]` without `text`; the default list;
  `dateTime` when it is a candidate.
- **IP1** `decodeText`: UTF-8 without and with a BOM (`ArrayBuffer`),
  windows-1252 `Año` and `€`, empty bytes.
- **IP2** `matchColumns`: alias, label, id, accents (`AÑO` for `Año`),
  `_` and spaces, the taken field (`taken: 'name'`), unmatched; a saved
  mapping with the same signature: its target, transform and `trim`, a
  saved `'skip'`, a saved field that no longer exists (by header), a
  freed field matched by label, a saved new field; another header line:
  ignored; `headers: false` by position; the signature.
- **IP3** `previewImport`: an M/D/Y copy (the field unchanged), a value
  map for a checkbox and a select (`Abierto` → `Open` → `o`), a transform
  (cents) with its context (`line`, `header`, the raw `row`), a throwing
  transform (its message), a linked record ("linked"), a new option
  (`createOnPaste`), an empty linked cell (`null`), texts not in the map
  read by the type, the blank line left out; without the copy the M/D/Y
  text is `notADate`; `size`; a `null`-returning transform; `trim` and
  `emptyIsNull` off; `'skip'` and unknown ids not read; a new field's
  draft under `importFieldId`; `suggestValueMap` for a checkbox, a
  single and a multi select, and a text field.
- **IP4** `runImport` over 1,000 lines: 1,000 rows, the field ids, the
  fields, a row's texts and values, the line indexes, ten errors
  (`notANumber`), one unresolved cell; `skipLinesWithErrors`: 990 rows
  and the ten `skippedLines`; `errorsCsv`: the header and ten lines, a
  quoted cell, `headers: false`, `;`, each line once in file order. And
  the rows with `run.fields` through the core's `pasteMatrix` (the path
  `appendRows` takes) give inserts equal to `values` and rejections equal
  to `errors`, with an M/D/Y copy and a decimal-comma copy.
- **IP5** one matcher: an alias with `_` matches in `importMatrix` and
  `matchColumns`; a second header naming the taken field is unmatched in
  both.

Suite: **670 tests, 670 pass** (baseline 657; +5 PNV, +8 IG/IP), one full
run on the commit's tree, no retries.

### Measurements

Chromium 153 headless (the suite's testem launcher), this container, a
temporary test file (not committed; no timing assertion is). A
10,000-line, 20-column matrix (four columns each of text, number with a
decimal comma, date D/M/Y, checkbox `Sí`/`No`, single select of five
options; 416 `bad` numbers; one transform), all columns mapped. Two
runs, idle machine:

| Helper | Median | Range | Target (10) |
| --- | --- | --- | --- |
| `runImport`, 10,000 × 20 (the dry run) | 67.7 ms, 71.8 ms (7 runs each) | 61.3-88.4 ms; the first call 84-85 ms | < 1 s |
| `previewImport`, 20 lines (of the 10,000) | 0.3 ms | 0.1-1.0 ms | < 300 ms |
| `guessColumn`, 20 columns × 200 texts | 12.1-13.3 ms | 11.1-36.7 ms | (none) |
| `matchColumns`, 20 headers | 0.1 ms | 0.0-0.3 ms | (none) |

An earlier run while the full suite ran in another Chromium gave the
same order (runImport 69.6 ms median). The dry run is well under 1 s, so
it needs no idle callbacks; stage 2's 250 ms debounce stays as designed.
Not measured: the component's rendering, a real 10,000-line CSV through
`parseCsv` and `decodeText` (those are batch B's and the platform's).

### Checks (on the commit's tree)

- `pnpm lint:types`: no error. The tests' `ember-tsc`: the baseline
  errors and no other (`diff` empty).
- `eslint` and `prettier --check` on the changed files
  (`src/core/import.ts`, `delimited.ts`, `fields.ts`, `csv.ts`,
  `index.ts`, `src/-private/sheet/field-editor.ts`,
  `tests/unit/import-test.ts`): clean.
- Owner gate: OK.
- `node scripts/generate-api-docs.mjs --check`: exit 0 (it reads no sheet
  source; only `--check` was run, nothing regenerated).
- `pnpm lint:js`, `pnpm lint:css` in `packages/sheet`: exit 0;
  `pnpm eui:check` at the root: exit 0.
- `packages/core/src` unchanged; no dependency added.

### Deviations

1. **A text counts as read when `parse` gives a value and the type's
   `validate` passes on it**, not `parse` alone: `email`, `url`, `phone`,
   `text` and `longText` never fail `parse` (they check in `validate`),
   so "the first candidate at 95 %" would make every leftover column an
   email. Still the types' own rules, no new ones for them.
2. **Evidence for three types.** `percent.parse` reads a plain number
   (`12` is 12 %) and comes before `number`; `currency.parse` strips every
   other character (`Calle 5` is 5). So `percent` counts a text only when
   it ends with `%`, and `currency` only when it is a number with a
   currency sign (`\p{Sc}`) or a three-letter code and nothing else.
   `url` counts a text only when its host as written has a dot and a
   non-digit: `url`'s `validate` takes `19/11/2026` (`new URL` reads the
   host `19` as the IPv4 address 0.0.0.19, which has dots), which made a
   mix of dates guess `url`.
3. **The date order.** "M/D/Y only when a text proves it" gates the
   order before the 95 % rule (one `11/19/2026` among 30 would otherwise
   still read 96.7 % as D/M/Y): a text that the type reads as M/D/Y and
   not as D/M/Y proves M/D/Y, the other way round D/M/Y; M/D/Y is tried
   only when proven and nothing proves D/M/Y. Same for `dateTime`.
4. **Currency and percent drafts get an explicit `decimalSeparator`**
   (`.` then `,`): without it currency uses the browser locale's, which
   would make the guess depend on the machine. A currency guess has no
   `currency` code: the new-field form must ask for it.
5. **App types are never candidates** (they have no place in the
   design's order), and a candidate missing from `ctx.types` is skipped
   (`resolveType` would throw). A blank sample gives `text` (or nothing
   without `text`), not the first type that reads 0 of 0.
6. **Signatures beyond the design's**: `ctx` carries `fields` for
   `previewImport` and `runImport` (they read `{ field: id }` targets);
   `matchColumns` takes `{ headers: false }`; `runImport` takes
   `{ skipLinesWithErrors }` and also returns `fields`, `lines`,
   `unresolved` and `skippedLines`; `errorsCsv` takes `{ headers,
   delimiter }`; `line` is the matrix index everywhere (errors,
   `errorsCsv`, the transform's context). Without `lines` the rows could
   not be tied to the file after blank lines are dropped.
7. **Extra exports**: `importSignature`, `importFieldId`,
   `suggestValueMap`, `CREATABLE_FIELD_TYPES` (moved), and the types in
   the list above beyond the design's seven.
8. **"Empty is no value"** decides `values` only: on, an empty text is
   `null` without `parse`; off, the type's `parse('')` (`''` for text).
   `rows` carry `''` either way (a string matrix cannot say "no value"),
   and the sheet reads `''` with the type: a text field gets `''`.
9. **Rows are full width**: a line shorter than the plan's columns gives
   `''` for its missing cells (the design: "one text per entry of
   `fieldIds`"; a transform may build a value from other columns). This
   differs from `importMatrix`, whose short rows let `@newRecordValues`
   fill the missing cells.
10. **The pipeline order** (trim, transform, value map, empty, parse) is
   this stage's choice; the design does not give one. The transform
   gets the trimmed text; its `row` has the raw file texts by header
   (the first column wins on a repeated header). An unknown transform id
   is no transform (a saved mapping may name one the app removed).
11. **A read-only target field is read like any other**; `appendRows`
   skips read-only fields (APR4). The screen's target select should
   offer only writable fields (stage 2).
12. **A cell whose transform threw is `''` in `rows`** (the follow-up
   commit). The first stage 1 commit (`edbf64e`) wrote the untransformed
   text there: with "Import all", `appendRows` would then store it
   wherever the type reads it (always, for a text field), although the
   dry run reported an error. No text makes every type reject, so the
   row writes nothing for that cell (the type's empty value) and the
   error is only in `errors`. IP3 asserts it. **The user's decision**
   whether the raw text should be written instead.
13. **With `skipLinesWithErrors`, `unresolved` lists only the kept
   lines' cells** (the follow-up commit; `edbf64e` listed the skipped
   lines' too). IP4 asserts it.

### Found (not changed)

- `url`'s `validate` accepts `19/11/2026` and plain numbers (`12` →
  `https://12` → the host 0.0.0.12): a url field shows such texts as
  valid. Checked with Node 22 (`new URL('https://19/11/2026').hostname`
  is `0.0.0.19`, `https://12` gives `0.0.0.12`; `urlFieldType.validate`
  returns `[]` for both and an error for `Calle 5`). Outside this batch
  (a field type's rule).
- ISO timestamps (`2026-11-19T10:30`) guess `date`, not `dateTime`:
  `date.parse` accepts a time part and drops it, and `date` comes first
  (`dateTime` is not in the default creatable list anyway). Spaced phone
  numbers (`81 1234 5678`, `+52 81 1234 5678`) guess `number`:
  `number.parse` removes spaces. Both follow the design's order.

### Notes for stage 2 (the component)

What the screen calls, in order (`ctx = { types: merged registry,
messages, fields: @fields }`):

1. The source: `@file` → `decodeText(await file.arrayBuffer())` →
   `parseCsv(text, { delimiter })` (the delimiter select re-parses);
   `@text` → `parseCsv`; `@matrix` as given. The file part shows
   `encoding` and the line count.
2. `headers` = the first line (with "First line is the header"), else
   `''` per column; `columns = matchColumns(headers, @fields,
   @savedMapping, { headers })`.
3. Per column, `guessColumn(ctx, texts, @creatableFieldTypes)` over its
   data texts (it samples 200 itself). An unmatched column without
   `taken`, with `@onCreateFields`, becomes `{ newField: { label: header,
   type: guess.type, ...guess.options } }`; a `taken` column says which
   column took its field. For a column mapped to an existing field the
   badge share is `1 - errors in that column / lines` of the dry run.
4. The value map table: `suggestValueMap(texts, field)` (select and
   checkbox targets); the user's edits go to `column.valueMap`.
5. Preview: `previewImport(ctx, matrix, plan, @transforms, { size:
   @sampleSize })`; its `fields` are the preview's column fields.
6. Dry run (debounced 250 ms): `runImport(ctx, matrix, plan,
   @transforms)`: "N lines ready" is `rows.length` minus the lines in
   `errors`; "M with errors" the distinct `errors[].line`; the column
   status filters `errors` by `column`; the link is `errorsCsv(matrix,
   run.errors, { headers, delimiter })`.
7. Import: the drafts are the `newField` targets in column order →
   `created = await @onCreateFields(drafts)`; replace each target with
   `{ field: created[k].id }`; `runImport({ ...ctx, fields: [...@fields,
   ...created] }, matrix, plan, @transforms, { skipLinesWithErrors })`;
   `@onImport({ rows, fieldIds, createdFields: created, skippedLines,
   mapping: { signature: importSignature(headers), columns } })`.
8. **Two columns can target one field.** `matchColumns` gives a field
   to one column, but the plan is the user's to edit and `runImport`
   does not stop a second column naming the same field: both go into
   `fieldIds`, and in `appendRows` the later one wins. The target select
   should take the field from the other column (or say it is taken).
9. **Without a header line** every header is `''`: `importSignature` is
   the same for every file of that width (a saved mapping then applies
   to any such file), and a transform's `row` has one key (`''`, the
   first column). The screen should save mappings only with headers, and
   may give such columns names (`Column 1`, …) before calling
   `matchColumns`.
10. **Decision needed:** the design's `SheetImportResult` has no
   `fields`, and its example passes `{ fields: result.createdFields }` to
   `appendRows`. That drops the per-column copies: an M/D/Y column of a
   D/M/Y field would be rejected (APR6 shows it). Stage 2 should add
   `fields: run.fields` to the result and the example should pass
   `{ fields: result.fields }` (it includes the created fields' copies
   too, by their real ids once step 7 replaced the targets).

### Open items

- The decisions above: `SheetImportResult.fields` (stage 2, note 10);
  a transform error's row text (deviation 12);
  rows full width vs `importMatrix`'s short rows (deviation 9); "empty is
  no value" for a text field in a sheet (deviation 8).
- No docs yet: `docs/sheet.md`'s import-screen section and the demo are
  stage 2's (the design's "Docs"). The helpers have doc comments.
- Not verified: a real Excel windows-1252 file (only hand-made bytes),
  UTF-16 files (not recognised: read as windows-1252, as the design's
  risk says), Firefox, Safari.

### Files

- New: `packages/sheet/src/core/import.ts`,
  `packages/sheet/tests/unit/import-test.ts`.
- Changed: `src/core/index.ts` (the export), `src/core/fields.ts`
  (`CREATABLE_FIELD_TYPES`), `src/core/delimited.ts`
  (`quoteDelimitedCell`), `src/core/csv.ts` (uses it),
  `src/-private/sheet/field-editor.ts` (imports the list).

### Commits

| Commit | Holds | Suite |
| --- | --- | --- |
| `a365483` | the paste fix (decision 10): `records.fillNewValues`, `pasteText`, `appendRows`; PNV1-PNV5; docs; its results | 662 / 662 |
| `edbf64e` | `src/core/import.ts` and the moves; IG1-IG3, IP1-IP5; these results | 670 / 670 |
| the follow-up commit | a transform error writes `''` in `rows`, skipped lines' unresolved cells left out (deviations 12, 13; IP3, IP4 assertions); corrections to these results | 670 / 670 |

One commit in this range is the main session's: `c5ca46f` (readiness
loose ends from batch C) before `a365483`.

## Batch E, stage 2: the import screen (10)

Built 2026-11-21 on `02f8585` (stage 1 and the main session's readiness
notes), in this checkout. Design: `v04/10-import-screen.md` ("API",
"Behaviour", "Code", "Tests", "Docs"), stage 1's "Notes for stage 2"
above, and decisions 14-17 of `v04/README.md` (recorded there by this
stage as the main session's recommendations; the user may overrule).
`packages/core/src` did not change; no dependency was added; nothing in
`src/-private/sheet/` or `eui-sheet.gts` changed.

### What was built

- **`<EuiSheetImport>`** (`src/components/eui-sheet-import.gts`,
  published as an app component: `package.json`'s `app-js` gets
  `./components/eui-sheet-import.js`, which is what the publish build's
  `appReexports` produces; the build left `package.json` unchanged), and
  its private parts in `src/-private/import/`: `column-row.gts` (one row
  of the columns table and its detail rows), `value-map.gts`,
  `new-field-form.gts`, `preview-table.gts`, `model.ts` (type labels,
  the draft from a guess, the value map's choices), `styles.ts` (its own
  `<style data-eui-sheet-import>`). Exported from `@ember-eui/sheet`
  (`EuiSheetImport`, `EuiSheetImportSignature`, `SheetImportResult`).
- **Arguments** as the design, with `@fieldTypes` for the design's
  `@types` (deviation 1). The source is `@file` (bytes →
  `decodeText` → `parseCsv`), `@text` or `@matrix`.
- **The screen**, as the design's three parts:
  1. The file: name, "Encoding: UTF-8 / Windows-1252", the delimiter
     select (`,` `;` tab; the detected one selected, `detectDelimiter`,
     now exported from `core/csv.ts`; a change re-reads the text), "First
     line is the header" (an `EuiSwitch`), the line count (data lines,
     without blank ones). The delimiter select is absent for `@matrix`.
  2. Columns: a table, one row per file column (the widest line's
     width): the header (`th scope=row`) and three non-blank samples; a
     badge: for a new or skipped column the first guess and its share
     ("Date, D/M/Y · 100%", hollow), for a column going to a field that
     field's type and the dry run's `1 - errors / lines` (green at 100 %,
     else yellow); the target select (writable fields, "New field…" with
     `@onCreateFields`, "Skip"); the transform select (with
     `@transforms`, "None" first); the options (Trim, Empty is no value,
     the date order for date/date-time, the decimal separator for
     number/currency/percent, a "Values (N mapped)" button for
     select/checkbox targets); the status ("8 of 8 read" or a "N can't
     be read" link that filters the preview to those lines). Under the
     row, when opened: the new-field form, or the value-map table.
  3. Preview: `previewImport` of `@sampleSize` lines (default 20), the
     line number (the file's, the header being 1), each cell's value or
     state (error with the message under the text, "linked on import",
     "new option"), new fields' headers marked "new"; then the totals
     from the dry run, "Download the lines with errors", and "Import all
     (errors stay as rejections)" / "Skip lines with errors" (an
     `EuiRadioGroup`, shown when there are errors). Buttons: Cancel (with
     `@onCancel`) and "Import N lines".
- **The calls are stage 1's notes, in order**: `matchColumns(headers,
  writable fields, @savedMapping (only with a header line), { headers })`;
  `guessColumn` per column over its data texts, with
  `@creatableFieldTypes`; an unmatched, untaken column becomes
  `{ newField: draftFromGuess }` with `@onCreateFields` (a column with
  no text, such as a trailing delimiter's, stays skipped, deviation 10); the value map is
  prefilled with `suggestValueMap` when a column's target is a select or
  checkbox; `previewImport` for the preview; `runImport` for the dry run
  (immediately for a new source, then 250 ms after the last change of the
  plan or of `@transforms`, a runloop timer under a test waiter); `errorsCsv(matrix, errors,
  { headers, delimiter: the file's })` for the download (a Blob with a
  UTF-8 BOM, `<name>-errors.csv`). On Import: the `newField` drafts in
  column order → `@onCreateFields(drafts)` once → each of those columns'
  target becomes `{ field: created[k].id }` at once (so a retry after a
  rejected `@onImport` creates nothing again) → `runImport({ ...ctx,
  fields: [...@fields, ...created] }, …, { skipLinesWithErrors })` →
  `@onImport({ rows, fieldIds, fields, createdFields, skippedLines,
  lines, values, mapping })`. A rejection of either shows its message in
  a danger call-out (`role=alert`); `aria-busy` and disabled controls
  while busy. A result of `@onCreateFields` whose length is not the
  drafts' is an error (`importCreateMismatch`).
- **The plan's state** is the proposal (recomputed from the source, the
  header choice, `@fields` and `@savedMapping`) with the user's changes
  per column on top, keyed to the parsed source and the header choice:
  a change of `@fields` (the owner adding the created fields) keeps the
  user's choices. A delimiter or header change starts from a new
  proposal.
- **Two columns on one field**: a field another column goes to is shown
  as "Item (in use by "Nombre")" and **disabled** in the other columns'
  selects (deviation 3); `setTarget` also frees a field from another
  column if a call ever names a taken one.
- **The new-field form is the sheet's field editor content**
  (`FieldEditorForm` from `field-editor.gts`: name, type, the type's
  `fieldOptions`, description, required). It needs no sheet, so the
  approved fallback (label and type only) was not needed. Its styles
  come from the sheet's `ensureStyles()` (called by the screen; the
  rules are not scoped to `.euiSheet`), its colours from the sheet's
  `sheetThemeVars` class on the screen's root. The name gets focus,
  Save changes the draft only, Escape and Cancel close it and give focus
  back to "Edit the new field". **Currency**: a currency guess's draft
  gets `currency: 'USD'` (the field editor's default) and the form shows
  the code to change.
- **Mapping**: `mappingOf` keeps `index`, `header`, `target` (created
  fields by id) and the options that are set; without a header line
  `mapping` is `null` and `@savedMapping` is not used (stage 1 note 9).
  Without a header line the columns are named `Column N` (the plan's
  headers too, so a transform's `row` has a key per column).
- **The preview shows the field's own format** (deviation 4).
- **Messages**: 60 keys `euiSheet.import*` in `core/messages.ts`
  (through `eui-i18n` as the sheet's, `@messages` over them; the first
  commit's message says 62, which is wrong); the screen also uses the
  existing `cancel`, `fieldDateOrder`, `dateOrderDmy`, `dateOrderMdy`,
  `fieldType_*`. No plural forms ("1 lines"), as the other messages.
- **Size**: the screen is its own module. Nothing reachable from
  `eui-sheet.gts` imports `eui-sheet-import.gts` or `-private/import/*`
  (checked by walking its relative imports: 134 files, none of them;
  `core/import.ts`, stage 1's pure helpers, is reachable through the
  core's barrel as before). In the publish build, `dist/components/
  eui-sheet.js` names none of the screen's modules; `dist/index.js`
  re-exports it (the package's `sideEffects` lets a bundler drop it).

### Tests

New file `tests/integration/components/eui-sheet-import-test.gts`, IW1-
IW12 (IW was unused). No existing test changed.

- **IW1** `Nombre,Precio,Fecha,Activo` × 25: Nombre by alias, Precio and
  Fecha by label, Activo skipped (no `@onCreateFields`); the badges
  (including the guess of the skipped column); three samples; "25 of 25
  read"; "25 lines"; preview headers and 20 rows; totals; "Import 25
  lines"; no download link; delimiter `,`; Cancel calls `@onCancel`.
- **IW2** a target (Activo → the checkbox field, value map prefilled
  "2 mapped"), two transforms, and the date order: the preview changes
  at once and the totals only after the debounce (checked with a
  dispatched change and `rerender()` before `settled()`), then "12 lines
  ready, 13 with errors", "13 can't be read", the badge "Date, M/D/Y ·
  48%"; the filter link shows the 13 lines (file lines 14-26) and "Show
  the first lines" back; a taken field is disabled in another column's
  select and not in its own; skipping a column frees it.
- **IW3** with `@onCreateFields`: the unmatched column is a new field
  ("New field: Activo (Checkbox)", "new" in the preview); its form (the
  field editor's name and type, focus on the name), a renamed draft,
  focus back; nothing created before Import; then one call with
  `[{ label, type: 'checkbox' }]`, and `@onImport` with the new id in
  `fieldIds`, `createdFields`, `fields[3]` the created field, rows,
  values, lines; the column now targets the created id.
- **IW4** without `@onCreateFields`: no "new" option in any select; a
  saved mapping's new-field column becomes Skip.
- **IW5** two bad prices: totals, the error cell's text and message; the
  download (`URL.createObjectURL` and the link's `click` stubbed): one
  Blob, `import-errors.csv`, a UTF-8 BOM, the header line and the two
  lines; "Skip lines with errors": 23 rows, `skippedLines` `[3, 7]`;
  "Import all": 25 rows, the bad text kept; a throwing transform writes
  `''` (decision 15).
- **IW6** a saved mapping with the same signature wins over the alias
  (target, transform, `trim: false` shown); `result.mapping` as saved,
  and passed back gives the same mapping and rows; another header line
  ignores it; without a header line: `Column 1-4`, by position, "4
  lines", `mapping` `null`.
- **IW7** a rejected `@onCreateFields` (message, no `@onImport`), a
  wrong count (`importCreateMismatch`), created then a rejected
  `@onImport` (message; the column on the created id; not busy), the
  retry creates nothing and reports the created field, a pending
  `@onImport` (`aria-busy`, disabled selects), then `createdFields` `[]`
  once reported.
- **IW8** end to end: a sheet and the screen on the same `@fields`;
  `@onImport` → `appendRows(rows, fieldIds, { fields })`: one change
  set, source `paste`, five inserts with `activo` true/false (a field
  `@fields` never has), no rejections; Ctrl+Z on a focused cell removes
  them.
- **IW9** every control in the screen (with the value map open) is a
  native button/select/input, tabbable, enabled and named
  (`aria-label`, `aria-labelledby`, `label[for]` or text); Import is the
  last; the target selects' names; Escape in the new-field form closes
  it and focuses its button. Tab itself and opening a select with the
  keyboard are not something a test can do; the real-input run did the
  Tab walk and keyboard selection.
- **IW10** (decision 14) `11/19/2026` into the D/M/Y field: 0 ready
  until the column's date order is M/D/Y, then 2; the preview shows
  `19/11/2026`; `result.fields[1]` is the M/D/Y copy, the field object
  unchanged; `appendRows` with `{ fields: result.createdFields }`
  rejects both dates, with `{ fields: result.fields }` inserts
  `2026-11-19` and `2026-12-31`.
- **IW11** a windows-1252 `File` (`Año;Precio;Señal`, `Peña;1,5;Sí`):
  "precios.csv", "Encoding: Windows-1252", delimiter `;`, the headers
  and preview with accents, `Año` matching the label `Ano`, the guesses
  "Number, Comma (1,5)" and "Checkbox"; the comma delimiter re-reads it
  (two columns: the header is one cell); the header switch gives
  `Column 1-3` and "3 lines".
- **IW12** (the last commit) a trailing delimiter on every line: the
  fifth column `Column 5` stays skipped while Activo goes to a new
  field, and Import creates only Activo's; a change of `@transforms`
  alone (the same id, now throwing) re-runs the dry run: "0 lines ready,
  4 with errors".

Suite: **681 tests, 681 pass** (baseline 670; +11 IW) on each of
`d6d978c` and `01e6e15`, and **682 tests, 682 pass** (+12 IW) on the
last commit's tree; one full run per tree, no retries. (A run on the
docs alone, before IW12, finished 681 / 681 but was stopped as its tree
was not the one committed.)

### Checks (before each commit, on its tree)

On `d6d978c`'s tree and again on `01e6e15`'s:

- `pnpm lint:types`: no error. The tests' `ember-tsc`: the baseline
  errors and no other (`diff` empty; a first draft had two TS errors in
  the new test, fixed before the commit).
- `eslint` and `prettier --check` on the changed `.ts`/`.gts` files:
  clean. (A first draft did not parse in ESLint: a `…` in a doc comment
  before a `<template>` shifts `ember-eslint-parser`'s offsets; the
  comments use `...` now.)
- Owner gate: OK (38 module classes; no module class changed).
- `node scripts/generate-api-docs.mjs --check`: exit 0.
- On `01e6e15`'s tree also: `pnpm lint:js`, `pnpm lint:css` (exit 0),
  `pnpm eui:check` at the root (exit 0), `pnpm build` in
  `packages/sheet` (exit 0; `dist/components/eui-sheet-import.js` and
  `dist/_app_/components/eui-sheet-import.js` built; not committed).
- On the last commit's tree, all of the above again: `lint:types`, the
  tests' `ember-tsc` (baseline only), `eslint`/`prettier --check` on the
  changed files, the owner gate, `lint:js`, `lint:css`, `eui:check`,
  `pnpm build`, `generate-api-docs.mjs --check`, and
  `generate-api-docs.mjs` itself (it regenerated nothing: `git status`
  unchanged; it reads no sheet source); README `prettier --check`
  clean.

### Deviations

1. **`@fieldTypes`, not `@types`**: the design says "`@types` … as
   `@types` of the sheet", but the sheet's argument is `@fieldTypes`;
   the screen uses the sheet's name. **The user's decision** if `@types`
   was meant.
2. **The result has more than the design's**: `fields` (decision 14),
   `lines` and `values` (for a target that is not a sheet: `runImport`'s),
   and `mapping` is `null` without a header line (stage 1 note 9).
3. **A taken field is disabled, not moved.** The first build moved the
   field from the other column when chosen. The real-input run showed
   why that is wrong with a native select: the arrow keys on a closed
   select fire `change` at every option, so stepping through the list
   took fields from other columns one by one (Precio lost its field
   while the keyboard went down Proveedor's list). Disabled options are
   skipped by the arrows. Fixed in the follow-up commit, IW2 changed
   with it.
4. **The preview formats with the target field**, not the per-column
   copy `previewImport` reads with: a column read as M/D/Y into a D/M/Y
   field shows `19/11/2026`, a decimal-comma column into a `.` field
   shows `0.25`, as the sheet will show them (the design: "the value as
   the target type formats it"). `previewImport` itself is unchanged (it
   formats with the copy, IP3 asserts it); the screen re-formats the
   cells (`asStored`). Found in the real-input run (the first run's
   preview showed `0,25` and the sheet `0.25`), fixed in the follow-up
   commit, IW2 and IW10 assert it.
5. **`detectDelimiter` is exported** from `core/csv.ts` (it was private):
   the screen shows the delimiter found. A new public helper.
6. **`readOnly: true` fields and buttons are not offered** as targets
   (stage 1 deviation 11), and they are left out of `matchColumns`, so
   a header naming one is unmatched (a new field with
   `@onCreateFields`).
7. **The column options for a new field are column options** (a copy of
   the draft), as for an existing field; the new field's own date order
   and options are the form's.
8. **The new-field form includes description and required** (it is the
   field editor's content as is); they go into the draft.
9. **Size**: the component is about 1,420 lines (the design estimated 350)
   and the private parts 845 (estimated 200): the template (about 260
   lines), the column view model, the doc comments, Prettier's
   formatting of the long argument lists.
10. **A column with no text is not a new field**: with
   `@onCreateFields`, an unmatched column whose data texts are all blank
   (a trailing delimiter, an empty spreadsheet column) stays Skip;
   otherwise one click on Import created an empty field that Ctrl+Z
   cannot remove. Found by the advisor review; the last commit, IW12.
11. **The 300 ms preview target is missed** on 10,000 × 20 (below, real
   input), and the design's clause "If not, the dry run moves to idle
   callbacks" was not applied: the profile shows the first dry run is
   about 110 ms of the ~430 ms, the rest is rendering the columns
   table's EUI controls, so the clause alone would not meet the target.
   The dry run's target (1 s) is met. **The user's decision.**

### Real input in Chromium

Production build of this checkout (the sheet's `pnpm build`, then
`site`'s `pnpm build`), served with `vite preview` (port 4185),
Playwright's Chromium (headless, 1300 × 900, `deviceScaleFactor` 2),
real `page.mouse` and `page.keyboard`, on the new demo d28 ("Import
screen", `localRecords`) on `/docs/sheet/docs/sheet`. The final run is
on the code of `01e6e15` and the demo as committed. **No page errors, no
console errors.** Selects were changed by the keyboard (focus, Home,
ArrowDown on the closed select), buttons and links by mouse clicks.

- **Sample file**: a mouse click on "Download sample file":
  `inventario.csv`, a UTF-8 BOM, the 8 Spanish lines (`;`).
- **Import…**: a mouse click opens the file chooser (Playwright's
  `filechooser` event), the sample set on it; the modal shows the
  screen: "inventario.csv · Encoding: UTF-8 · Delimiter Semicolon (;) ·
  First line is the header · 8 lines". Nombre → Item (alias), Precio →
  Unit price ("Number · 0%", "8 can't be read": a decimal comma into a
  `.` field), Fecha → Next count ("Date, D/M/Y · 87%", `31/02/2026`),
  Activo → Active ("Checkbox · 100%", "Values (2 mapped)"), Estado →
  Status ("Single select · 0%": Spanish texts, English options),
  Proveedor → "New field: Proveedor (Single select)" (the guess, its
  options the three suppliers), "new" in the preview's header.
- **Proveedor** by the keyboard: Skip (the badge stays, no status),
  then "New field…" back. "Edit the new field" (mouse): the field
  editor's form, name `Proveedor`, type `singleSelect`, the three
  options, focus on the name; Escape closes it, focus back on the
  button, the modal stays open.
- **Precio's decimal separator → Comma** (keyboard): "Number, Comma
  (1,5) · 87%", "1 can't be read" (`doce`); the preview shows `0.25`,
  `18.5`, `1250` (the field's own format).
- **Estado's values** (the Values button by mouse, each select by
  keyboard): Disponible → Available, Agotado → Out of stock, Poco
  stock → Low stock; "Single select · 100%", "8 of 8 read".
- **Fecha's date order → Month/Day/Year**: the totals at once still
  "6 lines ready, 2 with errors", 600 ms later "0 lines ready, 8 with
  errors", "Date, M/D/Y · 0%", "8 can't be read", the preview's dates
  marked `"15/11/2026" is not a date`; back to Day/Month/Year.
- **A transform**: Nombre → Upper case: `TORNILLO M6`, …,
  `MARTILLO DE UÑA` in the preview; totals "6 lines ready, 2 with
  errors", "Import 8 lines".
- **"1 can't be read"** on Precio (mouse): the preview shows line 6
  only (`doce`); "Show the first lines" back.
- **Download the lines with errors** (mouse; the download saved and
  read): `inventario-errors.csv`, a UTF-8 BOM, then
  `Nombre;Precio;Fecha;Activo;Estado;Proveedor` /
  `Taquete 1/4;doce;22/11/2026;Sí;Disponible;Ferretería Lupita` /
  `Llave Allen 5 mm;35,00;31/02/2026;No;Agotado;Herramientas Peña` (the
  file's own delimiter and texts).
- **Tab** from the delimiter select to Import, real Tab presses: 41
  stops in reading order: delimiter, header switch, then per column
  target, transform, trim, empty, the type's option, the Values button
  or "can't be read" link, the three value-map selects under Estado,
  "Edit the new field" under Proveedor, the download link, the radio
  group (one stop), Cancel, Import. Nothing skipped, no trap.
- **Skip lines with errors** (mouse on its label): "Import 6 lines";
  Import (mouse): the modal closes, the footer "inventario.csv: 6 lines
  imported, 2 skipped; new fields: Proveedor"; the sheet has a
  Proveedor column, rows 3-8 TORNILLO M6 / 0.25 / 15/11/2026 /
  Available / Aceros del Norte … MARTILLO DE UÑA / 1250 / 28/11/2026 /
  Available / Herramientas Peña.
- **Ctrl+Z** after a mouse click on row 1's Item: the six records gone
  (2 records left); the Proveedor field stays (field creation is not
  undoable, as `@onFieldCreate`).
- **The windows-1252 copy** (the script wrote the sample's text as
  latin1 bytes, no BOM; no UTF-8 sequences in it): "Encoding:
  Windows-1252", samples and preview `Ferretería Lupita`, `Herramientas
  Peña`, `CINTA MÉTRICA 5 M`, `MARTILLO DE UÑA`; the last mapping applied
  (Upper case, Comma, the value map, Proveedor → the created field);
  Cancel closes the modal. On a fresh page (no mapping),
  `light-9-preview-1252.png` shows the accents in the preview too.
- **Dark** (the header's theme switch): the same screen; text
  `rgb(180, 193, 213)`, table header `rgb(11, 22, 40)`, error text
  `rgb(246, 114, 106)`, the modal `rgb(17, 28, 44)`; the new-field form
  and the value map in dark.
- **First run, before `01e6e15`**: the keyboard steps down Proveedor's
  target list (Home, ArrowDown…) moved Item, Unit price, … from their
  columns one by one (each arrow fires `change`), and the preview
  showed `0,25` where the sheet shows `0.25`: deviations 3 and 4,
  fixed. (A first script also counted disabled options; fixed in the
  script.)
- **10,000 lines × 20 columns** (5 of the demo's columns and 15 extras
  that go to new fields; a temporary script on the same build, not
  committed): from the input's `change` event to the preview's first
  row 718 ms (first file), then 446 and 377 ms; a column's date order
  changed: the next frame 120-165 ms, its "can't be read" updated
  452-473 ms after the change (250 ms of it the debounce). The design's
  target for the preview (300 ms) **is missed**; the dry run's (1 s) is
  met. A CPU profile of one open (warm): about 430 ms in Glimmer's
  render, 109 ms of it the first dry run (`storeRun`), most of the rest
  rendering 20 rows of EUI controls (selects, switches, badges). The
  design's remedy (the dry run in an idle callback) would take the
  109 ms out of the first frame, not the rest: **the user's decision**
  (open items).
- Screenshots (not in the repo):
  `/tmp/claude-0/-home-user-ember-eui/87cd9e5a-212c-54c3-9d47-30ac398aebd2/scratchpad/v04e/`
  `light-1-opened.png`, `light-1-opened-screen.png`,
  `light-2-new-field-form.png`, `light-3-value-map.png`,
  `light-4-mdy.png`, `light-5-ready.png`, `light-6-imported.png`,
  `light-7-undone.png`, `light-8-windows-1252.png`,
  `light-9-preview-1252.png`, `dark-1-opened.png`,
  `dark-2-new-field-form.png`, `dark-9-preview-1252.png`; the downloads
  in `../v04e-files/`; the script's output in `results.json`,
  `real-input.log`. The agent looked at `light-1-opened-screen.png`,
  `light-5-ready.png`, `dark-2-new-field-form.png`,
  `light-9-preview-1252.png` and `dark-9-preview-1252.png`, not a
  person: readable in both themes; the error cells framed red with the
  message under the text; the value map and the form under their
  rows.
- **The bundle**: in the site's production build only the d28 demo's
  chunk (`docfy-demo-docs-sheet-d28-import-screen-*.js`) contains the
  screen (`euiSheetImport__`); the chunks of the other sheet demos do
  not.

### Open items

- **The 300 ms preview target is missed** on 10,000 × 20 (377-446 ms
  warm, 718 ms first): the user's decision whether to defer the first
  dry run (about 110 ms) and/or render fewer controls per row (e.g. the
  options behind a button).
- **The user's decisions**: `@fieldTypes` vs `@types` (deviation 1);
  the result's extra keys (deviation 2); disabled vs moved for a taken
  field (deviation 3, recommended: disabled); the preview's format
  (deviation 4); whether `importAliases` should also match a value-map
  option (today only labels and the yes/no words prefill).
- A guessed currency is always `USD` until the user edits the form; the
  sample's symbols (`€`, `MXN`) are not used to pick the code.
- Field creation is not undoable from the sheet (as `@onFieldCreate`):
  Ctrl+Z after an import removes the records, not the new field.
- No plural forms in the messages ("Import 1 lines").
- The value map lists the file's texts, but is applied after the
  transform: with a transform on a select or checkbox column, the
  listed texts may no longer be the ones mapped (it shows as errors,
  not silently).
- A new `@file` on the same instance keeps the last error message, the
  preview filter's column, the skip choice and the created fields (the
  plan itself starts afresh); apps that open the screen per file (a
  modal, as in d28) do not see it.
- The currency guess's `USD` default has no test and was not in the
  real-input run (the sample has no currency column).
- **Not verified**: Firefox, Safari, a screen reader (only the names
  and roles were checked), touch, a real Excel-made file (the
  windows-1252 copy was made by the script), UTF-16 files, `@matrix`
  from SheetJS (tested only as text and files), the EmberSearchUi
  connector (the screen is separate from it).

### Files

- New: `packages/sheet/src/components/eui-sheet-import.gts`,
  `packages/sheet/src/-private/import/{column-row,new-field-form,preview-table,value-map}.gts`,
  `packages/sheet/src/-private/import/{model,styles}.ts`,
  `packages/sheet/tests/integration/components/eui-sheet-import-test.gts`,
  `packages/sheet/docs/sheet-demo/d28-import-screen.md`.
- Changed: `src/core/csv.ts` (`detectDelimiter` exported),
  `src/core/messages.ts` (60 keys), `src/types.ts`
  (`SheetImportResult`, `EuiSheetImportSignature`), `src/index.ts`,
  `package.json` (`app-js`); `docs/sheet.md` ("The import screen" in
  "Import from CSV"), `README.md` (a paragraph);
  `internal/spikes/sheet/v04/README.md` (decisions 14-17),
  `v04/10-import-screen.md` (the result's `fields`, the example and
  IW8 pass `result.fields`).

### Commits

| Commit | Holds | Suite |
| --- | --- | --- |
| `d6d978c` | `<EuiSheetImport>`, `src/-private/import/*`, messages, types, exports, `detectDelimiter`, `app-js`; IW1-IW11 | 681 / 681 |
| `01e6e15` | a taken field disabled (not moved); the preview in the field's format; IW2, IW10 | 681 / 681 |
| the last commit | a column with no text stays skipped; `@transforms` re-runs the dry run (IW12); `docs/sheet.md`, README, d28, `v04/README.md` 14-17, the design's `fields`, these results | 682 / 682 |

One commit in this range is the main session's: `02f8585` (readiness
loose ends from stage 1) before `d6d978c`.

## Batch E: checked by the main session (2026-11-21)

- A new source in the same screen kept the last error, the preview
  filter, the open form and value map, and "Skip lines with errors". The
  screen's own state is now kept per source, like the delimiter and
  header choices (`currentUi` in `eui-sheet-import.gts`): a new `@file`,
  `@text` or `@matrix` starts from the defaults. The fields created on
  the way stay (they exist in the owner). IW13 checks it, and fails
  without the change.
- The site's checks, which no v0.4 batch had run: `pnpm lint` in `site/`
  (eslint, stylelint, template lint, Prettier, types) passes, and its
  `pnpm test` passes (`node --test`, 8; testem, 14).
- Open for the user: `@fieldTypes` (the sheet's name) rather than the
  design's `@types`; the 300 ms preview target, missed (see
  `READINESS.md`).
