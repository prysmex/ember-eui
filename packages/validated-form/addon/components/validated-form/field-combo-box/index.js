import ValidatedFormFieldBase from '../field-base';
import { action } from '@ember/object';

export default class ValidatedFormFieldComboBox extends ValidatedFormFieldBase {
  validationProperty = 'args.selectedOptions';

  @action
  handleChange(options) {
    this.args.onChange(options);
    this.notifyValidityChange();
  }
}
