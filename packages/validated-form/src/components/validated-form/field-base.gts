import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { later } from '@ember/runloop';

import {
  buildValidationMessages,
  notifyValidityChange
} from '../../utils/build-validation-messages.js';

import type { ComponentLike } from '@glint/template';

export interface FieldBaseSignature<T = ComponentLike> {
  Args: {
    id?: string;
    value: any;
    label?: string;
    error?: string[];
    options?: any[];
    validations?: any;
    customValidations?: {
      validation(value: any, options?: Record<string, unknown>): boolean;
    }[];
    rowClasses?: string;
    rowExtra?: Record<string, unknown>;
    onChange: (value: any) => void;
    onValidityChange: (isValid: boolean) => void;
    register: (field: T) => void;
    unregister: (field: T) => void;
  };
}

export default class ValidatedFormFieldBase<
  T extends FieldBaseSignature = FieldBaseSignature
> extends Component<T> {
  validationProperty = 'args.value';

  //cache for comparing
  lastIsValid?: boolean;
  lastIsTouched?: boolean;

  @tracked _validationErrorMessages: null | string[] = null;

  @tracked isTouched = false;

  formRowElement: HTMLElement | null = null;

  get validations() {
    return this.args.validations || {};
  }

  get hasErrorMessages() {
    return this._validationErrorMessages?.length || this.error?.length > 0;
  }

  get isValid() {
    return !this.isInvalid;
  }

  get isInvalid() {
    return this.hasErrorMessages;
  }

  get isInvalidAndTouched() {
    return !!(this.isInvalid && this.isTouched);
  }

  get formHasBeenValidated() {
    return this.isTouched;
  }

  set formHasBeenValidated(value) {
    this.isTouched = value;
  }

  get customValidations() {
    return this.args.customValidations || [];
  }

  get rowClasses() {
    return this.args.rowClasses || '';
  }

  get rowExtra() {
    return this.args.rowExtra || {};
  }

  get label() {
    return this.args.label || '';
  }

  get error() {
    return this.args.error || [];
  }

  get options() {
    return this.args.options || [];
  }

  get validationErrorMessages() {
    let error = [];

    if (this.error.length > 0) {
      error.push(...this.error);
    }

    if (
      this._validationErrorMessages &&
      this._validationErrorMessages.length > 0
    ) {
      error.push(...this._validationErrorMessages);
    }

    if (error.length === 0) {
      return null;
    }

    return error;
  }

  constructor(owner: unknown, args: T['Args']) {
    super(owner, args);
    this.args.register?.(this as unknown as ComponentLike);
  }

  //Should be executed by the child on start
  @action
  setValidationMessages(ele?: HTMLElement) {
    this._validationErrorMessages = buildValidationMessages.call(
      this,
      this.validationProperty
    );

    if (ele) {
      this.formRowElement = ele;
    }
  }

  //Should be executed by the child on value update
  @action
  didUpdateValue() {
    later(() => {
      if (!this.isDestroyed && !this.isDestroying) {
        this.setValidationMessages();
        this.notifyValidityChange();
      }
    }, 1);
  }

  @action
  notifyValidityChange() {
    notifyValidityChange(this, this.args.onValidityChange);
  }

  @action
  setIsTouched(val: boolean) {
    this.isTouched = val;
    this.notifyValidityChange();
  }

  /**
   * This is just a default handleChange, you should override this method
   * if you need to or use whatever mechanism to bubble the changed
   * value outside and then notifyValidityChanges
   *
   * @override
   * @param {*} e
   */
  @action
  handleChange(e: Event) {
    const value = (e.target as HTMLInputElement).value;

    this.args.onChange(value);
    this.notifyValidityChange();
  }

  willDestroy() {
    super.willDestroy();
    this.args.unregister?.(this as unknown as ComponentLike);
  }

  <template>
    {{!@glint-expect-error}}
    {{yield this}}
  </template>
}
