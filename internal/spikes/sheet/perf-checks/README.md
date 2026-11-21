# Scroll performance checks (`@ember-eui/sheet`)

The harness behind READINESS.md's "Performance" item and
READINESS-RESULTS.md's "Performance: scrolling": real wheel scrolling of
the d08 demo ("Employees", 10,000 records × 31 fields) in Playwright's
Chromium, on the production docs build.

The page: `PAGE` (default `/docs/sheet/docs/sheet/large-data`, the
Large data page, where d08 is alone) and the sheet: `LABEL` (default
`Employees`), both in `lib.js`. Until the docs split (READINESS-RESULTS.md,
"Docs split and getting started") every demo was on one page,
`/docs/sheet/docs/sheet`: pass `PAGE=/docs/sheet/docs/sheet` to measure a
build from before it. `shots.js` screenshots the sheets with chips of
one page, so since the split it covers fewer sheets per run (d15
"Products" is on `/docs/sheet/docs/sheet/field-types`).

## Build and serve

Turbo fails here ("Exec format error"), so build each package by hand
(`packages/core` must already be built):

```sh
export NODE_OPTIONS=--max-old-space-size=6144
(cd packages/sheet && pnpm build)
(cd site && pnpm build)            # production build into site/dist
(cd site && npx vite preview --port 4195 --strictPort --host 127.0.0.1) &
```

To compare two builds, copy `site/dist` aside and serve the copy on a
second port: `npx vite preview --port 4196 --strictPort --host 127.0.0.1
--outDir <copy>` (run from `site/`).

Playwright is resolved from Node's global paths (`require('playwright')`).

## Scripts

- `profile-scroll.js [frozen] [selected]`: a CPU profile and the frame
  times of 40 wheel steps of 120 px down, 20 right and 20 up (30 ms
  apart). `frozen` turns on the demo's "Freeze the first field" switch
  (and fails unless the first field's cells then have the frozen class: a
  count of a row's cells, the earlier check, depends on whether the frozen
  grid renders every column); `selected` clicks
  the Name cell of row 3 first, so the fill handle is shown while
  scrolling. Prints the top files and functions by self time and a
  `RESULT {...}` line: frame `median`, `p90`, `over50` (frames over
  50 ms), `busy` (profiled ms without idle) and `tagShare` (Glimmer's
  `[TAG_COMPUTE]` self time / busy; the minified function is found by its
  source, `[X](){let{lastChecked:`, so it is "V" in the profile).
- `count-tags.js [frozen] [selected]`: Glimmer's tag computes, re-walks
  (the `lastChecked !== $REVISION` branch) and tracked writes (`dirtyTag`)
  per 120 px wheel step (12 steps, 250 ms apart), and who writes (stack
  frames outside the template chunk). `RESULT`: the medians of the steps.
  Needs the instrumented chunk (below). The counts are deterministic: the
  three runs agree exactly.
- `instrument.mjs apply|restore [dist]`: adds the three counters to
  `dist/assets/template-*.js` (keeps the original as `*.orig`) and puts it
  back. Never commit an instrumented chunk (`site/dist` is not tracked).
- `run.sh <label> [profile|count|all]`: 3 runs of each case
  (`CASES="plain frozen selected frozen-selected"`, default
  `plain frozen`), instrumenting around the counts; writes the logs and
  `medians.txt` (median and the three values of each number) to
  `$OUT/<label>`. `PORT`, `DIST` (the served dist the counters
  instrument), `RUNS`, and `RUN_IDS` (to interleave two builds: call it
  with `RUN_IDS=1` for build A, then B, then `RUN_IDS=2`, …).
- `shots.js <dir> [dark]`: a screenshot of every sheet on the page that
  shows chips, and the chips' DOM (classes, title, attributes, inner
  spans, `innerText`, width) in `chips.json`; `dark` switches the docs'
  theme first.
- `compare.js <dir-a> <dir-b> [--common]`: `chips.json` exactly and each
  PNG pixel by pixel; `--common` compares a `shots-d08.js` directory's cells
  matched by row and column, only those both render (a build that renders
  fewer columns has fewer).
- `shots-d08.js <dir> [unfrozen] [edge]`: d08 frozen, a range selected,
  3 wheel steps down, 3 right, 3 up, a screenshot and every cell's
  attributes after each; `edge` starts the range on the frozen Code cell
  and goes to the far right (the range's other columns scrolled out).
- `median.mjs <dir>`: the medians of a `run.sh` directory.

## Reading the numbers

- Re-walks per step are the steady measure: every tracked write after a
  render bumps `$REVISION`, and the next render pass re-walks every tag
  it validates. Fewer writes only help when they remove a render pass.
- Frame times come in 16.7 ms quanta (p90 of 100, 116.6, 133.3 ms), and
  the profile's wall and busy times move by 10-30 % between sessions of
  this sandbox. Compare builds interleaved (A/B) in one session, and
  read p90 with `busy` and `over50`, not alone.

## At scale (10,000 to 100,000 records)

- `build-large.sh <out-dir>`: a production docs build with a harness-only
  page, `large-page/` (the d08 demo sized from the URL:
  `/docs/sheet/docs/perf-large?rows=100000&weeks=24&frozen=1&mode=grid`),
  into `<out-dir>` (never `site/dist`). The page is copied into
  `packages/sheet/docs` for the build and removed after it, with the
  generated page templates; it is never in the published docs. The records
  are generated when the page loads; the sheet mounts on "Mount", so its
  first render is timed alone. `mode=grid` is a plain `EuiDataGrid` with a
  trivial cell and the same columns.
- `scale.js rows=N [throttle=4] [frozen] [profile] [mode=grid] [validate]
[pasteAt=end] [only=mount+scroll+drag+paste+undo+edit] [lines=1000]`: on one page, in this
  order: first render (the click on "Mount" to the first frame with rows),
  10 wheel steps of 120 px each waited out, then 40 quick steps (frame
  times), a range drag (Name of row 2 to Week 3 of row 9, 14 moves; each
  move's time and the mouseup's), a paste of `lines` lines × 6 fields
  (Name, Department, Hours, Start, Active, Week 1) on Name of row 2 through
  the real clipboard (`navigator.clipboard.writeText`, then Ctrl+V; read
  back to check), its undo (Ctrl+Z). A time runs from the input event's
  `timeStamp` (the harness waits for the event to reach the page) to the
  end of the first frame after the result is on screen (the task after the
  next `requestAnimationFrame`). `throttle=4`: CDP's
  `Emulation.setCPUThrottlingRate`, set after the page loads. With the
  instrumented chunk the counters of each scenario are added; `profile`
  writes a CPU profile per scenario to `$OUT` and prints its top functions.
  `validate`: the page's `@validate` (`&validate=1`, an error on Hours over
  58); the harness waits for its debounced run after the paste, the undo and
  the edit, and reports the owner's function's time (`validateFn`) and, with
  `profile`, `runValidate`'s inclusive time (`validateTask`). `pasteAt=end`:
  the paste on Name of the last record (its lines past the end are
  inserts). `edit` (not in the default list): a click on Hours of row 2,
  "12" typed and Enter (`open`: the first key to the editor on screen;
  `total`/`toOnChange`: the Enter to the new value on screen / to
  `onChange`).
- `run-scale.sh <out-dir>` with `BUILDS="base:4197 new:4198"`,
  `CASES="rows=100000 rows=100000,throttle=4"`, `RUNS=3`: every case on
  every build, run by run (interleaved); `median-scale.mjs <out-dir>
[metrics]` prints the medians and the three values.

`results-at-scale.jsonl`: the RESULT lines of READINESS-RESULTS.md's
"Performance: at scale" matrix (base `46a7fbe`, head `53a3a52`).
