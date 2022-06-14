import Component from '@glimmer/component';
import dateMath from '@elastic/datemath';
import { INVALID_DATE, toRelativeStringFromParts } from '../utils';
import { LocaleSpecifier } from 'moment';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { parseRelativeParts } from '../utils';
import { EuiDatePopoverContentProps } from '@elastic/eui';

interface RelativeTabArgs {
  dateFormat: string;
  locale?: LocaleSpecifier;
  value: string;
  onChange: EuiDatePopoverContentProps['onChange'];
  roundUp?: boolean;
  position: 'start' | 'end';
  labelPrefix: string;
  // timeOptions: TimeOptions;
}

export default class RelativeTab extends Component<RelativeTabArgs> {
  @tracked count?: number;
  @tracked unit;

  round;
  roundUnit;

  constructor(owner: unknown, args: RelativeTabArgs) {
    super(owner, args);
    const parsed = parseRelativeParts(this.args.value);
    if (parsed) {
      this.count = parsed.count;
      this.unit = parsed.unit;
      this.round = parsed.round;
      this.roundUnit = parsed.roundUnit;
    }
  }

  get formattedValue() {
    const invalidDate = this.args.value === INVALID_DATE;
    const invalidValue = this.count === undefined || this.count < 0;
    const isInvalid = invalidValue || invalidDate;
    const parsedValue = dateMath.parse(this.args.value, {
      roundUp: this.args.roundUp
    });
    const invalid = isInvalid || !parsedValue || !parsedValue.isValid();
    return invalid
      ? ''
      : parsedValue
          .locale(this.args.locale || 'en')
          .format(this.args.dateFormat);
  }

  @action onCountChange(e: InputEvent) {
    const sanitizedValue = parseInt((e.target as HTMLInputElement).value, 10);
    this.count = isNaN(sanitizedValue) ? undefined : sanitizedValue;
    this.handleChange();
  }

  @action onUnitChange(unit: string) {
    this.unit = unit;
    this.handleChange();
  }

  @action onRoundChange(checked: boolean) {
    this.round = checked;
    this.handleChange();
  }

  handleChange() {
    if (this.count === undefined || this.count < 0) {
      return;
    }
    const date = toRelativeStringFromParts({
      count: this.count,
      round: this.round,
      roundUnit: this.roundUnit,
      unit: this.unit
    });
    console.log(date);
    this.args.onChange(date);
  }
}
