import Base, { BaseArgs } from '../base';
import { action } from '@ember/object';

interface EuiChangesetFormFieldComboBoxArgs extends BaseArgs {
  onChange?: (options: any[]) => void;
  singleSelection?: { isPlainText: boolean } | boolean;
}

export default class EuiChangesetFormFieldComboBox extends Base<EuiChangesetFormFieldComboBoxArgs> {
  @action
  handleChange(options: any[]) {
    this.args.changeset.set(this.args.fieldName, options);

    this.validate();
    this.args.onChange?.(options);
  }
}
