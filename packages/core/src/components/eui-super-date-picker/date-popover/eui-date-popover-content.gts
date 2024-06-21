import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { helper } from '@ember/component/helper';
import { inject as service } from '@ember/service';

import { eq } from 'ember-truth-helpers';

import EuiTabbedContent from '../../eui-tabbed-content.gts';
import { getDateMode,toAbsoluteString } from '../utils/index.ts';
import AbsoluteTab from './absolute-tab.gts';
import NowTab from './now-tab.gts';
import RelativeTab from './relative-tab.gts';

import type EuiI18n from '../../../services/eui-i18n';
import type { EuiTabbedContentTab } from '../../eui-tabbed-content';
import type { TimeOptions } from '../utils/time-options.ts';
import type { AbsoluteTabSignature } from './absolute-tab';
import type { NowTabSignature } from './now-tab';
import type { RelativeTabSignature } from './relative-tab';
import type { LocaleSpecifier } from 'moment';

interface EuiDatePopoverContentArgs {
  value: string;
  onChange:
    | RelativeTabSignature['Args']['onChange']
    | NowTabSignature['Args']['onChange']
    | AbsoluteTabSignature['Args']['onChange'];
  roundUp?: boolean;
  dateFormat: string;
  timeFormat?: string;
  locale?: LocaleSpecifier;
  position: 'start' | 'end';
  utcOffset?: number;
  timeOptions: TimeOptions;
}

const toAbsoluteStringHelper = helper(function ([value, roundUp]: [
  string,
  boolean
]) {
  return toAbsoluteString(value, roundUp);
});

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

  get roundUp() {
    return this.args.roundUp ?? false;
  }

  <template>
    <EuiTabbedContent
      @className="euiDatePopoverContent"
      @tabs={{this.tabs}}
      @initialSelectedTab={{this.initialSelectedTab}}
      @autoFocus="selected"
      @expand={{true}}
      @size="s"
    >
      <:selectedTabContent as |selected|>
        {{#if (eq selected.id "relative")}}
          <RelativeTab
            @value={{this.toAbsoluteStringHelper @value this.roundUp}}
            @onChange={{@onChange}}
            @labelPrefix={{this.labelPrefix}}
            @roundUp={{this.roundUp}}
            @dateFormat={{@dateFormat}}
            @locale={{@locale}}
            @position={{@position}}
            @timeOptions={{@timeOptions}}
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
          />
        {{/if}}
      </:selectedTabContent>
    </EuiTabbedContent>
  </template>
}
