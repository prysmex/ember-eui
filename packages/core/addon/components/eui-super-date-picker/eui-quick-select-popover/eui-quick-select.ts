import { action } from '@ember/object';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { ApplyTime, TimeUnitId } from '../types/global';
import { parseTimeParts } from '../utils/quick-select';
import { NEXT, TimeOptions } from '../utils/time-options';
import moment from 'moment';
import dateMath from '@elastic/datemath';

interface EuiQuickSelectArgs {
  applyTime: ApplyTime;
  start: string;
  end: string;
  // prevQuickSelect?: EuiQuickSelectState;
  timeOptions: TimeOptions;
}

export default class EuiQuickSelect extends Component<EuiQuickSelectArgs> {
  @tracked timeTense: string;
  @tracked timeValue: number;
  @tracked timeUnits: TimeUnitId;

  constructor(owner: unknown, args: EuiQuickSelectArgs) {
    super(owner, args);

    const {
      timeTense: timeTenseDefault,
      timeUnits: timeUnitsDefault,
      timeValue: timeValueDefault
    } = parseTimeParts(this.args.start, this.args.end);

    this.timeTense =
      this.args.prevQuickSelect && this.args.prevQuickSelect.timeTense
        ? this.args.prevQuickSelect.timeTense
        : timeTenseDefault;
    this.timeValue =
      this.args.prevQuickSelect && this.args.prevQuickSelect.timeValue
        ? this.args.prevQuickSelect.timeValue
        : timeValueDefault;
    this.timeUnits =
      this.args.prevQuickSelect && this.args.prevQuickSelect.timeUnits
        ? this.args.prevQuickSelect.timeUnits
        : timeUnitsDefault;
  }

  getBounds() {
    const startMoment = dateMath.parse(this.args.start);
    const endMoment = dateMath.parse(this.args.end, { roundUp: true });
    return {
      min:
        startMoment && startMoment.isValid()
          ? startMoment
          : moment().subtract(15, 'minute'),
      max: endMoment && endMoment.isValid() ? endMoment : moment()
    };
  }

  @action applyQuickSelect() {
    if (this.timeTense === NEXT) {
      this.args.applyTime({
        start: 'now',
        end: `now+${this.timeValue}${this.timeUnits}`
        // quickSelect: { ...this.state },
      });
    } else {
      this.args.applyTime({
        start: `now-${this.timeValue}${this.timeUnits}`,
        end: 'now'
        // quickSelect: { ...this.state },
      });
    }
  }

  @action stepForward() {
    const { min, max } = this.getBounds();
    const diff = max.diff(min);
    this.args.applyTime({
      start: moment(max).add(1, 'ms').toISOString(),
      end: moment(max)
        .add(diff + 1, 'ms')
        .toISOString(),
      keepPopoverOpen: true
    });
  }

  @action stepBackward() {
    const { min, max } = this.getBounds();
    const diff = max.diff(min);
    this.args.applyTime({
      start: moment(min)
        .subtract(diff + 1, 'ms')
        .toISOString(),
      end: moment(min).subtract(1, 'ms').toISOString(),
      keepPopoverOpen: true
    });
  }
}
