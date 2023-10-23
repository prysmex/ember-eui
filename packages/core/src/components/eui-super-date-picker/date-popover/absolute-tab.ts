import { action } from '@ember/object';
import Component from '@glimmer/component';
import moment, { LocaleSpecifier, Moment } from 'moment';
import dateMath from '@elastic/datemath';
import { tracked } from '@glimmer/tracking';

interface AbsoluteTabArgs {
  dateFormat: string;
  timeFormat: string;
  locale?: LocaleSpecifier;
  value: string;
  onChange: (value: any) => void;
  roundUp: boolean;
  position: 'start' | 'end';
  labelPrefix: string;
  utcOffset?: number;
}

export default class AbsoluteTab extends Component<AbsoluteTabArgs> {
  @tracked isTextInvalid: boolean;
  @tracked textInputValue: string;
  @tracked valueAsMoment: Moment | null;

  constructor(owner: unknown, args: AbsoluteTabArgs) {
    super(owner, args);

    const parsedValue = dateMath.parse(this.args.value, {
      roundUp: this.args.roundUp
    });
    const valueAsMoment =
      parsedValue && parsedValue.isValid() ? parsedValue : moment();

    const textInputValue = valueAsMoment
      .locale(this.args.locale || 'en')
      .format(this.args.dateFormat);

    this.isTextInvalid = false;
    this.textInputValue = textInputValue;
    this.valueAsMoment = valueAsMoment;
  }

  @action handleChange(date: any) {
    if (date === null) {
      return;
    }

    this.args.onChange(date.toISOString());

    const valueAsMoment = moment(date);
    this.valueAsMoment = valueAsMoment;
    this.textInputValue = valueAsMoment.format(this.args.dateFormat);
    this.isTextInvalid = false;
  }

  @action handleTextChange(e: InputEvent) {
    const valueAsMoment = moment(
      (e.target as HTMLInputElement).value,
      this.args.dateFormat,
      true
    );
    const dateIsValid = valueAsMoment.isValid();
    if (dateIsValid) {
      this.args.onChange(valueAsMoment.toISOString());
    }

    this.textInputValue = (e.target as HTMLInputElement).value;
    this.isTextInvalid = !dateIsValid;
    this.valueAsMoment = dateIsValid ? valueAsMoment : null;
  }

  // `change` event on an input gets called after a `blur`
  // blur the input and focus again to trigger the change event
  // and call `handleTextChange` with the updated value
  // and keep the field focused
  @action triggerChange(e: InputEvent) {
    (e.target as HTMLInputElement).blur();
    (e.target as HTMLInputElement).focus();
  }
}
