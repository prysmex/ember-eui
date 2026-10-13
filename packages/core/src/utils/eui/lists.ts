/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Hand port of EUI 123.1.0 `components/key_pad_menu/key_pad_menu_item.styles.js`.
 *
 * The upstream module imports `euiScreenReaderOnly` from the React
 * `components/accessibility` barrel, so the generator cannot extract it.
 * This port composes the same pure helpers (extracted into
 * `styles.generated.ts`) in the same order, and the parity suite
 * (`scripts/eui-upstream-parity.test.mjs`) compares every slot with the
 * upstream module in every color/contrast mode.
 */
import { euiCanAnimate } from '@elastic/eui-theme-common';
import { serializeStyles } from '@emotion/serialize';

import {
  euiFontSize,
  euiKeyPadMenuVariables,
  euiScreenReaderOnly,
  highContrastModeStyles,
  logicalCSS,
  logicalSizeCSS
} from './styles.generated.ts';

import type { EuiBorealisContext } from './theme.ts';

// Same serialization the generator substitutes for Emotion's `css`.
const css = (...args: unknown[]) =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

export const euiKeyPadMenuItemStyles = (euiThemeContext: EuiBorealisContext) => {
  const euiTheme = euiThemeContext.euiTheme;
  const { euiKeyPadMenuSize } = euiKeyPadMenuVariables(euiThemeContext);
  return {
    euiKeyPadMenuItem: css(
      'display:block;padding:',
      euiTheme.size.xs,
      ';',
      logicalSizeCSS(euiKeyPadMenuSize),
      ' border-radius:',
      euiTheme.border.radius.control,
      ';color:',
      euiTheme.colors.textParagraph,
      ';',
      euiCanAnimate,
      '{transition:background-color ',
      euiTheme.animation.fast,
      ' ease-in,box-shadow ',
      euiTheme.animation.fast,
      ' ease-in;};label:euiKeyPadMenuItem;'
    ),
    enabled: css(
      '&:is(:hover, :focus, :focus-within){cursor:pointer;text-decoration:underline;background-color:',
      euiTheme.colors.backgroundBaseInteractiveHover,
      ';',
      highContrastModeStyles(euiThemeContext, {
        // Use `outline` instead of border to avoid affecting absolutely positioned children
        preferred: `
            outline: ${euiTheme.border.width.thin} solid ${euiTheme.colors.primary};
          `
      }),
      ';}&:focus{box-shadow:none;background-color:',
      euiTheme.colors.backgroundBaseInteractiveHover,
      ';};label:enabled;'
    ),
    selected: css(
      'color:',
      euiTheme.colors.textHeading,
      ';',
      highContrastModeStyles(euiThemeContext, {
        preferred: `
          outline: ${euiTheme.border.width.thin} solid ${euiTheme.colors.primary};
        `
      }),
      ' &:is(*, :hover, :focus, :focus-within){color:',
      euiTheme.colors.textPrimary,
      ';background-color:',
      euiTheme.colors.backgroundBaseInteractiveSelect,
      ';',
      highContrastModeStyles(euiThemeContext, {
        // Skip checkable items (which render a <label> instead of <button>/<a>),
        // as they already have sufficient indication of state (checkbox or radio)
        preferred: `
            &:not(label) {
              outline: ${euiTheme.border.width.thick} solid ${euiTheme.colors.primary};
              outline-offset: 0;
            }
          `
      }),
      ';};label:selected;'
    ),
    disabled: {
      disabled: css(
        'cursor:not-allowed;color:',
        euiTheme.colors.textDisabled,
        ';',
        highContrastModeStyles(euiThemeContext, {
          none: `
            .euiKeyPadMenuItem__icon {
              svg * {
                fill: ${euiTheme.colors.textDisabled};
              }
            }
          `,
          forced: 'opacity: 0.5;'
        }),
        ';;label:disabled;'
      ),
      selected: css(
        'background-color:',
        euiTheme.colors.backgroundBaseDisabled,
        ';',
        highContrastModeStyles(euiThemeContext, {
          preferred: `
            &:not(label) {
              outline: ${euiTheme.border.width.thick} solid ${euiTheme.colors.textDisabled};
            }
          `
        }),
        ';;label:selected;'
      )
    }
  };
};

export const euiKeyPadMenuItemChildStyles = (
  euiThemeContext: EuiBorealisContext
) => {
  const euiTheme = euiThemeContext.euiTheme;
  const topRightChildren = `
    z-index: 3;
    position: absolute;
    ${logicalCSS('top', euiTheme.size.xs)}
    ${logicalCSS('right', euiTheme.size.xs)}
  `;
  return {
    euiKeyPadMenuItem__inner: css(
      logicalSizeCSS('100%'),
      ' display:flex;flex-direction:column;align-items:center;justify-content:center;position:relative;;label:euiKeyPadMenuItem__inner;'
    ),
    euiKeyPadMenuItem__icon: css(
      logicalCSS('margin-bottom', euiTheme.size.m),
      ' transform:translateY(2px);',
      euiCanAnimate,
      '{transition:transform ',
      euiTheme.animation.normal,
      ' ',
      euiTheme.animation.bounce,
      ';};label:euiKeyPadMenuItem__icon;'
    ),
    euiKeyPadMenuItem__label: css(
      euiFontSize(euiThemeContext, 'xs', undefined),
      ' font-weight:',
      euiTheme.font.weight.semiBold,
      ';text-align:center;;label:euiKeyPadMenuItem__label;'
    ),
    euiKeyPadMenuItem__betaBadge: css(
      topRightChildren,
      ';;label:euiKeyPadMenuItem__betaBadge;'
    ),
    euiKeyPadMenuItem__checkableInput: css(
      'position:absolute;',
      topRightChildren,
      ' transform:scale(.75);transform-origin:top right;;label:euiKeyPadMenuItem__checkableInput;'
    ),
    showCheckableInputOnInteraction: css(
      '.euiKeyPadMenuItem:not(:hover, :focus, :focus-within) &{',
      euiScreenReaderOnly(),
      ';};label:showCheckableInputOnInteraction;'
    ),
    hideCheckableInput: css(
      euiScreenReaderOnly(),
      ';;label:hideCheckableInput;'
    )
  };
};
