import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from 'ember-composable-helpers/helpers/optional';
import { modifier } from 'ember-modifier';
import { and, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

const indeterminateModifier = modifier(function invalidateIndeterminate(
  element: HTMLInputElement,
  [indeterminate]: [boolean?]
) {
  if (element) {
    element.indeterminate = indeterminate!!;
  }
});

export interface EuiCheckboxSignature {
  Element: HTMLInputElement;
  Args: {
    checked?: boolean;
    disabled?: boolean;
    indeterminate?: boolean;
    icon?: boolean;
    compressed?: boolean;
    label?: string;
    labelProps?: {
      className?: string;
    };
    containerClass?: string;
    className?: string;
    inputRef?: (element: HTMLInputElement) => void;
    isFakeLabelBlock?: boolean;
    id?: string;
    name?: string;
  };
  Blocks: {
    label?: [];
  };
}

const EuiCheckbox: TemplateOnlyComponent<EuiCheckboxSignature> = <template>
  {{#let
    (and (has-block "label") (not (argOrDefault @isFakeLabelBlock false)))
    (argOrDefault @id (uniqueId))
    as |hasLabelBlock id|
  }}
    {{#let
      (classNames
        (if @icon "euiCheckbox--withIcon")
        (if (not (or hasLabelBlock @label)) "euiCheckbox--noLabel")
        (if @compressed "euiCheckbox--compressed")
        "euiCheckbox"
        @className
        @containerClass
      )
      as |classes|
    }}
      <div class={{classes}}>
        <input
          class="euiCheckbox__input"
          type="checkbox"
          id={{id}}
          checked={{@checked}}
          disabled={{@disabled}}
          name={{@name}}
          ...attributes
          {{indeterminateModifier @indeterminate}}
          {{didInsert (optional @inputRef)}}
        />
        <div class="euiCheckbox__square"></div>
        {{#if (or hasLabelBlock @label)}}
          <label
            class={{classNames "euiCheckbox__label" @labelProps.className}}
            for={{id}}
          >
            {{#if hasLabelBlock}}
              {{yield to="label"}}
            {{else}}
              {{@label}}
            {{/if}}
          </label>
        {{/if}}
      </div>
    {{/let}}
  {{/let}}
</template>;

export default EuiCheckbox;
