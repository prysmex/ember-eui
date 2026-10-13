import { deprecateRemovedUpstream } from '../../-private/removed-upstream.ts';
import {
  euiPaletteComplementary,
  euiPaletteForDarkBackground as _euiPaletteForDarkBackground,
  euiPaletteForLightBackground as _euiPaletteForLightBackground,
  euiPaletteNegative as _euiPaletteNegative,
  euiPalettePositive as _euiPalettePositive
} from './eui_palettes.ts';

import type { EuiPalette, EuiPaletteCommonProps } from './eui_palettes.ts';

/**
 * Deprecated palettes, exported (with a runtime deprecation) from
 * `@ember-eui/core/utils/color`. The functions in `eui_palettes.ts` keep the same
 * names without the warning, so that file stays free of Ember imports.
 */

/**
 * @deprecated since 15.0.0, removed in 16.0.0. Renamed upstream (spelling):
 * use `euiPaletteComplementary`.
 */
export const euiPaletteComplimentary = function (
  steps: number,
  props?: EuiPaletteCommonProps
): EuiPalette {
  deprecateRemovedUpstream(
    'eui-palette-complimentary',
    'euiPaletteComplimentary',
    'Use euiPaletteComplementary (upstream corrected the spelling).'
  );

  return euiPaletteComplementary(steps, props);
};

/** @deprecated since 15.0.0, removed in 16.0.0. Use `euiPaletteRed`. */
export const euiPaletteNegative = function (steps: number): EuiPalette {
  deprecateRemovedUpstream('eui-palette-negative', 'euiPaletteNegative', 'Use euiPaletteRed.');

  return _euiPaletteNegative(steps);
};

/** @deprecated since 15.0.0, removed in 16.0.0. Use `euiPaletteGreen`. */
export const euiPalettePositive = function (steps: number): EuiPalette {
  deprecateRemovedUpstream('eui-palette-positive', 'euiPalettePositive', 'Use euiPaletteGreen.');

  return _euiPalettePositive(steps);
};

/** @deprecated since 15.0.0, removed in 16.0.0. Use `euiPaletteColorBlind`. */
export const euiPaletteForLightBackground = function (): EuiPalette {
  deprecateRemovedUpstream(
    'eui-palette-for-light-background',
    'euiPaletteForLightBackground',
    'Use euiPaletteColorBlind.'
  );

  return _euiPaletteForLightBackground();
};

/** @deprecated since 15.0.0, removed in 16.0.0. Use `euiPaletteColorBlind`. */
export const euiPaletteForDarkBackground = function (): EuiPalette {
  deprecateRemovedUpstream(
    'eui-palette-for-dark-background',
    'euiPaletteForDarkBackground',
    'Use euiPaletteColorBlind.'
  );

  return _euiPaletteForDarkBackground();
};
