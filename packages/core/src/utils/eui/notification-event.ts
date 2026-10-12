/*
 * Borealis styles for EuiNotificationEvent and its parts.
 *
 * EUI 123.1.0 has no notification event component (upstream removed
 * `EuiNotificationEvent` together with its Sass), so there is no factory to
 * extract. These styles keep the layout of the last upstream release (a
 * flex row: read indicator, then meta / title / messages / primary action;
 * a context menu button pinned to the top end; bold unread titles) and take
 * every value from the resolved Borealis theme, so they follow providers,
 * `@borealisOverrides`, dark mode and high contrast like the extracted
 * factories. Use them through `useEuiBorealisStyles`, which memoizes them
 * per theme.
 */
import type { CSSObject } from '@emotion/css/create-instance';
import type { EuiBorealisContext } from './theme.ts';

export interface EuiNotificationEventStyles {
  euiNotificationEvent: CSSObject;
  readButton: CSSObject;
  content: CSSObject;
  title: CSSObject;
  titleIsRead: CSSObject;
  primaryAction: CSSObject;
  meta: CSSObject;
  metaHasContextMenu: CSSObject;
  metaSection: CSSObject;
  metaIcon: CSSObject;
  metaContextMenu: CSSObject;
  messages: CSSObject;
  accordionButton: CSSObject;
  accordionContent: CSSObject;
  metaTime: CSSObject;
  readIconIsRead: CSSObject;
  readButtonIsRead: CSSObject;
}

type Theme = EuiBorealisContext['euiTheme'];
type FontScale = keyof Theme['font']['scale'];

/**
 * Upstream `euiFontSize(context, scale)` in rem (EUI 123
 * `global_styling/functions/typography.js`), which the generator does not
 * export: relative to the body scale, with the baseline-snapped line height.
 */
function fontSize({ base, font }: Theme, scale: FontScale): CSSObject {
  const numerator = base * font.scale[scale];
  const denominator = base * font.scale[font.body.scale as FontScale];
  const multiplier =
    numerator <= base
      ? font.lineHeightMultiplier
      : font.lineHeightMultiplier * 0.833;
  const lineHeight =
    Math.floor(Math.round(numerator * multiplier) / font.baseline) *
    font.baseline;
  return {
    fontSize: `${(numerator / denominator).toFixed(4)}rem`,
    lineHeight: `${(lineHeight / denominator).toFixed(4)}rem`
  };
}

export function euiNotificationEventStyles({
  euiTheme,
  highContrastMode
}: EuiBorealisContext): EuiNotificationEventStyles {
  const { size, border, colors, font } = euiTheme;
  return {
    euiNotificationEvent: {
      boxSizing: 'border-box',
      display: 'flex',
      padding: size.base,
      // A separator between consecutive events only.
      '& + &, & + .euiNotificationEvent': {
        borderBlockStart: border.thin
      },
      label: 'euiNotificationEvent'
    },
    readButton: {
      flexShrink: 0,
      marginInlineEnd: size.s,
      label: 'readButton'
    },
    content: {
      display: 'flex',
      flexDirection: 'column',
      gap: size.s,
      flex: 1,
      minInlineSize: 0,
      label: 'content'
    },
    title: {
      // the title is an `EuiTitle` `xs` heading; unread titles are bold
      fontWeight: font.weight.bold,
      overflowWrap: 'anywhere',
      label: 'title'
    },
    titleIsRead: {
      fontWeight: font.weight.regular,
      label: 'isRead'
    },
    primaryAction: {
      display: 'flex',
      label: 'primaryAction'
    },
    meta: {
      position: 'relative',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: size.s,
      minBlockSize: size.l,
      label: 'euiNotificationEventMeta'
    },
    metaHasContextMenu: {
      // room for the context menu button (xs icon button) in the end corner
      paddingInlineEnd: `calc(${size.l} + ${size.xs})`,
      label: 'hasContextMenu'
    },
    metaSection: {
      display: 'flex',
      alignItems: 'center',
      gap: size.s,
      minInlineSize: 0,
      '&:first-child': { flex: 1 },
      label: 'section'
    },
    metaIcon: {
      flexShrink: 0,
      label: 'icon'
    },
    metaContextMenu: {
      position: 'absolute',
      insetBlockStart: 0,
      insetInlineEnd: 0,
      label: 'contextMenuWrapper'
    },
    messages: {
      display: 'flex',
      flexDirection: 'column',
      gap: size.xs,
      label: 'euiNotificationEventMessages'
    },
    accordionButton: {
      ...fontSize(euiTheme, 'xs'),
      color: colors.textPrimary,
      label: 'accordionButton'
    },
    accordionContent: {
      display: 'flex',
      flexDirection: 'column',
      gap: size.xs,
      paddingBlockStart: size.xs,
      label: 'accordionContent'
    },
    metaTime: {
      ...fontSize(euiTheme, 'xs'),
      color: colors.textSubdued,
      whiteSpace: 'nowrap',
      label: 'time'
    },
    // Unread: a filled dot (the icon's color). Read: a hollow dot outlined
    // with the subdued text color; composed into EuiIcon's class (`@css`).
    readIconIsRead: {
      fill: 'transparent',
      stroke: highContrastMode ? colors.textParagraph : colors.textSubdued,
      strokeWidth: '1px',
      label: 'isRead'
    },
    // The same on the read button's icon, composed into EuiButtonIcon's
    // class (`@css`), after its own `.euiButtonIcon__icon` rule.
    readButtonIsRead: {
      '& .euiButtonIcon__icon': {
        fill: 'transparent',
        stroke: highContrastMode ? colors.textParagraph : colors.textSubdued,
        strokeWidth: '1px'
      },
      label: 'isRead'
    }
  };
}
