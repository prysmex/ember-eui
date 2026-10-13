import { getContext } from 'ember-provide-consume-context';

import type { EuiThemeContext } from '../utils/emotion/context.ts';
import type { SerializedStyles } from '@emotion/serialize';

/**
 * What an EuiListGroup shares with the items in its block (upstream clones
 * `color` and, when set, `showToolTip` into its children; the item's own
 * args win). `wrapText` only reaches `listItems` upstream.
 */
export interface EuiListGroupContext {
  readonly color: string | undefined;
  readonly showToolTips: boolean | undefined;
}

/** What an EuiDescriptionList shares with its titles and descriptions. */
export interface EuiDescriptionListContext {
  /** `row`, `inline`, `column` or `responsiveColumn`. */
  readonly type: 'row' | 'inline' | 'column' | 'responsiveColumn';
  readonly compressed: boolean;
  readonly textStyle: 'normal' | 'reverse';
  readonly align: 'left' | 'center';
  readonly rowGutterSize: 's' | 'm';
}

export const EUI_LIST_GROUP_CONTEXT = '@ember-eui/core/list-group' as const;
export const EUI_DESCRIPTION_LIST_CONTEXT =
  '@ember-eui/core/description-list' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_LIST_GROUP_CONTEXT]: EuiListGroupContext;
    [EUI_DESCRIPTION_LIST_CONTEXT]: EuiDescriptionListContext;
  }
}

/** Upstream `contextDefaults` of the description list context. */
const DESCRIPTION_LIST_DEFAULTS: EuiDescriptionListContext = {
  type: 'row',
  compressed: false,
  textStyle: 'normal',
  align: 'left',
  rowGutterSize: 's'
};

export function listGroupContext(
  component: object
): EuiListGroupContext | undefined {
  return getContext(component, EUI_LIST_GROUP_CONTEXT);
}

/** Read in a getter so changes of the parent list stay tracked. */
export function descriptionListContext(
  component: object
): EuiDescriptionListContext {
  return (
    getContext(component, EUI_DESCRIPTION_LIST_CONTEXT) ??
    DESCRIPTION_LIST_DEFAULTS
  );
}

/** Width where upstream's `responsiveColumn` (`xs`/`s` → row) becomes a column. */
export function columnMinWidth(context: EuiThemeContext): number {
  return context.upstream.euiTheme.breakpoint.m;
}

/**
 * Wraps serialized upstream slots in a media query. Upstream switches the
 * type with a resize hook; a media query gives the same result per width
 * without JavaScript.
 */
export function atMedia(
  query: string,
  ...styles: (SerializedStyles | string | false | undefined)[]
): string {
  const body = styles
    .filter((style): style is SerializedStyles | string => Boolean(style))
    .map((style) => (typeof style === 'string' ? style : style.styles))
    .join('');
  return body ? `@media ${query}{${body}}` : '';
}

export function rowQuery(context: EuiThemeContext): string {
  return `only screen and (max-width: ${columnMinWidth(context) - 1}px)`;
}

export function columnQuery(context: EuiThemeContext): string {
  return `only screen and (min-width: ${columnMinWidth(context)}px)`;
}
