# Color picker family migration handoff

Family: EuiColorPicker, EuiColorPickerSwatch, EuiSaturation, EuiHue, EuiColorStops (+ private thumb), EuiColorPaletteDisplay, EuiColorPalettePicker. Branch `eui-wave/color-picker`. Target EUI 123.1.0 / Borealis 8.1.0.

Status: **Migrated**. The full core suite passes in this worktree (932/932, Chromium 130), along with upstream parity (229/229), types and lint.

## Upstream audit

- `components/color_picker/` in 123.1.0 has style modules for the picker, swatch, hue, saturation and palette display. They extract cleanly.
- **EuiColorStops no longer exists upstream.** It was removed in EUI 89.0.0. The last version that ships it is 88.5.4, which was checked from the npm tarball: 89.0.0 has no `color_stops` directory. Its Emotion styles are hand-ported in `utils/eui/color-picker.ts` (see below).
- EuiColorPalettePicker is built on EuiSuperSelect, which is already migrated. It is used as-is; only the item display was ported.

## Files

- **Components:**
  - `eui-color-picker.gts`, `eui-color-picker-swatch.gts`, `eui-saturation.gts`, `eui-hue.gts`.
  - `eui-color-stops.gts`, `eui-color-stops/thumb.gts`.
  - `eui-color-palette-display.gts`, which is now a Glimmer class (it was template-only), and `eui-color-palette-picker.gts`.
  - All style getters are `@cached`. Factories are only used through `useEuiBorealisStyles`.
- `packages/core/src/utils/eui/color-picker.ts` (new, upstream license header). It holds:
  - The hand port of EUI 88.5.4 `color_stops.styles.js` and `color_stop_thumb.styles.js`, rebuilt on the 123.1.0 range factories (`euiRangeVariables`, `euiRangeThumbStyle`, `euiRangeThumbFocus`).
  - `euiCustomControl` is dropped from the add target, because the declarations that follow it override everything it sets.
  - `darken` and `brighten` are re-implemented with chroma, exactly as upstream `manipulation.js` does.
  - The scoped resets: `button`, `ul`, `input` and `*` box sizing.
- `scripts/generate-eui-styles.mjs`: a `// color picker` block. The generator now extracts 258 factories.
  - `euiColorPickerStyles`, `euiColorPickerSwatchStyles`, `euiHueStyles`, `euiSaturationStyles`, `euiColorPaletteDisplayStyles` and `euiColorPaletteDisplayFixed__bleedArea` (static).
  - The range pieces EuiColorStops composes: from `range.styles.js`, `euiRangeVariables`, `euiRangeThumbStyle` and `euiRangeThumbFocus`; plus `euiRangeWrapperStyles`, `euiRangeTrackStyles`, `euiRangeHighlightStyles`, `euiRangeHighlightProgressStyles` and `euiRangeThumbStyles`.
  - **Adapter change:** the `services/index.js` shim also re-exports `./color/hex_to_rgb`, because `range.styles.js` imports `hexToRgb` from the services barrel. This is a pure color helper, not a React workaround.
  - `styles.generated.ts` and `upstream-sources.json` were regenerated. The worktree path comments were normalized back to `node_modules/…`. A fresh regenerate plus normalize is byte-identical to the committed files.
- `scripts/eui-upstream-parity.test.mjs`:
  - The 13 factories join the 12-configuration matrix.
  - A static `deepEqual` test covers the bleed area.
  - A hand-port test bundles `color-picker.ts` and checks, in all 12 configurations, that its add target, track, focus ring, popover and form width come from the upstream 123.1.0 range variables, `euiRangeThumbStyle`/`euiRangeThumbFocus` and the picker width. There is no upstream 123 color stops module to `deepEqual` against.
- **Tests:**
  - New `tests/integration/components/eui-color-picker-family-test.gts` (module `Borealis color picker family`, 18 tests).
  - Updated `eui-color-palette-test.gts` and `eui-color-stops-test.gts` (below).
- **API docs** regenerated: `docs/forms/color-picker`, `docs/forms/color-palette-picker`.

## API and default changes (latest-only)

### EuiColorPicker

- **Field:**
  - The field is now upstream's: an `EuiFormControlLayout` around a `controlOnly` EuiFieldText (`input.euiColorPicker__input`, `data-test-subj="euiColorPickerAnchor"`).
  - The layout carries upstream's `isDropdown` arrow, which is new and hidden while disabled or read-only, plus the clear button, the invalid icon, prepend/append and the keydown handler. The extra wrapper `<div>` is gone.
- **Swatch icon:**
  - It now takes the chosen color, with the swatch stroke in `borderBaseFormsColorSwatch`. The empty `stopSlash` icon is `textSubdued`.
  - EuiFormControlLayout's `@icon` only accepts a type, so this goes through the layout's `@css`: a rule on the left icon group reading `--euiColorPickerIconColor`, set inline on the layout, plus upstream `euiColorPicker__swatchInputIcon`.
  - Before, the color was inherited from a wrapper `color`, which would also have tinted the arrow.
- **a11y (upstream):**
  - The input's `aria-label` is "Select a color" only without `@id`. With `@id`, it is labelled by its form row.
  - The open/close hints moved from `aria-label` to `aria-describedby`, pointing at screen-reader-only spans.
  - Composite adds a `p[aria-live=polite][aria-atomic]` reading "Selected color: #HEX".
- **Popover/inline root:**
  - Upstream `euiColorPicker`: 152px wide (5 × `size.l` + 4 × `size.s`), a flex column with an 8px gap.
  - The `EuiSpacer`s between parts were removed.
  - Removed classes: `euiColorPicker__popoverPanel--pickerOnly`, `euiColorPicker__input--inGroup`, and `euiColorPicker__swatch-item` on the swatch `li`.
- **Secondary input:**
  - Compressed only inside the popover. Inline display follows `@compressed`, as upstream.
  - Its form row is no longer `rowCompressed`.
- **Alpha:**
  - The `.euiColorPicker__alphaRange` class moved from the range's inputs to a wrapper div that carries upstream's alpha styles. EuiRange puts `...attributes` on its inputs, not its root.
  - It now has upstream's `%` append (`<:append><EuiFormLabel>%</EuiFormLabel>`).
  - `data-test-subj`/`aria-label` stay on the range.

### EuiColorPickerSwatch

- Upstream styles: 24px, `radius.inline`, a 1px swatch border plus an inset highlight (a real border in high contrast), pointer cursor, and a centered focus outline.
- A scoped button reset is composed first.
- **Not ported:** the default `showToolTip` tooltip. See unresolved #1.

### EuiSaturation

- Upstream styles: a square (`aspect-ratio`), radius control, both gradients, the 12px round indicator with the light/dark double ring, the focus-within primary ring, and the high-contrast `::after` border.
- **a11y:**
  - The indicator's `aria-label` is "Select a color" (token `euiSaturation.ariaLabel`). It was the hex.
  - `aria-roledescription` uses token `euiSaturation.roleDescription`. It was the label token.
  - The extra hidden `aria-live` hex span was removed; the picker announces the color.
- The indicator sits in a positioned span (upstream's tooltip anchor). It keeps physical `left/top` in RTL so it matches the physical gradients. Upstream uses logical `inset-inline-start`.
- `@hex` is documented as display-only (upstream tooltip).

### EuiHue

- Upstream styles: a 12px rainbow track, a 24px anchor bleeding 1px on each side, and the upstream thumb, focus and high-contrast styles.
- New upstream `aria-roledescription` "Hue slider" and `aria-valuetext` "Hue N°".
- The hue's `aria-live` hex was removed; the picker announces the color.
- `@hue={{0}}` is no longer replaced by the default 1.

### EuiColorStops

- **Root:** keeps the `euiRangeWrapper euiColorStops` classes, with the upstream range wrapper height (40/32px), form width or full width, and the color stops states.
- **Rendering:** the track (`euiRangeTrack euiColorStops__track`, a striped `::after`), highlight and progress are rendered directly, without EuiRangeWrapper/EuiRangeTrack/EuiRangeHighlight/EuiRangeThumb. This keeps one Emotion class per element and makes the family independent of the in-flight range port.
- **Removed classes:** `euiColorStops-isDragging/-isDisabled/-isReadOnly`, `euiColorStops__addContainer-isDisabled`, `euiRangeTrack--disabled`, `euiRangeHighlight--compressed`, `euiColorStopPopover-hasFocus`. They are now computed styles.
- **Behavior fix:** `@stopType="fixed"` now holds each color until the next stop, as upstream `fixedStop` does. It used to blend like a gradient.
- **Gradient start:** the area before the first stop is `transparent`, so the striped track shows, as upstream. It was `currentColor`.

### EuiColorStopThumb (private)

- It renders upstream EuiRangeThumb markup: a single `button.euiRangeThumb.euiColorStopThumb[role=slider]` with `aria-value*`, `aria-disabled` and native `disabled`. Before, it was a button wrapping a second `div[role=slider]`.
- The anchor class is upstream's `euiColorStopThumbPopover__anchor` (was `euiColorStopPopover__anchor`). It draws the white disc under the thumb.
- The popover root styles come through EuiPopover's `@rootCss`.
- The edit form is the picker width (152px).

### EuiColorPaletteDisplay

- Upstream styles: flex, overflow hidden, sizes xs/s/m at 4/8/16px with matching radius, the `::after` swatch border (`border.thin` in high contrast), and `preventForcedColors`. The fixed bleed area comes from upstream.
- Removed: the `euiColorPaletteDisplay--size*` classes.
- The screen-reader title is wrapped in a `span`, as upstream.

### EuiColorPalettePicker

- Items are upstream's: an EuiFlexGroup holding the EuiText `xs` title (`aria-hidden`, `.euiColorPalettePicker__itemTitle`), then an EuiSpacer `xs`, then the palette.
- **Default change:** there are no option dividers, as in upstream 123. It passed `@hasDividers={{true}}` before.
- New `@disabled`/`@readOnly` are passed to the super select.
- **Not ported:** a per-palette `append` and the picker's prepend/append (see unresolved #4).

## Existing tests changed

- `eui-color-palette-test.gts`: `hasClass('euiColorPaletteDisplay--sizeSmall'/'--sizeMedium')` are removed legacy modifiers. They are replaced by `doesNotHaveClass` and a computed height of 8px/16px.
- `eui-color-stops-test.gts` "read-only and disabled": `euiColorStops-isReadOnly`, `__addContainer-isDisabled` and `euiColorStops-isDisabled` are removed state classes. They are replaced by behavior: clicking the track adds no stop when read-only or disabled, the disabled root keeps `tabindex=-1`, and its thumbs are disabled.
- Every other assertion in `eui-color-picker-test.gts` (7 tests), `eui-color-stops-test.gts` and `eui-color-palette-test.gts` is unchanged and passes.

## New coverage (`Borealis color picker family`, 18 tests)

- **Field:**
  - Measured 40/32px height, 36/32px icon affordances, inset border, radius, 400px form width and full width.
  - The swatch icon in the chosen color, the stroke color, and an arrow that keeps its own color.
  - Empty state: `stopSlash` in subdued, and the "Transparent" placeholder.
- **States:**
  - Invalid: `aria-invalid`, warning icon, outline, 60px affordance.
  - Disabled: no arrow, disabled background, the swatch keeps its color.
  - Read-only: no arrow, never opens.
  - Clearable: label, 60px, clear output and placeholder.
  - a11y: `aria-label` fallback vs `@id`, `aria-describedby` switching between the close and open hints, and the popover `aria-label`.
- **Prepend/append:** group class, side nodes, yielded class and input id, borderless in-group input, no empty append.
- **Popover:**
  - Root 152px flex column with gap, no spacers.
  - Saturation: square, radius, hue background, both gradients, and indicator size, rings, reset, aria and position from s/v.
  - Hue: height, radius, gradient, appearance, anchor bleed, aria.
  - Swatches: flex/wrap/gap/list reset, 24px, color, radius, border, aria, 8px spacing.
  - The "Selected color" live region.
- **Keyboard:**
  - ArrowDown opens, then focuses the saturation square. Arrows change the color, and the field follows. Enter confirms and returns focus. Enter toggles.
  - Swatch mode: ArrowDown focuses the first swatch, with its focus outline (width, color, offset). Clicking picks it, closes and refocuses the field.
- **Inline:**
  - Top/bottom secondary input order, and compressed following `@display`.
  - Alpha: input value, aria, `%`; 25 → `211, 96, 134, 0.25`; 100 drops the alpha.
  - Hue keeps the rgb format. Clear empties the color. Invalid text reports invalid.
- **Custom button, secondaryInput mode and standalone pieces:** the inline-block anchor, the error text, hue 0, the default saturation color and a transparent swatch.
- **Reactive args, without element replacement:** picker compressed/invalid/color/disabled (including the icon color), palette size, color stops compressed.
- **Color stops:**
  - Wrapper flex/height/width/full width, announcement, striped `::after` (track color, 4px).
  - Highlight z-index/height, the gradient's transparent start, the add target (opacity, size, colors).
  - Thumb markup/aria/size/radius/stop color/border/cursor, the popover wrapper and its disc, thumb order and start position.
  - Fixed hard edges and stepped (4 unique colors).
  - Keyboard select/move/remove/add, focused stop z-index, the popover form (152px), the open-thumb focus outline, an inline picker, an invalid empty stop with its error, and trash remove.
  - Read-only (no add/move, no trash, secondary input only) and disabled (`tabindex`, announcement, 0.5 track opacity, disabled thumbs).
- **Palette display:** xs/s/m heights and radius, flex/overflow, the `::after` border, the bleed area (absolute/flex/−1px), blocks, the screen-reader title, and gradient `aria-hidden`.
- **Palette picker:** the selected display, title selection display, no dividers, EuiText xs title, flex group, palette below the title, accessible name, text options, choosing an option, disabled.
- **Providers:**
  - Nearest-provider light/dark with no replacement, the child inheriting, sibling isolation.
  - JS-object overrides: `size.l` drives the swatch and picker width (192px), `radius.control` reaches the saturation, and the nearest override wins.
  - Portaled popover content keeps the dark tokens.
- **RTL:**
  - The swatch icon and padding are on the right, the arrow on the left.
  - Color stops and the saturation indicator stay physical.
- **High contrast (preferred):** swatch `border.thin` and no inset, hue border, saturation `::after` border, indicator thick border with `plainLight` background, palette `::after`. Standard contrast is isolated.

## Checks (2026-10-12, this worktree, Node 22, Chromium 130 via the scratchpad shim, `CI=true`; pnpm unavailable, binaries run directly)

- Full core suite (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **932 tests, 932 pass, 0 fail**.
- Filtered `/color|super select|range/i`: 139/139.
- `node --test scripts/eui-upstream-parity.test.mjs`: **229/229**.
- `node scripts/generate-eui-styles.mjs --check`: "Stale generated artifact: styles.generated.ts". This is the expected worktree failure (symlinked `node_modules` path comments). A regenerate plus normalize is byte-identical to the committed files.
- `ember-tsc --noEmit`: pass. ESLint on all changed sources and tests: pass.
- `node scripts/generate-api-docs.mjs --check`: pass, after regenerating 2 pages.
- Not run (coordinator): rollup core build, site build/acceptance, showcase/visual checks.

## Unresolved / for the coordinator

1. **Tooltips not ported.** Upstream wraps swatches (`showToolTip`, default true), the hue thumb and the saturation indicator in EuiToolTip showing the color. EuiToolTip has no anchor `@css`/`anchorProps.css`. Upstream styles its anchor: `display: inline-flex` for swatches, and size/margins for hue and saturation. The anchor geometry is reproduced here with plain elements. Adding an anchor `@css` to EuiToolTip (overlays family) would let the tooltips be ported.
2. **EuiFormControlLayout `@icon` takes only a type.** Upstream passes `{ type, side, color, css }`. The picker colors its icon through the layout's private `@css` and a CSS variable. An `@iconColor`/`@iconCss` on the layout (form-controls family) would remove that descendant rule.
3. **Range overlap with the range family:**
   - Merge conflicts: the `// color picker` generator/parity blocks add `components/form/range/{range,range_wrapper,range_track,range_highlight,range_thumb}.styles.js` keys. Union their names with the range family's entries; duplicate object keys silently override. The range agent may also add the same `hex_to_rgb` shim line.
   - What this port leaves to the range family: EuiColorStops no longer renders EuiRangeWrapper/Track/Highlight/Thumb. The color picker's alpha slider still uses EuiRange (`@compressed @showInput` + `<:append>`), so its look follows the range port.
   - What the range family can add: once EuiRangeThumb/EuiRangeTrack have `@css`, the stops could reuse them.
4. **EuiColorPalettePicker:** upstream's prepend/append and the per-palette `append` are not ported. Glimmer cannot conditionally forward named blocks without duplicating the template.
5. **Saturation RTL:** upstream positions the indicator with logical `inset-inline-start` while the gradients are physical. That looks inconsistent upstream; physical `left` is kept here.
6. **EuiColorStops has no upstream after 88.5.4.** It is kept as an Ember extension on hand-ported styles. Decide whether to deprecate it, as with EuiNotificationEvent.
7. **Icons:** upstream uses `chevronSingleDown` for the dropdown arrow. The layout still draws `arrowDown` (form-controls #1).

## Next step

Coordinator: merge, union the generator/parity entries with the range family's, regenerate in the main checkout, and run parity and the full suite. Then do a visual pass on `/docs/forms/color-picker`, `color-stops` and `color-palette-*` (popover column, swatches, stops track and thumbs).
