import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import { and, eq, notEq } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import classNames from '../helpers/class-names.ts';
import EuiButton from './eui-button.gts';
import EuiInnerText from './eui-inner-text.gts';

import type { EuiButtonSignature } from './eui-button';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiButtonGroupButtonSignature {
  Element: EuiButtonSignature['Element'];
  Args: {
    /** Id of the option, passed to `@onChange`. */
    id: string;
    /** Value of the option, passed to `@onChange` for single selection. */
    value?: string;
    /**
     * `'label'` wraps a hidden radio input (single selection groups),
     * `'button'` renders a toggle button (multi selection groups).
     */
    element?: 'label' | 'button';
    /** `name` of the radio input, shared by the group's buttons. */
    name?: string;
    /** The button's text (visually hidden with `@isIconOnly`). */
    label?: string;
    /** Disables the button. */
    isDisabled?: boolean;
    /** Whether the option is selected. */
    isSelected?: boolean;
    /** Shows only the icon; the label is kept for screen readers. */
    isIconOnly?: boolean;
    /** `'s'`, `'m'` or `'compressed'`. */
    size?: EuiButtonSignature['Args']['size'];
    /** Color of the selected button, see `EuiButtonGroup`. */
    color?: EuiButtonSignature['Args']['color'];
    /** Classes for the element wrapping the icon and text. */
    contentClasses?: EuiButtonSignature['Args']['contentClasses'];
    /** `'right'` puts the icon after the text. */
    iconSide?: EuiButtonSignature['Args']['iconSide'];
    /** Icon of the button; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiButtonSignature['Args']['iconType'];
    /** Size of the icon. */
    iconSize?: EuiButtonSignature['Args']['iconSize'];
    /** Extra classes for the icon. */
    iconClasses?: EuiButtonSignature['Args']['iconClasses'];
    /** Shows a spinner instead of the icon. */
    isLoading?: EuiButtonSignature['Args']['isLoading'];
    /** Classes for the element wrapping the text. */
    textClasses?: EuiButtonSignature['Args']['textClasses'];
    /** `type` of the button (multi selection only). */
    type?: EuiButtonSignature['Args']['type'];
    /**
     * Called with the option's `id` (and `value` for single selection) when
     * it is clicked.
     */
    onChange: (id: string, value?: string) => void;
  };
}

const handleClick = (
  isNotLabel: boolean,
  onChange: (id: string, value?: string) => void,
  id: string
) => {
  if (isNotLabel) {
    onChange(id);
  }
};

const EuiButtonGroupButton: TemplateOnlyComponent<EuiButtonGroupButtonSignature> =
  <template>
    {{#let
      (if @isDisabled "button" @element)
      (randomId)
      (classNames
        (if @isSelected "euiButtonGroupButton-isSelected")
        (if @isIconOnly "euiButtonGroupButton-isIconOnly")
      )
      as |element newId classes|
    }}
      {{#let (notEq @element "label") as |isNotLabel|}}
        <EuiInnerText as |setInnerTextRef innerText|>
          <EuiButton
            @baseClassName="euiButtonGroupButton"
            class={{classes}}
            @element={{element}}
            @fill={{and (notEq @size "compressed") @isSelected}}
            @isDisabled={{@isDisabled}}
            @size={{if (eq @size "compressed") "s" @size}}
            @color={{@color}}
            @contentClasses={{@contentClasses}}
            @iconSide={{@iconSide}}
            @iconType={{@iconType}}
            @iconSize={{@iconSize}}
            @iconClasses={{@iconClasses}}
            @isLoading={{@isLoading}}
            @textClasses={{classNames
              @textClasses
              (if
                @isIconOnly
                "euiScreenReaderOnly"
                "euiButtonGroupButton__textShift"
              )
            }}
            @isSelected={{if isNotLabel @isSelected}}
            type={{if isNotLabel @type}}
            for={{if (eq element "label") newId}}
            id={{if isNotLabel newId}}
            title={{innerText}}
            {{on "click" (fn handleClick isNotLabel @onChange @id)}}
            {{didInsert setInnerTextRef}}
            ...attributes
          >
            {{#if (eq element "label")}}
              <input
                id={{newId}}
                class="euiScreenReaderOnly"
                name={{@name}}
                checked={{@isSelected}}
                disabled={{@isDisabled}}
                value={{@value}}
                type="radio"
                {{on "change" (fn @onChange @id @value)}}
              />
            {{/if}}
            {{@label}}
          </EuiButton>
        </EuiInnerText>
      {{/let}}
    {{/let}}
  </template>;

export default EuiButtonGroupButton;
