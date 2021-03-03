import Base, { BaseArgs } from "../base";
import { action } from "@ember/object";

interface EuiChangesetFormSwitchFieldArgs extends BaseArgs {
  onChange?: (value: boolean, event: InputEvent) => void;
}

export default class EuiChangesetFormSwitchField extends Base<EuiChangesetFormSwitchFieldArgs> {
  form: HTMLFormElement | null = null;

  @action
  handleChange(e: InputEvent) {
    e.preventDefault();
    const checked = (e.target as HTMLInputElement).checked;
    this.args.changeset.set(this.args.fieldName, checked);
    this.validate();
    this.args.onChange?.(checked, e);
  }
}
