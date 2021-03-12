import Base, { BaseArgs } from '../base';
import { action } from '@ember/object';

interface EuiChangesetFormFieldNumberArgs extends BaseArgs {
  onInput?: (value: string, event: InputEvent) => void;
}

export default class EuiChangesetFormFieldNumber extends Base<EuiChangesetFormFieldNumberArgs> {
  form: HTMLFormElement | null = null;

  @action
  handleInput(e: InputEvent) {
    const value = (e.target as HTMLInputElement).value;
    this.args.changeset.set(this.args.fieldName, value);

    this.args.onInput?.(value, e);
  }
}
