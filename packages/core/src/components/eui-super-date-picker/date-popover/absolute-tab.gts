import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import type Owner from '@ember/owner';

import dateMath from '@elastic/datemath';
import moment from 'moment';

import { randomId } from '../../../-private/random-id.ts';
import { localeDefaults } from '../../../utils/date/format.ts';
import { getEuiThemeContext } from '../../../utils/emotion/consume.ts';
import {
  euiAbsoluteTabDateFormStyles,
  euiDatePickerStyles
} from '../../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../../utils/eui/styles.ts';
import EuiDatePickerCalendar from '../../eui-date-picker/calendar.gts';
import EuiFieldText from '../../eui-field-text.gts';
import EuiFormControlLayout from '../../eui-form-control-layout.gts';
import EuiFormLabel from '../../eui-form-label.gts';
import EuiFormRow from '../../eui-form-row.gts';
import EuiI18n from '../../eui-i18n.gts';
import EuiTimeZoneDisplay from './eui-time-zone-display.gts';

import type { TimeOfDay } from '../../../utils/date/parse.ts';
import type { TimeEntry } from '../../../utils/date/times.ts';
import type { EuiTimeZoneDisplayProps } from './eui-time-zone-display.gts';
import type { LocaleSpecifier, Moment } from 'moment';

const pad = (n: number, width = 2) => String(n).padStart(width, '0');

/** A moment's calendar day as `YYYY-MM-DD`, read from its fields (never `format`, whose digits follow the moment's locale). */
function dayOf(m: Moment): string {
  return `${pad(m.year(), 4)}-${pad(m.month() + 1)}-${pad(m.date())}`;
}

/** A limit's day in local time, as the calendar's zone; the caller's moment is only read. */
function limitDay(m: Moment | null | undefined): string | null {
  if (!moment.isMoment(m) || !m.isValid()) return null;
  return dayOf(moment(m.valueOf()));
}

/**
 * A moment locale as a BCP 47 tag for the calendar's names and first day
 * of the week: `@locale`, else moment's global locale (where the old
 * calendar took its month names), else `'en'`.
 */
function calendarLocale(locale: LocaleSpecifier | null | undefined): string {
  const given = Array.isArray(locale) ? locale[0] : locale;
  const tag =
    typeof given === 'string' && given.trim() !== '' ? given : moment.locale();
  if (typeof tag !== 'string' || tag.trim() === '') return 'en';
  try {
    return Intl.getCanonicalLocales(tag)[0] ?? 'en';
  } catch {
    return 'en';
  }
}

interface AbsoluteTabArgs {
  /** moment format of absolute dates. */
  dateFormat?: string;
  /** moment format of times. */
  timeFormat?: string;
  /** moment locale; `'en'` when unset or `null`. */
  locale?: LocaleSpecifier | null;
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
  /**
   * The last valid value: the calendar and the time list show it, also
   * while the typed text cannot be read. It is the tab's own moment; the
   * caller's `@minDate` and `@maxDate` are only read.
   */
  @tracked valueAsMoment: Moment;

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
    return euiClass(
      context,
      { minInlineSize: 0 },
      styles.euiAbsoluteTabDateForm__row
    );
  }

  /** Upstream `EuiDatePicker inline shadow={false}`: a block wrapper whose form control layout loses its frame. */
  @cached
  get pickerClass() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDatePickerStyles);
    return euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiDatePicker,
      styles.inline.inline,
      styles.inline.noShadow
    );
  }

  /* The calendar (`EuiDatePickerCalendar`): moments are converted here, at its edge. */

  /** The calendar's names and first day of the week follow `@locale`, else moment's global locale. */
  @cached
  get calendarLocale() {
    return localeDefaults(calendarLocale(this.args.locale));
  }

  get selectedDay(): string {
    return dayOf(this.valueAsMoment);
  }

  get selectedTime(): TimeOfDay {
    const m = this.valueAsMoment;
    return { hour: m.hours(), minute: m.minutes(), second: m.seconds() };
  }

  get minDay(): string | null {
    return limitDay(this.args.minDate);
  }

  get maxDay(): string | null {
    return limitDay(this.args.maxDate);
  }

  /** A day picked in the calendar: the value's time on that day. */
  @action
  pickDay(date: string, e: Event) {
    const [year, month, day] = date.split('-').map(Number) as [
      number,
      number,
      number
    ];
    this.handleChange(
      this.valueAsMoment.clone().set({ year, month: month - 1, date: day }),
      e
    );
  }

  /** A time picked in the list: that time on its day, seconds zero (upstream). */
  @action
  pickTime(date: string | null, entry: TimeEntry, e: Event) {
    const next = this.valueAsMoment.clone();
    if (date !== null) {
      const [year, month, day] = date.split('-').map(Number) as [
        number,
        number,
        number
      ];
      next.set({ year, month: month - 1, date: day });
    }
    next.set({
      hour: entry.time.hour,
      minute: entry.time.minute,
      second: 0,
      millisecond: 0
    });
    this.handleChange(next, e);
  }

  @action
  handleChange(date: Moment, e: Event) {
    this.args.onChange(date.toISOString(), e);

    this.valueAsMoment = date;
    // in moment's global locale, as before: typed text is parsed in it
    this.textInputValue = date
      .clone()
      .locale(moment.locale())
      .format(this.args.dateFormat);
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
      this.valueAsMoment = valueAsMoment;
    }

    this.textInputValue = (e.target as HTMLInputElement).value;
    this.isTextInvalid = !dateIsValid;
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
      <div class="euiDatePicker {{this.pickerClass}}">
        <EuiFormControlLayout>
          <EuiDatePickerCalendar
            role="group"
            aria-label={{@labelPrefix}}
            @selected={{this.selectedDay}}
            @onPick={{this.pickDay}}
            @minDate={{this.minDay}}
            @maxDate={{this.maxDay}}
            @locale={{this.calendarLocale.locale}}
            @firstDayOfWeek={{this.calendarLocale.firstDayOfWeek}}
            @showTimeSelect={{true}}
            @selectedTime={{this.selectedTime}}
            @hour12={{false}}
            @onPickTime={{this.pickTime}}
          />
        </EuiFormControlLayout>
      </div>
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
