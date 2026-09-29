import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';
import { eq, or } from 'ember-truth-helpers';

import argOrDefault, { argOrDefaultDecorator } from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiFormControlLayout from './eui-form-control-layout.gts';
import EuiDatePopoverButton from './eui-super-date-picker/date-popover/eui-date-popover-button.gts';
import EuiDatePickerRange from './eui-super-date-picker/eui-date-picker-range.gts';
import EuiQuickSelectPopover from './eui-super-date-picker/eui-quick-select-popover.gts';
import EuiSuperUpdateButton from './eui-super-date-picker/eui-super-update-button.gts';
import { isRangeInvalid } from './eui-super-date-picker/utils/index.ts';
import { useI18nTimeOptions } from './eui-super-date-picker/utils/time-options.ts';

import type EuiI18n from '../services/eui-i18n';
import type {
  ApplyRefreshInterval,
  DurationRange,
  Milliseconds,
  ShortDate
} from './eui-super-date-picker/types/global';
import type { LocaleSpecifier } from 'moment';

export type { ApplyRefreshInterval, DurationRange, Milliseconds, ShortDate };

/**
 * EuiSuperDatePicker picks a time range (absolute dates, relative like
 * "last 15 minutes", or "now") with a quick select popover and optional
 * auto refresh, as in Kibana. `@onTimeChange` receives date math strings.
 */
export interface EuiSuperDatePickerArgs {
  /**
   * Ranges listed as "Commonly used" in the quick select popover:
   * `[{ start: 'now/d', end: 'now/d', label: 'Today' }, …]`. Defaults to
   * EUI's list (Today, This week, Last 15 minutes, …).
   */
  commonlyUsedRanges?: DurationRange[];
  // customQuickSelectPanels?: QuickSelectPanel[];
  /**
   * moment format for absolute dates. Defaults to
   * `'MMM D, YYYY @ HH:mm:ss.SSS'`.
   */
  dateFormat?: string;
  /**
   * Set isAutoRefreshOnly to true to limit the component to only display
   * auto refresh content. Defaults to `false`.
   */
  isAutoRefreshOnly?: boolean;
  /** Disables the picker. Defaults to `false`. */
  isDisabled?: boolean;
  /** Shows the update button's loading state, e.g. while data refreshes. */
  isLoading?: boolean;
  /**
   * Whether auto refresh is paused (with `@onRefreshChange`).
   * Defaults to `true`.
   */
  isPaused?: boolean;
  /**
   * Sets the overall width by adding sensible min and max widths.
   * - `auto`: fits width to internal content / time string.
   * - `restricted`: static width that fits the longest possible time string.
   * - `full`: expands to 100% of the container.
   * Defaults to `'restricted'`.
   */
  width?: 'restricted' | 'full' | 'auto';
  /**
   * Reduces overall height to compressed form size
   */
  compressed?: boolean;
  /**
   * Used to localize e.g. month names, passed to `moment`
   */
  locale?: LocaleSpecifier;
  /**
   * Called every `@refreshInterval` ms while not `@isPaused` (and by the
   * update button when the range has not changed), with `{ start, end,
   * refreshInterval }`. If it returns a promise, the next call waits for
   * it; if the promise rejects, refreshing stops.
   */
  onRefresh?: (props: {
    start: string;
    end: string;
    refreshInterval: number;
  }) => void | Promise<unknown>;
  /**
   * Adds the "Refresh every" section to the quick select popover; called
   * with `{ refreshInterval, isPaused }` when the user changes them.
   */
  onRefreshChange?: ApplyRefreshInterval;
  /**
   * Callback for when the time changes.
   */
  onTimeChange: (props: {
    start: string;
    end: string;
    isQuickSelection: boolean;
    isInvalid: boolean;
  }) => void;
  // recentlyUsedRanges?: DurationRange[];
  /**
   * Refresh interval in milliseconds. Defaults to `1000`.
   */
  refreshInterval?: Milliseconds;
  /**
   * Start of the range, as date math (`'now-15m'`, `'now/d'`) or an ISO
   * date. Defaults to `'now-15m'`.
   */
  start?: ShortDate;
  /** End of the range, like `@start`. Defaults to `'now'`. */
  end?: ShortDate;
  /**
   * moment format for times in the date picker. Defaults to `'HH:mm'`.
   */
  timeFormat?: string;
  /** UTC offset in minutes for absolute dates, e.g. `-300`. */
  utcOffset?: number;
  /**
   * Set showUpdateButton to false to immediately invoke onTimeChange for
   * all start and end changes; `'iconOnly'` shows a compact button.
   * Defaults to `true`.
   */
  showUpdateButton?: boolean | 'iconOnly';
  /**
   * Hides the actual input reducing to just the quick select button.
   */
  isQuickSelectOnly?: boolean;
  /**
   * Props passed to the update button #EuiSuperUpdateButtonProps
   */
  // updateButtonProps?: EuiSuperUpdateButtonProps;
}

export default class EuiSuperDatePicker extends Component<EuiSuperDatePickerArgs> {
  @argOrDefaultDecorator('MMM D, YYYY @ HH:mm:ss.SSS') dateFormat!: string;
  @argOrDefaultDecorator('HH:mm') timeFormat!: string;
  // @argOrDefaultDecorator('now-15m') start!: ShortDate;
  // @argOrDefaultDecorator('now') end!: ShortDate;
  @argOrDefaultDecorator(false) isAutoRefreshOnly!: boolean;
  @argOrDefaultDecorator(false) isDisabled!: boolean;
  @argOrDefaultDecorator(true) isPaused!: boolean;
  @argOrDefaultDecorator(true) showUpdateButton!: boolean;
  @argOrDefaultDecorator('restricted') width!: string;
  // recentlyUsedRanges: [],
  @argOrDefaultDecorator(1000) refreshInterval!: Milliseconds;

  @service declare euiI18n: EuiI18n;

  /**
   * The range the user is editing, before it is applied with the update
   * button. It remembers the @start/@end it was based on: when the parent
   * passes a different range, the draft no longer applies and the picker
   * shows the new arguments (like EUI React's getDerivedStateFromProps).
   */
  @tracked private draft?: {
    start: ShortDate;
    end: ShortDate;
    hasChanged: boolean;
    forStart: ShortDate | undefined;
    forEnd: ShortDate | undefined;
  };

  private get currentDraft() {
    const { draft } = this;

    return draft &&
      draft.forStart === this.args.start &&
      draft.forEnd === this.args.end
      ? draft
      : undefined;
  }

  get start(): ShortDate {
    return this.currentDraft?.start ?? this.args.start ?? 'now-15m';
  }

  get end(): ShortDate {
    return this.currentDraft?.end ?? this.args.end ?? 'now';
  }

  get isInvalid(): boolean {
    return isRangeInvalid(this.start, this.end);
  }

  get hasChanged(): boolean {
    return this.currentDraft?.hasChanged ?? false;
  }

  private setDraft(start: ShortDate, end: ShortDate, hasChanged: boolean) {
    this.draft = {
      start,
      end,
      hasChanged,
      forStart: this.args.start,
      forEnd: this.args.end
    };
  }

  get timeOptions() {
    return useI18nTimeOptions(this.euiI18n);
  }

  setTime({ start, end }: DurationRange) {
    this.setDraft(start, end, !(this.start === start && this.end === end));

    if (!this.showUpdateButton) {
      this.args.onTimeChange({
        start,
        end,
        isQuickSelection: false,
        isInvalid: isRangeInvalid(start, end)
      });
    }
  }

  applyTime() {
    this.args.onTimeChange({
      start: this.start,
      end: this.end,
      isQuickSelection: false,
      isInvalid: false
    });
  }

  @action
  applyQuickTime({ start, end }: DurationRange) {
    this.setDraft(start, end, false);

    this.args.onTimeChange({
      start,
      end,
      isQuickSelection: true,
      isInvalid: false
    });
  }

  @action
  setStart(start: ShortDate) {
    this.setTime({ start, end: this.end });
  }

  @action
  setEnd(end: ShortDate) {
    this.setTime({ start: this.start, end });
  }

  @action
  handleClickUpdateButton() {
    if (!this.hasChanged && this.args.onRefresh) {
      void this.args.onRefresh({
        start: this.start,
        end: this.end,
        refreshInterval: this.refreshInterval
      });
    } else {
      this.applyTime();
    }

    if (this.currentDraft) {
      this.draft = { ...this.currentDraft, hasChanged: false };
    }
  }

  /**
   * Calls `@onRefresh` every `@refreshInterval` ms while not `@isPaused`.
   * A returned promise delays the next call until it settles; a rejected
   * one stops the refreshing.
   */
  autoRefresh = modifier(
    (
      _element: Element,
      [onRefresh, isPaused, refreshInterval]: [
        EuiSuperDatePickerArgs['onRefresh'],
        boolean,
        number
      ]
    ) => {
      if (!onRefresh || isPaused || !(refreshInterval > 0)) return;

      let stopped = false;
      let timer: ReturnType<typeof setTimeout>;

      const tick = async () => {
        try {
          await onRefresh({ start: this.start, end: this.end, refreshInterval });
        } catch {
          stopped = true;
        }

        if (!stopped) timer = setTimeout(() => void tick(), refreshInterval);
      };

      timer = setTimeout(() => void tick(), refreshInterval);

      return () => {
        stopped = true;
        clearTimeout(timer);
      };
    }
  );

  <template>
    <EuiFlexGroup
      {{this.autoRefresh @onRefresh this.isPaused this.refreshInterval}}
      @gutterSize="s"
      @responsive={{false}}
      class={{classNames
        "euiSuperDatePicker__flexWrapper"
        (unless
          this.showUpdateButton
          "euiSuperDatePicker__flexWrapper--noUpdateButton"
        )
        (if
          this.isAutoRefreshOnly
          "euiSuperDatePicker__flexWrapper--isAutoRefreshOnly"
        )
        (if
          @isQuickSelectOnly
          "euiSuperDatePicker__flexWrapper--isQuickSelectOnly"
        )
        (if (eq this.width "full") "euiSuperDatePicker__flexWrapper--fullWidth")
        (if (eq this.width "auto") "euiSuperDatePicker__flexWrapper--autoWidth")
      }}
    >
      <EuiFlexItem>
        <EuiFormControlLayout
          class="euiSuperDatePicker"
          @compressed={{@compressed}}
          @isDisabled={{@isDisabled}}
          @useGroup={{true}}
        >
          <:prepend>
            <EuiQuickSelectPopover
              @start={{this.start}}
              @end={{this.end}}
              @applyTime={{this.applyQuickTime}}
              @timeOptions={{this.timeOptions}}
              @isDisabled={{@isDisabled}}
              @commonlyUsedRanges={{argOrDefault
                @commonlyUsedRanges
                this.timeOptions.commonDurationRanges
              }}
              @applyRefreshInterval={{@onRefreshChange}}
              @isPaused={{this.isPaused}}
              @refreshInterval={{this.refreshInterval}}
            />
          </:prepend>

          <:field>
            <EuiDatePickerRange
              @className="euiDatePickerRange--inGroup"
              @isInvalid={{this.isInvalid}}
              @disabled={{@isDisabled}}
            >
              <:startDateControl>
                <EuiDatePopoverButton
                  @className="euiSuperDatePicker__startPopoverButton"
                  @value={{this.start}}
                  @compressed={{@compressed}}
                  @position="start"
                  @isDisabled={{@isDisabled}}
                  @dateFormat={{this.dateFormat}}
                  @onChange={{this.setStart}}
                  @isInvalid={{this.isInvalid}}
                  @timeOptions={{this.timeOptions}}
                  @needsUpdating={{this.hasChanged}}
                  @locale={{@locale}}
                />
              </:startDateControl>

              <:endDateControl>
                <EuiDatePopoverButton
                  @className="euiSuperDatePicker__startPopoverButton"
                  @value={{this.end}}
                  @compressed={{@compressed}}
                  @position="end"
                  @isDisabled={{@isDisabled}}
                  @dateFormat={{this.dateFormat}}
                  @onChange={{this.setEnd}}
                  @isInvalid={{this.isInvalid}}
                  @timeOptions={{this.timeOptions}}
                  @roundUp={{true}}
                  @needsUpdating={{this.hasChanged}}
                  @locale={{@locale}}
                />
              </:endDateControl>
            </EuiDatePickerRange>
          </:field>
        </EuiFormControlLayout>
      </EuiFlexItem>

      {{#if this.showUpdateButton}}
        <EuiFlexItem @grow={{false}}>
          <EuiSuperUpdateButton
            @size={{if @compressed "s" "m"}}
            @onClick={{this.handleClickUpdateButton}}
            @isLoading={{@isLoading}}
            @isDisabled={{or @isDisabled this.isInvalid}}
            @needsUpdate={{this.hasChanged}}
            @fill={{true}}
            @iconOnly={{eq this.showUpdateButton "iconOnly"}}
          />
        </EuiFlexItem>
      {{/if}}
    </EuiFlexGroup>
  </template>
}
