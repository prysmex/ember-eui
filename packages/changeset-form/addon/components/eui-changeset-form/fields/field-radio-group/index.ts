import Base, { BaseArgs } from '../base';
import { action } from '@ember/object';

interface EuiChangesetFormFieldRadioGroupArgs extends BaseArgs {
  onChange?: (value: string) => void;
}

export default class EuiChangesetFormFieldRadioGroup extends Base<EuiChangesetFormFieldRadioGroupArgs> {
  form: HTMLFormElement | null = null;

  @action
  handleChange(idSelected: string) {
    this.args.changeset.set(this.args.fieldName, idSelected);
    this.validate();
    this.args.onChange?.(idSelected);
  }
}
