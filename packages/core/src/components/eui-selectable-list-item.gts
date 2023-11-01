import classNames from '../helpers/class-names';
import { eq, not, and } from 'ember-truth-helpers';
import typeOf from '../helpers/type-of';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiSelectableListItemSignature {
  Element: HTMLLIElement;
  Args: {
    isFocused?: boolean;
    disabled?: boolean;
    checked?: boolean | 'on' | 'off';
  };
  Blocks: {
    default: [];
  };
}

const EuiSelectableListItem: TemplateOnlyComponent<EuiSelectableListItemSignature> =
  <template>
    {{! TODO: not fully implemented }}
    <li
      role="option"
      aria-selected={{and (not @disabled) (eq (typeOf @checked) "string")}}
      class={{classNames
        componentName="EuiSelectableListItem"
        isFocused=@isFocused
      }}
      aria-disabled={{@disabled}}
      ...attributes
    >
      <span class="euiSelectableListItem__content">
        {{!-- {{optionIcon}} --}}
        {{!-- {{prependNode}} --}}
        <span class="euiSelectableListItem__text">
          {{yield}}
          {{!-- {{state}} --}}
          {{!-- {{children}} --}}
          {{!-- {{instruction}} --}}
        </span>
        {{!-- {{appendNode}} --}}
      </span>
    </li>
  </template>;

export default EuiSelectableListItem;
