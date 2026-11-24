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
import { timeList } from '../../utils/date/times.ts';
import { todayIn, wallAt } from '../../utils/date/zone.ts';
import EuiButtonIcon from '../eui-button-icon.gts';
import { euiScreenReaderOnlyClass } from '../eui-screen-reader-only.gts';
import EuiSelect from '../eui-select.gts';
import EuiDatePickerTimeList from './time-list.gts';

import type { Weekday } from '../../utils/date/calendar-date.ts';
import type { DayLimits } from '../../utils/date/calendar-nav.ts';
import type { TimeOfDay } from '../../utils/date/parse.ts';
import type { TimeEntry, TimeListOptions } from '../../utils/date/times.ts';
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
  /** The `@selected`, `@openToDate` and `@preview` this view was made for: it is dropped when they change (9 #29). */
  forSelected: string | null;
  forOpenTo: string | null;
  forPreview: string | null;
}

/** The time list's rules (upstream `timeIntervals`, `injectTimes`, `excludeTimes`, `minTime`, `maxTime`). */
export type CalendarTimeOptions = Pick<
  TimeListOptions,
  | 'interval'
  | 'injectTimes'
  | 'excludeTimes'
  | 'minTime'
  | 'maxTime'
  | 'seconds'
>;

export interface EuiDatePickerCalendarSignature {
  Element: HTMLDivElement;
  Args: {
    /** The selected day, `YYYY-MM-DD`. Anything else selects nothing. */
    selected?: string | null;
    /** Called with the chosen day; never with a disabled one, nor with the selected one. */
    onSelect?: (date: string, event: Event) => void;
    /** Called with every day picked (click, Enter, Space), the selected one too; never a disabled one. After `@onSelect`. */
    onPick?: (date: string, event: Event) => void;
    /**
     * A day to show instead of the selected one, e.g. typed text that reads
     * as a date: its month is shown and it holds the tab stop. Nothing is
     * selected by it.
     */
    preview?: string | null;
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
    /** The time list beside the month (upstream `showTimeSelect`). */
    showTimeSelect?: boolean;
    /** Only the time list (upstream `showTimeSelectOnly`): no month, no navigation. */
    showTimeSelectOnly?: boolean;
    /** The time list's rules. With a month, `@minDate` and `@maxDate` (instants or days) also disable times. */
    timeOptions?: CalendarTimeOptions;
    /** The value's time of day: its entry is selected. */
    selectedTime?: TimeOfDay | null;
    /** `h:mm am` in the time list. */
    hour12?: boolean;
    /**
     * Called with an entry of the time list that can be chosen, and the day
     * it belongs to: the preview, else the selected day, else the focused
     * one; null with `@showTimeSelectOnly`.
     */
    onPickTime?: (day: string | null, entry: TimeEntry, event: Event) => void;
    /** Called with the focused day after a key, a month or year change or a navigation button moved it (upstream `adjustDateOnChange`). */
    onMove?: (date: string) => void;
    /** This calendar picks a range's start: a hovered or focused day previews the range from it to `@rangeEnd` (upstream `selectsStart`). */
    selectsStart?: boolean;
    /** This calendar picks a range's end: a hovered or focused day previews the range from `@rangeStart` to it (upstream `selectsEnd`). */
    selectsEnd?: boolean;
    /** The range's first day, `YYYY-MM-DD` (upstream `startDate`). With `@rangeEnd`, the days between are highlighted. */
    rangeStart?: string | null;
    /** The range's last day, `YYYY-MM-DD` (upstream `endDate`). */
    rangeEnd?: string | null;
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
  /** The day under the mouse, and whether focus is in the grid: what the range preview runs to (upstream `selectingDate`). */
  @tracked private hovered: string | null = null;
  @tracked private gridHasFocus = false;

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

  get preview(): string | null {
    return validIsoDate(this.args.preview);
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
      view.forOpenTo === this.openTo &&
      view.forPreview === this.preview
      ? view
      : null;
  }

  /** The day the calendar opens on: `@preview`, else the selected day, else `@openToDate`, else today within the limits. */
  get opening(): string {
    return openingDate(
      this.preview ?? this.selected,
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
      focused: this.currentView?.focused ?? this.preview ?? this.openToFocus,
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
      forOpenTo: this.openTo,
      forPreview: this.preview
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

  /* Range (upstream `day.js`: `isInRange`, `isInSelectingRange`) */

  get rangeStart(): string | null {
    return validIsoDate(this.args.rangeStart);
  }

  get rangeEnd(): string | null {
    return validIsoDate(this.args.rangeEnd);
  }

  get selectsRange(): boolean {
    return Boolean(this.args.selectsStart || this.args.selectsEnd);
  }

  /** The day a pick would set, previewed: the hovered day, else the focused one while the grid has focus. */
  get selectingDate(): string | null {
    if (!this.interactive || !this.selectsRange) return null;
    return this.hovered ?? (this.gridHasFocus ? this.focused : null);
  }

  /** The previewed range, as upstream: from the selecting day to the end, or from the start to it; none when it would be reversed. */
  get selectingRange(): { from: string; to: string } | null {
    const selecting = this.selectingDate;
    if (selecting === null) return null;
    const { rangeStart, rangeEnd } = this;
    if (this.args.selectsStart && rangeEnd !== null && selecting <= rangeEnd) {
      return { from: selecting, to: rangeEnd };
    }
    if (
      this.args.selectsEnd &&
      rangeStart !== null &&
      selecting >= rangeStart
    ) {
      return { from: rangeStart, to: selecting };
    }
    return null;
  }

  /** The classes of a day for the range and its preview. */
  private rangeClasses(date: string, disabled: boolean): string[] {
    const classes: string[] = [];
    const { rangeStart, rangeEnd } = this;
    if (rangeStart !== null && rangeEnd !== null) {
      if (date === rangeStart)
        classes.push('react-datepicker__day--range-start');
      if (date === rangeEnd) classes.push('react-datepicker__day--range-end');
      if (date >= rangeStart && date <= rangeEnd) {
        classes.push('react-datepicker__day--in-range');
      }
    }
    const selecting = this.selectingRange;
    if (
      selecting &&
      !disabled &&
      date >= selecting.from &&
      date <= selecting.to
    ) {
      classes.push('react-datepicker__day--in-selecting-range');
      if (date === selecting.from) {
        classes.push('react-datepicker__day--selecting-range-start');
      }
      if (date === selecting.to) {
        classes.push('react-datepicker__day--selecting-range-end');
      }
    }
    return classes;
  }

  @action
  hoverDay(date: string | null) {
    if (this.hovered !== date) this.hovered = date;
  }

  @action
  onGridFocusIn() {
    this.gridHasFocus = true;
  }

  @action
  onGridFocusOut(event: FocusEvent) {
    const next = event.relatedTarget as Node | null;
    if (next && (event.currentTarget as HTMLElement).contains(next)) return;
    this.gridHasFocus = false;
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
        classes.push(...this.rangeClasses(date, disabled));
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
    this.moveBy(focusInMonth(this.focused, year, month, this.limits));
  }

  /** A move by the user (keys, selects, navigation): `@onMove` hears of it. */
  private moveBy(date: string) {
    this.moveTo(date);
    this.args.onMove?.(date);
  }

  @action
  changeMonth(event: Event) {
    const month = Number((event.target as HTMLSelectElement).value) + 1;
    this.moveBy(
      focusInMonth(this.focused, this.shown.year, month, this.limits)
    );
  }

  @action
  changeYear(event: Event) {
    const year = Number((event.target as HTMLSelectElement).value);
    this.moveBy(
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
    this.args.onPick?.(day.date, event);
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
    this.moveBy(next);
    this.focusRequest++;
  }

  /* Time */

  get timeOnly(): boolean {
    return Boolean(this.args.showTimeSelectOnly);
  }

  get hasTime(): boolean {
    return Boolean(this.args.showTimeSelect || this.args.showTimeSelectOnly);
  }

  /** The day the time list is for (DESIGN 5.2): the preview, else the selected day, else the focused one; none for time only. */
  get timeDay(): string | null {
    if (this.timeOnly) return null;
    return this.preview ?? this.selected ?? this.focused;
  }

  @cached
  get timeEntries(): TimeEntry[] {
    if (!this.hasTime) return [];
    const day = this.timeDay;
    return timeList({
      ...this.args.timeOptions,
      day,
      zone: this.zone,
      minDate: day ? this.args.minDate : null,
      maxDate: day ? this.args.maxDate : null
    });
  }

  /** Without a selected time, the list opens near the time now in the zone (upstream). */
  get timeReference(): TimeOfDay {
    const wall = wallAt(this.now, this.zone);
    return { hour: wall.h, minute: wall.mi, second: 0 };
  }

  @action
  pickTime(entry: TimeEntry, event: Event) {
    if (!this.interactive) return;
    this.args.onPickTime?.(this.timeDay, entry, event);
  }

  <template>
    <div
      class="react-datepicker
        {{this.calendarClass}}
        {{@calendarClass}}
        {{if this.timeOnly 'react-datepicker--time-only'}}
        {{unless this.interactive 'react-datepicker--non-interactive'}}
        {{if @disabled 'euiDatePickerCalendar--disabled'}}"
      ...attributes
    >
      {{#unless this.timeOnly}}
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
            class="react-datepicker__month react-datepicker__month--accessible
              {{if
                this.selectingRange
                'react-datepicker__month--selecting-range'
              }}"
            aria-labelledby={{this.headingId}}
            {{on "keydown" this.onGridKeyDown}}
            {{on "mouseleave" (fn this.hoverDay null)}}
            {{on "focusin" this.onGridFocusIn}}
            {{on "focusout" this.onGridFocusOut}}
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
                        {{on "mouseenter" (fn this.hoverDay day.date)}}
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
      {{/unless}}
      {{#if this.hasTime}}
        <EuiDatePickerTimeList
          @entries={{this.timeEntries}}
          @selected={{@selectedTime}}
          @reference={{this.timeReference}}
          @hour12={{@hour12}}
          @disabled={{not this.interactive}}
          @onPick={{this.pickTime}}
        />
      {{/if}}
    </div>
  </template>
}
