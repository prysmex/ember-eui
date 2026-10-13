---
title: Color palettes
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Color palettes"/>
<EuiSpacer @size="l" />

<EuiText>

The palette functions return an array of hexadecimal colors for use in other EUI components or charts. Import them from `@ember-eui/core/utils/color/eui_palettes` (or `@ember-eui/core/utils/color`):

```js
import { euiPaletteColorBlind, euiPaletteForStatus, colorPalette } from '@ember-eui/core/utils/color';
```

## Qualitative palettes

`euiPaletteColorBlind()` is recommended for qualitative and categorical data. It has 10 colors; `rotations` adds more groups of 10 that are alternates of the original (better than looping the set), `order` (`'append'` or `'group'`), `direction` (`'lighter'`, `'darker'`, `'both'`), `sortBy: 'natural'` and `sortShift` change how they are arranged. `euiPaletteColorBlindBehindText()` is a brightened variant for placing text on top of the colors. `euiPaletteForLightBackground()` and `euiPaletteForDarkBackground()` return five colors tuned for each background.

## Quantitative palettes

For data on a continuum pass the number of steps and the function interpolates: `euiPaletteForStatus`, `euiPaletteForTemperature`, `euiPaletteComplimentary`, `euiPaletteNegative`, `euiPalettePositive`, `euiPaletteCool`, `euiPaletteWarm`, `euiPaletteGray`, and `euiPaletteRed`, `euiPaletteGreen`, `euiPaletteSkyBlue`, `euiPaletteYellow`, `euiPaletteOrange`. The status palette is the only one with proper contrast ratios: with the others consider adding another form of the data for screen readers.

## Custom palettes

`colorPalette(colors, len, diverging, categorical)` generates a gradient array of any length from one or more hex colors. `diverging` interpolates the two halves of the spectrum separately; without a middle point it graduates to light gray.

**Differences from upstream:** the React `useEuiPalette*` hooks do not exist; call the functions, and call them again when the color mode changes. Upstream's palettes read the theme's visualization colors from `EUI_VIS_COLOR_STORE` and accept a `colors` option; in Ember EUI only `euiPaletteRed`, `euiPaletteGreen`, `euiPaletteSkyBlue`, `euiPaletteYellow` and `euiPaletteOrange` do (by default the Borealis vis colors, identical in light and dark mode), and the others return EUI's classic palette values. `euiPaletteComplimentary` is upstream's `euiPaletteComplementary` under its old spelling. See the EuiColorPalettePicker page for using palettes in a picker.

</EuiText>

<EuiSpacer />
