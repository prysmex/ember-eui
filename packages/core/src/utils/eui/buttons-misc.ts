/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Hand port of EUI 123.1.0
 * `components/button/button_group/button_group_button.styles.js`.
 *
 * The upstream module imports `euiScreenReaderOnly` from the React
 * `components/accessibility` barrel, so the generator cannot extract it.
 * This port composes the same pure helpers (extracted into
 * `styles.generated.ts`) in the same order, and the parity suite
 * (`scripts/eui-upstream-parity.test.mjs`) compares every slot with the
 * upstream module in every color/contrast mode.
 */
import { serializeStyles } from '@emotion/serialize';

import {
  BUTTON_COLORS,
  euiButtonSizeMap,
  euiDisabledSelector,
  euiOutline,
  euiScreenReaderOnly,
  euiTextShift,
  highContrastModeStyles,
  logicalCSS,
  preventForcedColors
} from './styles.generated.ts';

import type { EuiBorealisContext } from './theme.ts';

// The extracted helpers read optional parameters through `arguments`, so
// their inferred TypeScript signatures take no parameters.
const textShift = euiTextShift as unknown as (
  fontWeight: string,
  attribute: string,
  euiTheme: EuiBorealisContext['euiTheme']
) => string;
const outline = euiOutline as unknown as (
  euiThemeContext: EuiBorealisContext,
  offset: string,
  color: string
) => string;
import type { SerializedStyles } from '@emotion/serialize';

// Same serialization the generator substitutes for Emotion's `css`.
const css = (...args: unknown[]) =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

interface ButtonSize {
  height: string;
  radiusInset: string;
  getInsetHeight: (height: string, padding: string) => string;
}

// Upstream ships this static slot pre-serialized (Babel's Emotion plugin).
const tooltipWrapper = {
  name: '1ockoqy-tooltipWrapper',
  styles:
    'min-inline-size:0;&:has(:focus-visible){z-index:1;};label:tooltipWrapper;'
} as SerializedStyles;

export const euiButtonGroupButtonStyles = (
  euiThemeContext: EuiBorealisContext
) => {
  const euiTheme = euiThemeContext.euiTheme;
  const highContrastMode = euiThemeContext.highContrastMode;
  const buttonSizeMap = euiButtonSizeMap(euiThemeContext) as Record<
    's' | 'm',
    ButtonSize
  >;
  const buttonSizes = {
    s: {
      height: buttonSizeMap.s.getInsetHeight(
        buttonSizeMap.s.height,
        euiTheme.size.xs
      ),
      radius: buttonSizeMap.s.radiusInset
    },
    m: {
      height: buttonSizeMap.m.getInsetHeight(
        buttonSizeMap.m.height,
        euiTheme.size.xs
      ),
      radius: buttonSizeMap.m.radiusInset
    }
  };
  const selectedSelectors =
    '.euiButtonGroupButton-isSelected, .euiButtonGroup__tooltipWrapper-isSelected';
  return {
    // Base
    euiButtonGroupButton: css(
      logicalCSS('min-width', 0),
      ' flex-shrink:1;flex-grow:0;border:none;border-radius:',
      buttonSizes.s.radius,
      ';font-weight:',
      euiTheme.font.weight.medium,
      ';&:is(',
      selectedSelectors,
      '):not(',
      euiDisabledSelector,
      '){',
      highContrastModeStyles(euiThemeContext, {
        forced: `
            --highContrastHoverIndicatorColor: ${euiTheme.colors.textInverse};
            border: none;

            /* styles the content manually instead of the button itself to preserve the system
            focus style, as otherwise preventForcedColors() would require manual styling */
            > [class*="euiButtonDisplayContent"] {
              ${preventForcedColors(euiThemeContext)}
              color: ${euiTheme.colors.emptyShade};
              border: none;
            }
          `
      }),
      ';}&:is(',
      selectedSelectors,
      ':where(',
      euiDisabledSelector,
      ')){border:none;}&:focus-visible{outline-offset:0;};label:euiButtonGroupButton;'
    ),
    iconOnly: {
      // used only as classname, sizes are added separately
      iconOnly: css(';label:iconOnly;'),
      s: `
        ${logicalCSS('width', buttonSizes.s.height)}
      `,
      m: `
        ${logicalCSS('width', buttonSizes.m.height)}
      `
    },
    s: css(
      logicalCSS('height', buttonSizes.s.height),
      ' line-height:',
      buttonSizes.s.height,
      ';;label:s;'
    ),
    m: css(
      logicalCSS('height', buttonSizes.m.height),
      ' line-height:',
      buttonSizes.m.height,
      ';;label:m;'
    ),
    // States
    isSelected: css(
      'background-color:',
      euiTheme.colors.backgroundLightText,
      ';&:is(',
      selectedSelectors,
      '):not(',
      euiDisabledSelector,
      '){',
      highContrastModeStyles(euiThemeContext, {
        preferred: `
            border: ${euiTheme.border.width.thin} solid currentColor;
          `,
        forced: `
            border: none;
          `
      }),
      ';}&:is(',
      selectedSelectors,
      ':where(',
      euiDisabledSelector,
      ')){',
      highContrastModeStyles(euiThemeContext, {
        preferred: `
            border: ${euiTheme.border.thin};
          `
      }),
      ';};label:isSelected;'
    ),
    disabledAndSelected: css(
      'color:',
      euiTheme.colors.textDisabled,
      ';background-color:',
      euiTheme.components.buttonGroupBackgroundDisabledSelected,
      ';border:',
      highContrastMode
        ? `${euiTheme.border.width.thin} solid ${euiTheme.components.buttonGroupBackgroundDisabledSelected}`
        : `${euiTheme.border.width.thin} solid ${euiTheme.colors.borderBasePlain}`,
      ';;label:disabledAndSelected;'
    ),
    // Tooltip anchor wrapper
    tooltipWrapper,
    // Text wrapper
    text: {
      euiButtonGroupButton__text: css(
        textShift('bold', 'data-text', euiTheme),
        ';;label:euiButtonGroupButton__text;'
      ),
      euiButtonGroupButton__iconOnly: css(
        euiScreenReaderOnly(),
        ';;label:euiButtonGroupButton__iconOnly;'
      )
    }
  };
};

export const _compressedButtonFocusColors = (
  euiThemeContext: EuiBorealisContext
): Record<string, SerializedStyles> => {
  const euiTheme = euiThemeContext.euiTheme;
  const colors: string[] = [...(BUTTON_COLORS as string[]), 'disabled'];
  return colors.reduce<Record<string, SerializedStyles>>(
    (acc, color) => ({
      ...acc,
      [color]: css(
        '&:focus-visible{',
        outline(euiThemeContext, 'outset', euiTheme.focus.color),
        ';}'
      )
    }),
    {}
  );
};
