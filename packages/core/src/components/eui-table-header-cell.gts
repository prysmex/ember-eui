import Component from '@glimmer/component';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { on } from '@ember/modifier';
import { inject as service } from '@ember/service';

import { element } from 'ember-element-helper';

import { alignClasses, widthStyle } from '../-private/table.ts';
import EuiIcon from './eui-icon.gts';
import EuiInnerText from './eui-inner-text.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n';
import type { TableAlignment, TableMobileOptions } from '../-private/table.ts';

/**
 * A column header of an `EuiTable`. With `@onSort` it is a button that
 * shows the sort direction (`@isSorted`, `@isSortAscending`).
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
    /** More about the column, in its title and for screen readers. */
    description?: string;
    /** `scope` of the `<th>`. Defaults to `'col'`. */
    scope?: string;
    /** `{ show, only }` on small screens. */
    mobileOptions?: TableMobileOptions;
  };
  Blocks: {
    /** The column's name. */
    default: [];
  };
}

export default class EuiTableHeaderCell extends Component<EuiTableHeaderCellSignature> {
  @service declare euiI18n: EuiI18n;

  get classes(): string {
    const mobile = this.args.mobileOptions ?? {};

    return [
      'euiTableHeaderCell',
      mobile.only && 'euiTableHeaderCell--hideForDesktop',
      mobile.show === false && 'euiTableHeaderCell--hideForMobile'
    ]
      .filter(Boolean)
      .join(' ');
  }

  get contentClasses(): string {
    return ['euiTableCellContent', alignClasses(this.args.align)].filter(Boolean).join(' ');
  }

  get isSortable(): boolean {
    return Boolean(this.args.onSort || this.args.isSorted);
  }

  get ariaSort(): string | undefined {
    if (!this.isSortable) return undefined;
    if (!this.args.isSorted) return 'none';

    return this.args.isSortAscending ? 'ascending' : 'descending';
  }

  title = (innerText: string): string =>
    this.args.description
      ? this.euiI18n.lookupToken('euiTableHeaderCell.titleTextWithDesc', '{innerText}; {description}', {
          innerText,
          description: this.args.description
        })
      : innerText;

  <template>
    {{#let (element (if (has-block) "th" "td")) as |Cell|}}
      <Cell
        class={{this.classes}}
        scope={{if (has-block) (if @scope @scope "col")}}
        role="columnheader"
        aria-sort={{this.ariaSort}}
        aria-live={{if this.isSortable "polite"}}
        style={{widthStyle @width}}
        ...attributes
      >
        {{#if (and2 @onSort (not2 @readOnly))}}
          <button
            type="button"
            class="euiTableHeaderButton {{if @isSorted 'euiTableHeaderButton-isSorted'}}"
            data-test-subj="tableHeaderSortButton"
            {{on "click" (sortHandler @onSort)}}
          >
            <span class={{this.contentClasses}}>
              <EuiInnerText as |ref innerText|>
                <span
                  class="euiTableCellContent__text"
                  title={{this.title innerText}}
                  {{didInsert ref}}
                >{{yield}}</span>
              </EuiInnerText>
              {{#if @description}}
                <EuiScreenReaderOnly>{{@description}}</EuiScreenReaderOnly>
              {{/if}}
              {{#if @isSorted}}
                <EuiIcon
                  class="euiTableSortIcon"
                  @type={{if @isSortAscending "sortUp" "sortDown"}}
                  @size="m"
                />
              {{/if}}
            </span>
          </button>
        {{else}}
          <span class={{this.contentClasses}}>
            <EuiInnerText as |ref innerText|>
              <span
                class="euiTableCellContent__text"
                title={{this.title innerText}}
                {{didInsert ref}}
              >{{yield}}</span>
            </EuiInnerText>
            {{#if @description}}
              <EuiScreenReaderOnly>{{@description}}</EuiScreenReaderOnly>
            {{/if}}
            {{#if (and2 this.isSortable @isSorted)}}
              <EuiIcon
                class="euiTableSortIcon"
                @type={{if @isSortAscending "sortUp" "sortDown"}}
                @size="m"
              />
            {{/if}}
          </span>
        {{/if}}
      </Cell>
    {{/let}}
  </template>
}

function sortHandler(onSort?: (event: MouseEvent) => void): (event: MouseEvent) => void {
  return (event) => onSort?.(event);
}

function and2(a: unknown, b: unknown): boolean {
  return Boolean(a && b);
}

function not2(a: unknown): boolean {
  return !a;
}
