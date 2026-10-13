import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';

import {
  BOX_SIZING,
  CELL_RESET,
  cellContentStyles,
  tableContext,
  widthStyle
} from '../-private/table.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiTableCellContentStyles,
  euiTableRowCellStyles
} from '../utils/eui/styles.generated.ts';
import { euiTableStickyCellStyles } from '../utils/eui/table.ts';
import TableNode from '../-private/table-node.gts';
import cssStyle from '../-private/css-style.ts';
import EuiTextBlockTruncate from './eui-text-block-truncate.gts';

import type {
  TableAlignment,
  TableMobileOptions,
  TableTruncateText
} from '../-private/table.ts';
import type { EuiTableStickyCellOptions } from '../utils/eui/table.ts';
import type { EuiTableNode } from '../-private/table-node.gts';
import type { CSSObject } from '@emotion/css/create-instance';

/** Inline styles of a cell: an object of CSS properties, or a string. */
export type EuiTableRowCellStyle =
  | string
  | Record<string, string | number | null | undefined>;

/** A cell of an `EuiTableRow`. */
export interface EuiTableRowCellSignature {
  Element: HTMLTableCellElement;
  Args: {
    /** `'left'`, `'right'` (numbers) or `'center'`. Defaults to `'left'`. */
    align?: TableAlignment;
    /**
     * `true` cuts long text on one line with an ellipsis; `{ lines: n }`
     * clamps it to `n` lines. Otherwise long words break (upstream
     * default).
     */
    truncateText?: TableTruncateText;
    /**
     * The content is only text (wrapped in a span that truncates or
     * wraps). Set `false` for components. Defaults to `true`.
     */
    textOnly?: boolean;
    /** Renders a `<th scope="row">`: the row's header. */
    setScopeRow?: boolean;
    /**
     * Shows the content only while the row is hovered or the cell has
     * focus (always shown in the cards layout). Upstream's
     * `euiBasicTableAction-showOnHover`.
     */
    showOnHover?: boolean;
    /**
     * The cell holds the row's actions (`true`: icon actions in the cards
     * layout's right column; `'custom'`: other content on its own line).
     */
    hasActions?: boolean | 'custom';
    /** The cell holds the row's expand button. */
    isExpander?: boolean;
    /**
     * Vertical alignment: `'top'`, `'middle'`, `'bottom'` or `'baseline'`.
     * Defaults to `'middle'`.
     */
    valign?: 'top' | 'middle' | 'bottom' | 'baseline';
    /** Width, e.g. `100` (px) or `'20%'`. */
    width?: number | string;
    /** Min width, e.g. `100` (px). */
    minWidth?: number | string;
    /** Max width, e.g. `'30%'`. */
    maxWidth?: number | string;
    /**
     * Sticks the cell to a side of the table (`{ side: 'start' | 'end' }`)
     * while it scrolls inline; only for the first or last column, and not
     * in the cards layout. With `@hasBackground={{false}}` on the table,
     * set `--euiTableCellStickyBackgroundColor` to the background behind
     * it. Upstream beta.
     */
    sticky?: EuiTableStickyCellOptions;
    /**
     * In the cards layout: `{ show, only, header, enlarge, align,
     * truncateText, textOnly, width, minWidth, maxWidth }`. `header`
     * labels the value in the row's card; the `<:mobile>` block replaces
     * the content there.
     */
    mobileOptions?: TableMobileOptions;
    /**
     * Inline styles merged under the cell's own width styles (upstream's
     * `style` prop). A `style` attribute replaces them instead.
     */
    style?: EuiTableRowCellStyle;
  };
  Blocks: {
    /** The content. */
    default: [];
    /** Different content in the cards layout. */
    mobile: [];
    /**
     * Content after the cell's content wrapper (upstream `append`), e.g. the
     * hidden tabular copy markers of `EuiBasicTable`.
     */
    append: [];
  };
}

/** Ember's `@showOnHover` reveals its content on any row hover. */
const SHOW_ON_HOVER: CSSObject = {
  '.euiTableRow:hover &, &:focus-within': {
    '.euiBasicTableAction-showOnHover': { opacity: 1 }
  }
};

export default class EuiTableRowCell extends Component<EuiTableRowCellSignature> {
  get isResponsive(): boolean {
    return tableContext(this).isResponsive;
  }

  get mobile(): TableMobileOptions {
    return this.args.mobileOptions ?? {};
  }

  /** Upstream renders nothing for hidden cells. */
  get isRendered(): boolean {
    return this.isResponsive
      ? this.mobile.show !== false
      : !this.mobile.only;
  }

  get tagName(): 'th' | 'td' {
    return this.args.setScopeRow ? 'th' : 'td';
  }

  get mobileHeader(): EuiTableNode | boolean | undefined {
    return this.isResponsive ? this.mobile.header : undefined;
  }

  get textOnly(): boolean {
    const textOnly = this.args.textOnly ?? true;
    return this.isResponsive ? (this.mobile.textOnly ?? textOnly) : textOnly;
  }

  get truncateText(): TableTruncateText {
    const truncate = this.args.truncateText ?? false;
    return this.isResponsive ? (this.mobile.truncateText ?? truncate) : truncate;
  }

  /** Lines of a multi-line clamp (`truncateText: { lines }`). */
  get truncateLines(): number | undefined {
    const truncate = this.truncateText;
    return typeof truncate === 'object' && truncate?.lines
      ? truncate.lines
      : undefined;
  }

  get stickySide(): 'start' | 'end' | undefined {
    return this.isResponsive ? undefined : this.args.sticky?.side;
  }

  get hasActionsOrExpander(): boolean | 'custom' {
    return this.args.hasActions || Boolean(this.args.isExpander);
  }

  /** The text span (upstream renders it for text or truncated content). */
  get wrapsContent(): boolean {
    return (
      this.textOnly ||
      this.truncateText === true ||
      Boolean(this.args.showOnHover)
    );
  }

  get textClass(): string {
    return [
      (this.textOnly || this.truncateText === true || this.truncateLines) &&
        'euiTableCellContent__text',
      this.args.showOnHover && 'euiBasicTableAction-showOnHover'
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get style() {
    const widths = this.widthStyle;
    const base = this.args.style;
    if (!base) return widths;
    const baseText = typeof base === 'string' ? base : cssStyle(base)?.toString();
    if (!baseText) return widths;
    // upstream `resolveWidthPropsAsStyle(style, widths)`: widths win
    return htmlSafe(widths ? `${baseText}; ${widths.toString()}` : baseText);
  }

  get widthStyle() {
    const { width, minWidth, maxWidth, hasActions, isExpander } = this.args;
    if (!this.isResponsive) return widthStyle(width, minWidth, maxWidth);
    // In cards, actions are shifted to a right column via CSS
    if (hasActions || isExpander) return undefined;
    return widthStyle(
      this.mobile.width,
      this.mobile.minWidth,
      this.mobile.maxWidth
    );
  }

  @cached
  get cellClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableRowCellStyles);
    const { setScopeRow, isExpander, hasActions, showOnHover } = this.args;
    const valign = this.args.valign ?? 'middle';
    // Same order as upstream's `cssStyles`.
    const css = [
      CELL_RESET,
      styles.euiTableRowCell,
      setScopeRow ? styles.rowHeader : undefined,
      isExpander ? styles.isExpander : undefined,
      hasActions ? styles.hasActions : undefined,
      styles[valign],
      ...(this.isResponsive
        ? [
            styles.mobile.mobile,
            this.mobile.enlarge ? styles.mobile.enlarge : undefined,
            hasActions === 'custom' ? styles.mobile.customActions : undefined,
            hasActions === true ? styles.mobile.actions : undefined,
            isExpander ? styles.mobile.expander : undefined
          ]
        : [
            styles.desktop.desktop,
            hasActions || showOnHover ? styles.desktop.actions : undefined,
            showOnHover ? SHOW_ON_HOVER : undefined,
            ...this.stickyStyles
          ])
    ];

    return [
      'euiTableRowCell',
      hasActions && 'euiTableRowCell--hasActions',
      isExpander && 'euiTableRowCell--isExpander',
      euiClass(context, ...css)
    ]
      .filter(Boolean)
      .join(' ');
  }

  get stickyStyles(): EuiCss[] {
    const { sticky } = this.args;
    if (!sticky) return [];
    const styles = useEuiBorealisStyles(
      getEuiThemeContext(this),
      euiTableStickyCellStyles
    );
    return [styles.root, styles.side[sticky.side]];
  }

  @cached
  get mobileHeaderClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableRowCellStyles);
    return euiClass(context, BOX_SIZING, styles.euiTableRowCell__mobileHeader);
  }

  @cached
  get contentClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableCellContentStyles);
    const align = this.isResponsive
      ? (this.mobile.align ?? 'left')
      : this.args.align;
    return euiClass(
      context,
      BOX_SIZING,
      ...cellContentStyles(styles, {
        align,
        // upstream: `true` truncates, `false` breaks words, a clamp neither
        truncateText:
          typeof this.truncateText === 'boolean' ? this.truncateText : null,
        hasActions: this.hasActionsOrExpander,
        isResponsive: this.isResponsive
      })
    );
  }

  <template>
    {{#if this.isRendered}}
      {{#let (element this.tagName) as |Cell|}}
        <Cell
          class={{this.cellClass}}
          scope={{if @setScopeRow "row"}}
          style={{this.style}}
          data-sticky={{this.stickySide}}
          ...attributes
        >
          {{#if this.mobileHeader}}
            <div
              class="euiTableRowCell__mobileHeader {{this.mobileHeaderClass}}"
            ><TableNode @node={{this.mobileHeader}} /></div>
          {{/if}}
          <div class="euiTableCellContent {{this.contentClass}}">
            {{#if this.truncateLines}}
              <EuiTextBlockTruncate
                @lines={{this.truncateLines}}
                @cloneElement={{true}}
                as |clamp|
              >
                <span class={{this.textClass}} {{clamp}}>
                  {{~#if (useMobileBlock this.isResponsive (has-block "mobile"))~}}
                    {{yield to="mobile"}}
                  {{~else~}}
                    {{yield}}
                  {{~/if~}}
                </span>
              </EuiTextBlockTruncate>
            {{else if this.wrapsContent}}
              <span class={{this.textClass}}>
                {{~#if (useMobileBlock this.isResponsive (has-block "mobile"))~}}
                  {{yield to="mobile"}}
                {{~else~}}
                  {{yield}}
                {{~/if~}}
              </span>
            {{else if (useMobileBlock this.isResponsive (has-block "mobile"))}}
              {{yield to="mobile"}}
            {{else}}
              {{yield}}
            {{/if}}
          </div>
          {{yield to="append"~}}
        </Cell>
      {{/let}}
    {{/if}}
  </template>
}

function useMobileBlock(isResponsive: boolean, hasMobileBlock: boolean): boolean {
  return isResponsive && hasMobileBlock;
}
