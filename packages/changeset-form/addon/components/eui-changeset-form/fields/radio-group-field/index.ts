import Base, { BaseArgs } from '../base';
import { action } from '@ember/object';

interface EuiChangesetFormRadioGroupFieldArgs extends BaseArgs {
  onChange?: (value: string) => void;
}

export default class EuiChangesetFormRadioGroupField extends Base<EuiChangesetFormRadioGroupFieldArgs> {
  form: HTMLFormElement | null = null;

  @action
  handleChange(idSelected: string) {
    this.args.changeset.set(this.args.fieldName, idSelected);
    this.validate();
    this.args.onChange?.(idSelected);
  }
}
