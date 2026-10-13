import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import type Owner from '@ember/owner';

import dateMath from '@elastic/datemath';
import moment from 'moment';

import { randomId } from '../../../-private/random-id.ts';
import { getEuiThemeContext } from '../../../utils/emotion/consume.ts';
import { euiAbsoluteTabDateFormStyles } from '../../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../../utils/eui/styles.ts';
import EuiFieldText from '../../eui-field-text.gts';
import EuiFormLabel from '../../eui-form-label.gts';
import EuiFormRow from '../../eui-form-row.gts';
import EuiI18n from '../../eui-i18n.gts';
import DatetimePicker from './datetime-picker.gts';
import EuiTimeZoneDisplay from './eui-time-zone-display.gts';

import type { EuiTimeZoneDisplayProps } from './eui-time-zone-display.gts';
import type { LocaleSpecifier, Moment } from 'moment';

interface AbsoluteTabArgs {
  /** moment format of absolute dates. */
  dateFormat?: string;
  /** moment format of times. */
  timeFormat?: string;
  /** moment locale. */
  locale?: LocaleSpecifier;
  /** The date (date math or ISO date). */
  value: string;
  /** Called with the new value. */
  onChange: (value: string, event?: Event) => void;
  /** Rounds relative dates up (for the end of a range). */
  roundUp: boolean;
  /** `'start'` or `'end'` of the range. */
  position: 'start' | 'end';
  /** Prefix of the input labels, e.g. "Start date". */
  labelPrefix: string;
  /** UTC offset in minutes. */
  utcOffset?: number;
  /** Earliest selectable day of the calendar. */
  minDate?: Moment;
  /** Latest selectable day of the calendar. */
  maxDate?: Moment;
  /** Shows the time zone under the form (see `EuiTimeZoneDisplay`). */
  timeZoneDisplayProps?: EuiTimeZoneDisplayProps;
}

/** @private The "Absolute" tab of the date popover. */
export interface AbsoluteTabSignature {
  Args: AbsoluteTabArgs;
}

export default class AbsoluteTab extends Component<AbsoluteTabSignature> {
  @tracked isTextInvalid: boolean;
  @tracked textInputValue: string;
  @tracked valueAsMoment: Moment | null;

  constructor(owner: Owner, args: AbsoluteTabArgs) {
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

  labelId = randomId();
  timeZoneDescriptionId = randomId();

  /** Upstream `euiAbsoluteTabDateForm`: the text input under the calendar. */
  @cached
  get formClass() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiAbsoluteTabDateFormStyles);
    return euiClass(
      context,
      { boxSizing: 'border-box', display: 'flex' },
      styles.euiAbsoluteTabDateForm
    );
  }

  @cached
  get rowClass() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiAbsoluteTabDateFormStyles);
    return euiClass(context, { minInlineSize: 0 }, styles.euiAbsoluteTabDateForm__row);
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
    <div class="euiAbsoluteTab">
      <DatetimePicker
        @onChange={{this.handleChange}}
        @dateFormat={{@dateFormat}}
        @selected={{this.valueAsMoment}}
        @minDate={{@minDate}}
        @maxDate={{@maxDate}}
      />
      <EuiI18n
        @token="euiAbsoluteTab.dateFormatError"
        @default="Expected format: {dateFormat}"
        @values={{hash dateFormat=@dateFormat}}
        as |Token|
      >
        <Token as |dateFormatError|>
          <div class="euiAbsoluteTabDateForm {{this.formClass}}">
            <div class={{this.rowClass}}>
              <EuiFormRow
                class="euiSuperDatePicker__absoluteDateFormRow"
                @isInvalid={{this.isTextInvalid}}
                @error={{if this.isTextInvalid dateFormatError}}
              >
                <EuiFieldText
                  aria-labelledby={{this.labelId}}
                  aria-describedby={{this.timeZoneDescriptionId}}
                  data-test-subj="superDatePickerAbsoluteDateInput"
                  @isInvalid={{this.isTextInvalid}}
                  @value={{this.textInputValue}}
                  @compressed={{true}}
                  {{on "input" this.triggerChange}}
                  {{on "change" this.handleTextChange}}
                >
                  <:prepend as |classes|>
                    <EuiFormLabel id={{this.labelId}} class={{classes}}>
                      {{@labelPrefix}}
                    </EuiFormLabel>
                  </:prepend>
                </EuiFieldText>
              </EuiFormRow>
            </div>
          </div>
        </Token>
      </EuiI18n>
      <EuiTimeZoneDisplay
        @id={{this.timeZoneDescriptionId}}
        @timeZone={{@timeZoneDisplayProps.timeZone}}
        @date={{@timeZoneDisplayProps.date}}
        @customRender={{@timeZoneDisplayProps.customRender}}
      />
    </div>
  </template>
}
