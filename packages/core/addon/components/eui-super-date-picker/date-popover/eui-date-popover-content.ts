import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { toAbsoluteString, getDateMode } from '../utils';
import { helper } from '@ember/component/helper';
import { useEuiI18n as _useEuiI18n } from '@ember-eui/core/i18n';
import { inject as service } from '@ember/service';

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
  @service euiI18n;
  @tracked selectedTab = 0;
  useEuiI18n;
  toAbsoluteStringHelper = toAbsoluteStringHelper;

  constructor(owner: unknown, args: EuiDatePopoverContentArgs) {
    super(owner, args);

    // bind the function
    this.useEuiI18n = _useEuiI18n.bind(this.euiI18n);
  }

  get labelPrefix() {
    return this.args.position === 'start'
      ? this.useEuiI18n('euiDatePopoverContent.startDateLabel', 'Start date')
      : this.useEuiI18n('euiDatePopoverContent.endDateLabel', 'End date');
  }

  get tabs() {
    return [
      {
        id: 'absolute',
        name: this.useEuiI18n(
          'euiDatePopoverContent.absoluteTabLabel',
          'Absolute'
        )
      },
      {
        id: 'relative',
        name: this.useEuiI18n(
          'euiDatePopoverContent.relativeTabLabel',
          'Relative'
        )
      },
      {
        id: 'now',
        name: this.useEuiI18n('euiDatePopoverContent.nowTabLabel', 'Now')
      }
    ];
  }

  get initialSelectedTab() {
    return this.tabs.find((tab) => tab.id === getDateMode(this.args.value));
  }
}
