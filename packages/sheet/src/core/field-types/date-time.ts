/**
 * `dateTime` (V03 10.3, D9): an instant, stored as a UTC ISO string
 * (`2026-11-19T15:30:00.000Z`, what `Date.prototype.toISOString` gives) or
 * `null`, shown and typed in the field's zone. `date` is not touched.
 * No `Date` parsing of typed text (it is locale-dependent): only ISO
 * strings with a designator are read as instants.
 */
import type { DateTimeField, FieldType } from '../types.ts';

const DAY = 86_400_000;

/** A wall clock: calendar date and time, no zone. */
interface Wall {
  y: number;
  m: number;
  d: number;
  h: number;
  mi: number;
  s: number;
  ms: number;
}

function pad(n: number, width = 2): string {
  return String(n).padStart(width, '0');
}

/** The wall clock as if it were UTC, in ms (any year). */
function wallMs(wall: Wall): number {
  const date = new Date(0);
  date.setUTCFullYear(wall.y, wall.m - 1, wall.d);
  date.setUTCHours(wall.h, wall.mi, wall.s, wall.ms);
  return date.getTime();
}

/** Whether y/m/d h:mi:s is a real calendar date and time. */
function realWall(wall: Wall): boolean {
  if (wall.h > 23 || wall.mi > 59 || wall.s > 59) return false;
  const date = new Date(wallMs(wall));
  return (
    date.getUTCFullYear() === wall.y &&
    date.getUTCMonth() === wall.m - 1 &&
    date.getUTCDate() === wall.d
  );
}

const formatters = new Map<string, Intl.DateTimeFormat | null>();

/** A formatter of the zone's wall clock; null for a zone `Intl` does not know. */
function formatterOf(zone: string): Intl.DateTimeFormat | null {
  if (formatters.has(zone)) return formatters.get(zone)!;
  let formatter: Intl.DateTimeFormat | null;
  try {
    formatter = new Intl.DateTimeFormat('en-US', {
      timeZone: zone,
      hourCycle: 'h23',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  } catch {
    formatter = null;
  }
  formatters.set(zone, formatter);
  return formatter;
}

/** The field's zone: 'local', 'utc', or an IANA name (default 'local'). */
function zoneOf(field: DateTimeField): string {
  const zone = field.timeZone;
  if (!zone || zone === 'local') return 'local';
  if (zone.toLowerCase() === 'utc') return 'utc';
  return zone;
}

/** Whether the zone is one this browser knows ('local' and 'utc' always). */
export function validTimeZone(zone: string | undefined): boolean {
  if (!zone || zone === 'local' || zone.toLowerCase() === 'utc') return true;
  return formatterOf(zone) !== null;
}

/** The zone's wall clock at an instant. An unknown zone reads as UTC (`validate` reports it). */
function wallAt(ms: number, zone: string): Wall {
  const date = new Date(ms);
  if (zone === 'local') {
    return {
      y: date.getFullYear(),
      m: date.getMonth() + 1,
      d: date.getDate(),
      h: date.getHours(),
      mi: date.getMinutes(),
      s: date.getSeconds(),
      ms: date.getMilliseconds()
    };
  }
  const formatter = zone === 'utc' ? null : formatterOf(zone);
  if (!formatter) {
    return {
      y: date.getUTCFullYear(),
      m: date.getUTCMonth() + 1,
      d: date.getUTCDate(),
      h: date.getUTCHours(),
      mi: date.getUTCMinutes(),
      s: date.getUTCSeconds(),
      ms: date.getUTCMilliseconds()
    };
  }
  const parts: Record<string, number> = {};
  for (const part of formatter.formatToParts(date)) {
    if (part.type !== 'literal') parts[part.type] = Number(part.value);
  }
  return {
    // a year before 1 comes as its era's: not supported, read as is
    y: parts['year']!,
    m: parts['month']!,
    d: parts['day']!,
    h: parts['hour']! % 24,
    mi: parts['minute']!,
    s: parts['second']!,
    ms: ((ms % 1000) + 1000) % 1000
  };
}

/**
 * The instant of a wall clock in a zone. A wall clock that does not exist
 * (the spring DST gap) resolves forward, by the gap; one that exists twice
 * (the autumn overlap) resolves to the first. 'local' uses `Date`'s own
 * rules, which are the same.
 */
function instantOf(wall: Wall, zone: string): number {
  if (zone === 'local') {
    const date = new Date(0);
    date.setFullYear(wall.y, wall.m - 1, wall.d);
    date.setHours(wall.h, wall.mi, wall.s, wall.ms);
    return date.getTime();
  }
  const guess = wallMs(wall);
  if (zone === 'utc' || !formatterOf(zone)) return guess;
  // the zone's offset (wall clock minus instant) a day either side
  const offsetAt = (ms: number) => wallMs(wallAt(ms, zone)) - ms;
  const before = guess - offsetAt(guess - DAY);
  const after = guess - offsetAt(guess + DAY);
  const fits = (ms: number) => wallMs(wallAt(ms, zone)) === guess;
  const early = Math.min(before, after);
  const late = Math.max(before, after);
  if (fits(early)) return early;
  if (fits(late)) return late;
  // the gap: the offset from before it moves the clock forward
  return before;
}

/** The value as an instant in ms, or null when it is not a valid stored value. */
function msOf(value: unknown): number | null {
  if (typeof value !== 'string') return null;
  const ms = readIso(value.trim());
  return ms === undefined ? null : ms;
}

const ISO =
  /^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,3})\d*)?)?)?\s*(Z|[+-]\d{2}(?::?\d{2})?)?$/i;

/**
 * An ISO string with `Z` or an offset: that instant; `undefined` when the
 * text is not one. (Without a designator it is a wall clock: `readWall`.)
 */
function readIso(text: string): number | undefined {
  const match = ISO.exec(text);
  if (!match || !match[8] || match[4] === undefined) return undefined;
  const wall = isoWall(match);
  if (!wall) return undefined;
  const designator = match[8].toUpperCase();
  let offset = 0;
  if (designator !== 'Z') {
    const digits = designator.replace(':', '');
    const sign = digits[0] === '-' ? -1 : 1;
    const hours = Number(digits.slice(1, 3));
    const minutes = Number(digits.slice(3, 5) || '0');
    if (hours > 23 || minutes > 59) return undefined;
    offset = sign * (hours * 60 + minutes) * 60_000;
  }
  return wallMs(wall) - offset;
}

function isoWall(match: RegExpExecArray): Wall | null {
  const wall: Wall = {
    y: Number(match[1]),
    m: Number(match[2]),
    d: Number(match[3]),
    h: Number(match[4] ?? 0),
    mi: Number(match[5] ?? 0),
    s: Number(match[6] ?? 0),
    ms: match[7] ? Number(match[7].padEnd(3, '0')) : 0
  };
  return realWall(wall) ? wall : null;
}

const TYPED =
  /^(\d{1,2})([/.-])(\d{1,2})\2(\d{4})(?:,?\s+(\d{1,2})(?:[:.](\d{2}))?(?:[:.](\d{2}))?\s*(am|pm|a\.m\.|p\.m\.|a|p)?)?$/i;

/** A wall clock typed in the field's order (`D/M/YYYY H:mm[:ss] [am|pm]`), or an ISO string without a designator. */
function readWall(text: string, order: 'dmy' | 'mdy'): Wall | null {
  const iso = ISO.exec(text);
  if (iso && !iso[8]) return isoWall(iso);
  const match = TYPED.exec(text);
  if (!match) return null;
  const a = Number(match[1]);
  const b = Number(match[3]);
  let h = Number(match[5] ?? 0);
  const meridiem = match[8]?.toLowerCase().replace(/\./g, '');
  // "15:30" needs its minutes; "3 pm" does not
  if (match[5] !== undefined && match[6] === undefined && !meridiem) {
    return null;
  }
  if (meridiem) {
    if (h < 1 || h > 12) return null;
    const pm = meridiem.startsWith('p');
    h = (h % 12) + (pm ? 12 : 0);
  }
  const wall: Wall = {
    y: Number(match[4]),
    m: order === 'dmy' ? b : a,
    d: order === 'dmy' ? a : b,
    h,
    mi: Number(match[6] ?? 0),
    s: Number(match[7] ?? 0),
    ms: 0
  };
  return realWall(wall) ? wall : null;
}

/** The instant a text names in the field, as stored; null when it names none. */
function parseText(text: string, field: DateTimeField): string | null {
  const zone = zoneOf(field);
  const instant = readIso(text);
  if (instant !== undefined) return new Date(instant).toISOString();
  const wall = readWall(text, field.dateOrder ?? 'dmy');
  if (!wall) return null;
  // typed: to the field's precision (minutes, or seconds)
  wall.ms = 0;
  if (!field.seconds) wall.s = 0;
  const ms = instantOf(wall, zone);
  return Number.isFinite(ms) ? new Date(ms).toISOString() : null;
}

/** An instant in the field's zone: `DD/MM/YYYY HH:mm` (or its order, clock and seconds). */
function display(ms: number, field: DateTimeField): string {
  const wall = wallAt(ms, zoneOf(field));
  const date =
    (field.dateOrder ?? 'dmy') === 'dmy'
      ? `${pad(wall.d)}/${pad(wall.m)}/${pad(wall.y, 4)}`
      : `${pad(wall.m)}/${pad(wall.d)}/${pad(wall.y, 4)}`;
  const seconds = field.seconds ? `:${pad(wall.s)}` : '';
  if (field.hour12) {
    const h = wall.h % 12 || 12;
    return `${date} ${h}:${pad(wall.mi)}${seconds} ${wall.h < 12 ? 'am' : 'pm'}`;
  }
  return `${date} ${pad(wall.h)}:${pad(wall.mi)}${seconds}`;
}

/**
 * The value as the field's zone's wall clock, for `<input type="datetime-local">`
 * (`YYYY-MM-DDTHH:mm`, with `:ss` when the field keeps seconds); '' for no value.
 */
export function dateTimeLocalValue(
  value: unknown,
  field: DateTimeField
): string {
  const ms = msOf(value);
  if (ms === null) return '';
  const wall = wallAt(ms, zoneOf(field));
  const time = `${pad(wall.h)}:${pad(wall.mi)}${field.seconds ? `:${pad(wall.s)}` : ''}`;
  return `${pad(wall.y, 4)}-${pad(wall.m)}-${pad(wall.d)}T${time}`;
}

/** A stored value (a UTC ISO instant) normalized, or null when it is not one. */
export function validIsoDateTime(value: unknown): string | null {
  const ms = msOf(value);
  return ms === null ? null : new Date(ms).toISOString();
}

export const dateTimeFieldType: FieldType<string | null, DateTimeField> = {
  parse(text, field, { messages }) {
    const trimmed = text.trim();
    if (trimmed === '') return { value: null };
    const iso = parseText(trimmed, field);
    return iso ? { value: iso } : { error: messages.notADateTime(text) };
  },
  format(value, field) {
    if (value == null || value === '') return '';
    const ms = msOf(value);
    return ms === null ? String(value) : display(ms, field);
  },
  copyText: (value) => (value == null ? '' : String(value)),
  validate(value, field, { messages }) {
    const errors: string[] = [];
    if (!validTimeZone(field.timeZone)) {
      errors.push(messages.unknownTimeZone(String(field.timeZone)));
    }
    const ms = msOf(value);
    if (ms === null) return [...errors, messages.notADateTime(String(value))];
    const min = msOf(field.min);
    const max = msOf(field.max);
    if (min !== null && ms < min)
      errors.push(messages.min(display(min, field)));
    if (max !== null && ms > max)
      errors.push(messages.max(display(max, field)));
    return errors;
  },
  /** String order (one stored format); empty values first. */
  compare(a, b) {
    if (a == null) return b == null ? 0 : -1;
    if (b == null) return 1;
    return a < b ? -1 : a > b ? 1 : 0;
  },
  /**
   * One value continues by a day (a calendar day in the field's zone, so
   * the time stays across a DST change); two or more with a constant step
   * in ms continue it. Else `undefined`.
   */
  series(samples, count, field, direction) {
    const times: number[] = [];
    for (const sample of samples) {
      const ms = msOf(sample);
      if (ms === null) return undefined;
      times.push(ms);
    }
    if (!times.length) return undefined;
    const start = direction === 1 ? times[times.length - 1]! : times[0]!;
    if (times.length === 1) {
      const zone = zoneOf(field);
      const wall = wallAt(start, zone);
      return Array.from({ length: count }, (_, k) => {
        // the next calendar day, counted at noon (no DST edge)
        const day = new Date(
          wallMs({ ...wall, h: 12 }) + (k + 1) * direction * DAY
        );
        return new Date(
          instantOf(
            {
              ...wall,
              y: day.getUTCFullYear(),
              m: day.getUTCMonth() + 1,
              d: day.getUTCDate()
            },
            zone
          )
        ).toISOString();
      });
    }
    const step = times[1]! - times[0]!;
    for (let i = 2; i < times.length; i++) {
      if (times[i]! - times[i - 1]! !== step) return undefined;
    }
    return Array.from({ length: count }, (_, k) =>
      new Date(start + direction * step * (k + 1)).toISOString()
    );
  }
};
