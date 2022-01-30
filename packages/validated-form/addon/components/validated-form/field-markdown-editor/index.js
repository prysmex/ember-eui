import { action } from '@ember/object';
import ValidatedFormFieldBase from '../field-base';

export default class ValidatedFormFieldMarkdownEditor extends ValidatedFormFieldBase {
  @action
  handleChange(str) {
    super.handleChange({ target: { value: str } });
  }
}
