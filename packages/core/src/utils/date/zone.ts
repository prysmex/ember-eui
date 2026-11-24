/**
 * Time zones for `EuiDatePicker` (DESIGN 5.2). An instant is a UTC ISO
 * string (`Date.prototype.toISOString`), handled here in ms. `@timeZone` is
 * a property of the field: 'local', 'utc', an IANA name, or a fixed offset
 * from UTC (`'+05:30'`, `'-02:00'`: upstream's `utcOffset`, DESIGN 17).
 *
 * `wallAt` and `instantOf` are the sheet's algorithm
 * (`packages/sheet/src/core/field-types/date-time.ts`), copied because the
 * sheet's `src/core` may not import from core. Both test suites run the same
 * vectors (`tests/unit/utils/date-zone-vectors.json`), so keep the two
 * copies equal: a fix here is a fix there.
 */
import { pad } from './calendar-date.ts';

const DAY = 86_400_000;

/** A wall clock: calendar date and time, no zone. */
export interface Wall {
  y: number;
  m: number;
  d: number;
  h: number;
  mi: number;
  s: number;
  ms: number;
}

/** 'local', 'utc', an IANA name, or a fixed offset (`'+05:30'`). */
export type TimeZone = 'local' | 'utc' | (string & {});

// ECMA-402's offset time zones: ±HH, ±HHMM or ±HH:MM, at most 23:59
const OFFSET_ZONE = /^([+-])(\d{2})(?::?(\d{2}))?$/;

/**
 * A fixed offset from UTC, in minutes, or null when the zone is not one:
 * `'+05:30'` is 330, `'-02:00'` is -120. The forms are `Intl`'s
 * (`±HH:MM`, `±HHMM`, `±HH`), up to 23:59 either way. A fixed offset has no
 * DST: every wall clock exists exactly once.
 */
export function offsetMinutes(zone: string | null | undefined): number | null {
  const match = OFFSET_ZONE.exec(zone ?? '');
  if (!match) return null;
  const hours = Number(match[2]);
  const minutes = Number(match[3] ?? 0);
  if (hours > 23 || minutes > 59) return null;
  return (match[1] === '-' ? -1 : 1) * (hours * 60 + minutes);
}

/** A fixed offset as `±HH:MM` (`-00:00` is `+00:00`). */
function offsetZone(minutes: number): string {
  const sign = minutes < 0 ? '-' : '+';
  const abs = Math.abs(minutes);
  return `${sign}${pad(Math.floor(abs / 60))}:${pad(abs % 60)}`;
}

/** The wall clock as if it were UTC, in ms (any year). */
export function wallMs(wall: Wall): number {
  const date = new Date(0);
  date.setUTCFullYear(wall.y, wall.m - 1, wall.d);
  date.setUTCHours(wall.h, wall.mi, wall.s, wall.ms);
  return date.getTime();
}

/** Whether y/m/d h:mi:s is a real calendar date and time. */
export function realWall(wall: Wall): boolean {
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

/** The zone as used here: 'local' (also for none), 'utc' (any case), a fixed offset as `±HH:MM`, or the IANA name. */
export function normalizeTimeZone(zone: string | null | undefined): string {
  if (!zone || zone === 'local') return 'local';
  if (zone.toLowerCase() === 'utc') return 'utc';
  const offset = offsetMinutes(zone);
  return offset === null ? zone : offsetZone(offset);
}

/** Whether the zone is one this browser knows ('local', 'utc' and fixed offsets always). */
export function validTimeZone(zone: string | null | undefined): boolean {
  if (!zone || zone === 'local' || zone.toLowerCase() === 'utc') return true;
  if (offsetMinutes(zone) !== null) return true;
  return formatterOf(zone) !== null;
}

/** The wall clock of an instant as if it were UTC. */
function utcWall(date: Date): Wall {
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

/**
 * The zone's wall clock at an instant. An unknown zone reads as UTC (the
 * picker reports it). A fixed offset is plain arithmetic, so it does not
 * depend on the engine's `Intl` knowing offset zones.
 */
export function wallAt(ms: number, zone: string): Wall {
  const offset = offsetMinutes(zone);
  if (offset !== null) return utcWall(new Date(ms + offset * 60_000));
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
  if (!formatter) return utcWall(date);
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
 * rules, which are the same. A fixed offset has neither.
 */
export function instantOf(wall: Wall, zone: string): number {
  const offset = offsetMinutes(zone);
  if (offset !== null) return wallMs(wall) - offset * 60_000;
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

/* Below: not in the sheet. Built on the two functions above. */

/** Whether two wall clocks are the same to the millisecond. */
export function sameWall(a: Wall, b: Wall): boolean {
  return wallMs(a) === wallMs(b);
}

/** The calendar day of a wall clock, `YYYY-MM-DD`. */
export function dayOfWall(wall: Wall): string {
  return `${pad(wall.y, 4)}-${pad(wall.m)}-${pad(wall.d)}`;
}

/** The zone's calendar day at an instant, `YYYY-MM-DD`. */
export function dayAt(ms: number, zone: string): string {
  return dayOfWall(wallAt(ms, zone));
}

/**
 * Today in a zone (DESIGN 5.1): the calendar day in `zone` at `now`. The
 * caller reads the clock once (`Date.now()`) and passes it; nothing here
 * reads it.
 */
export function todayIn(zone: string | null | undefined, now: number): string {
  return dayAt(now, normalizeTimeZone(zone));
}

/** The wall clock of a day at a time of day. */
export function wallOf(
  day: string,
  hour = 0,
  minute = 0,
  second = 0,
  millisecond = 0
): Wall {
  const [y, m, d] = day.split('-').map(Number) as [number, number, number];
  return { y, m, d, h: hour, mi: minute, s: second, ms: millisecond };
}

/** The first instant of a day in a zone (its 00:00, or the first wall time after a gap at midnight). */
export function startOfDayIn(day: string, zone: string): number {
  return instantOf(wallOf(day), zone);
}

/**
 * The instant on another day at the same wall time, seconds and
 * milliseconds included (DESIGN 5.2, "changing the day"). If the new day
 * has no such time it resolves forward; on an overlap, to the first.
 */
export function withDay(ms: number, day: string, zone: string): number {
  const wall = wallAt(ms, zone);
  const [y, m, d] = day.split('-').map(Number) as [number, number, number];
  return instantOf({ ...wall, y, m, d }, zone);
}

/** Whether a wall clock exists in a zone (it is not in a DST gap). */
export function wallExists(wall: Wall, zone: string): boolean {
  return sameWall(wallAt(instantOf(wall, zone), zone), wall);
}
