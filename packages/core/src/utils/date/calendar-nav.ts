/**
 * The calendar's rules for `EuiDatePicker` (DESIGN 2.3, 5.2, 7.1 to 7.3):
 * the limits (`@minDate`, `@maxDate`, `@excludeDates`, `@includeDates`,
 * `@filterDate`), the disabled test, the next focused day for a key, month
 * navigation, the year list and the roving tab stop.
 *
 * Dates are `YYYY-MM-DD`. `@minDate` and `@maxDate` may also be instants
 * (with `@showTimeSelect`); for days they count by their calendar day in
 * the field's zone, so a day is disabled only when none of its wall hours
 * can fall inside the limits.
 */
import {
  addDays,
  addMonths,
  addMonthsTo,
  addYears,
  daysInMonth,
  endOfWeek,
  inMonth,
  isoDateOf,
  MAX_YEAR,
  MIN_YEAR,
  monthBounds,
  parseIsoDate,
  startOfWeek,
  validIsoDate,
  withYearMonth
} from './calendar-date.ts';
import { parseInstant } from './parse.ts';
import { dayAt, startOfDayIn } from './zone.ts';

import type { Weekday } from './calendar-date.ts';

const FIRST_DAY = '0001-01-01';
const LAST_DAY = '9999-12-31';

export interface DateLimits {
  /** `YYYY-MM-DD`, or an instant with `@showTimeSelect`. */
  minDate?: string | null;
  maxDate?: string | null;
  excludeDates?: readonly string[] | null;
  /** When given, only these days are enabled. */
  includeDates?: readonly string[] | null;
  /** Called with `YYYY-MM-DD`; false disables the day. */
  filterDate?: ((date: string) => boolean) | null;
}

/** The limits as days, ready for the disabled test. Make once per render, not per day. */
export interface DayLimits {
  min: string | null;
  max: string | null;
  excluded: ReadonlySet<string>;
  included: ReadonlySet<string> | null;
  filter: ((date: string) => boolean) | null;
}

/** Why a day (or a time) cannot be chosen; null when it can. The reasons of `@onInputError`. */
export type LimitProblem = 'min' | 'max' | 'disabled';

/**
 * A limit as a day: a date is itself; an instant is its calendar day in
 * the zone; anything else is null (no limit). `zone` is normalized.
 */
export function limitDay(
  limit: string | null | undefined,
  zone = 'utc'
): string | null {
  if (validIsoDate(limit)) return limit as string;
  const ms = parseInstant(limit);
  return ms === null ? null : dayAt(ms, zone);
}

/**
 * A limit as an instant in ms: an instant is itself; a date is its first
 * instant in the zone (for a minimum) or the last millisecond of its day
 * (for a maximum); anything else is null.
 */
export function limitInstant(
  limit: string | null | undefined,
  zone: string,
  edge: 'min' | 'max'
): number | null {
  const ms = parseInstant(limit);
  if (ms !== null) return ms;
  const day = validIsoDate(limit);
  if (!day) return null;
  if (edge === 'min') return startOfDayIn(day, zone);
  const next = addDays(day, 1);
  return next ? startOfDayIn(next, zone) - 1 : Infinity;
}

/** Whether a limit is present but neither a date nor an instant (for a development warning). */
export function isUnreadableLimit(limit: unknown): boolean {
  return (
    limit != null &&
    limit !== '' &&
    !validIsoDate(limit) &&
    parseInstant(limit) === null
  );
}

function dateSet(dates: readonly string[] | null | undefined): Set<string> {
  const set = new Set<string>();
  for (const date of dates ?? []) {
    const day = validIsoDate(date);
    if (day) set.add(day);
  }
  return set;
}

/** Resolve the limits once: days in the zone, sets for the lists. */
export function dayLimits(limits: DateLimits = {}, zone = 'utc'): DayLimits {
  return {
    min: limitDay(limits.minDate, zone),
    max: limitDay(limits.maxDate, zone),
    excluded: dateSet(limits.excludeDates),
    included: limits.includeDates ? dateSet(limits.includeDates) : null,
    filter: limits.filterDate ?? null
  };
}

/** Whether `@minDate` is after `@maxDate`: every day is disabled (9 #18, a development warning). */
export function limitsConflict(limits: DayLimits): boolean {
  return limits.min !== null && limits.max !== null && limits.min > limits.max;
}

/**
 * Why a day cannot be chosen, or null (upstream `isDayDisabled`,
 * `date_utils.js:331-343`): before the minimum, after the maximum, in
 * `@excludeDates`, not in `@includeDates`, or refused by `@filterDate`.
 */
export function dayProblem(
  date: string,
  limits: DayLimits
): LimitProblem | null {
  if (limits.min !== null && date < limits.min) return 'min';
  if (limits.max !== null && date > limits.max) return 'max';
  if (limits.excluded.has(date)) return 'disabled';
  if (limits.included && !limits.included.has(date)) return 'disabled';
  if (limits.filter && !limits.filter(date)) return 'disabled';
  return null;
}

export function isDayDisabled(date: string, limits: DayLimits): boolean {
  return dayProblem(date, limits) !== null;
}

/** The date moved inside `[min, max]` and the supported years. With min after max, min wins. */
export function clampDate(
  date: string,
  limits: Pick<DayLimits, 'min' | 'max'>
): string {
  let clamped = date;
  if (limits.max !== null && clamped > limits.max) clamped = limits.max;
  if (limits.min !== null && clamped < limits.min) clamped = limits.min;
  return clamped;
}

export type NavigationKey =
  | 'ArrowLeft'
  | 'ArrowRight'
  | 'ArrowUp'
  | 'ArrowDown'
  | 'Home'
  | 'End'
  | 'PageUp'
  | 'PageDown';

export interface NavigationOptions {
  firstDayOfWeek: Weekday;
  /** The direction is right to left: ArrowLeft and ArrowRight swap. */
  rtl?: boolean;
  /** With PageUp and PageDown: a year instead of a month. */
  shiftKey?: boolean;
  limits?: Pick<DayLimits, 'min' | 'max'>;
}

/**
 * The day focus moves to for a key in the grid (DESIGN 7.2), or null when
 * the key does not move it. Arrows move a day or a week, Home and End to
 * the week's first and last day, PageUp and PageDown a month (with Shift a
 * year), the day clamped. Moving onto a disabled day is allowed; moving
 * past `@minDate` or `@maxDate` stops at the limit.
 */
export function nextFocusedDate(
  focused: string,
  key: string,
  options: NavigationOptions
): string | null {
  const forward = options.rtl ? -1 : 1;
  let next: string | null;
  let fallback: string;
  switch (key) {
    case 'ArrowLeft':
      next = addDays(focused, -forward);
      fallback = forward === 1 ? FIRST_DAY : LAST_DAY;
      break;
    case 'ArrowRight':
      next = addDays(focused, forward);
      fallback = forward === 1 ? LAST_DAY : FIRST_DAY;
      break;
    case 'ArrowUp':
      next = addDays(focused, -7);
      fallback = FIRST_DAY;
      break;
    case 'ArrowDown':
      next = addDays(focused, 7);
      fallback = LAST_DAY;
      break;
    case 'Home':
      next = startOfWeek(focused, options.firstDayOfWeek);
      fallback = FIRST_DAY;
      break;
    case 'End':
      next = endOfWeek(focused, options.firstDayOfWeek);
      fallback = LAST_DAY;
      break;
    case 'PageUp':
      next = options.shiftKey ? addYears(focused, -1) : addMonths(focused, -1);
      fallback = FIRST_DAY;
      break;
    case 'PageDown':
      next = options.shiftKey ? addYears(focused, 1) : addMonths(focused, 1);
      fallback = LAST_DAY;
      break;
    default:
      return null;
  }
  return clampDate(next ?? fallback, options.limits ?? NO_LIMITS);
}

const NO_LIMITS = { min: null, max: null };

/**
 * Whether the month before and the month after the shown one have a day
 * inside the limits (DESIGN 7.3): the navigation buttons are disabled when
 * not. Months outside 0001 to 9999 never do.
 */
export function monthNavigation(
  year: number,
  month: number,
  limits: Pick<DayLimits, 'min' | 'max'>
): { previous: boolean; next: boolean } {
  const reachable = (n: number) => {
    const target = addMonthsTo(year, month, n);
    if (target.year < MIN_YEAR || target.year > MAX_YEAR) return false;
    const { first, last } = monthBounds(target.year, target.month);
    return (
      (limits.min === null || last >= limits.min) &&
      (limits.max === null || first <= limits.max)
    );
  };
  return { previous: reachable(-1), next: reachable(1) };
}

/**
 * The years of the year select (DESIGN 7.3): from `@minDate`'s year to
 * `@maxDate`'s; a missing limit is 100 years back or 20 forward from the
 * shown year. Always includes the shown year; within 0001 to 9999.
 */
export function yearRange(
  shownYear: number,
  limits: Pick<DayLimits, 'min' | 'max'>
): { from: number; to: number } {
  let from = limits.min ? Number(limits.min.slice(0, 4)) : shownYear - 100;
  let to = limits.max ? Number(limits.max.slice(0, 4)) : shownYear + 20;
  from = Math.max(MIN_YEAR, Math.min(from, shownYear));
  to = Math.min(MAX_YEAR, Math.max(to, shownYear));
  return { from, to };
}

/**
 * The focused day after the month or year select changes the shown month
 * (9 #31): the same day of the month, clamped to its length, then to the
 * limits. The value does not change.
 */
export function focusInMonth(
  focused: string,
  year: number,
  month: number,
  limits: Pick<DayLimits, 'min' | 'max'>
): string {
  const moved =
    withYearMonth(focused, year, month) ??
    (isoDateOf(year, month, 1) as string);
  return clampDate(moved, limits);
}

/**
 * The day that holds the grid's one tab stop (DESIGN 7.1): the focused
 * day, else the selected day, else today, else the first enabled day of
 * the month, else its first day. Only days of the shown month count.
 */
export function tabStopDate(options: {
  year: number;
  month: number;
  focused?: string | null;
  selected?: string | null;
  today?: string | null;
  limits?: DayLimits;
}): string {
  const { year, month, limits } = options;
  for (const candidate of [options.focused, options.selected, options.today]) {
    if (
      candidate &&
      parseIsoDate(candidate) &&
      inMonth(candidate, year, month)
    ) {
      return candidate;
    }
  }
  const { first } = monthBounds(year, month);
  if (limits) {
    for (let day = 1; day <= daysInMonth(year, month); day++) {
      const date = isoDateOf(year, month, day)!;
      if (!isDayDisabled(date, limits)) return date;
    }
  }
  return first;
}

/**
 * The day the calendar opens on (DESIGN 2.2, 5.3): the value's day, else
 * `@openToDate`, else today. An unreadable value or `@openToDate` is
 * skipped (9 #1).
 */
export function openingDate(
  selected: string | null | undefined,
  openToDate: string | null | undefined,
  today: string
): string {
  return validIsoDate(selected) ?? validIsoDate(openToDate) ?? today;
}
