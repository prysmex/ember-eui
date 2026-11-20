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
  room of the drag icon and menu button, which collapse until hover) and
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
  record's flyout at the top, all undone on exit.
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

Suite per commit (each a full run on that commit's tree, the other
batch A work set aside): 602, 609, 614, 620, 624, 625, all passing. In
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
   grid's own lowers a fixed EUI header to 997 and moves flyouts to the
   top. A separate commit after 05; FS8.
8. **Escape that ends full screen is the sheet's, on a cell** (`keys.ts`,
   the fall-through after the range collapse), not a bubbling listener
   on the wrapper: a header, the toolbar and app controls keep Escape.
9. Smaller: `contentWidth` takes a fourth `context` argument (a select
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
  rows-test RW and VP1).
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
  tested); fitting with `@frozenFields` (the frozen layout follows a new
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
| the docs commit | docs, d24, d25, these results | (no code; 625 carried over) |

`3979f3d` (the readiness plan, `internal/spikes/sheet/READINESS.md`) sits
between `55f8f4c` and `5ebb56d`: the main session's, not this batch's.
