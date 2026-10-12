import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { provide } from 'ember-provide-consume-context';

import {
  atMedia,
  columnQuery,
  EUI_DESCRIPTION_LIST_CONTEXT,
  rowQuery
} from '../-private/eui-list-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiDescriptionListStyles } from '../utils/eui/styles.generated.ts';
import EuiDescriptionListDescription from './eui-description-list-description.gts';
import EuiDescriptionListTitle from './eui-description-list-title.gts';

import type { EuiDescriptionListContext } from '../-private/eui-list-context.ts';
import type { CSSInterpolation } from '@emotion/css/create-instance';

export type EuiDescriptionListType =
  | 'row'
  | 'inline'
  | 'column'
  | 'responsiveColumn';

export interface EuiDescriptionListSignature {
  Element: HTMLElement;
  Args: {
    /** Smaller text. */
    compressed?: boolean;
    /**
     * `'row'` stacks each title above its description, `'column'` puts them
     * side by side, `'responsiveColumn'` is a column that stacks below the
     * `m` breakpoint, `'inline'` flows them as compact inline text.
     * Defaults to `'row'`.
     */
    type?: EuiDescriptionListType;
    /**
     * `'reverse'` styles the descriptions as the prominent text and the
     * titles as the smaller labels. Defaults to `'normal'`.
     */
    textStyle?: 'normal' | 'reverse';
    /** `'left'` or `'center'`. Defaults to `'left'`. */
    align?: 'left' | 'center';
    /**
     * Space between rows: `'s'` or `'m'`. Defaults to `'s'`. Column lists
     * use it as the grid's row gap, row lists as the title's top margin.
     */
    rowGutterSize?: 's' | 'm';
    /** Space between the columns of a column list: `'s'` or `'m'`. Defaults to `'s'`. */
    columnGutterSize?: 's' | 'm';
    /**
     * Widths of the title and description columns of a column list: numbers
     * are `fr` units, strings any grid track (`'200px'`, `'minmax(…)'`).
     */
    columnWidths?: [number | string, number | string];
    /**
     * The terms: `[{ title: 'Name', description: 'Jane' }]`. Without it,
     * pass `EuiDescriptionListTitle` / `EuiDescriptionListDescription` in the
     * block.
     */
    listItems?: {
      title: string;
      description: string;
    }[];
    /** Props for each title from `@listItems`: `{ className }`. */
    titleProps?: {
      className?: string;
    };
    /** Props for each description from `@listItems`: `{ className }`. */
    descriptionProps?: {
      className?: string;
    };
  };
  Blocks: {
    /**
     * Pairs of `EuiDescriptionListTitle` and `EuiDescriptionListDescription`
     * (ignored when `@listItems` is set).
     */
    default: [];
  };
}

function track(value: number | string): string {
  return typeof value === 'number' ? `${value}fr` : value;
}

/** Scoped stand-in for React's global reset. */
const RESET = { boxSizing: 'border-box' as const, margin: 0, padding: 0 };

/** Native Ember description list using the upstream EUI 123 / Borealis factories. */
export default class EuiDescriptionList
  extends Component<EuiDescriptionListSignature>
  implements EuiDescriptionListContext
{
  @provide(EUI_DESCRIPTION_LIST_CONTEXT)
  get descriptionListContext(): EuiDescriptionListContext {
    return this;
  }

  get type(): EuiDescriptionListType {
    return this.args.type ?? 'row';
  }

  get compressed(): boolean {
    return Boolean(this.args.compressed);
  }

  get textStyle(): 'normal' | 'reverse' {
    return this.args.textStyle ?? 'normal';
  }

  get align(): 'left' | 'center' {
    return this.args.align ?? 'left';
  }

  get rowGutterSize(): 's' | 'm' {
    return this.args.rowGutterSize ?? 's';
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDescriptionListStyles);
    const columnGutter = this.args.columnGutterSize ?? 's';
    const widths = this.args.columnWidths;
    const columnStyles = [
      styles.column,
      styles.rowGap[this.rowGutterSize],
      styles.columnGap[columnGutter],
      // Upstream sets `columnWidths` as an inline style on column lists.
      widths &&
        `grid-template-columns:${track(widths[0])} ${track(widths[1])};`
    ];
    let typeStyles: CSSInterpolation[];
    if (this.type === 'responsiveColumn') {
      typeStyles = [
        atMedia(rowQuery(context), styles.row),
        atMedia(columnQuery(context), ...columnStyles)
      ];
    } else if (this.type === 'column') {
      typeStyles = columnStyles;
    } else {
      typeStyles = [styles[this.type]];
    }
    return `euiDescriptionList ${euiClass(
      context,
      RESET,
      styles.euiDescriptionList,
      ...typeStyles,
      styles[this.align]
    )}`;
  }

  <template>
    <dl class={{this.classes}} data-type={{this.type}} ...attributes>
      {{#if @listItems}}
        {{#each @listItems as |item|}}
          <EuiDescriptionListTitle class={{@titleProps.className}}>
            {{item.title}}
          </EuiDescriptionListTitle>
          <EuiDescriptionListDescription class={{@descriptionProps.className}}>
            {{item.description}}
          </EuiDescriptionListDescription>
        {{/each}}
      {{else}}
        {{yield}}
      {{/if}}
    </dl>
  </template>
}
