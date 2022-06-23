import { action } from '@ember/object';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { getOwner } from '@ember/application';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';
import { LocaleSpecifier } from 'moment';
import {
  ApplyRefreshInterval,
  DurationRange,
  Milliseconds,
  ShortDate
} from './types/global';
import { isRangeInvalid } from './utils';
import { useI18nTimeOptions } from './utils/time-options';
import { OnRefreshProps, OnTimeChangeProps } from '@elastic/eui';

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
  onRefresh?: (props: OnRefreshProps) => void;
  /**
   * Callback for when the refresh interval changes.
   * Supply onRefreshChange to show refresh interval inputs in quick select popover
   */
  onRefreshChange?: ApplyRefreshInterval;
  /**
   * Callback for when the time changes.
   */
  onTimeChange: (props: OnTimeChangeProps) => void;
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
  @argOrDefault('MMM D, YYYY @ HH:mm:ss.SSS') dateFormat!: string;
  @argOrDefault('HH:mm') timeFormat!: string;
  // @argOrDefault('now-15m') start!: ShortDate;
  // @argOrDefault('now') end!: ShortDate;
  @argOrDefault(false) isAutoRefreshOnly!: boolean;
  @argOrDefault(false) isDisabled!: boolean;
  @argOrDefault(true) isPaused!: boolean;
  @argOrDefault(true) showUpdateButton!: boolean;
  @argOrDefault('restricted') width!: string;
  // recentlyUsedRanges: [],
  @argOrDefault(1000) refreshInterval!: Milliseconds;

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
    return useI18nTimeOptions(getOwner(this));
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
      } as OnTimeChangeProps);
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
}
