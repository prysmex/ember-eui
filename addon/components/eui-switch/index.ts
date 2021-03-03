import Component from '@glimmer/component';
import { action } from '@ember/object';

type SwitchArgs = {
  /**
   * Whether to render the render the text label
   */
  showLabel?: boolean;
  /**
   * Must be a string if `showLabel` prop is false
   */
  label: unknown | string;
  checked: boolean;
  onChange: (event: { target: HTMLInputElement }) => void;
  disabled?: boolean;
  compressed?: boolean;
  type?: 'submit' | 'reset' | 'button';
};

export default class EuiSwitch extends Component<SwitchArgs> {
  @action
  onClick(e: { target: HTMLInputElement }) {
    if (this.args.disabled) {
      return;
    }

    e.target.checked = !this.args.checked;

    this.args.onChange?.(e);
  }
}
