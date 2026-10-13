import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import {
  BOX_SIZING,
  CELL_RESET,
  buttonReset,
  cellContentStyles,
  tableContext,
  widthStyle
} from '../-private/table.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiTableCellContentStyles,
  euiTableHeaderFooterCellStyles,
  euiTextTruncate
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';
import EuiInnerText from './eui-inner-text.gts';
import EuiIconTip from './eui-icon-tip.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { EuiIconTipSignature } from './eui-icon-tip';
import type EuiI18n from '../services/eui-i18n';
import type { TableAlignment, TableMobileOptions } from '../-private/table.ts';

/** An icon with a tooltip next to the column name (upstream `tooltipProps`). */
export interface EuiTableHeaderCellTooltipProps {
  /** The main content of the tooltip. */
  content: string;
  /** The icon type. Defaults to `'question'`. */
  icon?: string;
  /** Props of the icon: `{ className }`. */
  iconProps?: EuiIconTipSignature['Args']['iconProps'];
  /** More arguments of the tooltip. */
  tooltipProps?: {
    position?: 'top' | 'right' | 'bottom' | 'left';
    title?: string;
    delay?: 'regular' | 'long';
    anchorClassName?: string;
  };
}

/**
 * A column header of an `EuiTable`. With `@onSort` it is a button that
 * shows the sort direction (`@isSorted`, `@isSortAscending`), or a
 * "sortable" icon while the column is not sorted.
 */
export interface EuiTableHeaderCellSignature {
  Element: HTMLTableCellElement;
  Args: {
    /** `'left'`, `'right'` (numbers) or `'center'`. Defaults to `'left'`. */
    align?: TableAlignment;
    /** Makes the header a button sorting the column. */
    onSort?: (event: MouseEvent) => void;
    /** The table is sorted by this column: shows the direction. */
    isSorted?: boolean;
    /** Ascending order (arrow up); descending otherwise. */
    isSortAscending?: boolean;
    /** Shows the sort state without the button. */
    readOnly?: boolean;
    /** Width, e.g. `100` (px) or `'20%'`. */
    width?: number | string;
    /** Min width, e.g. `100` (px). */
    minWidth?: number | string;
    /** Max width, e.g. `'30%'`. */
    maxWidth?: number | string;
    /** More about the column, in its title and for screen readers. */
    description?: string;
    /** `scope` of the `<th>`. Defaults to `'col'`. */
    scope?: string;
    /** `{ show, only }` for the cards layout. */
    mobileOptions?: TableMobileOptions;
    /**
     * Adds an icon with a tooltip next to the name. In a sortable header
     * the icon is plain and the tooltip shows on the whole sort button.
     */
    tooltipProps?: EuiTableHeaderCellTooltipProps;
  };
  Blocks: {
    /** The column's name. */
    default: [];
  };
}

/** Shows the tooltip on the whole sort button (upstream wraps it in `EuiToolTip`). */
const MaybeTooltip: TemplateOnlyComponent<{
  Args: { tooltipProps?: EuiTableHeaderCellTooltipProps };
  Blocks: { default: [] };
}> = <template>
  {{#if @tooltipProps}}
    <EuiToolTip
      @content={{@tooltipProps.content}}
      @position={{@tooltipProps.tooltipProps.position}}
      @title={{@tooltipProps.tooltipProps.title}}
      @delay={{@tooltipProps.tooltipProps.delay}}
      @anchorClassName={{@tooltipProps.tooltipProps.anchorClassName}}
      @display="block"
    >{{yield}}</EuiToolTip>
  {{else}}
    {{yield}}
  {{/if}}
</template>;

const TRUNCATE = euiTextTruncate();

export default class EuiTableHeaderCell extends Component<EuiTableHeaderCellSignature> {
  @service declare euiI18n: EuiI18n;

  /** Upstream renders nothing for cells hidden in the current layout. */
  get isRendered(): boolean {
    const mobile = this.args.mobileOptions ?? {};
    return tableContext(this).isResponsive
      ? mobile.show !== false
      : !mobile.only;
  }

  get canSort(): boolean {
    return Boolean(this.args.onSort && !this.args.readOnly);
  }

  /** Upstream: the sorted direction, `none` if sortable, else no attribute. */
  get ariaSort(): string | undefined {
    if (this.args.isSorted) {
      return this.args.isSortAscending ? 'ascending' : 'descending';
    }
    return this.canSort ? 'none' : undefined;
  }

  get isSortable(): boolean {
    return Boolean(this.args.onSort || this.args.isSorted);
  }

  @cached
  get style() {
    return widthStyle(this.args.width, this.args.minWidth, this.args.maxWidth);
  }

  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableHeaderFooterCellStyles);
    const content = useEuiBorealisStyles(context, euiTableCellContentStyles);
    return {
      cell: euiClass(context, CELL_RESET, styles.euiTableHeaderCell),
      button: euiClass(
        context,
        buttonReset(context.upstream),
        styles.euiTableHeaderCell__button
      ),
      content: euiClass(
        context,
        BOX_SIZING,
        ...cellContentStyles(content, {
          align: this.args.align,
          // upstream passes `null`: neither truncates nor breaks words
          truncateText: null,
          isResponsive: tableContext(this).isResponsive
        }),
        styles.euiTableHeaderCell__content
      ),
      text: euiClass(context, TRUNCATE)
    };
  }

  title = (innerText: string): string =>
    this.args.description
      ? this.euiI18n.lookupToken(
          'euiTableHeaderCell.titleTextWithDesc',
          '{innerText}; {description}',
          { innerText, description: this.args.description }
        )
      : innerText;

  <template>
    {{#if this.isRendered}}
      {{#let (element (if (has-block) "th" "td")) as |Cell|}}
        <Cell
          class="euiTableHeaderCell {{this.styles.cell}}"
          scope={{if (has-block) (if @scope @scope "col")}}
          role="columnheader"
          aria-sort={{this.ariaSort}}
          aria-live={{if this.isSortable "polite"}}
          style={{this.style}}
          ...attributes
        >
          {{#if this.canSort}}
            <MaybeTooltip @tooltipProps={{@tooltipProps}}>
              <button
                type="button"
                class="euiTableHeaderButton
                  {{if @isSorted 'euiTableHeaderButton-isSorted'}}
                  {{this.styles.button}}"
                data-test-subj="tableHeaderSortButton"
                {{on "click" (sortHandler @onSort)}}
              >
                <span class="euiTableCellContent {{this.styles.content}}">
                  <EuiInnerText as |ref innerText|>
                    <span
                      class="eui-textTruncate {{this.styles.text}}"
                      title={{this.title innerText}}
                      {{didInsert ref}}
                    >{{yield}}</span>
                  </EuiInnerText>
                  {{#if @description}}
                    <EuiScreenReaderOnly><span>{{@description}}</span></EuiScreenReaderOnly>
                  {{/if}}
                  {{#if @tooltipProps}}
                    <EuiIcon
                      class="euiTableSortIcon"
                      @type={{if @tooltipProps.icon @tooltipProps.icon "question"}}
                      @size="m"
                      @color="subdued"
                      @iconClasses={{@tooltipProps.iconProps.className}}
                    />
                  {{/if}}
                  {{#if @isSorted}}
                    <EuiIcon
                      class="euiTableSortIcon"
                      @type={{if @isSortAscending "sortUp" "sortDown"}}
                      @size="m"
                    />
                  {{else}}
                    <EuiIcon
                      class="euiTableSortIcon euiTableSortIcon--sortable"
                      @type="sortable"
                      @size="m"
                      @color="subdued"
                    />
                  {{/if}}
                </span>
              </button>

            </MaybeTooltip>
          {{else}}
            <div class="euiTableCellContent {{this.styles.content}}">
              <EuiInnerText as |ref innerText|>
                <span
                  class="eui-textTruncate {{this.styles.text}}"
                  title={{this.title innerText}}
                  {{didInsert ref}}
                >{{yield}}</span>
              </EuiInnerText>
              {{#if @description}}
                <EuiScreenReaderOnly><span>{{@description}}</span></EuiScreenReaderOnly>
              {{/if}}
              {{#if @tooltipProps}}
                <EuiIconTip
                  @content={{@tooltipProps.content}}
                  @type={{if @tooltipProps.icon @tooltipProps.icon "question"}}
                  @position={{@tooltipProps.tooltipProps.position}}
                  @title={{@tooltipProps.tooltipProps.title}}
                  @delay={{@tooltipProps.tooltipProps.delay}}
                  @anchorClassName={{@tooltipProps.tooltipProps.anchorClassName}}
                  @iconProps={{@tooltipProps.iconProps}}
                  @size="m"
                  @color="subdued"
                  @display="block"
                />
              {{/if}}
              {{#if @isSorted}}
                <EuiIcon
                  class="euiTableSortIcon"
                  @type={{if @isSortAscending "sortUp" "sortDown"}}
                  @size="m"
                />
              {{/if}}
            </div>
          {{/if}}
        </Cell>
      {{/let}}
    {{/if}}
  </template>
}

function sortHandler(
  onSort?: (event: MouseEvent) => void
): (event: MouseEvent) => void {
  return (event) => onSort?.(event);
}
