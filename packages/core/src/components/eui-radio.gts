import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A single radio. Attributes and modifiers (`value`, `{{on "change" …}}`)
 * go to the `<input type="radio">`. For a list of choices use
 * EuiRadioGroup.
 */
export interface EuiRadioSignature {
  Element: HTMLInputElement;
  Args: {
    /** Whether it is checked. */
    checked?: boolean;
    /** Disables the radio. */
    disabled?: boolean;
    /** `name` of the radio; radios with the same name form a group. */
    name?: string;
    /** Label next to the radio. Use the `<:label>` block for markup. */
    label?: string;
    /** Props for the `<label>`: `{ className }`. */
    labelProps?: {
      className?: string;
    };
    /** Smaller radio, for dense forms. */
    compressed?: boolean;
    /** Extra classes for the wrapper around the input and label. */
    containerClass?: string;
    /** Called with the `<input>` element once rendered. */
    inputRef?: (element: HTMLInputElement | null) => void;
    /** @private Ignore the `<:label>` block. */
    isFakeLabelBlock?: boolean;
    /** Id of the input, linked to the label. Defaults to a random id. */
    id?: string;
  };
  Blocks: {
    /** The label, instead of `@label`. */
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
