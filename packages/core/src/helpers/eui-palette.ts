import { helper } from '@ember/component/helper';

import {
  euiPaletteColorBlind,
  euiPaletteColorBlindBehindText,
  euiPaletteComplementary,
  euiPaletteCool,
  euiPaletteForStatus,
  euiPaletteForTemperature,
  euiPaletteGray,
  euiPaletteGreen,
  euiPaletteOrange,
  euiPaletteRed,
  euiPaletteSkyBlue,
  euiPaletteWarm,
  euiPaletteYellow
} from '../utils/color/eui_palettes.ts';
import {
  euiPaletteComplimentary,
  euiPaletteForDarkBackground,
  euiPaletteForLightBackground,
  euiPaletteNegative,
  euiPalettePositive
} from '../utils/color/eui_palettes_deprecated.ts';

import type { EuiPalette } from '../utils/color/eui_palettes.ts';

export const PALETTES = {
  euiPaletteForLightBackground,
  euiPaletteForDarkBackground,
  euiPaletteColorBlind,
  euiPaletteColorBlindBehindText,
  euiPaletteForStatus,
  euiPaletteForTemperature,
  euiPaletteComplementary,
  euiPaletteComplimentary,
  euiPaletteNegative,
  euiPalettePositive,
  euiPaletteCool,
  euiPaletteWarm,
  euiPaletteGray,
  euiPaletteRed,
  euiPaletteGreen,
  euiPaletteSkyBlue,
  euiPaletteYellow,
  euiPaletteOrange
};

export type palette_keys = keyof typeof PALETTES;

export default helper(function ([paletteName, steps]: [
  palette_keys,
  number
]): EuiPalette {
  return PALETTES[paletteName](steps);
});
