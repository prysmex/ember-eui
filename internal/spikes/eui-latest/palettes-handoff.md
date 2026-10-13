# Color palettes handoff (eui-wave/palettes)

Ports EUI 123.1.0 `services/color/eui_palettes.ts` + `eui_palettes_hooks.ts`.

## Shape (Ember)
- `utils/color/eui_palettes.ts`: palettes read the Borealis vis colors and take upstream's `colors` option. No global `EUI_VIS_COLOR_STORE`: the default is the Borealis light vis colors (upstream's store default; vis colors are identical in dark).
- Theme-aware equivalents of the `useEuiPalette*` hooks: `useEuiPaletteX(context, steps | props)` where `context` is the theme context (`getEuiThemeContext(this).upstream`) or any `{ euiTheme }`. Call them in `@cached` getters. Exported from `@ember-eui/core/utils/color` (and `utils`).
- `euiPaletteComplementary` added. Deprecated runtime wrappers (since 15.0.0, until 16.0.0) in `eui_palettes_deprecated.ts`, exported by the `utils/color` barrel and the `eui-palette` helper: `euiPaletteComplimentary` (alias), `euiPaletteNegative`, `euiPalettePositive`, `euiPaletteForLightBackground`, `euiPaletteForDarkBackground` (the last four do not exist upstream; classic values unchanged). Deep-importing `utils/color/eui_palettes` gives the same names without the runtime warning (keeps that file free of `@ember/debug`, which the parity script bundles).
- `euiPaletteColorBlindBehindText` equals `euiPaletteColorBlind` (upstream no longer brightens).

## Visible color changes
- Default categorical palette: `#54B399 #6092C0 ...` -> Borealis `#16C5C0 #A6EDEA #61A2FF #BFDBFF #EE72A6 #FFC7DB #F6726A #FFC9C2 #EAAE01 #FCD883`; high contrast uses the darker set.
- ForStatus, ForTemperature, Cool, Warm, Gray, Complementary (was Complimentary): new gradients from vis colors.
- BehindText: no longer brightened.
- `EuiColorPicker` default swatches: now theme-aware vis colors (was fixed classic palette).
- Avatar default colors, Token, sitewide selectable already used theme vis colors; they now call the palette functions (no color change).
- Docs demos calling `euiPalette*()` (color palette picker, combo box pills, timeline) change automatically.
All listed in `.changeset/borealis-migration.md` and `docs/migrating-to-borealis.md` ("Color palettes").

## Tests
- `tests/unit/utils/eui-palettes-test.ts`: ports upstream palette + hook tests (values in light, dark, light high contrast), deprecation test. 29 tests.
- Full core suite: see final reply. Parity: 356/356.

## Docs
- `docs/utilities/color-palettes`: index rewritten; demos d01 qualitative, d02 quantitative (all 11 palettes), d03 custom, mirroring upstream's examples (copy links, behind-text badges).

## Not done / notes
- No store `subscribe()`; apps re-call on color mode change (or use the theme-aware functions).
- Combo box docs demos (other agent) call the plain functions; they are not theme-aware.
