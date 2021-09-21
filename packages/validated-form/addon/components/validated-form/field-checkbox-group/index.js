import ValidatedFormFieldBase from '../field-base';
import { action } from '@ember/object';
import { maybeUnwrapProxy } from '@ember-eui/core/utils/maybe-unwrap-proxy';

export default class ValidatedFormFieldCheckboxGroup extends ValidatedFormFieldBase {
  get value() {
    let value = maybeUnwrapProxy(this.args.value);
    return value?.toArray?.() || value;
  }

  get arrayToMap() {
    const currArr = this.value || [];
    return this.transformToMap(currArr);
  }

  transformToMap(value = []) {
    let valuesMap = value.reduce((acc, val) => {
      acc[val] = true;
      return acc;
    }, {});
    return valuesMap;
  }

  @action
  handleChange(optionId) {
    let value = this.value || [];

    const found = value.find((v) => v === optionId);
    let newArr = [];

    if (found) {
      newArr = value.filter((v) => v !== optionId);
    } else {
      newArr = [...value, optionId];
    }

    this.args.onChange?.(newArr);

    this.notifyValidityChange();
    this.isTouched = true;
  }
}
