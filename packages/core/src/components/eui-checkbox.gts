import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { modifier } from 'ember-modifier';
import { and, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

const indeterminateModifier = modifier(function invalidateIndeterminate(
  element: HTMLInputElement,
  [indeterminate]: [boolean?]
) {
  if (element) {
    element.indeterminate = indeterminate!;
  }
});

/**
 * Attributes and modifiers (`value`, `{{on "change" …}}`) go to the
 * `<input type="checkbox">`.
 */
export interface EuiCheckboxSignature {
  Element: HTMLInputElement;
  Args: {
    /** Whether it is checked. Update it from `{{on "change" …}}`. */
    checked?: boolean;
    /** Disables the checkbox. */
    disabled?: boolean;
    /** Shows the "partially checked" state, e.g. for a "select all" box. */
    indeterminate?: boolean;
    /** @private Styles the checkbox for use next to an icon. */
    icon?: boolean;
    /** Smaller checkbox, for dense forms. */
    compressed?: boolean;
    /** Label next to the checkbox. Use the `<:label>` block for markup. */
    label?: string;
    /** Props for the `<label>`: `{ className }`. */
    labelProps?: {
      className?: string;
    };
    /** Extra classes for the wrapper around the input and label. */
    containerClass?: string;
    /** Extra classes for the wrapper around the input and label. */
    className?: string;
    /** Called with the `<input>` element once rendered. */
    inputRef?: (element: HTMLInputElement) => void;
    /**
     * @private Ignore the `<:label>` block (for wrappers that always pass
     * one).
     */
    isFakeLabelBlock?: boolean;
    /** Id of the input, linked to the label. Defaults to a random id. */
    id?: string;
    /** `name` of the input, for forms. */
    name?: string;
  };
  Blocks: {
    /** The label, instead of `@label`. */
    label?: [];
  };
}

const EuiCheckbox: TemplateOnlyComponent<EuiCheckboxSignature> = <template>
  {{#let
    (and (has-block "label") (not (argOrDefault @isFakeLabelBlock false)))
    (argOrDefault @id (randomId))
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
