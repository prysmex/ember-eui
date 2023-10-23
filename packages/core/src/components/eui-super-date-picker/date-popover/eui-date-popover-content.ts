import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { toAbsoluteString, getDateMode } from '../utils';
import { helper } from '@ember/component/helper';
import { inject as service } from '@ember/service';
import type EuiI18n from '../../../services/eui-i18n';

interface EuiDatePopoverContentArgs {
  value: string;
  onChange(date: string | null, event?: any): void;
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
  @service declare euiI18n: EuiI18n;
  @tracked selectedTab = 0;
  toAbsoluteStringHelper = toAbsoluteStringHelper;

  get labelPrefix() {
    return this.args.position === 'start'
      ? this.euiI18n.lookupToken(
          'euiDatePopoverContent.startDateLabel',
          'Start date'
        )
      : this.euiI18n.lookupToken(
          'euiDatePopoverContent.endDateLabel',
          'End date'
        );
  }

  get tabs() {
    return [
      {
        id: 'absolute',
        name: this.euiI18n.lookupToken(
          'euiDatePopoverContent.absoluteTabLabel',
          'Absolute'
        )
      },
      {
        id: 'relative',
        name: this.euiI18n.lookupToken(
          'euiDatePopoverContent.relativeTabLabel',
          'Relative'
        )
      },
      {
        id: 'now',
        name: this.euiI18n.lookupToken(
          'euiDatePopoverContent.nowTabLabel',
          'Now'
        )
      }
    ];
  }

  get initialSelectedTab() {
    return this.tabs.find((tab) => tab.id === getDateMode(this.args.value));
  }
}
