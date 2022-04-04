import ValidatedFormFieldBase from '../field-base';
import { action } from '@ember/object';

export default class ValidatedFormFieldRangeSlider extends ValidatedFormFieldBase {
  @action
  handleChange(e) {
    // The received event for the dual range is an array with [min, max] as strings
    const value = [Number(e[0]), Number(e[1])];
    this.args.onChange(value);
    this.notifyValidityChange();
  }
}
