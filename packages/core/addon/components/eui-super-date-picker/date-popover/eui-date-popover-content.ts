import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { toAbsoluteString, getDateMode } from '../utils';
import { helper } from '@ember/component/helper';

interface EuiDatePopoverContentArgs {
  value: string;
  onChange(date: string | null, event?: React.SyntheticEvent<any>): void;
  roundUp?: boolean;
  dateFormat: string;
  timeFormat: string;
  // locale?: LocaleSpecifier;
  position: 'start' | 'end';
  utcOffset?: number;
  // timeOptions: TimeOptions;
}

const toAbsoluteStringHelper = helper(function ([value, roundUp]: [
  string,
  boolean
]) {
  return toAbsoluteString(value, roundUp);
});

export default class EuiDatePopoverContent extends Component<EuiDatePopoverContentArgs> {
  @tracked selectedTab = 0;

  toAbsoluteStringHelper = toAbsoluteStringHelper;

  // get value() {
  //   console.log(
  //     this.args.value,
  //     toAbsoluteString(this.args.value, this.roundUp)
  //   );

  //   return toAbsoluteString(this.args.value, this.roundUp);
  // }

  get labelPrefix() {
    return this.args.position === 'start' ? 'startDateLabel' : 'endDateLabel';
  }

  get tabs() {
    return [
      {
        id: 'relative',
        name: 'Relative',
        content: 'Test'
      },
      {
        id: 'now',
        name: 'Now',
        content: 'Test'
      }
    ];
  }

  get initialSelectedTab() {
    return this.tabs.find((tab) => tab.id === getDateMode(this.args.value));
  }
}
