# EuiButtonEmpty / EuiButtonIcon migration handoff

Status: **Migrated**. The full core suite passes in Chromium 130 (620/620), along with upstream parity, types, lint and the API docs check.

## Files

- `packages/core/src/components/eui-button-empty.gts`: now a Glimmer class. It renders the root through `(element)`, like EuiButton, and uses `euiButtonEmptyStyles`, `euiButtonDisplaysColors.empty`, `euiButtonDisplayContentStyles` and `euiFocusRing`.
- `packages/core/src/components/eui-button-icon.gts`: now a Glimmer class using `euiButtonIconStyles`, `euiButtonDisplaysColors[display]`, `euiFocusRing` and a small local `ember-modifier` for the a11y checks.
- `packages/core/tests/integration/components/eui-button-empty-icon-test.gts`: new, 11 computed-style tests.
- Existing tests whose legacy-class assertions broke were replaced with computed-style or semantic checks. Nothing unrelated was weakened.
  - `eui-button-icon-test.gts`: the default button now has no `aria-pressed`.
  - `eui-button-test.gts` (the two EuiButtonEmpty cases at the end).
  - `eui-header-test.gts` and `eui-filter-group-test.gts`: these asserted `euiButtonEmpty--primary` / `--text`. They now compare the computed color to the Borealis `textColorPrimary` / `textColorText` tokens.
- `packages/core/docs/navigation/button/index.md`: only the API sections were regenerated.
- Not touched:
  - `eui-button.gts`, `eui-button-content.gts`, `eui-loading-spinner.gts`, providers and shared utils, the generator and generated files, the showcase.
  - `utils/css-mappings/eui-button-{empty,icon}.ts`: the mapping registry `css-mappings/index.ts` still imports them. The components no longer use them, so the coordinator can delete them together with their registry entries.

## API and default changes (latest-only)

- **Root classes kept:** `euiButtonEmpty` and `euiButtonIcon`. Wrapper classes kept: `euiButtonEmpty__content`, `euiButtonEmpty__text`, `euiButtonContent__icon/__spinner` and `euiButtonIcon__icon`. Upstream flush styles target `.euiButtonEmpty__content` and `.euiButtonEmpty__text`.
- **Legacy classes removed:** every `--color`/`--size`/`--flush*`/`--display` modifier, plus `euiButtonEmpty-isDisabled` and `euiButtonIcon-isDisabled`.
- **Colors** (EuiButton's decisions):
  - Adds `accentSecondary`, `neutral` and `risk`. EuiButtonEmpty also gains `accent`.
  - `ghost` is still accepted and maps to the themed `text` tokens; upstream removed it.
  - Unknown names fall back to `primary`.
  - The `@color` type is now `string`; it was the keys of the css-mapping.
- **Sizes:**
  - EuiButtonEmpty: xs/s/m are 24/32/40px tall, with 6/8/12px inline padding. Text padding is 2/4/4px. The xs font scale is smaller.
  - EuiButtonIcon: xs/s/m are 24/32/40px squares with an 8px radius. The default is still `euiButtonIcon.size` config, then `xs`. `@size` and `@display` types are now literal unions.
- **Flush:** `padding-inline: 0`, and the content gap grows to 8px. `left` adds `margin-inline-end: 8px` and `right` adds `margin-inline-start: 8px`; these are logical, so they flip in RTL. Hover/active get no background and underline the text, as upstream.
- **`@isSelected`:** omitted means no `aria-pressed`, `true`/`false` emit `"true"`/`"false"`.
  - **Behavior change for EuiButtonIcon:** it used to always emit `aria-pressed="false"`, which announced every icon button as a toggle. This now matches upstream and EuiButton.
  - Like upstream, `aria-pressed` is only set on `<button>`, never on links. EuiButton also sets it on links; consider aligning EuiButton.
- **Disabled and loading:**
  - `@disabled` now also turns an `@href` link into a disabled `<button>` on both components. It was previously ignored for links, the same fix EuiButton received.
  - Disabled/loading links drop `href` and `target`.
  - Loading adds `aria-busy="true"`, as EuiButton does.
- **New EuiButtonIcon `@isLoading`** (upstream prop): with `@iconType`, it replaces the icon with an `EuiLoadingSpinner`. The spinner gets the upstream `{ border: 'currentcolor' }` color and the icon size (`original` falls back to the spinner default). It also disables the button.
- **aria-label requirement** (EuiButtonIcon):
  - Ember cannot read `...attributes` as args, so a local modifier checks the rendered element on install.
  - It logs upstream's `console.warn` when there's no `aria-label`/`aria-labelledby` and the button isn't `aria-hidden="true"`.
  - For `aria-hidden="true"`, it sets `tabindex="-1"` unless the caller passed a `tabindex`, matching upstream.
  - It only runs on install and when the element is replaced (button↔link). Attribute changes after that are not re-checked.
- **Scoped reset** (no React global reset):
  - Box sizing, no border, margin or padding, and `background: none`. Without it, Chromium's UA button face shows through on empty buttons.
  - EuiButtonEmpty also gets the Borealis font family and no text decoration.
  - Focus ring: upstream `euiFocusRing` on `:focus`, scoped locally as in EuiButton.
- **Icon sizing:** EuiIcon is not migrated, so sizes are scoped locally: s/m/l/xl/xxl are 12/16/24/32/40px, with `fill: currentColor`. The `ICON_SIZES` map is duplicated from EuiButton (see below).
- **Not ported:** upstream React-only props: `hasAriaDisabled`, `buttonRef`, structured `contentProps`/`textProps`, `textProps={false}`, `rel`/`getSecureRelForTarget`, and button-group context. `...attributes` remains the native escape hatch.

## Checks run (2026-10-12, in this worktree)

Environment: Node 22.22.1. pnpm is unavailable, so binaries were run directly. Chromium 130 came from the scratchpad `bin` with `CI=true`.

- Core tests (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **620 tests, 620 pass, 0 fail**, including the 11 new tests.
  - After that run, only doc comments and the inlined `@size`/`@display` type aliases changed. There was no runtime change, and types/lint were re-run.
- `node --test scripts/eui-upstream-parity.test.mjs`: **29/29 pass**.
- `ember-tsc --noEmit`: pass. ESLint on both components and the five touched test files: pass. Prettier was run on the new files.
- `node scripts/generate-api-docs.mjs --check`: pass, after regenerating.
- `node scripts/generate-eui-styles.mjs --check`: **fails with "Stale generated artifact: styles.generated.ts" on the untouched base commit too** (checked with my changes stashed). It is not caused by this branch, and per the brief I did not touch the generator or the generated file. Coordinator: please confirm it passes in your environment.
- Not run (root): rollup core build, site build/acceptance, showcase/visual checks.

## What the new tests cover

- **EuiButtonEmpty matrix:** 10 colors × 3 sizes. Checks height, padding, text padding/ellipsis, transparent background, no border, radius, weight, Inter font, measured icon size, and color compared to the `textColor*` tokens through an `rgb()` probe.
- **Flush:** left/right/both, the content gap and the class hooks.
- **EuiButtonIcon matrix:** 3 displays × 9 colors × 3 sizes. Checks measured width/height, inline-flex, radius, background/foreground tokens per display, the base-text border, icon size/fill/`aria-hidden`, and that the icon is centered.
- **Defaults and config:** default size, ghost, icon sizes, and config-driven size that updates in place.
- **Disabled/loading:** for links and buttons, including the native `@disabled` alias. Checks cursor, disabled tokens, base disabled surface, no click dispatch, the spinner and its currentColor border, and that modifiers survive element replacement.
- **`aria-pressed`:** reactive undefined/true/false, and never on links.
- **aria-label:** the warning, `aria-labelledby`, and `aria-hidden` tabindex.
- **Native interaction:** click, keyboard and submit, plus the focus ring (color/offset, modality-aware).
- **Reactive args:** color/size/flush/display/iconSide change without replacing the element.
- **Providers:** nearest-provider light/dark, a fixed-light island, sibling isolation, and JS-object overrides. The overrides cover border radius and the mode-specific `colors.LIGHT/DARK.textDanger`, which feeds the button tokens.
- **Contrast and RTL:** preferred high-contrast borders (base/fill bordered, empty not), RTL icon placement, and the logical flush margin.

The ember-qunit container is scaled, so measured sizes divide client rects by the container's scale.

## Unresolved / for the coordinator

1. **Upstream contrast adjustment changes override colors.** For empty and base displays, upstream runs `makeHighContrastColor(text)(background)`. An override token can therefore render differently than written, e.g. a dark `textDanger` on the dark danger background. This is upstream-faithful. Light `accentSecondary` is likewise adjusted (`#046e6b` vs token `#047471`), so the tests skip exact equality for it.
2. **Shared-logic duplication.** The `ICON_SIZES` map, the scoped reset and the content/icon/spinner scoping are duplicated from EuiButton. Suggested refactor once EuiButton is final: a shared `buttonReset(theme)` plus an `iconSizeCSS(size)` helper in a button utility.
3. **`euiButtonIcon.size` config type.** In `services/eui-config.ts` it is typed as `EuiButtonIconSignature['Args']['iconSize']`, which looks wrong: it's an icon size and doesn't allow `'xs'`. The component accepts xs/s/m from config at runtime. Fix it in the service, which I don't own.
4. **Unmigrated callers.** About 35 components now get Borealis button styling (header links, filter buttons, pagination, modal/flyout close, code-block controls, etc.). On legacy docs pages, vendor `.euiButtonEmpty`/`.euiButtonIcon` rules also still apply. Audit visually when those callers migrate. EuiButtonGroup uses EuiButton, not these components.
5. **Not covered here:** hover/active computed styles and forced-colors mode need trusted pointer and emulation browser checks (root).

## Next step

Root: merge, then re-run the full suite with the coordinator's final EuiButton/content/spinner changes. Those wrappers are shared, so check flush gap/padding, the spinner border and icon sizing again. Then run the core build and site checks, and decide on the shared button-utility refactor and on removing the css-mappings.
