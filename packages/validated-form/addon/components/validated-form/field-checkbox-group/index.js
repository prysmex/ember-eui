import ValidatedFormFieldBase from '../field-base';
import { action } from '@ember/object';

export default class ValidatedFormFieldCheckboxGroup extends ValidatedFormFieldBase {
  get value() {
    return (
      this.args.changeset.get(this.args.fieldName)?.toArray() ||
      this.args.changeset.get(this.args.fieldName)
    );
  }

  get arrayToMap() {
    const currArr = this.args.value || [];
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
