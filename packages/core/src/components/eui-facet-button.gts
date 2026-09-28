import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import EuiInnerText from './eui-inner-text.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiNotificationBadge from './eui-notification-badge.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A button to filter by one value (a facet), usually with the number of
 * matching items. Put several in an `EuiFacetGroup`.
 */
export interface EuiFacetButtonSignature {
  Element: HTMLButtonElement;
  Args: {
    /** Number of matching items, shown in a badge. */
    quantity?: number;
    /** Selected look: bold text and an accent badge. */
    isSelected?: boolean;
    /** Disables the button. */
    isDisabled?: boolean;
    /** Replaces the quantity with a spinner and disables the button. */
    isLoading?: boolean;
  };
  Blocks: {
    /** The facet's name. */
    default: [];
    /**
     * An icon or avatar before the name; give it the class
     * `euiFacetButton__icon`, e.g. `<EuiIcon class="euiFacetButton__icon" … />`.
     */
    icon: [];
  };
}

function badgeColor(isSelected?: boolean, isDisabled?: boolean): 'subdued' | 'accent' {
  return !isSelected || isDisabled ? 'subdued' : 'accent';
}

function isNumber(value: unknown): value is number {
  return typeof value === 'number';
}

const EuiFacetButton: TemplateOnlyComponent<EuiFacetButtonSignature> = <template>
  <EuiInnerText as |ref innerText|>
    <button
      type="button"
      class="euiFacetButton
        {{if @isSelected 'euiFacetButton--isSelected' 'euiFacetButton--unSelected'}}"
      disabled={{if (or2 @isLoading @isDisabled) true}}
      title={{innerText}}
      ...attributes
    >
      <span class="euiFacetButton__content">
        {{yield to="icon"}}
        <span
          class="euiFacetButton__text"
          data-text={{innerText}}
          {{didInsert ref}}
        >{{yield}}</span>
        {{#if @isLoading}}
          <EuiLoadingSpinner class="euiFacetButton__spinner" @size="m" />
        {{else if (isNumber @quantity)}}
          <EuiNotificationBadge
            class="euiFacetButton__quantity"
            @size="m"
            @color={{badgeColor @isSelected (or2 @isLoading @isDisabled)}}
          >{{@quantity}}</EuiNotificationBadge>
        {{/if}}
      </span>
    </button>
  </EuiInnerText>
</template>;

function or2(a?: boolean, b?: boolean): boolean {
  return Boolean(a || b);
}

export default EuiFacetButton;
