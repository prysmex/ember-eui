import { alignClasses, widthStyle } from '../-private/table.ts';

import type { TableAlignment, TableMobileOptions } from '../-private/table.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A cell of an `EuiTableRow`. */
export interface EuiTableRowCellSignature {
  Element: HTMLTableCellElement;
  Args: {
    /** `'left'`, `'right'` (numbers) or `'center'`. Defaults to `'left'`. */
    align?: TableAlignment;
    /** Cuts long text with an ellipsis instead of wrapping it. */
    truncateText?: boolean;
    /**
     * The content is only text (wrapped in a span that truncates or
     * wraps). Set `false` for components. Defaults to `true`.
     */
    textOnly?: boolean;
    /** Renders a `<th scope="row">`: the row's header. */
    setScopeRow?: boolean;
    /** Shows the content only while the row is hovered. */
    showOnHover?: boolean;
    /** The cell holds the row's actions. */
    hasActions?: boolean;
    /** The cell holds the row's expand button. */
    isExpander?: boolean;
    /** Vertical alignment: `'top'`, `'middle'` or `'bottom'`. Defaults to `'middle'`. */
    valign?: 'top' | 'middle' | 'bottom';
    /** Width, e.g. `100` (px) or `'20%'`. */
    width?: number | string;
    /**
     * On small screens: `{ show, only, header, enlarge, align,
     * truncateText }`. `header` labels the value in the row's card; the
     * `<:mobile>` block replaces the content there.
     */
    mobileOptions?: TableMobileOptions;
  };
  Blocks: {
    /** The content. */
    default: [];
    /** Different content on small screens. */
    mobile: [];
  };
}

function cellClasses(
  hasActions?: boolean,
  isExpander?: boolean,
  mobile: TableMobileOptions = {},
  valign = 'middle'
): string {
  return [
    'euiTableRowCell',
    hasActions && 'euiTableRowCell--hasActions',
    isExpander && 'euiTableRowCell--isExpander',
    mobile.only && 'euiTableRowCell--hideForDesktop',
    mobile.enlarge && 'euiTableRowCell--enlargeForMobile',
    `euiTableRowCell--${valign}`,
    mobile.show === false && 'euiTableRowCell--hideForMobile'
  ]
    .filter(Boolean)
    .join(' ');
}

function contentClasses(
  align?: TableAlignment,
  showOnHover?: boolean,
  truncateText?: boolean,
  textOnly?: boolean
): string {
  return [
    'euiTableCellContent',
    alignClasses(align),
    showOnHover && 'euiTableCellContent--showOnHover',
    truncateText && 'euiTableCellContent--truncateText',
    textOnly === false && 'euiTableCellContent--overflowingContent'
  ]
    .filter(Boolean)
    .join(' ');
}

function childClasses(textOnly?: boolean, showOnHover?: boolean): string {
  return [textOnly !== false && 'euiTableCellContent__text', showOnHover && 'euiTableCellContent__hoverItem']
    .filter(Boolean)
    .join(' ');
}

function isShown(mobile: TableMobileOptions = {}): boolean {
  return mobile.show !== false;
}

function mobileAlign(mobile: TableMobileOptions = {}, align?: TableAlignment): TableAlignment | undefined {
  return mobile.align ?? align;
}

function mobileTruncate(mobile: TableMobileOptions = {}, truncateText?: boolean): boolean | undefined {
  return mobile.truncateText ?? truncateText;
}

const EuiTableRowCell: TemplateOnlyComponent<EuiTableRowCellSignature> = <template>
  {{#let
    (contentClasses @align @showOnHover @truncateText @textOnly)
    (childClasses @textOnly @showOnHover)
    as |content child|
  }}
    {{#if @setScopeRow}}
      <th
        class={{cellClasses @hasActions @isExpander @mobileOptions @valign}}
        scope="row"
        style={{widthStyle @width}}
        ...attributes
      >
        {{#if (isShown @mobileOptions)}}
          {{#if @mobileOptions.header}}
            <div class="euiTableRowCell__mobileHeader euiTableRowCell--hideForDesktop">{{@mobileOptions.header}}</div>
          {{/if}}
        {{/if}}
        <div class={{content}}><span class={{child}}>{{yield}}</span></div>
      </th>
    {{else}}
      <td
        class={{cellClasses @hasActions @isExpander @mobileOptions @valign}}
        style={{widthStyle @width}}
        ...attributes
      >
        {{#if (isShown @mobileOptions)}}
          {{#if @mobileOptions.header}}
            <div class="euiTableRowCell__mobileHeader euiTableRowCell--hideForDesktop">{{@mobileOptions.header}}</div>
          {{/if}}
          {{#if (has-block "mobile")}}
            <div
              class="{{contentClasses
                  (mobileAlign @mobileOptions @align)
                  @showOnHover
                  (mobileTruncate @mobileOptions @truncateText)
                  @textOnly
                }} euiTableRowCell--hideForDesktop"
            ><span class={{child}}>{{yield to="mobile"}}</span></div>
            <div class="{{content}} euiTableRowCell--hideForMobile"><span class={{child}}>{{yield}}</span></div>
          {{else}}
            <div class={{content}}><span class={{child}}>{{yield}}</span></div>
          {{/if}}
        {{else}}
          <div class={{content}}><span class={{child}}>{{yield}}</span></div>
        {{/if}}
      </td>
    {{/if}}
  {{/let}}
</template>;

export default EuiTableRowCell;
