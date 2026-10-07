import Component from '@glimmer/component';
import { inject as service } from '@ember/service';

import EuiFormControlLayout from './eui-form-control-layout.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n';

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
    /** `id` of the hidden input. */
    id?: string;
    /** `name` of the hidden input, for forms. */
    name?: string;
    /** Takes the container's full width. */
    fullWidth?: boolean;
    /** Smaller, for dense forms. */
    compressed?: boolean;
    /** Shows a spinner. */
    isLoading?: boolean;
    /** Invalid look. */
    isInvalid?: boolean;
    /** Id of the element announcing the selection to screen readers. */
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

export default class EuiSuperSelectControl extends Component<EuiSuperSelectControlSignature> {
  @service declare euiI18n: EuiI18n;

  get selectedOption(): EuiSuperSelectOption<unknown> | undefined {
    return this.args.options?.find((option) => option.value === this.args.value);
  }

  get announcement(): string {
    return this.euiI18n.lookupToken(
      'euiSuperSelectControl.selectAnOption',
      'Select an option: {selectedValue}, is selected',
      { selectedValue: this.selectedOption?.inputDisplay ?? '' }
    );
  }

  get hiddenValue(): string {
    const value = this.args.value;

    return value === undefined || value === null ? '' : String(value as string);
  }

  classes = (hasGroup: boolean): string =>
    [
      'euiSuperSelectControl',
      this.args.fullWidth && 'euiSuperSelectControl--fullWidth',
      this.args.compressed && 'euiSuperSelectControl--compressed',
      hasGroup && 'euiSuperSelectControl--inGroup',
      this.args.isLoading && 'euiSuperSelectControl-isLoading',
      this.args.isInvalid && 'euiSuperSelectControl-isInvalid'
    ]
      .filter(Boolean)
      .join(' ');

  <template>
    <input type="hidden" id={{@id}} name={{@name}} value={{this.hiddenValue}} />
    {{#if (or2 (has-block "prepend") (has-block "append"))}}
      <EuiFormControlLayout
        @icon="arrowDown"
        @iconSide="right"
        @fullWidth={{@fullWidth}}
        @isLoading={{@isLoading}}
        @compressed={{@compressed}}
      >
        <:prepend as |className|>{{yield className to="prepend"}}</:prepend>
        <:field>
          <EuiScreenReaderOnly>
            <span id={{@screenReaderId}}>{{this.announcement}}</span>
          </EuiScreenReaderOnly>
          <button
            type="button"
            class={{this.classes true}}
            aria-haspopup="listbox"
            ...attributes
          >
            {{#if this.selectedOption}}
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
    {{else}}
      <EuiFormControlLayout
        @icon="arrowDown"
        @iconSide="right"
        @fullWidth={{@fullWidth}}
        @isLoading={{@isLoading}}
        @compressed={{@compressed}}
      >
        <EuiScreenReaderOnly>
          <span id={{@screenReaderId}}>{{this.announcement}}</span>
        </EuiScreenReaderOnly>
        <button
          type="button"
          class={{this.classes false}}
          aria-haspopup="listbox"
          ...attributes
        >
          {{#if this.selectedOption}}
            {{#if (has-block "inputDisplay")}}
              {{yield this.selectedOption to="inputDisplay"}}
            {{else}}
              {{this.selectedOption.inputDisplay}}
            {{/if}}
          {{/if}}
        </button>
      </EuiFormControlLayout>
    {{/if}}
  </template>
}

function or2(a: unknown, b: unknown): boolean {
  return Boolean(a || b);
}
