import { helper } from '@ember/component/helper';

import {
  euiPaletteColorBlind,
  euiPaletteColorBlindBehindText,
  euiPaletteComplimentary,
  euiPaletteCool,
  euiPaletteForDarkBackground,
  euiPaletteForLightBackground,
  euiPaletteForStatus,
  euiPaletteForTemperature,
  euiPaletteGray,
  euiPaletteNegative,
  euiPalettePositive,
  euiPaletteWarm} from '../utils/color/eui_palettes';

import type { EuiPalette } from '../utils/color/eui_palettes';

export const PALETTES = {
  euiPaletteForLightBackground,
  euiPaletteForDarkBackground,
  euiPaletteColorBlind,
  euiPaletteColorBlindBehindText,
  euiPaletteForStatus,
  euiPaletteForTemperature,
  euiPaletteComplimentary,
  euiPaletteNegative,
  euiPalettePositive,
  euiPaletteCool,
  euiPaletteWarm,
  euiPaletteGray
};

export type palette_keys = keyof typeof PALETTES;

export default helper(function ([paletteName, steps]: [
  palette_keys,
  number
]): EuiPalette {
  return PALETTES[paletteName](steps);
});
