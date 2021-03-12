import Base, { BaseArgs } from '../base';
import { action } from '@ember/object';

type Values = string[] | [] | undefined;

interface EuiChangesetFormFieldCheckboxGroupArgs extends BaseArgs {
  onChange?: (value: Values) => void;
}

export default class EuiChangesetFormFieldCheckboxGroup extends Base<EuiChangesetFormFieldCheckboxGroupArgs> {
  form: HTMLFormElement | null = null;

  get value(): Values {
    return this.args.changeset.get(this.args.fieldName);
  }

  get arrayToMap() {
    const currArr = this.value || [];
    return this.transformToMap(currArr);
  }

  transformToMap(value: string[] = []) {
    return value.reduce((acum, currVal) => {
      return {
        [currVal]: true,
        ...acum
      };
    }, {});
  }

  @action
  handleChange(optionId: string) {
    const value: string[] = this.value || [];
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
