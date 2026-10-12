# Range family migration handoff (EuiRange, EuiDualRange and range parts)

Branch `eui-wave/range`. Target EUI 123.1.0 / Borealis 8.1.0. Status: **Migrated**. The full core suite passes in this worktree (922/922).

## Files

- Components, all Glimmer classes now, with `@cached` style getters and factories only through `useEuiBorealisStyles`:
  - `eui-range.gts`, `eui-dual-range.gts`
  - `eui-range-wrapper.gts`, `eui-range-track.gts`, `eui-range-slider.gts`, `eui-range-thumb.gts`, `eui-range-ticks.gts`, `eui-range-levels.gts`, `eui-range-highlight.gts`, `eui-range-label.gts`, `eui-range-tooltip.gts`, `eui-range-input.gts`
- `packages/core/src/utils/eui/range.ts` (new, upstream license header): hand ports of the logic that lives in React modules: `calculateThumbPosition` (with a guard for an unmeasured track), the levels' `calculateOffset`/position, the tick label shift, `handleAriaValueText`, and `logicalStyle()` (upstream `logicalStyles` for inline styles, so positions mirror in RTL).
- `scripts/generate-eui-styles.mjs`, `// range` block: `euiRangeVariables`, `euiRangeStyles`, `euiDualRangeStyles`, `euiRangeDraggableStyles`, `euiRangeDraggableInnerStyles`, `euiRangeHighlightStyles`, `euiRangeHighlightProgressStyles`, `euiRangeHighlightLevelsWrapperStyles`, `euiRangeHighlightLevelsStyles`, `euiRangeInputStyles`, `euiRangeLabelStyles`, `euiRangeLevelsStyles`, `euiRangeLevelStyles`, `euiRangeLevelColor`, `getLevelColor`, `isNamedLevelColor`, `euiRangeSliderStyles`, `euiRangeThumbStyles`, `euiRangeTicksStyles`, `euiRangeTickStyles`, `euiRangeTooltipStyles`, `euiRangeTooltipValueStyles`, `euiRangeTrackStyles`, `euiRangeWrapperStyles` (24 names; 266 total). All extracted cleanly.
  - **Adapter change:** `range.styles.js` imports `hexToRgb` from the `services` barrel, so the services barrel shim now also re-exports `./color/hex_to_rgb` (pure, like the existing `is_color_dark` re-export). No React involved.
  - `styles.generated.ts` / `upstream-sources.json` regenerated; worktree `../../…/Users/…` source-path comments normalized back to `node_modules/…` with sed.
- `scripts/eui-upstream-parity.test.mjs`: 21 factories in the 12-configuration matrix, plus a test for the level color helpers (`getLevelColor`, `isNamedLevelColor`, `euiRangeLevelColor`). 212 → 234.
- Tests: new `tests/integration/components/eui-range-family-test.gts` (module `Borealis range family`, 22 tests). `eui-range-test.gts` updated (below).
- `packages/core/docs/forms/form-controls/range/index.md`: generated API section only.

## API / default changes (latest-only)

- **Legacy classes removed:** `euiRangeWrapper--fullWidth/--compressed`, `euiRange--hasInput`, `euiRangeSlider--hasTicks/--hasFocus/--hasRange/--compressed`, `euiRangeThumb--hasTicks`, `euiRangeTrack--disabled/--hasTicks/--hasLevels`, `euiRangeTicks--compressed`, `euiRangeTick--selected/--isCustom`, `euiRangeLevels--hasTicks/--compressed`, `euiRangeLevel--{color}`, `euiRangeHighlight--hasTicks/--compressed`, `euiRangeHighlight__progress--hasFocus`, `euiRangeTooltip--compressed`, `euiRangeTooltip__value--left/--right/--hasTicks`, `euiRangeLabel--min/--max/--isDisabled`. Root/part class names (`euiRange`, `euiDualRange`, `euiRangeWrapper`, `euiRangeTrack`, `euiRangeSlider`, `euiDualRange__slider`, `euiRangeThumb`, `euiRangeTicks`, `euiRangeTick`, `euiRangeTick__pseudo`, `euiRangeLevels`, `euiRangeLevel`, `euiRangeHighlight(__progress)`, `euiRangeTooltip(__value)`, `euiRangeLabel`, `euiRangeInput(--min|--max)`, `euiRange__horizontalSpacer`, `euiRange__slimHorizontalSpacer`, `euiRangeDraggable(__inner)`) are kept/added as upstream.
- **DOM order follows upstream**: slider, (draggable), thumbs, highlight, tooltip, so upstream's `:focus-visible ~ .euiRangeHighlight` / tooltip scale selectors work. The `@hasFocus` tracked flag is gone (`@hasFocus` on slider/highlight deprecated, no-op).
- **Sizes/colors** (Borealis): wrapper 40px (compressed 32px), form width 400px, track line 6px `lightShade` with `radius.inline`, 16px thumbs (`darkShade` + 2px `emptyShade` border + shadow; primary + 2px outline on focus), highlight `darkShade` (`fullShade` in high contrast), ticks `xs` text with 4×6px marks, track reserves 1em on each side with ticks, tooltip uses the tooltip background, ghost text, `radius.control`, `l` offset with an arrow.
- **EuiRangeThumb**: `role="slider"` and the aria values are on the button itself; the nested `div[role=slider]` is removed. It gets `disabled` when disabled, and is not focusable when `@showInput` is set (upstream). New private `@css`. Element stays `HTMLButtonElement` (EuiColorStops uses it).
- **EuiRange**: the slider is `aria-hidden` and `tabindex=-1` whenever `@showInput` is set (also `"inputWithPopover"`, as upstream; was only for `true`). Thumb color follows the level containing the value (`--euiRangeThumbColor`). `@ticks` get `aria-valuetext` (`"value, (label)"`, new optional `accessibleLabel` on `EuiRangeTick`). The popover passes upstream's `euiRange.sliderScreenReaderInstructions` as `@popoverScreenReaderText` (see unresolved 2).
- **EuiDualRange**: new `@isDraggable` (upstream draggable highlight: `role="slider"`, `aria-valuetext="lower, upper"`, arrows move both values, mouse/touch drag; drag calls `@onChange` with a synthetic `drag` event, upstream passes none) and `@isLoading` (delimited input spinner). The popover class is now upstream's `euiDualRange__popover` (was `euiRange__popover`). The delimited layout gets `@isInvalid`/`@isLoading`; deprecated `@useGroup` is no longer passed, and empty prepend/append side wrappers are not rendered. Inputs get `@ariaLabel`/`@ariaDescribedby`; thumbs omit them in popover mode. **Bug fix:** the non-popover lower thumb handled `click` instead of `keydown` (no keyboard); both thumbs now use native `keydown` (ember-keyboard `onKey` dropped).
- **EuiRangeInput**: upstream auto width (`calc(padding + Nch + 2em + invalid icon)`, follows the value length) and `min-inline-size: base × 3.5`, applied **inline** because EuiFieldNumber has no `@css`. Now forwards `@readOnly` (was dropped) and `@isLoading`; min/max go through FieldNumber's args (native-invalid `aria-invalid` then applies). `@digitTolerance` deprecated/optional.
- **EuiRangeLevels**: `color` accepts any CSS color (inline background) besides the 4 names; `className` per level; `@showRange` adds upstream stripes. Out-of-range levels and off-step ticks now really `assert` in development (the old asserts were `assert(msg, true)`, never firing).
- **EuiRangeHighlight**: with `@levels`, renders upstream's level colors inside the highlight instead of the progress bar. New `@background`, `@levels`, `@trackWidth`.
- **EuiRangeTrack**: measures its own width (ResizeObserver) and yields it (`Blocks.default: [trackWidth]`); used for thumb/tick/level positions (was a one-off `clientWidth` read). The ticks margin hack (`margin-left: Nem`) is replaced by upstream's 1em margins.
- **EuiRangeTooltip**: value blocks are rendered without whitespace between prepend/value/append (upstream renders `20kb`, not `20 kb`).
- Kept Ember behavior: tick sequence includes `max` via a tiny epsilon (upstream only when divisible), tick selection compares `String(value)`, events/handlers and `@onChange` signatures unchanged.

## Legacy test assertions changed (`eui-range-test.gts`)

- `.euiRangeTick--selected` → computed font weight differing from the parent (upstream marks selection with medium weight only).
- Tick `style` `left:` → `inset-inline-start:` (logical positions).
- `euiRangeSlider--hasRange` / `euiRangeLevel--danger` → the two levels have different computed colors; with levels the highlight shows level spans, not `__progress` (upstream), so the test asserts the levels in both the track and the highlight.
- `euiRange--hasInput` → the input is inside `.euiRangeWrapper.euiRange`.
- Thumb `[role="slider"]` child → role on the thumb button itself, no nested slider.

## Checks (2026-10-12, this worktree)

Node 22.22.1, Chromium 130 via the scratchpad shim, `CI=true`, binaries run directly. Mid-task the shared `node_modules` lost `@rollup/rollup-linux-arm64-gnu` (it now has only the darwin binary); builds ran with `NODE_PATH=<scratchpad>/linux-natives/node_modules` as a fallback, without touching `node_modules`.

- Core tests (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **922 / 922 pass** (900 base + 22 new). Earlier full runs: one hit a 120s browser timeout in an accordion test (load); one had 4 failures in the new file from Chrome's session-dependent `:focus-visible` heuristic. Those assertions now read the `:focus-visible` rules from the CSSOM.
- Filtered `range` 44/44, `color` 92/92 (EuiColorPicker/EuiColorStops use EuiRange, EuiRangeWrapper and EuiRangeThumb).
- `node --test scripts/eui-upstream-parity.test.mjs`: **234 / 234**.
- `node scripts/generate-eui-styles.mjs --check`: "Stale generated artifact" (expected in a worktree: path comments). Regenerate in the main checkout.
- `ember-tsc --noEmit`: pass. ESLint on all changed sources/tests: pass.
- `node scripts/generate-api-docs.mjs --check`: the range page is current; it flags `docs/display/list-group/index.md` (`@externalIconClass` → `@externalIconCss`), which is pre-existing drift from the base, not regenerated here.

## What the new tests cover

Wrapper/track/slider geometry and colors, native webkit thumb rules (read from the CSSOM: Chrome exposes no computed style for vendor pseudo-elements), focus-visible rules; compressed/fullWidth/disabled; labels incl. RTL; ticks (thumb-aligned centers, marks, selected, click, titles), custom ticks (long label shift, `__pseudo`, `aria-valuetext`), RTL ticks and compressed spacing; named/custom levels, positions, stripes, levels in the highlight; highlight geometry and RTL mirroring; tooltip colors/sides/positions/blocks; showInput sizing, spacers, invalid width, aria-hidden slider; inputWithPopover spinner/read-only/popover; native slider keyboard/aria; reactive args without element replacement; dual range thumbs (positions, colors, focus ring, aria), keyboard bounds/Tab, track click; draggable (styles, aria, keyboard, mouse drag and release); dual inputs and the delimited popover; level thumb colors and disabled thumbs; standalone thumb `@css`; nearest-provider light/dark, island, sibling isolation and JS-object overrides (`size.xxl`, `colors.LIGHT.darkShade/lightShade`); high contrast (thumb, highlight, ticks); RTL dual thumbs.

## Unresolved / for the coordinator

1. **EuiFieldNumber needs `@css`** (forms family) so EuiRangeInput can compose `euiRangeInputStyles` instead of the inline `min-inline-size`/width. The result is identical today.
2. **EuiInputPopover does not forward `@popoverScreenReaderText`** to EuiPopover (overlays family). The range components already pass it.
3. **EuiFormControlLayoutDelimited has no `@isPrependProvided`/`@isAppendProvided`**, so EuiDualRange branches into four invocations to avoid empty side wrappers. Adding the args would let it collapse to one.
4. **EuiColorStops** (unmigrated) now gets the upstream thumb/wrapper styles; its thumbs inherit `pointer-events: none` from `euiRangeThumb`. Upstream color stop thumbs override this with their own styles. Pass them through the new `EuiRangeThumb @css` when color stops migrate. Its own `.euiRangeTrack`/`.euiRangeHighlight` markup is unstyled now.
5. RTL ticks use upstream's physical `translateX(-50%)` with logical insets, so in RTL they sit half a label width off center. This matches upstream and is documented in a test.
6. Cleanup: `utils/css-mappings/eui-range-{highlight,input,levels}.ts` and `helpers/get-range-tick.ts` are no longer used by components (css-mappings registry still imports them).
7. Firefox `::-moz-range-*` rules are present (factory output) but untested (Chromium only).

## Next step

Root: merge, union the generator/parity entries (including the `hex_to_rgb` shim line), regenerate in the main checkout, rerun core, then update the range docs demos.
