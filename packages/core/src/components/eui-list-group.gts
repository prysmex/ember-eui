import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { provide } from 'ember-provide-consume-context';

import { EUI_LIST_GROUP_CONTEXT } from '../-private/eui-list-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiListGroupStyles } from '../utils/eui/styles.generated.ts';

import type { EuiListGroupContext } from '../-private/eui-list-context.ts';

/** A list of `EuiListGroupItem`s, e.g. navigation links in a side bar. */
export interface EuiListGroupSignature {
  Element: HTMLUListElement;
  Args: {
    /**
     * Limits the list's width: `true` for upstream's default (the form max
     * width, 400px), `false` for none, or any CSS width (numbers are
     * pixels). Defaults to `true`.
     */
    maxWidth?: boolean | string | number;
    /** Adds a rounded border around the list. */
    bordered?: boolean;
    /**
     * Default `@color` of the items in the block: `'text'`, `'primary'` or
     * `'subdued'`. An item's own `@color` wins. Defaults to `'text'`.
     */
    color?: string;
    /** Default `@wrapText` of the items in the block. */
    wrapText?: boolean;
    /** @deprecated Has no effect: latest EUI lists have no padding. */
    flush?: boolean;
    /** @deprecated Has no effect: latest EUI lists have no item gutters. */
    gutterSize?: string;
  };
  Blocks: {
    /** The `EuiListGroupItem`s. */
    default: [];
  };
}

/** Scoped stand-in for React's global list reset; upstream comes after. */
const RESET = {
  boxSizing: 'border-box' as const,
  margin: 0,
  padding: 0,
  listStyle: 'none'
};

/** Native Ember list group using the upstream EUI 123 / Borealis factory. */
export default class EuiListGroup
  extends Component<EuiListGroupSignature>
  implements EuiListGroupContext
{
  @provide(EUI_LIST_GROUP_CONTEXT)
  get listGroupContext(): EuiListGroupContext {
    return this;
  }

  get color(): string | undefined {
    return this.args.color;
  }

  get wrapText(): boolean | undefined {
    return this.args.wrapText;
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiListGroupStyles);
    const maxWidth = this.args.maxWidth ?? true;
    return `euiListGroup ${euiClass(
      context,
      RESET,
      styles.euiListGroup,
      this.args.bordered && styles.bordered,
      maxWidth === true && styles.maxWidthDefault,
      // Upstream sets custom widths as an inline logical style.
      typeof maxWidth === 'string' && { maxInlineSize: maxWidth },
      typeof maxWidth === 'number' && { maxInlineSize: `${maxWidth}px` }
    )}`;
  }

  <template>
    <ul class={{this.classes}} ...attributes>
      {{yield}}
    </ul>
  </template>
}
