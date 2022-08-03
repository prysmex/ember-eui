import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { useFormatTimeString } from '../utils';
import { LocaleSpecifier } from 'moment';
import { getOwner } from '@ember/application';

interface EuiDatePopoverButtonArgs {
  className?: string;
  // buttonProps?: ButtonHTMLAttributes<HTMLButtonElement>;
  dateFormat: string;
  isDisabled?: boolean;
  isInvalid?: boolean;
  isOpen: boolean;
  needsUpdating?: boolean;
  locale?: LocaleSpecifier;
  // onChange: NonNullable<EuiDatePopoverContentProps['onChange']>;
  // onPopoverClose: EuiPopoverProps['closePopover'];
  // onPopoverToggle: MouseEventHandler<HTMLButtonElement>;
  position: 'start' | 'end';
  roundUp?: boolean;
  timeFormat: string;
  value: string;
  utcOffset?: number;
  compressed?: boolean;
  // timeOptions: TimeOptions;
}

export default class EuiDatePopoverButton extends Component<EuiDatePopoverButtonArgs> {
  @tracked isOpen = false;

  get formattedValue() {
    const roundUp = this.args.roundUp ?? false;
    const locale = this.args.locale ?? 'en';

    return useFormatTimeString(
      this.args.value,
      this.args.dateFormat,
      roundUp,
      locale,
      getOwner(this)
    );
  }

  get anchorPosition() {
    return this.args.position === 'start' ? 'downLeft' : 'downRight';
  }
}