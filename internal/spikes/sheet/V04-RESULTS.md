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
