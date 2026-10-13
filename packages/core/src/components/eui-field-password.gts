import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';
import { and, eq, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import validatableControl from '../modifiers/validatable-control.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { formControlReset } from '../utils/eui/form-controls.ts';
import { euiFieldPasswordStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiFormControlLayout from './eui-form-control-layout.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiFormControlLayoutSignature } from './eui-form-control-layout';
import type { EuiButtonIconSignature } from './eui-button-icon.gts';
import type { CommonArgs } from './common.ts';

type ButtonIconArgs = EuiButtonIconSignature['Args'];

/** Supported keys of `@dualToggleProps`, spread over the toggle's defaults. */
export type EuiFieldPasswordDualToggleProps = CommonArgs &
  Pick<
    ButtonIconArgs,
    | 'iconType'
    | 'iconSize'
    | 'color'
    | 'display'
    | 'size'
    | 'isDisabled'
    | 'disabled'
    | 'css'
  > & {
    /** Called after the toggle switched the visibility. */
    onClick?: (event: MouseEvent) => void;
  };

export interface EuiFieldPasswordSignature {
  Element: HTMLInputElement;
  Args: {
    /** The value. Update it from `{{on "input" …}}` on the component. */
    value?: string;
    /** Id of the input, e.g. to match an `EuiFormRow`'s label. Defaults to a random id. */
    id?: string;
    /**
     * `'password'` hides the text, `'text'` shows it, `'dual'` hides it with
     * a button to show it. Defaults to `'dual'` (upstream defaults to
     * `'password'`).
     */
    type?: 'dual' | 'text' | 'password';
    /** Stretches the input to its container's width. */
    fullWidth?: boolean;
    /** Shorter input (32px instead of 40px), for dense forms. */
    compressed?: boolean;
    /** Shows a spinner in the input. */
    isLoading?: boolean;
    /** Makes the input read-only. */
    readOnly?: boolean;
    /** Disables the input. */
    disabled?: boolean;
    /**
     * Shows the invalid state (danger border and warning icon), sets
     * `aria-invalid` and marks the input invalid for native form validation.
     */
    isInvalid?: boolean;
    /** Shows a clear ("x") button calling this function; empty the value there. */
    clear?: EuiFormControlLayoutSignature['Args']['clear'];
    /** Called with the `<input>` element once rendered. */
    inputRef?: (element: HTMLInputElement) => void;
    /** @private Ignore the `<:prepend>` block. */
    isFakePrependBlock?: boolean;
    /** @private Ignore the `<:append>` block. */
    isFakeAppendBlock?: boolean;
    /** Placeholder text. */
    placeholder?: string;
    /**
     * Extra props for the `@type="dual"` show/mask button, an
     * `EuiButtonIcon` (upstream `dualToggleProps`): `iconType`, `iconSize`,
     * `color`, `display`, `size`, `isDisabled` / `disabled`, `css`, `id`,
     * `className`, `aria-label` and `data-test-subj` replace the defaults;
     * `onClick` is called after the toggle.
     */
    dualToggleProps?: EuiFieldPasswordDualToggleProps;
  };
  Blocks: {
    /** Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. */
    prepend: [unknown, string];
    /** Content after the input; yields the class to put on it and the input id. */
    append: [unknown, string];
  };
}

/**
 * A password input on the upstream EUI 123 / Borealis form control styles.
 * With `@type="dual"` an eye button in the append shows/masks the text.
 */
export default class EuiFieldPassword extends Component<EuiFieldPasswordSignature> {
  @service('eui-i18n') declare euiI18n: EuiI18n;

  /** `null` until toggled: then the visible type overrides `@type`. */
  @tracked toggledType: 'text' | 'password' | null = null;
  inputElement: HTMLInputElement | null = null;

  get type() {
    return this.args.type ?? 'dual';
  }
  get isDual() {
    return this.type === 'dual';
  }
  get inputType() {
    if (!this.isDual) return this.type;
    return this.toggledType ?? 'password';
  }
  get isVisible() {
    return this.inputType === 'text';
  }
  get toggleLabel() {
    return this.isVisible
      ? this.euiI18n.lookupToken(
          'euiFieldPassword.maskPassword',
          'Mask password'
        )
      : this.euiI18n.lookupToken(
          'euiFieldPassword.showPassword',
          'Show password as plain text. Note: this will visually expose your password on the screen.'
        );
  }

  registerInput = modifier((element: HTMLInputElement) => {
    this.inputElement = element;
    this.args.inputRef?.(element);
    return () => {
      if (this.inputElement === element) this.inputElement = null;
    };
  });

  @action
  toggle(event: MouseEvent) {
    this.toggledType = this.isVisible ? 'password' : 'text';
    this.inputElement?.focus();
    this.args.dualToggleProps?.onClick?.(event);
  }

  get toggleProps(): EuiFieldPasswordDualToggleProps {
    return this.args.dualToggleProps ?? {};
  }

  get toggleIconType() {
    return this.toggleProps.iconType ?? (this.isVisible ? 'eyeSlash' : 'eye');
  }

  get toggleAriaLabel() {
    return this.toggleProps['aria-label'] ?? this.toggleLabel;
  }

  /** Upstream: `disabled={disabled}`, overridden by the toggle props. */
  get toggleDisabled() {
    return (
      this.toggleProps.isDisabled ??
      this.toggleProps.disabled ??
      this.args.disabled
    );
  }

  inputClasses = (inGroup: boolean) => {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFieldPasswordStyles);
    const { compressed, fullWidth } = this.args;
    return `euiFieldPassword ${euiClass(
      context,
      formControlReset,
      styles.euiFieldPassword,
      compressed ? styles.compressed : styles.uncompressed,
      fullWidth ? styles.fullWidth : styles.formWidth,
      inGroup && styles.inGroup,
      this.isDual && styles.withToggle
    )}`;
  };

  <template>
    {{#let
      (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
      (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
      (argOrDefault @id (randomId))
      as |hasPrepend hasAppend inputId|
    }}
      {{#let
        (this.inputClasses (or hasPrepend hasAppend this.isDual))
        as |classes|
      }}
        <EuiFormControlLayout
          @inputId={{inputId}}
          @icon="lock"
          @clear={{@clear}}
          @fullWidth={{@fullWidth}}
          @isLoading={{@isLoading}}
          @isInvalid={{@isInvalid}}
          @compressed={{@compressed}}
          @readOnly={{@readOnly}}
          @disabled={{@disabled}}
          @isPrependProvided={{hasPrepend}}
          @isAppendProvided={{or hasAppend this.isDual}}
        >
          <:prepend as |prependClasses|>
            {{yield prependClasses inputId to="prepend"}}
          </:prepend>
          <:field>
            <input
              id={{inputId}}
              class={{classes}}
              type={{this.inputType}}
              value={{@value}}
              disabled={{@disabled}}
              readonly={{@readOnly}}
              placeholder={{@placeholder}}
              aria-invalid={{if @isInvalid "true"}}
              {{validatableControl @isInvalid}}
              {{this.registerInput}}
              ...attributes
            />
          </:field>
          <:append as |appendClasses|>
            {{#if hasAppend}}
              {{yield appendClasses inputId to="append"}}
            {{/if}}
            {{#if (eq this.type "dual")}}
              <EuiButtonIcon
                @iconType={{this.toggleIconType}}
                @isDisabled={{this.toggleDisabled}}
                @iconSize={{this.toggleProps.iconSize}}
                @color={{this.toggleProps.color}}
                @display={{this.toggleProps.display}}
                @size={{this.toggleProps.size}}
                @css={{this.toggleProps.css}}
                id={{this.toggleProps.id}}
                class={{this.toggleProps.className}}
                aria-label={{this.toggleAriaLabel}}
                title={{this.toggleLabel}}
                data-test-subj={{this.toggleProps.data-test-subj}}
                {{on "click" this.toggle}}
              />
            {{/if}}
          </:append>
        </EuiFormControlLayout>
      {{/let}}
    {{/let}}
  </template>
}
