import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import { and, not } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';
import EuiIcon from './eui-icon.gts';

export interface EuiSwitchSignature {
  Element: HTMLButtonElement;
  Args: {
    id?: string;
    /**
     * Whether to render the render the text label
     */
    showLabel?: boolean;
    /**
     * Must be a string if `showLabel` prop is true
     */
    label?: string;
    checked: boolean;
    onChange: (event: MouseEvent) => void;
    disabled?: boolean;
    compressed?: boolean;
    type?: 'submit' | 'reset' | 'button';

    containerClass?: string;
    isFakeLabelBlock?: boolean;
  };
  Blocks: {
    default: [];
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
      (argOrDefault @id (uniqueId))
      (uniqueId)
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
