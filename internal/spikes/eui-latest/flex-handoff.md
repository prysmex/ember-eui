# Flex family migration handoff (EuiFlexGroup, EuiFlexItem, EuiFlexGrid)

Status: **Migrated**. The full core suite passes in Chromium 130 (620/620, including 11 new flex-family tests), along with upstream parity, types, lint and API docs.

## Files

- `packages/core/src/components/eui-flex-group.gts`, `eui-flex-item.gts`, `eui-flex-grid.gts`: now Glimmer classes composing the pre-extracted `euiFlexGroupStyles`, `euiFlexItemStyles` (static object) and `euiFlexGridStyles` through `getEuiThemeContext` / `useEuiBorealisStyles` / `euiClass`, in upstream's `cssStyles` order.
- `packages/core/tests/integration/components/eui-flex-family-test.gts`: new, 11 computed-style/geometry tests.
- `eui-flex-test.gts`, `eui-facet-test.gts`: legacy modifier-class assertions (`euiFlexGroup--gutterLarge`, `--directionColumn`, `--wrap`, `euiFlexItem--flexGrow3`, `euiFlexGrid--thirds`…) replaced by computed `display`/`gap`/`flex-direction`/`flex-wrap`/`flex-grow`/`grid-template-columns` checks. The facet test still asserts its own `euiFacetGroup--*` classes unchanged. No other existing test needed changes.
- `packages/core/docs/layout/flex/index.md`: only the generated API section changed.
- Not touched: generator, `styles.generated.ts`, `upstream-sources.json`, `utils/css-mappings/eui-flex-*.ts` (now unused by the components but still registered in the shared mappings index), `eui-health.gts` (hard-codes legacy `euiFlexGroup--*` classes; it is not a flex component), providers/shared utils, showcase, `.vscode/settings.json`.

## API and default changes (latest-only)

- **EuiFlexGroup default `@gutterSize` is now `'m'` (16px)**, upstream's default. It was `'l'`. Callers that relied on the old default get a tighter gutter; none of the core tests depended on it.
- Gutters are CSS `gap` (row and column) from theme tokens: `xs`=size.xs 4px, `s`=size.s 8px, `m`=size.base 16px, `l`=size.l 24px, **`xl`=size.xxl 40px** (legacy xl was 32px). No negative margins or item padding remain. Grid gutters: `s` 8, `m` 16, `l` 24 (default), `xl`=size.xl 32px.
- **Responsive** follows upstream: below `euiMaxBreakpoint(m)` (`max-width: 767px` in Borealis; theme-overridable) the group wraps and direct `.euiFlexItem` children become 100% wide. Column directions never receive the responsive styles (upstream). Grids collapse to one column with `grid-auto-flow: row`.
- Group root has upstream `flex-grow: 1`; items are `display:flex; flex-direction:column` with `flex-basis: 0%` and `flex-grow: N` for `true`/1–10, `flex-grow:0; flex-basis:auto` for `false`/`0`. **`0` is newly accepted** (upstream). Invalid values fall back to `true` (upstream; no console warning in Ember). The legacy string key `'false'` that the old `keyof growMapping` type allowed is no longer typed; no caller used it.
- **EuiFlexGrid default `@columns` is now `1`** (upstream). It was `0`. `@columns={{0}}` is kept as a documented **Ember-only extension** (flex-wrap, items at their own width, gutter gap, column stack below the breakpoint); upstream removed this mode. No caller in core/docs uses `0`.
- **EuiFlexGrid `@direction="column"`** sets `grid-auto-flow: column` plus upstream's inline `grid-template-rows: repeat(ceil(children / columns), 1fr)`. Ember counts element children with a MutationObserver modifier so `{{#each}}` additions/removals update rows; the property is removed when direction/columns change. Note: if a caller's own `style` attribute is re-rendered, Glimmer rewrites the attribute and the rows are restored only on the next child mutation/arg change (edge case; no caller binds `style` on a column grid).
- **EuiFlexGrid adds `@alignItems`** (`stretch` default, `start`, `end`, `center`, `baseline`), as upstream.
- Exported arg types: `EuiFlexGroupGutterSize`, `EuiFlexGroupAlignItems`, `EuiFlexGroupJustifyContent`, `EuiFlexGroupDirection`, `EuiFlexItemGrow`, `EuiFlexGridDirection`, `EuiFlexGridGutterSize`, `EuiFlexGridAlignItems`. Key sets are unchanged, so `EuiDescribedFormGroup`'s derived arg types still check.
- **Stable:** `Element` types, `@tagName` support (group `div|span`; item and grid any tag via `(element)`), `...attributes`, default blocks, and the root classes `euiFlexGroup`, `euiFlexItem`, `euiFlexGrid` (upstream's responsive selector `& > .euiFlexItem` needs the item class). All `--modifier` classes are removed.
- **Scoped reset** instead of React's global reset: roots get `box-sizing: border-box`; when rendered as `ul/ol/dl/p/figure/blockquote` they also reset margin, padding and list-style (quick-select popovers render `<EuiFlexGrid @tagName="ul">`).

## Checks run (2026-10-12, worktree `eui-batch2/flex`)

Environment: Node 22.22.1, pnpm unavailable (binaries run directly), Chromium 130 via `google-chrome` shim on PATH with `CI=true`.

- Core suite (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **620 tests, 620 pass, 0 fail** (609 base + 11 new).
- `node --test scripts/eui-upstream-parity.test.mjs`: **29/29 pass**.
- `node scripts/generate-eui-styles.mjs --check`: reports "Stale generated artifact" **in this worktree only**, because `node_modules` is a symlink to the main checkout and esbuild's provenance comments become `../../../../Users/.../node_modules/...` paths. Regenerating changes only those `//` comment lines (verified: zero non-comment diff); the file was restored and is unmodified on this branch. Re-run in the main checkout after merge.
- `ember-tsc --noEmit`: pass. ESLint on the three components and the three touched tests: pass.
- `node scripts/generate-api-docs.mjs --check`: pass.
- Not run (root): core rollup build, site build/acceptance, showcase visual checks.

## Test coverage (eui-flex-family-test.gts)

Every group gutter measured as real horizontal and column gaps against tokens; default m; no negative margins. All alignItems/justifyContent values by geometry. All directions in LTR and RTL (row starts on the right in RTL, rowReverse on the left); wrap row-gap vs nowrap shrink. Grow 1–10 by measured widths and ratios, false/0 content width, default = true, invalid fallback. Responsive collapse at exactly `m - 1` vs `m` (markup + all CSSOM rules cloned into iframes of those widths, with `matchMedia` checks), `responsive=false`, column groups unaffected, grids collapse. A `breakpoint.m` JS-object override collapses only groups inside that provider in the real 1440px window. Grid columns 1–4 (distinct columns, equal widths), every grid gutter both axes, row vs column fill order and inline rows, default 1 column, alignItems, columns=0 wrap, RTL grid. Column-grid rows follow `{{#each}}` additions and arg changes; group/item/grid args update without element replacement; teardown. Nested group/grid gutters independent. Light/dark nearest provider, sibling isolation, nested size override winning, size overrides on m/l/grid xl and their removal. Tags/attributes/aria/events/blocks, span-inside-paragraph, ul/li list reset.

Finding: in theme-common 10.1 overriding `size.base` does **not** re-derive `size.l`/`xl` etc. (they stay at their computed defaults); override each size explicitly.

## Unresolved

1. Default gutter `l`→`m`, xl 32→40px and grid columns `0`→`1` change spacing of unmigrated callers (DescribedFormGroup, FormRow layouts, PageHeader, Card, Stat, super date picker, etc.). On legacy docs pages that still load Amsterdam CSS, vendor `.euiFlexGroup`/`.euiFlexItem` rules (negative margins, item padding by `--gutter*` classes) no longer match because the modifier classes are gone; base `.euiFlexGroup`/`.euiFlexItem` vendor rules still apply alongside gap. Audit visually when the legacy CSS is retired or the callers migrate.
2. `eui-health.gts` hard-codes legacy flex classes and does not use the components; it should switch to EuiFlexGroup/EuiFlexItem when Health is migrated.
3. `utils/css-mappings/eui-flex-*.ts` are now dead but still imported by the shared mappings index; remove them in a coordinated cleanup.
4. The `generate-eui-styles --check` worktree path artifact above (root to verify in the main checkout).

## Next step

Root: merge, re-run `generate-eui-styles --check` in the main checkout, core build and site checks, and a visual pass of flex-heavy docs pages (layout/flex demos, page templates, form demos). Add flex samples to the `/docs/eui-latest` showcase later.
