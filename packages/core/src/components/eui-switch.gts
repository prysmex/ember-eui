import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import { and, not } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiSwitchStyles } from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';

import type { CSSObject } from '@emotion/css/create-instance';

/** Stands in for React's global `button` reset (plus border-box sizing). */
const buttonReset: CSSObject = {
  boxSizing: 'border-box',
  background: 'none',
  border: 'none',
  padding: 0,
  margin: 0,
  color: 'inherit',
  fontSize: 'inherit'
};

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
    /** Props for the label `<span>`: `{ className, id }`. */
    labelProps?: {
      className?: string;
      id?: string;
    };
    /** Whether it is on. */
    checked: boolean;
    /**
     * Called on click; `event.target.checked` is the new state. Update
     * `@checked` here.
     */
    onChange?: (event: MouseEvent) => void;
    /** Disables the switch. */
    disabled?: boolean;
    /** Smaller switch (16px tall, no check/cross icons), for dense forms. */
    compressed?: boolean;
    /**
     * Smallest switch (10px tall, no icons, `xs` label). Takes precedence
     * over `@compressed`.
     */
    mini?: boolean;
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

  get size(): 'mini' | 'compressed' | 'uncompressed' {
    return this.args.mini
      ? 'mini'
      : this.args.compressed
        ? 'compressed'
        : 'uncompressed';
  }

  get showIcons(): boolean {
    return this.size === 'uncompressed';
  }

  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSwitchStyles);
    const { size } = this;
    const { checked, disabled } = this.args;
    const reset: CSSObject = {
      boxSizing: 'border-box',
      fontFamily: context.upstream.euiTheme.font.family
    };
    const borderBox: CSSObject = { boxSizing: 'border-box' };

    return {
      root: euiClass(
        context,
        reset,
        styles.euiSwitch,
        disabled ? styles.disabled : styles.enabled
      ),
      button: euiClass(
        context,
        buttonReset,
        styles.button.euiSwitch__button,
        styles.button[size]
      ),
      body: euiClass(
        context,
        borderBox,
        styles.body.euiSwitch__body,
        disabled
          ? styles.body.disabled[size]
          : checked
            ? styles.body.on
            : styles.body.off
      ),
      icons: euiClass(
        context,
        borderBox,
        styles.icons.euiSwitch__icons,
        checked ? styles.icons.on : styles.icons.off,
        disabled ? styles.icons.disabled : styles.icons.enabled
      ),
      // Same order as upstream: checked styles after enabled ones, so `on`
      // overrides the enabled `off` border.
      thumb: euiClass(
        context,
        borderBox,
        styles.thumb.euiSwitch__thumb,
        disabled ? undefined : styles.thumb.enabled.enabled,
        disabled ? undefined : styles.thumb.enabled[size],
        checked ? styles.thumb.on[size] : styles.thumb.off,
        disabled ? styles.thumb.disabled.disabled : undefined,
        disabled ? styles.thumb.disabled[size] : undefined
      ),
      label: euiClass(
        context,
        reset,
        styles.label.euiSwitch__label,
        styles.label[size],
        disabled ? styles.label.disabled : undefined
      )
    };
  }

  <template>
    {{#let
      (argOrDefault @type "button")
      (argOrDefault @showLabel true)
      (argOrDefault @id (randomId))
      (argOrDefault @labelProps.id (randomId))
      (and (has-block "label") (not (argOrDefault @isFakeLabelBlock false)))
      this.styles
      as |type showLabel switchId labelId hasLabelBlock styles|
    }}
      <div class={{classNames "euiSwitch" styles.root @containerClass}}>
        <button
          type={{type}}
          id={{switchId}}
          aria-checked={{if @checked "true" "false"}}
          class="euiSwitch__button {{styles.button}}"
          role="switch"
          aria-label={{if (not showLabel) @label}}
          aria-labelledby={{if showLabel labelId undefined}}
          disabled={{@disabled}}
          ...attributes
          {{on "click" this.onClick}}
        >
          <span class="euiSwitch__body {{styles.body}}">
            {{#if this.showIcons}}
              <span class="euiSwitch__icons {{styles.icons}}">
                <EuiIcon @type="check" @size="m" />
                <EuiIcon @type="cross" @size="m" />
              </span>
            {{/if}}
          </span>
          <span class="euiSwitch__thumb {{styles.thumb}}"></span>
        </button>
        {{#if showLabel}}
          {{! <button> + <label> has poor screen reader support; the click
            handler simulates a label (as upstream does). }}
          {{! template-lint-disable}}
          <span
            class={{classNames
              "euiSwitch__label"
              styles.label
              @labelProps.className
            }}
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
  </template>
}
