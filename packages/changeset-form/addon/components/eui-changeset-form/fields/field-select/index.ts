import Base, { BaseArgs } from '../base';
import { action } from '@ember/object';

interface EuiChangesetFormFieldSelectArgs extends BaseArgs {
  onChange?: (value: string, event: InputEvent) => void;
}

export default class EuiChangesetFormFieldSelect extends Base<EuiChangesetFormFieldSelectArgs> {
  form: HTMLFormElement | null = null;

  @action
  handleInput(e: InputEvent) {
    const value = (e.target as HTMLInputElement).value;
    this.args.changeset.set(this.args.fieldName, value);

    this.args.onChange?.(value, e);
  }
}
