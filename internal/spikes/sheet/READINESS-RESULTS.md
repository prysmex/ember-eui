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
  scroll step 250-310 ms, frame p90 200-217 ms, 40 of the ~60 frames over
  50 ms; a drag move 120-140 ms; first render 1.4-1.7 s. That is the
  per-render cost (below), not the data size.
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
