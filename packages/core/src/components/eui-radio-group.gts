import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { fn, get } from '@ember/helper';
import { on } from '@ember/modifier';

import { eq, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiRadioGroupStyles } from '../utils/eui/styles.generated.ts';
import EuiFormFieldset from './eui-form-fieldset.gts';
import EuiRadio from './eui-radio.gts';

/** A group of radios to pick one option. */
export interface EuiRadioGroupSignature {
  /** The group `<div>`, or the `<fieldset>` when `@legend` is set. */
  Element: HTMLDivElement | HTMLFieldSetElement;
  Args: {
    /** Id (`@valueKey` value) of the checked option. */
    idSelected: string;
    /**
     * The radios: `[{ id: 'a', label: 'Option A' }, …]` (keys set by
     * `@valueKey` / `@labelKey`); `value`, `disabled` and `className` are
     * optional.
     */
    options: Array<{
      id: string;
      label: string;
      value?: string;
      disabled?: boolean;
      className?: string;
    }>;
    /** `name` shared by the radios. Defaults to a random name. */
    name?: string;
    /**
     * Wraps the radios in an `EuiFormFieldset` with this legend. Use it when
     * the group is not inside an `EuiFormRow`.
     */
    legend?: string;
    /** Removes the spacing between radio rows, for dense forms. */
    compressed?: boolean;
    /** Disables every radio. */
    disabled?: boolean;
    /**
     * Called with the chosen option's id and its `value`. Update
     * `@idSelected` here.
     */
    onChange: (id: string, value?: string) => void;
    /** Key of each option holding its id. Defaults to `'id'`. */
    valueKey?: string;
    /** Key of each option holding its label. Defaults to `'label'`. */
    labelKey?: string;
    /** `form` attribute of the radios, to join a form by id. */
    formId?: string;
  };
}

export default class EuiRadioGroup extends Component<EuiRadioGroupSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiRadioGroupStyles);
    return euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiRadioGroup,
      this.args.compressed ? styles.compressed : styles.uncompressed
    );
  }

  <template>
    {{#let
      (argOrDefault @valueKey "id")
      (argOrDefault @labelKey "label")
      (argOrDefault @name (randomId))
      as |valueKey labelKey name|
    }}
      {{#if @legend}}
        <EuiFormFieldset
          class="euiRadioGroup {{this.classes}}"
          @legend={{@legend}}
          @compressed={{@compressed}}
          ...attributes
        >
          {{#each @options key="id" as |option|}}
            <EuiRadio
              class="euiRadioGroup__item {{option.className}}"
              form={{@formId}}
              @name={{name}}
              @checked={{eq @idSelected (get option valueKey)}}
              @disabled={{or @disabled option.disabled}}
              {{!@glint-expect-error}}
              @label={{get option labelKey}}
              {{!@glint-expect-error}}
              {{on "change" (fn @onChange (get option valueKey) option.value)}}
            />
          {{/each}}
        </EuiFormFieldset>
      {{else}}
        <div class="euiRadioGroup {{this.classes}}" ...attributes>
          {{#each @options key="id" as |option|}}
            <EuiRadio
              class="euiRadioGroup__item {{option.className}}"
              form={{@formId}}
              @name={{name}}
              @checked={{eq @idSelected (get option valueKey)}}
              @disabled={{or @disabled option.disabled}}
              {{!@glint-expect-error}}
              @label={{get option labelKey}}
              {{!@glint-expect-error}}
              {{on "change" (fn @onChange (get option valueKey) option.value)}}
            />
          {{/each}}
        </div>
      {{/if}}
    {{/let}}
  </template>
}
