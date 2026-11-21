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
