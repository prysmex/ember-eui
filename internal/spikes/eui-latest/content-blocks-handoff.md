# Content blocks family migration handoff (EuiCallOut, EuiEmptyPrompt, EuiStat)

Status: **Migrated**. The full core suite passes in Chromium 130 (683/683), along with upstream parity (41/41), the generator check, types, lint and API docs.

## Files

- `packages/core/src/components/eui-call-out.gts`, `eui-empty-prompt.gts`, `eui-stat.gts` and `eui-stat/title.gts`: now Glimmer classes on extracted factories, with `@cached` class getters. Factories are read only through `useEuiBorealisStyles`. `eui-stat/description.gts` stays template-only (it has no styles of its own).
- `packages/core/src/utils/eui/content-blocks.ts` (new, family-local): `euiPanelSurfaceCss(context, …)`.
  - Upstream renders CallOut and EmptyPrompt as an `EuiPanel` with extra `css`, which Emotion merges into one class. Ember's EuiPanel cannot take extra Emotion styles, and putting a second class on it makes the winner depend on insertion order. For example, Panel's reset sets `border: none; padding: 0; text-align: start`.
  - This helper therefore composes the panel slots in upstream `panel.js` order (reset, `euiPanel`, grow, radius, background, `hasBorder`, high-contrast border). They come first in the component's single class.
  - It mirrors `eui-panel.gts`, which was not touched.
- `scripts/generate-eui-styles.mjs`: new `// content-blocks` block adds `euiCallOutStyles`, `euiCallOutHeaderStyles`, `euiEmptyPromptStyles`, `euiStatStyles` and `euiStatTitleStyles`. The generator now extracts 46 factories.
- `styles.generated.ts` and `upstream-sources.json` were regenerated, never edited by hand.
- `scripts/eui-upstream-parity.test.mjs`: the five factories are in the `factories` map and go through the 12-configuration matrix.
- `packages/core/tests/integration/components/eui-content-blocks-test.gts`: new, 16 computed-style and behavior tests.
- `packages/core/docs/display/{callout,empty-prompt,stat-demo}/index.md`: only the generated API sections were regenerated.
- Not touched:
  - `text-block.gts`, EuiTitle, EuiText, EuiPanel and EuiButtonIcon.
  - `utils/css-mappings/eui-{call-out,empty-prompt,stat}.ts`. They are now unused by these components but still imported by the mappings index.
  - Providers, the site and `.vscode/settings.json`.

### Legacy test updates

Each legacy-class assertion was replaced with a check of the same intent:

- `eui-call-out-test.gts`:
  - `.euiCallOutHeader` wrapper and `svg.euiCallOutHeader__icon` → `p.euiCallOutHeader__title`, plus "exactly one aria-hidden svg, and no default icon when `@iconType` is set". Upstream has neither the wrapper nor the icon class.
  - `.euiCallOut--small` → `data-size="s"`. Upstream drives sizes by `data-size`.
  - `.euiCallOut .euiText` → `.euiCallOut__additionalContent`, the upstream class for children.
- `eui-empty-prompt-test.gts`:
  - `--vertical`, `--horizontal` and `--padding*` modifiers → `doesNotHaveClass` plus structure. Layout and padding are measured in the new file.
  - `__contentInner` → `__content`. Upstream has no inner wrapper.
  - The title→body spacer is now 8px instead of 16px, because upstream uses an `s` spacer.
  - The single action is asserted inside `.euiEmptyPrompt__actions`.
- `eui-stat-test.gts`:
  - `--centerAligned` → computed `text-align: center`.
  - `__title--success` → `doesNotHaveClass`. Colors are measured in the new file.
  - `__title-isLoading` → `aria-label="Statistic is loading"`.

## API and default changes (latest-only)

### EuiCallOut

- **The heading defaults to `<p>`** (upstream), not `<span>`.
  - The title is now an `EuiTitle` (size `xs`, or `xxs` when `@size="s"`) carrying `euiCallOutHeader__title`.
  - The `.euiCallOutHeader` wrapper div and the `euiCallOutHeader__icon` class are gone.
- **A default icon is always shown**, chosen by color, even without a title. Before, an icon showed only when there was a title and an `@iconType`.
  - Upstream's `infoFill`, `checkCircleFill`, `warningStatic` and `errorFill` are not in Ember's icon set. They map to `iInCircle`, `checkInCircleFilled`, `warning` and `error`, with class `euiNotificationIcon`.
  - A custom `@iconType` gets upstream's `borderStrong<Color>` token as its color.
  - `@iconSize` now defaults to `l` (or `m` for size s), as upstream; it was `m`.
- **New arguments:**
  - `@onDismiss`: an `xs` EuiButtonIcon with a `cross` icon, the callout's color and `data-test-subj="euiDismissCalloutButton"`. Its label comes from the i18n token `euiCallOut.dismissAriaLabel` ("Dismiss this callout"), or from `@dismissButtonAriaLabel`. The DOM order follows upstream: title, button, body (body then button when there is no title).
  - `@text`: upstream `text` → `.euiCallOut__text`, EuiText `s`, inline after the title in small callouts.
  - `<:actions>` block: Ember's equivalent of upstream `actionProps`. Callers pass `EuiButton`/`EuiButtonEmpty @size="s"`.
- **Upstream's width-driven layout.** A modifier observes the callout's width and sets `data-layout="superNarrow"` (≤400px) or `"wide"` (≥800px for size s, ≥1000px for size m). In a wide callout the actions sit beside the text. The attribute is written in the next animation frame, which avoids the browser's "ResizeObserver loop" error that a synchronous write triggers.
- **Unknown colors fall back to `primary`**, as upstream. The four colors are unchanged; upstream added none and removed none.
- Body text uses `@textColor`, defaulting to `'default'` (upstream).
- Root classes are `euiCallOut euiCallOut--<color>`; there is no size class. Attributes such as `role`/`aria-live` (used by EuiForm) are forwarded.
- **Dismiss button wrapper (deliberate deviation).** Upstream puts `position: absolute; inset…` on the button through `css`. EuiButtonIcon's own class sets `position: relative`, and as two separate classes the winner depended on insertion order: the button ended up in normal flow, which the RTL test caught. The positioning therefore lives on a shrink-wrapping `<span>` (`display: flex`) around the button.
  - Follow-up: give EuiButtonIcon (and other migrated components) a way to append caller Emotion styles to their single class.
- Not ported: `announceOnMount` (Ember has no EuiLiveAnnouncer) and the action tooltips/popovers from upstream `actionProps`.

### EuiEmptyPrompt

- **`@hasBorder` defaults to `color === 'plain'`** (upstream). Before, it was passed through to EuiPanel, whose default is `true`, so transparent prompts used to have a border.
- **No longer grows.** Upstream sets `grow=false`; it used to inherit Panel's `grow=true`.
- The root is a plain div composed from the panel surface plus `euiEmptyPrompt`. It is no longer an `EuiPanel` instance, so there is no `data-eui-panel`/`euiPanelBorealis`.
- **Classes:**
  - Removed: `euiEmptyPrompt--vertical`, `--horizontal`, `--padding*` and `__contentInner`.
  - Kept: `euiEmptyPrompt`, `__main`, `__icon`, `__content`, `__actions` and `__footer`.
- **Spacing:** the title→body spacer is now `s` (was `m`), and the actions spacer appears only after a title or body (upstream).
- An `@actions` array always renders upstream's actions flex group, even for a single action (it used to need two or more). The flex group styles (gutter m, centered, column/row, responsive row) and the prompt's actions `css` are composed into one class on a `div.euiFlexGroup.euiEmptyPrompt__actions`, for the same insertion-order reason as the panel surface.
- **`@iconColor`** defaults to `@color` when that is a named icon color, otherwise to `subdued`. It used to pass e.g. `'plain'` straight to EuiIcon.
- Footer: upstream colors, padding, and rounded corners for a borderless transparent prompt.
- The horizontal layout collapses below the `l` breakpoint (992px) through upstream's min-width media queries.
- **`@paddingSize` type** is now `'none' | 's' | 'm' | 'l'`, which is what upstream supports. It used to be typed as EuiPanel's padding.

### EuiStat

- **No more `aria-hidden` title/description and no screen-reader duplicate paragraph** (upstream 123 renders neither). `@screenReader` stays a deprecated no-op.
- **Loading:**
  - The title shows `--`.
  - It gets `aria-label` from the i18n token `euiStat.loadingText` ("Statistic is loading").
  - It pulses (1.5s infinite) only under `prefers-reduced-motion: no-preference`.
- **The title is a single element** (`@titleElement`, default `p`) carrying `euiTitle euiStat__title` with the EuiTitle size styles, the same as upstream's cloned EuiTitle.
  - It used to be an EuiTitle `<p>` wrapping another `<p>`.
  - It is a Glimmer class and no longer needs `@isColorClass`, which is now deprecated and ignored.
- **Colors:** adds `warning`. Default is `fullShade`. Custom CSS colors use an Emotion class, not an inline style.
- **Alignment is logical:** start/center/end plus `align-items`, so left/right flip in RTL.
- Removed classes: `euiStat--*Aligned`, `euiStat__title--<color>` and `euiStat__title-isLoading`.

## Checks run (2026-10-12, worktree `eui-wave/content-blocks`)

Environment: Node 22 and Chromium 130 through the scratchpad `google-chrome` shim, with `CI=true`. Binaries were run directly.

- Core tests (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **683 tests, 683 pass, 0 fail**. That is the 667 base tests plus 16 new `Borealis content blocks` tests.
- Filtered run of the family, the legacy tests and `eui-form`: 50/50.
- `node scripts/generate-eui-styles.mjs --check`: pass (exit 0, 46 factories, React-free).
- `node --test scripts/eui-upstream-parity.test.mjs`: **41/41** (36 before plus 5 new).
- `ember-tsc --noEmit`: pass. ESLint on all changed sources and tests: pass.
- `node scripts/generate-api-docs.mjs --check`: pass after regenerating 3 pages.
- Not run (root): rollup/core build, site build/type check, acceptance tests, showcase.

## Test notes

- The test container is scaled 0.5, so positions are measured with `offset*` or scale-corrected rects.
- The testem window is 1440px wide, above the `l` breakpoint, and cannot be resized. The responsive collapse is therefore checked two ways:
  - The horizontal `__main` rules sit inside `@media … (min-width: 992px)`, read from the CSSOM.
  - The computed state matches `matchMedia`.
- The callout layout test resizes its container through `element.style` and waits a few animation frames for the observer and its deferred write.

## Unresolved

1. **Icon family:**
   - Upstream sizes the default notification icon and m-size custom icons to 20px (`euiNotificationIconStyles.size.l`). Per the wave rules this is not applied, so Ember passes `@size="l"` (24px legacy). Revisit once EuiIcon lands.
   - The family should add `infoFill`, `checkCircleFill`, `warningStatic` and `errorFill`, then swap `DEFAULT_ICONS` in `eui-call-out.gts`.
   - Icon colors and `fill: currentColor` depend on the icon port.
   - The callout's icon `position`/`margin` class sits beside EuiIcon's class. That is fine today (EuiIcon has no Emotion class), but it will race on insertion order if the icon port sets `position` or `margin`.
2. **Duplicated composition:** `euiPanelSurfaceCss` duplicates `eui-panel.gts`'s composition, and the dismiss button needed a wrapper. Suggested shared change (root/panel/button owners): let migrated components accept extra Emotion interpolations (an `@css`-style argument) so composite components can append styles to one class, as upstream does. Then CallOut/EmptyPrompt can render a real EuiPanel and drop the wrapper.
3. EuiForm's error callout now shows the danger icon and a `p` title (upstream defaults). Docs demos were not visually audited (callout `@iconSize="s"` demos, page-template empty prompts that relied on the old default border/grow).
4. Not ported from upstream: `announceOnMount` (no EuiLiveAnnouncer) and `actionProps` tooltips/popovers.

## Next step

Root: merge, regenerate in the main checkout, then run the core build, site build/type check and showcase. Then decide on item 2 (the extra-styles argument for migrated components).
