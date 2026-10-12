import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { provide } from 'ember-provide-consume-context';

import { EUI_FILTER_GROUP_CONTEXT } from '../-private/eui-filter-group-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiFilterGroupStyles } from '../utils/eui/styles.generated.ts';

import type { EuiFilterGroupContext } from '../-private/eui-filter-group-context.ts';

/**
 * A bar of `EuiFilterButton`s joined in one bordered group, usually next
 * to a search field, e.g. "On / Off" toggles and a "Status" popover.
 */
export interface EuiFilterGroupSignature {
  Element: HTMLDivElement;
  Args: {
    /** Takes the container's full width instead of its content's. */
    fullWidth?: boolean;
    /** Smaller buttons and radius, e.g. next to a compressed search field. */
    compressed?: boolean;
    /**
     * `'regular'` or `'highlighted'` (selected `@isToggle` buttons are
     * filled). Defaults to `'regular'`.
     */
    display?: 'regular' | 'highlighted';
    /** Dividers between the buttons. Defaults to `true`. */
    showDividers?: boolean;
  };
  Blocks: {
    /** The `EuiFilterButton`s (and popovers anchored on them). */
    default: [];
  };
}

export default class EuiFilterGroup
  extends Component<EuiFilterGroupSignature>
  implements EuiFilterGroupContext
{
  @provide(EUI_FILTER_GROUP_CONTEXT)
  get filterGroupContext(): EuiFilterGroupContext {
    return this;
  }

  get compressed() {
    return this.args.compressed;
  }
  get display() {
    return this.args.display ?? 'regular';
  }
  get showDividers() {
    return this.args.showDividers ?? true;
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFilterGroupStyles);
    return `euiFilterGroup ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiFilterGroup,
      this.args.fullWidth && styles.fullWidth,
      this.compressed ? styles.compressed : styles.uncompressed
    )}`;
  }

  <template>
    <div
      class={{this.classes}}
      data-display={{this.display}}
      data-dividers={{if this.showDividers "true"}}
      ...attributes
    >{{yield}}</div>
  </template>
}
