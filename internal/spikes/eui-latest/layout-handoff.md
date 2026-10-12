# Layout/loading migration handoff

## Scope

Ports `EuiSpacer`, `EuiHorizontalRule`, and `EuiLoadingSpinner` to extracted **EUI 123.1.0** factories and real **Borealis 8.1.0** context. All three consume the nearest Ember provider automatically and use owner defaults outside a provider.

Owned source files are the three component files; rendering coverage lives in `eui-borealis-layout-test.gts` (seven tests), with existing spacer/rule/loading tests updated to verify current dimensions/defaults.

## Latest-only decisions

User requested latest styles without legacy compatibility. Components use roots `euiBorealisSpacer`, `euiBorealisHorizontalRule`, and `euiBorealisLoadingSpinner`. Legacy classes/variant mappings and selector specificity workarounds are removed. Components directly compose upstream serialized styles, with small local resets replacing React's assumed global reset.

- All components set `box-sizing: border-box` locally.
- HorizontalRule sets `margin: 0` before native logical width/margin styles. Default margin is latest upstream `m=16px`. Explicit Borealis margins: `xs=8px`, `s=12px`, `m=16px`, `l=24px`, `xl=32px`, `xxl=40px`; `none=0`.
- Spacer uses upstream `l=24px` default. Sizes use native tokens/logical block size.
- Spinner defaults to `m`, supports upstream `xxl`, and accepts `@color={{hash border="..." highlight="..."}}`. Defaults `role="progressbar"`, `aria-label="Loading"`; forwarded native attributes override role/label and support decorative `aria-hidden`. English label is overridable; framework localization is a later pass.
- Spinner baseline `animation: none` precedes upstream animation guarded by `prefers-reduced-motion: no-preference`.
- Native contrast mode reaches upstream factories. Forced contrast overrides custom spinner colors, sets forced-color-adjust, and draws rules using borders.

## Coverage and evidence

Seven rendering tests cover all sizes/dimensions/border widths; rule widths/margins/native semantics; RTL centering; vertical writing mode; reactive sizes/native tokens/color modes; nesting/sibling isolation; spinner labels/roles/custom colors/attributes; preferred/forced contrast; reduced-motion guards/keyframes; teardown.

Chromium at device scale 1 quantizes upstream 1.5px borders to computed 1px. Tests assert rendered 1px and separately verify serialized 1.5px. Spinner highlight derives from `colors.borderStrongPrimary`; use mode-specific `colors.DARK.borderStrongPrimary` overrides for dark mode. Installed-upstream `buildTheme/getComputed` probe confirmed DARK overrides propagate to spinner highlight; flat overrides lose to mode-specific values.

Latest-only simplification requires a new root-coordinated full suite/type/build pass before recording final results. Synthetic legacy CSS test removed as requested.

## Next checks

- Root: full core suite/type/build; record counts in component tracker.
- Browser: emulate reduced motion and forced colors in migration showcase.
- Review larger-spinner high-contrast calculation (`mathWithUnits(euiTheme.border.thick, ...)`) through parity checks rather than patching extracted source.
- Later accessibility/localization pass: agree translated default loading label strategy.
