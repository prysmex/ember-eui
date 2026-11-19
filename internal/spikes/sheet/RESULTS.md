# EuiSheet spike: results

Implemented 2026-11-19 on `master` at `13303391`, following `DESIGN.md`.
Run in the Linux sandbox (headless Chrome 155, `CI=1`) from a scratch copy.
Nothing committed.

## Short answer

- **No hook is needed.** With zero changes under `packages/core/src/` and
  to existing tests, all 15 integration cases (T1–T15) pass with
  `@cursorSource="dom"` (phase 1). H0 holds for everything the spike tests.
- **One hook is enough.** With the `cell-api` extension (3 marked lines, a
  32-line file, one marked expectation in the API test), T1–T15 pass with
  both `api` and `dom` (phase 2). No other hook was needed;
  `@onFocusedCellChange` (design 4.4) was not added.
- No ported grid file needed any change beyond the cell-api lines.
- Scope: synthetic events (`@ember/test-helpers`, `ClipboardEvent` with a
  `DataTransfer`) in headless Chrome 155, plus a pass with **trusted**
  keyboard and clipboard events in Chromium through Playwright (section 6).
  That pass found one sheet bug, fixed in the spike (D22); it needed no grid
  change. Firefox, Safari and IME still need the Mac (design 8.4).

## 1. Answers to design section 9

**Q1. Is one hook enough?** Yes. Phase 2 ran with the section-4.2 lines
only, plus `cell-api.ts`. All 30 integration runs (T1–T15 × api, dom), the
8 unit tests, the 2 contract tests, the `EuiDataGrid` filter (90 tests) passed;
the full suite has one failure, pre-existing on `HEAD` and unrelated (section 4). Logs:
`test-p2-spike-v4.log` (final spike code), `test-p2-cellapi-2.log`,
`test-p2-grid-post-lint.log`, `test-p2-full-final.log`.

**Q2. Is even one hook needed?** No. In phase 1 (`dom` source, no hook, no
`src/` change) T1–T15 all passed: first in `test-p1-dom.log`, while the repo
had only untracked spike files (`p1-git-status.log`: `git status` and an
empty `git diff --stat`), and again on the final spike code in
`test-p1-dom-final.log`, with the scratch copy's `src/` and existing tests
restored to `HEAD` and `cell-api.ts` and the contract test removed
(`p1-final-state.log`). Every key event the sheet handles targets the
focused cell; a real copy or paste can target an element inside it (the
cell's content, section 6). Either way the enclosing cell's
`data-gridcell-*` attributes give its position.

What `getFocusedCell` still buys, against its cost:

- Buys: the grid's focused position while that cell is not in the DOM
  (scrolled out of the rendered window). In the spike this never mattered:
  when the focused cell is unmounted, DOM focus is on `<body>` (asserted in
  T7 while scrolled away), so key and clipboard events target `<body>` and
  never pass through the sheet's wrapper (follows from event dispatch, not
  tested separately). It would matter
  for a sheet that acts on a key while focus is elsewhere (for example a
  toolbar button "edit focused cell"), or that wants the focused position
  in a `scroll` handler.
- Buys: no dependence on the cell markup attributes
  (`data-gridcell-visible-row-index`, `data-gridcell-column-index`,
  `data-gridcell-row-index`) and the `[role=gridcell]` selector. These are
  upstream EUI markup, so they are re-ported with the grid anyway; the
  `dom` source still needs `role`, `.euiDataGridFooterCell` and
  `.euiDataGridRowCell--controlColumn` to recognise a data cell, which the
  `api` source uses too (mode gating is DOM-based in both).
- Buys: the data row index under grid sorting (contract test 2 proves
  `rowIndex !== visibleRowIndex` round-trips through `setFocusedCell`). The
  `dom` source has this too (`data-gridcell-row-index`), and the sheet does
  not use grid sorting (design 5.1).
- Costs: 3 marked lines in 2 ported files, `cell-api.ts` (32 lines), one
  changed expectation in the ported `eui-data-grid-api-test.gts` (R14),
  and the contract test.

Recommendation from the evidence: drop the hook for now (H0). Add it when a
feature needs the focused position without a cell event.

**Q3. Which extra hooks were needed?** None. No failing test asked for one.
`@onFocusedCellChange` was not needed: the `focusin` listener on the
wrapper saw every focus move the tests make: arrows and Shift+arrows moved
by the grid (T4, T5, T7), `api.setFocusedCell` after commit (T1, T3, T15)
and cancel (T2, T8), click (T9), re-mount after scroll (T7, T10), and with
the `api` source `getFocusedCell()` already returned the new cell inside
`focusin` (R11: T4, T5 and all other `(api)` cases pass), so the grid's
capture `focus` listener (F7) runs first in Chrome.

**Q4. Does any upstream behaviour force a grid change?** No.

- F6 (focus on re-mount): T7 passes. It asserts that focus left with the
  unmounted cell (`document.activeElement === document.body` while
  scrolled away), that the re-mounted focused cell `(4, 1)` took focus
  again after scrolling back, and that the 6-cell range is still selected:
  `onFocusIn` ignores that focus because it equals the last position seen. T10 passes (scrolling while
  editing commits without refocus; no second change set, no error).
- F5 (`onTabularCopy` ignores `defaultPrevented`): T5 passes with and
  without a text selection inside the grid; `stopPropagation()` in the
  wrapper's capture listener keeps both document listeners from running.
  T5 carries a positive control: with the same selection (the whole grid,
  so it holds the copy markers), a `copy` dispatched on `document` is
  prevented and rewritten by the grid's handler (`name\tcity\tqty\nname0…`);
  the same event dispatched on the focused cell yields the sheet's TSV.
- F9 (tab management): T11 passes; the editor is outside the grid content,
  has no `tabindex="-1"` and no `data-euigrid-tab-managed`.
- F4 (Enter/F2 popover): T8 passes with `isExpandable: true` fields, and
  asserts the cell shows its expand button first (so without the sheet
  Enter would open the popover, as `eui-data-grid-keyboard-test.gts` shows).

**Q5. Does `setCellProps` scale for the selection?** At the size tested,
yes; at the size the design asked about, not measured. T7 logs
(`console.info`, visible in the testem "browser log"):

| Log | Source | Shift+ArrowDown → `settled()` | Rendered `[role=gridcell]` |
| --- | --- | --- | --- |
| `test-p1-dom.log` | dom | 11.0 ms | 24 |
| `test-p2-spike-final.log` | api | 10.0 ms | 24 |
| `test-p2-spike-final.log` | dom | 9.9 ms | 24 |
| `test-p2-spike-v4.log` (final code) | api | 11.0 ms | 24 |
| `test-p2-spike-v4.log` (final code) | dom | 10.9 ms | 24 |
| `test-p1-dom-final.log` (final code, no hook) | dom | 11.1 ms | 24 |

The 300px grid inside the test container renders only 8 rows × 3 columns,
so this does not stress R9's "~200 rendered cells". The number includes
`settled()` overhead (a run loop, an `afterRender` and the second render the
cell-props state causes). The class-toggle fallback was not needed here;
whether it is needed for a wide, tall grid is still open (measure with
~20 columns and a taller grid in the product spike).

**Q6. Does the sibling overlay hold?** Yes, in the tested setup. T11: the
input's box matches the cell's `getBoundingClientRect()` within 1px, the
editor is inside the sheet wrapper and outside `.euiDataGrid`, focused,
tabbable. It needed one fix (deviation D1): the design subtracted client
rects directly, which is wrong under an ancestor `transform` (the QUnit
container is scaled to 50%: the first run put a 50×9.75 box over a
100×19.5 cell). The sheet now divides by the wrapper's scale
(`getBoundingClientRect().width / offsetWidth`).

Not tested (the toolbar is hidden, so fullscreen is unreachable):
fullscreen and clipping ancestors. From the code: in fullscreen the grid's
focus trap (`focusTrap` on the grid's own wrapper, `isActive=isFullScreen`)
would not contain the editor, and the grid is fixed-position while the
editor is positioned in the sheet wrapper. Supporting it needs either a
portal into the grid's fullscreen element plus its own key handler, or a
grid slot that renders inside the grid wrapper but outside the content
element (a new hook). An `overflow: hidden` ancestor would clip the editor
only where it is larger than the cell (not the case now: it is the cell's
size).

**Q7. Manual check (8.4).** Not run: it needs the Mac (trusted events,
three browsers). The `demo (manual)` test is in place: `pnpm test:dev` in
`packages/core`, open `/tests/index.html?filter=demo&sheetdemo` (the `dom`
source, no hook needed) or `?filter=demo&sheetdemo=api` (the cell-api
source). It renders 50 records in a 400px grid and calls `pauseTest()`. Still to check there:
typing a letter gives one character; Cmd+C on a range then paste into a
spreadsheet; copy a block from a spreadsheet and Cmd+V on a cell; Esc and
Enter return focus to the cell; that `paste`/`copy` fire on the focused,
non-editable cell in Chrome, Firefox and Safari (R12). Tip: the QUnit
container is scaled to 50%; the overlay accounts for it (D1).

**Q8. Left for the product version** (unchanged from the design, plus what
the spike showed):

- IME (an always-mounted hidden input, still outside the grid).
- Sheet-owned sorting/filtering versus exposing `getCorrectRowIndex` for
  arbitrary rows.
- Tab in nav mode; Excel-style active cell on the anchor (today focus is on
  the moving end of a Shift+arrow range).
- Quoted TSV cells (cells with newlines from Excel).
- Undo from the `from`/`to` patches.
- Control columns (row numbers, checkboxes) shifting `colIndex`.
- What synthetic tests cannot show: R12 (trusted copy/paste/typing; manual check pending) and IME.
- `extending` stays true after a Shift+arrow until the next keydown or
  mousedown (T7 presses `Control` to reset it); a programmatic focus move
  in between would extend the range.
- `setCellProps` cost on large rendered windows (Q5).
- Fullscreen and clipping ancestors (Q6).

## 2. Test results

Phase 1: `@cursorSource="dom"`, no `src/` change (`SOURCES = ['dom']`).
Phase 2: cell-api extension added, `SOURCES = ['api', 'dom']`.
All cases are declared in one loop over `SOURCES` (brief overrides design
7.1, which ran T7–T15 with `api` only).

| Case | Phase 1 dom (`test-p1-dom.log`, `test-p1-dom-final.log`) | Phase 2 api (`test-p2-spike-v4.log`) | Phase 2 dom (`test-p2-spike-v4.log`) |
| --- | --- | --- | --- |
| T1 type-to-edit, Enter saves and moves down | pass | pass | pass |
| T2 Enter and F2 edit the current value, Esc cancels | pass | pass | pass |
| T3 Tab saves and moves right, Shift+Tab left, clamps | pass | pass | pass |
| T4 Shift+arrows select a range, Delete clears it | pass | pass | pass |
| T5 copy gives the range as TSV | pass | pass | pass |
| T6 paste a 2x3 block at the last row inserts a row | pass | pass | pass |
| T7 the selection class survives virtualization | pass | pass | pass |
| T8 the grid's Enter/F2 popover stays closed | pass | pass | pass |
| T9 clicking another cell commits and does not steal focus | pass | pass | pass |
| T10 scrolling while editing commits without a focus fight | pass | pass | pass |
| T11 the editor is outside the grid and tabbable | pass (after D1; failed in `test-p1-try1.log`, see below) | pass | pass |
| T12 arrows while editing do not move grid focus | pass | pass | pass |
| T13 header cells keep their keys | pass | pass | pass |
| T14 read-only fields | pass | pass | pass |
| T15 Enter on the last row keeps focus there | pass | pass | pass |
| demo (manual), not paused (outside the loop) | pass in `test-p1-dom-final.log` (added after `test-p1-dom.log`) | pass (outside the loop) | |

The first phase-1 run (`test-p1-try1.log`) had 14/15 passing; T11 failed
with: `editor box {"x":769,"y":438.25,"width":50,"height":9.75,…} matches
cell box {"x":769,"y":448.5,"width":100,"height":19.5,…}` (actual false).
Cause: a spike bug (D1), fixed in `eui-sheet.gts`; `test-p1-dom.log` is the
phase-1 run after the fix, still with no `src/` change.

Spike code versions: `test-p1-dom.log` ran the sheet code after D1. After
it, the sheet component changed only by Prettier layout; the tests changed
by the `SOURCES` flip, the `demo (manual)` test, the lint fixes (D15) and
the strengthened assertions (D19, D20). `test-p1-dom-final.log` (phase 1)
and `test-p2-spike-v4.log` (phase 2) both ran that final code, so both
columns reflect it. The run before the strengthening, `test-p2-spike-v3.log`,
failed T5 (api, dom) on a wrong expectation in my new control assertion
(`'name1\tcity1\tqty1'`; the fixture's `qty` is `'1'`), fixed in v4 (D21).

Unit tests (`Unit | Spike | EuiSheet change sets`), 8 tests, pass in both
phases: `toRange`, `parseTsv`, `toTsv(parseTsv(x))` round-trip,
`commitPatch`, `clearRange`, `pasteMatrix`, `rangeMatrix`,
`localRecords().apply`.

Hook contract (`Integration | Component | EuiDataGrid cell-api`), phase 2,
2 tests, pass (`test-p2-cellapi-2.log`): `undefined` after render, data cell
after `setFocusedCell`, header row `-1` after ArrowUp from row 0, unchanged
after `blur()`; with `@sorting` desc + `@inMemory` `sorting`,
`{ rowIndex: 3, colIndex: 2, visibleRowIndex: 0 }` and it round-trips
through `setFocusedCell`. The first run (`test-p2-cellapi.log`) failed the
sorting test with `waitUntil timed out`: a mistake in my test (it waited on
the cell's whole `textContent`, which includes screen-reader text); fixed
to read `[data-datagrid-cellcontent]`.

## 3. Deviations from the design

| # | Where | Deviation | Reason |
| --- | --- | --- | --- |
| D1 | `eui-sheet.gts` `startEdit` | Editor rect divided by the wrapper's scale. | Spike bug found by T11: client rects are screen px; the test container is scaled 50%. |
| D2 | integration test | All T1–T15 run per source (phase 1 `['dom']`, phase 2 `['api', 'dom']`). | The brief. |
| D3 | `eui-sheet.gts` `onScroll` | Ignores `scroll` events whose target is inside the editor. | An input scrolling its own text would otherwise commit the edit. Not covered by a test. |
| D4 | `eui-sheet.gts` `onPaste` | Ignores the paste when there is no range. | Needs a top-left; a data cell that got `focusin` always has one. |
| D5 | `eui-sheet.gts` `cursor` | `api` source returns `null` for the header row (`visibleRowIndex < 0`). | The sheet only acts on data cells. |
| D6 | `eui-sheet.gts` | `startEdit(pos, text, cell)` takes the cell element. | The rect is read from the event's cell, never from the DOM by position (design 5.1). |
| D7 | `local-records.ts` | `localRecords()` returns a `LocalRecords` instance; `apply` is an arrow property. | So `@onChange={{store.apply}}` is bound. |
| D8 | integration test | Waits with `waitUntil(() => document.activeElement === …)` before focus assertions in T2, T3, T8, T15 (design: T1 only), then asserts strictly. | Robust against a deferred focus; `waitUntil` fails the test on timeout, so nothing is loosened. |
| D9 | integration test, T6 | Asserts the insert's `index` and `values`, not its `tempId`. | The design's T6 lists only those; the unit test asserts `tempId: 'new-0'`/`'new-1'`. |
| D10 | integration test, T7 | Timing also emitted as an assertion message, and the rendered cell count is logged. | To make R9's number readable; testem shows `console.info` in "browser log", which is what was cited. |
| D11 | integration test, T2 | The document `keydown` listener is a bubble listener, removed in `finally`. | Leak hygiene; a capture listener on `document` runs before the wrapper and could not prove R7. |
| D12 | `sheet-editor.gts` | The input is styled inline (`display:block; box-sizing:border-box; width/height:100%; margin:0`); the style binding is `htmlSafe`. | "The input fills the box"; `tests/deprecations.ts` turns the style XSS warning into an error. |
| D13 | test runs | Filter `EuiSheet` instead of `Spike`. | `Spike` also matches 9 `Emotion spike` tests (`test-p1-try1.log`). |
| D14 | contract test | ArrowUp from `(0, 1)` reaches the header; the sorting test focuses `cell(0, 2)` with `element.focus()`. | Concrete steps for the design's description. |
| D15 | integration test | `focusCell` is `await focus(cell)` without the extra `settled()`; `demo (manual)` disables `ember/no-pause-test` for its one line. | ESLint (`ember/no-settled-after-test-helper`, `ember/no-pause-test`). |
| D16 | `cell-api.ts` | Prettier wrapped the `rowIndex:` ternary over two lines. | Formatting only; same code as design 4.1. |
| D17 | `eui-sheet.gts` `onFocusIn` | Extends only when an anchor exists (`this.extending && this.anchor`), else collapses. | A Shift+arrow before any cell was seen has no anchor to extend from. |
| D18 | `demo (manual)` | 50 records, `@height={{400}}`, source from the URL (`?sheetdemo` → `dom`, `?sheetdemo=api` → `api`). | A scrollable demo; and the `dom` default works if the hook is dropped. |
| D19 | integration test, T5 | The text selection is the whole `[role=grid]`, not one cell's content, plus a positive control (copy on `document` is rewritten by the grid). | Stronger: one cell's content holds no copy markers, so `onTabularCopy` would not have acted and the case could not fail. |
| D20 | integration test, T7, T8 | Added assertions: T7 focus is on `<body>` while scrolled away and back on `cell(4, 1)` after; T8 the expand button exists before Enter. | Stronger: make F6 and R4 observable. |
| D21 | integration test, T5 | Control expectation fixed from `'name1\tcity1\tqty1'` to `'name1\tcity1\t1\n'`. | My mistake in the new assertion (`test-p2-spike-v3.log`). |

No assertion of the design's T-table was weakened; no ported grid file was
changed beyond the cell-api lines.

## 4. Regression and static checks

Regression (phase 2, long testem config):

| Run | Log | Result |
| --- | --- | --- |
| filter `EuiDataGrid` (all grid modules, incl. the API test with the changed key list and the cell-api contract) | `test-p2-grid.log`, again after lint/format fixes `test-p2-grid-post-lint.log` | 90/90 pass, both runs |
| full core suite | `test-p2-full.log` | 2182 tests: 2179 pass, 2 todo, **1 fail** |
| full core suite after lint/format fixes | `test-p2-full-final.log` | 2182 tests: 2179 pass, 2 todo, 1 fail (the same combo-box test) |

The last full run predates D18–D21 (test-only changes in the spike test);
the spike filter re-ran after them (`test-p2-spike-v4.log`, 39/39) and in
phase 1 (`test-p1-dom-final.log`, 24/24).

The one full-suite failure is **pre-existing and unrelated**:
`Integration | Component | eui-combo-box upstream behavior > matching
(matching_options.ts): sortMatchesBy "none" and "startsWith" (upstream)`
(actual `…ething is Disabled … Something is Disabled,Dione`, expected
`Something is Disabled,Dione`). It fails the same way re-run alone with the
spike (`test-p2-combobox-rerun.log`, 34/35) and on a pristine `HEAD` copy
of `src/` and `tests/` (the three edited files restored with `git show
HEAD:…`, every new file removed from the scratch copy;
`test-baseline-combobox.log`, 34/35). This is a module-level baseline, not
a full-suite run on `HEAD`. The 2 todo tests are the
`leak-infra` LI-2/LI-3 todos.

Static checks (scratch copy, `packages/core`):

| Check | Log | Result |
| --- | --- | --- |
| `pnpm exec eslint` on the spike dirs, the contract test, the API test, `cell-api.ts`, `types.ts`, `eui-data-grid.gts` | `static-eslint.log` (first), `static-eslint-2.log`, `static-3.log` (final) | first: 3 errors in the spike test (2 × `ember/no-settled-after-test-helper`, 1 × `ember/no-pause-test`); then clean, and clean again after D19–D21 |
| `pnpm exec ember-tsc --noEmit` (covers `src/` only, so the hook) | `static-tsc.log`, `static-tsc-2.log` | exit 0 |
| `pnpm exec prettier --check` | `static-prettier.log` (all changed files), `static-prettier-2.log`, `static-3.log` (new files) | New files: formatted with the repo's `.prettierrc.js` and clean. The 3 edited ported files fail `--check`, but so do their `HEAD` versions (and e.g. `eui-data-grid-keyboard-test.gts`), so they were not reformatted. `RESULTS.md` and `DESIGN.md` both fail `--check` (tables not aligned); left as is. |
| `grep -rn "ember-eui extension (cell-api)" src tests` | `static-grep.log` | 4 lines: `eui-data-grid.gts:49` (import), `eui-data-grid.gts:1136` (`...cellApi(this)`), `types.ts:425` (`getFocusedCell?`), `eui-data-grid-api-test.gts:303`. Matches design 8.3 (3 in `src`, 1 in the API test). The `types.ts` JSDoc line and appended block, and the `cell-api.ts` header, say "Ember EUI extension (cell-api)" / "extension cell-api" (capitalised, as the design wrote them), so the case-sensitive grep does not count them. |

Lint fixes applied in the repo files (then re-synced): `focusCell` no
longer calls `settled()` after `focus()` (which already settles), T9 no
longer calls `settled()` after `click()`, and the `demo (manual)` test's
`pauseTest()` carries `// eslint-disable-next-line ember/no-pause-test`
(the design asks for that call). After these and the Prettier pass, the
spike filter passed again 39/39 (`test-p2-spike-post-lint.log`; T7 11.1 ms
api, 10.7 ms dom) and the grid filter 90/90.

## 5. Commands and logs

Scratch: `S=/tmp/claude-1000/-Users-betocantu93-prysmex/df04f7e2-a347-4eab-a276-4d9974f4dbc1/scratchpad`
(copy at `$S/ember-eui`, store `$S/pnpm-store`, logs in `$S/`). Left in
place for the orchestrator.

```bash
cd /Users/betocantu93/prysmex/ember-eui
git ls-files -co --exclude-standard -z | rsync -a --from0 --files-from=- ./ "$S/ember-eui/"   # after every edit
cd "$S/ember-eui" && pnpm install --frozen-lockfile --store-dir "$S/pnpm-store"              # once, $S/install.log
# $S/run.sh <log> <filter> [long]: from $S/ember-eui/packages/core
pnpm exec vite build --mode=development --out-dir dist-tests --emptyOutDir                   # $S/build-<log>
CI=1 pnpm exec testem --file testem.cjs ci --port 0 --test_page 'tests/index.html?hidepassed&filter=<filter>'
#   long runs: --file "$S/testem-long.cjs" (browser_disconnect_timeout: 86400)
```

| Log | What |
| --- | --- |
| `$S/install.log` | `pnpm install` |
| `$S/p1-git-status.log` | `git status` before the phase-1 runs (only untracked spike files) |
| `$S/test-p1-try1.log` | phase 1, first run, filter `Spike`: 31/32 (T11 failed, D1) |
| `$S/test-p1-dom.log` | phase 1, filter `EuiSheet`: 23/23 |
| `$S/test-p2-spike.log` | phase 2, filter `EuiSheet`: 38/38 (before the demo test) |
| `$S/test-p2-spike-final.log` | phase 2, filter `EuiSheet`: 39/39 (with the demo test) |
| `$S/test-p2-cellapi.log` | contract test, first run: 1/2 (test mistake) |
| `$S/test-p2-cellapi-2.log` | contract test: 2/2 |
| `$S/test-p2-grid.log` | filter `EuiDataGrid`, long config: 90/90 |
| `$S/test-p2-full.log` | full core suite, long config: 2179 pass, 2 todo, 1 fail |
| `$S/build-*.log` | the vite build of each run |
| `$S/test-p2-combobox-rerun.log` | the failing combo-box module alone, with the spike: 34/35 |
| `$S/test-baseline-combobox.log` | the same module on pristine `HEAD` `src/` + `tests/`: 34/35 (same failure) |
| `$S/test-p2-spike-post-lint.log`, `$S/test-p2-grid-post-lint.log` | spike and grid filters after the lint/format fixes: 39/39, 90/90 |
| `$S/test-p2-full-final.log` | full core suite after the lint/format fixes: 2179 pass, 2 todo, 1 fail |
| `$S/test-p2-spike-v3.log` | spike filter after D19/D20: 37/39 (T5 api/dom, D21) |
| `$S/test-p2-spike-v4.log` | spike filter, final code: 39/39 |
| `$S/p1-final-state.log` | scratch state for the final phase-1 run: `SOURCES = ['dom']`, no file differs from `HEAD`, no `cell-api.ts` |
| `$S/test-p1-dom-final.log` | phase 1 on the final code, filter `EuiSheet`: 24/24 (15 cases, demo, 8 unit) |
| `$S/static-*.log` | eslint, ember-tsc, prettier, marker grep |
| `$S/run.sh`, `$S/testem-long.cjs` | the run script and the long testem config |

## 6. Trusted events in Chromium (added by the orchestrator, 2026-11-19)

Synthetic tests dispatch every key and clipboard event on
`document.activeElement`, so they cannot show where a browser really sends
them. This pass used real input (Playwright `keyboard.press`, real clicks) on
the `demo (manual)` page with the `dom` source and no hook, served from the
built tests (`vite preview --outDir dist-tests`; `vite dev` cannot load
`tests/index.html` because `src/utils/eui/search-bar/date-format.ts` is
imported for a type that dev mode does not strip, unrelated to the spike).

| Check | Result |
| --- | --- |
| Click a cell, press `x` | Editor opens with `x` once, and has focus |
| Type `y`, press Enter | Cell saved as `xy`, focus on the cell below, no expansion popover |
| Shift+ArrowDown, Shift+ArrowRight | 2×2 range selected (`setCellProps` class) |
| Ctrl+C on the range | Trusted `copy` fires on the focused cell; the clipboard holds the range as TSV |
| Click another cell, Ctrl+V | **Failed first** (see D22), then: the 2×2 block lands at the cell, pasted area selected |
| Delete on the range | The four cells are empty, the next column unchanged |
| Enter, then Escape | Editor opens, closes, focus back on the cell |

**D22 (sheet bug, found here):** after a click, Chromium dispatches the
trusted `paste` (and `copy`) on the cell's content element
(`.euiDataGridRowCell__content`), where the browser's selection is, not on
the focused cell. `onPaste`/`onCopy` required `event.target === cell`, so
the paste was ignored. Fix in `tests/spikes/sheet/eui-sheet.gts`:
`isClipboardTarget(target, cell)` accepts the cell or any non-interactive
element inside it. New test **T16** (both sources) dispatches copy and paste
on the cell content. The grid needed no change. After the fix the
`EuiSheet` filter passes 41/41 (`test-verify-t16.log`).

## 7. Decision: the cell-api hook is dropped (2026-11-19)

The user chose to keep `EuiDataGrid` unchanged. Nothing in the spike needs
`getFocusedCell`, and the sheet is controlled (the owner sorts its records),
so visible and data row indexes stay equal and the hook's main use does not
arise.

- The hook is saved as `internal/spikes/sheet/cell-api.patch` (5 files: the
  2 marked files in `src/`, `src/utils/data-grid/cell-api.ts`, the marked key
  list in `eui-data-grid-api-test.gts`, the contract test). It applies
  cleanly to `master` at `13303391` (`git apply --check`).
- The working tree is back to `master` for every tracked file; only the
  untracked spike files remain.
- The sheet's default cursor source is now `dom`, and the integration tests
  run with `SOURCES = ['dom']`. The `api` path stays in the sheet code (it
  declares its own type), so restoring the hook is: `git apply
  internal/spikes/sheet/cell-api.patch`, then `SOURCES = ['api', 'dom']`.
- Bring it back when a feature needs the focused position while that cell is
  scrolled out of the DOM, or when the grid's own sorting is used (that also
  needs `getCorrectRowIndex` exposed).
- `data-grid-extensions.md` gets no `cell-api` section.
- Verified after the revert, from a fresh scratch copy of the hook-free
  checkout: `EuiSheet` filter 25/25 (T1–T16 with `dom`, 8 unit tests, the
  demo; `test-nohook-sheet.log`) and `EuiDataGrid` filter 88/88 (the earlier
  90 minus the 2 contract tests now in the patch; `test-nohook-grid.log`).
  ESLint and Prettier are clean on `tests/spikes`, `tests/integration/spikes`
  and `tests/unit/spikes`.

## 8. The code moved to `packages/sheet` (2026-11-19)

The spike became `@ember-eui/sheet` v0.1 (`PACKAGE-DESIGN.md`,
`PACKAGE-RESULTS.md`). Its code under `packages/core/tests/spikes/`,
`tests/integration/spikes/` and `tests/unit/spikes/` is deleted on branch
`feat/sheet`, after the package's `Sheet` filter passed; core's
`EuiDataGrid` filter still passes 88/88 without it. Not committed yet: the
commit that moves it is the one that adds `packages/sheet`. This folder
(`DESIGN.md`, `RESULTS.md`, `cell-api.patch`) stays.
