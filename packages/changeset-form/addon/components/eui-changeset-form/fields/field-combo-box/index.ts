import Base, { BaseArgs } from '../base';
import { action } from '@ember/object';
import { isArray } from '@ember/array';

interface EuiChangesetFormFieldComboBoxArgs extends BaseArgs {
  onChange?: (options: any[] | string) => void;
  singleSelection?: { isPlainText: boolean } | boolean;
}

export default class EuiChangesetFormFieldComboBox extends Base<EuiChangesetFormFieldComboBoxArgs> {
  @action
  handleChange(options: any[]) {
    let value: any[] | string = options;
    if (this.args.singleSelection) {
      value = isArray(options) ? options[0] : null;
    }
    this.args.changeset.set(this.args.fieldName, value);
    this.validate();
    this.args.onChange?.(value);
  }
}
