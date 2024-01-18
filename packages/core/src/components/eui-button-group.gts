import { get } from '@ember/helper';

import { and, eq } from 'ember-truth-helpers';
import { notEq } from 'ember-truth-helpers';

import randomId from '../-private/random-id';
import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import screenReaderOnly from '../modifiers/screen-reader-only';
import EuiButtonGroupButton from './eui-button-group-button.gts';

import type { EuiButtonGroupButtonSignature } from './eui-button-group-button';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiButtonGroupSignature {
  Element: HTMLFieldSetElement;
  Args: {
    buttonSize?: 's' | 'm' | 'compressed';
    color?: 'primary' | 'text' | 'ghost' | 'success' | 'warning' | 'danger';
    isFullWidth?: boolean;
    isDisabled?: boolean;
    type?: 'single' | 'multi';
    legend?: string;
    name?: string;
    className?: string;
    isIconOnly?: EuiButtonGroupButtonSignature['Args']['isIconOnly'];
    onChange: EuiButtonGroupButtonSignature['Args']['onChange'];
    idSelected?: EuiButtonGroupButtonSignature['Args']['isSelected'];
    idToSelectedMap?: {
      [key: string]: EuiButtonGroupButtonSignature['Args']['isSelected'];
    };
    options?: Array<{
      isDisabled?: boolean;
      iconType?: EuiButtonGroupButtonSignature['Args']['iconType'];
      value?: EuiButtonGroupButtonSignature['Args']['value'];
      label?: EuiButtonGroupButtonSignature['Args']['label'];
      id: EuiButtonGroupButtonSignature['Args']['id'];
      isLoading?: EuiButtonGroupButtonSignature['Args']['isLoading'];
      iconSide?: EuiButtonGroupButtonSignature['Args']['iconSide'];
      iconSize?: EuiButtonGroupButtonSignature['Args']['iconSize'];
      textClasses?: EuiButtonGroupButtonSignature['Args']['textClasses'];
      contentClasses?: EuiButtonGroupButtonSignature['Args']['contentClasses'];
      iconClasses?: EuiButtonGroupButtonSignature['Args']['iconClasses'];
      type?: EuiButtonGroupButtonSignature['Args']['type'];
      className?: string;
      'aria-label'?: string;
    }>;
  };
}

export const EuiButtonGroup: TemplateOnlyComponent<EuiButtonGroupSignature> =
  <template>
    {{#let
      (argOrDefault @buttonSize "s")
      (argOrDefault @color "text")
      (argOrDefault @isFullWidth false)
      (argOrDefault @isDisabled false)
      (argOrDefault @type "single")
      as |buttonSize color isFullWidth isDisabled type|
    }}
      {{#let
        (if (and (eq buttonSize "compressed") (eq color "ghost")) "text" color)
        (eq type "single")
        as |resolvedColor typeIsSingle|
      }}

        <fieldset
          class={{classNames
            "euiButtonGroup"
            (if isFullWidth "euiButtonGroup--fullWidth")
            (if isDisabled "euiButtonGroup--fullWidth")
            @className
            componentName="EuiButtonGroup"
            size=(argOrDefault buttonSize "s")
            color=resolvedColor
          }}
          disabled={{isDisabled}}
          ...attributes
        >
          <legend {{screenReaderOnly}}>{{@legend}}</legend>
          <div class="euiButtonGroup__buttons">
            {{#let (argOrDefault @name (randomId)) as |name|}}
              {{#each @options as |option|}}
                <EuiButtonGroupButton
                  @name={{name}}
                  @isDisabled={{if
                    (notEq option.isDisabled undefined)
                    option.isDisabled
                    isDisabled
                  }}
                  @element={{if typeIsSingle "label" "button"}}
                  @isSelected={{if
                    typeIsSingle
                    (eq option.id @idSelected)
                    (get @idToSelectedMap option.id)
                  }}
                  @color={{resolvedColor}}
                  @size={{buttonSize}}
                  @isIconOnly={{@isIconOnly}}
                  @onChange={{@onChange}}
                  @iconType={{option.iconType}}
                  @value={{option.value}}
                  @label={{option.label}}
                  @id={{option.id}}
                  @isLoading={{option.isLoading}}
                  @iconSide={{option.iconSide}}
                  @iconSize={{option.iconSize}}
                  @textClasses={{option.textClasses}}
                  @contentClasses={{option.contentClasses}}
                  @iconClasses={{option.iconClasses}}
                  @type={{option.type}}
                  class={{option.className}}
                  aria-label={{option.aria-label}}
                />
              {{/each}}
            {{/let}}
          </div>
        </fieldset>
      {{/let}}
    {{/let}}
  </template>;

export default EuiButtonGroup;
