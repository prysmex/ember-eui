import { and,eq, not } from 'ember-truth-helpers';

import classNames from '../helpers/class-names.ts';
import typeOf from '../helpers/type-of.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A checkable row in a selectable list (as in EUI's EuiSelectable). */
export interface EuiSelectableListItemSignature {
  Element: HTMLLIElement;
  Args: {
    /** Highlights the item (keyboard focus in the list). */
    isFocused?: boolean;
    /** Disables the item. */
    disabled?: boolean;
    /**
     * `'on'` (or `true`) shows a check, `'off'` a cross (excluded); leave
     * undefined for unchecked.
     */
    checked?: boolean | 'on' | 'off';
  };
  Blocks: {
    /** The item's content. */
    default: [];
  };
}

const EuiSelectableListItem: TemplateOnlyComponent<EuiSelectableListItemSignature> =
  <template>
    {{! TODO: not fully implemented }}
    <li
      role="option"
      aria-selected={{if
        (and (not @disabled) (eq (typeOf @checked) "string"))
        "true"
        "false"
      }}
      class={{classNames
        componentName="EuiSelectableListItem"
        isFocused=@isFocused
      }}
      aria-disabled={{if @disabled "true"}}
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
