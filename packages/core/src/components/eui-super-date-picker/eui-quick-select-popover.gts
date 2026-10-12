import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiQuickSelectPopoverStyles } from '../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiFormPrepend from '../eui-form-prepend.gts';
import EuiPopover from '../eui-popover.gts';
import EuiRefreshInterval from '../eui-refresh-interval.gts';
import EuiToolTip from '../eui-tool-tip.gts';
import EuiCommonlyUsedTimeRanges from './eui-quick-select-popover/eui-commonly-used-time-ranges.gts';
import EuiQuickSelect from './eui-quick-select-popover/eui-quick-select.gts';
import EuiRecentlyUsed from './eui-quick-select-popover/eui-recently-used.gts';
import { useI18nTimeOptions } from './utils/time-options.ts';

import type EuiI18n from '../../services/eui-i18n';
import type { EuiCommonlyUsedTimeRangesSignature } from './eui-quick-select-popover/eui-commonly-used-time-ranges';
import type { EuiQuickSelectSignature } from './eui-quick-select-popover/eui-quick-select';
import type { EuiRecentlyUsedSignature } from './eui-quick-select-popover/eui-recently-used';
import type { ApplyRefreshInterval, ApplyTime } from './types/global';

/** @private EuiSuperDatePicker's quick select popover. */
export interface EuiQuickSelectPopoverSignature {
  Args: {
    /** Applies a new `{ start, end }` range. */
    applyTime: ApplyTime;
    /** Disables it. */
    isDisabled?: boolean;
    /** Compressed prepend button (follows the picker's `@compressed`). */
    compressed?: boolean;
    /** Ranges listed as "Commonly used". */
    commonlyUsedRanges: EuiCommonlyUsedTimeRangesSignature['Args']['commonlyUsedRanges'];
    /** Ranges listed as "Recently used". */
    recentlyUsedRanges?: EuiRecentlyUsedSignature['Args']['recentlyUsedRanges'];
    /** Start of the range (date math or ISO date). */
    start: string;
    /** End of the range. */
    end: string;
    /** Time units and tenses for the quick select. */
    timeOptions: EuiQuickSelectSignature['Args']['timeOptions'];
    /** Shows the refresh interval section, calling this on change. */
    applyRefreshInterval?: ApplyRefreshInterval;
    /** Whether auto refresh is paused. */
    isPaused?: boolean;
    /** The refresh interval in milliseconds. */
    refreshInterval?: number;
  };
}

export default class EuiQuickSelectPopover extends Component<EuiQuickSelectPopoverSignature> {
  @service declare euiI18n: EuiI18n;
  @tracked isOpen = false;

  get context() {
    return getEuiThemeContext(this);
  }

  @action
  applyTime({
    start,
    end,
    keepPopoverOpen = false
  }: {
    start: string;
    end: string;
    quickSelect?: { timeTense: string; timeValue: number; timeUnits: string };
    keepPopoverOpen?: boolean;
  }) {
    this.args.applyTime({
      start,
      end
    });

    if (!keepPopoverOpen) {
      this.isOpen = false;
    }
  }

  @action
  toggle() {
    this.isOpen = !this.isOpen;
  }

  @action
  close() {
    this.isOpen = false;
  }

  get timeOptions() {
    return this.args.timeOptions || useI18nTimeOptions(this.euiI18n);
  }

  get buttonLabel() {
    return this.euiI18n.lookupToken(
      'euiQuickSelectPopover.buttonLabel',
      'Date quick select'
    );
  }

  @cached
  get contentClass() {
    const styles = useEuiBorealisStyles(
      this.context,
      euiQuickSelectPopoverStyles
    );
    return `euiQuickSelectPopover ${euiClass(
      this.context,
      { boxSizing: 'border-box' },
      styles.euiQuickSelectPopover
    )}`;
  }

  <template>
    <EuiPopover
      @isOpen={{this.isOpen}}
      @closePopover={{this.close}}
      @anchorPosition="downLeft"
      @anchorClassName="euiQuickSelectPopover__anchor"
    >
      <:button>
        <EuiToolTip
          @content={{this.buttonLabel}}
          @disableScreenReaderOutput={{true}}
        >
          <EuiFormPrepend
            @element="button"
            @compressed={{@compressed}}
            @isDisabled={{@isDisabled}}
            @iconLeft="calendar"
            @iconRight="chevronSingleDown"
            @onClick={{this.toggle}}
            class="euiQuickSelectPopover__button"
            aria-label={{this.buttonLabel}}
            data-test-subj="superDatePickerToggleQuickMenuButton"
          />
        </EuiToolTip>
      </:button>

      <:content>
        <div
          class={{this.contentClass}}
          data-test-subj="superDatePickerQuickMenu"
        >
          <EuiQuickSelect
            @applyTime={{this.applyTime}}
            @start={{@start}}
            @end={{@end}}
            @timeOptions={{this.timeOptions}}
          />

          {{#if @commonlyUsedRanges.length}}
            <EuiCommonlyUsedTimeRanges
              @applyTime={{this.applyTime}}
              @commonlyUsedRanges={{@commonlyUsedRanges}}
            />
          {{/if}}

          <EuiRecentlyUsed
            @applyTime={{this.applyTime}}
            @recentlyUsedRanges={{@recentlyUsedRanges}}
          />

          {{#if @applyRefreshInterval}}
            <EuiRefreshInterval
              @applyRefreshInterval={{@applyRefreshInterval}}
              @isPaused={{@isPaused}}
              @refreshInterval={{@refreshInterval}}
            />
          {{/if}}
        </div>
      </:content>
    </EuiPopover>
  </template>
}
