import { helper } from '@ember/component/helper';
import {
  EuiPalette,
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
} from '../utils/color/eui_palettes';

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
}

export type palette_keys = keyof typeof PALETTES;

export default helper(function ([paletteName, steps]: [palette_keys, number]): EuiPalette {
  return PALETTES[paletteName](steps);
});