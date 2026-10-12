import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { buttonReset } from '../utils/eui/form-controls.ts';
import { euiSuperSelectControlStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import EuiFormControlLayout from './eui-form-control-layout.gts';

export interface EuiSuperSelectOption<T = string> {
  /** The value passed to `@onChange` when chosen. */
  value: T;
  /** Text shown in the control when selected. */
  inputDisplay?: string;
  /** Text shown in the list; defaults to `inputDisplay`. */
  dropdownDisplay?: string;
  /** Disables the option. */
  disabled?: boolean;
  [key: string]: unknown;
}

/**
 * The button of an `EuiSuperSelect`, showing the selected option, with a
 * hidden `<input>` holding its value for forms. Usually rendered for you
 * by `EuiSuperSelect`.
 */
export interface EuiSuperSelectControlSignature {
  Element: HTMLButtonElement;
  Args: {
    /** The options, to show the selected one. */
    options?: EuiSuperSelectOption<unknown>[];
    /** Value of the selected option. */
    value?: unknown;
    /**
     * `id` of the hidden input. When an element `<id>-label` exists (the
     * label of an `EuiFormRow` given the same `@id`), the button is
     * labelled by it and by its own value, as upstream.
     */
    id?: string;
    /** `name` of the hidden input, for forms. */
    name?: string;
    /** Shown while no option is selected. */
    placeholder?: string;
    /** Takes the container's full width. */
    fullWidth?: boolean;
    /** Smaller, for dense forms. */
    compressed?: boolean;
    /** Shows a spinner. */
    isLoading?: boolean;
    /** Invalid look and the warning icon. */
    isInvalid?: boolean;
    /** Disables the control. */
    disabled?: boolean;
    /** Read-only: shows the value, cannot be opened. */
    readOnly?: boolean;
    /** Focus styles while the list is open (set by `EuiSuperSelect`). */
    isDropdownOpen?: boolean;
    /** @private Whether the `<:prepend>` block has content. Defaults to `has-block`. */
    isPrependProvided?: boolean;
    /** @private Whether the `<:append>` block has content. Defaults to `has-block`. */
    isAppendProvided?: boolean;
    /**
     * @deprecated Has no effect: latest EUI no longer renders a separate
     * screen reader announcement for the control.
     */
    screenReaderId?: string;
  };
  Blocks: {
    /** Renders the selected option yourself; yields it. */
    inputDisplay: [option: EuiSuperSelectOption<unknown>];
    /** Content before the control; yields the class to put on it. */
    prepend: [className: string];
    /** Content after the control; yields the class to put on it. */
    append: [className: string];
  };
}

/**
 * Upstream labels the button with itself and the form row label
 * (`<id>-label`) when one exists, so screen readers read both the label and
 * the value. A caller's own `aria-labelledby` is left alone.
 */
const labelFromFormRow = modifier(
  (button: HTMLButtonElement, [id]: [string | undefined]) => {
    if (!id) return;
    const labelId = `${id}-label`;
    const owned = button.dataset['euiLabelledBy'];

    if (button.hasAttribute('aria-labelledby') && owned === undefined) return;
    if (!button.ownerDocument.getElementById(labelId)) return;

    if (!button.id) button.id = `${id}-button`;
    const value = `${button.id} ${labelId}`;
    button.setAttribute('aria-labelledby', value);
    button.dataset['euiLabelledBy'] = value;
  }
);

export default class EuiSuperSelectControl extends Component<EuiSuperSelectControlSignature> {
  get selectedOption(): EuiSuperSelectOption<unknown> | undefined {
    const value = this.args.value;
    if (value === undefined || value === null) return undefined;
    return this.args.options?.find((option) => option.value === value);
  }

  get showPlaceholder(): boolean {
    return Boolean(this.args.placeholder) && !this.selectedOption;
  }

  get hiddenValue(): string {
    const value = this.args.value;

    return value === undefined || value === null ? '' : String(value as string);
  }

  get stateClasses(): string {
    return [
      'euiSuperSelectControl',
      this.args.isLoading && 'euiSuperSelectControl-isLoading',
      this.args.isInvalid && 'euiSuperSelectControl-isInvalid'
    ]
      .filter(Boolean)
      .join(' ');
  }

  private composeClasses(inGroup: boolean): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSuperSelectControlStyles);
    const { compressed, fullWidth, isDropdownOpen, isInvalid, readOnly, disabled } =
      this.args;

    return `${this.stateClasses} ${euiClass(
      context,
      buttonReset,
      styles.euiSuperSelect__control,
      compressed ? styles.compressed : styles.uncompressed,
      fullWidth ? styles.fullWidth : styles.formWidth,
      inGroup && styles.inGroup,
      isDropdownOpen && styles.open,
      isInvalid && styles.invalid,
      readOnly && styles.readOnly,
      disabled && !readOnly && styles.disabled
    )}`;
  }

  @cached
  get classes(): string {
    return this.composeClasses(false);
  }

  @cached
  get groupClasses(): string {
    return this.composeClasses(true);
  }

  @cached
  get placeholderClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSuperSelectControlStyles);

    return `euiSuperSelectControl__placeholder ${euiClass(
      context,
      styles.euiSuperSelect__placeholder
    )}`;
  }

  get isButtonDisabled(): boolean {
    return Boolean(this.args.disabled || this.args.readOnly);
  }

  <template>
    <input
      type="hidden"
      id={{@id}}
      name={{@name}}
      value={{this.hiddenValue}}
      readonly={{@readOnly}}
    />
    {{#let
      (argOrDefault @isPrependProvided (has-block "prepend"))
      (argOrDefault @isAppendProvided (has-block "append"))
      as |hasPrepend hasAppend|
    }}
      <EuiFormControlLayout
        @isDropdown={{true}}
        @fullWidth={{@fullWidth}}
        @isLoading={{@isLoading}}
        @isInvalid={{@isInvalid}}
        @isDisabled={{@disabled}}
        @readOnly={{@readOnly}}
        @compressed={{@compressed}}
        @isPrependProvided={{hasPrepend}}
        @isAppendProvided={{hasAppend}}
      >
        <:prepend as |className|>{{yield className to="prepend"}}</:prepend>
        <:field>
          <button
            type="button"
            class={{if (or2 hasPrepend hasAppend) this.groupClasses this.classes}}
            aria-haspopup="listbox"
            disabled={{this.isButtonDisabled}}
            {{labelFromFormRow @id}}
            ...attributes
          >
            {{#if this.showPlaceholder}}
              <span class={{this.placeholderClass}}>{{@placeholder}}</span>
            {{else if this.selectedOption}}
              {{#if (has-block "inputDisplay")}}
                {{yield this.selectedOption to="inputDisplay"}}
              {{else}}
                {{this.selectedOption.inputDisplay}}
              {{/if}}
            {{/if}}
          </button>
        </:field>
        <:append as |className|>{{yield className to="append"}}</:append>
      </EuiFormControlLayout>
    {{/let}}
  </template>
}

function or2(a: unknown, b: unknown): boolean {
  return Boolean(a || b);
}
