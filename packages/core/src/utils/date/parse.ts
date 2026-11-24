/**
 * Typed text and stored values for `EuiDatePicker` (DESIGN 5.3). One rule:
 * never guess. Text names exactly one value, or it is unreadable (null).
 * Limits and disabled dates are checked elsewhere (`calendar-nav.ts`,
 * `times.ts`).
 *
 * No `Date` parsing of text (it is locale-dependent) and no clock: the year
 * that two-digit years are read around is passed in.
 */
import { isoDateOf, pad } from './calendar-date.ts';
import { instantOf, realWall, wallMs } from './zone.ts';

import type { Wall } from './zone.ts';

export type DateOrder = 'dmy' | 'mdy' | 'ymd';

/** A time of day. */
export interface TimeOfDay {
  hour: number;
  minute: number;
  second: number;
}

export interface ParseDateOptions {
  /** The field's order: `3/4/2026` is 3 April with `dmy`, 4 March with `mdy`. */
  order: DateOrder;
  /** This year, around which two-digit years are read. */
  year: number;
}

export interface ParseDateTimeOptions extends ParseDateOptions {
  /** The field's zone, already normalized (`normalizeTimeZone`). */
  zone: string;
  /** Keep typed seconds. Without, a typed time has zero seconds. */
  seconds?: boolean;
}

/**
 * The year a two-digit year names: the one in the hundred years from
 * `year - 50` to `year + 49` (in 2026: 1976 to 2075).
 */
export function resolveTwoDigitYear(twoDigits: number, year: number): number {
  const base = year - 50;
  return base + ((((twoDigits - base) % 100) + 100) % 100);
}

function yearOf(digits: string, year: number): number {
  return digits.length === 2
    ? resolveTwoDigitYear(Number(digits), year)
    : Number(digits);
}

// ISO-like, year first: always accepted
const YEAR_FIRST = /^(\d{4})([/-])(\d{1,2})\2(\d{1,2})$/;
// in the field's order, the same separator twice; years of two or four digits
const DAY_OR_MONTH_FIRST = /^(\d{1,2})([/.-])(\d{1,2})\2(\d{2}|\d{4})$/;
const YMD = /^(\d{2}|\d{4})([/.-])(\d{1,2})\2(\d{1,2})$/;

/**
 * A typed date as `YYYY-MM-DD`, or null. Accepts `YYYY-MM-DD`,
 * `YYYY/MM/DD`, and `D/M/YYYY` in the field's order with `/`, `.` or `-`;
 * leading zeros optional, two-digit years read around `options.year`.
 * Impossible dates (`31/02/2026`, month 13), partial dates (`24/11`) and
 * three- or five-digit years are null.
 */
export function parseDateText(
  text: string,
  options: ParseDateOptions
): string | null {
  const trimmed = text.trim();
  let match = YEAR_FIRST.exec(trimmed);
  if (match) {
    return isoDateOf(Number(match[1]), Number(match[3]), Number(match[4]));
  }
  if (options.order === 'ymd') {
    match = YMD.exec(trimmed);
    if (!match) return null;
    return isoDateOf(
      yearOf(match[1]!, options.year),
      Number(match[3]),
      Number(match[4])
    );
  }
  match = DAY_OR_MONTH_FIRST.exec(trimmed);
  if (!match) return null;
  const a = Number(match[1]);
  const b = Number(match[3]);
  const y = yearOf(match[4]!, options.year);
  return options.order === 'dmy' ? isoDateOf(y, b, a) : isoDateOf(y, a, b);
}

const TIME =
  /^(\d{1,2})(?:[:.](\d{2})(?:[:.](\d{2}))?)?\s*(am|pm|a\.m\.|p\.m\.|a|p)?$/i;

/**
 * A typed time, or null: `H:mm`, `H:mm:ss`, `H.mm`, optionally with `am`,
 * `pm`, `a.m.`, `p.m.`, `a` or `p`; and `3 pm`. `15` alone is null; with a
 * meridiem the hour is 1 to 12; hour 24 is null.
 */
export function parseTimeText(text: string): TimeOfDay | null {
  const match = TIME.exec(text.trim());
  if (!match) return null;
  const meridiem = match[4]?.toLowerCase().replace(/\./g, '');
  // "15:30" needs its minutes; "3 pm" does not
  if (match[2] === undefined && !meridiem) return null;
  let hour = Number(match[1]);
  const minute = Number(match[2] ?? 0);
  const second = Number(match[3] ?? 0);
  if (meridiem) {
    if (hour < 1 || hour > 12) return null;
    hour = (hour % 12) + (meridiem.startsWith('p') ? 12 : 0);
  }
  if (hour > 23 || minute > 59 || second > 59) return null;
  return { hour, minute, second };
}

const ISO_INSTANT =
  /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,3})\d*)?)?\s*(Z|[+-]\d{2}(?::?\d{2})?)?$/i;

function isoWall(match: RegExpExecArray): Wall | null {
  const wall: Wall = {
    y: Number(match[1]),
    m: Number(match[2]),
    d: Number(match[3]),
    h: Number(match[4]),
    mi: Number(match[5]),
    s: Number(match[6] ?? 0),
    ms: match[7] ? Number(match[7].padEnd(3, '0')) : 0
  };
  return wall.y >= 1 && realWall(wall) ? wall : null;
}

/** The offset of a designator (`Z`, `+02:00`, `-0530`, `+02`) in ms, or null. */
function offsetOf(designator: string): number | null {
  if (designator.toUpperCase() === 'Z') return 0;
  const digits = designator.replace(':', '');
  const sign = digits.startsWith('-') ? -1 : 1;
  const hours = Number(digits.slice(1, 3));
  const minutes = Number(digits.slice(3, 5) || '0');
  if (hours > 23 || minutes > 59) return null;
  return sign * (hours * 60 + minutes) * 60_000;
}

/**
 * An ISO instant with `Z` or an offset (`2026-11-24T15:30:00.000Z`,
 * `…T17:30+02:00`), in ms; null for anything else. This reads `@value` in
 * date-and-time mode and typed instants.
 */
export function parseInstant(value: unknown): number | null {
  if (typeof value !== 'string') return null;
  const match = ISO_INSTANT.exec(value.trim());
  if (!match?.[8]) return null;
  const wall = isoWall(match);
  const offset = offsetOf(match[8]);
  if (!wall || offset === null) return null;
  return wallMs(wall) - offset;
}

/** An instant as stored: the UTC ISO string. */
export function instantString(ms: number): string {
  return new Date(ms).toISOString();
}

/** A stored instant normalized to `…Z`, or null when the value is not one. */
export function validInstant(value: unknown): string | null {
  const ms = parseInstant(value);
  return ms === null ? null : instantString(ms);
}

const TIME_VALUE = /^(\d{2}):(\d{2})(?::(\d{2}))?$/;

/** `@value` in time mode, `HH:mm` or `HH:mm:ss`; null for anything else. */
export function parseTimeValue(value: unknown): TimeOfDay | null {
  if (typeof value !== 'string') return null;
  const match = TIME_VALUE.exec(value);
  if (!match) return null;
  const time = {
    hour: Number(match[1]),
    minute: Number(match[2]),
    second: Number(match[3] ?? 0)
  };
  return time.hour > 23 || time.minute > 59 || time.second > 59 ? null : time;
}

/** A time of day as stored: `HH:mm`, or `HH:mm:ss` with seconds. */
export function timeValueOf(time: TimeOfDay, seconds = false): string {
  const base = `${pad(time.hour)}:${pad(time.minute)}`;
  return seconds ? `${base}:${pad(time.second)}` : base;
}

/** Compare two times of day: -1, 0 or 1. */
export function compareTimes(a: TimeOfDay, b: TimeOfDay): -1 | 0 | 1 {
  const x = a.hour * 3600 + a.minute * 60 + a.second;
  const y = b.hour * 3600 + b.minute * 60 + b.second;
  return x < y ? -1 : x > y ? 1 : 0;
}

const DATE_THEN_TIME = /^([^\s,]+),?\s+(.+)$/;

/**
 * A typed wall clock (no zone), or null: a date (as `parseDateText`), then
 * a space or `, `, then a time (as `parseTimeText`); a date alone is
 * midnight. An ISO string without a designator is a wall clock too.
 */
export function parseWallText(
  text: string,
  options: ParseDateOptions
): Wall | null {
  const trimmed = text.trim();
  const iso = ISO_INSTANT.exec(trimmed);
  if (iso) return iso[8] ? null : isoWall(iso);
  let dateText = trimmed;
  let time: TimeOfDay = { hour: 0, minute: 0, second: 0 };
  const split = DATE_THEN_TIME.exec(trimmed);
  if (split) {
    dateText = split[1]!;
    const typed = parseTimeText(split[2]!);
    if (!typed) return null;
    time = typed;
  }
  const day = parseDateText(dateText, options);
  if (!day) return null;
  const [y, m, d] = day.split('-').map(Number) as [number, number, number];
  return { y, m, d, h: time.hour, mi: time.minute, s: time.second, ms: 0 };
}

/**
 * A typed date and time as an instant in ms, or null. An ISO string with
 * `Z` or an offset is that instant (seconds and ms kept). Anything else is
 * a wall clock in the field's zone (`parseWallText`), resolved by the DST
 * rules of `instantOf`, to minutes (or seconds with `options.seconds`).
 */
export function parseDateTimeText(
  text: string,
  options: ParseDateTimeOptions
): number | null {
  const instant = parseInstant(text);
  if (instant !== null) return instant;
  const wall = parseWallText(text, options);
  if (!wall) return null;
  wall.ms = 0;
  if (!options.seconds) wall.s = 0;
  const ms = instantOf(wall, options.zone);
  return Number.isFinite(ms) ? ms : null;
}
