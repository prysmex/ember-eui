# New components: text truncation (EuiTextTruncate, EuiTextBlockTruncate)

Branch `eui-wave/new-truncate` (from `feat/eui-latest` at `b1004ad0`).
Target EUI 123.1.0 / Borealis 8.1.0. Status: **Migrated**.

Salvaged from the interrupted new-timeline worktree (truncate pieces only),
reviewed against upstream `components/text_truncate/*` and fixed where noted.

## Files

- `packages/core/src/components/eui-text-truncate.gts` (new)
- `packages/core/src/components/eui-text-block-truncate.gts` (new)
- `packages/core/src/utils/eui/text-truncate.ts` (hand port of the
  module-local `euiTextBlockTruncate` style object; upstream keeps it in the
  React component file, so the generator cannot extract it)
- `scripts/generate-eui-styles.mjs`: `// text truncate` block extracting
  `euiTextTruncateStyles` and `TruncationUtils` (with its `CanvasTextUtils`
  base); regenerated `styles.generated.ts` and `upstream-sources.json`.
- `scripts/eui-upstream-parity.test.mjs`: factories entry, a
  `TruncationUtils` test (generated vs upstream class over 3 texts × 7 widths
  × 3 ellipses × 11 type/offset/position cases, with a deterministic fake
  canvas font) and a block-truncate test against upstream's React component
  (css, inline `WebkitLineClamp`, cloneElement classes/styles).
- `components.ts`, `template-registry.ts` (added lines only),
  `packages/core/package.json` app-js exports (rollup).
- Tests: `packages/core/tests/integration/components/eui-text-truncate-test.gts`.
- Docs: `packages/core/docs/display/text-truncation/` (index + 5 demos:
  types with a width slider, offset/position/ellipsis, render block with
  `EuiHighlight`, fixed `@width`/`calculationDelayMs`, block truncate) and
  `scripts/api-docs-pages.json` entry.

## API

`EuiTextTruncate` (`<div class="euiTextTruncate">`, `...attributes` on it):
`@text` (required), `@truncation` end|start|startEnd|middle (default end),
`@truncationOffset` (start/end only; ignored unless 0 < offset < length),
`@truncationPosition` (startEnd only; ≤0 → end, ≥length → start),
`@ellipsis` (default `…`), `@width` (skips the observer), `@onResize(width)`,
`@calculationDelayMs`, `@toolTipProps` (`EuiTextTruncateToolTipProps`:
position/delay/title/content/offset/className/css), `@css`. Default block
receives the text to render (upstream's render prop). Exported types:
`EuiTextTruncationTypes`, `TRUNCATION_TYPES`.

`EuiTextBlockTruncate`: `@lines` (required), `@cloneElement`, `@css`.

## Ember differences

- Upstream wraps the root in a block `EuiToolTip` only while truncating
  (which remounts the root). Ember attaches the tooltip with `@attachTo` to
  the same root, so the element is kept when truncation starts/stops.
  `disableScreenReaderOutput` as upstream.
- Upstream renders an empty truncated string until the observer reports a
  width; Ember shows the full text until the first measurement, which avoids
  a height change (and a second resize/`onResize`) right after mount. With an
  explicit `@width={{0}}` it renders nothing, as upstream.
- Resize observing is a local modifier reproducing `EuiResizeObserver`
  (border-box size, reports only changes from 0×0); it registers a test waiter
  until the first observation.
- `@cloneElement`: Ember cannot clone a block's element, so the block yields a
  modifier (`as |clamp|` → `<p {{clamp}}>`) that adds the classes and inline
  `-webkit-line-clamp`. A caller's inline `style` on the wrapper `<div>` is
  kept, but `-webkit-line-clamp` from `@lines` wins over a caller-set value
  (upstream lets `style` override it).

## Review fixes vs the salvaged code

- `@cloneElement` swap bug: when `@lines`/`@css` changed, Glimmer installed
  the new yielded modifier before tearing down the old one, whose teardown
  then removed the clamp (element unclamped). Clamps now track ownership per
  element; a stale teardown leaves the newer clamp alone and the previous
  classes are swapped, not accumulated. Covered by the block test.
- Empty class tokens are filtered before `classList.add` (would throw).
- Named `EuiTextTruncateToolTipProps` type so the API docs show it.

## Tests (2026-10-12, Chromium 130)

`eui-text-truncate-test.gts`, 7 tests: every truncation type/offset/position/
ellipsis compared with upstream `TruncationUtils` for the rendered font and
checked to fit, reactive without replacing the root; structure/styles/a11y
(aria-hidden copy, transparent full-text overlay, user-select/pointer-events),
render block, `@css`, tooltip on hover and none without truncation; resize
observer measuring, recalculating, `@onResize`, `@width` disconnect/reconnect
and teardown; `calculationDelayMs` and RTL; block truncate wrapper + clone,
reactive `@lines`/`@css` without replacement, teardown; nearest-provider
light/dark colors, forced contrast (`forced-color-adjust: none` on the
overlay), sibling isolation.

## Checks

- `ember-tsc --noEmit`: pass. ESLint on changed files: pass.
- Generator: 354 factories, React-free; parity 312/312.
- API docs: 100 pages, 1 added; `--check` clean.
- Rollup: pass (2 exports added to package.json).
- Focused suite 7/7; full core suite 1140/1140.
- Demos d03–d05 and the d01 slider were rendered in a throwaway core test
  (deleted); no site build was run.

## For the coordinator

- The new docs page adds one navigation entry: the site's catalog/navigation
  count test (bumped to 104 for the timeline) will need +1.
- Merge `scripts/generate-eui-styles.mjs`/parity factories as a union (the
  `// text truncate` block sits after `// new-skeleton`) and regenerate.
