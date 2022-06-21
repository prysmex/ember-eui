import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { toAbsoluteString, getDateMode } from '../utils';
import { helper } from '@ember/component/helper';
import { useEuiI18n } from '@ember-eui/core/i18n';

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

  get labelPrefix() {
    return this.args.position === 'start'
      ? useEuiI18n('euiDatePopoverContent.startDateLabel', 'Start date')
      : useEuiI18n('euiDatePopoverContent.endDateLabel', 'End date');
  }

  get tabs() {
    return [
      {
        id: 'absolute',
        name: useEuiI18n('euiDatePopoverContent.absoluteTabLabel', 'Absolute')
      },
      {
        id: 'relative',
        name: useEuiI18n('euiDatePopoverContent.relativeTabLabel', 'Relative')
      },
      {
        id: 'now',
        name: useEuiI18n('euiDatePopoverContent.nowTabLabel', 'Now')
      }
    ];
  }

  get initialSelectedTab() {
    return this.tabs.find((tab) => tab.id === getDateMode(this.args.value));
  }
}
