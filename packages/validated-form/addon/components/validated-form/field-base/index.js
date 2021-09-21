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
    return this._validationErrorMessages?.length;
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

  get label() {
    return this.args.label || '';
  }

  get errors() {
    return this.args.errors || [];
  }

  get options() {
    return this.args.options || [];
  }

  get validationErrorMessages() {
    return this._validationErrorMessages;
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
      this.setValidationMessages();
      this.notifyValidityChange();
    });
  }

  @action
  notifyValidityChange() {
    notifyValidityChange.call(this);
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
