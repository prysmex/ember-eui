import Component from '@glimmer/component';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { modifier } from 'ember-modifier';
import { and, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiCheckboxControlStyles,
  euiCheckboxStyles
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';

import type { CSSObject } from '@emotion/css/create-instance';
import type { EuiBorealisContext } from '../utils/eui/theme.ts';

const indeterminateModifier = modifier(function invalidateIndeterminate(
  element: HTMLInputElement,
  [indeterminate]: [boolean?]
) {
  if (element) {
    element.indeterminate = indeterminate ?? false;
  }
});

/**
 * Native state selectors. Upstream (React, always controlled) picks its
 * selected/disabled styles from props; Ember checkboxes may be uncontrolled,
 * so the visual state follows the native `<input>` instead (`:checked`,
 * `:indeterminate`, `:disabled`). `&` is the element being styled.
 */
const SQUARE = '.euiCheckbox__square';
const INPUT = '> .euiCheckbox__input';
const SELECTED = `${SQUARE}:has(${INPUT}:checked) &, ${SQUARE}:has(${INPUT}:indeterminate) &`;
const DISABLED = `${SQUARE}:has(${INPUT}:disabled) &`;
const DISABLED_SELECTED = `${SQUARE}:has(${INPUT}:disabled:checked) &, ${SQUARE}:has(${INPUT}:disabled:indeterminate) &`;
const CHECKED_ONLY = `${SQUARE}:has(${INPUT}:checked:not(:indeterminate)) &`;
const INDETERMINATE = `${SQUARE}:has(${INPUT}:indeterminate) &`;
const LABEL_DISABLED = `.euiCheckbox:has(> ${SQUARE} ${INPUT}:disabled) &`;

/** Stands in for React's global reset, which Ember apps do not have. */
export function euiCheckableReset({ euiTheme }: EuiBorealisContext): CSSObject {
  return { boxSizing: 'border-box', fontFamily: euiTheme.font.family };
}

/** Upstream's input reset (`margin: 0; padding: 0`) plus border-box sizing. */
export const euiCheckableInputReset: CSSObject = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0
};

/**
 * A checkbox: a styled square over a visually hidden native
 * `<input type="checkbox">`. Attributes and modifiers (`value`,
 * `{{on "change" …}}`) go to the `<input>`.
 */
export interface EuiCheckboxSignature {
  Element: HTMLInputElement;
  Args: {
    /** Whether it is checked. Update it from `{{on "change" …}}`. */
    checked?: boolean;
    /** Disables the checkbox. */
    disabled?: boolean;
    /**
     * Shows the "partially checked" state, e.g. for a "select all" box. Sets
     * the input's `indeterminate` property.
     */
    indeterminate?: boolean;
    /** @deprecated Has no effect; upstream EUI has no icon variant. */
    icon?: boolean;
    /**
     * @deprecated Has no effect on a single checkbox (upstream EUI has no
     * compressed checkbox). `EuiCheckboxGroup`'s `@compressed` tightens the
     * spacing between rows.
     */
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

export default class EuiCheckbox extends Component<EuiCheckboxSignature> {
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiCheckboxStyles);
    const control = useEuiBorealisStyles(context, euiCheckboxControlStyles);
    const reset = euiCheckableReset(context.upstream);
    const hidden: CSSObject = { display: 'none' };

    return {
      root: euiClass(context, reset, styles.euiCheckbox),
      square: (hasLabel: unknown) =>
        euiClass(
          context,
          reset,
          styles.input.euiCheckbox__square,
          hasLabel ? styles.input.hasLabel : undefined
        ),
      control: euiClass(
        context,
        reset,
        control.euiCheckboxControl,
        control.enabled.unselected,
        {
        [SELECTED]: control.enabled.selected,
        [DISABLED]: control.disabled.unselected,
        [DISABLED_SELECTED]: control.disabled.selected
        }
      ),
      // Hidden icons are removed rather than made transparent, so forced
      // colors (which override `color`) never reveal them (upstream swaps in
      // its `empty` icon for the same reason).
      check: euiClass(
        context,
        control.icon.euiCheckbox__icon,
        control.icon.check,
        { ...hidden, [CHECKED_ONLY]: { display: 'block' } }
      ),
      indeterminate: euiClass(
        context,
        control.icon.euiCheckbox__icon,
        control.icon.indeterminate,
        { ...hidden, [INDETERMINATE]: { display: 'block' } }
      ),
      input: euiClass(
        context,
        euiCheckableInputReset,
        styles.input.euiCheckbox__input
      ),
      label: euiClass(
        context,
        reset,
        styles.label.euiCheckbox__label,
        styles.label.enabled,
        { [LABEL_DISABLED]: styles.label.disabled }
      )
    };
  }

  <template>
    {{#let
      (and (has-block "label") (not (argOrDefault @isFakeLabelBlock false)))
      (argOrDefault @id (randomId))
      this.styles
      as |hasLabelBlock id styles|
    }}
      <div
        class={{classNames
          "euiCheckbox"
          styles.root
          @className
          @containerClass
        }}
      >
        <div
          class="euiCheckbox__square {{styles.square (or hasLabelBlock @label)}}"
        >
          <span class="euiCheckboxControl {{styles.control}}">
            <EuiIcon
              @type="check"
              @size="m"
              role="presentation"
              class="euiCheckbox__icon {{styles.check}}"
            />
            <EuiIcon
              @type="stopFilled"
              @size="m"
              role="presentation"
              class="euiCheckbox__icon {{styles.indeterminate}}"
            />
          </span>
          <input
            class="euiCheckbox__input {{styles.input}}"
            type="checkbox"
            id={{id}}
            checked={{@checked}}
            disabled={{@disabled}}
            name={{@name}}
            ...attributes
            {{indeterminateModifier @indeterminate}}
            {{didInsert (optional @inputRef)}}
          />
        </div>
        {{#if (or hasLabelBlock @label)}}
          <label
            class={{classNames
              "euiCheckbox__label"
              styles.label
              @labelProps.className
            }}
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
  </template>
}
