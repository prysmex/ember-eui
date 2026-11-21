# `@ember-eui/sheet`: readiness batch, results

Results of the readiness batch (READINESS.md). Sections are added as the
items are done.

## Performance: scrolling

Done 2026-11-21, on `feat/sheet` after `581d4e4`, the plan in
READINESS.md's item 2 ("Scroll profile", "The plan, in order", "The
user's rule for (3)").

### How it was measured

The harness is in `perf-checks/` (README there): production docs build
(each package's `pnpm build`, then `site`'s `pnpm build`), `vite
preview`, Playwright's Chromium (headless, 1400 × 900, device scale 2),
real `page.mouse.wheel` on d08 ("Employees", 10,000 records × 31
fields).

- **Counts** (`count-tags.js`): Glimmer's tag computes, re-walks (the
  `lastChecked !== $REVISION` branch) and tracked writes (`dirtyTag`) per
  120 px wheel step, the template chunk instrumented
  (`instrument.mjs`), median of 12 steps; each number below is the median
  of 3 runs, and the 3 runs agreed exactly in every case.
- **Profile** (`profile-scroll.js`): a CPU profile and frame times over
  40 wheel steps down, 20 right, 20 up. Median of 3 runs, with the four
  builds (baseline, after step 1, after 2, after 3) served side by side
  and run in turn (run 1 of each, then run 2, …), because wall and busy
  time move by 10-30 % between sessions of this sandbox. Frame times come
  in 16.7 ms quanta.
- **Cases**: plain; `selected` (the Name cell of row 3 clicked first, so
  the fill handle is shown while scrolling, the usual state); `frozen`
  ("Freeze the first field" on: the frozen grid renders all 31 cells of
  each row).

Two corrections to the main session's profile on the way:

- Its "frozen" runs clicked the d08 description paragraph (whose text
  contains "Freeze the first field"), not the switch: the counts were
  identical to the plain ones and a row rendered 12 cells. So "frozen or
  not alike" in READINESS.md was the unfrozen grid twice. The harness now
  clicks the switch and fails unless a row renders 31 cells. Really
  frozen, d08 does about 11 % more re-walks per step and its frame p90 is
  about 80 % higher (below).
- "About 35 % of CPU is tag compute" was a share of all profiled time;
  `tagShare` here is `[TAG_COMPUTE]` self time / busy time (profiled time
  without idle), so it reads about 54 % for the same baseline.

### Numbers

Re-walks per 120 px step (tag computes in brackets), medians of 3:

| Build                       | plain               | selected | frozen                | frozen, selected |
| --------------------------- | ------------------- | -------- | --------------------- | ---------------- |
| Baseline (`581d4e4`)        | 947,048 (2,186,120) | 947,122  | 1,050,015 (2,475,373) | 1,050,085        |
| Step 1, chips               | 941,688 (2,174,401) | 941,756  | 1,044,456 (2,463,652) | 1,044,520        |
| Step 2, scroll placing      | 705,670 (1,634,771) | 705,709  | 781,861 (1,857,395)   | 781,897          |
| Step 3, core `setCellProps` | 476,539 (1,155,882) | 476,589  | 528,987 (1,339,356)   | 529,073          |
| Whole plan                  | **-49.7 %**         | -49.7 %  | **-49.6 %**           | -49.6 %          |

Tracked writes per step:

| Build    | plain / selected | frozen |
| -------- | ---------------- | ------ |
| Baseline | 22               | 25     |
| Step 1   | 15               | 18     |
| Step 2   | 14               | 17     |
| Step 3   | 11               | 11     |

The 11 left are all during the grid's render (Glimmer's `{{#each}}`
`retainItem`/`moveItem` and the grid's `scrollVersion` in `syncWindow`),
none after it.

Profile, four builds interleaved, medians of 3 (frame median 16.7 ms in
every run):

| Build    | Case     | frame p90 | frames > 50 ms | busy      | `[TAG_COMPUTE]` of busy |
| -------- | -------- | --------- | -------------- | --------- | ----------------------- |
| Baseline | plain    | 100.1 ms  | 69             | 8,499 ms  | 54.5 %                  |
| Step 1   | plain    | 116.7 ms  | 78             | 9,243 ms  | 57.7 %                  |
| Step 2   | plain    | 100.0 ms  | 66             | 7,802 ms  | 49.4 %                  |
| Step 3   | plain    | 99.9 ms   | 74             | 7,912 ms  | 48.0 %                  |
| Baseline | selected | 116.6 ms  | 71             | 8,641 ms  | 55.1 %                  |
| Step 1   | selected | 116.6 ms  | 73             | 8,924 ms  | 55.9 %                  |
| Step 2   | selected | 100.0 ms  | 68             | 7,875 ms  | 52.2 %                  |
| Step 3   | selected | 100.0 ms  | 65             | 7,526 ms  | 47.2 %                  |
| Baseline | frozen   | 183.4 ms  | 62             | 12,221 ms | 46.8 %                  |
| Step 1   | frozen   | 183.3 ms  | 61             | 12,445 ms | 47.8 %                  |
| Step 2   | frozen   | 166.7 ms  | 61             | 11,227 ms | 40.9 %                  |
| Step 3   | frozen   | 150.1 ms  | 62             | 10,109 ms | 33.6 %                  |

Reading them: the re-walks halve, deterministically. The frame times
move much less: frozen p90 -18 % and busy -17 %, plain p90 flat (one
quantum either way between runs) and busy -7 %, selected p90 -14 % and
busy -13 %. Step 1's plain row (p90 up one quantum, busy +9 %) is noise of
this kind: an earlier two-build A/B of baseline against step 1 in the same
session read the opposite way (p90 133.3 -> 116.7 ms, busy 10,708 ->
9,488 ms), and step 1 does not change the re-walks. What is left of a
frame is not only revalidation: in the step 3 profile `[TAG_COMPUTE]` is
48 % of busy time, `(program)` (native work: layout, style, DOM) about
22 %, GC 5 %, the grid's own code 4 % and the sheet's code 2 %
(`onScroll` 99 ms over the 80 steps).

### Step by step

1. **Chips without `EuiBadge`** (`5dc052e`, sheet). The select,
   multi-select and linked-record cells render a light span
   (`cells/chip.gts`) with EuiBadge's DOM, classes and `title` (from the
   text, as `innerText` reads it). Writes 22 -> 15 per step (the
   `innerText` set after render and the `ref` cleared in `willDestroy`
   are gone from the writers' list), re-walks -0.6 %. Alone it removes
   no render pass, because the grid's `setCellProps` write lands in the
   same after-render pass; it is what lets step 3 remove that pass. An
   experiment build with step 2 and without step 1 (single runs; the
   counts never varied between runs): 709,807 re-walks with core's write,
   709,700 with the write suppressed; with step 1: 705,670 and 470,843.
   (Step 1's commit message calls 470,843 "with steps 2 and 3"; it is
   this suppressed-write upper bound, the real step 3 gives 476,539.)
   The user cell (`EuiAvatar`) has no such write and was not changed.
   Tests CHP1-CHP5.
2. **The parts over the grid placed without `layoutTick` on scroll**
   (`ac281da`, sheet). "Bump it only when an outline or the fill handle
   is shown" would not have helped the usual case: one selected cell
   shows the fill handle. So each shown part (range outline, copy mark,
   flash, fill target, fill handle, selection handles) registers its
   placing with `scroll.placeOnScroll` from its modifier, and `onScroll`
   schedules them after the render, as the tick's re-render did.
   `layoutTick` stays for column and full-screen changes. Re-walks
   -25.1 % (plain, selected and frozen alike). Tests TK1-TK4.
3. **Core `setCellProps`** (`74e4771` and the follow-up fix `5adfb2c`,
   `packages/core/src`). See the decision below.
4. **Fewer tracked reads per cell view**: not done (below).

### The core decision (the user's rule)

Rule: change `packages/core/src` "only and only if" the numbers justify
it, measured after steps 1 and 2: at least -25 % re-walks per step or
-20 % frame p90 (median of 3), and core's own tests green.

- **Upper bound first:** core's built `cell.js` patched so the
  `cellPropsState` write never happens (props lost, numbers only), after
  steps 1 and 2, single runs: re-walks 705,670 -> 470,843 (-33.3 %),
  frozen 781,861 -> 522,265 (-33.2 %).
- **The change:** the props are kept untracked and put on the cell
  element after the render that set them: `class`, `style` and
  `data-test-subj` as the same strings the template renders (the getters
  still include the props, so a later render writes the same values),
  other attributes as before. A modifier holding the element re-applies
  them when the cell shows another row or column. Only `isExpandable`,
  which changes what the cell renders, stays tracked; a cell whose
  invoker also sets `class`, `style` or `data-test-subj` (a custom body's
  `Cell` with `...attributes`) re-renders them through a tracked revision,
  as before.
- **A follow-up fix (`5adfb2c`):** a review of `74e4771` found an
  untested path. Cells are kept by column index, so a column reorder or
  a sort makes a cell element show another column or row. Glimmer does
  not rewrite an attribute whose new value equals what it last wrote
  itself, so when the new column's renderer set no props, `74e4771`
  took the cell's own attributes (still holding the old props, written
  by `applyCellProps`) for an invoker's, and kept the old class and
  `data-test-subj`. The cell now remembers what `applyCellProps` last
  wrote. New tests SCP5 (a column swap) and SCP6 (the swap where the new
  column's renderer sets nothing): SCP6 fails on `74e4771`, passes on the
  old cell and on the fix. The counts are unchanged by the fix.
- **Measured:** re-walks 705,670 -> 476,539 (-32.5 %) plain, 705,709 ->
  476,589 selected, 781,861 -> 528,987 (-32.3 %) frozen; writes 14 -> 11
  and 17 -> 11. Frame p90: plain 100.0 -> 99.9 ms, selected 100.0 ->
  100.0 ms, frozen 166.7 -> 150.1 ms (-10 %). **Justified by the re-walk
  criterion (-32.5 % against 25 %); the p90 criterion alone would not
  have justified it.**
- **Core's tests:** `pnpm test` in `packages/core` (its full suite). On
  `74e4771`: 2145 tests, 2143 pass, 2 todo, 0 fail; the same totals with
  the old `cell.gts` and SCP1-SCP4. On `5adfb2c`: 2147 tests, 2145 pass,
  2 todo, 0 fail. SCP1-SCP6 and the existing `setCellProps` test also
  pass on the old `cell.gts`: `setCellProps`' public behaviour is
  unchanged. Core's `lint:types` and `lint:css` pass; its `lint:js`
  reports 3 errors, in files neither commit touches
  (`tests/addon-app-modules.ts`, `tests/integration/leak-infra-test.gts`,
  `tests/integration/leaks/components-teardown-test.gts`; they and the
  eslint config are unchanged since `581d4e4`, so they are taken as
  pre-existing; lint was not run at `581d4e4` itself). eslint on the
  changed files passes.

### Screenshots compared

- `shots.js` on the baseline build and on each step's build: every sheet
  of the docs page that shows chips (16 sheets, d08 and the select-heavy
  d15 "Products" and d16 among them), light and dark, plus the chips' DOM
  (classes, `title`, attributes, inner spans, `innerText`, width). Two
  baseline runs are pixel-identical to each other (no noise floor). After
  step 1 and after step 3: the chips' DOM identical in all 16 sheets;
  dark pixel-identical; light pixel-identical except 26-31 pixels (at
  most 6/255 per channel) in an `arrowDown` icon of two demos' toolbars
  ("Expand all" above "Tasks", and "Sheet"), not in a chip or a cell. On
  the final build (`5adfb2c`) all 16 sheets are pixel-identical to the
  baseline in light and dark, so those icon pixels came with a build, not
  with the change. The step 2 build alone was not screenshotted.
- `shots-d08.js` on the baseline and step 3 builds (`74e4771`, and again
  on `5adfb2c`): d08 frozen, a range selected (Name and Department of rows
  3-4, real clicks), then 3 wheel steps down, 3 right and 3 back up: all
  four screenshots pixel-identical, and the attributes of every rendered
  cell (classes in the same order, styles, `aria-*`, row numbers)
  identical. On `5adfb2c` also not frozen (the grid then virtualizes its
  columns): the same, identical.
- Kept in `perf-checks/shots/`: d08 with the range and the fill handle
  (step 3 build) and d15 "Products" light and dark (step 3 build).

### Not done, and why

- **Step 4 (fewer tracked reads in `cellView`).** The plan made it
  conditional on a profile showing it matters after steps 1-3. It does
  not show it directly: the sheet's own code is about 2 % of busy time and
  `cellView` is not among the top functions. The remaining cost is
  Glimmer's re-walks (48 % of busy time, 476,539 per step), spread over
  the grid's and the sheet's tags; how many of them `cellView`'s reads
  account for would need its own experiment (for example the counters on
  a grid with a trivial cell). Left for a later batch with that
  measurement.
- The remaining writes come from the grid's own scrolling (`{{#each}}`
  sync, `scrollVersion` in `syncWindow`); not touched.
- Step 1 alone does not help on d08 (-0.6 % re-walks, the frame numbers
  within noise); it was committed as the precondition for step 3's gain
  (above). Its commit message calls 470,843 "with steps 2 and 3": that is
  the suppressed-write upper bound; the real step 3 gives 476,539. The
  frame numbers in its message come from an earlier two-build A/B and
  read the other way from the four-build campaign above.
- TK3 and TK4 (the outline and handle follow a scroll) were not run on
  the tree before step 2. The experiment counts (step 2 without step 1,
  the upper bound) are single runs.
- READINESS.md itself is not edited; the correction of its "frozen or
  not alike" is the one in this file.
- Not measured here: 50,000 and 100,000 records, CPU throttling, a range
  drag, paste and undo (READINESS.md item 2's other parts); other
  browsers and real devices.
- The harness files are not linted by eslint (the repository's eslint
  has no configuration for `internal/`); they are Prettier-formatted and
  pass `node --check`.

## Performance: at scale

Done 2026-11-21, on `feat/sheet` after `46a7fbe`: READINESS.md item 2's
parts the scrolling stage left (10,000, 50,000 and 100,000 records, CPU
throttling, a range drag, a paste of 1,000 lines and its undo), and a look
for further gains.

### How it was measured

- **A page of its own** (`perf-checks/build-large.sh`, `large-page/`): the
  d08 demo (Code, Name, Department, Hours, Start, Active and 24 "Week"
  number fields: 30 fields, 31 cells per row with the row numbers) with its
  size from the URL, in a production docs build into a scratch directory.
  The page is copied into the sheet's docs only for that build and removed
  after it: d08 and the published docs are unchanged, and no public API
  changed. The records are generated when the page loads (`generate`: about
  50 ms at 10,000, 400-600 ms at 100,000; `localRecords()` under 1 ms); the
  sheet mounts on a "Mount" button, so its first render is timed alone.
  `mode=grid` renders a plain `EuiDataGrid` with a trivial cell and the
  same columns instead (the step-4 experiment).
- **The scenarios** (`perf-checks/scale.js`), on one page in this order,
  Playwright's Chromium (headless, 1400 × 900, device scale 2), real input:
  1. first render: the click on "Mount" to the first frame with rows;
  2. scroll: 10 wheel steps of 120 px, each waited out (the step's time: the
     wheel event to the end of the frame its render took), then 40 quick
     steps 30 ms apart (frame median, p90, frames over 50 ms);
  3. a range drag: mouse down on Name of row 2, 14 moves to Week 3 of row 9,
     mouse up (the median move: the mousemove to the end of the next
     frame; the mouseup the same way);
  4. a paste of 1,000 lines × 6 fields (Name, Department, Hours, Start,
     Active, Week 1) on Name of row 2: 5,443 patches of existing records
     (the rest equal what is there), no inserts. **Through the real
     clipboard**: `context.grantPermissions(['clipboard-read',
'clipboard-write'])`, `navigator.clipboard.writeText`, read back and
     compared (it matched in every run), then a real Ctrl+V, which fires a
     real `paste` event in headless Chromium. Its time: the keydown to the
     end of the first frame with the pasted text on screen; `to onChange`
     is the keydown to the demo's `onChange`, `apply` the demo's
     `store.apply` (the owner's cost, not the sheet's);
  5. its undo (Ctrl+Z), the same way.

  Every time runs from the input event's `timeStamp` to the end of the
  first frame after the result is on screen (the task after the next
  `requestAnimationFrame`); the harness waits for the event to reach the
  page first (a wheel event can arrive after Playwright's call returns: the
  first version of the script timed some steps from the previous wheel
  event and read 140 ms instead of 70). CPU throttling: CDP's
  `Emulation.setCPUThrottlingRate` 4, set after the page has loaded.

- **Counts** (the instrumented template chunk, unthrottled, deterministic):
  tag computes, re-walks and tracked writes of each scenario.
- **Builds compared interleaved** (`run-scale.sh`: run 1 of every case on
  build A, then on B, then run 2, …), medians of 3 (`median-scale.mjs`).
  The matrix's raw results are in `perf-checks/results-at-scale.jsonl`.

### Numbers

Base: the sheet at `46a7fbe` (before this stage); after: `53a3a52` (the
record lookup below). 3 runs each, interleaved, ms, median of 3:

| Records, CPU     | Build | first render | scroll step | scroll p90 | > 50 ms | drag move | paste     | (to onChange) | undo      | (to onChange) |
| ---------------- | ----- | ------------ | ----------- | ---------- | ------- | --------- | --------- | ------------- | --------- | ------------- |
| 10,000 ×1        | base  | 418.6        | 87.8        | 33.4       | 2       | 46.0      | 89.4      | 21.1          | 72.0      | 9.4           |
|                  | after | 308.4        | 82.0        | 33.4       | 3       | 46.5      | 84.8      | 15.3          | 66.7      | 6.8           |
| 50,000 ×1        | base  | 349.3        | 83.5        | 49.9       | 5       | 46.5      | 125.6     | 38.7          | 143.1     | 47.3          |
|                  | after | 326.3        | 93.1        | 33.4       | 6       | 46.0      | **99.3**  | 14.8          | **70.7**  | 7.0           |
| 100,000 ×1       | base  | 352.7        | 74.0        | 33.4       | 4       | 45.2      | 187.2     | 69.0          | 256.3     | 95.2          |
|                  | after | 373.8        | 83.2        | 50.0       | 11      | 45.8      | **106.3** | 14.2          | **73.4**  | 10.2          |
| 10,000 ×4        | base  | 1,595.1      | 313.5       | 216.7      | 39      | 126.9     | 332.7     | 78.3          | 292.0     | 54.3          |
|                  | after | 1,682.2      | 283.6       | 200.0      | 42      | 129.3     | 321.1     | 63.8          | 254.0     | 24.5          |
| 50,000 ×4        | base  | 1,522.2      | 290.3       | 216.7      | 41      | 126.8     | 548.0     | 195.4         | 573.9     | 174.3         |
|                  | after | 1,411.3      | 277.4       | 216.7      | 41      | 128.2     | **352.5** | 61.2          | **286.5** | 30.2          |
| 100,000 ×4       | base  | 1,407.7      | 253.5       | 200.1      | 41      | 143.0     | 908.1     | 350.4         | 1,089.5   | 529.7         |
|                  | after | 1,482.5      | 300.5       | 200.0      | 41      | 121.8     | **417.1** | 64.2          | **348.1** | 36.7          |
| 10,000 frozen ×1 | base  | 521.9        | 130.4       | 100.0      | 37      | 60.7      | 145.4     | 23.2          | 103.2     | 8.8           |
|                  | after | 551.1        | 129.0       | 83.4       | 37      | 50.1      | 145.0     | 18.6          | 99.1      | 6.2           |

The demo's own `store.apply` is 1-5 ms unthrottled and 8-22 ms at ×4 in
both builds (not in the table). Scroll, drag and first render are not
touched by the change: their differences between the builds are this
sandbox's noise (for example 100,000 ×1 scroll p90 33.4 / 50.0 ms, one
quantum, with the per-run values overlapping), and so is the 10,000 ×1
first render (418.6 / 308.4 ms; its runs range 270-420 ms in both).

Reading them:

- **What grows with the record count** (base, ×1, 10,000 -> 100,000):
  paste 89 -> 187 ms and undo 72 -> 256 ms, all of it before `onChange`
  (21 -> 69 and 9 -> 95 ms); at ×4 paste 333 -> 908 ms and undo 292 ->
  1,090 ms. First render, a scroll step and a drag move stay flat (first
  render 350-420 ms unthrottled, 1.4-1.6 s at ×4; a step 75-90 ms, a drag
  move 45 ms). After the change paste and undo are flat too (85-106 ms and
  67-73 ms unthrottled; 321-417 ms and 254-348 ms at ×4).
- **What is left** in a paste at 100,000 ×4 (417 ms): 64 ms before
  `onChange` (parsing and planning the 6,000 cells), 22 ms the owner's
  apply, the rest the render of the pasted range, the flash and the
  selection, about as at 10,000 (321 ms). Not changed further.
- **At ×4 every interaction is slow on this machine, at any size**: a
  scroll step 250-310 ms, frame p90 200-217 ms and about 40 frames over
  50 ms during the 40 quick steps; a drag move 120-140 ms; first render
  1.4-1.7 s. That is the per-render cost (below), not the data size. (The
  quick steps' frame statistics include the idle frames of the wait after
  them, 500 ms × the throttle rate, which is why the median stays 16.7 ms;
  compare p90 and the count over 50 ms, not the median.)
- **Frozen** (10,000 ×1): a step 130 ms and frame p90 83-100 ms, against
  82-88 ms and 33 ms unfrozen; first render 520-550 ms against 310-420 ms.
  The frozen grid renders all 31 cells of each row (below).

Counts per scenario (current build, instrumented, unthrottled; the 10 scroll
steps and 14 drag moves summed; deterministic except first render, whose
counts vary from run to run with the measuring):

| Case                             | scroll, 10 steps                                  | drag, 15 events         | paste               | undo                |
| -------------------------------- | ------------------------------------------------- | ----------------------- | ------------------- | ------------------- |
| sheet 10,000                     | 673,633 re-walks (1,858,971 computes), 110 writes | 336,384 (1,052,333), 17 | 36,887 (234,599), 6 | 37,108 (232,021), 9 |
| sheet 100,000                    | 673,633 (1,858,971), 110                          | 336,384 (1,052,333), 17 | 36,887 (324,599), 6 | 37,108 (322,021), 9 |
| sheet 10,000 frozen              | 1,188,459 (3,703,187), 110                        | 589,484 (2,095,052), 17 | 66,757 (484,689), 6 | 67,206 (483,995), 9 |
| plain grid, trivial cell, 10,000 | 1,492,837 (3,313,380), 171                        |                         |                     |                     |

A step is one render pass on this page: about 67,000 re-walks (a scratch
counter on Ember's render transaction, `renderRoots`, counted 1 per step).
The re-walks do not depend on the record count.

### Kept: a change set's records found without a map of every record (`53a3a52`, sheet)

The paste and undo profiles at 100,000 showed the sheet building a `Map`
or `Set` of every record's `String(id)` up to five times per operation:
`emit` (the rejections' records, built even with no rejection),
`flashCells`, `selectChanged`, `touchesRecords`, the redo's rejections and
core's `withoutConflicts` (plus an id list for placing inserts, now built
only when there are inserts). Each costs 20-45 ms in Chromium at 100,000
(the first time, as in a real paste). They now go through `findRecords`
(`core/record-lookup.ts`, internal: not exported from the core's index),
one pass that keeps only the ids the change set names and compares the raw
id before turning it into a string: measured in the page over 100,000
records, the first call 2.7 ms against 36-44 ms for the plain pass with
`String()` and `Set.has` on each id (a micro-benchmark, kept out of the
repository). Same results: an id is matched as its `String()` (LK6 checks
numbers, strings, `-0`, `1e21`, `'08'`, a BigInt and `NaN` against a map of
every record), the last of two records with one id wins, as with the maps.

Measured (the table above): paste at 100,000 187 -> 106 ms (-43 %), ×4
908 -> 417 ms (-54 %); undo 256 -> 73 ms (-71 %), ×4 1,090 -> 348 ms
(-68 %); at 50,000 paste -21 % / -36 % (×4), undo -51 % / -50 %; at 10,000
within noise. An earlier A/B of the first version (a full pass with
`String()` of every id) gave about half of that (paste at 100,000 243 ->
169 ms); the raw-id comparison is what took the rest. Tests LK1-LK6.
`53a3a52`'s commit message quotes an earlier A/B of the same two builds in
another part of the session (paste at 100,000 208.5 -> 126.0 ms, ×4 801.5
-> 461.6 ms; undo 187.1 -> 99.6 ms, ×4 834.0 -> 374.0 ms); the numbers
above are the later full matrix. They agree in direction and roughly in
size; the matrix is the one to cite.

### Tried and dropped, measured

- **First render, the row window's loop** (core): at first render the
  grid's height is not measured yet, so `computeRowWindow` walks every row
  calling `rowTop` (with tracked getters): 2.5 ms of profile at 10,000, 28
  ms at 100,000. Upper bound (the built `eui-data-grid` chunk patched to
  compute the uniform-height window by arithmetic): first render at
  100,000 306.7 -> 322.9 ms ×1, 1,587 -> 1,590 ms ×4, 10,000 351 -> 371 ms
  (interleaved, medians of 3): no gain, within noise, far from the 25 %
  the rule asks. Not changed. (The tag computes of first render grow by
  about 2 per record, 501,040 at 10,000 against 691,277 at 100,000; the
  patch did not remove them, so they come from elsewhere; not chased,
  since first render's time hardly grows.)
- **Frozen: only the frozen columns and the visible window** (core and
  sheet): the frozen grid renders every column of the rendered rows
  (`overscanColumnCount` = all), because a frozen cell must not unmount
  when its column leaves the column window. The cells are absolutely
  positioned and a frozen cell is `position: sticky; float: left` through
  `setCellProps`, so it keeps working if the grid always renders the
  leading columns plus the window. Upper bound (the built grid's
  `renderedColumns` patched to always include columns 0-1, the sheet's
  overscan off; 10,000 records, one frozen field, interleaved, medians of
  3):

  | Frozen, 10,000            | all columns        | frozen + window    | change        |
  | ------------------------- | ------------------ | ------------------ | ------------- |
  | re-walks, 10 scroll steps | 1,188,459          | 646,579            | -45.6 %       |
  | scroll frame p90 ×1 / ×4  | 83.4 / 400.0 ms    | 33.5 / 200.1 ms    | -60 % / -50 % |
  | scroll step ×1 / ×4       | 133.1 / 480.2 ms   | 75.1 / 267.2 ms    | -44 % / -44 % |
  | first render ×1 / ×4      | 504.3 / 2,760.9 ms | 304.6 / 1,479.8 ms | -40 % / -46 % |
  | drag move ×1 / ×4         | 63.2 / 198.2 ms    | 45.9 / 126.2 ms    | -27 % / -36 % |

  A screenshot after 6 steps down and 12 right was pixel-identical to the
  current frozen grid. The numbers clear the core rule by far. **Not
  landed, because existing tests pin the current behaviour**, and tests may
  not be edited: FZ8 ("frozen: every column of a rendered row is
  rendered", column 12 must exist), FZ9 (`on.cells > off.cells`), VR5
  (`frozenCells >= 13`, "every column rendered"), and the field-type tests
  in `eui-sheet-types2-test.gts` turn freezing on to have every column in
  the DOM. Landing it needs the user's decision on those tests, then: an
  opt-in option of core's virtualization (the leading columns always
  rendered, `onItemsRendered` unchanged), the sheet passing it instead of
  the full overscan, and the checks the upper bound did not cover (two
  frozen fields, no row numbers, groups, the summary footer, the add row,
  a range across the frozen edge while scrolled right, freezing while
  scrolled right, and a focused cell scrolled out of the window: typing,
  arrows and copy). d08's prose ("31 cells per row") would then change.
  The 50-field cap could then go too (a user-visible change; not proposed
  here).

### Measured, not changed

- **The docs page against one sheet.** On the docs page (28 demos) a d08
  scroll step re-walks 476,000 tags (the scrolling stage's number); on the
  harness page with one sheet, 67,000. Both are one render pass per step in
  the steady state (a scratch counter on Ember's render transaction; on the
  docs page the first two steps after a click took 2 passes, then 1). A
  render pass re-validates every tag of the page, so about 86 % of the
  docs page's re-walks are the other demos: an app's cost per step depends
  on what else it renders. "The grid renders twice per step" (the task's
  list) is not the steady state.
- **Step 4 (fewer tracked reads per cell view), the experiment.** The same
  page with a plain `EuiDataGrid` and a trivial cell (`mode=grid`): 5 render
  passes per scroll step, 1,492,837 re-walks per 10 steps, more than the
  sheet. The extra passes are core's, with the mouse over the grid: the
  cell under the pointer changes on scroll, its `isHovered` is set
  (`onMouseEnter`/`onMouseLeave`), and the hovered cell's actions (an
  `EuiPopover`, an `EuiToolTip`) write tracked state when they are torn
  down; the sheet has no cell actions, so it has 1 pass. Per pass: the
  trivial grid about 30,000 re-walks for 120 cells (about 250 per cell),
  the sheet 67,000 for 144 cells (about 470): roughly 45 % of the sheet's
  re-walks per step are its own cells' tracked state. For step 4 alone to
  reach the rule's -25 % of re-walks, the sheet's own share would have to
  drop by more than half. Not attempted in this batch. The plain grid's
  extra passes under a hovering mouse are a core matter for plain
  `EuiDataGrid` users, not measured further.
- **Paste and undo after `onChange`**: the render of the pasted range and
  the browser's style, layout and paint (a Chromium trace of the paste at
  100,000: about 20 ms paint, 17 ms style and layout, 15 ms GC); flat in the
  record count now.

### Not done or not verified

- Only Chromium, headless, in this sandbox; no real device, no other
  browser. Frame times come in 16.7 ms quanta; first render's runs range
  ±20 %.
- Scroll and drag at scale have counts and timings but no CPU profile of
  their own here (the scrolling stage profiled d08's scroll; this stage
  profiled first render, paste and undo).
- Still a pass over every record after each change: with `@validate`,
  `runValidate` keeps a map of every record as the validation's snapshot.
  Not measured (the harness page has no `@validate`).
- Scratch-only evidence, not in the repository: the render-pass counter
  (a patch of Ember's `renderRoots` in a copied build), the upper-bound
  patches (the row-window loop, the frozen columns), the in-page
  micro-benchmark of the id lookup and the paste trace. Each is described
  above well enough to redo; the harness itself (`build-large.sh`,
  `scale.js`, `run-scale.sh`, `median-scale.mjs`) is committed.
- The paste is of existing records (patches). A paste past the last record
  (inserts) was not measured at scale; `withoutConflicts` now builds the
  insert-placing id list only when there are inserts, so an undo of an
  insert-heavy paste still has one full pass.
- The `cellView` call count per cell (READINESS.md item 2's second point)
  was not re-measured.
- The record lookup's numbers are of the lookup alone (`53a3a52`); the
  barcode change after it does not touch these paths.

## Bundle size

Measured with `pnpm size` (`scripts/measure-bundle-size.mjs`: each entry a
production Vite + Embroider build, minified; KB of the entry's static
graph minus Ember alone, 91.6 KB / 29.6 KB gzip), with three new probes in
`site/size-probe/` (`06a163b`): `sheet` (an app importing only
`{ EuiSheet }` and rendering it), `sheet-core` (every export of
`@ember-eui/sheet/core`) and `sheet-import` (`EuiSheet` and
`EuiSheetImport`).

| Entry                           | before (`700ddd4`)         | after (`eff636a`) | lazy chunks |
| ------------------------------- | -------------------------- | ----------------- | ----------- |
| `sheet`                         | 1,497.2 KB / 394.1 KB gzip | 1,496.2 / 394.1   | 2 -> 3      |
| `sheet-import`                  | 1,558.4 / 409.2            | 1,557.5 / 409.2   | 2 -> 3      |
| `sheet-core` (in all, no Ember) | 82.1 / 23.6                | 82.6 / 23.8       | 0           |

(`sheet-core` reads -9.5 / -6.0 KB in the script's table: it imports no
Ember, so it is below the Ember baseline; the absolute numbers are above.
Its +0.5 KB after is `findRecords`, which `withoutConflicts` uses.)

- **The import screen** (`EuiSheetImport`, `-private/import/*`) is not in
  `sheet`: Vite (Rolldown) tree-shakes it out of `index.ts`, which only
  re-exports it, so nothing had to change and no import path changed. It
  costs 61.3 KB / 15.1 KB gzip when imported. Caveat: the package's
  `app-js` re-export (`components/eui-sheet-import.js`) puts it in the app
  tree of classic and compat (`@embroider/compat`) builds, which resolve
  components at runtime and keep every app-tree module; there it is in
  whatever the app bundles, used or not. A separate entry would not change
  that; dropping the `app-js` entry would change how classic apps resolve
  `<EuiSheetImport>` (not done: an import-path change for them).
- **The barcode scan panel** was in `sheet` (4.2 KB before minifying):
  `field-types.ts` -> the barcode editor -> `barcode-scan.gts`, statically.
  Now (`eff636a`) the panel is its own module, loaded with `import()` by
  `barcode-scan-loader.ts` (core's markdown-engine pattern, a test waiter
  for `settled()`) when a barcode editor that can scan opens;
  `barcodeDevice` and `canScan` stay in `barcode-scan.gts`. It is a third
  lazy chunk of `sheet`; the gain is about 1 KB minified, under 0.1 KB
  gzip. BS1 walks `<EuiSheet>`'s static imports over the sources and fails
  if they reach the import screen or the panel; BS2 checks that only the
  loader names the panel, by `import()`.
- **Where the rest is** (the `sheet` entry's largest modules, before
  minifying): `@ember-eui/core`'s theme (73 KB), chroma-js (83 KB, core's
  colour utilities), `EuiFlyout` (41 KB), the data grid (cell 35 KB, grid
  28 KB, body 28 KB), `EuiPopover` (25 KB), the router from Ember; the
  sheet's own 126 modules in the graph are about 525 KB before minifying,
  the largest its styles (44 KB) and messages (28 KB).

**Proposed budget** (checked with `pnpm size`): `sheet` at most 400 KB gzip
over Ember (now 394.1), `sheet-import` at most 15.5 KB gzip more than
`sheet` (now 15.1), `sheet-core` at most 25 KB gzip in all (now 23.8), and
neither `eui-sheet-import` nor `barcode-scan-panel` among `sheet`'s static
modules (BS1 checks the second part in the suite). Not wired into CI here.

## Loose ends

Done 2026-11-21, on `feat/sheet` after `0882057`, READINESS.md item 5.
One commit per item, each with tests that fail without it (said in each
commit message); no change to `packages/core/src`, no existing test
edited, the public API only added to. Test prefixes are new (`grep`ped
first): UH, RI, SA, IG4-IG7, LL, RH, IPL, IVM, VR6.

### 1. TR1, the touch handles' placement (`587c2e0`)

- **Cause, found:** a layout change after the render the handles are
  placed on. A scratch copy of TR1 that taps right after the render
  (without the two-frame wait TR1 got in V03 batch 5), 15 runs while
  another test run loaded the CPU: in 7 the cell moved 1.66 px left and
  narrowed (197.7 -> 196.0 px) after the handles were placed, and they
  stayed 1.66 px off for every later frame. The grid's body measures its
  scroll bar in the frame after a ResizeObserver callback
  (`observeResize` in core's `body.gts`) and the columns share the new
  width; the parts' arguments do not change, so nothing placed them
  again until the next scroll or selection change. A container or window
  resize does the same.
- **Fix:** while a part over the grid is shown, the sheet observes the
  grid's content box (the inner element sized to the columns and rows)
  and places every registered part again on a resize, through the same
  `scroll.placeAll` that `onScroll` uses since `ac281da`, with no
  tracked write. The observer starts with the first part shown and stops
  with the last.
- **Tests:** LL1 (the touch handles) and LL2 (the fill handle and the
  range outline) narrow the sheet's container after the parts are
  placed; both fail without the fix (the fill handle 146.5 px off in a
  first draft of LL2). With the fix the scratch copy's 15 runs (not under load: no suite was
  running then) are all on the corner, 4 of them with the late move;
  TR1-TR5, LL and RH passed 10 targeted runs in a row (TK1-TK4 were not
  in that loop: one targeted run and every full run since). `587c2e0`'s
  message says 8 and 5 of 15 and puts TK1-TK4 in the loop; the counts
  here are the ones in the runs' output.

### 2. The EmberSearchUi connector (`fa658b6`)

- `EuiSheetSearch` now passes on every `EuiSheet` argument but the ones
  the search provides or it replaces (`fields`, `records`,
  `getRecordId`, `onChange`, `sort`, `onSortChange`, `highlight`,
  `isLoading`, `rowNumberOffset`, `groups`). Besides the eight the plan
  named it was also missing `@canMove`, `@onButtonPress`, `<:empty>`
  and `<:recordFooter>`. Its signature is `Omit<>` of the sheet's
  arguments (was a `Pick<>` list), so a new argument is in it at once.
- **Blocks:** `EuiSheet` draws the expanded record's footer divider when
  `<:recordFooter>` is given, and a named block cannot be passed
  conditionally, so the template curries `EuiSheet` once with every
  argument (`(component this.Sheet ...)`) and invokes it twice, with and
  without the block. `<:empty>` is always passed and renders the sheet's
  own "No records" (the same markup and message) when the app gives none.
  Both yield the connector's block API (with `search`).
- **The guard:** `src/-private/sheet-arg-names.ts` lists every argument
  and block of `EuiSheetSignature` with `satisfies Record<keyof ...>`, so
  `lint:types` fails on a new one until it is listed; SA1 reads the inner
  sheet's arguments from Ember's debug render tree (`captureRenderTree`,
  on in development builds) and fails for any listed name not passed.
  SA1, SA3 and SA4 fail on the old connector; SA1 also fails with one
  line (`cellColor=@cellColor`) removed.
- Its suite (716/716) ran before a lint fix that turned the toolbar's and
  footer's content into template-only components; the 17 connector tests
  re-ran green then, and every later full run includes it.

### 3. The fill handle after a row-height change (`7d0030e`)

- **A placement bug, not an early screenshot.** In the test runner, a
  selected cell and `@rowHeight` from short to extra tall: the fill
  handle stayed 135 px above the corner (two rows of 67.5 px more) in
  every frame after the change; tall -81 px, medium -27 px. The parts are
  placed after the render that changes `@rowHeight`, but the grid gives
  the rows their new height after that render.
- **Fix:** item 1's observer (the content box's height follows the
  rows'); the handle is on the corner within two frames. RH1 (the fill
  handle and the outline at each height) and RH2 (the touch handles),
  test-only commit; both fail without `587c2e0`.
- **Production build** (the final one, below; `vite preview`, Chromium
  headless, 1300 × 900, scale 2, real clicks): d27 ("Cell colours"), a
  click on row 1's Task cell, then each row-height button: the fill
  handle's centre on the cell's corner (0.0, 0.0 px) at 100, 300 and
  600 ms after the click, at Extra tall (cell 156 px), Tall (108),
  Medium (60) and Short (36). No page or console errors. The build before
  the fix was not re-run here (batch C's screenshot is the before).

### 4. A rejection on an inserted row (`7207995`)

- **Rule:** a rejection on a record the change set inserts is stored as
  `UNSEEN` and takes the value its record arrives with in `@records`,
  after the render that brings it (`cells.bindInserted`, called from
  `follow.recordsRendered`; a plain write, the cell already showed it).
  Until then it is shown. So an owner's default (`qty: null`, and also
  `qty: 0`) keeps it, and a later change by the owner still hides it.
  Chosen over "compare with the value sent, or empty": it also covers a
  default that is not empty and an owner that normalises the value, and
  binds at one place (not in a cell's render, where a cell out of view
  would bind to a later value). Redo puts back a rejection whose record
  was not seen yet with the record's current value.
- **Tests:** RI1 (`appendRows`), RI2 (a paste on the add row), RI3 (a
  `0` default), RI4 (the owner's change hides it), RI5 (undo and redo),
  RI6 (`remapIds`), RI7 (`localRecords`' default, as before), RI8
  (`restoreRejections`). RI1-RI6 fail without the change.

### 5. `url`'s host rule (`2821741`)

- **Rule (documented in docs/sheet.md):** the host as the text writes it
  (after `//`, without `user@` and `:port`) must be `localhost`, an IPv6
  address in brackets, a dotted quad of 0-255, or two or more labels
  whose last one has a letter (`example.com`, `ñandú.mx`). So
  `19/11/2026`, `12`, `1.2.3`, `0x7f.1` and empty labels are not URLs.
  The URL parser's `hostname` is not used for it: it turns `19` into
  0.0.0.19.
- **The import guess's workaround (`URL_HOST`) is gone:** the type's rule
  is enough for dates and numbers. One change: a column of dotted quads
  now guesses `url`. Tests UH1-UH4.
- Pre-existing, not changed: a text with no scheme and a port
  (`localhost:4200`, `example.com:8080`) reads as the scheme
  `localhost:` and is not a URL.

### 6. The import guess (`97e5226`)

- A sample with a time of day after a date tries `dateTime` before
  `date`; without `dateTime` among the candidates (the default list) it
  stays `date`. When 95 % of the sample is written as phone numbers (a
  `+` first, parentheses, or digit groups split by spaces or dashes, 7
  digits or more, not `1 234 567`), `phone` comes before `number`; plain
  digits, decimals, negatives and `+5` stay numbers. Tests IG4-IG5.

### 7. `@newRecordValues` for a paste past the last record: blocked

Not done: PNV5 pins the old behaviour and existing tests may not be
edited. `tests/integration/components/eui-sheet-paste-new-values-test.gts`,
PNV5 ("a paste on a record row does not call @newRecordValues, also for
its lines past the end"), with `@newRecordValues` giving `{ code: 'NEW' }`
and `Bea\nCaro` pasted on record row 1:

```ts
assert.deepEqual(
  set!.inserts.map((insert) => insert.values),
  [{ name: 'Caro' }],
  'the line past the end: the pasted values only (unchanged)'
);
assert.deepEqual(owner.seen, [], 'no call');
```

**The user's decision:** allow PNV5's expectation to change (to
`[{ name: 'Caro', code: 'NEW' }]` and one call with `['r1', undefined]`),
then it is the one call the plan names.

### 8. The import screen's counts and its value map (`9d10999`, `7daf0f9`)

- **Counts:** every count message has a form for one, as new keys beside
  the old ones, with the same parameters and tokens `euiSheet.<key>`:
  `importLinesOne` ("Import 1 line"), `importLineCountOne`,
  `importLinesReadyOne`, `importLinesWithErrorsOne`, `importValuesOne`,
  `importCantReadOne`, and `importReadOne` and `importPreviewOfOne`
  ("The only line") for a one-line file. The old keys keep their meaning
  (any count but one). An app that overrides (`@messages`) or translates
  (`eui-i18n`) only the plural keeps its text for one too.
- **Value map, decided: list the texts it is applied to** (after the
  column's trim and transform), not move it before the transform. The
  design (`v04/10-import-screen.md`) has a transform return text "so the
  target type still reads it", and the value map is one of the column's
  options for reading it; `SheetImportColumn.valueMap` already documents
  "a text (after trim and the transform)" and `runImport` applies it so,
  so the public helpers keep their order and only the screen changes. A
  text whose transform throws is left out. A change of the transform or
  of "Trim spaces" keeps the choices made and prefills only the texts it
  brings. The transform runs over the lines until the table's 50
  distinct texts: over the whole file when the column has fewer (the
  usual case for a select or checkbox; `9d10999`'s message says it does
  not, which is wrong). Not timed on a large file.
- **A bug in `9d10999`, fixed in `7daf0f9`:** with a saved mapping whose
  checkbox or select column has a transform and no value map, proposing
  the plan read the plan for the transform's `row` (re-entering a
  `@cached` getter): "Maximum call stack size exceeded". The `row` now
  comes from the header line, as `runImport` builds it. IVM3 fails
  without it.
- Tests IPL1-IPL3, IVM1-IVM3.

### 9. The import screen's open time: not reached, not committed

The deferral the plan recommends was built and measured, and is **not
committed**: it does not get the open under 300 ms. The patch and its
test are kept, for the user's decision, in
`internal/spikes/sheet/readiness-import-first-run.patch` (it applies to
this commit's tree: `git apply`).

- **What it does:** a new source's first dry run waits for the frame that
  shows the preview (a `requestAnimationFrame`, then a timer, so after
  the paint; a test waiter meanwhile); the totals read "Checking the
  lines…" (one new message, `importChecking`), each column's status is
  empty and its badge shows the type without the share, and "Import N
  lines" counts every line. Import itself never used the dry run (it runs
  its own), so it cannot act on a missing one. Two tests (IDR1-IDR2, in
  the patch) hold `requestAnimationFrame` to see the state between.
- **Measured** as batch E stage 2 did (the docs demo, a 10,000-line,
  20-column file, from the input's `change` event to the first preview
  row in the DOM; production build, Chromium headless, 1300 × 900), one
  first open and three warm per run, the two builds served side by side
  and run alternately, twice:

|               | first open | warm runs     | warm median |
| ------------- | ---------- | ------------- | ----------- |
| before, run 1 | 732 ms     | 442, 455, 417 | 442 ms      |
| before, run 2 | 749 ms     | 372, 555, 439 | 439 ms      |
| after, run 1  | 568 ms     | 393, 337, 302 | 337 ms      |
| after, run 2  | 566 ms     | 362, 365, 353 | 362 ms      |

(An earlier before-only run: 751 ms, then 463, 445, 405.) The deferral
takes about 90 ms off the warm open and 180 ms off the first, and the
counts come later: 553-646 ms after the `change` event, against about
445 ms before (they came with the preview). The rest of the open is
the first render of the columns table's EUI controls (stage 2's
profile). The probe's "painted" time is not reported: its timer queues
behind the dry run's, so it includes the run.

- **For the user:** take the deferral as it is (about 340-360 ms warm), or
  also render fewer controls per column (the plan's "options behind a
  button"), or relax the target.

### 10. Other open items of the v0.4 batches

Done (no user decision needed):

- **A guessed currency's code** (batch E stage 2: "always `USD`"; and
  "the `USD` default has no test"): the code every text that names a
  currency names (a code the browser lists, such as `MXN`, or a sign of
  one currency, such as `€`), else the new field's `USD` (`$` alone names
  none: dollars and pesos share it; a mix names none). IG6-IG7; both fail
  without the change. `616822c`
- **`@onVisibleRangeChange` on a height change** (batch D: "not
  verified: the resize path"): VR6, a test only; it passes on the code as
  it was, so the docs' claim holds. `616822c`

Left, each needs the user or a device: the v0.4 decisions listed in
V04-RESULTS.md (`@fieldTypes` vs `@types`, the result's extra keys,
disabled vs moved for a taken field, the preview's format,
`importAliases` matching a value-map option, the expanded record's cell
colour, the selected bar on a range's bottom row, batch A's deviations
2-4); the focus of a single cell after a scroll that moves its row node
(core's list update, pre-existing); the core reporting the visible range
only when its overscanned window changes; scroll chaining at the end of a
half-loaded list; fitting measuring loaded records only; the 3 px resize
edge; no focus trap in full screen; field creation not undoable;
`appendRows` chunks needing the owner to apply each change set first;
and everything listed as not verified on other browsers, touch devices
and screen readers.

### Checks

- **Before every commit** (on its tree, with the noted exceptions): the
  sheet's `pnpm lint:types`; the tests' `ember-tsc` at the 19 baseline
  errors (`diff` against `3c-checks/baseline-tests-tsc.log` empty);
  eslint and Prettier on the changed code and test files;
  `node scripts/generate-api-docs.mjs --check` exits 0 (no `EuiSheet`
  argument was added, so no API docs changed). `docs/sheet.md` is not
  Prettier-clean at `0882057` either and was not reformatted.
- **Full sheet suite** (development build, testem, headless Chrome):
  704/704 (`2821741`), 712/712 (`7207995`), 716/716 (`fa658b6`, before
  its template-only refactor), 718/718 (`97e5226`), 722/722 (`587c2e0`
  and `7d0030e`, one run with both), 727/727 (`9d10999`), 731/731
  (`7daf0f9` and `616822c`, one run with both). No flaky failure in any
  run. Each new test was also run against its change reversed
  (`git apply -R` of a saved diff) and failed, but the regression
  guards named in the commits.
- **Final:** the sheet's `lint:js` and `lint:css` pass; root
  `pnpm eui:check` passes (357 node tests); `site`'s `pnpm lint` passes
  (css, format, js, types) and its `pnpm test` passes (node 8, testem 14).
  Every package rebuilt (`pnpm build` in core, flatpickr, pikaday,
  validated-form, changeset-form, sheet), then `site`'s `pnpm build`:
  `site/dist` is that production build. Preview servers stopped.
- **Bundle size** (`pnpm size` on the final build, gzip over Ember):
  `sheet` 394.8 KB (was 394.1; the proposed budget 400), `sheet-import`
  16.2 KB more than `sheet` (was 15.1; **over the proposed 15.5** by
  0.7 KB: the value map's texts and the counts' forms, items 8 and 10),
  `sheet-core` 24.4 KB in all (was 23.8; budget 25). The budget is not
  wired into CI; raising it to 16.5 or trimming is the user's call.

### Decisions the user may overrule

- Item 4: a rejection on an inserted row binds to the value its record
  arrives with, not the plan's suggested "the value sent, else empty".
- Item 5: a column of dotted quads now guesses `url`; bracketed IPv6
  hosts are URLs.
- Item 8: the value map lists the texts after the transform (the public
  helpers' order kept), rather than moving the map before the transform.
- Item 10: a guessed currency takes the code its texts name, where
  docs/sheet.md said "always `USD`" (beyond the plan's named items).
- Item 9's patch is committed as a file under `internal/spikes`
  (as `cell-api.patch` was), not applied.

### Notes for bisecting

- `9d10999` alone overflows the stack for a saved mapping with a
  transform on a select or checkbox column; `7daf0f9` fixes it.
- Two pairs of commits shared one suite run each (`587c2e0` with
  `7d0030e`, `7daf0f9` with `616822c`).

### Not verified

- Only Chromium (headless, the test runner and one production run); no
  other browser, no touch device, no screen reader.
- Item 8's value map with a transform on a large file was not timed (the
  transform runs over every line when the column has fewer than 50
  distinct texts).
- Item 9's numbers are single-machine runs (two alternated rounds of one
  first and three warm opens each); the profile behind "the rest is the
  columns table's controls" is stage 2's, not redone.
- Scroll performance was not re-measured after `587c2e0` (the observed
  box should not resize on a scroll; not checked with the harness).
- Item 9's patch ran only the import tests, on `9d10999`; against this
  tree it was only checked to apply (`git apply --check`), not run.
- `@canMove` and `@onButtonPress` through the connector are tested as
  passed on, not for behaviour (whether `search.apply` handles a change
  set's `moves` is not known).
- LL1, LL2, RH1 and RH2 wait up to 1 s for the parts: timing-sensitive,
  like FZ9 and TR1.
- Item 1's observer is checked for the late column sizing and a
  container resize; a toolbar that changes height while a part is shown
  (the grid moves without resizing) is not covered by it.

## Performance: the frozen grid and more

Done 2026-11-21, on `feat/sheet` after `46c5448`, READINESS.md item 2's
continuation ("keep working in performance"): (1) the frozen grid
renders only the frozen columns and the columns in view (the user
approved changing FZ8, FZ9, VR5 and the freezing field-type tests);
(2) the parts' `ResizeObserver` of the loose-ends stage re-measured; a
re-check of the core `setCellProps` change on a single-sheet page; (3)
further gains, kept only when measured.

Harness: `perf-checks/` (`1fa26ea` adds `validate`, `pasteAt=end`, the
`edit` scenario, the frozen check by class, `shots-d08.js edge` and
`compare.js --common`). Production builds, `vite preview`, Playwright's
Chromium headless (1400 × 900, scale 2), real input; builds served side
by side and run interleaved (run 1 of each, then run 2, …), medians of
3; re-walk counts from the instrumented template chunk, deterministic.
This session's absolute times run 10-25 % above the earlier stages'
(plain d08 p90 117 against 100 ms, the same counts): compare within a
table, not across sections.

Commits: `1fa26ea` (harness), `05dd3b0`, `a5490ee`, `8ad506a` (item 3),
and this section with the two patch files. **Item 1 is not committed**
(below).

### 1. The frozen grid renders the frozen columns and the columns in view: built and measured, **not committed** (blocked)

**Status:** implemented and measured; not committed, because five existing
tests outside the user's approval (FZ1, FZ4, FZ12, IM7, ED1) fail with it,
and the coordinator's rule (b) says to stop and report then. The change is
kept, for the user's decision, as
`internal/spikes/sheet/frozen-window.patch` (core, sheet, docs and
tests, the approved test edits included; it applies to this section's
commit with `git apply`), and the proposed edits of the five as
`internal/spikes/sheet/frozen-window-proposed-tests.patch`.

**The change.**

- Core (`packages/core/src/components/eui-data-grid/body.gts`,
  `utils/data-grid/types.ts`): an opt-in
  `virtualizationOptions.leadingColumnCount` (an Ember addition, default
  0): the first N columns (leading control columns counted) are always
  rendered besides the window; `renderedColumns` lists them first, then
  the window's, ascending, each once (clamped to the column count; 0,
  negative or missing: exactly as before). `columnWindow`, `syncWindow`
  and `onItemsRendered` are unchanged (it still reports the window only).
  Core docs (container constraints) mention it. Three new core tests:
  on (leading cells first, kept and not re-created while scrolling, the
  columns between not rendered, `onItemsRendered` the window only, the
  last row too), 0 / negative / more than the columns, and the arrows
  from a leading column into the window and back.
- Sheet: `grid-options.ts` passes `leadingColumnCount: colOffset +
frozenCount` instead of the full `overscanColumnCount` while frozen.
  `outline.ts`: a range that starts in the frozen columns, scrolled so its
  other columns are left of the column window (not rendered now), drew its
  right side past the clip (to the grid's right edge); its right side is
  now its frozen cells' (the first rendered non-frozen column is checked,
  so a window entirely inside the frozen columns still extends right). The
  50-field cap is kept; its comment and warning no longer give the old
  reason. d08's text ("the row numbers and Code, then the dozen or so
  columns in view of 31") and docs/sheet.md's Frozen field / Performance
  section (the FZ9 numbers below; the grouping section's "freezing
  multiplies the work" corrected) describe the new rendering.
- A bug found by the new core test and fixed in the patch: with
  `leadingColumnCount` beyond the window's end (more leading columns than
  fit), the first version rendered the leading columns only up to the
  window's start. The measurements above and below were taken before
  the fix; it does not touch them (the sheet's leading count is always
  inside the window or before it).
- Sticky placement: frozen cells are `position: sticky; float: left` in
  the absolutely positioned row; the leading cells come first in the DOM
  (as before), so the floats stack the same when middle columns are
  skipped (FV1, FV2 check the lefts side by side, with one and two frozen
  fields, with and without row numbers, and freezing or going from one to
  two while scrolled right).

**Measured, the real implementation** (`build-large.sh` page, `46c5448`
"base" against the change "new", interleaved, medians of 3; counts from
the instrumented chunk, one run each, deterministic):

| Case                                   | metric                           | base                        | new                         | change                       |
| -------------------------------------- | -------------------------------- | --------------------------- | --------------------------- | ---------------------------- |
| frozen 10,000 ×1                       | re-walks / 10 steps              | 1,188,459                   | 646,609                     | **-45.6 %**                  |
|                                        | drag re-walks                    | 589,484                     | 323,094                     | -45.2 %                      |
|                                        | first render                     | 645.7 ms                    | 297.9 ms                    | -54 %                        |
|                                        | scroll step                      | 136.5 ms                    | 78.9 ms                     | -42 %                        |
|                                        | frame p90                        | 100.0 ms                    | 50.0 ms                     | **-50 %**                    |
|                                        | frames > 50 ms                   | 38                          | 5                           |                              |
|                                        | drag move                        | 64.3 ms                     | 45.8 ms                     | -29 %                        |
| frozen 100,000 ×1                      | re-walks                         | 1,188,459                   | 646,609                     | -45.6 %                      |
|                                        | first render                     | 602.0 ms                    | 404.3 ms                    | -33 %                        |
|                                        | scroll step                      | 135.9 ms                    | 90.1 ms                     | -34 %                        |
|                                        | frame p90                        | 100.0 ms                    | 50.0 ms                     | -50 %                        |
|                                        | drag move                        | 62.2 ms                     | 44.8 ms                     | -28 %                        |
| frozen 10,000 ×4                       | first render                     | 3,067 ms                    | 2,031 ms                    | -34 %                        |
|                                        | scroll step                      | 580.1 ms                    | 363.8 ms                    | -37 %                        |
|                                        | frame p90                        | 500.0 ms                    | 249.9 ms                    | -50 %                        |
|                                        | drag move                        | 185.3 ms                    | 135.1 ms                    | -27 %                        |
| frozen 100,000 ×4                      | first render                     | 2,837 ms                    | 1,785 ms                    | -37 %                        |
|                                        | scroll step                      | 495.2 ms                    | 285.0 ms                    | -42 %                        |
|                                        | frame p90                        | 466.7 ms                    | 233.4 ms                    | -50 %                        |
|                                        | drag move                        | 209.1 ms                    | 149.8 ms                    | -28 %                        |
| plain 10,000 ×1                        | re-walks                         | 673,633                     | 673,663                     | +0.004 %                     |
|                                        | first render / step / p90 / drag | 365.9 / 81.1 / 49.9 / 45.5  | 337.3 / 87.9 / 33.4 / 45.8  | noise                        |
| plain 100,000 ×1                       | first render / step / p90 / drag | 359.9 / 88.2 / 50 / 45.7    | 328.9 / 82.1 / 50 / 46.1    | noise                        |
| plain 100,000 ×4                       | first render / step / p90 / drag | 1,813 / 349.8 / 250 / 143.3 | 1,788 / 327.4 / 250 / 169.1 | noise (drag runs 130-192 ms) |
| plain `EuiDataGrid` (grid mode) 10,000 | re-walks                         | 1,492,837                   | 1,492,837                   | 0                            |

The frozen ×4 "frames > 50 ms" stay about 40 (every frame is slow at ×4,
as the at-scale stage found). The real implementation matches the
patched best case (646,579 re-walks then, 646,609 now). On the docs page
(d08 among 28 demos) a frozen step re-walks 528,995 -> 473,850 (-10.4 %:
the other demos dominate there); plain 476,547 -> 476,604.

**The core rule:** -45.6 % re-walks per step (against 25 %), -50 % frame
p90 (against 20 %), and every frozen scenario's time -27 % to -54 %. The
plain grid and the unfrozen sheet do not change (counts equal to 0.004 %).

**Screenshots and DOM** (`shots-d08.js` on the docs build, `46c5448`
against the change; `compare.js --common` compares the cells both builds
render):

- frozen, a range on Name-Department, 3 wheel steps down, 3 right, 3 up:
  "selected", "scrolled down" and "scrolled right" pixel-identical, and
  every cell both render identical (classes, styles, `aria-*`); the new
  build renders 132-195 cells where the old rendered 372-403.
  "Scrolled back" differs (230,209 pixels): the old build, scrolling back
  up to the focused Name cell while scrolled right, re-mounted it (it was
  rendered, under the frozen column), and its re-focus made the sheet
  scroll the grid back to the left edge (`clearFrozenOverlap`); the new
  build does not render the scrolled-out Name column, so nothing is
  re-focused and the grid stays scrolled right, as the unfrozen grid does
  (its "scrolled back" is pixel-identical between the builds).
- `edge` (new): the range from the frozen Code to Department, steps right
  to the far right: identical but "scrolled back", 1,932 pixels: the old
  build drew the outline's left side over the row numbers (its scrolled-
  out Name and Department cells, rendered at negative x, widened the
  box); the new one draws it at Code's left edge, which is the range's
  visible part.
- unfrozen: all four pixel-identical, all cells identical.

**Tests** (new file `eui-sheet-frozen-window-test.gts`, FV1-FV14, in the
patch): FV1 one or two frozen fields, row numbers on and off, scrolled far
right (the frozen cells' lefts kept and side by side, painted over the
scrolled ones, every column whose header is in view rendered at its
header's left, a scrolled-out column not rendered, and back); FV2 freezing
while scrolled right and 1 -> 2 -> 0; FV3 groups (the header row's label in
view and painted, its first cell the row numbers; a record row); FV4 the
summary footer and the add row; FV5 a range across the frozen edge,
scrolled far right (outline right side at the frozen edge, its other
sides, the frozen cells drawn selected, back again, copy of every cell);
FV6 the focused cell scrolled out sideways: where focus is, a copy,
typing and the return of focus are the same frozen and unfrozen; FV7
focus comes back to the cell and typing edits it (frozen 0 and 1); FV8 an
open editor and a sideways scroll (saved and closed, frozen 0 and 1); FV9
ArrowRight from the frozen field into the first scrolled column while
scrolled far right (focus, right of the frozen edge), ArrowLeft back, End;
FV10 resizing the frozen field and moving a field while scrolled right;
FV11 full screen while scrolled right; FV12 the expanded record while
scrolled far right; FV13 the fill handle on a scrolled cell, the frozen
cell, hidden out of view and placed again; FV14 the touch handles. In the
first full run with the change FV7, FV10 and FV12 failed on the tests'
own mechanics (a DOM-based selection check on an unrendered cell, a
resize driven by pointer events the resizer does not listen to,
`@expandedRecordId` without its handler); fixed, all of FV1-FV14 pass
with the change (the last full run below). On the unchanged code
(`46c5448`) FV2-FV4 and FV7-FV14 pass too (the same behaviour before and
after: freezing while scrolled, groups, footer and add row, focus and
editor, the arrows across the edge, resize and move, full screen, the
expanded record, fill and touch handles); FV1 fails only on "a column
scrolled out to the left is not rendered", FV5 on the outline's left
side (the old bug above) and FV6 on the frozen grid's old focus
behaviour (below), as expected.

**Behaviour that changes** (all the frozen grid's, from not rendering
offscreen columns; each the unfrozen grid's behaviour already):

- A focused cell scrolled out sideways unmounts: focus leaves it (to the
  body), typing does nothing and Ctrl+C copies nothing until it is back,
  then the grid focuses it again (FV6 compares with the unfrozen grid and
  finds them equal; before, the frozen grid kept it mounted and focused).
- Scrolling vertically back to a focused cell while scrolled right no
  longer jumps the grid back to it (the old frozen grid re-mounted it,
  and the re-focus scrolled; the unfrozen grid never did).
- The outline of a range from a frozen cell no longer extends over the row
  numbers when its other columns are scrolled out (a fix).

**Existing tests.**

Approved and changed (in the patch), each kept to what it checks:

- FZ8: `.exists('frozen: every column of a rendered row is rendered')` ->
  `.doesNotExist('frozen: the last column is not rendered either (column
window)')`, then after `scrollGrid(outer().scrollWidth)`
  `.exists('frozen, scrolled to the end: the last column is rendered')`.
- FZ9: `assert.ok(on.cells > off.cells, 'frozen renders every column')` ->
  `assert.strictEqual(on.cells, off.cells, 'at the left edge the frozen
columns are in the column window anyway: the same cells')`.
- VR5: title "…and every column of a rendered row is still rendered" ->
  "…and a rendered row has the same cells as without it";
  `assert.true(frozenCells >= 13, 'every column rendered')` ->
  `assert.true(frozenCells < 14, 'the frozen columns and the ones in
view, not every column')`.
- A4 (types2): `renderSheet(allFields(), [fullRow()], 1)` ->
  `renderSheet(allFields(), [fullRow()], 1, 3000)` (a 3000 px container:
  every field in view, so rendered; `renderSheet` takes the width, 1100 by
  default, as before).
- LT1 (types2): the same, `…, 1)` -> `…, 1, 3000)`.

- VR5, a second edit after the first full run with the edits:
  `assert.strictEqual(cellsOfRow(), frozenCells, 'after a scroll right')`
  -> `assert.true(scrolled < 14, 'after a scroll right: still not every
column')`, and the last check `cellsOfRow() < frozenCells` ->
  `cellsOfRow() < scrolled` (scrolled right, a row renders the two
  leading cells besides the window, so its count is not the one at the
  left edge).

Runs with the change: FZ8, FZ9, A4 and LT1 pass with their edits in the
full run; VR5 with its second edit run alone (1/1). FZ9 reported
(`?report`): "frozen on 103.6 ms per scroll step, 72 cells rendered; off
105.7 ms, 72 cells"; FZ13: frozen off 78.4 / 98.9 ms (ungrouped /
grouped), frozen on 101.3 / 108.6 ms, 72 cells each (a loaded run).

Not approved, failing (stopped here, reported to the coordinator), each at
its first reach for a cell outside the column window:

- FZ1 (`eui-sheet-frozen-test.gts`): at scrollLeft 700 reads `cell(3, 1)`
  (the second field, scrolled out). Proposed: `cell(3, 1)` -> `cell(3, 6)`
  in "the second field is not [sticky]".
- FZ4: `focusCell(3, 11)` at scrollLeft 0. Proposed: scroll to the end
  first (`await scrollGrid(outer().scrollWidth); await frame();`).
- FZ12: `focus(at(3, 11))` at scrollLeft 700. Proposed: the same.
- IM7 (`eui-sheet-ime-test.gts`): `focusCell(0, 12)`, a far cell focused
  before the grid scrolled to it; that premise no longer exists frozen.
  Proposed: `focusCell(0, 0)` + `press('End')` (the focus's late scroll
  event is kept, as ED1b does unfrozen).
- ED1 (`eui-sheet-polish-test.gts`): the same premise ("frozen: the far
  cell is in the DOM before it is scrolled into view"). Proposed: the
  same, and `cell(0, 12)` -> `cell(0, 13)` in the "editor over its cell"
  check (End lands on the last field).

Scratch copies of those five with exactly these edits (untracked; the
edits are in `internal/spikes/sheet/frozen-window-proposed-tests.patch`) passed
on the new code in a full run, so they are test assumptions, not
regressions. No other existing test failed. The last full run with the
change (and without the proposed edits): 750 tests, 744 pass, 6 fail: the
five above and VR5 before its second edit. Applying the proposed edits
in the working tree for a run was refused by this session's permission
check (they are not approved), so the full suite with them has not run;
the scratch copies are the evidence.

Core checks with the change: core `lint:types` passes; core's full suite
(before the leading-columns fix): 2150 tests, 2147 pass, 2 todo, 1 fail
(the new test that found the bug); after the fix the virtualization
module passes (9/9), the full core suite was not run again; eslint on the
changed core files passes.

### 2. The parts' ResizeObserver (`587c2e0`): no measurable cost

The loose-ends stage observes the grid's content box while a part over
the grid (fill handle, outline, touch handles, …) is shown. Measured on
the production docs build of `46c5448` (d08, the harness of "Performance:
scrolling"):

- **Callbacks:** a wrapper of `ResizeObserver` installed before the page
  (`INIT_SCRIPT`) counted its callbacks during 12 wheel steps down and 6
  right: **0** in every case (plain, selected, frozen, frozen + selected).
  With a cell selected one more element is observed (183 against 182 on
  the page), as designed; scrolling never resizes it.
- **Counts** (medians of 3, all three runs identical): plain 476,547
  re-walks per step, selected 476,597, frozen 528,995; writes 11 in each.
  The scrolling stage's numbers were 476,539 / 476,589 / 528,987: +8 in
  each case, the plain case included, where no part is shown and the
  observer is off. A copy of the same build with `watchLayout` stubbed
  (`return` first, so nothing is ever observed) gives exactly the same
  476,547 / 476,597 / 528,995: the +8 come from the docs page's other
  changes since then, not from the observer.
- **Profile**, the build against the stubbed copy, interleaved, medians of
  3 (`profile-scroll.js`; frame median 16.7 ms everywhere):

  | Case     | build p90 / busy     | stubbed p90 / busy   |
  | -------- | -------------------- | -------------------- |
  | plain    | 116.7 ms / 9,661 ms  | 100.1 ms / 9,182 ms  |
  | selected | 116.7 ms / 9,836 ms  | 116.7 ms / 9,484 ms  |
  | frozen   | 183.3 ms / 11,166 ms | 199.9 ms / 11,767 ms |

  The differences go both ways by about 5 % and are as large in the plain
  case, where the observer is not running in either build: noise. (All
  these runs are slower than the scrolling stage's, plain p90 100 ms and
  busy 7,912 ms then: another session of this sandbox, as that section
  warns; the counts did not move.)

Nothing to fix.

### (a) The core `setCellProps` change on a single-sheet page

The scrolling stage justified `74e4771` + `5adfb2c` on the docs page,
where about 86 % of a step's re-walks are the other demos. Re-checked on
the harness page (`build-large.sh`, one sheet, 10,000 records), the core
built with `cell.gts` from `74e4771~1` ("old cell") against `46c5448`
("new cell"), both with steps 1 and 2 in place (the sheet's dist the same,
built from `46c5448`). Counts from the instrumented chunk (deterministic,
one run each); times interleaved, medians of 3:

| 10,000 records                            | old cell  | new cell  | change      |
| ----------------------------------------- | --------- | --------- | ----------- |
| plain: re-walks, 10 steps                 | 1,001,978 | 673,633   | **-32.8 %** |
| plain: writes, 10 steps                   | 143       | 110       |             |
| plain: drag re-walks                      | 588,019   | 336,384   | -42.8 %     |
| plain: frame p90                          | 50.0 ms   | 49.9 ms   | 0 %         |
| plain: scroll step                        | 91.6 ms   | 81.1 ms   | -11 %       |
| plain: drag move                          | 46.2 ms   | 45.5 ms   | -2 %        |
| frozen: re-walks, 10 steps                | 1,759,751 | 1,188,459 | **-32.5 %** |
| frozen: writes, 10 steps                  | 176       | 110       |             |
| frozen: drag re-walks                     | 1,018,975 | 589,484   | -42.1 %     |
| frozen: frame p90                         | 116.7 ms  | 100.0 ms  | -14 %       |
| frozen: scroll step                       | 154.3 ms  | 136.5 ms  | -12 %       |
| frozen: drag move                         | 62.8 ms   | 64.3 ms   | +2 %        |
| plain `EuiDataGrid` (grid mode): re-walks | 1,476,737 | 1,492,837 | +1.1 %      |

So on a page with one sheet it still clears the rule's re-walk criterion
(-32.8 % and -32.5 %, against 25 %) by the same margin as on the docs
page, and still not the p90 one (0 % and -14 %, against 20 %). The plain
`EuiDataGrid` with a trivial cell (no `setCellProps`) moves by +1.1 %
re-walks (its 5 passes per step with the mouse over it). Not reverted:
the user decides.

### 3. Further gains

Measured on the harness page (`build-large.sh`, now with `&validate=1`,
`pasteAt=end` and the `edit` scenario, `1fa26ea`), interleaved against
`46c5448` + the harness ("base"), medians of 3. Kept, one commit each:

**`@validate` (`05dd3b0`).** Every run put every record in a `Map` by
`String(id)` (the snapshot that hides an error of a changed record). The
run now copies the array and looks up only the records with errors when
its result comes (`findRecords`). `runValidate`'s inclusive time (CPU
profile), 100,000 records, an error on 3 % of them:

| after              | base    | kept    | change |
| ------------------ | ------- | ------- | ------ |
| a 1,000-line paste | 43.6 ms | 10.4 ms | -76 %  |
| its undo           | 40.0 ms | 9.1 ms  | -77 %  |
| a cell edit        | 33.9 ms | 6.6 ms  | -81 %  |

(The owner's function itself: 2-11 ms. The run is debounced 50 ms, so
this is a task after the change's frame, not in it; the paste's own time
moved 202 -> 110 ms in this matrix but 128-281 ms between base runs:
noise.) Still a pass over the records per run (the copy and the lookup):
a run "only over the changed records" would need the owner's function to
be incremental too, which `changed` already allows; not done.

**A paste past the last record (`a5490ee`, `8ad506a`).** A paste of 1,000
lines on the last record (5 patches, 999 inserts) at 100,000 records:
the profile showed `isOwnChange` (follow.ts) at 63-70 ms (a set of every
previous id and 100,000 string comparisons), and its undo spent 20-25 ms
in `applyChangeSet`'s `String()` of every record (localRecords' apply).
Now the follower compares the raw ids first (`8ad506a`) and
`applyChangeSet` matches deletes by raw id (`a5490ee`):

| 100,000 records     | base            | kept          | change                                        |
| ------------------- | --------------- | ------------- | --------------------------------------------- |
| paste ×1            | 206.0 ms        | 105.2 ms      | -49 %                                         |
| paste ×4            | 693.8 ms        | 489.8 ms      | -29 %                                         |
| undo ×1             | 173.4 ms        | 119.0 ms      | -31 %                                         |
| undo ×4             | 576.7 ms        | 514.4 ms      | -11 % (runs 500-1,050 / 384-587: noise-heavy) |
| undo apply ×1 / ×4  | 23.5 / 105.4 ms | 5.7 / 28.9 ms | -76 % / -73 %                                 |
| to onChange (paste) | 14.4 ms         | 10.1 ms       |                                               |

At 10,000 records nothing moves beyond noise (paste 109.6 / 116.0 ms,
undo 88.8 / 89.7 ms). Tried and replaced: the same walk over the strings
without a set (self time 63-70 -> 42-53 ms, the paste's total not moved:
187.8 -> 201.6 ms).

**Measured, not changed:**

- A single cell edit at 100,000 (Hours of row 2, "12", Enter): the
  keystroke to `onChange` 1 ms; to the frame with the value 64-87 ms ×1,
  about 330 ms ×4 (10,000: 55 ms). The first key to the editor on screen
  20-30 ms. What remains per edit at 100,000 is the render, plus about
  5 ms building each render's id strings (`follow.recordsRendered`); not
  chased.
- A paste of patches at 100,000 (the at-scale stage's scenario): 122.1 ->
  116.1 ms, undo 85.8 -> 69.0 ms (runs overlap; not changed on purpose).
- Sort, filter and group toggles at 100,000: the d08 demo and the harness
  page have none (d19 has groups over a small list); not measured.
- Step 4 (fewer tracked reads per `cellView`): not attempted, and no
  experiment was run for it. The reason is the numbers already at hand: on
  the harness page a plain `EuiDataGrid` with a trivial cell re-walks
  about 250 tags per cell per pass, the sheet about 470; for step 4 alone
  to reach -25 % of the sheet's re-walks, the sheet's own ~220 per cell
  would have to lose more than half.
- Plain `EuiDataGrid` with the mouse over it (5 render passes per scroll
  step, 1,492,837 re-walks / 10 steps and 171 writes, from the hovered
  cell's state and its actions' popover and tooltip): a core matter, not
  quick to change safely; not investigated further.

### Checks

- Each item 3 commit: sheet `lint:types`; the tests' `ember-tsc` at the 19
  baseline errors (`diff` empty); eslint and Prettier on the changed
  files; `generate-api-docs --check` exits 0; the tests matching
  "validate" (12/12, `05dd3b0`) and "record lookup" (8/8, `a5490ee`) on
  their trees; the full sheet suite once, on `8ad506a`'s tree (the three
  together): 735/735, no flaky failure.
- Final (on `8ad506a`): sheet `lint:js` and `lint:css` pass; root
  `pnpm eui:check` passes (357 node tests); `site`'s `pnpm lint` passes
  and its `pnpm test` passes (node 8, testem 14). Every package rebuilt
  from `HEAD` (core, sheet; the others unchanged since the last stage),
  then `site`'s `pnpm build`: `site/dist` is that production build, no
  instrumented chunk. Preview servers stopped.
- Bundle size (`pnpm size`, gzip over Ember): `sheet` 395.1 KB (was
  394.8; budget 400), `sheet-import` 16.2 KB more than `sheet` (as before;
  over the proposed 15.5, unchanged by this stage), `sheet-core` 24.5 KB
  in all (was 24.4: `namedBy`; budget 25).

### Not verified

- Only Chromium, headless, in this sandbox. Timings move 10-30 % between
  sessions and the per-run values overlap in the rows marked noise; frame
  times come in 16.7 ms quanta.
- Item 1: the full sheet suite with the five proposed test edits has not
  run (see above); the full core suite was not re-run after the
  leading-columns fix (its module was); FV1-FV14 ran on the change only
  in its last form; the patch was checked to apply (`git apply --check`)
  to this section's commit, not built from it.
- Item 1's docs text (d08, sheet.md) is in the patch, not published.
- The item 3 numbers at ×4 for undo are noise-heavy (single runs of
  500-1,050 ms); `validateTask` comes from CPU profiles (the profiler's
  overhead is in both builds alike).
- The cell edit at 100,000 and the 100,000-record first render were not
  changed and not profiled in depth.
- Item 1 was measured plain at 10,000 ×1 and 100,000 ×1 and ×4, not plain
  at 10,000 ×4 (frozen: all four).
- After the results commit the full sheet suite ran again on its tree:
  735/735.

### The frozen grid: landed (main session, 2026-11-21)

The user approved the five further test edits (FZ1, FZ4, FZ12, IM7, ED1)
after the four first approved (FZ8, FZ9, VR5, the freezing field-type
tests A4 and LT1). Both patches were applied as they were: core in
`42e3782` (`virtualizationOptions.leadingColumnCount`), the sheet and the
test edits in `e5a90b1` (every old -> new assertion listed there).
Checks on the applied tree: core suite 2150 tests, 2148 pass, 2 todo,
0 fail (the full suite had not run since the `renderedColumns` fix);
core `lint:types`; sheet `lint:types`; the tests' ember-tsc at the
19-error baseline; eslint on the changed files; `generate-api-docs
--check`; full sheet suite 754/754 with the proposed edits (the first
run of the suite with them).
