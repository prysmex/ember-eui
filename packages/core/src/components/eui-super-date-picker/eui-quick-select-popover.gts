import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { buttonReset } from '../../utils/eui/form-controls.ts';
import {
  euiFormAppendPrependStyles,
  euiQuickSelectPopoverStyles
} from '../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiIcon from '../eui-icon.gts';
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

  /** Upstream `EuiFormPrepend` wrapper (focus ring around the button). */
  @cached
  get wrapperClass() {
    const styles = useEuiBorealisStyles(
      this.context,
      euiFormAppendPrependStyles
    );
    return euiClass(this.context, { boxSizing: 'border-box' }, styles.wrapper);
  }

  /** Upstream `EuiFormPrepend element="button"`. */
  @cached
  get buttonClass() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiFormAppendPrependStyles);
    const isDisabled = Boolean(this.args.isDisabled);
    return `euiFormPrepend euiQuickSelectPopover__button ${euiClass(
      context,
      buttonReset,
      { fontFamily: context.upstream.euiTheme.font.family },
      styles.side,
      this.args.compressed ? styles.compressed : styles.uncompressed,
      !isDisabled && styles.isInteractive,
      isDisabled && styles.disabled
    )}`;
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
          <div class={{this.wrapperClass}}>
            <button
              type="button"
              class={{this.buttonClass}}
              aria-label={{this.buttonLabel}}
              data-test-subj="superDatePickerToggleQuickMenuButton"
              disabled={{@isDisabled}}
              {{on "click" this.toggle}}
            >
              <EuiIcon @type="calendar" />
              <EuiIcon @type="arrowDown" />
            </button>
          </div>
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
