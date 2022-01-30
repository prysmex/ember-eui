import { action } from '@ember/object';
import ValidatedFormFieldBase from '../field-base';

export default class ValidatedFormFieldMarkdownEditor extends ValidatedFormFieldBase {
  @action
  handleChange(str) {
    this.args.onChange(str);
    this.notifyValidityChange();
  }
}
