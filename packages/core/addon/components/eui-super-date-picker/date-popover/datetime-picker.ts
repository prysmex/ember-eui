import { action } from '@ember/object';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { helper } from '@ember/component/helper';
import moment from 'moment';
// import { isDayDisabled, isOutOfBounds } from '../utils/date-utils';

const isSameDayHelper = helper(function ([year, month, day, selectedDate]: [
  number,
  number,
  number,
  moment.Moment
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
  selected: moment.Moment;
  onChange: (value: any) => void;
}

interface Day {
  day: number;
  month: number;
  year: number;
  isOutside: boolean;
}

export default class DatetimePicker extends Component<DatetimePickerArgs> {
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

  isSameDayHelper = isSameDayHelper;

  constructor(owner: unknown, args: DatetimePickerArgs) {
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
    let hour = this.momentConfig.hour;
    let minute = this.momentConfig.minute;
    let hourStr = hour < 10 ? `0${hour}` : hour;
    let minuteStr = minute < 10 ? `0${minute}` : minute;
    this.selectedTime = `${hourStr}:${minuteStr}`;

    this.offset = this.monthMoment.clone().startOf('month').day();

    this.today = moment();
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
      let year = this.year - 7 + i;
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
      let hour = i < 10 ? `0${i}` : i;
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
    let daysInMonth = this.monthMoment.daysInMonth();
    let daysInPrevMonth = prevMonth.daysInMonth();

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

  @action selectTime(time: string) {
    this.selectedTime = time;
    const [hour, minute] = time.split(':');
    this.momentConfig.hour = parseInt(hour);
    this.momentConfig.minute = parseInt(minute);
    this.momentConfig.second = 0;
    this.momentConfig.millisecond = 0;
    this.selectedDate = moment(this.momentConfig);
    this.args.onChange(this.selectedDate);
  }

  @action selectDate(day: Day) {
    // Only outside days will have year/month
    this.momentConfig.year = day.year || this.year;
    this.momentConfig.month = day.month || this.month;
    this.momentConfig.day = day.day;
    this.selectedDate = moment(this.momentConfig);
    this.args.onChange(this.selectedDate);

    // Update the state to show the selected month properly
    if (day.isOutside) {
      this.monthMoment.month(day.month);
      this.monthMoment.year(day.year);
      this.updateDate();
    }
  }

  // @action setSelected(date, event, keepInput) {
  //   let changedDate = date;

  //   if (changedDate !== null && isDayDisabled(changedDate, this.props)) {
  //     if (isOutOfBounds(changedDate, this.props)) {
  //       this.props.onChange(date, event);
  //       this.props.onSelect(changedDate, event);
  //     }

  //     return;
  //   }

  //   if (changedDate !== null && this.props.selected) {
  //     let selected = this.props.selected;
  //     if (keepInput) selected = newDate(changedDate);
  //     changedDate = setTime(newDate(changedDate), {
  //       hour: getHour(selected),
  //       minute: getMinute(selected),
  //       second: getSecond(selected),
  //       millisecond: getMillisecond(selected),
  //     });
  //   }

  //   if (
  //     !isSameTime(this.props.selected, changedDate) ||
  //     this.props.allowSameDay
  //   ) {
  //     if (changedDate !== null) {
  //       if (!this.props.inline) {
  //         this.setState({
  //           preSelection: changedDate
  //         });
  //       }
  //     }
  //     this.props.onChange(changedDate, event);
  //   }

  //   this.props.onSelect(changedDate, event);

  //   if (!keepInput) {
  //     this.setState({ inputValue: null });
  //   }
  // }

  @action setYear(year: string) {
    this.year = parseInt(year);
  }

  @action setMonth(month: string) {
    this.monthMoment.month(parseInt(month));
    this.updateDate();
  }

  @action increaseMonth() {
    this.monthMoment.add(1, 'month');
    this.updateDate();
  }

  @action decreaseMonth() {
    this.monthMoment.subtract(1, 'month');
    this.updateDate();
  }
}
