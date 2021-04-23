import ValidatedFormFieldBase from '../field-base';
import { action } from '@ember/object';
import { isArray } from '@ember/array';

export default class ValidatedFormFieldComboBox extends ValidatedFormFieldBase {
  validationProperty = 'args.selectedOptions';

  @action
  handleChange(options) {
    let value = options;
    if (this.args.singleSelection) {
      value = isArray(options) ? options[0] : null;
    }
    this.args.onChange(value);
    this.notifyValidityChange();
  }
}
