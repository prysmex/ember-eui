import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import {
  buildValidationMessages,
  notifyValidityChange
} from '../../../utils/build-validation-messages';
import { action } from '@ember/object';
import { later } from '@ember/runloop';

export default class ValidatedFormFieldBase extends Component {
  validationProperty = 'args.value';

  //cache for comparing
  lastIsValid;
  lastIsTouched;

  @tracked _validationErrorMessages = null;

  @tracked isTouched = false;

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
    return this.isInvalid && this.isTouched;
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

  constructor() {
    super(...arguments);
    this.args.register?.(this);
  }

  //Should be executed by the child on start
  @action
  setValidationMessages() {
    this._validationErrorMessages = buildValidationMessages.call(
      this,
      this.validationProperty
    );
  }

  //Should be executed by the child on value update
  @action
  didUpdateValue() {
    later(() => {
      if (!this.isDestroyed && !this.isDestroying) {
        this.setValidationMessages();
        this.notifyValidityChange();
      }
    });
  }

  @action
  notifyValidityChange() {
    notifyValidityChange(this, this.args.onValidityChange);
  }

  @action
  setIsTouched(val) {
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
  handleChange(e) {
    const value = e.target.value;
    this.args.onChange(value);
    this.notifyValidityChange();
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.args.unregister?.(this);
  }
}
