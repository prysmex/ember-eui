/*
 * Ported from @elastic/eui 123.1.0 `components/date_picker/date_picker.js`
 * (the wrapper, its inline styles and form states) and the calendar of its
 * fork of react-datepicker@2.0.0, MIT, Copyright (c) 2018 HackerOne Inc and
 * individual contributors (see NOTICE.md). EUI's code: Copyright
 * Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one or more
 * contributor license agreements. Licensed under the Elastic License 2.0 or
 * the Server Side Public License, v 1; see vendor/eui-latest.
 *
 * The values are strings, not moments (DESIGN 4, 5), and the logic is new.
 */
import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { warn } from '@ember/debug';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiDatePickerStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { validIsoDate } from '../utils/date/calendar-date.ts';
import {
  dayLimits,
  isUnreadableLimit,
  limitsConflict
} from '../utils/date/calendar-nav.ts';
import { localeDefaults } from '../utils/date/format.ts';
import { normalizeTimeZone, validTimeZone } from '../utils/date/zone.ts';
import EuiDatePickerCalendar from './eui-date-picker/calendar.gts';
import EuiFormControlLayout from './eui-form-control-layout.gts';

import type { Weekday } from '../utils/date/calendar-date.ts';
import type { DateOrder } from '../utils/date/parse.ts';
import type EuiI18n from '../services/eui-i18n.ts';

export interface EuiDatePickerSignature {
  /** `...attributes` go to the calendar's root (`div.react-datepicker`, `role="group"`). */
  Element: HTMLDivElement;
  Args: {
    /** The value, `YYYY-MM-DD`. `null` or `undefined` for none. */
    value?: string | null;
    /** Called with the chosen day, `YYYY-MM-DD`. Never with a disabled day. */
    onChange?: (value: string | null) => void;
    /** Shows the clear button (below the calendar) while there is a value. */
    onClear?: () => void;

    /** Shows the calendar in the page. Until batch 3 adds the text input and popover, the calendar is always inline. */
    inline?: boolean;
    /** With `@inline`: the raised frame. Default true. */
    shadow?: boolean;

    /** 'local' (default), 'utc' or an IANA name: the zone of "today". */
    timeZone?: 'local' | 'utc' | (string & {});
    /** BCP 47 tag for names and defaults. Default: the document's language, then the browser's. */
    locale?: string;
    /** 0 (Sunday) to 6. Default from `@locale`. */
    firstDayOfWeek?: Weekday;

    /** Days before are disabled (`YYYY-MM-DD`). */
    minDate?: string | null;
    /** Days after are disabled (`YYYY-MM-DD`). */
    maxDate?: string | null;
    /** These days are disabled. */
    excludeDates?: readonly string[] | null;
    /** When given, only these days are enabled. */
    includeDates?: readonly string[] | null;
    /** Called with `YYYY-MM-DD`; `false` disables the day. */
    filterDate?: ((date: string) => boolean) | null;

    /** The month shown when there is no value. */
    openToDate?: string | null;
    /** Extra classes for a day, called with `YYYY-MM-DD` (upstream `dayClassName`). */
    dayClassName?: (date: string) => string | null | undefined;
    /** Extra classes on the calendar (upstream `calendarClassName`). */
    calendarClass?: string;

    isInvalid?: boolean;
    isLoading?: boolean;
    disabled?: boolean;
    readOnly?: boolean;
  };
}

/** Whether a value is a `Date` or a moment-like object rather than a string (9 #2). */
function isDateObject(value: unknown): boolean {
  return (
    value instanceof Date ||
    (typeof value === 'object' &&
      value !== null &&
      typeof (value as { isValid?: unknown }).isValid === 'function')
  );
}

/**
 * A date picker: a calendar of days (upstream `EuiDatePicker`). Values are
 * `YYYY-MM-DD` strings.
 *
 * Private until batch 3: not registered, and only the inline calendar
 * exists. See `internal/spikes/date-picker/DESIGN.md`.
 */
export default class EuiDatePicker extends Component<EuiDatePickerSignature> {
  @service declare euiI18n: EuiI18n;

  get context() {
    return getEuiThemeContext(this);
  }

  /** The value when it is a real `YYYY-MM-DD` date, else null. */
  get value(): string | null {
    return validIsoDate(this.args.value);
  }

  /** A value is present but not a date (9 #1, #2). */
  get hasUnreadableValue(): boolean {
    const { value } = this.args;
    return value != null && value !== '' && this.value === null;
  }

  get zone(): string {
    return normalizeTimeZone(this.args.timeZone);
  }

  get hasUnknownZone(): boolean {
    return !validTimeZone(this.args.timeZone);
  }

  @cached
  get localeDefaults(): {
    locale: string;
    dateOrder: DateOrder;
    hour12: boolean;
    firstDayOfWeek: Weekday;
  } {
    return localeDefaults(this.args.locale);
  }

  get firstDayOfWeek(): Weekday {
    const day = this.args.firstDayOfWeek;
    return typeof day === 'number' &&
      Number.isInteger(day) &&
      day >= 0 &&
      day <= 6
      ? day
      : this.localeDefaults.firstDayOfWeek;
  }

  get isInvalid(): boolean {
    return Boolean(
      this.args.isInvalid || this.hasUnreadableValue || this.hasUnknownZone
    );
  }

  /** Development warnings for what the picker cannot read (9 #1, #2, #18, #24). */
  @cached
  get warnings(): null {
    const { value, timeZone, minDate, maxDate } = this.args;
    warn(
      isDateObject(value)
        ? 'EuiDatePicker: @value must be a YYYY-MM-DD string, not a Date or a moment.'
        : `EuiDatePicker: @value ${JSON.stringify(value)} is not a YYYY-MM-DD date.`,
      !this.hasUnreadableValue,
      { id: 'ember-eui.eui-date-picker.unreadable-value' }
    );
    warn(
      `EuiDatePicker: @timeZone ${JSON.stringify(timeZone)} is not a time zone this browser knows; it is shown as UTC.`,
      !this.hasUnknownZone,
      { id: 'ember-eui.eui-date-picker.unknown-time-zone' }
    );
    for (const [name, limit] of [
      ['@minDate', minDate],
      ['@maxDate', maxDate]
    ] as const) {
      warn(
        `EuiDatePicker: ${name} ${JSON.stringify(limit)} is not a YYYY-MM-DD date; it is ignored.`,
        !isUnreadableLimit(limit),
        { id: 'ember-eui.eui-date-picker.unreadable-limit' }
      );
    }
    warn(
      'EuiDatePicker: @minDate is after @maxDate; every day is disabled.',
      !limitsConflict(dayLimits({ minDate, maxDate }, this.zone)),
      { id: 'ember-eui.eui-date-picker.limits-conflict' }
    );
    return null;
  }

  /** Upstream's inline wrapper: frame, then invalid (when interactive), shadow, disabled, read-only. */
  @cached
  get rootClass() {
    const styles = useEuiBorealisStyles(this.context, euiDatePickerStyles);
    const { disabled, readOnly } = this.args;
    return euiClass(
      this.context,
      { boxSizing: 'border-box' },
      styles.euiDatePicker,
      styles.inline.inline,
      this.isInvalid && !(disabled || readOnly) && styles.inline.invalid,
      this.args.shadow !== false
        ? styles.inline.shadow
        : styles.inline.noShadow,
      disabled && styles.inline.disabled,
      readOnly && styles.inline.readOnly
    );
  }

  /** The inline calendar's name (DESIGN 7.3); `aria-label` or `aria-labelledby` on the picker win. */
  get calendarLabel() {
    return this.euiI18n.lookupToken(
      'euiDatePicker.calendarLabel',
      'Choose date'
    );
  }

  get clear() {
    const { onClear, disabled, readOnly } = this.args;
    return this.value !== null && onClear && !disabled && !readOnly
      ? this.onClear
      : undefined;
  }

  @action
  onClear() {
    this.args.onClear?.();
  }

  @action
  onSelect(date: string) {
    this.args.onChange?.(date);
  }

  <template>
    {{this.warnings}}
    <div class="euiDatePicker {{this.rootClass}}">
      <EuiFormControlLayout
        @isDelimited={{true}}
        @iconsPosition="static"
        @clear={{this.clear}}
        @isLoading={{@isLoading}}
        @isInvalid={{this.isInvalid}}
        @isDisabled={{@disabled}}
        @readOnly={{@readOnly}}
      >
        <EuiDatePickerCalendar
          role="group"
          aria-label={{this.calendarLabel}}
          @selected={{this.value}}
          @onSelect={{this.onSelect}}
          @openToDate={{@openToDate}}
          @minDate={{@minDate}}
          @maxDate={{@maxDate}}
          @excludeDates={{@excludeDates}}
          @includeDates={{@includeDates}}
          @filterDate={{@filterDate}}
          @timeZone={{this.zone}}
          @locale={{this.localeDefaults.locale}}
          @firstDayOfWeek={{this.firstDayOfWeek}}
          @dayClassName={{@dayClassName}}
          @calendarClass={{@calendarClass}}
          @disabled={{@disabled}}
          @readOnly={{@readOnly}}
          ...attributes
        />
      </EuiFormControlLayout>
    </div>
  </template>
}
