import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { A } from '@ember/array';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { next, schedule } from '@ember/runloop';
import { EuiForm } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';

import FieldBase from './validated-form/field-base.gts';
import FieldCheckboxGroupComponent from './validated-form/field-checkbox-group.gts';
import FieldComboBoxComponent from './validated-form/field-combo-box.gts';
import FieldDualRangeSliderComponent from './validated-form/field-dual-range-slider.gts';
import FieldMarkdownEditorComponent from './validated-form/field-markdown-editor.gts';
import FieldNumberComponent from './validated-form/field-number.gts';
import FieldPasswordComponent from './validated-form/field-password.gts';
import FieldRadioGroupComponent from './validated-form/field-radio-group.gts';
import FieldRangeSliderComponent from './validated-form/field-range-slider.gts';
import FieldSelectComponent from './validated-form/field-select.gts';
import FieldSwitchComponent from './validated-form/field-switch.gts';
import FieldTextComponent from './validated-form/field-text.gts';
import FieldTextAreaComponent from './validated-form/field-text-area.gts';

import type { EuiFormSignature } from '@ember-eui/core/components/eui-form';
import type { ComponentLike } from '@glint/template';

export interface IValidatedFormTheme {
  FieldBase: ComponentLike<any>;
  FieldNumber: ComponentLike<any>;
  FieldText: ComponentLike<any>;
  FieldPassword: ComponentLike<any>;
  FieldTextArea: ComponentLike<any>;
  FieldSelect: ComponentLike<any>;
  FieldComboBox: ComponentLike<any>;
  FieldCheckboxGroup: ComponentLike<any>;
  FieldRadioGroup: ComponentLike<any>;
  FieldRangeSlider: ComponentLike<any>;
  FieldDualRangeSlider: ComponentLike<any>;
  FieldSwitch: ComponentLike<any>;
  FieldMarkdownEditor: ComponentLike<any>;
}

export const ValidatedFormDefaultTheme: IValidatedFormTheme = {
  FieldBase: FieldBase,
  FieldNumber: FieldNumberComponent,
  FieldText: FieldTextComponent,
  FieldPassword: FieldPasswordComponent,
  FieldTextArea: FieldTextAreaComponent,
  FieldSelect: FieldSelectComponent,
  FieldComboBox: FieldComboBoxComponent,
  FieldCheckboxGroup: FieldCheckboxGroupComponent,
  FieldRadioGroup: FieldRadioGroupComponent,
  FieldRangeSlider: FieldRangeSliderComponent,
  FieldDualRangeSlider: FieldDualRangeSliderComponent,
  FieldSwitch: FieldSwitchComponent,
  FieldMarkdownEditor: FieldMarkdownEditorComponent
};

export interface ValidatedFormSignature {
  Element: EuiFormSignature['Element'];
  Args: {
    id?: string;
    register?: (child: ValidatedFormComponent) => void;
    unregister?: (child: ValidatedFormComponent) => void;
    addChild?: (child: FieldBase) => void;
    removeChild?: (child: FieldBase) => void;
    onInvalid?: () => void;
    onSubmit?: () => void;
    onReset?: (e: Event) => void;
    onValidityChange?: (
      isValid: boolean,
      isTouched: boolean,
      isInvalidAndTouched: boolean
    ) => void;
    theme?: Partial<IValidatedFormTheme>;
    isDisabled?: boolean;
    fullWidth?: boolean;
    tagName?: EuiFormSignature['Args']['tagName'];
    isInvalid?: EuiFormSignature['Args']['isInvalid'];
    invalidCallout?: EuiFormSignature['Args']['invalidCallout'];
    error?: EuiFormSignature['Args']['error'];
    errorTitle?: EuiFormSignature['Args']['errorTitle'];
  };
  Blocks: {
    default: [
      {
        onValidityChange: (
          isValid: boolean,
          isTouched: boolean,
          isInvalidAndTouched: boolean
        ) => void;
        register: (child: FieldBase) => void;
        unregister: (child: FieldBase) => void;
        isValid: boolean;
        isInvalid: boolean;
        isTouched: boolean;
        isInvalidAndTouched: boolean;
        formId: string;
        FieldBase: IValidatedFormTheme['FieldBase'];
        FieldNumber: IValidatedFormTheme['FieldNumber'];
        FieldText: IValidatedFormTheme['FieldText'];
        FieldPassword: IValidatedFormTheme['FieldPassword'];
        FieldTextArea: IValidatedFormTheme['FieldTextArea'];
        FieldSelect: IValidatedFormTheme['FieldSelect'];
        FieldComboBox: IValidatedFormTheme['FieldComboBox'];
        FieldCheckboxGroup: IValidatedFormTheme['FieldCheckboxGroup'];
        FieldRadioGroup: IValidatedFormTheme['FieldRadioGroup'];
        FieldRangeSlider: IValidatedFormTheme['FieldRangeSlider'];
        FieldDualRangeSlider: IValidatedFormTheme['FieldDualRangeSlider'];
        FieldSwitch: IValidatedFormTheme['FieldSwitch'];
        FieldMarkdownEditor: IValidatedFormTheme['FieldMarkdownEditor'];
      }
    ];
  };
}

export default class ValidatedFormComponent extends Component<ValidatedFormSignature> {
  @tracked childComponents = A<FieldBase>([]);
  //cache to only notify if changed
  lastIsValid?: boolean;
  lastIsTouched?: boolean;

  @tracked isInvalid = false;
  @tracked isTouched = false;

  constructor(owner: unknown, args: ValidatedFormSignature['Args']) {
    super(owner, args);
    this.args.register?.(this);
  }

  willDestroy() {
    super.willDestroy();
    this.args.unregister?.(this);
  }

  get isValid() {
    return !this.isInvalid;
  }

  get isInvalidAndTouched() {
    return this.isInvalid && this.isTouched;
  }

  addChild(child: FieldBase) {
    this.childComponents.pushObject(child);
  }

  removeChild(child: FieldBase) {
    this.childComponents.removeObject(child);
  }

  @action
  async handleSubmit(e: Event) {
    e.preventDefault();

    if (this.isInvalid) {
      this.childComponents.setEach('isTouched', true);
      this.args.onInvalid?.();
    } else {
      this.childComponents.setEach('isTouched', false);

      try {
        await this.args.onSubmit?.();
      } catch (e) {
        this.childComponents.setEach('isTouched', true);
      }
    }
  }

  @action
  handleReset(e: Event) {
    e.preventDefault();
    this.args.onReset?.(e);
  }

  @action
  register(child: FieldBase) {
    if (!this.isDestroyed) {
      schedule('afterRender', this, this.addChild, child);
    }
  }

  @action
  unregister(child: FieldBase) {
    if (!this.isDestroyed) {
      schedule('afterRender', this, this.removeChild, child);
      // When adding a child the validation gets calculated on a `did-insert` modifier
      // for removal there's no modifier so it gets called here
      schedule('afterRender', this, this.triggerValidityChange);
    }
  }

  @action
  updateValidity() {
    this.triggerValidityChange();
  }

  getIsValid() {
    return this.childComponents.isEvery('isValid');
  }

  getIsTouched() {
    return this.childComponents.isAny('isTouched');
  }

  triggerValidityChange() {
    const lastIsValid = this.isValid;
    const lastIsTouched = this.isTouched;

    if (
      lastIsValid !== this.getIsValid() ||
      lastIsTouched !== this.getIsTouched()
    ) {
      this.setNewValidity();
    }
  }

  @action
  setNewValidity() {
    next(() => {
      this.isInvalid = !this.getIsValid();
      this.isTouched = this.getIsTouched();

      if (!this.isDestroying) {
        this.args.onValidityChange?.(
          this.isValid,
          this.isTouched,
          this.isInvalidAndTouched
        );
      }
    });
  }

  @action
  onChildValidityChange() {
    if (!this.isDestroying) {
      this.updateValidity();
    }
  }

  get theme() {
    const theme: Partial<IValidatedFormTheme> = this.args.theme || {};

    return { ...ValidatedFormDefaultTheme, ...theme };
  }

  <template>
    {{#let (argOrDefault @id (uniqueId)) as |formId|}}
      <EuiForm
        @tagName={{argOrDefault @tagName "form"}}
        id={{formId}}
        @isInvalid={{@isInvalid}}
        @invalidCallout={{@invalidCallout}}
        @error={{@error}}
        @errorTitle={{@errorTitle}}
        {{on "submit" this.handleSubmit}}
        {{on "reset" this.handleReset}}
        {{didInsert this.setNewValidity}}
        ...attributes
      >
        {{yield
          (hash
            onValidityChange=this.onChildValidityChange
            register=this.register
            unregister=this.unregister
            isValid=this.isValid
            isInvalid=this.isInvalid
            isTouched=this.isTouched
            isInvalidAndTouched=this.isInvalidAndTouched
            formId=formId
            FieldBase=(component
              this.theme.FieldBase
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              formId=formId
              disabled=@isDisabled
            )
            FieldNumber=(component
              this.theme.FieldNumber
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              formId=formId
              disabled=@isDisabled
            )
            FieldText=(component
              this.theme.FieldText
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              formId=formId
              disabled=@isDisabled
            )
            FieldPassword=(component
              this.theme.FieldPassword
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              formId=formId
              disabled=@isDisabled
            )
            FieldTextArea=(component
              this.theme.FieldTextArea
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              formId=formId
              disabled=@isDisabled
            )
            FieldSelect=(component
              this.theme.FieldSelect
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              formId=formId
              disabled=@isDisabled
            )
            FieldComboBox=(component
              this.theme.FieldComboBox
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              formId=formId
              isDisabled=@isDisabled
            )
            FieldCheckboxGroup=(component
              this.theme.FieldCheckboxGroup
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              formId=formId
              disabled=@isDisabled
            )
            FieldRadioGroup=(component
              this.theme.FieldRadioGroup
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              formId=formId
              disabled=@isDisabled
            )
            FieldRangeSlider=(component
              this.theme.FieldRangeSlider
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              formId=formId
              disabled=@isDisabled
            )
            FieldDualRangeSlider=(component
              this.theme.FieldDualRangeSlider
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              formId=formId
              disabled=@isDisabled
            )
            FieldSwitch=(component
              this.theme.FieldSwitch
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              formId=formId
              disabled=@isDisabled
            )
            FieldMarkdownEditor=(component
              this.theme.FieldMarkdownEditor
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              formId=formId
              disabled=@isDisabled
            )
          )
        }}
      </EuiForm>
    {{/let}}
  </template>
}
