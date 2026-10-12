# Icon family migration handoff (EuiIcon, EuiIconTip, EuiToken, EuiAvatar, EuiBeacon, EuiHealth)

Status: **Migrated** (all six). Full core suite 679/679 in Chromium 130, parity 36/36, types, lint and API docs pass. Branch `eui-wave/icon`.

## Files

- `packages/core/src/components/eui-icon.gts`: upstream `euiIconStyles` (sizes, named/custom colors, app two-tone, `fillNegative`, `logoElasticOutline`, loading/loaded). The factory runs once per resolved theme (module `WeakMap` keyed on `context.upstream`), since EuiIcon renders everywhere.
- `eui-avatar.gts`, `eui-beacon.gts`, `eui-health.gts`, `eui-token.gts`: now Glimmer classes on upstream factories (`euiAvatarStyles`, `euiBeaconStyles`, `euiHealthStyles`, hand-ported `euiTokenStyles`).
- `eui-icon-tip.gts`: unchanged. Upstream `icon_tip` has no styles (it is EuiToolTip + EuiIcon `tabIndex=0`, `aria-label` default "Info"); it now picks up the migrated icon. ToolTip itself belongs to another wave.
- `packages/core/src/utils/eui/token.ts` (new): hand port of `token.styles.js` with the upstream license header. Upstream reads its palette from the global `EUI_VIS_COLOR_STORE` (filled by the React provider) through `services/index.js`, which the generator shims, so the factory cannot be extracted. The port reads `euiTheme.colors.vis` instead; Borealis vis colors are identical in light and dark. All helpers (`tint`, `shade`, `isColorDark`, `logicalCSS`, `logicalSizeCSS`, `highContrastModeStyles`, `TOKEN_COLOR_TO_ICON_COLOR_MAP`) come from the extracted upstream sources.
- `scripts/generate-eui-styles.mjs`, `// icon family` block: `euiIconStyles`, `euiAvatarStyles`, `euiBeaconStyles`, `euiHealthStyles`, `TOKEN_MAP`, `TOKEN_COLOR_TO_ICON_COLOR_MAP`, `logicalCSS`, `logicalSizeCSS`, `highContrastModeStyles`, `isColorDark`, `hexToRgb`. **One shared line was edited**: `services/color/manipulation.js` now exports `['transparentize', 'tint', 'shade']` (an object key cannot be duplicated). The generator now extracts 48 factories/helpers, up from 35.
- `styles.generated.ts` and `upstream-sources.json` were regenerated. The worktree-only `../../…/Users/…` source-path comments were normalized back to `node_modules/…` with sed, so the committed file matches a main-checkout run. The other diff to existing code is esbuild `_refN` renumbering.
- `scripts/eui-upstream-parity.test.mjs`: the 4 factories join the 12-configuration matrix. New tests:
  - Static `TOKEN_MAP`/`TOKEN_COLOR_TO_ICON_COLOR_MAP` and color/logical helper parity.
  - Token-port parity: every slot's serialized `styles`, for 3 fills × 2 modes × 3 contrast modes × 2 override sets, with upstream's store set to the theme's vis colors.
- `packages/core/tests/integration/components/eui-icon-family-test.gts`: new, 23 computed-style tests.
- Existing tests updated (legacy-class or legacy-default assertions only):
  - `eui-icon-test.gts`:
    - `euiIcon--medium/--small/--xLarge/--large` were replaced with measured widths.
    - `--danger/--primary/--customColor` were replaced with computed `color`/`fill` against Borealis tokens. The custom color is now a `color` class, not an inline `fill`, and no `style` attribute is set.
    - `--app` was replaced with the computed fills of the base and `.euiIcon__fillSecondary` shapes.
    - Decorative icons: `aria-hidden="true"` became `role="presentation"` with no `aria-hidden`.
    - `role="image"` became `role="img"`.
    - The iconsFromGlob selector no longer uses `.euiIcon--large`.
  - `eui-token-test.gts`: `euiToken--*` and `euiIcon--medium` were replaced with radius, size and background checks. `--euiColorVis5` dark is now its computed background.
  - `eui-health-test.gts`: `euiHealth--textSizeS` and `euiIcon--success` were replaced with text and `data-icon-type` checks; the family test covers the computed values.
  - `eui-avatar-test.gts`: `euiAvatar--m/--user/--xl/--space` and `-isDisabled` were replaced with computed size, radius and cursor.
  - `eui-link-test.gts` and `eui-link-borealis-test.gts` (not my family): both asserted the external icon was `aria-hidden="true"`, which came from the old EuiIcon default. EuiLink passes `role="presentation"`, as upstream does, and latest EuiIcon no longer adds `aria-hidden`. Both now assert `role="presentation"` with no `aria-hidden`/`aria-label`; the size, margin, fill and screen-reader text assertions are unchanged.
- `packages/core/docs/display/{avatar,beacon,health,icons,token}/index.md`: only the generated API sections were regenerated.
- Not touched: `utils/css-mappings/eui-{icon,avatar,health}.ts`, which the mapping registry still imports. `eui-icon.ts` still provides `typeToPathMap`; the others are unused by the components now. `utils/token-map.ts` is no longer used by EuiToken; it may be public, so it was kept. `-private/vis-colors.ts` is still used by the badge css-mapping.

## API and default changes (latest-only)

**EuiIcon**
- Root class `euiIcon` is kept. All `euiIcon--{size,color,app,customColor}` classes are removed.
- Colors:
  - Adds `default`, `neutral`, `accentSecondary` and `risk` (upstream `COLORS`).
  - `text` now maps to `textHeading` and ghost to `textGhost`; both force one tone (`*[fill]` uses currentColor).
  - Custom colors set `color` (with `fill: currentColor`) through an Emotion class. Before, they set an inline `fill`.
  - The SVG `color="<arg>"` attribute is no longer emitted.
- Sizes: s/m/l/xl/xxl are 12/16/24/32/40px through logical `inline-size`/`block-size`. `original` keeps the SVG's own width/height. The `IconSize` type is unchanged (it excludes `original`, which still works at runtime) because button/spinner callers forward it. `SIZES` and `COLORS` are exported with the upstream lists; `COLORS` is now the upstream list.
- **Semantics (upstream 123):**
  - An icon with no `@title`/`@aria-label`/`@aria-labelledby` gets `role="presentation"` and **no default `aria-hidden`**. Before, it got `aria-hidden="true"` and `role="image"`.
  - A labelled icon gets `role="img"`.
  - A caller `role`/`aria-hidden` attribute still wins (`...attributes` comes last).
  - `@title` together with `@aria-label` renders an unlabelled `<title>` without an id, as upstream does.
  - `<img>` icons get the same role and `alt`.
- Loading:
  - While an EUI icon's SVG loads, the placeholder carries `data-is-loading` and the upstream `isLoading` style: opacity 0.05, currentColor background, inline radius.
  - An icon that had to load gets `data-is-loaded` and the 250ms fade-in, under `prefers-reduced-motion: no-preference`.
  - Preloaded icons get neither. The asset set and loader are unchanged.
- New `data-icon-type="<name>"` on EUI icons. Upstream only sets it after an async load; here it is always set. `data-type` (logoElastic) is kept.
- **`@onIconLoad` now fires.** It was documented but never called. It fires once the final icon is in the DOM: on insert for components and images, after the SVG arrives for EUI icons.
- Not ported: `stylesMemoizer`, and React `appendIconComponentCache`/`clearIconComponentCache` (`preloadIcons`/`clearIconCache` cover these).

**EuiToken**
- Presets come from upstream `TOKEN_MAP`. **49 entries differ from the old local map**:
  - Borealis uses the even vis colors, e.g. `tokenString` euiColorVis1 → euiColorVis2.
  - `tokenRepo/tokenSymbol/tokenFile` were dark rectangles and are now light squares. Upstream ignores fill presets: the default fill is always `light`.
  - `tokenDenseVector`, our name for upstream `tokenVectorDense`, keeps the upstream preset through a local alias.
- Sizes are 8/16/24/32px. Rectangles are content-box with logical inline padding.
- Colors follow the upstream fill math: light uses tint/shade plus an inset border, with preferred and forced contrast variants; dark picks textGhost or textInk. A custom hex still forces dark unless `@fill="none"`, set through a class.
- New args forwarded to the icon: `@aria-label`, `@aria-labelledby`, `@aria-describedby`. The `euiToken--*` classes are removed.

**EuiAvatar**
- New upstream args:
  - `@casing`, defaulting to uppercase for users and none for spaces.
  - `@color="subdued"`.
  - `@color={{null}}`, the default gray `lightShade`.
  - `@initialsLength`, the upstream name. `@initialLength` is kept as an alias.
- The default background is the theme's `colors.vis[name.length % 10]` (Borealis). It was the legacy Amsterdam behind-text palette.
- Sizes are 24/32/40/64px with upstream font sizes. Forced contrast adds a border, with box-sizing reset to border-box, and makes icons `fullShade`.
- The icon now has `aria-hidden="true"`, because the avatar carries the label. Before, the icon repeated `aria-label`/`role`.
- Initials always render when there is no image or icon.
- Upstream wraps named avatars in EuiToolTip; this port keeps the native `title` attribute instead, because ToolTip is unmigrated.

**EuiBeacon**
- New `@color` (subdued/primary/success/accent/danger/warning), defaulting to `success`.
- Size is set through a class (logical), so the caller's `style` is kept. Pulse keyframes come from upstream; forced contrast sets `forced-color-adjust: none`.

**EuiHealth**
- Uses upstream styles and the migrated `EuiFlexGroup`/`EuiFlexItem` (gutter xs, centered, responsive=false, items grow=false), replacing the hand-written legacy flex classes.
- **The default `@textSize` is now `'s'`** (upstream). It was `'m'`. The `euiHealth--textSize*` classes are removed.

## Icon-name gaps vs upstream (assets not changed)

- Ours: 470 named icons. Upstream 123.1.0: 567.
- 226 upstream names are missing here. Upstream renamed most legacy names: e.g. `external` (ours `popout`), `question` (ours `questionInCircle`), `chevronSingleDown/Left/Right/Up` (ours `arrowDown/…`), `info` (`iInCircle`), `plusCircle`/`minusCircle` (`plusInCircle`/`minusInCircle`), `textBold`… (`editorBold`…), `chart*` (`vis*`), `tokenVectorDense` (`tokenDenseVector`), `starFill`, `checkCircleFill`, `eyeSlash`. Upstream also added new ones: `product*`, `table*`, `transition*`, `sparkles`, `workflow`, etc.
- 129 of our names no longer exist upstream: the legacy names above plus removed glyphs.
- EuiIconTip keeps `questionInCircle` as its default; upstream uses `question`, which we don't ship.
- A rename/alias table plus refreshed assets is a separate task.

## Local icon styling in migrated components that can be removed now

EuiIcon itself now provides each of these declarations: size through logical inline/block size, `fill: currentColor`, `flex-shrink: 0`, `display: inline-block` and `vertical-align: middle`. I did not edit these files.

1. `eui-button.gts` (~L150–171): the inline `iconSize` map and the `'& .euiButtonContent__icon': { width, height, inlineSize, blockSize, fill, flexShrink }` block. Keep only `margin: 0` if wanted. `original: 'auto'` there overrode the SVG's own size; without it, `original` follows upstream (the SVG attributes).
2. `eui-button-empty.gts`: the `ICON_SIZES` map (L16–24) and the same `'& .euiButtonContent__icon'` block (~L163–171).
3. `eui-button-icon.gts`: the `ICON_SIZES` map (L22–30) and the `'& .euiButtonIcon__icon'` block (~L190–198). `@size`/`@color="inherit"` on the EuiIcon already produce it.
4. `eui-badge.gts`: `euiBadgeIconSizing()` (L97–113) and its use in `iconClass` (L316). EuiIcon `@size="s"` is passed already.
5. `eui-beta-badge.gts`: the `euiBadgeIconSizing(...)` call in `iconClass` (L145–147). The icon already gets `@size={{this.size}}`.
6. `eui-link.gts` (L164–173) `'& .euiLink__externalIcon'`: everything except `marginInlineStart: theme.size.xs`, which is upstream link styling. That is display, verticalAlign, inline/block size, fill and flexShrink.

The scoped selectors have higher specificity (0,2,0) than the icon class (0,1,0) but produce the same values, so nothing breaks before they are removed.

## Checks run

Environment: Node 22.22.1, Chromium 130 from the scratchpad, `CI=true`, with five other agents building concurrently. pnpm was unavailable, so binaries were run directly.

- Core tests (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **679 tests, 679 pass, 0 fail**. That includes the 23 new `Borealis icon family` tests. The first full run found 1 failure, the `eui-link-borealis-test` `aria-hidden` assertion described above; it was fixed and the full suite re-run.
- `node --test scripts/eui-upstream-parity.test.mjs`: **36/36 pass** (30 before, plus 4 factory matrices, the helper/static test and the token-port test).
- `node scripts/generate-eui-styles.mjs --check`: fails in the worktree with "Stale generated artifact", as the brief expects. The cause is the `node_modules` symlink path comments. Regenerating and normalizing those comments gives a byte-identical file.
- `ember-tsc --noEmit`: pass. ESLint on every changed component, util and test: pass.
- `node scripts/generate-api-docs.mjs --check`: pass, after regenerating 5 pages.
- The "every named icon" catalog test takes about 5–8s under a load average of about 12, on both the base and this branch. It hit testem's 10s browser timeout once in a filtered run under load, and passed in the full runs.

## Unresolved

1. Avatar tooltip: the upstream EuiToolTip wrapper (`anchorProps` with the user/space radius) is not ported; the `title` attribute stands in. Revisit when ToolTip migrates. The `tooltip` slot of `euiAvatarStyles` is ready.
2. The token palette comes from the nearest theme's `colors.vis`, while upstream uses the global store set from the outermost theme. Borealis vis colors are mode-independent, so they only diverge if a nested provider overrides `colors.vis`.
3. Decorative icons no longer default to `aria-hidden`. Through `...attributes`, labels passed as `aria-label=` (an attribute, not `@aria-label`) are invisible to the component, which then emits `role="presentation"`. Per ARIA, the presentation role is ignored when a global `aria-*` attribute is present, so the icon is still announced. Prefer `@aria-label`.
4. Icon renames/assets (above).
5. Coordinator: remove the local icon styling listed above, delete the unused css-mappings (`eui-avatar.ts`, `eui-health.ts`, the size/color maps in `eui-icon.ts`) together with their registry entries, and decide on `utils/token-map.ts`.
6. Not run (root): rollup build, site build/acceptance, showcase/visual and forced-colors emulation.
