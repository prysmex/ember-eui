# Accessibility checks (`@ember-eui/sheet`)

The harness behind READINESS.md item 3 and READINESS-RESULTS.md's
"Accessibility": axe-core over every sheet docs page and over the sheet
in states (an editor open, a menu, the field editor, ...), a contrast
rater for the sheet's own text, and a check of the grid's ARIA indices.
Playwright's Chromium on the production docs build.

## Build and serve

Turbo fails here ("Exec format error"), so build by hand:

```sh
(cd packages/core && pnpm build)
(cd packages/sheet && pnpm build)
(cd site && pnpm build)            # production build into site/dist
(cd site && npx vite preview --port 4211 --strictPort --host 127.0.0.1) &
```

axe-core is a dev dependency of `site` (`axe-core` in its
`node_modules`, resolved from there); Playwright from Node's global paths
(`require('playwright')`). `PORT` (default 4211) is the preview's port.

## Scripts

- `axe-pages.js [outDir] [modes]`: every page of the sheet's docs nav (the
  `index.md` files under `packages/sheet/docs/sheet/`, `nav: false` pages
  left out: 52 on 2026-11-21), in each mode (`light`, `dark`, `light-hc`,
  `dark-hc`: the site's `?theme=` and `?highContrast=true`). Waits for
  each demo's sheet, runs axe (default rules: WCAG 2 A/AA, 2.1, best
  practices) and the contrast rater. Writes `pages-<mode>.json` and prints
  per page and in total the nodes per rule and impact, by scope:
  - `sheet`: inside a sheet, its import screen or a part it portals (its
    layers, the expanded record, the shortcut list);
  - `demo`: inside a demo's example but not a sheet (the example's own
    controls and text);
  - `chrome`: the site (header, nav, prose, code snippets).
  `PAGES=<path>,<path>` limits the run.
- `axe-states.js [outDir] [modes]`: the sheet in states, each on its page:
  `text-editor`, `select-editor`, `multi-select-editor`, `date-editor`,
  `date-time-editor`, `row-menu`, `field-menu`, `field-editor`,
  `expanded-record`, `import-screen` (a 30-line file loaded),
  `shortcut-list`, `cell-error` (an invalid cell focused), `tints` (a range
  over invalid cells and two checked rows), `search-match`, `full-screen`.
  An EUI portal open in a state counts as the sheet's. A state that did not
  reach what it shows is printed `NOT REACHED` and left out of the totals.
  `STATES=<name>,<name>` limits the run.
- `aria-grid.js <page> <grid label> [scrollLeft] [scrollTop]`: the grid's
  `aria-rowcount`/`aria-colcount`, every rendered row's cells (one
  `aria-rowindex` per row, no `aria-colindex` twice, each cell's equal to
  its column header's), at the top and after scrolling; `FREEZE=1` first
  turns on the page's "Freeze..." switch (the frozen grid's column window).
- `lib.js`: the page list, opening a page in a mode, axe, the scopes, and
  `runContrast`.

## The contrast rater

axe rates almost none of the sheet's text: the grid's cells have
pseudo-elements (rings and borders), so its `color-contrast` result for
them is "incomplete" (the scripts record that count as
`axeIncompleteContrast`). `runContrast` rates every visible text inside
the sheet roots itself: the computed text colour with the opacity of the
element and its ancestors, against the ancestors' background colours
composited up to the first opaque one (pseudo-elements and background
images ignored; disabled controls exempt). 4.5:1, 3:1 for large text and
for glyphs that are graphics (a rating's stars). It only sees the state a
script puts the page in (a hover only where the mouse is).

## Notes

- Never commit the output or screenshots; keep them in the session's
  scratchpad.
- The scripts read the docs tree, so a page added or removed changes the
  list; compare runs on the same build.
