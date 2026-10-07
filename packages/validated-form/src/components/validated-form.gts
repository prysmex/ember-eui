import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { A } from '@ember/array';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { next, schedule } from '@ember/runloop';
import EuiForm from '@ember-eui/core/components/eui-form';
import { argOrDefault } from '@ember-eui/core/helpers';
import type Owner from '@ember/owner';

import randomId from '../-private/random-id.ts';
import { ValidatedFormDefaultTheme } from './default-theme.ts';

import type { IValidatedFormTheme } from './default-theme';
import type FieldBase from './validated-form/field-base.gts';
import type { EuiFormSignature } from '@ember-eui/core/components/eui-form';

export type ValidatedFormChild = FieldBase | ValidatedFormComponent;

/**
 * A form whose fields validate their own values with ember-validators
 * (`@validations`) or functions (`@customValidations`). Errors show once a
 * field is touched; submitting calls `@onSubmit` only when all fields are
 * valid.
 */
export interface ValidatedFormSignature {
  Element: EuiFormSignature['Element'];
  Args: {
    /** Id of the form; fields join it with `form=`. Defaults to a random id. */
    id?: string;
    /** HTML form that owns the fields; inherited by nested forms. */
    formId?: string;
    /** @private Nested forms register with their parent form. */
    register?: (child: ValidatedFormComponent) => void;
    /** @private Nested forms register with their parent form. */
    unregister?: (child: ValidatedFormComponent) => void;
    /** @private */
    addChild?: (child: ValidatedFormChild) => void;
    /** @private */
    removeChild?: (child: ValidatedFormChild) => void;
    /** Called on submit while a field is invalid (all fields show their errors). */
    onInvalid?: () => void;
    /**
     * Called on submit when every field is valid. If it returns a promise
     * that rejects, the fields are marked touched again.
     */
    onSubmit?: () => void | Promise<void>;
    /** Called when the form is reset. */
    onReset?: (e: Event) => void;
    /**
     * Called when the form's validity or touched state changes, e.g. to
     * disable the submit button while invalid.
     */
    onValidityChange?: (
      isValid: boolean,
      isTouched: boolean,
      isInvalidAndTouched: boolean
    ) => void;
    /** Replaces the yielded field components (see the theme docs). */
    theme?: Partial<IValidatedFormTheme>;
    /** Disables every field. */
    isDisabled?: boolean;
    /** Makes every field full width. */
    fullWidth?: boolean;
    /** Compressed fields, for dense forms. */
    compressed?: boolean;
    /** `'form'` (the default) or `'div'`. */
    tagName?: EuiFormSignature['Args']['tagName'];
    /** Shows `@error` in a callout above the form, see EuiForm. */
    isInvalid?: EuiFormSignature['Args']['isInvalid'];
    /** See EuiForm's `@invalidCallout`. */
    invalidCallout?: EuiFormSignature['Args']['invalidCallout'];
    /** Form-level errors, see EuiForm's `@error`. */
    error?: EuiFormSignature['Args']['error'];
    /** Title of the errors callout. */
    errorTitle?: EuiFormSignature['Args']['errorTitle'];
  };
  Blocks: {
    /**
     * Yields the form's state (`isValid`, `isInvalid`, `isTouched`,
     * `isInvalidAndTouched`, `formId`) and its field components, already
     * connected to it: `as |form|` → `<form.FieldText @label="Name"
     * @value={{this.name}} @onChange={{…}} @validations={{…}} />`.
     */
    default: [
      {
        onValidityChange: (
          isValid: boolean,
          isTouched: boolean,
          isInvalidAndTouched: boolean
        ) => void;
        register: (child: ValidatedFormChild) => void;
        unregister: (child: ValidatedFormChild) => void;
        isValid: boolean;
        isInvalid: boolean;
        isTouched: boolean;
        isInvalidAndTouched: boolean;
        formId: string;
        Form: IValidatedFormTheme['FieldNestedForm'];
        FieldNestedForm: IValidatedFormTheme['FieldNestedForm'];
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
  @tracked childComponents: ReturnType<typeof A<ValidatedFormChild>> = A<ValidatedFormChild>([]);
  //cache to only notify if changed
  lastIsValid?: boolean;
  lastIsTouched?: boolean;

  @tracked isInvalid = false;
  @tracked isTouched = false;

  constructor(owner: Owner, args: ValidatedFormSignature['Args']) {
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

  addChild(child: ValidatedFormChild) {
    this.childComponents.pushObject(child);
    this.triggerValidityChange();
  }

  removeChild(child: ValidatedFormChild) {
    this.childComponents.removeObject(child);
  }

  @action
  async handleSubmit(e: Event) {
    if (e.target !== e.currentTarget) {
      return;
    }

    e.preventDefault();

    if (this.isInvalid) {
      this.setIsTouched(true);
      this.args.onInvalid?.();
    } else {
      this.setIsTouched(false);

      try {
        await this.args.onSubmit?.();
      } catch {
        this.setIsTouched(true);
      }
    }
  }

  @action
  setIsTouched(isTouched: boolean) {
    this.childComponents.forEach((child) => child.setIsTouched(isTouched));
    this.updateValidity();
  }

  @action
  handleReset(e: Event) {
    if (e.target !== e.currentTarget) {
      return;
    }

    e.preventDefault();
    this.args.onReset?.(e);
  }

  @action
  register(child: ValidatedFormChild) {
    if (!this.isDestroyed) {
      schedule('afterRender', this, this.addChild, child);
    }
  }

  @action
  unregister(child: ValidatedFormChild) {
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
      if (this.isDestroying || this.isDestroyed) {
        return;
      }

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

  @action
  onFocusOut(e: FocusEvent) {
    const targetEuiFormRow = (e.target as HTMLInputElement)?.closest?.('.euiFormRow');

    if (!targetEuiFormRow) {
      return;
    }

    this.childComponents
      .find((child) => {
        return 'formRowElement' in child && targetEuiFormRow === child.formRowElement;
      })
      ?.setIsTouched(true);
  }

  get theme() {
    const theme: Partial<IValidatedFormTheme> = this.args.theme || {};

    return { ...ValidatedFormDefaultTheme, ...theme };
  }

  <template>
    {{#let (argOrDefault @id (randomId)) as |formId|}}
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
        {{on "focusout" this.onFocusOut}}
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
            formId=(argOrDefault @formId formId)
            Form=(component
              this.theme.FieldNestedForm
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              tagName="div"
              formId=(argOrDefault @formId formId)
              theme=@theme
              isDisabled=@isDisabled
              fullWidth=@fullWidth
              compressed=@compressed
            )
            FieldNestedForm=(component
              this.theme.FieldNestedForm
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              tagName="div"
              formId=(argOrDefault @formId formId)
              theme=@theme
              isDisabled=@isDisabled
              fullWidth=@fullWidth
              compressed=@compressed
            )
            FieldBase=(component
              this.theme.FieldBase
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              formId=(argOrDefault @formId formId)
              disabled=@isDisabled
            )
            FieldNumber=(component
              this.theme.FieldNumber
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              compressed=@compressed
              formId=(argOrDefault @formId formId)
              disabled=@isDisabled
            )
            FieldText=(component
              this.theme.FieldText
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              compressed=@compressed
              formId=(argOrDefault @formId formId)
              disabled=@isDisabled
            )
            FieldPassword=(component
              this.theme.FieldPassword
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              compressed=@compressed
              formId=(argOrDefault @formId formId)
              disabled=@isDisabled
            )
            FieldTextArea=(component
              this.theme.FieldTextArea
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              compressed=@compressed
              formId=(argOrDefault @formId formId)
              disabled=@isDisabled
            )
            FieldSelect=(component
              this.theme.FieldSelect
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              compressed=@compressed
              formId=(argOrDefault @formId formId)
              disabled=@isDisabled
            )
            FieldComboBox=(component
              this.theme.FieldComboBox
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              compressed=@compressed
              formId=(argOrDefault @formId formId)
              isDisabled=@isDisabled
            )
            FieldCheckboxGroup=(component
              this.theme.FieldCheckboxGroup
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              compressed=@compressed
              formId=(argOrDefault @formId formId)
              disabled=@isDisabled
            )
            FieldRadioGroup=(component
              this.theme.FieldRadioGroup
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              compressed=@compressed
              formId=(argOrDefault @formId formId)
              disabled=@isDisabled
            )
            FieldRangeSlider=(component
              this.theme.FieldRangeSlider
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              compressed=@compressed
              formId=(argOrDefault @formId formId)
              disabled=@isDisabled
            )
            FieldDualRangeSlider=(component
              this.theme.FieldDualRangeSlider
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              compressed=@compressed
              formId=(argOrDefault @formId formId)
              disabled=@isDisabled
            )
            FieldSwitch=(component
              this.theme.FieldSwitch
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              compressed=@compressed
              formId=(argOrDefault @formId formId)
              disabled=@isDisabled
            )
            FieldMarkdownEditor=(component
              this.theme.FieldMarkdownEditor
              register=this.register
              unregister=this.unregister
              onValidityChange=this.onChildValidityChange
              fullWidth=@fullWidth
              compressed=@compressed
              formId=(argOrDefault @formId formId)
              disabled=@isDisabled
            )
          )
        }}
      </EuiForm>
    {{/let}}
  </template>
}
