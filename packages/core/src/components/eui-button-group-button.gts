import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import noop from 'ember-composable-helpers/helpers/noop';
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
    id: string;
    value?: string;
    element?: 'label' | 'button';
    name?: string;
    label?: string;
    isDisabled?: boolean;
    isSelected?: boolean;
    isIconOnly?: boolean;
    size?: EuiButtonSignature['Args']['size'];
    color?: EuiButtonSignature['Args']['color'];
    contentClasses?: EuiButtonSignature['Args']['contentClasses'];
    iconSide?: EuiButtonSignature['Args']['iconSide'];
    iconType?: EuiButtonSignature['Args']['iconType'];
    iconSize?: EuiButtonSignature['Args']['iconSize'];
    iconClasses?: EuiButtonSignature['Args']['iconClasses'];
    isLoading?: EuiButtonSignature['Args']['isLoading'];
    textClasses?: EuiButtonSignature['Args']['textClasses'];
    type?: EuiButtonSignature['Args']['type'];
    onChange: (id: string, value?: string) => void;
  };
}

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
            {{on "click" (if isNotLabel (fn @onChange @id) (noop))}}
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
