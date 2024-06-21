import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from 'ember-composable-helpers/helpers/optional';
import { and, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiRadioSignature {
  Element: HTMLInputElement;
  Args: {
    checked?: boolean;
    disabled?: boolean;
    name?: string;
    label?: string;
    labelProps?: {
      className?: string;
    };
    compressed?: boolean;
    containerClass?: string;
    inputRef?: (element: HTMLInputElement | null) => void;
    isFakeLabelBlock?: boolean;
    id?: string;
  };
  Blocks: {
    label: [];
  };
}

const EuiRadio: TemplateOnlyComponent<EuiRadioSignature> = <template>
  {{#let
    (and (has-block "label") (not (argOrDefault @isFakeLabelBlock false)))
    (argOrDefault @id (randomId))
    as |hasLabelBlock id|
  }}
    {{#let
      (classNames
        @containerClass
        (if (not (or hasLabelBlock @label)) "euiRadio--noLabel")
        (if @compressed "euiRadio--compressed")
        "euiRadio"
      )
      as |classes|
    }}
      <div class={{classes}}>
        <input
          class="euiRadio__input"
          type="radio"
          id={{id}}
          checked={{@checked}}
          disabled={{@disabled}}
          name={{@name}}
          {{didInsert (optional @inputRef)}}
          ...attributes
        />
        <div class="euiRadio__circle"></div>
        {{#if (or hasLabelBlock @label)}}
          <label
            class={{classNames "euiRadio__label" @labelProps.className}}
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

export default EuiRadio;
