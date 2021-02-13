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
  onChange: (event: Event) => void;
  disabled?: boolean;
  compressed?: boolean;
  type?: 'submit' | 'reset' | 'button';
};

export default class EuiAccordionAccordionComponent extends Component<SwitchArgs> {
  @action
  onClick(e: Event) {
    if (this.args.disabled) {
      return;
    }
    const event = (e as Event) as HTMLInputElement & Event;
    event.target.checked = !this.args.checked;
    this.args.onChange?.(event);
  }
}
