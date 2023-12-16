import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { assert } from '@ember/debug';
import { hash } from '@ember/helper';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { later } from '@ember/runloop';
import { EuiForm } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';
import { EnsureSafeComponentHelper } from '@embroider/util';

import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';

import FormContext from './eui-changeset-form/context.gts';
import FieldBaseComponent from './eui-changeset-form/fields/field-base.gts';
import FieldCheckboxGroupComponent from './eui-changeset-form/fields/field-checkbox-group.gts';
import FieldComboBoxComponent from './eui-changeset-form/fields/field-combo-box.gts';
import FieldDualRangeSliderComponent from './eui-changeset-form/fields/field-dual-range-slider.gts';
import FieldNumberComponent from './eui-changeset-form/fields/field-number.gts';
import FieldPasswordComponent from './eui-changeset-form/fields/field-password.gts';
import FieldRadioGroupComponent from './eui-changeset-form/fields/field-radio-group.gts';
import FieldRangeSliderComponent from './eui-changeset-form/fields/field-range-slider.gts';
import FieldSelectComponent from './eui-changeset-form/fields/field-select.gts';
import FieldSwitchComponent from './eui-changeset-form/fields/field-switch.gts';
import FieldTextComponent from './eui-changeset-form/fields/field-text.gts';
import FieldTextAreaComponent from './eui-changeset-form/fields/field-text-area.gts';

import type { ContextSignature } from './eui-changeset-form/context.gts';
import type { EuiFieldNumberSignature } from '@ember-eui/core/components/eui-field-number';
import type { EuiFormSignature } from '@ember-eui/core/components/eui-form';
import type { ComponentLike } from '@glint/template';
import type { BufferedChangeset } from 'ember-changeset/types';

export interface IEuiChangesetFormTheme {
  FieldBase: ComponentLike<any>;
  FieldText: ComponentLike<any>;
  FieldTextArea: ComponentLike<any>;
  FieldPassword: ComponentLike<any>;
  FieldRadio: ComponentLike<any>;
  FieldCheckbox: ComponentLike<any>;
  FieldSwitch: ComponentLike<any>;
  FieldRadioGroup: ComponentLike<any>;
  FieldCheckboxGroup: ComponentLike<any>;
  FieldDualRangeSlider: ComponentLike<any>;
  FieldRangeSlider: ComponentLike<any>;
  FieldNumber: ComponentLike<any>;
  FieldSelect: ComponentLike<any>;
  FieldComboBox: ComponentLike<any>;
}

export const DefaultTheme: IEuiChangesetFormTheme = {
  FieldBase: FieldBaseComponent,
  FieldText: FieldTextComponent,
  FieldTextArea: FieldTextAreaComponent,
  FieldPassword: FieldPasswordComponent,
  FieldRadio: FieldTextComponent,
  FieldCheckbox: FieldTextComponent,
  FieldSwitch: FieldSwitchComponent,
  FieldRadioGroup: FieldRadioGroupComponent,
  FieldCheckboxGroup: FieldCheckboxGroupComponent,
  FieldDualRangeSlider: FieldDualRangeSliderComponent,
  FieldRangeSlider: FieldRangeSliderComponent,
  FieldNumber: FieldNumberComponent,
  FieldSelect: FieldSelectComponent,
  FieldComboBox: FieldComboBoxComponent
};

export interface EuiChangesetFormSignature {
  Element: EuiFormSignature['Element'];
  Args: EuiFormSignature['Args'] &
    EuiFieldNumberSignature['Args'] & {
      changeset: BufferedChangeset;
      beforeSubmit?: (changeset: BufferedChangeset, e: Event) => void;
      onSubmit?: (data: {}, e: Event) => void;
      onReset?: (data: {}, e: Event) => void;
      runExecuteInsteadOfSave?: boolean;
      fullWidth?: boolean;
      initialValidation?: boolean;
      theme?: IEuiChangesetFormTheme;
      isDisabled?: boolean;
    };
  Blocks: {
    default: [
      ...ContextSignature['Blocks']['default'],
      BufferedChangeset,
      boolean,
      string
    ];
  };
}

export default class EuiChangesetFormComponent extends Component<EuiChangesetFormSignature> {
  form: HTMLFormElement | null = null;

  @tracked hasSubmitted: boolean = false;

  constructor(owner: unknown, args: EuiChangesetFormSignature['Args']) {
    super(owner, args);
    assert('Must provide a changeset', this.args.changeset);
  }

  get theme() {
    const theme: Partial<IEuiChangesetFormTheme> = this.args.theme || {};

    return { ...DefaultTheme, ...theme };
  }

  @action
  async validate(initialValidation?: boolean) {
    if (initialValidation) {
      later(
        this,
        () => {
          this.args.changeset.validate();
        },
        1
      );
    }
  }

  @action
  async handleSubmit(changeset: BufferedChangeset, event: Event) {
    event.preventDefault();

    if (typeof this.args.beforeSubmit === 'function') {
      this.args.beforeSubmit(changeset, event);
    }

    await changeset.validate();

    this.hasSubmitted = true;

    if (changeset.isInvalid) {
      return;
    }

    let result;

    if (this.args.runExecuteInsteadOfSave) {
      result = changeset.execute();
    } else {
      result = await changeset.save({});
    }

    if (typeof this.args.onSubmit === 'function') {
      this.args.onSubmit(result.data, event);
    }
  }

  @action
  handleReset(changeset: BufferedChangeset, event: Event) {
    event.preventDefault();
    this.hasSubmitted = false;

    const { data } = changeset.rollback();

    if (typeof this.args.onReset === 'function') {
      this.args.onReset(data, event);
    }
  }

  <template>
    {{#let (argOrDefault @id (uniqueId)) as |formId|}}
      <EuiForm
        @tagName="form"
        id={{formId}}
        ...attributes
        {{on "submit" (fn this.handleSubmit @changeset)}}
        {{on "reset" (fn this.handleReset @changeset)}}
        {{didInsert (fn this.validate @initialValidation)}}
      >
        <:content>
          <FormContext
            @formId={{formId}}
            @changeset={{@changeset}}
            @theme={{this.theme}}
            as |Context|
          >
            {{yield
              (hash
                FieldBase=(component
                  (EnsureSafeComponentHelper Context.FieldBase)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldText=(component
                  (EnsureSafeComponentHelper Context.FieldText)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldTextArea=(component
                  (EnsureSafeComponentHelper Context.FieldTextArea)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldPassword=(component
                  (EnsureSafeComponentHelper Context.FieldPassword)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldRadio=(component
                  (EnsureSafeComponentHelper Context.FieldRadio)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldCheckbox=(component
                  (EnsureSafeComponentHelper Context.FieldCheckbox)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldSwitch=(component
                  (EnsureSafeComponentHelper Context.FieldSwitch)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldRadioGroup=(component
                  (EnsureSafeComponentHelper Context.FieldRadioGroup)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldCheckboxGroup=(component
                  (EnsureSafeComponentHelper Context.FieldCheckboxGroup)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldDualRangeSlider=(component
                  (EnsureSafeComponentHelper Context.FieldDualRangeSlider)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldRangeSlider=(component
                  (EnsureSafeComponentHelper Context.FieldRangeSlider)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldNumber=(component
                  (EnsureSafeComponentHelper Context.FieldNumber)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldSelect=(component
                  (EnsureSafeComponentHelper Context.FieldSelect)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  disabled=@isDisabled
                )
                FieldComboBox=(component
                  (EnsureSafeComponentHelper Context.FieldComboBox)
                  fullWidth=@fullWidth
                  hasSubmitted=this.hasSubmitted
                  isDisabled=@isDisabled
                )
              )
              @changeset
              this.hasSubmitted
              formId
            }}
          </FormContext>
        </:content>
      </EuiForm>
    {{/let}}
  </template>
}
