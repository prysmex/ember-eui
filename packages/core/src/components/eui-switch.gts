import Component from '@glimmer/component';
import { action } from '@ember/object';
import classNames from '../helpers/class-names';
import { and, not } from 'ember-truth-helpers';
import argOrDefault from '../helpers/arg-or-default';
import EuiIcon from './eui-icon';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';

type SwitchArgs = {
  /**
   * Whether to render the render the text label
   */
  showLabel?: boolean;
  /**
   * Must be a string if `showLabel` prop is false
   */
  label: unknown | string;
  checked: boolean;
  onChange: (event: { target: HTMLInputElement }) => void;
  disabled?: boolean;
  compressed?: boolean;
  type?: 'submit' | 'reset' | 'button';
};

export default class EuiSwitch extends Component<SwitchArgs> {
  @action
  onClick(e: { target: HTMLInputElement }): void {
    if (this.args.disabled) {
      return;
    }

    e.target.checked = !this.args.checked;

    this.args.onChange?.(e);
  }

  <template>
    {{#let
      (argOrDefault @type "button")
      (argOrDefault @showLabel true)
      (argOrDefault @id (guidFor))
      (guidFor)
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
            aria-label={{if showLabel undefined @label}}
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