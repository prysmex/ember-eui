import Base, { BaseArgs } from '../base';
import { action } from '@ember/object';
import { isArray } from '@ember/array';
import { assert } from '@ember/debug';

interface EuiChangesetFormFieldComboBoxArgs extends BaseArgs {
  onChange: (options: any[] | string) => void;
  singleSelection?: { isPlainText: boolean } | boolean;
}

/**
 * In order to provide full flexibility, this component doesn't handle the setting
 * or hardcodes the selected
 */
export default class EuiChangesetFormFieldComboBox extends Base<EuiChangesetFormFieldComboBoxArgs> {
  constructor(owner: unknown, args: EuiChangesetFormFieldComboBoxArgs) {
    super(owner, args);

    assert(
      `Must provide @onChange to FieldComboBox for ${this.args.fieldName}`,
      this.args.onChange
    );
  }

  @action
  handleChange(options: any[]) {
    let value: any[] | string = options;
    if (this.args.singleSelection) {
      value = isArray(options) ? options[0] : null;
    }
    this.args.onChange(value);
    this.validate();
  }
}
