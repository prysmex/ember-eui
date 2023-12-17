import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import dateMath from '@elastic/datemath';
import moment from 'moment';

import EuiFieldText from '../../eui-field-text.gts';
import EuiFormLabel from '../../eui-form-label.gts';
import EuiFormRow from '../../eui-form-row.gts';
import EuiI18n from '../../eui-i18n.gts';
import DatetimePicker from './datetime-picker.gts';

import type { LocaleSpecifier, Moment } from 'moment';

interface AbsoluteTabArgs {
  dateFormat?: string;
  timeFormat?: string;
  locale?: LocaleSpecifier;
  value: string;
  onChange: (value: string, event?: Event) => void;
  roundUp: boolean;
  position: 'start' | 'end';
  labelPrefix: string;
  utcOffset?: number;
}

export interface AbsoluteTabSignature {
  Args: AbsoluteTabArgs;
}

export default class AbsoluteTab extends Component<AbsoluteTabSignature> {
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

  @action
  handleChange(date: any, e: Event) {
    if (date === null) {
      return;
    }

    this.args.onChange(date.toISOString(), e);

    const valueAsMoment = moment(date);

    this.valueAsMoment = valueAsMoment;
    this.textInputValue = valueAsMoment.format(this.args.dateFormat);
    this.isTextInvalid = false;
  }

  @action
  handleTextChange(e: Event) {
    const valueAsMoment = moment(
      (e.target as HTMLInputElement).value,
      this.args.dateFormat,
      true
    );
    const dateIsValid = valueAsMoment.isValid();

    if (dateIsValid) {
      this.args.onChange(valueAsMoment.toISOString(), e);
    }

    this.textInputValue = (e.target as HTMLInputElement).value;
    this.isTextInvalid = !dateIsValid;
    this.valueAsMoment = dateIsValid ? valueAsMoment : null;
  }

  // `change` event on an input gets called after a `blur`
  // blur the input and focus again to trigger the change event
  // and call `handleTextChange` with the updated value
  // and keep the field focused
  @action
  triggerChange(e: Event) {
    (e.target as HTMLInputElement).blur();
    (e.target as HTMLInputElement).focus();
  }

  <template>
    <div>
      <DatetimePicker
        @onChange={{this.handleChange}}
        @dateFormat={{@dateFormat}}
        @selected={{this.valueAsMoment}}
      />
      <EuiI18n
        @token="euiAbsoluteTab.dateFormatError"
        @default="Expected format: {dateFormat}"
        @values={{hash dateFormat=@dateFormat}}
        as |Token|
      >
        <Token as |dateFormatError|>
          <EuiFormRow
            class="euiSuperDatePicker__absoluteDateFormRow"
            @isInvalid={{this.isTextInvalid}}
            @error={{if this.isTextInvalid dateFormatError}}
          >
            <EuiFieldText
              @isInvalid={{this.isTextInvalid}}
              @value={{this.textInputValue}}
              @compressed={{true}}
              {{on "input" this.triggerChange}}
              {{on "change" this.handleTextChange}}
            >
              <:prepend as |classes|>
                <EuiFormLabel class={{classes}}>
                  {{@labelPrefix}}
                </EuiFormLabel>
              </:prepend>
            </EuiFieldText>
          </EuiFormRow>
        </Token>
      </EuiI18n>
    </div>
  </template>
}
