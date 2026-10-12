/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Hand port of EUI 123.1.0
 * `components/selectable/selectable_list/selectable_list.styles.js` and
 * `components/selectable/selectable_templates/selectable_template_sitewide.styles.js`.
 *
 * - `euiSelectableListStyles.euiSelectableList__list` is built upstream with
 *   `@emotion/css` (a class name injected into a global document cache, used
 *   by react-window). Here it is the same serialized style, composed into the
 *   provider-owned cache like every other slot.
 * - The sitewide meta colors come from `euiPaletteColorBlind()`, which reads
 *   the global `EUI_VIS_COLOR_STORE` the React provider fills with the
 *   theme's `colors.vis`. Ember has no such global, so this port reads the
 *   same colors from the theme it is given (as `token.ts` does).
 *
 * Everything else is upstream's code with its helpers imported from the
 * extracted upstream sources. The parity suite
 * (`scripts/eui-upstream-parity.test.mjs`) compares every slot with the
 * upstream modules in every color/contrast mode.
 */
import { mathWithUnits } from '@elastic/eui-theme-common';
import { serializeStyles } from '@emotion/serialize';

import {
  euiFocusRing as _euiFocusRing,
  euiFontSize,
  euiListItemVariables,
  euiTitle as _euiTitle,
  euiYScrollWithShadows as _euiYScrollWithShadows,
  logicalCSS,
  makeHighContrastColor as _makeHighContrastColor
} from './styles.generated.ts';

import type { SerializedStyles } from '@emotion/serialize';
import type { EuiBorealisContext } from './theme.ts';

// The generated helpers read optional parameters from `arguments`, so their
// inferred types drop them; these aliases restore upstream's signatures.
type Loose<R> = (...args: unknown[]) => R;
const euiFocusRing = _euiFocusRing as Loose<string>;
const euiTitle = _euiTitle as Loose<Record<string, unknown>>;
const euiYScrollWithShadows = _euiYScrollWithShadows as Loose<string>;
const makeHighContrastColor = _makeHighContrastColor as Loose<
  (themeOrBackground: unknown) => string
>;

const css = (...args: unknown[]): SerializedStyles =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

const fullHeight = css('flex-grow:1;label:fullHeight;');

export const euiSelectableListStyles = (euiThemeContext: EuiBorealisContext) => {
  const { euiTheme } = euiThemeContext;
  return {
    euiSelectableList: css(
      '&:has(:focus-visible){',
      euiFocusRing(euiThemeContext, 'outset'),
      ';};label:euiSelectableList;'
    ),
    fullHeight,
    bordered: css(
      'overflow:hidden;border:',
      euiTheme.border.thin,
      ';border-radius:',
      euiTheme.border.radius.panel,
      ';;label:bordered;'
    ),
    paddingSize: {
      s: css('padding:', euiTheme.size.s, ';;label:s;')
    },
    euiSelectableList__list: css(
      euiYScrollWithShadows(euiThemeContext, {
        hasAnimatedOverflowShadow: true
      }),
      ' &:focus,&>ul:focus{outline:none;};label:euiSelectableList__list;'
    )
  };
};

export const euiSelectableListGroupLabelStyles = (
  euiThemeContext: EuiBorealisContext
) => {
  const { euiTheme } = euiThemeContext;
  const itemVars = euiListItemVariables(euiThemeContext);
  const spacingVertical = euiTheme.size.s;
  const borderColor = euiTheme.components.selectableListItemBorderColor;
  return {
    groupLabel: css(
      euiTitle(euiThemeContext, 'xxxs'),
      ' position:relative;display:flex;align-items:center;gap:',
      itemVars.spacing.horizontal,
      ';',
      logicalCSS('padding-horizontal', itemVars.textPadding.horizontal),
      ' ',
      logicalCSS('padding-vertical', spacingVertical),
      ' &:not(:first-child){',
      logicalCSS(
        'padding-top',
        mathWithUnits([spacingVertical], (a: number) => a * 3)
      ),
      " &::before{content:'';position:absolute;z-index:-1;inset:0;inset-block-start:",
      spacingVertical,
      ';',
      logicalCSS(
        'border-top',
        `${euiTheme.border.width.thin} solid ${borderColor}`
      ),
      ';}};label:groupLabel;'
    )
  };
};

const sitewideRoot = css('display:block;label:euiSelectableTemplateSitewide;');

/** Upstream `euiPaletteColorBlind()` (one rotation) from the given theme. */
function visPalette(euiThemeContext: EuiBorealisContext): string[] {
  const vis = euiThemeContext.euiTheme.colors.vis as unknown as Record<
    string,
    string
  >;
  return Array.from({ length: 10 }, (_, i) => vis[`euiColorVis${i}`]!);
}

export const euiSelectableTemplateSitewideStyles = (
  euiThemeContext: EuiBorealisContext
) => {
  const { euiTheme } = euiThemeContext;
  const visColors = visPalette(euiThemeContext);
  const highContrast = (color: string) =>
    makeHighContrastColor(color)(euiTheme);
  return {
    euiSelectableTemplateSitewide: sitewideRoot,
    euiSelectableTemplateSitewide__optionMetasList: css(
      'display:block;',
      euiFontSize(euiThemeContext, 'xs', undefined),
      ' color:',
      euiTheme.colors.textSubdued,
      ';;label:euiSelectableTemplateSitewide__optionMetasList;'
    ),
    euiSelectableTemplateSitewide__optionMeta: css(
      "&:not(:last-of-type)::after{content:'•';",
      logicalCSS('margin-horizontal', euiTheme.size.xs),
      ' color:',
      euiTheme.colors.textSubdued,
      ';};label:euiSelectableTemplateSitewide__optionMeta;'
    ),
    metaTypes: {
      fontWeight: `
        font-weight: ${euiTheme.font.weight.medium};
      `,
      application: css(
        'color:',
        highContrast(visColors[1]!),
        ';;label:application;'
      ),
      deployment: css(
        'color:',
        highContrast(visColors[0]!),
        ';;label:deployment;'
      ),
      article: css('color:', highContrast(visColors[3]!), ';;label:article;'),
      case: css('color:', highContrast(visColors[9]!), ';;label:case;'),
      platform: css('color:', highContrast(visColors[5]!), ';;label:platform;')
    }
  };
};

export const euiSelectableTemplateSitewidePopoverStyles = (
  euiThemeContext: EuiBorealisContext
) => {
  const { euiTheme } = euiThemeContext;
  return {
    euiSelectableTemplateSitewide__popover: css(
      'color:',
      euiTheme.colors.textParagraph,
      ';;label:euiSelectableTemplateSitewide__popover;'
    )
  };
};

/** Meta types with upstream colors. */
export const SITEWIDE_META_TYPES = [
  'application',
  'deployment',
  'article',
  'case',
  'platform'
] as const;
