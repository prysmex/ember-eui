/**
 * The time list and time rules for `EuiDatePicker` (DESIGN 2.3, 5.2):
 * wall times every `@timeIntervals` minutes from midnight, plus
 * `@injectTimes`; `@excludeTimes`, `@minTime`, `@maxTime` and instant
 * limits disable entries. With a day and a zone the list is that day's: a
 * wall time that does not exist (a DST gap) is left out, one that exists
 * twice appears once (its first instant).
 */
import { dayLimits, dayProblem, limitInstant } from './calendar-nav.ts';
import { compareTimes, parseTimeValue, timeValueOf } from './parse.ts';
import {
  dayOfWall,
  instantOf,
  sameWall,
  wallAt,
  wallExists,
  wallOf
} from './zone.ts';

import type { DateLimits, LimitProblem } from './calendar-nav.ts';
import type { TimeOfDay } from './parse.ts';
import type { Wall } from './zone.ts';

export const DEFAULT_TIME_INTERVAL = 30;

/**
 * `@timeIntervals` as used: a positive whole number of minutes; anything
 * else is 30, with `valid: false` for a development warning (9 #52).
 */
export function timeInterval(minutes: unknown): {
  interval: number;
  valid: boolean;
} {
  if (minutes === undefined || minutes === null) {
    return { interval: DEFAULT_TIME_INTERVAL, valid: true };
  }
  return typeof minutes === 'number' && Number.isInteger(minutes) && minutes > 0
    ? { interval: minutes, valid: true }
    : { interval: DEFAULT_TIME_INTERVAL, valid: false };
}

export interface TimeLimits {
  /** `HH:mm` (or `HH:mm:ss`): wall times before it are disabled. */
  minTime?: string | null;
  maxTime?: string | null;
  /** `HH:mm` entries that are disabled. */
  excludeTimes?: readonly string[] | null;
}

export interface TimeListOptions extends TimeLimits {
  /** Minutes between entries; see `timeInterval`. */
  interval?: number;
  /** `HH:mm` entries added to the list (upstream `injectTimes`). */
  injectTimes?: readonly string[] | null;
  /** Values carry `:ss` (`@seconds`). */
  seconds?: boolean;
  /** The shown day, `YYYY-MM-DD`. Without one (time only), no instants. */
  day?: string | null;
  /** The field's zone, normalized. Needed with `day`. */
  zone?: string;
  /** `@minDate`, `@maxDate`: dates or instants, checked against each entry's instant. */
  minDate?: string | null;
  maxDate?: string | null;
}

export interface TimeEntry {
  /** As stored in time mode: `HH:mm`, or `HH:mm:ss` with seconds. */
  value: string;
  time: TimeOfDay;
  /** The entry's instant on `day` in `zone`, or null without a day. */
  instant: number | null;
  /** Added by `@injectTimes` and not on the interval. */
  injected: boolean;
  /** Why it cannot be chosen, or null. */
  problem: LimitProblem | null;
}

function minutesOf(time: TimeOfDay): number {
  return time.hour * 60 + time.minute;
}

function timeSet(times: readonly string[] | null | undefined): Set<number> {
  const set = new Set<number>();
  for (const text of times ?? []) {
    const time = parseTimeValue(text);
    if (time) set.add(minutesOf(time));
  }
  return set;
}

/**
 * Why a wall time cannot be chosen by the time limits alone, or null:
 * before `@minTime` is 'min', after `@maxTime` is 'max', in
 * `@excludeTimes` is 'disabled'. Excluded times match on hours and
 * minutes.
 */
export function timeProblem(
  time: TimeOfDay,
  limits: TimeLimits
): LimitProblem | null {
  const min = parseTimeValue(limits.minTime);
  const max = parseTimeValue(limits.maxTime);
  if (min && compareTimes(time, min) < 0) return 'min';
  if (max && compareTimes(time, max) > 0) return 'max';
  if (timeSet(limits.excludeTimes).has(minutesOf(time))) return 'disabled';
  return null;
}

/** The time list for a day (or for time only, without `day`). Sorted, no duplicates. */
export function timeList(options: TimeListOptions = {}): TimeEntry[] {
  const { interval } = timeInterval(options.interval);
  const zone = options.zone ?? 'utc';
  const day = options.day ?? null;
  const minimum = day ? limitInstant(options.minDate, zone, 'min') : null;
  const maximum = day ? limitInstant(options.maxDate, zone, 'max') : null;

  const minutes = new Map<number, boolean>();
  for (let m = 0; m < 24 * 60; m += interval) minutes.set(m, false);
  for (const m of timeSet(options.injectTimes)) {
    if (!minutes.has(m)) minutes.set(m, true);
  }

  const entries: TimeEntry[] = [];
  for (const m of [...minutes.keys()].sort((a, b) => a - b)) {
    const time = { hour: Math.floor(m / 60), minute: m % 60, second: 0 };
    let instant: number | null = null;
    let problem = timeProblem(time, options);
    if (day) {
      const wall = wallOf(day, time.hour, time.minute);
      // a DST gap: the wall time does not exist that day
      if (!wallExists(wall, zone)) continue;
      instant = instantOf(wall, zone);
      if (minimum !== null && instant < minimum) problem ??= 'min';
      if (maximum !== null && instant > maximum) problem ??= 'max';
    }
    entries.push({
      value: timeValueOf(time, options.seconds),
      time,
      instant,
      injected: minutes.get(m)!,
      problem
    });
  }
  return entries;
}

export interface InstantRules extends DateLimits, TimeLimits {
  /** The field's zone, normalized. */
  zone: string;
}

/**
 * Why an instant (typed, or from a native input) cannot be chosen, or
 * null: its day in the zone fails the day rules (`dayProblem`); the
 * instant is before `@minDate` or after `@maxDate` when they are instants;
 * its wall time fails `@minTime`, `@maxTime` or `@excludeTimes`.
 */
export function instantProblem(
  ms: number,
  rules: InstantRules
): LimitProblem | null {
  const wall = wallAt(ms, rules.zone);
  const day = dayProblem(dayOfWall(wall), dayLimits(rules, rules.zone));
  if (day) return day;
  const minimum = limitInstant(rules.minDate, rules.zone, 'min');
  const maximum = limitInstant(rules.maxDate, rules.zone, 'max');
  if (minimum !== null && ms < minimum) return 'min';
  if (maximum !== null && ms > maximum) return 'max';
  return timeProblem({ hour: wall.h, minute: wall.mi, second: wall.s }, rules);
}

/**
 * The instant of a day at a chosen time (DESIGN 5.2): seconds and
 * milliseconds are zero unless `seconds`, a gap time resolves forward, an
 * overlap to the first.
 */
export function instantAt(
  day: string,
  time: TimeOfDay,
  zone: string,
  seconds = false
): number {
  return instantOf(
    wallOf(day, time.hour, time.minute, seconds ? time.second : 0),
    zone
  );
}

/**
 * Whether choosing a wall clock changes the value (DESIGN 5.2, "a stored
 * second occurrence survives"): only when it differs from the wall clock of
 * the current value in the zone. So the second `01:30` of an overlap stays
 * that instant until the user picks something else.
 */
export function changesValue(
  current: number | null,
  chosen: Wall,
  zone: string
): boolean {
  return current === null || !sameWall(wallAt(current, zone), chosen);
}
