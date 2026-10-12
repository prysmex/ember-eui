# Utilities and loaders migration handoff

Branch `eui-wave/utilities`. Target EUI 123.1.0 / Borealis 8.1.0. Status: **Migrated** (full core suite passes in this worktree).

## Scope

Styled ports: EuiScreenReaderOnly (+ `screenReaderOnly` modifier), EuiSkipLink, EuiProgress, EuiLoadingContent, EuiLoadingChart, EuiLoadingElastic, EuiLoadingLogo, EuiOverlayMask, EuiMark, EuiHighlight, EuiCode (inline only), EuiImage, EuiAspectRatio, EuiShowFor/EuiHideFor (theme breakpoints).

Audited, no styles upstream (behavior kept, tests confirmed): EuiPortal (adds upstream `data-euiportal="true"`), EuiDelayHide, EuiDelayRender, EuiInnerText, EuiI18n, EuiI18n/render, EuiI18nNumber, EuiAutoSizer, EuiCopy, and the private `text-block.gts` (no upstream counterpart; contract for CallOut/NotificationEvent/Title unchanged).

## Files

- Components: `eui-screen-reader-only.gts`, `eui-skip-link.gts`, `eui-progress.gts`, `eui-loading-{content,chart,elastic,logo}.gts`, `eui-overlay-mask.gts`, `eui-mark.gts`, `eui-highlight.gts`, `eui-code.gts`, `eui-image.gts`, `eui-aspect-ratio.gts`, `eui-show-for.gts`, `eui-hide-for.gts`, `eui-portal.gts`.
- `modifiers/screen-reader-only.ts`: now a class modifier applying the upstream SR-only styles (owner's default Emotion cache; the styles are theme independent).
- `utils/eui/utilities.ts` (new, hand port with upstream license header): `euiMarkStyles`, `euiMarkScreenReaderStyles`, `euiOverlayMaskStyles`. Reasons: `mark.styles.js` imports `euiScreenReaderOnly` through the React `components/accessibility` barrel (the generator rejects it); `overlay_mask.styles.js` uses `@emotion/css` (class names in Emotion's global cache), not `@emotion/react`. Parity: mark slots deep-equal upstream; overlay mask slots produce the same `css-<name>` class and the same registered styles as upstream's `@emotion/css`.
- `scripts/generate-eui-styles.mjs` (`// utilities` block) and regenerated `styles.generated.ts` / `upstream-sources.json`: 35 -> 58 factories. Added: `euiScreenReaderOnly`, `euiScreenReaderOnlyStyles`, `euiSkipLinkStyles`, `euiProgressStyles`, `euiProgressDataStyles`, `euiProgressLabelStyles`, `euiProgressValueTextStyles`, `makeHighContrastColor`, `euiSkeletonTextStyles`, `euiLoadingChartStyles`, `euiLoadingChartBarStyles`, `euiLoadingElasticStyles`, `euiLoadingLogoStyles`, `euiAnimFadeIn`, `highContrastModeStyles`, `logicalCSS`, `euiCodeStyles`, `euiImageStyles`, `euiImageWrapperStyles`, `euiImageButtonStyles`, `euiImageButtonIconStyles`, `euiImageCaptionStyles`, `euiImageFullscreenWrapperStyles`. Only esbuild renames/reordering change existing factories.
- `scripts/eui-upstream-parity.test.mjs`: 14 new factories in the 12-configuration matrix; new tests for progress (native/indeterminate × 6 modes × default/overridden), static SR-only/progress-label/loading-elastic styles, `makeHighContrastColor`, and the hand ports. 30 -> 48 tests.
- Tests: new module `Integration | Component | Borealis utilities` in `tests/integration/components/eui-utilities-test.gts` (14 tests). Updated legacy assertions (below).
- API docs regenerated (7 pages: highlight-and-mark, image, loading, progress, accessibility, overlay-mask, responsive).

## Reusable SR-only helper (adopters)

`eui-screen-reader-only.gts` exports `euiScreenReaderOnlyCss(showOnFocus)` (serialized upstream slot, to compose into a component's own class) and `euiScreenReaderOnlyClass(context, showOnFocus)` (root class + Emotion class). Used here by SkipLink, Progress (live region), Image (instructions) and the modifier. Not edited (other families), candidates to adopt:

- `eui-link.gts`: local `screenReaderOnlyCss` copy of the mixin -> `euiScreenReaderOnlyCss()`.
- `eui-button-group-button.gts`: hard-coded `class="euiScreenReaderOnly"` spans (no styles without legacy CSS) -> `euiScreenReaderOnlyClass`.
- Modifier users already get upstream styles through the modifier: toast, stat, hue, form-legend, color-palette-display, button-group, super-select(+control), refresh-interval, table-header-cell, color-stops(+thumb), popover, bottom-bar, side-nav, tree-view, step-number, selectable-list-item, control-bar.

## API / default changes (latest-only)

- EuiScreenReaderOnly: showOnFocus root class is upstream's label `euiScreenReaderOnly-showOnFocus` (was `euiScreenReaderOnly--showOnFocus`). Same for the modifier. Plain variant keeps `euiScreenReaderOnly`.
- EuiSkipLink: new `@fallbackDestination` (default `'main'`) and `@overrideLinkBehavior`; clicking moves focus to the destination (temporary `tabindex="-1"` when not tabbable), as upstream. Legacy `euiSkipLink--{position}` classes removed.
- EuiProgress: any CSS color in `@color` (value text gets upstream's contrast-adjusted color); adds `accentSecondary`. **`@valueText={{true}}` now renders `{value}%`** (upstream, i18n token `euiProgress.valueText`). `@label` (was deprecated/no-op) now works like upstream's `label`. Determinate bars get upstream's `aria-label`/`aria-valuetext` from the rendered label/value text and an SR-only `aria-live="polite"` region; the old `aria-hidden` on the progress element is gone. Label/value wrappers are `<div>`s (upstream).
- EuiLoadingChart/Elastic/Logo/Content: `role="progressbar"` and `aria-label` from `euiLoadingStrings.ariaLabel` ("Loading"), overridable by attributes. Chart `@mono` is deprecated/no-op (latest uses only mono tokens). Logo now forwards `...attributes` (new `Element: HTMLSpanElement`). Content uses upstream EuiSkeletonText styles, adds `@size` (`m` default, `s`, `xs`, `relative`); the inner `euiLoadingContent__singleLineBackground` span is gone.
- EuiOverlayMask: z-index from `levels.mask` / `levels.maskBelowHeader`, `--euiFixedHeadersOffset` top for `below`, `data-relative-to-header` attribute instead of `--aboveHeader/--belowHeader` classes; new `@hasAnimation` and `@maskRef`. Body scroll lock is an Emotion `overflow:hidden` class added with `euiBody-hasOverlayMask` through the ref-counted `setBodyClass` (upstream uses a `<Global>` body rule).
- EuiMark: new `@hasScreenReaderHelpText` (default `true`, upstream) adds visually hidden " [highlight start] " / " [highlight end] " pseudo content (i18n tokens `euiMark.highlightStart/End`).
- EuiHighlight: `@search` accepts an array with `@highlightAll` (upstream); passes `@hasScreenReaderHelpText`. Multiple terms without `@highlightAll` throw, as upstream.
- EuiCode: `euiCode--transparentBackground` class removed; syntax highlighting untouched.
- EuiImage: upstream structure and classes: `figure.euiImageWrapper`, `img.euiImage`, `button.euiImageButton`, `figcaption.euiImageCaption`, `.euiImageFullScreenWrapper` (old `euiImage__img`, `euiImage__button`, `euiImage--*` removed). **`@hasShadow` now defaults to `false`** (upstream; docs said `true`). String custom sizes are kept as CSS lengths (`'50%'`); numbers and numeric strings become px. Figure gets `aria-label` from `@caption`; SR instructions in the buttons; new `@onFullScreen`; Escape on the full-screen button closes. `...attributes` still go on the figure. Signature fixed (`Component<EuiImageSignature>`).
- EuiAspectRatio: CSS `aspect-ratio` on a single wrapper (upstream applies it to the cloned child; Ember cannot clone a block, so the direct child fills the wrapper and is made `display:block`). The extra outer `max-width` div and inline `padding-bottom` style are gone.
- EuiShowFor/EuiHideFor: breakpoints come from the nearest theme (`euiTheme.breakpoint`, so `@borealisOverrides` apply). Fixed a listener leak (a resize listener was added on every recompute). New exported type `EuiResponsiveSizes`; `CurrentBreakPointHelper` now takes `(sizes, breakpoints)`.
- EuiPortal: adds `data-euiportal="true"`. Not ported: upstream adds the nested theme's color class to body portals when the provider's color differs from the global theme.

## Legacy test assertions changed

- `eui-screen-reader-only-test`: `--showOnFocus` -> `-showOnFocus` class (upstream label).
- `eui-skip-link-test`: position/SR modifier classes -> computed `clip-path` / `position: fixed`.
- `eui-progress-test`: modifier classes -> computed height; value text `70` -> `70%` (upstream default).
- `eui-loading-test`, `eui-loading-chart-test`: size/mono modifier classes -> role / computed height.
- `eui-aspect-ratio-test`: inline `padding-bottom` -> `aspect-ratio` style.
- `eui-image-test`: `euiImage__img`/`euiImage__button` -> upstream `euiImage`/`euiImageButton`.
- `eui-internals-test` (overlay mask): `euiOverlayMask--belowHeader` class -> `data-relative-to-header="below"`.
- `eui-utilities-test` (existing module): `euiCode--transparentBackground` class -> computed transparent background.
- `eui-portal-test`: added the `data-euiportal` assertion.

## Checks (2026-10-12, worktree, Chromium 130)

- `node scripts/generate-eui-styles.mjs --check`: pass (58 factories, React-free).
- `node --test scripts/eui-upstream-parity.test.mjs`: **48/48 pass** (30 before).
- `ember-tsc --noEmit`: pass. ESLint on all changed components/tests: pass (generated file is lint-ignored).
- `node scripts/generate-api-docs.mjs --check`: pass after regenerating 7 pages.
- Core (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **670 tests, 670 pass, 0 fail**, including the 14 new `Borealis utilities` tests.
- Not run (coordinator): rollup core build, site build/acceptance, showcase screenshots.

## Unresolved / notes

1. The modifier cannot see provider context, so its class lives in the owner's default Emotion cache; a provider with a custom cache container (e.g. shadow root) would not receive it. The styles are theme independent.
2. On a button (skip link, modifier on a button), EuiButton's min sizes still apply under SR-only, as upstream; `clip-path: inset(50%)` keeps it invisible.
3. Chrome's `getComputedStyle` ignores `::-webkit-progress-value`; tests read the matching stylesheet rule instead.
4. Indeterminate progress animates by default and switches to static stripes under `prefers-reduced-motion: reduce` (upstream), unlike the other loaders which only animate under `no-preference`.
5. Portal theme color class (see above) and translated defaults rely on the `euiI18n` service tokens; no translations added.
6. Callers still using legacy classes for these components: none in core source; `utils/css-mappings/eui-progress*.ts` and `eui-image.ts` are now unused by the components (left in place; MarkdownFormat-related mappings untouched).

## Next step

Coordinator: merge, regenerate in the main checkout, run site build/acceptance. Other families may adopt `euiScreenReaderOnlyCss` (EuiLink, EuiButtonGroupButton).
