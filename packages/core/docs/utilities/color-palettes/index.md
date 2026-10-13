---
title: Color palettes
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Color palettes"/>
<EuiSpacer @size="l" />

<EuiText>

EUI provides a base set of color palettes that return an array of hexadecimal colors for use in other EUI components or charts. Import them from `@ember-eui/core/utils/color` (or `@ember-eui/core/utils/color/eui_palettes`):

```js
import {
  euiPaletteColorBlind,
  euiPaletteForStatus,
  colorPalette,
  useEuiPaletteColorBlind
} from '@ember-eui/core/utils/color';
```

## Theme-aware palettes

Upstream's palettes read the theme's visualization colors (`euiTheme.colors.vis`, the Borealis vis colors, which change in high contrast mode). React keeps a global store in sync with the provider and offers `useEuiPalette*` hooks. Ember EUI has no global store, so:

- The plain functions (`euiPaletteColorBlind()`, `euiPaletteForStatus(5)`, …) use the Borealis light mode vis colors by default, and accept the same `colors` option as upstream (`euiPaletteForStatus(5, { colors })`, `euiPaletteColorBlind({ colors })`) to use any other set, e.g. `euiTheme.colors.vis`.
- The `useEuiPalette*` functions are the theme-aware equivalents. They take the theme context as the first argument (`getEuiThemeContext(this).upstream` from `@ember-eui/core/theming`, or any `{ euiTheme }`), so call them in a `@cached` getter and the palette follows the color mode and high contrast: `useEuiPaletteColorBlind(context, { rotations: 2 })`, `useEuiPaletteForStatus(context, 5)`.

## Preset qualitative palettes

Qualitative palettes are best suited for communicating and comparing discrete data series. EUI recommends using `euiPaletteColorBlind()` for qualitative and categorical data.

This palette is restricted to only 10 colors. However, you can add more groups of 10 which are alternates of the original (`rotations`, with `order`, `direction`, `sortBy: 'natural'` and `sortShift`). This is better than allowing the initial set to loop.

These colors are meant to be used as graphics and contrasted against the value of `euiColorEmptyShade` for the current theme. When placing text on top of these colors, use the `euiPaletteColorBlindBehindText()` variant, which follows the theme's behind-text vis colors.

## Recommended quantitative palettes

Quantitative palettes are best suited for displaying data on a continuum, as in the case of health statuses and large geographic or demographic-based data sets. Just pass in the number of steps needed and the function will interpolate between the colors: `euiPaletteForStatus`, `euiPaletteForTemperature`, `euiPaletteComplementary`, `euiPaletteRed`, `euiPaletteGreen`, `euiPaletteSkyBlue`, `euiPaletteYellow`, `euiPaletteOrange`, `euiPaletteCool`, `euiPaletteWarm` and `euiPaletteGray`.

The palette for status is the only palette that has proper contrast ratios. When using the other palettes, consider adding another form of the data for screen readers.

## Custom palettes

Use the `colorPalette(colors, len, diverging, categorical)` service to generate a custom, gradiated palette array of any length from one or more hexadecimal color codes. The third parameter, `diverging`, will interpolate between the two halves of the spectrums separately. If a middle point is not provided, it will graduate to light gray.

## Deprecated

Deprecated since 15.0.0, removed in 16.0.0:

- `euiPaletteComplimentary` is `euiPaletteComplementary` under its old spelling.
- `euiPaletteNegative`, `euiPalettePositive`, `euiPaletteForLightBackground` and `euiPaletteForDarkBackground` do not exist upstream in the Borealis release. They keep their classic values; use `euiPaletteRed`, `euiPaletteGreen` and `euiPaletteColorBlind`.

See the EuiColorPalettePicker page for using palettes in a picker.

</EuiText>

<EuiSpacer />
