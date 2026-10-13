# Theming handoff (branch `eui-wave/theming`)

Shared theme plumbing work: system high contrast/color mode, theme CSS
variables, and a public theming API with theme-function `@css`.

## Part 1: high contrast like upstream EuiProvider/EuiThemeProvider

- `utils/emotion/system.ts` (new): `EuiSystemPreferences`, tracked
  `matchMedia` watchers for `(prefers-color-scheme: dark)`,
  `(forced-colors: active)` and `(prefers-contrast: more)` (upstream
  `EuiSystemDefaultsProvider` + `useWindowMediaMatcher`). SSR/test safe;
  `destroy()` removes the listeners.
- `utils/emotion/context.ts`: `@highContrastMode` accepts `true`
  (→ `'preferred'`), `false` (overrides parent/system), `'preferred'`,
  `'forced'`; undefined inherits. A `'forced'` parent supersedes the own
  contrast **and** color mode (upstream `getColorMode(_, parent, isForced)`).
  `settings` is now public (read-only) so the root can see what the service
  explicitly set.
- `eui-emotion-provider.gts`: a root provider (no parent provider, no
  `@parent`) gets a system parent context: `colorMode`/`highContrastMode`
  come from the `eui-emotion` service when set, else from the OS; OS forced
  colors always win. Upstream checked: `EuiProvider` colorMode **does**
  follow `prefers-color-scheme` when undefined, so ours does too (root
  only). Components without any provider still default to light/false.
  Listeners are created only by root providers and removed in `willDestroy`.
- `services/eui-emotion.ts`: `colorMode`/`highContrastMode` are now
  optional (undefined by default) so roots can follow the OS.
- `utils/eui/theme.ts`: `euiHighContrastModifications` ports upstream
  `useHighContrastModifications` (border tokens → text colors / plain
  dark|light, `border.thin/thick/color`); `resolveBorealisTheme` applies it
  when high contrast is on. Parity test added
  (`scripts/eui-upstream-parity.test.mjs`, upstream hook run with
  `useMemo` stubbed). **Intentional difference:** upstream spreads it over
  the consumer's modifications shallowly (`{...mods, ...hc}`), which drops
  consumer `colors`/`border` overrides in high contrast; we deep-merge, so
  brand colors survive and the HC border tokens still win.
- Existing tests asserted the old (non-upstream) HC border = normal border
  color. Updated the expectations only (to
  `resolveBorealisTheme('light', {}, 'preferred')`) in color-picker,
  combo-box-family, date-pickers, form-controls and super-select-family
  tests (combo box / date pickers belong to other agents: expect a trivial
  conflict at most).
- Site: `theme-manager` `highContrast` (true | undefined = follow OS,
  `?highContrast=true`, localStorage), `BorealisRoot @highContrastMode`,
  header `EuiButtonIcon` toggle (`contrast` icon, `aria-pressed`) next to
  the light/dark switcher, inside a dark nested provider since the header
  is always dark.

## Part 2: CSS variables

- `utils/eui/css-variables.ts` (new): `euiThemeCssVariables(theme)`
  (190 vars, memoized via `memoizedStyles`), `euiCssVariableName(path)`,
  `euiCssVar(path, fallback?)`. Naming: `--eui-` + token path in kebab
  case, `colors` → `color` (`colors.textSubdued` →
  `--eui-color-text-subdued`). Published: all string colors +
  `colors.severity` (not `vis`), `size.*`, `border.*`, font families,
  feature settings, weights, `--eui-font-size-*`/`--eui-line-height-*`
  (upstream `euiFontSize`), `focus.color/width`, `animation.*`.
- Upstream 123.1.0 has no token variables (only component vars like
  `--euiFixedHeadersOffset` via `useEuiThemeCSSVariables`), so the names
  are ours.
- Root provider injects `:root { … }` from its own `eui-vars` Emotion
  cache (also with `@globalStyles={{false}}`; the existing "globalStyles
  false injects nothing" test checks `eui-global`, which stays empty),
  re-injected on theme change, flushed on teardown. Nested providers whose
  colorMode/contrast differ from the parent's, or with own non-empty
  `@borealisOverrides`, add the variables to their wrapper's color class.
  Limits: `@wrapper={{false}}` nested providers and portaled content read
  the root values.

## Part 3: public API and theme-function `@css`

- `src/theming.ts` (new, `@ember-eui/core/theming` via the existing
  `./*` export, no package.json change): `getEuiThemeContext`,
  `useEuiBorealisStyles`, `euiClass`, `memoizedStyles`, `resolveEuiCss`,
  `euiCssVar`, `euiCssVariableName`, `euiThemeCssVariables`,
  `resolveBorealisTheme`, `EUI_UPSTREAM_VERSIONS`, `EuiThemeContext`, and
  types `EuiCss`, `EuiCssFunction`, `EuiCssVariables`,
  `EuiThemeStyleContext` (= `EuiBorealisContext`),
  `EuiBorealisOverrides`, `EuiHighContrastModeArg`, `EuiColorMode`…
- `utils/eui/styles.ts`: `EuiCss = CSSInterpolation | EuiCssFunction |
  readonly EuiCss[]`. `euiClass` resolves functions (top level or nested
  in arrays) against `context.upstream`, memoized per resolved theme and
  function identity (`memoizedStyles`); it reads `context.upstream` only
  when a function is present. No per-component edits beyond types:
  `EuiPopover @css/@rootCss/@panelCss` and `EuiListGroupItem` extra
  action `css` were typed `CSSInterpolation` (now `EuiCss`), plus
  `EuiBreadcrumbs`' popover css getters.
- Every `EuiCss` arg reaches `euiClass` (audited the `args.*Css` uses).

## Docs

- New top-level guide `docs/theming.md` ("Theming your own components",
  order 3) + `docs/theming-demo/demo1-4.md` (style factory component,
  `@css` forms, plain CSS variables with nested dark/HC, brand overrides).
  **The site nav gains one top-level page** (site nav count tests, if
  any, need +1). Demos are placed before the page's only `##` heading
  ("Reference: CSS variables", the full variable tables). Not built here:
  please check the `docs/theming-demo` folder is picked up at the docs
  root like `<page>-demo` folders in packages.
- `docs/migrating-to-borealis.md`: colorMode/high contrast/CSS variables
  bullets, `@css` theme functions, two Changed-defaults rows.
- `generate-api-docs`: popover page now shows `EuiCss`.

## Checks (worktree)

- Core suite: **1377/1377** (14 new in `eui-theming-test.gts`).
- `ember-tsc --noEmit`: clean. eslint on all changed core files + site
  ts/gts: clean.
- `node --test scripts/eui-upstream-parity.test.mjs`: 350/350 (1 new).
- `node scripts/generate-api-docs.mjs`: updated 1 of 110 pages.
- Not run (per brief): site build, sync-injected, companion suites.

## Behavior changes to note

- Root providers without `@colorMode` now follow the OS dark preference
  (was always light). The site passes `@colorMode` explicitly. Apps that
  want light regardless must pass `@colorMode="light"` (or set the
  service's `colorMode`).
- High contrast now changes border tokens (upstream behavior).
