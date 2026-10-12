import Component from '@glimmer/component';
import { fn, get } from '@ember/helper';
import { on } from '@ember/modifier';

import { or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import validatableControl from '../modifiers/validatable-control.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiCheckboxGroupStyles } from '../utils/eui/styles.generated.ts';
import EuiCheckbox from './eui-checkbox.gts';
import EuiFormFieldset from './eui-form-fieldset.gts';

import type { EuiCheckboxSignature } from './eui-checkbox';
import type { EuiFormFieldsetSignature } from './eui-form-fieldset';

export interface EuiCheckboxGroupSignature {
  /** The group `<div>`, or the `<fieldset>` when `@legend` is set. */
  Element: HTMLDivElement | HTMLFieldSetElement;
  Args: {
    /**
     * Key of each option holding its id, used with `@idToSelectedMap` and
     * passed to `@onChange`. Defaults to `'id'`; pass `'value'` for options
     * shaped like `{ value, label }`.
     */
    valueKey?: string;
    /** Key of each option holding its label. Defaults to `'label'`. */
    labelKey?: string;
    /**
     * Marks the group invalid for native form validation (e.g. EuiForm's
     * `checkValidity()`).
     */
    isInvalid?: boolean;
    /**
     * Wraps the checkboxes in an `EuiFormFieldset` with this legend, e.g.
     * "Choose toppings". Use it when the group is not inside an
     * `EuiFormRow`.
     */
    legend?: EuiFormFieldsetSignature['Args']['legend'];
    /** Removes the spacing between checkbox rows, for dense forms. */
    compressed?: EuiFormFieldsetSignature['Args']['compressed'];
    /**
     * The checkboxes: `[{ id: 'a', label: 'Option A' }, …]` (keys set by
     * `@valueKey` / `@labelKey`). `disabled` and `className` apply to one
     * checkbox.
     */
    options: {
      value: string;
      label: string;
      disabled?: boolean;
      className?: string;
    }[];
    /** `form` attribute of the checkboxes, to join a form by id. */
    formId?: string;
    /** @deprecated Has no effect; use `@legend` or an `EuiFormRow` label. */
    label?: EuiCheckboxSignature['Args']['label'];
    /** Disables every checkbox. */
    disabled?: EuiCheckboxSignature['Args']['disabled'];
    /**
     * Called with the id (`@valueKey` value) of the checkbox that changed,
     * then the change event. Toggle it in `@idToSelectedMap` here.
     */
    onChange: (value: any) => void;
    /** Checked state by option id: `{ a: true, b: false }`. */
    idToSelectedMap: Record<string, boolean>;
  };
}

export default class EuiCheckboxGroup extends Component<EuiCheckboxGroupSignature> {
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiCheckboxGroupStyles);
    return euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiCheckboxGroup,
      this.args.compressed ? styles.compressed : styles.uncompressed
    );
  }

  <template>
    {{#let
      (argOrDefault @valueKey "id") (argOrDefault @labelKey "label")
      as |valueKey labelKey|
    }}
      {{!template-lint-disable}}
      <input
        tabindex="-1"
        style="opacity: 0px; width:0px; height:0px; position: absolute; top: 40%; border:solid 1px transparent !important; margin:0px !important;"
        class="fake-input-for-html-form-validity"
        {{validatableControl @isInvalid}}
      />
      {{!template-lint-enable}}
      {{#if @legend}}
        <EuiFormFieldset
          class="euiCheckboxGroup {{this.classes}}"
          @legend={{@legend}}
          @compressed={{@compressed}}
          ...attributes
        >
          {{#each @options key=valueKey as |option|}}
            <EuiCheckbox
              form={{@formId}}
              class="euiCheckboxGroup__item {{option.className}}"
              {{!@glint-expect-error}}
              @checked={{get @idToSelectedMap (get option valueKey)}}
              @disabled={{or @disabled option.disabled}}
              {{!@glint-expect-error}}
              @label={{get option labelKey}}
              {{on "change" (fn @onChange (get option valueKey))}}
            />
          {{/each}}
        </EuiFormFieldset>
      {{else}}
        <div class="euiCheckboxGroup {{this.classes}}" ...attributes>
          {{#each @options key=valueKey as |option|}}
            <EuiCheckbox
              form={{@formId}}
              class="euiCheckboxGroup__item {{option.className}}"
              {{!@glint-expect-error}}
              @checked={{get @idToSelectedMap (get option valueKey)}}
              @disabled={{or @disabled option.disabled}}
              {{!@glint-expect-error}}
              @label={{get option labelKey}}
              {{on "change" (fn @onChange (get option valueKey))}}
            />
          {{/each}}
        </div>
      {{/if}}
    {{/let}}
  </template>
}
