import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiRadioStyles } from '../utils/eui/styles.generated.ts';
import { euiCheckableInputReset, euiCheckableReset } from './eui-checkbox.gts';
import EuiIcon from './eui-icon.gts';

/**
 * Native state selectors: the visual state follows the `<input>`
 * (`:checked`, `:disabled`) rather than upstream's props, so uncontrolled
 * radios (and siblings unchecked by the browser) stay in sync.
 */
const INPUT = '> .euiRadio__input';
const SELECTED = `&:has(${INPUT}:checked)`;
const DISABLED = `&:has(${INPUT}:disabled)`;
const DISABLED_SELECTED = `&:has(${INPUT}:disabled:checked)`;
const DOT_VISIBLE = `.euiRadio__circle:has(${INPUT}:checked) &`;
const LABEL_DISABLED = `.euiRadio:has(> .euiRadio__circle ${INPUT}:disabled) &`;

/**
 * A single radio: a styled circle over a visually hidden native
 * `<input type="radio">`. Attributes and modifiers (`value`,
 * `{{on "change" …}}`) go to the `<input>`. For a list of choices use
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
    /**
     * @deprecated Has no effect on a single radio (upstream EUI has no
     * compressed radio). `EuiRadioGroup`'s `@compressed` tightens the spacing
     * between rows.
     */
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

export default class EuiRadio extends Component<EuiRadioSignature> {
  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiRadioStyles);
    const reset = euiCheckableReset(context.upstream);

    return {
      root: euiClass(context, reset, styles.euiRadio),
      circle: (hasLabel: unknown) =>
        euiClass(
          context,
          reset,
          styles.input.euiRadio__circle,
          hasLabel ? styles.input.hasLabel : undefined,
          styles.input.enabled.unselected,
          {
            [SELECTED]: styles.input.enabled.selected,
            [DISABLED]: styles.input.disabled.unselected,
            [DISABLED_SELECTED]: styles.input.disabled.selected
          }
        ),
      // Removed (not transparent) when unchecked, so forced colors never
      // reveal it; upstream swaps in its `empty` icon for the same reason.
      // Composed into EuiIcon's own class via @css, so it wins over the
      // icon's display rule regardless of insertion order.
      dot: [
        styles.input.euiRadio__icon,
        { display: 'none', [DOT_VISIBLE]: { display: 'block' } }
      ] as EuiCss,
      input: euiClass(
        context,
        euiCheckableInputReset,
        styles.input.euiRadio__input
      ),
      label: euiClass(
        context,
        reset,
        styles.label.euiRadio__label,
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
      <div class={{classNames "euiRadio" styles.root @containerClass}}>
        <div
          class="euiRadio__circle {{styles.circle (or hasLabelBlock @label)}}"
        >
          <EuiIcon @type="dot" @css={{styles.dot}} class="euiRadio__icon" />
          <input
            class="euiRadio__input {{styles.input}}"
            type="radio"
            id={{id}}
            checked={{@checked}}
            disabled={{@disabled}}
            name={{@name}}
            {{didInsert (optional @inputRef)}}
            ...attributes
          />
        </div>
        {{#if (or hasLabelBlock @label)}}
          <label
            class={{classNames
              "euiRadio__label"
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
