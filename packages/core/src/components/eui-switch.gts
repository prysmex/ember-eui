import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import { and, not } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiIcon from './eui-icon.gts';

/** An on/off toggle, for settings that apply immediately. */
export interface EuiSwitchSignature {
  Element: HTMLButtonElement;
  Args: {
    /** Id of the switch button. Defaults to a random id. */
    id?: string;
    /**
     * Whether to render the text label. Without it `@label` becomes the
     * accessible label. Defaults to `true`.
     */
    showLabel?: boolean;
    /**
     * Must be a string if `showLabel` prop is true
     */
    label?: string;
    /** Whether it is on. */
    checked: boolean;
    /**
     * Called on click; `event.target.checked` is the new state. Update
     * `@checked` here.
     */
    onChange?: (event: MouseEvent) => void;
    /** Disables the switch. */
    disabled?: boolean;
    /** Smaller switch, for dense forms. */
    compressed?: boolean;
    /** `type` of the button. Defaults to `'button'`. */
    type?: 'submit' | 'reset' | 'button';

    /** Extra classes for the wrapper. */
    containerClass?: string;
    /** @private Ignore the `<:label>` block. */
    isFakeLabelBlock?: boolean;
  };
  Blocks: {
    /** Unused. */
    default: [];
    /** The label, instead of `@label`. */
    label: [];
  };
}

export default class EuiSwitch extends Component<EuiSwitchSignature> {
  @action
  onClick(e: MouseEvent): void {
    if (this.args.disabled) {
      return;
    }

    (e.target as HTMLInputElement).checked = !this.args.checked;

    this.args.onChange?.(e);
  }

  <template>
    {{#let
      (argOrDefault @type "button")
      (argOrDefault @showLabel true)
      (argOrDefault @id (randomId))
      (randomId)
      (and (has-block "label") (not (argOrDefault @isFakeLabelBlock false)))
      as |type showLabel switchId labelId hasLabelBlock|
    }}
      {{#let
        (classNames
          (if @compressed "euiSwitch--compressed") "euiSwitch" @containerClass
        )
        as |classes|
      }}
        <div class={{classes}}>
          <button
            type={{type}}
            id={{switchId}}
            aria-checked={{if @checked "true" "false"}}
            class="euiSwitch__button"
            role="switch"
            aria-label={{if (not showLabel) @label}}
            aria-labelledby={{if showLabel labelId undefined}}
            disabled={{@disabled}}
            ...attributes
            {{on "click" this.onClick}}
          >
            <span class="euiSwitch__body">
              <span class="euiSwitch__thumb"></span>
              <span class="euiSwitch__track">
                {{#unless @compressed}}
                  <EuiIcon
                    @type="cross"
                    @size="m"
                    @iconClasses="euiSwitch__icon"
                  />
                  <EuiIcon
                    @type="check"
                    @size="m"
                    @iconClasses="euiSwitch__icon euiSwitch__icon--checked"
                  />
                {{/unless}}
              </span>
            </span>
          </button>
          {{#if showLabel}}
            {{! template-lint-disable}}
            <span
              class="euiSwitch__label"
              id={{labelId}}
              {{on "click" this.onClick}}
            >
              {{#if hasLabelBlock}}
                {{yield to="label"}}
              {{else}}
                {{@label}}
              {{/if}}
            </span>
            {{! template-lint-enable}}
          {{/if}}
        </div>
      {{/let}}
    {{/let}}
  </template>
}
