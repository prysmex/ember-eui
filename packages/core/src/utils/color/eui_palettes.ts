/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

import chroma from 'chroma-js';
import type { _EuiThemeVisColors } from '@elastic/eui-theme-common';

import { resolveBorealisTheme } from '../eui/theme.ts';
import { colorPalette } from './color_palette.ts';

export type EuiPalette = string[];

const flatten = (arr: string[][]): string[] => ([] as string[]).concat(...arr);

const euiPalette = function (
  colors: string[],
  steps: number,
  diverge: boolean = false,
  categorical: boolean = true
): EuiPalette {
  // This function also trims the first color so white/black is never a color
  if (!diverge && steps > 1) {
    const palette = colorPalette(colors, steps + 1);
    palette.shift();
    return palette;
  }

  return colorPalette(colors, steps, diverge, categorical);
};

let defaultVisColors: EuiPaletteVisColors | undefined;

/** The given vis colors, or the Borealis (light mode) ones: upstream's default store. */
function visColorsOf(colors?: EuiPaletteVisColors): EuiPaletteVisColors {
  if (colors) return colors;
  defaultVisColors ??= resolveBorealisTheme('light').euiTheme.colors
    .vis as EuiPaletteVisColors;
  return defaultVisColors;
}

export type EuiPaletteVisColors = _EuiThemeVisColors;

export type EuiPaletteCommonProps = {
  /**
   * Defines the default set of colors the palette uses.
   * Ember EUI has no global vis color store: this defaults to the Borealis
   * (light mode) vis colors. Pass the current theme's `euiTheme.colors.vis`
   * (or use the `useEuiPalette*` functions) to follow the color mode and
   * high contrast.
   */
  colors?: EuiPaletteVisColors;
};

export type EuiPaletteRotationProps = {
  /**
   * How many variations of the series is needed
   */
  rotations?: number;
  /**
   * Order similar colors as `group`s or just `append` each variation
   */
  order?: 'append' | 'group';
  /**
   * Specifies if the direction of the color variations
   */
  direction?: 'lighter' | 'darker' | 'both';
  /**
   * Use the default sort order, or re-sort them based on the color wheel (natural)
   */
  sortBy?: 'default' | 'natural';
  /**
   * Shift the sorting order by a certain number when used in conjunction with `'natural'` `sortBy`.
   * Defaults to a number close to green.
   */
  sortShift?: string;
};

export type EuiPaletteColorBlindProps = EuiPaletteCommonProps &
  EuiPaletteRotationProps;

/**
 * Theme-aware version: `useEuiPaletteColorBlind(context)`.
 */
export const euiPaletteColorBlind = ({
  rotations = 1,
  order = 'append',
  direction = 'lighter',
  sortBy = 'default',
  sortShift = '-100',
  colors,
}: EuiPaletteColorBlindProps = {}): EuiPalette => {
  let _colors: string[] = [];

  const visColors = visColorsOf(colors);

  let base = [
    visColors.euiColorVis0,
    visColors.euiColorVis1,
    visColors.euiColorVis2,
    visColors.euiColorVis3,
    visColors.euiColorVis4,
    visColors.euiColorVis5,
    visColors.euiColorVis6,
    visColors.euiColorVis7,
    visColors.euiColorVis8,
    visColors.euiColorVis9,
  ];

  if (sortBy === 'natural') {
    // Sort the colors based on the color wheel, but shifting the values based on sortShift
    base = [...base].sort(function (a, b) {
      return (
        chroma(a).set('hsl.h', sortShift).hsl()[0] -
        chroma(b).set('hsl.h', sortShift).hsl()[0]
      );
    });
  }

  if (rotations > 1) {
    const palettes = base.map((color) => {
      // Create the darkest and lightest versions of each color using black and white
      const palette = colorPalette(['black', color, 'white'], 5, false, true);
      // Then removing the extremes
      palette.pop();
      palette.shift();

      switch (direction) {
        case 'lighter':
          return colorPalette([palette[1]!, palette[2]!], rotations, false, true);
        case 'darker':
          return colorPalette([palette[1]!, palette[0]!], rotations, false, true);
        case 'both':
          return colorPalette(palette, rotations, false, true);
      }
    });

    if (order === 'group') {
      _colors = flatten(palettes);
    } else {
      for (let i = 0; i < rotations; i++) {
        const rotation = palettes.map((palette) => palette[i]!);
        _colors.push(...rotation);
      }
    }
  } else {
    _colors = base;
  }

  return _colors;
};

/**
 * Theme-aware version: `useEuiPaletteColorBlindBehindText(context)`.
 *
 * Color blind palette with text is meant for use when text is applied on top of the color.
 * Like upstream's Borealis, it returns the same colors as `euiPaletteColorBlind`.
 */
export const euiPaletteColorBlindBehindText = (
  paletteProps: EuiPaletteColorBlindProps = {}
) => {
  return euiPaletteColorBlind(paletteProps);
};

/**
 * Theme-aware version: `useEuiPaletteForStatus(context)`.
 */
export const euiPaletteForStatus = function (
  steps: number,
  { colors }: EuiPaletteCommonProps = {}
): EuiPalette {
  const visColors = visColorsOf(colors);

  if (steps === 1) {
    return [visColors.euiColorVisSuccess0];
  }
  if (steps <= 3) {
    return euiPalette(
      [
        visColors.euiColorVisSuccess0,
        visColors.euiColorVisWarning1,
        visColors.euiColorVisDanger0,
      ],
      steps,
      true
    );
  }
  return euiPalette(
    [
      visColors.euiColorVisSuccess0,
      visColors.euiColorVisSuccess1,
      visColors.euiColorVisWarning1,
      visColors.euiColorVisDanger1,
      visColors.euiColorVisDanger0,
    ],
    steps,
    true
  );
};

/**
 * Theme-aware version: `useEuiPaletteForTemperature(context)`.
 */
export const euiPaletteForTemperature = function (
  steps: number,
  { colors }: EuiPaletteCommonProps = {}
): EuiPalette {
  const visColors = visColorsOf(colors);

  if (steps === 1) {
    return [visColors.euiColorVisCool2];
  } else if (steps <= 3) {
    return euiPalette(
      [visColors.euiColorVisCool2, visColors.euiColorVisWarm2],
      steps,
      true
    );
  }

  const cools = colorPalette(
    [
      visColors.euiColorVisCool2,
      visColors.euiColorVisCool1,
      visColors.euiColorVisCool0,
    ],
    3
  );
  const warms = colorPalette(
    [
      visColors.euiColorVisWarm0,
      visColors.euiColorVisWarm1,
      visColors.euiColorVisWarm2,
    ],
    3
  );

  const paletteColors = [...cools, visColors.euiColorVisBase0, ...warms];

  return euiPalette(paletteColors, steps, true);
};

/**
 * Theme-aware version: `useEuiPaletteComplementary(context)`.
 */
export const euiPaletteComplementary = function (
  steps: number,
  { colors }: EuiPaletteCommonProps = {}
): EuiPalette {
  const visColors = visColorsOf(colors);

  if (steps === 1) {
    return [visColors.euiColorVisComplementary0];
  }

  const paletteColors = [
    visColors.euiColorVisComplementary0,
    visColors.euiColorVisBase0,
    visColors.euiColorVisComplementary1,
  ];

  return euiPalette(paletteColors, steps, true);
};

/**
 * Theme-aware version: `useEuiPaletteRed(context)`.
 */
export const euiPaletteRed = function (
  steps: number,
  { colors }: EuiPaletteCommonProps = {}
): EuiPalette {
  const visColors = visColorsOf(colors);

  if (steps === 1) {
    return [visColors.euiColorVisDanger1];
  }

  return euiPalette(
    [visColors.euiColorVisBase0, visColors.euiColorVisDanger0],
    steps
  );
};

/**
 * Theme-aware version: `useEuiPaletteGreen(context)`.
 */
export const euiPaletteGreen = function (
  steps: number,
  { colors }: EuiPaletteCommonProps = {}
): EuiPalette {
  const visColors = visColorsOf(colors);

  if (steps === 1) {
    return [visColors.euiColorVisSuccess1];
  }

  return euiPalette(
    [visColors.euiColorVisBase0, visColors.euiColorVisSuccess0],
    steps
  );
};

/**
 * Theme-aware version: `useEuiPaletteSkyBlue(context)`.
 */
export const euiPaletteSkyBlue = function (
  steps: number,
  { colors }: EuiPaletteCommonProps = {}
): EuiPalette {
  const visColors = visColorsOf(colors);

  if (steps === 1) {
    return [visColors.euiColorVisNeutral1];
  }

  return euiPalette(
    [visColors.euiColorVisBase0, visColors.euiColorVisNeutral0],
    steps
  );
};

/**
 * Theme-aware version: `useEuiPaletteYellow(context)`.
 */
export const euiPaletteYellow = function (
  steps: number,
  { colors }: EuiPaletteCommonProps = {}
): EuiPalette {
  const visColors = visColorsOf(colors);

  if (steps === 1) {
    return [visColors.euiColorVisWarning1];
  }

  return euiPalette(
    [visColors.euiColorVisBase0, visColors.euiColorVisWarning0],
    steps
  );
};

/**
 * Theme-aware version: `useEuiPaletteOrange(context)`.
 */
export const euiPaletteOrange = function (
  steps: number,
  { colors }: EuiPaletteCommonProps = {}
): EuiPalette {
  const visColors = visColorsOf(colors);

  if (steps === 1) {
    return [visColors.euiColorVisRisk1];
  }

  return euiPalette(
    [visColors.euiColorVisBase0, visColors.euiColorVisRisk0],
    steps
  );
};

/**
 * Theme-aware version: `useEuiPaletteCool(context)`.
 */
export const euiPaletteCool = function (
  steps: number,
  { colors }: EuiPaletteCommonProps = {}
): EuiPalette {
  const visColors = visColorsOf(colors);

  if (steps === 1) {
    return [visColors.euiColorVisCool1];
  }

  return euiPalette(
    [
      visColors.euiColorVisCool0,
      visColors.euiColorVisCool1,
      visColors.euiColorVisCool2,
    ],
    steps
  );
};

/**
 * Theme-aware version: `useEuiPaletteWarm(context)`.
 */
export const euiPaletteWarm = function (
  steps: number,
  { colors }: EuiPaletteCommonProps = {}
): EuiPalette {
  const visColors = visColorsOf(colors);

  if (steps === 1) {
    return [visColors.euiColorVisWarm2];
  }

  return euiPalette(
    [
      visColors.euiColorVisWarm0,
      visColors.euiColorVisWarm1,
      visColors.euiColorVisWarm2,
    ],
    steps
  );
};

/**
 * Theme-aware version: `useEuiPaletteGray(context)`.
 */
export const euiPaletteGray = function (
  steps: number,
  { colors }: EuiPaletteCommonProps = {}
): EuiPalette {
  const visColors = visColorsOf(colors);

  if (steps === 1) {
    return [visColors.euiColorVisGrey1];
  }

  return euiPalette(
    [
      visColors.euiColorVisBase0,
      visColors.euiColorVisGrey0,
      visColors.euiColorVisGrey1,
      visColors.euiColorVisGrey2,
      visColors.euiColorVisGrey3,
    ],
    steps,
    false
  );
};

/**
 * @deprecated since 15.0.0, removed in 16.0.0. Renamed upstream (spelling):
 * use `euiPaletteComplementary`.
 */
export const euiPaletteComplimentary = euiPaletteComplementary;

/* Legacy (Amsterdam era) palettes: upstream removed these in Borealis. They keep
   their classic values so existing consumers don't change; prefer the vis-based
   palettes above. */

const legacyNegativeColor = '#CC5642';
const legacyPositiveColor = '#209280';

/** @deprecated since 15.0.0, removed in 16.0.0. Use `euiPaletteRed`. */
export const euiPaletteNegative = function (steps: number): EuiPalette {
  if (steps === 1) {
    return ['#E7664C'];
  }

  return euiPalette(['white', legacyNegativeColor], steps);
};

/** @deprecated since 15.0.0, removed in 16.0.0. Use `euiPaletteGreen`. */
export const euiPalettePositive = function (steps: number): EuiPalette {
  if (steps === 1) {
    return ['#54B399'];
  }

  return euiPalette(['white', legacyPositiveColor], steps);
};

/**
 * @deprecated since 15.0.0, removed in 16.0.0. Upstream removed it with the
 * Amsterdam theme: use `euiPaletteColorBlind`.
 */
export const euiPaletteForLightBackground = function (): EuiPalette {
  return ['#006BB4', '#017D73', '#F5A700', '#BD271E', '#DD0A73'];
};

/**
 * @deprecated since 15.0.0, removed in 16.0.0. Upstream removed it with the
 * Amsterdam theme: use `euiPaletteColorBlind`.
 */
export const euiPaletteForDarkBackground = function (): EuiPalette {
  return ['#1BA9F5', '#7DE2D1', '#F990C0', '#F66', '#FFCE7A'];
};

/* Theme-aware versions (upstream's `useEuiPalette*` hooks). Ember has no hooks and
   no global vis color store: pass the theme context, e.g.
   `getEuiThemeContext(this)` from `@ember-eui/core/theming` (or any
   `{ euiTheme }`), and wrap the call in `@cached` so it recomputes with the
   color mode and high contrast. */

export interface EuiPaletteThemeContext {
  euiTheme: { colors: { vis: object } };
}

const themeColors = (context: EuiPaletteThemeContext): EuiPaletteVisColors =>
  context.euiTheme.colors.vis as EuiPaletteVisColors;

export const useEuiPaletteColorBlind = (
  context: EuiPaletteThemeContext,
  args?: EuiPaletteRotationProps
) => euiPaletteColorBlind({ ...args, colors: themeColors(context) });

export const useEuiPaletteColorBlindBehindText = (
  context: EuiPaletteThemeContext,
  args?: EuiPaletteRotationProps
) => euiPaletteColorBlindBehindText({ ...args, colors: themeColors(context) });

type StepsPalette = (steps: number, props?: EuiPaletteCommonProps) => EuiPalette;

const withSteps =
  (fn: StepsPalette) => (context: EuiPaletteThemeContext, steps: number) =>
    fn(steps, { colors: themeColors(context) });

export const useEuiPaletteForStatus = withSteps(euiPaletteForStatus);
export const useEuiPaletteForTemperature = withSteps(euiPaletteForTemperature);
export const useEuiPaletteComplementary = withSteps(euiPaletteComplementary);
export const useEuiPaletteRed = withSteps(euiPaletteRed);
export const useEuiPaletteGreen = withSteps(euiPaletteGreen);
export const useEuiPaletteSkyBlue = withSteps(euiPaletteSkyBlue);
export const useEuiPaletteYellow = withSteps(euiPaletteYellow);
export const useEuiPaletteOrange = withSteps(euiPaletteOrange);
export const useEuiPaletteCool = withSteps(euiPaletteCool);
export const useEuiPaletteWarm = withSteps(euiPaletteWarm);
export const useEuiPaletteGray = withSteps(euiPaletteGray);
