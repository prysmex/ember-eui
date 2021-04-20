import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import {
  buildValidationMessages,
  notifyValidityChange
} from '../../../utils/build-validation-messages';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ValidatedFormFieldBase extends Component {
  validationProperty = 'args.value';

  //cache for comparing
  lastIsValid;
  lastIsTouched;

  @tracked isTouched = false;

  get validations() {
    return this.args.validations || {}
  }
  
  get hasErrorMessages() {
    return this.validationErrorMessages?.length;
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

  @cached
  get validationErrorMessages() {
    return buildValidationMessages.call(this, this.validationProperty);
  }

  constructor() {
    super(...arguments);
    this.args.register?.(this);
  }

  @action
  notifyValidityChange() {
    notifyValidityChange.call(this);
  }

  @action
  didUpdateValue() {
    this.notifyValidityChange();
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
