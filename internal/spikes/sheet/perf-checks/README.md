# Scroll performance checks (`@ember-eui/sheet`)

The harness behind READINESS.md's "Performance" item and
READINESS-RESULTS.md's "Performance: scrolling": real wheel scrolling of
the d08 demo ("Employees", 10,000 records × 31 fields) in Playwright's
Chromium, on the production docs build.

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
  (and fails unless a row then renders all 31 cells); `selected` clicks
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
- `compare.js <dir-a> <dir-b>`: `chips.json` exactly and each PNG pixel by
  pixel.
- `median.mjs <dir>`: the medians of a `run.sh` directory.

## Reading the numbers

- Re-walks per step are the steady measure: every tracked write after a
  render bumps `$REVISION`, and the next render pass re-walks every tag
  it validates. Fewer writes only help when they remove a render pass.
- Frame times come in 16.7 ms quanta (p90 of 100, 116.6, 133.3 ms), and
  the profile's wall and busy times move by 10-30 % between sessions of
  this sandbox. Compare builds interleaved (A/B) in one session, and
  read p90 with `busy` and `over50`, not alone.
