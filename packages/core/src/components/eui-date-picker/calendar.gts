/*
 * Ported from @elastic/eui 123.1.0
 * `components/date_picker/react-datepicker/src/calendar.js`, `month.js`,
 * `week.js` and `day.js`: the markup and class names. Those files fork
 * react-datepicker@2.0.0, MIT, Copyright (c) 2018 HackerOne Inc and
 * individual contributors (see NOTICE.md). EUI's changes: Copyright
 * Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one or more
 * contributor license agreements. Licensed under the Elastic License 2.0 or
 * the Server Side Public License, v 1; see vendor/eui-latest.
 *
 * The logic is new (DESIGN 3, 7): dates are `YYYY-MM-DD` strings
 * (`utils/date/*`), and the month is the WAI-ARIA date picker grid instead
 * of upstream's listbox.
 */
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import { service } from '@ember/service';
import type Owner from '@ember/owner';

import { modifier } from 'ember-modifier';
import { not, or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import {
  euiDatePickerCalendarStyles,
  euiReactDatePickerStyles
} from '../../utils/eui/date-pickers.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import {
  addMonthsTo,
  inMonth,
  monthBounds,
  validIsoDate,
  weekdayOf,
  weeksOfMonth
} from '../../utils/date/calendar-date.ts';
import {
  clampDate,
  dayLimits,
  dayProblem,
  focusInMonth,
  monthNavigation,
  nextFocusedDate,
  openingDate,
  tabStopDate,
  yearRange
} from '../../utils/date/calendar-nav.ts';
import {
  fullDateLabel,
  monthNames,
  monthYearLabel,
  weekdayNames
} from '../../utils/date/format.ts';
import { todayIn } from '../../utils/date/zone.ts';
import EuiButtonIcon from '../eui-button-icon.gts';
import { euiScreenReaderOnlyClass } from '../eui-screen-reader-only.gts';
import EuiSelect from '../eui-select.gts';

import type { Weekday } from '../../utils/date/calendar-date.ts';
import type { DayLimits } from '../../utils/date/calendar-nav.ts';
import type EuiI18n from '../../services/eui-i18n.ts';

/** react-datepicker's `react-datepicker__day--{code}` classes, by `getUTCDay`. */
const DAY_CODES = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'] as const;

/** The longest short weekday name shown as is, in characters. */
const MAX_SHORT_WEEKDAY = 4;

export interface CalendarDay {
  /** `YYYY-MM-DD`; null for a cell outside 0001 to 9999. */
  date: string | null;
  key: string;
  number: number;
  label: string;
  className: string;
  disabled: boolean;
  selected: boolean;
  today: boolean;
  tabIndex: 0 | -1;
}

interface View {
  year: number;
  month: number;
  focused: string;
  /** The `@selected` and `@openToDate` this view was made for: it is dropped when they change (9 #29). */
  forSelected: string | null;
  forOpenTo: string | null;
}

export interface EuiDatePickerCalendarSignature {
  Element: HTMLDivElement;
  Args: {
    /** The selected day, `YYYY-MM-DD`. Anything else selects nothing. */
    selected?: string | null;
    /** Called with the chosen day; never with a disabled one, nor with the selected one. */
    onSelect?: (date: string, event: Event) => void;
    /** The month shown when there is no selected day. */
    openToDate?: string | null;
    minDate?: string | null;
    maxDate?: string | null;
    excludeDates?: readonly string[] | null;
    includeDates?: readonly string[] | null;
    filterDate?: ((date: string) => boolean) | null;
    /** The field's zone, normalized (`normalizeTimeZone`): for "today", and for limits that are instants. */
    timeZone?: string;
    /** A resolved BCP 47 tag (`resolveLocale`). */
    locale: string;
    firstDayOfWeek: Weekday;
    /** Extra classes for a day (upstream `dayClassName`), called with `YYYY-MM-DD`. */
    dayClassName?: (date: string) => string | null | undefined;
    /** Extra classes on the `react-datepicker` element (upstream `calendarClassName`). */
    calendarClass?: string;
    /** Nothing can be chosen or focused; the days are dimmed. */
    disabled?: boolean;
    /** Nothing can be chosen or focused. */
    readOnly?: boolean;
    /** @private The clock, for tests. Read when the calendar is made and when the month changes. */
    now?: () => number;
  };
}

/**
 * @private The calendar of `EuiDatePicker`: the month and year selects,
 * the navigation buttons and the day grid (DESIGN 7.1 to 7.4).
 */
export default class EuiDatePickerCalendar extends Component<EuiDatePickerCalendarSignature> {
  @service declare euiI18n: EuiI18n;

  /** The clock as read last (DESIGN 5.1: when the calendar is made and when the month changes). */
  @tracked private now: number;
  @tracked private view: View | null = null;
  /** Bumped by a key in the grid or a pick: the focused day's button then takes DOM focus. */
  @tracked private focusRequest = 0;
  private handledFocusRequest = 0;
  private headingId = `${guidFor(this)}-month`;

  constructor(owner: Owner, args: EuiDatePickerCalendarSignature['Args']) {
    super(owner, args);
    this.now = this.readClock();
  }

  private readClock(): number {
    return (this.args.now ?? Date.now)();
  }

  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get calendarClass() {
    const styles = useEuiBorealisStyles(this.context, euiReactDatePickerStyles);
    return euiClass(
      this.context,
      // React's global reset: border-box
      {
        boxSizing: 'border-box',
        '& :where(*, *::before, *::after)': { boxSizing: 'border-box' }
      },
      styles.euiReactDatePicker,
      useEuiBorealisStyles(this.context, euiDatePickerCalendarStyles)
    );
  }

  get headingClass() {
    return euiScreenReaderOnlyClass(this.context);
  }

  get interactive(): boolean {
    return !this.args.disabled && !this.args.readOnly;
  }

  get zone(): string {
    return this.args.timeZone ?? 'local';
  }

  get today(): string {
    return todayIn(this.zone, this.now);
  }

  get selected(): string | null {
    return validIsoDate(this.args.selected);
  }

  get openTo(): string | null {
    return validIsoDate(this.args.openToDate);
  }

  @cached
  get limits(): DayLimits {
    return dayLimits(
      {
        minDate: this.args.minDate,
        maxDate: this.args.maxDate,
        excludeDates: this.args.excludeDates,
        includeDates: this.args.includeDates,
        filterDate: this.args.filterDate
      },
      this.zone
    );
  }

  /** The view, while it was made for the current `@selected` and `@openToDate`. */
  get currentView(): View | null {
    const view = this.view;
    return view &&
      view.forSelected === this.selected &&
      view.forOpenTo === this.openTo
      ? view
      : null;
  }

  /** The day the calendar opens on: the selected day, else `@openToDate`, else today within the limits. */
  get opening(): string {
    return openingDate(
      this.selected,
      this.openTo,
      clampDate(this.today, this.limits)
    );
  }

  get shown(): { year: number; month: number } {
    const view = this.currentView;
    if (view) return view;
    const opening = this.opening;
    return {
      year: Number(opening.slice(0, 4)),
      month: Number(opening.slice(5, 7))
    };
  }

  /**
   * The day holding the grid's one tab stop (DESIGN 7.1): the focused day,
   * else the selected day, today or the first enabled day of the shown
   * month. Before any move, an enabled `@openToDate` counts as focused
   * (upstream's `preSelection`).
   */
  get focused(): string {
    const { year, month } = this.shown;
    return tabStopDate({
      year,
      month,
      focused: this.currentView?.focused ?? this.openToFocus,
      selected: this.selected,
      today: this.today,
      limits: this.limits
    });
  }

  get openToFocus(): string | null {
    const openTo = this.openTo;
    return openTo && !this.selected && dayProblem(openTo, this.limits) === null
      ? openTo
      : null;
  }

  /** Show the month of `date` and put the tab stop on it. The value does not change. */
  private moveTo(date: string) {
    const year = Number(date.slice(0, 4));
    const month = Number(date.slice(5, 7));
    const { year: shownYear, month: shownMonth } = this.shown;
    if (year !== shownYear || month !== shownMonth) this.now = this.readClock();
    this.view = {
      year,
      month,
      focused: date,
      forSelected: this.selected,
      forOpenTo: this.openTo
    };
  }

  /* Header */

  get previousMonthLabel() {
    return this.euiI18n.lookupToken(
      'euiDatePickerCalendar.previousMonth',
      'Previous month'
    );
  }

  get nextMonthLabel() {
    return this.euiI18n.lookupToken(
      'euiDatePickerCalendar.nextMonth',
      'Next month'
    );
  }

  get monthLabel() {
    return this.euiI18n.lookupToken('euiDatePickerCalendar.month', 'Month');
  }

  get yearLabel() {
    return this.euiI18n.lookupToken('euiDatePickerCalendar.year', 'Year');
  }

  get navigation() {
    const { year, month } = this.shown;
    const reachable = monthNavigation(year, month, this.limits);
    return {
      previous: this.interactive && reachable.previous,
      next: this.interactive && reachable.next
    };
  }

  /** The month select's value: 0 (January) to 11, as the Absolute tab's. */
  get monthIndex(): number {
    return this.shown.month - 1;
  }

  @cached
  get monthOptions() {
    const { year } = this.shown;
    const { min, max } = this.limits;
    return monthNames(this.args.locale).map((text, i) => {
      const { first, last } = monthBounds(year, i + 1);
      return {
        value: i,
        text,
        disabled: (min !== null && last < min) || (max !== null && first > max)
      };
    });
  }

  @cached
  get yearOptions() {
    const { from, to } = yearRange(this.shown.year, this.limits);
    const years = [];
    for (let year = from; year <= to; year++) {
      years.push({ value: year, text: year });
    }
    return years;
  }

  /** The shown month and year, for the grid's name and the live announcement. */
  get monthYear() {
    const { year, month } = this.shown;
    return monthYearLabel(year, month, this.args.locale);
  }

  @cached
  get weekdays() {
    const { locale, firstDayOfWeek } = this.args;
    let short = weekdayNames(locale, 'short', firstDayOfWeek);
    // A 32px column fits about four letters. Some locales' short names are
    // whole words (ar, fa, he): those get the narrow names. The long name
    // is still read out and kept in `abbr`.
    if (short.some((name) => [...name].length > MAX_SHORT_WEEKDAY)) {
      short = weekdayNames(locale, 'narrow', firstDayOfWeek);
    }
    const long = weekdayNames(locale, 'long', firstDayOfWeek);
    return short.map((name, i) => ({ short: name, long: long[i]! }));
  }

  /* Grid */

  @cached
  get weeks(): CalendarDay[][] {
    const { year, month } = this.shown;
    const { locale, firstDayOfWeek, dayClassName } = this.args;
    const limits = this.limits;
    const selected = this.selected;
    const today = this.today;
    const focused = this.focused;
    return weeksOfMonth(year, month, firstDayOfWeek).map((week, w) =>
      week.map((date, d): CalendarDay => {
        if (date === null) {
          return {
            date,
            key: `empty-${w}-${d}`,
            number: 0,
            label: '',
            className: 'react-datepicker__day react-datepicker__day--empty',
            disabled: true,
            selected: false,
            today: false,
            tabIndex: -1
          };
        }
        const weekday = weekdayOf(date);
        const disabled = dayProblem(date, limits) !== null;
        const isSelected = date === selected;
        const isToday = date === today;
        const classes = ['react-datepicker__day'];
        const custom = dayClassName?.(date);
        if (custom) classes.push(custom);
        classes.push(`react-datepicker__day--${DAY_CODES[weekday]}`);
        if (disabled) classes.push('react-datepicker__day--disabled');
        if (isSelected) classes.push('react-datepicker__day--selected');
        if (isToday) classes.push('react-datepicker__day--today');
        if (weekday === 0 || weekday === 6) {
          classes.push('react-datepicker__day--weekend');
        }
        if (!inMonth(date, year, month)) {
          classes.push('react-datepicker__day--outside-month');
        }
        return {
          date,
          key: date,
          number: Number(date.slice(8, 10)),
          label: fullDateLabel(date, locale),
          className: classes.join(' '),
          disabled,
          selected: isSelected,
          today: isToday,
          tabIndex: date === focused ? 0 : -1
        };
      })
    );
  }

  /** Gives DOM focus to the focused day after a key or a pick moved it, never otherwise. */
  focusDay = modifier(
    (element: HTMLElement, [date, request]: [string, number]) => {
      if (request === this.handledFocusRequest) return;
      this.handledFocusRequest = request;
      element
        .querySelector<HTMLButtonElement>(`[data-date="${date}"] > button`)
        ?.focus();
    }
  );

  /* Actions */

  @action
  previousMonth() {
    this.showMonthOffset(-1);
  }

  @action
  nextMonth() {
    this.showMonthOffset(1);
  }

  private showMonthOffset(n: number) {
    const { year, month } = addMonthsTo(this.shown.year, this.shown.month, n);
    this.moveTo(focusInMonth(this.focused, year, month, this.limits));
  }

  @action
  changeMonth(event: Event) {
    const month = Number((event.target as HTMLSelectElement).value) + 1;
    this.moveTo(
      focusInMonth(this.focused, this.shown.year, month, this.limits)
    );
  }

  @action
  changeYear(event: Event) {
    const year = Number((event.target as HTMLSelectElement).value);
    this.moveTo(
      focusInMonth(this.focused, year, this.shown.month, this.limits)
    );
  }

  @action
  selectDay(day: CalendarDay, event: MouseEvent) {
    if (!this.interactive || day.date === null || day.disabled) return;
    // the day's button keeps focus, also when the month changes under it
    this.moveTo(day.date);
    this.focusRequest++;
    if (day.date !== this.selected) this.args.onSelect?.(day.date, event);
  }

  @action
  onGridKeyDown(event: KeyboardEvent) {
    if (!this.interactive || event.altKey || event.ctrlKey || event.metaKey) {
      return;
    }
    const cell = (event.target as HTMLElement).closest<HTMLElement>(
      'td[data-date]'
    );
    if (!cell) return;
    const from = cell.dataset['date'] ?? this.focused;
    const grid = event.currentTarget as HTMLElement;
    const next = nextFocusedDate(from, event.key, {
      firstDayOfWeek: this.args.firstDayOfWeek,
      rtl: getComputedStyle(grid).direction === 'rtl',
      shiftKey: event.shiftKey,
      limits: this.limits
    });
    if (next === null) return;
    event.preventDefault();
    this.moveTo(next);
    this.focusRequest++;
  }

  <template>
    <div
      class="react-datepicker
        {{this.calendarClass}}
        {{@calendarClass}}
        {{unless this.interactive 'react-datepicker--non-interactive'}}
        {{if @disabled 'euiDatePickerCalendar--disabled'}}"
      ...attributes
    >
      <EuiButtonIcon
        class="react-datepicker__navigation react-datepicker__navigation--previous"
        aria-label={{this.previousMonthLabel}}
        title={{this.previousMonthLabel}}
        @iconType="sortLeft"
        @size="s"
        @color="text"
        @isDisabled={{not this.navigation.previous}}
        {{on "click" this.previousMonth}}
      />
      <EuiButtonIcon
        class="react-datepicker__navigation react-datepicker__navigation--next"
        aria-label={{this.nextMonthLabel}}
        title={{this.nextMonthLabel}}
        @iconType="sortRight"
        @size="s"
        @color="text"
        @isDisabled={{not this.navigation.next}}
        {{on "click" this.nextMonth}}
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
                aria-label={{this.monthLabel}}
                @value={{this.monthIndex}}
                @options={{this.monthOptions}}
                @disabled={{or @disabled @readOnly}}
                {{on "change" this.changeMonth}}
              />
            </div>
            <div
              class="react-datepicker__year-dropdown-container react-datepicker__year-dropdown-container--scroll"
            >
              <EuiSelect
                @compressed={{true}}
                @fullWidth={{true}}
                aria-label={{this.yearLabel}}
                @value={{this.shown.year}}
                @options={{this.yearOptions}}
                @disabled={{or @disabled @readOnly}}
                {{on "change" this.changeYear}}
              />
            </div>
          </div>
        </div>
        <h2
          id={{this.headingId}}
          class={{this.headingClass}}
          aria-live="polite"
        >{{this.monthYear}}</h2>
        <table
          role="grid"
          class="react-datepicker__month react-datepicker__month--accessible"
          aria-labelledby={{this.headingId}}
          {{on "keydown" this.onGridKeyDown}}
          {{this.focusDay this.focused this.focusRequest}}
        >
          <thead role="rowgroup">
            <tr role="row" class="react-datepicker__day-names">
              {{#each this.weekdays as |weekday|}}
                <th
                  role="columnheader"
                  scope="col"
                  abbr={{weekday.long}}
                  class="react-datepicker__day-name"
                ><span aria-hidden="true">{{weekday.short}}</span><span
                    class={{this.headingClass}}
                  >{{weekday.long}}</span></th>
              {{/each}}
            </tr>
          </thead>
          <tbody role="rowgroup">
            {{#each this.weeks key="@index" as |week|}}
              <tr role="row" class="react-datepicker__week">
                {{#each week key="key" as |day|}}
                  {{#if day.date}}
                    <td
                      role="gridcell"
                      class={{day.className}}
                      aria-selected={{if day.selected "true"}}
                      data-date={{day.date}}
                      {{on "click" (fn this.selectDay day)}}
                    ><button
                        type="button"
                        class="react-datepicker__day-button"
                        tabindex={{day.tabIndex}}
                        aria-label={{day.label}}
                        aria-current={{if day.today "date"}}
                        aria-disabled={{if day.disabled "true"}}
                        disabled={{not this.interactive}}
                      >{{day.number}}</button></td>
                  {{else}}
                    <td role="gridcell" class={{day.className}}></td>
                  {{/if}}
                {{/each}}
              </tr>
            {{/each}}
          </tbody>
        </table>
      </div>
    </div>
  </template>
}
