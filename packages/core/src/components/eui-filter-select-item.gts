import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiIcon from './eui-icon.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * One option in a filter popover (opened from an `EuiFilterButton`): a
 * button with a check mark when `@checked="on"`, or a cross when `"off"`
 * (excluded).
 */
export interface EuiFilterSelectItemSignature {
  Element: HTMLButtonElement;
  Args: {
    /**
     * `'on'` (check mark, included), `'off'` (cross, excluded) or
     * nothing (not applied).
     */
    checked?: 'on' | 'off';
    /** Highlights it, e.g. while moving through the list with the keyboard. */
    isFocused?: boolean;
    /** Shows the check mark / cross column. Defaults to `true`. */
    showIcons?: boolean;
    /** Disables the option. */
    disabled?: boolean;
  };
  Blocks: {
    /** The option's label. */
    default: [];
  };
}

function icon(checked?: string): string {
  return checked === 'on' ? 'check' : checked === 'off' ? 'cross' : 'empty';
}

const EuiFilterSelectItem: TemplateOnlyComponent<EuiFilterSelectItemSignature> =
  <template>
    <button
      type="button"
      role="option"
      class="euiFilterSelectItem {{if @isFocused 'euiFilterSelectItem-isFocused'}}"
      aria-selected={{if @isFocused "true" "false"}}
      disabled={{@disabled}}
      aria-disabled={{if @disabled "true"}}
      ...attributes
    >
      <EuiFlexGroup
        @alignItems="center"
        @gutterSize="s"
        @tagName="span"
        @responsive={{false}}
      >
        {{#if (showIcons @showIcons)}}
          <EuiFlexItem @grow={{false}}>
            <EuiIcon @type={{icon @checked}} @color={{if @checked "text"}} />
          </EuiFlexItem>
        {{/if}}
        <EuiFlexItem class="euiFilterSelectItem__content" @tagName="span">
          {{yield}}
        </EuiFlexItem>
      </EuiFlexGroup>
    </button>
  </template>;

function showIcons(value?: boolean): boolean {
  return value !== false;
}

export default EuiFilterSelectItem;
