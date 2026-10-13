# Misc display family migration handoff (TreeView, TextDiff, Expression, Tour)

Branch `eui-wave/misc-display`. Target EUI 123.1.0 / Borealis 8.1.0. Status: **ported, rows left `In progress`**. Every family test passes (28/28 filtered). The full core suite is 850/851. The one failure, `Borealis header family: EuiCollapsibleNav: overlay vs docked…` ("overlay uses levels.navigation", actual z-index 1000 vs 6000), also fails on the untouched base `9e3d1e09`: I checked it with a base build of this worktree, 3/3 failing filtered runs. Mark the rows Migrated once the base is green.

## Files

- Components (Glimmer classes; every style getter is `@cached`; factories only go through `useEuiBorealisStyles`; static resets are module constants):
  - `eui-tree-view.gts`, `eui-text-diff.gts` (was template-only), `eui-expression.gts` (was template-only), `eui-tour-step.gts`, `eui-tour-step-indicator.gts`. `eui-tour.gts` has no upstream styles and is unchanged.
  - `src/-private/eui-tour-parts.gts` (new): upstream `_tour_header` / `_tour_footer`. Each composes the EuiPopoverTitle/Footer and EuiTitle factories with the tour styles in one class per element, because those components have no `@css` (see Unresolved 1).
- `scripts/generate-eui-styles.mjs` (`// misc-display` block), 210 factories: `euiTreeViewStyles`, `euiTreeViewItemStyles`, `euiTextDiffStyles`, `euiExpressionStyles`, `euiExpressionDescriptionStyles`, `euiExpressionValueStyles` (static), `euiExpressionIconStyles`, `euiTourStyles`, `euiTourBeaconStyles`, `euiTourHeaderStyles`, `euiTourFooterStyles`, `_tourFooterBgColor`. All extracted cleanly; no hand port was needed. `styles.generated.ts` and `upstream-sources.json` are regenerated, and the worktree `../../…/Users/…` source-path comments are normalized back to `node_modules/…`.
- `scripts/eui-upstream-parity.test.mjs`: 11 factories in the 12-configuration matrix, plus a deepEqual test for the static `euiExpressionValueStyles`. 182/182.
- Tests: new `tests/integration/components/eui-misc-display-test.gts` (12 tests). Existing tests updated as described below.
- API docs: no family page changed. `generate-api-docs.mjs` also rewrites `display/icons`, `display/list-group`, `layout/panel` and `navigation/button`. Those pages were already stale on the base (from the `@css` commit), so I reverted them to stay in scope; the coordinator should regenerate them.

## API / default changes (latest-only)

**EuiTreeView**
- The legacy wrapper `div.euiText.euiText--{small,medium}.euiTreeView__wrapper` is removed. The component now renders the SR-only instructions plus the `ul` (upstream). `...attributes` still go on the `ul`.
- Upstream styles: list reset, nested lists indented by `size.l` (logical), font `m` / compressed `s`. Rows are 32px / 24px (max-height + line-height; `none` when expanded). Buttons are full width with `s` / `xxs` logical padding, gap `s` / `xs`, control radius, `treeViewItemBackgroundHover` on hover/focus and an inset focus ring. Icon wrappers are half the row wide. Labels truncate (`eui-textTruncate` class kept, mixin applied).
- `ul` gets `role="list"` (upstream VoiceOver fix).
- **`aria-expanded` and `aria-controls` are now set only on nodes with children** (upstream). Before, every node had `aria-expanded="false"` and pointed at an empty div. The children region is rendered only for parents.
- `useEmptyIcon` renders an empty `span.euiTreeView__iconWrapper` (upstream; was `euiTreeView__iconPlaceholder`). With `@showExpansionArrows`, leaves get `span.euiTreeView__arrowPlaceholder` to align (new, upstream). An `iconWhenExpanded` without an `icon` now shows while expanded (upstream).
- Removed classes: `euiTreeView--compressed`, `euiTreeView--withArrows`, `euiTreeView__nodeInner--withArrows`. Kept: `euiTreeView`, `euiTreeView__node`, `euiTreeView__node--expanded`, `euiTreeView__nodeInner`, `euiTreeView__node--active`, `euiTreeView__iconWrapper`, `euiTreeView__expansionArrow`, `euiTreeView__nodeLabel`.
- Expansion arrows stay `arrowDown` / `arrowRight`, because the Ember icon set has no `chevronSingle*` (see the icon handoff).
- Keyboard handling (arrow up/down/right/left, left from children back to the parent) and callbacks are unchanged.

**EuiTextDiff**: upstream `del { textDanger }` / `ins { textSuccess }`. The diff is now a `@cached` getter. API unchanged.

**EuiExpression**
- Upstream styles:
  - Code font, size `s`, logical start alignment, break-word, `s/2` block padding, `& + .euiExpression` spacing.
  - Clickable: editable dashed bottom border; columns add a `lightestShade` background and underline on focus/hover.
  - Per color: focus background `transparentize(text color, 0.1)`. Active: solid border in `colors.<color>`.
  - Columns: flex, width 100%, `xs` padding/margin, description at logical end with `s` margin, value grows. In non-high-contrast mode the border is transparent with an `xs` radius.
  - Truncate: max-width plus ellipsis on description and value.
- **Invalid:** only the description turns danger. The root keeps `@color`'s focus/active colors (upstream); before, the root got `euiExpression--danger`. The alert icon (Ember `alert` = upstream `warning`) gets its margins through EuiIcon `@css`.
- Removed classes: `euiExpression--{color}`, `-isActive`, `-isClickable`, `-isUppercase`, `--columns`, `--truncate`. Kept: `euiExpression`, `__description`, `__value`, `__icon`.
- A clickable expression gets a scoped button reset. New exports: `EXPRESSION_COLORS` and `EuiExpressionColor`. Unknown colors fall back to `success`.

**EuiTourStep**
- The panel gets `euiTour` plus an Emotion class that holds only upstream's descendant rule `[data-popover-arrow='top'] { background: tourFooterBackground }`. It never styles the panel itself, so precedence doesn't depend on insertion order (see Unresolved 2). The popover root gets `euiTourAnchor` (upstream class name).
- **`@minWidth` / `@maxWidth` / `tourPopoverWidth` now apply as `min-inline-size` / `max-inline-size` on a content wrapper div** (upstream). Before, they went on the panel through `@panelStyle`.
- Header (`div.euiPopoverTitle.euiTourHeader`): popover title styles + padding from the popover context, no bottom border, `s` bottom margin. Subtitle: `h2.euiTitle.euiTourHeader__subtitle`, xxxs, `textSubdued`, `xs` bottom padding. Title: `h3` (or `h2` without a subtitle) `.euiTitle.euiTourHeader__title`, xxs. The title id stays on the header and labels the panel.
- Footer (`div.euiPopoverFooter.euiTourFooter`): popover footer styles plus `tourFooterBackground` and panel-radius bottom corners. The flex group is now `alignItems="center"` (upstream). The step list gets a scoped list reset and no whitespace between items.
- **i18n tokens are now upstream's `euiTourFooter.endTour/skipTour/closeTour`** (were `euiTourStep.*`). The default texts are unchanged.
- Beacon: upstream `euiTourBeaconStyles` (absolute, `z-index: 1`, no pointer events, opacity fade-in delayed by `animation.slow` behind `euiCanAnimate`). Upstream reads the side from `onPositionChange`, which Ember's popover doesn't expose. Here the side comes from the preceding arrow's `data-popover-arrow` through `[data-popover-arrow='<side>'] ~ &` rules. The styles sit on a `div.euiTour__beaconWrapper` around `EuiBeacon.euiTour__beacon` because EuiBeacon has no `@css` (see Unresolved 1). Before this port the beacon was not positioned at all.
- Kept from the overlays agent: arrow only with the beacon (`@hasArrow={{this.hasBeacon}}`), offset 10 only with the beacon.

**EuiTourStepIndicator**: `li.euiTourStepIndicator` is upstream inline-block with a scoped reset. Dot colors use the theme `tourStepIndicatorActiveColor` / `tourStepIndicatorInactiveColor` tokens (were named `success` / `subdued`). Removed `euiTourStepIndicator--{status}` and the stray `euiStepNumber__icon` icon class. Aria labels and `aria-current="step"` are unchanged.

**EuiTour**: no change.

## Legacy test assertions changed

- `eui-tree-view-test`: `euiTreeView--compressed` / `--withArrows` and `.euiTreeView__wrapper.euiText--small` became: no wrapper, a measured 24px compressed button, and an arrow placeholder on leaves.
- `eui-expression-test`:
  - `--success` / `-isUppercase` / not `-isClickable` → uppercase transform, `cursor: auto`, no `type`.
  - `-isClickable` / `-isActive` → `type="button"`, `cursor: pointer`, solid bottom border.
  - `--danger` → description color differs from the value color.
  - `--columns` / no `-isUppercase` → `display: flex`, `text-transform: none`.
- `eui-tour-test`:
  - `.euiTourStepIndicator--active` → `[aria-current="step"]` count plus "Step 1 active".
  - `--complete` / `--incomplete` classes → aria labels, icon labels, `inline-block`.

## New coverage (`Borealis misc display…`, 12 tests)

- **Tree view measurements** in a provider: list reset, root vs nested indent, font m/s, row max-height/line-height, button height/gap/padding/radius/reset, icon wrapper and placeholder widths, empty icon, arrows, truncation, the iconWhenExpanded swap, and the focus background.
- **Tree view behavior:** role/instructions (SR-only), aria-expanded/controls only on parents, nested `aria-labelledby`, callbacks, full keyboard navigation, and reactive `@display` without replacing the list or button.
- **Text diff:** elements, token colors, decorations, character granularity, and reactive text without replacing the root.
- **Expression:**
  - Base metrics, code font and sibling spacing.
  - Each of the 6 colors: description color, active border, focus background, button semantics.
  - Clickable border and click; reactive color/active/invalid/columns/width/truncate on the same element.
  - Columns layout, the HC-less transparent border, the value underline on focus, and the icon `@css` margins.
- **Tour step:**
  - Anchor and panel classes and `aria-labelledby`.
  - Header border/margin/padding, subtitle/title tags and colors.
  - Reactive min/max inline size on the same panel.
  - Footer background/radii/padding, list reset, indicator labels and colors, skip button.
  - Top arrow in the footer color; beacon wrapper position for `top` and `left`; opacity; transition under `euiCanAnimate`, or none with reduced motion.
- **Other tour cases:** default `leftUp` with a non-footer arrow, a single step ("Close tour", h2 title), and `decoration="none"` (no beacon, no arrow).
- **EuiTour:** `tourPopoverWidth`, `goToStep`, End tour, indicators.
- **Theming:**
  - Light/dark nearest provider, nested light, sibling isolation and a reactive mode switch; the dark tour footer and arrow.
  - JS-object overrides (`textDanger`, `size.s`) with outside isolation; high contrast `preferred` shows the columns border.
- **RTL:** tree indent and padding, expression sibling margin, columns description margin/alignment, icon margin.

## Checks (worktree, Chromium 130, CI=true, Node 22; binaries run directly)

- Filtered family run (`misc display|tree-view|expression|tour|text-diff`): **28/28**.
- Full core suite: **851 tests, 850 pass, 1 fail**. The failure is the pre-existing base failure described at the top.
- `node --test scripts/eui-upstream-parity.test.mjs`: **182/182**.
- `node scripts/generate-eui-styles.mjs --check`: the expected worktree "stale" result (symlinked source-path comments). It extracted 210 factories, React-free.
- `ember-tsc --noEmit`: pass. ESLint on all changed sources and tests: pass.
- `generate-api-docs.mjs --check`: fails only on the four pages that were already stale on the base (icons, list-group, panel, button); no family page differs.
- Not run (coordinator): rollup build, site build/acceptance, showcase.

## Unresolved / for the coordinator

1. **Missing `@css` on migrated children** (rule: report, don't edit):
   - `EuiPopoverTitle`, `EuiPopoverFooter`, `EuiTitle`: once they accept `@css`, `-private/eui-tour-parts.gts` can render them with `euiTourHeaderStyles.*` / `euiTourFooterStyles.euiTourFooter`.
   - `EuiBeacon`: then drop `div.euiTour__beaconWrapper` and pass the beacon styles through `@css`.
2. **`EuiPopover` has no panel `css` argument** (upstream `panelProps.css`). The tour's arrow rule goes in through `@panelClassName`; it is order-safe because it only targets the arrow. A private `@panelCss` (like `@rootCss`) would make this explicit.
3. **Base failure:** the `EuiCollapsibleNav` overlay z-index (1000 vs `levels.navigation` 6000) fails on `9e3d1e09`. It is likely a header × modal-flyout merge interaction.
4. Stale API docs on the base (icons, list-group, panel, button): regenerate them in the main checkout.
5. Not ported: tree view `icon` as arbitrary markup (it stays an EuiIcon type) and per-node `css`; tour `panelProps`, `footerAction` arrays (the `<:footerAction>` block covers that), `anchor` selectors via EuiWrappingPopover, and the `step === 0` warning.

## Next step

Coordinator: merge, regenerate in the main checkout, fix the collapsible nav base failure, then mark these rows Migrated. Switch the items in Unresolved 1–2 to `@css` when it lands.
