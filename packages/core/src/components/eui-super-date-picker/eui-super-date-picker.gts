import { action } from '@ember/object';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import argOrDefault, {
  argOrDefaultDecorator
} from '../../helpers/arg-or-default';
import type { LocaleSpecifier } from 'moment';
import type {
  ApplyRefreshInterval,
  DurationRange,
  Milliseconds,
  ShortDate
} from './types/global';
import { isRangeInvalid } from './utils';
import { useI18nTimeOptions } from './utils/time-options';
import type EuiI18n from '../../services/eui-i18n';
import { inject as service } from '@ember/service';
import { or, eq } from 'ember-truth-helpers';

interface EuiSuperDatePickerArgs {
  commonlyUsedRanges?: DurationRange[];
  // customQuickSelectPanels?: QuickSelectPanel[];
  /**
   * Specifies the formatted used when displaying dates and/or datetimes
   */
  dateFormat?: string;
  /**
   * Set isAutoRefreshOnly to true to limit the component to only display auto refresh content.
   */
  isAutoRefreshOnly?: boolean;
  isDisabled?: boolean;
  isLoading?: boolean;
  isPaused?: boolean;
  /**
   * Sets the overall width by adding sensible min and max widths.
   * - `auto`: fits width to internal content / time string.
   * - `restricted`: static width that fits the longest possible time string.
   * - `full`: expands to 100% of the container.
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
   * Callback for when the refresh interval is fired.
   * EuiSuperDatePicker will only manage a refresh interval timer when onRefresh callback is supplied
   * If a promise is returned, the next refresh interval will not start until the promise has resolved.
   * If the promise rejects the refresh interval will stop and the error thrown
   */
  onRefresh?: (props: any) => void;
  /**
   * Callback for when the refresh interval changes.
   * Supply onRefreshChange to show refresh interval inputs in quick select popover
   */
  onRefreshChange?: ApplyRefreshInterval;
  /**
   * Callback for when the time changes.
   */
  onTimeChange: (props: any) => void;
  // recentlyUsedRanges?: DurationRange[];
  /**
   * Refresh interval in milliseconds
   */
  refreshInterval?: Milliseconds;
  start?: ShortDate;
  end?: ShortDate;
  /**
   * Specifies the formatted used when displaying times
   */
  timeFormat?: string;
  utcOffset?: number;
  /**
   * Set showUpdateButton to false to immediately invoke onTimeChange for all start and end changes.
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

  @tracked start: ShortDate;
  @tracked end: ShortDate;
  @tracked isInvalid = false;
  @tracked hasChanged = false;

  constructor(owner: any, args: EuiSuperDatePickerArgs) {
    super(owner, args);

    this.start = this.args.start ?? 'now-15m';
    this.end = this.args.end ?? 'now';

    // if (this.args.start === undefined || this.args.end === undefined) {
    //   this.setTime({
    //     start: this.args.start ?? 'now-15m',
    //     end: this.args.end ?? 'now'
    //   });
    // }
  }

  get timeOptions() {
    return useI18nTimeOptions(this.euiI18n);
  }

  setTime({ start, end }: DurationRange) {
    this.hasChanged = !(this.start === start && this.end === end);
    this.start = start;
    this.end = end;
    this.isInvalid = isRangeInvalid(start, end);

    if (!this.showUpdateButton) {
      this.args.onTimeChange({
        start,
        end,
        isQuickSelection: false,
        isInvalid: this.isInvalid
      } as any);
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

  // stopInterval() {
  //   if (this.asyncInterval) {
  //     this.asyncInterval.stop();
  //   }
  // }

  // startInterval(refreshInterval: number) {
  //   if (this.args.onRefresh) {
  //     const handler = () => {
  //       const { start, end } = this.props;
  //       this.args.onRefresh({ start, end, refreshInterval });
  //     };
  //     this.asyncInterval = new AsyncInterval(handler, refreshInterval);
  //   }
  // }

  @action applyQuickTime({ start, end }: DurationRange) {
    // this.setState({
    //   showPrettyDuration: showPrettyDuration(
    //     start,
    //     end,
    //     this.props.commonlyUsedRanges
    //   )
    // });

    // Update the internal state
    this.start = start;
    this.end = end;

    this.args.onTimeChange({
      start,
      end,
      isQuickSelection: true,
      isInvalid: false
    });
  }

  @action setStart(start: ShortDate) {
    this.setTime({ start, end: this.end });
  }

  @action setEnd(end: ShortDate) {
    this.setTime({ start: this.start, end });
  }

  @action handleClickUpdateButton() {
    if (!this.hasChanged && this.args.onRefresh) {
      // const { start, end, refreshInterval } = this.args;
      this.args.onRefresh({
        start: this.start,
        end: this.end,
        refreshInterval: this.refreshInterval
      });
    } else {
      this.applyTime();
    }
    this.hasChanged = false;
  }

  // @action onRefreshChange({ refreshInterval, isPaused }) {
  //   this.stopInterval();
  //   if (!isPaused) {
  //     this.startInterval(refreshInterval);
  //   }
  //   if (this.props.onRefreshChange) {
  //     this.props.onRefreshChange({ refreshInterval, isPaused });
  //   }
  // }

  <template>
    {{! @glint-nocheck: not typesafe yet }}
    <EuiFlexGroup
      @gutterSize="s"
      @responsive={{false}}
      class={{class-names
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
          {{!-- @fullWidth={{this.fullWidth}} --}}
          {{!-- @readOnly={{@readOnly}} --}}
        >
          <:prepend>
            <EuiSuperDatePicker::EuiQuickSelectPopover
              @start={{this.start}}
              @end={{this.end}}
              @applyTime={{this.applyQuickTime}}
              @timeOptions={{this.timeOptions}}
              @isDisabled={{@isDisabled}}
              @dateFormat={{this.dateFormat}}
              @commonlyUsedRanges={{argOrDefault
                @commonlyUsedRanges
                this.timeOptions.commonDurationRanges
              }}
              {{!-- @applyRefreshInterval={{if @onRefreshChange this.onRefreshChange}} --}}
              {{! commonlyUsedRanges={commonlyUsedRanges}
          customQuickSelectPanels={customQuickSelectPanels}
          isPaused={isPaused}
          recentlyUsedRanges={recentlyUsedRanges}
          refreshInterval={refreshInterval} }}
            />
          </:prepend>

          <:field>
            <EuiSuperDatePicker::EuiDatePickerRange
              @className="euiDatePickerRange--inGroup"
              @iconType={{false}}
              @isInvalid={{this.isInvalid}}
              @disabled={{@isDisabled}}
              @isCustom={{true}}
            >
              <:startDateControl>
                <EuiSuperDatePicker::DatePopover::EuiDatePopoverButton
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
                  {{!
              isInvalid={isInvalid}
              utcOffset={utcOffset}
              timeFormat={timeFormat}
              isOpen={this.state.isStartDatePopoverOpen}
              onPopoverToggle={this.onStartDatePopoverToggle}
              onPopoverClose={this.onStartDatePopoverClose}
              }}
                />
              </:startDateControl>

              <:endDateControl>
                <EuiSuperDatePicker::DatePopover::EuiDatePopoverButton
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
                  {{!
              utcOffset={utcOffset}
              timeFormat={timeFormat}
              isOpen={this.state.isStartDatePopoverOpen}
              onPopoverToggle={this.onStartDatePopoverToggle}
              onPopoverClose={this.onStartDatePopoverClose}
              }}
                />
              </:endDateControl>
            </EuiSuperDatePicker::EuiDatePickerRange>
          </:field>
        </EuiFormControlLayout>
      </EuiFlexItem>

      {{#if this.showUpdateButton}}
        <EuiFlexItem @grow={{false}}>
          <EuiSuperDatePicker::EuiSuperUpdateButton
            @size={{if @compressed "s" "m"}}
            @onClick={{this.handleClickUpdateButton}}
            @isLoading={{@isLoading}}
            @isDisabled={{or @isDisabled this.isInvalid}}
            @needsUpdate={{this.hasChanged}}
            @fill={{true}}
            @iconOnly={{eq this.showUpdateButton "iconOnly"}}
            {{!
        showTooltip={
          !this.state.isStartDatePopoverOpen &&
          !this.state.isEndDatePopoverOpen
        }
        responsive
        }}
          />
        </EuiFlexItem>
      {{/if}}
    </EuiFlexGroup>
  </template>
}
