import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { modifier } from 'ember-modifier';
import { eq } from 'ember-truth-helpers';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiFlexGridStyles } from '../utils/eui/styles.generated.ts';
import { euiFlexRootReset } from './eui-flex-item.gts';

import type { CSSObject } from '@emotion/css/create-instance';
import type { EuiBorealisContext } from '../utils/eui/theme.ts';

export type EuiFlexGridDirection = 'row' | 'column';
export type EuiFlexGridGutterSize = 'none' | 's' | 'm' | 'l' | 'xl';
export type EuiFlexGridAlignItems =
  | 'stretch'
  | 'start'
  | 'end'
  | 'center'
  | 'baseline';

/**
 * Ember-only `@columns={{0}}`: items keep their own width and wrap. Upstream
 * removed this mode; it is kept so existing callers do not collapse into a
 * single column.
 */
function euiFlexGridWrap(
  context: EuiBorealisContext,
  responsive: boolean
): CSSObject {
  const breakpoint = context.euiTheme.breakpoint.m as number;
  return {
    display: 'flex',
    flexWrap: 'wrap',
    '& > .euiFlexItem': { flexGrow: 0, flexBasis: 'auto' },
    ...(responsive
      ? {
          [`@media only screen and (max-width: ${breakpoint - 1}px)`]: {
            flexDirection: 'column',
            '& > .euiFlexItem': { inlineSize: '100%' }
          }
        }
      : {})
  };
}

/**
 * Upstream sets `grid-template-rows: repeat(ceil(children / columns), 1fr)`
 * inline for column direction. Ember counts element children and keeps the
 * count current as items are added or removed.
 */
const columnRows = modifier(
  (
    element: Element,
    [direction, columns]: [EuiFlexGridDirection, number]
  ) => {
    const target = element as HTMLElement;
    if (direction !== 'column' || !(columns > 0)) return;
    const update = () => {
      const rows = Math.ceil(target.children.length / columns);
      target.style.gridTemplateRows = `repeat(${rows}, 1fr)`;
    };
    update();
    const observer = new MutationObserver(update);
    observer.observe(target, { childList: true });
    return () => {
      observer.disconnect();
      target.style.removeProperty('grid-template-rows');
    };
  }
);

export interface EuiFlexGridSignature {
  Element: HTMLDivElement | any;
  Args: {
    /**
     * Passes the HTML tag to the wrapping element. Defaults to `'div'`.
     */
    tagName?: string;
    /**
     * `'row'` fills the grid row by row, `'column'` column by column.
     * Defaults to `'row'`.
     */
    direction?: EuiFlexGridDirection;
    /**
     * Number of columns, `1` to `4` (upstream default `1`). The Ember-only
     * `0` lets the items wrap at their own width. Defaults to `1`.
     */
    columns?: number;
    /**
     * Space between items (CSS `gap`): `'none'`, `'s'` (8px), `'m'` (16px),
     * `'l'` (24px) or `'xl'` (32px). Defaults to `'l'`.
     */
    gutterSize?: EuiFlexGridGutterSize;
    /**
     * Cross axis alignment of the items in their cells: `'stretch'`,
     * `'start'`, `'end'`, `'center'` or `'baseline'`. Defaults to `'stretch'`.
     */
    alignItems?: EuiFlexGridAlignItems;
    /**
     * Below the theme's `m` breakpoint (767px in Borealis), stacks the items
     * in one column. Defaults to `true`.
     */
    responsive?: boolean;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /** The `EuiFlexItem`s, laid out in a grid. */
    default: [];
  };
}

export default class EuiFlexGrid extends Component<EuiFlexGridSignature> {
  columnRows = columnRows;

  get tagName() {
    return this.args.tagName ?? 'div';
  }

  get direction() {
    return this.args.direction ?? 'row';
  }

  get columns() {
    return this.args.columns ?? 1;
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlexGridStyles);
    const responsive = this.args.responsive !== false;
    // Same order as upstream's `cssStyles`.
    return euiClass(
      context,
      euiFlexRootReset(this.tagName),
      styles.euiFlexGrid,
      styles.gutterSizes[this.args.gutterSize ?? 'l'],
      styles.direction[this.direction],
      styles.alignItems[this.args.alignItems ?? 'stretch'],
      this.columns === 0
        ? euiFlexGridWrap(context.upstream, responsive)
        : styles.columnCount[
            String(this.columns) as keyof typeof styles.columnCount
          ],
      responsive && this.columns !== 0 ? styles.responsive : undefined,
      this.args.css
    );
  }

  <template>
    {{#if (eq this.tagName "div")}}
      <div
        class="euiFlexGrid {{this.classes}}"
        {{this.columnRows this.direction this.columns}}
        ...attributes
      >
        {{yield}}
      </div>
    {{else}}
      {{#let (element this.tagName) as |Tag|}}
        <Tag
          class="euiFlexGrid {{this.classes}}"
          {{this.columnRows this.direction this.columns}}
          ...attributes
        >
          {{yield}}
        </Tag>
      {{/let}}
    {{/if}}
  </template>
}
