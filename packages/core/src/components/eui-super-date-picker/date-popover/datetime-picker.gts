import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { helper } from '@ember/component/helper';
import { concat, fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import type Owner from '@ember/owner';

import pick from '@nullvoxpopuli/ember-composable-helpers/helpers/pick';
import { and, eq, not } from 'ember-truth-helpers';
import moment from 'moment';

import { getEuiThemeContext } from '../../../utils/emotion/consume.ts';
import { euiReactDatePickerStyles } from '../../../utils/eui/date-pickers.ts';
import { euiDatePickerStyles } from '../../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../../utils/eui/styles.ts';
import EuiButtonIcon from '../../eui-button-icon.gts';
import EuiFormControlLayout from '../../eui-form-control-layout.gts';
import EuiSelect from '../../eui-select.gts';
import { isOutOfBounds } from '../utils/date-utils.ts';

const isSameDayHelper = helper(function ([year, month, day, selectedDate]: [
  number,
  number,
  number,
  moment.Moment | undefined
]) {
  if (!selectedDate) {
    return false;
  }

  return (
    selectedDate.year() === year &&
    selectedDate.month() === month &&
    selectedDate.date() === day
  );
});

interface DatetimePickerArgs {
  /** The selected date. */
  selected?: moment.Moment | null;
  /** Called with the new value. */
  onChange: (value: string | Date | moment.Moment, e: Event) => void;
  /** @deprecated Has no effect: the month buttons are `EuiButtonIcon`s. */
  iconClasses?: string;
  /** moment format of absolute dates. */
  dateFormat?: string;
  /** Days before this one are disabled (react-datepicker `minDate`). */
  minDate?: moment.Moment;
  /** Days after this one are disabled (react-datepicker `maxDate`). */
  maxDate?: moment.Moment;
}

interface Day {
  day: number;
  month?: number;
  year?: number;
  isOutside?: boolean;
}

/** @private The calendar and time list of the "Absolute" tab. */
interface DatetimePickerSignature {
  Args: DatetimePickerArgs;
}

export default class DatetimePicker extends Component<DatetimePickerSignature> {
  @tracked month: number = 0;
  @tracked year: number = 0;
  @tracked monthMoment: moment.Moment;
  // Used to style the days outside of the current month
  @tracked offset: number = 0;
  @tracked selectedDate?: moment.Moment;
  @tracked selectedTime?: string;
  @tracked today: moment.Moment;

  momentConfig: {
    year: number;
    month: number;
    day: number;
    hour: number;
    minute: number;
    second: number;
    millisecond: number;
  };

  constructor(owner: Owner, args: DatetimePickerArgs) {
    super(owner, args);

    if (this.args.selected) {
      this.monthMoment = this.args.selected;
      this.selectedDate = this.args.selected;
    } else {
      this.monthMoment = moment([this.year, this.month]);
    }

    this.momentConfig = {
      year: this.monthMoment.year(),
      month: this.monthMoment.month(),
      day: this.monthMoment.date(),
      hour: this.monthMoment.hour(),
      minute: this.monthMoment.minute(),
      second: 0,
      millisecond: 0
    };

    this.month = this.momentConfig.month;
    this.year = this.momentConfig.year;

    const hour = this.momentConfig.hour;
    const minute = this.momentConfig.minute;
    const hourStr = hour < 10 ? `0${hour}` : hour;
    const minuteStr = minute < 10 ? `0${minute}` : minute;

    this.selectedTime = `${hourStr}:${minuteStr}`;

    this.offset = this.monthMoment.clone().startOf('month').day();

    this.today = moment();
  }

  get context() {
    return getEuiThemeContext(this);
  }

  /**
   * Upstream `EuiDatePicker inline shadow={false}`: a block wrapper whose
   * form control layout loses its frame and stacks the calendar.
   */
  @cached
  get rootClass() {
    const styles = useEuiBorealisStyles(this.context, euiDatePickerStyles);
    return euiClass(
      this.context,
      { boxSizing: 'border-box' },
      styles.euiDatePicker,
      styles.inline.inline,
      styles.inline.noShadow
    );
  }

  /** Upstream's react-datepicker styles, applied to the same markup. */
  @cached
  get calendarClass() {
    const styles = useEuiBorealisStyles(
      this.context,
      euiReactDatePickerStyles
    );
    return euiClass(
      this.context,
      // React's global reset: no list markers/spacing, border-box
      {
        boxSizing: 'border-box',
        '& :where(*, *::before, *::after)': { boxSizing: 'border-box' },
        '& :where(ul)': { margin: 0, padding: 0, listStyle: 'none' }
      },
      styles.euiReactDatePicker
    );
  }

  get monthNames() {
    return moment.months().map((month, i) => {
      return {
        text: month,
        value: i
      };
    });
  }

  get years() {
    return Array.from(Array(15).keys()).map((_, i) => {
      // Create a list of years +/- 7 from the current year
      const year = this.year - 7 + i;

      return {
        text: year,
        value: year
      };
    });
  }

  get times() {
    const timesArray = [];

    // Create entries every 30 minutes
    for (let i = 0; i < 24; i++) {
      const hour = i < 10 ? `0${i}` : i;

      timesArray.push(`${hour}:00`, `${hour}:30`);
    }

    return timesArray;
  }

  get days() {
    // Used for showing days outside of the current month
    // const prevMonth = moment([this.year, this.month - 1]);
    const prevMonth = this.monthMoment.clone().subtract(1, 'month');
    const nextMonth = this.monthMoment.clone().add(1, 'month');
    const offset = this.offset;
    const daysInMonth = this.monthMoment.daysInMonth();
    const daysInPrevMonth = prevMonth.daysInMonth();

    const daysArray = [];

    for (let i = 0; i < daysInMonth; i++) {
      daysArray[i] = {
        day: i + 1
      };
    }

    // Fill the previous and next month days
    for (let i = 0, d = daysInPrevMonth; i < offset; i++, d--) {
      daysArray.unshift({
        day: d,
        month: prevMonth.month(),
        year: prevMonth.year(),
        isOutside: true
      });
    }

    // All months fit within 6 weeks (42 days)
    for (let d = 1, i = daysInMonth + offset; i < 42; d++, i++) {
      daysArray.push({
        day: d,
        month: nextMonth.month(),
        year: nextMonth.year(),
        isOutside: true
      });
    }

    // All months fit within 6 weeks (42 days)
    // but depending on the starting day, one week may not be needed
    const daysMatrix = [];
    const weeks = daysInMonth + offset > 35 ? 6 : 5;

    for (let i = 0; i < weeks; i++) {
      daysMatrix[i] = daysArray.slice(i * 7, i * 7 + 7);
    }

    return daysMatrix;
  }

  updateDate() {
    this.year = this.monthMoment.year();
    this.month = this.monthMoment.month();
    this.offset = this.monthMoment.clone().startOf('month').day();
  }

  @action
  selectTime(time: string, e: Event) {
    this.selectedTime = time;

    const [hour, minute] = time.split(':');

    this.momentConfig.hour = parseInt(hour!);
    this.momentConfig.minute = parseInt(minute!);
    this.momentConfig.second = 0;
    this.momentConfig.millisecond = 0;
    this.selectedDate = moment(this.momentConfig);
    this.args.onChange(this.selectedDate, e);
  }

  /** react-datepicker disables the days outside `minDate`..`maxDate`. */
  isDayDisabled = (day: Day): boolean => {
    const { minDate, maxDate } = this.args;
    if (!minDate && !maxDate) return false;
    const date = moment([
      day.year ?? this.year,
      day.month ?? this.month,
      day.day
    ]);
    return Boolean(isOutOfBounds(date, { minDate, maxDate }));
  };

  @action
  selectDate(day: Day, e: Event) {
    if (this.isDayDisabled(day)) return;

    // Only outside days will have year/month
    this.momentConfig.year = day.year || this.year;
    this.momentConfig.month = day.month || this.month;
    this.momentConfig.day = day.day;
    this.selectedDate = moment(this.momentConfig);
    this.args.onChange(this.selectedDate, e);

    // Update the state to show the selected month properly
    if (day.isOutside && day.month && day.year) {
      this.monthMoment.month(day.month);
      this.monthMoment.year(day.year);
      this.updateDate();
    }
  }

  @action
  setYear(year: string) {
    this.year = parseInt(year);
  }

  @action
  setMonth(month: string) {
    this.monthMoment.month(parseInt(month));
    this.updateDate();
  }

  @action
  increaseMonth() {
    this.monthMoment.add(1, 'month');
    this.updateDate();
  }

  @action
  decreaseMonth() {
    this.monthMoment.subtract(1, 'month');
    this.updateDate();
  }

  <template>
    <div class="euiDatePicker {{this.rootClass}}">
      <EuiFormControlLayout>
        <div class="react-datepicker {{this.calendarClass}}">
          <EuiButtonIcon
            class="react-datepicker__navigation react-datepicker__navigation--previous"
            aria-label="Previous month"
            @iconType="sortLeft"
            @size="s"
            @color="text"
            {{on "click" this.decreaseMonth}}
          />
          <EuiButtonIcon
            class="react-datepicker__navigation react-datepicker__navigation--next"
            aria-label="Next month"
            @iconType="sortRight"
            @size="s"
            @color="text"
            {{on "click" this.increaseMonth}}
          />
          <div class="react-datepicker__month-container">
            <div class="react-datepicker__header">
              <div
                class="react-datepicker__header__dropdown react-datepicker__header__dropdown--scroll"
              >
                <div
                  class="react-datepicker__month-dropdown-container react-datepicker__month-dropdown-container--scroll"
                >
                  <EuiSelect
                    @compressed={{true}}
                    @fullWidth={{true}}
                    aria-label="Month"
                    @value={{this.month}}
                    @options={{this.monthNames}}
                    {{on "change" (pick "target.value" this.setMonth)}}
                  />
                </div>
                <div
                  class="react-datepicker__year-dropdown-container react-datepicker__year-dropdown-container--scroll"
                >
                  <EuiSelect
                    @compressed={{true}}
                    @fullWidth={{true}}
                    aria-label="Year"
                    @value={{this.year}}
                    @options={{this.years}}
                    {{on "change" (pick "target.value" this.setYear)}}
                  />
                </div>
              </div>
              <div class="react-datepicker__day-names">
                <div class="react-datepicker__day-name">Su</div>
                <div class="react-datepicker__day-name">Mo</div>
                <div class="react-datepicker__day-name">Tu</div>
                <div class="react-datepicker__day-name">We</div>
                <div class="react-datepicker__day-name">Th</div>
                <div class="react-datepicker__day-name">Fr</div>
                <div class="react-datepicker__day-name">Sa</div>
              </div>
            </div>

            <div
              class="react-datepicker__month react-datepicker__month--accessible"
            >
              {{#each this.days as |days|}}
                <div class="react-datepicker__week">
                  {{#each days as |day|}}
                    <div
                      role="button"
                      class={{concat
                        "react-datepicker__day"
                        (if
                          (and
                            (not day.isOutside)
                            (isSameDayHelper
                              this.year this.month day.day this.selectedDate
                            )
                          )
                          " react-datepicker__day--selected"
                        )
                        (if
                          (isSameDayHelper
                            this.year this.month day.day this.today
                          )
                          " react-datepicker__day--today"
                        )
                        (if
                          day.isOutside " react-datepicker__day--outside-month"
                        )
                        (if
                          (this.isDayDisabled day)
                          " react-datepicker__day--disabled"
                        )
                      }}
                      aria-disabled={{if (this.isDayDisabled day) "true"}}
                      {{on "click" (fn this.selectDate day)}}
                    >
                      <div class="react-datepicker__day-text">{{day.day}}</div>
                    </div>
                  {{/each}}
                </div>
              {{/each}}
            </div>
          </div>

          <div class="react-datepicker__time-container">
            <div class="react-datepicker__time">
              <div
                class="react-datepicker__time-box react-datepicker__time-box--accessible"
              >
                <ul class="react-datepicker__time-list">
                  {{#each this.times as |time|}}
                    <li
                      role="option"
                      class={{concat
                        "react-datepicker__time-list-item"
                        (if
                          (eq time this.selectedTime)
                          " react-datepicker__time-list-item--selected"
                        )
                      }}
                      {{on "click" (fn this.selectTime time)}}
                    >
                      {{time}}
                    </li>
                  {{/each}}
                </ul>
              </div>
            </div>
          </div>
        </div>
      </EuiFormControlLayout>
    </div>
  </template>
}
