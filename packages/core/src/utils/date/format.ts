/**
 * Display text and locale for `EuiDatePicker` (DESIGN 5.3, 5.4). The text
 * in the input is fixed and numeric, so it always parses back
 * (`parse.ts`). Names come from `Intl`, formatted in UTC on UTC dates, so
 * the machine's zone never moves a day. `Intl` formatters are made lazily
 * and cached.
 */
import { pad, utcMidnight } from './calendar-date.ts';
import { dayOfWall, wallAt } from './zone.ts';

import type { Weekday } from './calendar-date.ts';
import type { DateOrder, TimeOfDay } from './parse.ts';

export interface TimeDisplayOptions {
  /** `h:mm am` instead of `HH:mm`. */
  hour12?: boolean;
  /** Show `:ss`. */
  seconds?: boolean;
}

export interface DateTimeDisplayOptions extends TimeDisplayOptions {
  order: DateOrder;
  /** The field's zone, already normalized (`normalizeTimeZone`). */
  zone: string;
}

/** A `YYYY-MM-DD` date as shown: `DD/MM/YYYY`, `MM/DD/YYYY` or `YYYY-MM-DD`. */
export function formatDate(iso: string, order: DateOrder): string {
  const [y, m, d] = iso.split('-');
  if (order === 'ymd') return `${y}-${m}-${d}`;
  return order === 'dmy' ? `${d}/${m}/${y}` : `${m}/${d}/${y}`;
}

/** A time of day as shown: `HH:mm` or `h:mm am`, with `:ss` when asked. */
export function formatTime(
  time: TimeOfDay,
  options: TimeDisplayOptions = {}
): string {
  const seconds = options.seconds ? `:${pad(time.second)}` : '';
  if (options.hour12) {
    const hour = time.hour % 12 || 12;
    return `${hour}:${pad(time.minute)}${seconds} ${time.hour < 12 ? 'am' : 'pm'}`;
  }
  return `${pad(time.hour)}:${pad(time.minute)}${seconds}`;
}

/** An instant as shown in a zone: the date, a space, the time. */
export function formatDateTime(
  ms: number,
  options: DateTimeDisplayOptions
): string {
  const wall = wallAt(ms, options.zone);
  const time = { hour: wall.h, minute: wall.mi, second: wall.s };
  return `${formatDate(dayOfWall(wall), options.order)} ${formatTime(time, options)}`;
}

/** Letters for the placeholder, from i18n tokens; English by default. */
export interface PlaceholderLetters {
  day: string;
  month: string;
  year: string;
}

/** The display format spelled out: `DD/MM/YYYY`, `MM/DD/YYYY` or `YYYY-MM-DD`. */
export function datePlaceholder(
  order: DateOrder,
  letters: PlaceholderLetters = { day: 'D', month: 'M', year: 'Y' }
): string {
  const dd = letters.day.repeat(2);
  const mm = letters.month.repeat(2);
  const yyyy = letters.year.repeat(4);
  if (order === 'ymd') return `${yyyy}-${mm}-${dd}`;
  return order === 'dmy' ? `${dd}/${mm}/${yyyy}` : `${mm}/${dd}/${yyyy}`;
}

/** Letters for the time placeholder, from i18n tokens; English by default. */
export interface TimePlaceholderLetters {
  hour: string;
  minute: string;
  second: string;
  meridiem: string;
}

/** The time display format spelled out: `HH:mm`, `HH:mm:ss`, or `hh:mm am` with a 12-hour clock. */
export function timePlaceholder(
  options: TimeDisplayOptions = {},
  letters: TimePlaceholderLetters = {
    hour: 'H',
    minute: 'm',
    second: 's',
    meridiem: 'am'
  }
): string {
  const hour = options.hour12
    ? letters.hour.toLowerCase().repeat(2)
    : letters.hour.repeat(2);
  const seconds = options.seconds ? `:${letters.second.repeat(2)}` : '';
  const time = `${hour}:${letters.minute.repeat(2)}${seconds}`;
  return options.hour12 ? `${time} ${letters.meridiem}` : time;
}

/* Locale */

function canonical(tag: unknown): string | undefined {
  if (typeof tag !== 'string' || tag.trim() === '') return undefined;
  try {
    return Intl.getCanonicalLocales(tag)[0];
  } catch {
    return undefined;
  }
}

/**
 * The locale to use (DESIGN 5.4): the argument, else the document's `lang`,
 * else the browser's language, else `en-US`. A tag `Intl` rejects is
 * skipped. Safe without `document` or `navigator` (server rendering).
 */
export function resolveLocale(locale?: string | null): string {
  return (
    canonical(locale) ??
    canonical(
      typeof document === 'undefined'
        ? undefined
        : document.documentElement?.lang
    ) ??
    canonical(
      typeof navigator === 'undefined' ? undefined : navigator.language
    ) ??
    'en-US'
  );
}

const formatters = new Map<string, Intl.DateTimeFormat>();

function formatter(
  locale: string,
  options: Intl.DateTimeFormatOptions
): Intl.DateTimeFormat {
  const key = `${locale}|${JSON.stringify(options)}`;
  let cached = formatters.get(key);
  if (!cached) {
    cached = new Intl.DateTimeFormat(locale, { ...options, timeZone: 'UTC' });
    formatters.set(key, cached);
  }
  return cached;
}

/** The locale's order of day, month and year, from `formatToParts`. */
export function dateOrderOf(locale: string): DateOrder {
  const parts = formatter(locale, {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  })
    .formatToParts(utcMidnight(2026, 11, 24))
    .map((part) => part.type);
  const y = parts.indexOf('year');
  const m = parts.indexOf('month');
  const d = parts.indexOf('day');
  if (y < m && y < d) return 'ymd';
  return m < d ? 'mdy' : 'dmy';
}

/** Whether the locale uses a 12-hour clock, from its `hourCycle`. */
export function hour12Of(locale: string): boolean {
  const options = new Intl.DateTimeFormat(locale, {
    hour: 'numeric'
  }).resolvedOptions();
  if (options.hourCycle) {
    return options.hourCycle === 'h11' || options.hourCycle === 'h12';
  }
  return options.hour12 ?? false;
}

interface WeekInfo {
  firstDay?: number;
}

/**
 * The first day of the week from an `Intl.Locale`: `getWeekInfo()`, else
 * the older `weekInfo` accessor, else Monday. `Intl` counts 1 (Monday) to
 * 7 (Sunday); the result is 0 (Sunday) to 6.
 */
export function firstDayFromLocale(locale: object): Weekday {
  const withInfo = locale as {
    getWeekInfo?: () => WeekInfo;
    weekInfo?: WeekInfo;
  };
  let info: WeekInfo | undefined;
  try {
    info =
      typeof withInfo.getWeekInfo === 'function'
        ? withInfo.getWeekInfo()
        : withInfo.weekInfo;
  } catch {
    info = undefined;
  }
  const day = info?.firstDay;
  if (typeof day !== 'number' || day < 1 || day > 7) return 1;
  return (day % 7) as Weekday;
}

/** The locale's first day of the week, 0 (Sunday) to 6; Monday when the engine does not say. */
export function firstDayOfWeekOf(locale: string): Weekday {
  try {
    return firstDayFromLocale(new Intl.Locale(locale));
  } catch {
    return 1;
  }
}

export interface LocaleDefaults {
  locale: string;
  dateOrder: DateOrder;
  hour12: boolean;
  firstDayOfWeek: Weekday;
}

/** The defaults the arguments override: `@dateOrder`, `@hour12`, `@firstDayOfWeek`. */
export function localeDefaults(locale?: string | null): LocaleDefaults {
  const resolved = resolveLocale(locale);
  return {
    locale: resolved,
    dateOrder: dateOrderOf(resolved),
    hour12: hour12Of(resolved),
    firstDayOfWeek: firstDayOfWeekOf(resolved)
  };
}

/* Names */

function dateOf(iso: string): number {
  const [y, m, d] = iso.split('-').map(Number) as [number, number, number];
  return utcMidnight(y, m, d);
}

/** The twelve month names, January first, standalone (as in a select). */
export function monthNames(
  locale: string,
  width: 'long' | 'short' = 'long'
): string[] {
  const format = formatter(locale, { month: width });
  return Array.from({ length: 12 }, (_, i) =>
    format.format(utcMidnight(2026, i + 1, 1))
  );
}

/** The seven weekday names, starting at `firstDayOfWeek`. */
export function weekdayNames(
  locale: string,
  width: 'long' | 'short' | 'narrow',
  firstDayOfWeek: Weekday = 0
): string[] {
  const format = formatter(locale, { weekday: width });
  // 2026-11-22 is a Sunday
  return Array.from({ length: 7 }, (_, i) =>
    format.format(utcMidnight(2026, 11, 22 + ((firstDayOfWeek + i) % 7)))
  );
}

/** A day's accessible name: "Tuesday, November 24, 2026" (`dateStyle: 'full'`). */
export function fullDateLabel(iso: string, locale: string): string {
  return formatter(locale, { dateStyle: 'full' }).format(dateOf(iso));
}

/** A month's name with its year: "November 2026". */
export function monthYearLabel(
  year: number,
  month: number,
  locale: string
): string {
  return formatter(locale, { month: 'long', year: 'numeric' }).format(
    utcMidnight(year, month, 1)
  );
}
