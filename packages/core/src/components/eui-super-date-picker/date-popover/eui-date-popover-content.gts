import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { helper } from '@ember/component/helper';
import { service } from '@ember/service';

import { eq } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../../../utils/emotion/consume.ts';
import { euiDatePopoverContentStyles } from '../../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../../utils/eui/styles.ts';
import EuiTabbedContent from '../../eui-tabbed-content.gts';
import { getDateMode, toAbsoluteString } from '../utils/index.ts';
import { useI18nTimeOptions } from '../utils/time-options.ts';
import AbsoluteTab from './absolute-tab.gts';
import NowTab from './now-tab.gts';
import RelativeTab from './relative-tab.gts';

import type EuiI18n from '../../../services/eui-i18n';
import type { EuiTabbedContentTab } from '../../eui-tabbed-content';
import type { TimeOptions } from '../utils/time-options.ts';
import type { AbsoluteTabSignature } from './absolute-tab';
import type { NowTabSignature } from './now-tab';
import type { RelativeTabSignature } from './relative-tab';
import type { EuiTimeZoneDisplayProps } from './eui-time-zone-display.gts';
import type { LocaleSpecifier, Moment } from 'moment';

interface EuiDatePopoverContentArgs {
  /** The date (date math or ISO date). */
  value: string;
  /** Called with the new value. */
  onChange:
    | RelativeTabSignature['Args']['onChange']
    | NowTabSignature['Args']['onChange']
    | AbsoluteTabSignature['Args']['onChange'];
  /** Rounds relative dates up (for the end of a range). */
  roundUp?: boolean;
  /** moment format of absolute dates. */
  dateFormat: string;
  /** moment format of times. */
  timeFormat?: string;
  /** moment locale. */
  locale?: LocaleSpecifier;
  /** `'start'` or `'end'` of the range. */
  position: 'start' | 'end';
  /** UTC offset in minutes. */
  utcOffset?: number;
  /** Time units and tenses for the quick select. */
  timeOptions: TimeOptions;
  /** Earliest selectable day of the absolute tab's calendar. */
  minDate?: Moment;
  /** Latest selectable day of the absolute tab's calendar. */
  maxDate?: Moment;
  /**
   * `false` keeps relative values as typed in the relative tab (upstream
   * rounds them through an absolute date). Defaults to `true`.
   */
  canRoundRelativeUnits?: boolean;
  /** Shows the time zone in the absolute and relative tabs. */
  timeZoneDisplayProps?: EuiTimeZoneDisplayProps;
}

const toAbsoluteStringHelper = helper(function ([
  value,
  roundUp,
  canRoundRelativeUnits = true
]: [string, boolean, boolean?]) {
  return canRoundRelativeUnits ? toAbsoluteString(value, roundUp) : value;
});

/** @private The tabs (absolute, relative, now) of the date popover. */
export interface EuiDatePopoverContentSignature {
  Element: HTMLDivElement;
  Args: EuiDatePopoverContentArgs;
  Blocks: {
    selectedTabContent: [
      {
        id: string;
        name: string;
      }
    ];
  };
}

export default class EuiDatePopoverContent extends Component<EuiDatePopoverContentSignature> {
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

  get tabs(): EuiTabbedContentTab[] {
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

  /** Upstream: the form width (400px), narrower below the `s` breakpoint. */
  @cached
  get className() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDatePopoverContentStyles);
    return `euiDatePopoverContent ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiDatePopoverContent
    )}`;
  }

  get roundUp() {
    return this.args.roundUp ?? false;
  }

  get canRoundRelativeUnits() {
    return this.args.canRoundRelativeUnits ?? true;
  }

  get timeOptions() {
    return this.args.timeOptions || useI18nTimeOptions(this.euiI18n);
  }

  <template>
    <EuiTabbedContent
      @className={{this.className}}
      @tabs={{this.tabs}}
      @initialSelectedTab={{this.initialSelectedTab}}
      @autoFocus="selected"
      @expand={{true}}
      @size="s"
    >
      <:selectedTabContent as |selected|>
        {{#if (eq selected.id "relative")}}
          <RelativeTab
            @value={{this.toAbsoluteStringHelper
              @value
              this.roundUp
              this.canRoundRelativeUnits
            }}
            @onChange={{@onChange}}
            @labelPrefix={{this.labelPrefix}}
            @roundUp={{this.roundUp}}
            @dateFormat={{@dateFormat}}
            @locale={{@locale}}
            @position={{@position}}
            @timeOptions={{this.timeOptions}}
            @timeZoneDisplayProps={{@timeZoneDisplayProps}}
          />
        {{else if (eq selected.id "now")}}
          <NowTab @position={{@position}} @onChange={{@onChange}} />
        {{else if (eq selected.id "absolute")}}
          <AbsoluteTab
            @value={{@value}}
            @roundUp={{this.roundUp}}
            @dateFormat={{@dateFormat}}
            @locale={{@locale}}
            @position={{@position}}
            @onChange={{@onChange}}
            @labelPrefix={{this.labelPrefix}}
            @minDate={{@minDate}}
            @maxDate={{@maxDate}}
            @timeZoneDisplayProps={{@timeZoneDisplayProps}}
          />
        {{/if}}
      </:selectedTabContent>
    </EuiTabbedContent>
  </template>
}
