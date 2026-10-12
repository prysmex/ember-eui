import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiFilterSelectItemStyles,
  euiTextTruncate
} from '../utils/eui/styles.generated.ts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiIcon from './eui-icon.gts';

/**
 * One option in a filter popover (opened from an `EuiFilterButton`): a
 * button with a check mark when `@checked="on"`, or a cross when `"off"`
 * (excluded).
 */
export interface EuiFilterSelectItemSignature {
  Element: HTMLButtonElement;
  Args: {
    /**
     * `'on'` (check mark, included; sets `aria-selected="true"`), `'off'`
     * (cross, excluded) or nothing (not applied).
     */
    checked?: 'on' | 'off';
    /**
     * Highlights it, e.g. while moving through the list with the keyboard,
     * and scrolls it into view when it becomes focused.
     */
    isFocused?: boolean;
    /** Shows the check mark / cross column. Defaults to `true`. */
    showIcons?: boolean;
    /** Truncates a long label with an ellipsis. Defaults to `true`. */
    truncateContent?: boolean;
    /** Disables the option. */
    disabled?: boolean;
  };
  Blocks: {
    /** The option's label. */
    default: [];
  };
}

export default class EuiFilterSelectItem extends Component<EuiFilterSelectItemSignature> {
  get icon(): string {
    const checked = this.args.checked;
    return checked === 'on' ? 'check' : checked === 'off' ? 'cross' : 'empty';
  }
  get showIcons(): boolean {
    return this.args.showIcons !== false;
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFilterSelectItemStyles);
    return `euiFilterSelectItem ${euiClass(
      context,
      // React's global `button` reset, scoped.
      {
        boxSizing: 'border-box',
        margin: 0,
        border: 'none',
        background: 'none',
        fontFamily: context.upstream.euiTheme.font.family
      },
      styles.euiFilterSelectItem,
      this.args.isFocused && styles.isFocused
    )}`;
  }

  /** Upstream gives the content item the `eui-textTruncate` utility class. */
  @cached
  get contentCss(): EuiCss {
    return this.args.truncateContent !== false ? euiTextTruncate() : undefined;
  }

  /** Upstream scrolls an option into view when it becomes focused. */
  scrollWhenFocused = (element: HTMLButtonElement) => {
    if (this.args.isFocused) element.scrollIntoView?.({ block: 'nearest' });
  };

  <template>
    <button
      type="button"
      role="option"
      class={{this.classes}}
      aria-selected={{if (isOn @checked) "true" "false"}}
      disabled={{@disabled}}
      aria-disabled={{if @disabled "true"}}
      {{didUpdate this.scrollWhenFocused @isFocused}}
      ...attributes
    >
      <EuiFlexGroup
        @alignItems="center"
        @gutterSize="s"
        @tagName="span"
        @responsive={{false}}
      >
        {{#if this.showIcons}}
          <EuiFlexItem @grow={{false}}>
            <EuiIcon @type={{this.icon}} @color={{if @checked "text"}} />
          </EuiFlexItem>
        {{/if}}
        <EuiFlexItem
          class="euiFilterSelectItem__content"
          @tagName="span"
          @css={{this.contentCss}}
        >
          {{yield}}
        </EuiFlexItem>
      </EuiFlexGroup>
    </button>
  </template>
}

function isOn(checked?: string): boolean {
  return checked === 'on';
}
