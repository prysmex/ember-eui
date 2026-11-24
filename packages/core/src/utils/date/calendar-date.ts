/**
 * Calendar dates for `EuiDatePicker` (DESIGN 5.1): a date is the string
 * `YYYY-MM-DD`, years 0001 to 9999. A date never becomes a `Date` through
 * `new Date(string)` or the local getters: all math is on year, month and
 * day integers, through UTC, where there is no DST. Comparison is string
 * comparison.
 *
 * Plain TypeScript, no Ember, no moment, no top-level side effects.
 */

export interface CalendarDate {
  year: number;
  /** 1 to 12 */
  month: number;
  day: number;
}

/** 0 (Sunday) to 6 (Saturday), as `Date.prototype.getUTCDay`. */
export type Weekday = 0 | 1 | 2 | 3 | 4 | 5 | 6;

export const MIN_YEAR = 1;
export const MAX_YEAR = 9999;

const DAY_MS = 86_400_000;
const ISO_DATE = /^(\d{4})-(\d{2})-(\d{2})$/;

export function pad(n: number, width = 2): string {
  return String(n).padStart(width, '0');
}

/** The UTC midnight of y/m/d in ms. Any year (`Date.UTC` maps 0 to 99 to 19xx; this does not). Month and day may overflow. */
export function utcMidnight(year: number, month: number, day: number): number {
  const date = new Date(0);
  date.setUTCFullYear(year, month - 1, day);
  return date.getTime();
}

function fromUtc(ms: number): CalendarDate {
  const date = new Date(ms);
  return {
    year: date.getUTCFullYear(),
    month: date.getUTCMonth() + 1,
    day: date.getUTCDate()
  };
}

export function isLeapYear(year: number): boolean {
  return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
}

export function daysInMonth(year: number, month: number): number {
  if (month === 2) return isLeapYear(year) ? 29 : 28;
  return [4, 6, 9, 11].includes(month) ? 30 : 31;
}

/** Whether y/m/d is a real date in the supported years. No rollover: 31 February is not one. */
export function isRealDate(year: number, month: number, day: number): boolean {
  return (
    Number.isInteger(year) &&
    Number.isInteger(month) &&
    Number.isInteger(day) &&
    year >= MIN_YEAR &&
    year <= MAX_YEAR &&
    month >= 1 &&
    month <= 12 &&
    day >= 1 &&
    day <= daysInMonth(year, month)
  );
}

/** `YYYY-MM-DD` when y/m/d is a real date, else null. */
export function isoDateOf(
  year: number,
  month: number,
  day: number
): string | null {
  return isRealDate(year, month, day)
    ? `${pad(year, 4)}-${pad(month)}-${pad(day)}`
    : null;
}

/** The parts of a strict `YYYY-MM-DD` string that names a real date, else null. */
export function parseIsoDate(value: unknown): CalendarDate | null {
  if (typeof value !== 'string') return null;
  const match = ISO_DATE.exec(value);
  if (!match) return null;
  const date = {
    year: Number(match[1]),
    month: Number(match[2]),
    day: Number(match[3])
  };
  return isRealDate(date.year, date.month, date.day) ? date : null;
}

/** The value when it is a strict `YYYY-MM-DD` real date, else null. */
export function validIsoDate(value: unknown): string | null {
  return parseIsoDate(value) ? (value as string) : null;
}

function isoOfParts(date: CalendarDate): string | null {
  return isoDateOf(date.year, date.month, date.day);
}

function partsOf(iso: string): CalendarDate {
  const date = parseIsoDate(iso);
  if (!date) throw new TypeError(`Not a YYYY-MM-DD date: ${String(iso)}`);
  return date;
}

/** -1, 0 or 1. Valid dates compare as strings. */
export function compareDates(a: string, b: string): -1 | 0 | 1 {
  return a < b ? -1 : a > b ? 1 : 0;
}

export function minDate(a: string, b: string): string {
  return a <= b ? a : b;
}

export function maxDate(a: string, b: string): string {
  return a >= b ? a : b;
}

/** The date n days later (n may be negative); null outside 0001 to 9999. */
export function addDays(iso: string, n: number): string | null {
  const { year, month, day } = partsOf(iso);
  return isoOfParts(fromUtc(utcMidnight(year, month, day) + n * DAY_MS));
}

/** The year and month n months later. */
export function addMonthsTo(
  year: number,
  month: number,
  n: number
): { year: number; month: number } {
  const index = year * 12 + (month - 1) + n;
  return {
    year: Math.floor(index / 12),
    month: (((index % 12) + 12) % 12) + 1
  };
}

/** The date in another month, the day clamped to its length; null outside the supported years. */
export function withYearMonth(
  iso: string,
  year: number,
  month: number
): string | null {
  const { day } = partsOf(iso);
  if (year < MIN_YEAR || year > MAX_YEAR || month < 1 || month > 12) {
    return null;
  }
  return isoDateOf(year, month, Math.min(day, daysInMonth(year, month)));
}

/** n months later, the day clamped: 31 January plus one month is 28 or 29 February. */
export function addMonths(iso: string, n: number): string | null {
  const { year, month } = partsOf(iso);
  const next = addMonthsTo(year, month, n);
  return withYearMonth(iso, next.year, next.month);
}

/** n years later, the day clamped: 29 February 2028 plus one year is 28 February 2029. */
export function addYears(iso: string, n: number): string | null {
  return addMonths(iso, n * 12);
}

/** Days from a to b (b minus a). */
export function daysBetween(a: string, b: string): number {
  const x = partsOf(a);
  const y = partsOf(b);
  return Math.round(
    (utcMidnight(y.year, y.month, y.day) -
      utcMidnight(x.year, x.month, x.day)) /
      DAY_MS
  );
}

export function weekdayOf(iso: string): Weekday {
  const { year, month, day } = partsOf(iso);
  return new Date(utcMidnight(year, month, day)).getUTCDay() as Weekday;
}

/** The first day of the week holding the date; null before 0001-01-01. */
export function startOfWeek(
  iso: string,
  firstDayOfWeek: Weekday
): string | null {
  return addDays(iso, -((weekdayOf(iso) - firstDayOfWeek + 7) % 7));
}

/** The last day of the week holding the date; null after 9999-12-31. */
export function endOfWeek(iso: string, firstDayOfWeek: Weekday): string | null {
  return addDays(iso, 6 - ((weekdayOf(iso) - firstDayOfWeek + 7) % 7));
}

/** The first and last day of a month. */
export function monthBounds(
  year: number,
  month: number
): { first: string; last: string } {
  return {
    first: `${pad(year, 4)}-${pad(month)}-01`,
    last: `${pad(year, 4)}-${pad(month)}-${pad(daysInMonth(year, month))}`
  };
}

/** Whether the date is in the given month. */
export function inMonth(iso: string, year: number, month: number): boolean {
  return iso.startsWith(`${pad(year, 4)}-${pad(month)}-`);
}

/**
 * The weeks shown for a month: each week is seven dates from
 * `firstDayOfWeek`, from the week holding the 1st to the week holding the
 * last day (4 to 6 weeks, as upstream without `fixedHeight`). Days of the
 * neighbouring months are included; a day before 0001-01-01 or after
 * 9999-12-31 is null.
 */
export function weeksOfMonth(
  year: number,
  month: number,
  firstDayOfWeek: Weekday
): (string | null)[][] {
  const { first } = monthBounds(year, month);
  if (!parseIsoDate(first)) {
    throw new RangeError(`Not a supported month: ${year}-${month}`);
  }
  const lead = (weekdayOf(first) - firstDayOfWeek + 7) % 7;
  const span = lead + daysInMonth(year, month);
  const weekCount = Math.ceil(span / 7);
  const weeks: (string | null)[][] = [];
  const start = utcMidnight(year, month, 1) - lead * DAY_MS;
  for (let w = 0; w < weekCount; w++) {
    const week: (string | null)[] = [];
    for (let d = 0; d < 7; d++) {
      week.push(isoOfParts(fromUtc(start + (w * 7 + d) * DAY_MS)));
    }
    weeks.push(week);
  }
  return weeks;
}
