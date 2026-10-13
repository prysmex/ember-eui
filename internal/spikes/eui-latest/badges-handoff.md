# Badge family migration handoff (EuiBadge, EuiBadgeGroup, EuiBetaBadge, EuiNotificationBadge)

Status: **Migrated**. The full core suite passes in Chromium 130 (621/621), along with upstream parity, types, lint and API docs.

## Files

- `packages/core/src/components/eui-badge.gts`: Glimmer class on `euiBadgeStyles` and the extracted color helpers (`getTextColor`, `getCustomInteractiveColors`, `getIsValidColor`). It also exports small shared helpers that EuiBetaBadge uses: `euiBadgeReset`, `euiBadgeIconSizing`, `secureRel`, `BADGE_COLORS` and `EuiBadgeNamedColor`.
- `eui-badge-group.gts`, `eui-beta-badge.gts`, `eui-notification-badge.gts`: Glimmer classes on `euiBadgeGroupStyles`, `euiBetaBadgeStyles` and `euiNotificationBadgeStyles`.
- `packages/core/tests/integration/components/eui-badge-family-test.gts`: new, 12 computed-style tests.
- Updated legacy-class assertions, replaced with computed-style or semantic checks of the same intent:
  - `eui-badge-test.gts`, `eui-badge-group-test.gts`, `eui-beta-badge-test.gts`, `eui-notification-badge-test.gts`.
  - `eui-facet-test.gts` and `eui-filter-group-test.gts`: these asserted `euiNotificationBadge--subdued`. They now compare the badge background with the Borealis `subdued` and `accentText` colors. The old `doesNotHaveClass('…--subdued')` checks for the accent state became positive accent-color checks, so they are stronger, not weaker.
  - `eui-badge-test.gts` "@href with @iconType": now asserts that the whole `a.euiBadge` is the link, as upstream does (see the DOM changes below).
- `packages/core/docs/display/badge/index.md`: only the generated API section was regenerated.
- `components.md`: the four rows.
- Not touched:
  - The generator, `styles.generated.ts`, `upstream-sources.json`, providers and shared utilities.
  - EuiIcon and EuiToolTip, and other families.
  - `utils/css-mappings/eui-*badge*.ts`. Components no longer use them, but `eui-header-section-item-button.gts` imports a type from the notification mapping, and the mapping registry still lists them.

## API and default changes (latest-only)

### EuiBadge

- **Named colors default to the light "base" variant, as upstream does (`fill=false`).** The new `@fill={{true}}` arg gives the stronger filled variant. Before, named colors were solid VIS colors. This is a visible default change.
- **New colors** `neutral` and `risk`. `default` is now upstream's light badge (`backgroundLightText`), not `#d3dae6`.
- **Custom colors** accept any color that chroma can parse (hex, `rgb()`, …).
  - Text and hover colors come from upstream `getTextColor` and `getCustomInteractiveColors`: ink or ghost text, picked for contrast.
  - The four `--euiBadge*` custom properties are set in an Emotion class rather than upstream's inline `style`, so a caller's `style` attribute is never overwritten.
  - An invalid color falls back to upstream's default fill colors and fires an Ember `warn` (id `ember-eui.eui-badge.invalid-color`).
  - Disabled badges ignore custom colors.
- **DOM follows upstream.**
  - With `@onClick`/`@href` and no `@iconOnClick`, the whole badge is the `<button>`/`<a>`, even with `@iconType`. Before, an `@iconType` badge got an inner `euiBadge__childButton`.
  - `euiBadge__childButton` is now used only when `@iconOnClick` is combined with `@onClick`/`@href`, as upstream does.
  - The icon renders before the text for `left` and after it for `right`, with logical margins, so it flips in RTL.
  - The legacy `--iconLeft`/`--iconRight`, `--hollow`, `-isClickable` and `-isDisabled` classes are gone. The root class `euiBadge` and the upstream element classes (`euiBadge__content`, `__text`, `__icon`, `__iconButton`, `__childButton`) are kept.
- **Icons are always upstream size `s` (12px).** Before, icon-only badges used `m`. EuiIcon is not migrated, so the badge sizes and colors its SVG locally (`euiBadgeIconSizing`).
- **Root `title` is the badge's inner text** (upstream EuiInnerText), which shows truncated text on hover. A caller's `title` attribute still wins because it comes after `...attributes`.
- **Links:** new `@rel` arg. `noreferrer` is always added, plus `noopener` for `_blank` (upstream `getSecureRelForTarget`).
- **`javascript:` hrefs disable the badge**, as upstream's `validateHref` does. Upstream calls `new URL(href)` without a base, which throws on relative hrefs. Ember passes a base so `#anchor` and `/path` stay valid.
- `@onClick` and `@iconOnClick` now receive the `MouseEvent`. The types are widened, so existing `() => void` callers still type-check.
- `@iconOnClick` with `@onClick`/`@href`: `...attributes` stay on the root `<span>`, unlike upstream, which spreads its rest props onto the child button. Ember callers such as the combo-box pill use the root `class`.
- `@iconUseSvg` is kept as deprecated and is still passed through to EuiIcon.

### EuiBetaBadge

- New `warning` color and new `@alignment` (`baseline` by default, or `middle`).
- **Clickable badges with `@tooltipContent` render once, inside the tooltip.** Before, Ember rendered them twice, once outside the tooltip and once inside.
- Title, as upstream:
  - Clickable badges use the label, else `@title`.
  - Plain badges use `@title`, else `@label`. Before, plain badges used `@title` only.
  - Tooltip anchors get no title, plus `tabindex="0"` and `role="button"`. `role="button"` is new; upstream sets it.
- `@rel` is secured the same way as on EuiBadge.
- Legacy modifier classes are gone, and `Element` is widened to include `a`/`button`.
- Upstream `anchorProps` (a wrapper `<span>`) is not ported: no wrapper is rendered.

### EuiNotificationBadge

- New `success` color. Every property animates (`transition: all`), as upstream does.

### EuiBadgeGroup

- New `none` gutter. Gutters use flex `gap`.
- The Ember-only `group.item` wrapper is kept. It gets `min-inline-size: 0; max-inline-size: 100%`, so badges inside it truncate.

### Scoped resets

These stand in for React's global reset, composed before the upstream styles so every upstream rule wins:

- Box sizing and the Borealis font family on all four components.
- A `button` reset (background, border, padding, font, color) on badge root buttons, the icon button and the child button, and on beta badge buttons.

## Checks run (2026-10-12, worktree `eui-batch2/badges`)

Environment: Node 22.22.1 and Chromium 130 through the scratchpad `google-chrome` shim, with `CI=true`. Binaries were run directly because pnpm is unavailable.

- Core tests (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **621 tests, 621 pass, 0 fail**. That is the 609 base tests plus 12 new `Borealis badge family` tests.
- `node --test scripts/eui-upstream-parity.test.mjs`: **29/29 pass**.
- `node scripts/generate-eui-styles.mjs --check`: **reports "stale" in this worktree, for an environmental reason.**
  - The worktree's `node_modules` is a symlink to the main checkout, so esbuild writes `// ../../…/Users/…/node_modules/...` source-path comments.
  - Regenerated into the scratchpad, the output differs from the committed file **only in those `//` path comments: 0 code lines differ**.
  - No generated file was edited.
- `ember-tsc --noEmit`: pass.
- ESLint on all changed components and tests: pass.
- `node scripts/generate-api-docs.mjs --check`: pass after regenerating. Private sub-component signatures are placed after the main class, so the docs generator picks the public signature.
- Not run (root agent's job): rollup/core build, site build, acceptance tests and showcase.

## Test notes and findings

- `#ember-testing` is scaled to 50%. Geometry assertions divide `getBoundingClientRect()` by the container's scale.
- **Root font size (shared finding):** upstream font sizes are rem based, and EUI apps set `html { font-size: 14px }` (Borealis body scale). The Ember test page and apps keep the browser's 16px, so the `xs` badge text computes to 13.71px instead of 12px. Line heights and boxes are in px and match. The tests assert `rem × root`.
  - This is a root/provider decision (owner: root agent), like EuiText's inherited color. It should not be patched per component.
- Notification badges animate every property for `animation.fast`, so the tests call `document.getAnimations().forEach(a => a.finish())` after reactive changes.
- Focus rings follow upstream `euiFocusRing`: `outline-style: auto` only for `:focus-visible`, otherwise `none`, with a 3px outset offset. The tests assert against `:focus-visible`.
- In `preferred` high contrast:
  - Upstream maps `textInk` to `#000`, so custom-color text expectations are computed with `getTextColor` on the high-contrast theme.
  - Named badges get a border in their own color (`--euiBadgeBorder`), not `border.color`.
- Upstream disabled badges inherit the cursor (`cursor: inherit`). Only the disabled child and icon buttons show `not-allowed`, so Ember does the same.

## Unresolved

1. Root font size of 14px vs 16px (see above). This affects every rem-based migrated component.
2. Hover and active interaction colors (`euiButtonInteractionStyles`, and `color-mix()` for custom colors) are covered only by the factory parity tests, not by browser hover assertions.
3. An empty-but-present block (e.g. `combo-box/create-option` with `{{#if}}` inside the badge) renders an empty `euiBadge__text`. Ember cannot tell an empty block apart from content, so the badge keeps text padding instead of becoming icon-only.
4. Callers were not visually audited: combo-box pill/options, selectable list item, card, key pad menu item, facet/filter buttons, header section item button, and notification event meta. They now get Borealis badges. On legacy docs pages, Amsterdam `.euiBadge`/`.euiBetaBadge` vendor rules still apply too.
5. EuiToolTip is unmigrated. The beta badge tooltip wrapper works as before.

## Next step

Root agent: merge, then run the core build, site build and showcase checks. Decide the root font-size policy. Optionally, add badge samples to `/docs/eui-latest`.
