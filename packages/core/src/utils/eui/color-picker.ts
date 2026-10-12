/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Color picker family pieces without an EUI 123.1.0 style module.
 *
 * `EuiColorStops` was removed upstream in EUI 89.0.0, so 123.1.0 has no
 * `color_stops` styles to extract. The stops styles below are a hand port of
 * the last upstream version (EUI 88.5.4 `color_stops.styles.js` and
 * `color_stop_thumb.styles.js`), rebuilt on the EUI 123.1.0 range factories
 * extracted into `styles.generated.ts` (`euiRangeVariables`,
 * `euiRangeThumbStyle`, `euiRangeThumbFocus`), so they follow the current
 * Borealis range tokens. `euiCustomControl` (88.5.4) is omitted from the add
 * target: every declaration it set is overridden by the declarations that
 * follow it there. The parity suite checks the derived values against the
 * upstream 123.1.0 range variables.
 *
 * Also here: the scoped resets the family needs because Ember does not run
 * React's global reset (`button`, `ul`, `input` rules of upstream
 * `resetStyles`).
 */
import { euiCanAnimate, mathWithUnits } from '@elastic/eui-theme-common';
import { serializeStyles } from '@emotion/serialize';
import chroma from 'chroma-js';

import {
  euiRangeThumbFocus,
  euiRangeThumbStyle,
  euiRangeVariables,
  hexToRgb
} from './styles.generated.ts';

import type { EuiBorealisContext } from './theme.ts';
import type { CSSObject } from '@emotion/css/create-instance';

// Same serialization the generator substitutes for Emotion's `css`.
const css = (...args: unknown[]) =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

// upstream `services/color/manipulation.js` darken/brighten
const darken = (color: string, amount: number) =>
  chroma(color).darken(amount).hex();
const brighten = (color: string, amount: number) =>
  chroma(color).brighten(amount).hex();

/** React global `button` reset (upstream `resetStyles`), composed first. */
export const buttonReset: CSSObject = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  background: 'none',
  border: 'none',
  color: 'inherit',
  borderRadius: 0,
  fontSize: 'inherit'
};

/** React global `ul` reset (margin, padding, list style). */
export const listReset: CSSObject = {
  margin: 0,
  padding: 0,
  listStyle: 'none'
};

/** React global `input` reset (margin, padding) plus `*` box sizing. */
export const inputReset: CSSObject = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0
};

/** React global `*` box sizing for a wrapper and its descendants. */
export const boxReset: CSSObject = {
  boxSizing: 'border-box',
  '& :where(*, *::before, *::after)': { boxSizing: 'border-box' }
};

/** EUI 88.5.4 `euiColorPickerVariables().width`: 5 swatches and 4 gaps. */
export const euiColorPickerWidth = ({ euiTheme }: EuiBorealisContext) =>
  mathWithUnits(
    [euiTheme.size.l, euiTheme.size.s],
    (x: number, y: number) => x * 5 + y * 4
  );

/** EUI 88.5.4 `euiColorStopsStyles` on the 123.1.0 range variables. */
export const euiColorStopsStyles = (euiThemeContext: EuiBorealisContext) => {
  const range = euiRangeVariables(euiThemeContext);
  const { euiTheme, colorMode } = euiThemeContext;
  const isDarkMode = colorMode === 'DARK';
  const stripeColor = isDarkMode
    ? brighten(range.trackColor, 0.5)
    : darken(range.trackColor, 0.5);
  const stripesBackground = `repeating-linear-gradient(
    -45deg,
    ${range.trackColor},
    ${range.trackColor} 25%,
    ${stripeColor} 25%,
    ${stripeColor} 50%,
    ${range.trackColor} 50%
  )`;
  return {
    euiColorStops: css(';label:euiColorStops;'),
    isEnabled: css(
      '&:focus{outline:none;}&:focus-visible{.euiColorStops__track::after{box-shadow:0 0 0 1px rgba(',
      hexToRgb(euiTheme.colors.emptyShade).join(', '),
      ', 0.8),0 0 0 3px ',
      range.focusColor,
      ';}};label:isEnabled;'
    ),
    isDisabled: css(';label:isDisabled;'),
    isReadOnly: css(';label:isReadOnly;'),
    isDragging: css('cursor:grabbing;label:isDragging;'),
    euiColorStops__track: css(
      '&::after{background:',
      stripesBackground,
      ';background-size:',
      euiTheme.size.xs,
      ' ',
      euiTheme.size.xs,
      ';};label:euiColorStops__track;'
    ),
    euiColorStops__addTarget: css(
      euiRangeThumbStyle(euiThemeContext),
      ' position:absolute;inset-block-start:0;block-size:',
      range.thumbHeight,
      ';inline-size:',
      range.thumbHeight,
      ';background-color:',
      euiTheme.colors.lightestShade,
      ';pointer-events:none;opacity:0;border:',
      euiTheme.border.width.thin,
      ' solid ',
      euiTheme.colors.darkShade,
      ';box-shadow:none;z-index:',
      range.thumbZIndex,
      ';',
      euiCanAnimate,
      '{transition:opacity ',
      euiTheme.animation.fast,
      ' ease-in;};label:euiColorStops__addTarget;'
    )
  };
};

/** EUI 88.5.4 `euiColorStopsAddContainerStyles`. */
export const euiColorStopsAddContainerStyles = (
  euiThemeContext: EuiBorealisContext
) => {
  const range = euiRangeVariables(euiThemeContext);
  return {
    euiColorStopsAddContainer: css(
      'display:block;position:absolute;inset-inline-start:0;inset-inline-end:0;inset-block-start:50%;block-size:',
      range.thumbHeight,
      ';margin-block-start:',
      mathWithUnits(range.thumbHeight, (x: number) => x * -0.5),
      ';z-index:',
      range.thumbZIndex,
      ';;label:euiColorStopsAddContainer;'
    ),
    isEnabled: css(
      '&:hover{cursor:pointer;.euiColorStops__addTarget{opacity:0.7;}};label:isEnabled;'
    ),
    isDisabled: css(';label:isDisabled;')
  };
};

/** EUI 88.5.4 `euiColorStopThumbStyles` (composed after `euiRangeThumbStyles`). */
export const euiColorStopThumbStyles = (euiThemeContext: EuiBorealisContext) => ({
  euiColorStopThumb: css(
    '&:not(:disabled){inset-block-start:0;margin-block-start:0;pointer-events:auto;cursor:grab;&:active{cursor:grabbing;}};label:euiColorStopThumb;'
  ),
  isPopoverOpen: css(
    euiRangeThumbFocus(euiThemeContext),
    ';;label:isPopoverOpen;'
  )
});

/** EUI 88.5.4 `euiColorStopThumbPopoverStyles` (the popover root). */
export const euiColorStopThumbPopoverStyles = (
  euiThemeContext: EuiBorealisContext
) => {
  const range = euiRangeVariables(euiThemeContext);
  const { euiTheme } = euiThemeContext;
  return {
    euiColorStopThumbPopover: css(
      'position:absolute;inset-block-start:50%;inline-size:',
      range.thumbWidth,
      ';block-size:',
      range.thumbHeight,
      ';margin-block-start:',
      mathWithUnits(range.thumbHeight, (x: number) => x * -0.5),
      ";.euiColorStopThumbPopover__anchor{position:absolute;inline-size:100%;block-size:100%;&::before{content:'';display:block;position:absolute;inset-inline-start:0;inset-block-start:0;block-size:",
      range.thumbHeight,
      ';inline-size:',
      range.thumbWidth,
      ';border-radius:',
      range.thumbHeight,
      ';background:',
      euiTheme.colors.emptyShade,
      ';}};label:euiColorStopThumbPopover;'
    ),
    hasFocus: css('z-index:', range.thumbZIndex, ';;label:hasFocus;')
  };
};

/** EUI 88.5.4 `euiColorStopStyles` (the edit form in the popover). */
export const euiColorStopStyles = (euiThemeContext: EuiBorealisContext) => ({
  euiColorStop: css(
    'inline-size:',
    euiColorPickerWidth(euiThemeContext),
    ';;label:euiColorStop;'
  )
});
