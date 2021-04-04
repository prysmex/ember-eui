import Base, { BaseArgs } from '../base';
import { action } from '@ember/object';

interface EuiChangesetFormFieldCheckboxGroupArgs extends BaseArgs {
  onChange?: (value: string[]) => void;
}

export default class EuiChangesetFormFieldCheckboxGroup extends Base<EuiChangesetFormFieldCheckboxGroupArgs> {
  get value(): string[] {
    return (
      this.args.changeset.get(this.args.fieldName)?.toArray() ||
      this.args.changeset.get(this.args.fieldName)
    );
  }

  get arrayToMap() {
    const currArr = this.value || [];
    return this.transformToMap(currArr);
  }

  transformToMap(value: string[] = []) {
    let valuesMap = value.reduce(
      (acc, val: string) => {
        acc[val] = true;
        return acc;
      },
      {} as { [key: string]: boolean }
    );
    return valuesMap;
  }

  @action
  handleChange(optionId: string) {
    let value: string[] = this.value || [];

    const found = value.find((v) => v === optionId);
    let newArr = [];

    if (found) {
      newArr = value.filter((v) => v !== optionId);
    } else {
      newArr = [...value, optionId];
    }
    this.args.changeset.set(this.args.fieldName, newArr);
    this.validate();
    this.args.onChange?.(newArr);
  }
}
