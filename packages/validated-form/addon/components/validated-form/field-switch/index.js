import ValidatedFormFieldBase from '../field-base';
import { action } from '@ember/object';

export default class ValidatedFormFieldSwitch extends ValidatedFormFieldBase {
  @action
  handleChange(e) {
    e.preventDefault();
    const checked = e.target.checked;
    this.args.onChange?.(checked, e);
    this.notifyValidityChange();
  }
}
