/**
 * `EuiDatePicker`'s native path (DESIGN 6): which path a picker takes, and
 * its value as the OS input holds it and back. Plain functions, no Ember,
 * no Capacitor import: Capacitor is read through `window` only.
 *
 * Nothing the OS returns is trusted: every value is checked against the
 * picker's limits here, as typed text is on the calendar path.
 */
import { pad, validIsoDate } from '../utils/date/calendar-date.ts';
import { dayProblem, limitInstant } from '../utils/date/calendar-nav.ts';
import { instantString, timeValueOf } from '../utils/date/parse.ts';
import {
  changesValue,
  instantProblem,
  timeProblem
} from '../utils/date/times.ts';
import { instantOf, wallAt } from '../utils/date/zone.ts';

import type { DayLimits, LimitProblem } from '../utils/date/calendar-nav.ts';
import type { TimeOfDay } from '../utils/date/parse.ts';
import type { InstantRules, TimeLimits } from '../utils/date/times.ts';
import type { PickerMode } from '../utils/date/value.ts';
import type { Wall } from '../utils/date/zone.ts';

/** `@native` and `componentDefaults.EuiDatePicker.native`: `'auto'`, or a path forced. */
export type EuiDatePickerNative = 'auto' | boolean;

/** The arguments the OS picker cannot honour (DESIGN 6.2): auto takes the calendar when one is present (decision 7). */
export const NATIVE_UNSUPPORTED_ARGS = [
  'filterDate',
  'excludeDates',
  'includeDates',
  'excludeTimes',
  'injectTimes',
  'dayClassName'
] as const;

/** The names of `NATIVE_UNSUPPORTED_ARGS` that are given (not null, not undefined). */
export function unsupportedByNative(args: object): string[] {
  const given = args as Record<string, unknown>;
  return NATIVE_UNSUPPORTED_ARGS.filter((name) => given[name] != null);
}

/** What auto looks at in the browser. */
export interface NativeEnvironment {
  /** A browser, not server rendering. */
  browser: boolean;
  /** `window.Capacitor?.isNativePlatform?.()` is true: a Capacitor app on a device. */
  nativePlatform: boolean;
  /** `(pointer: coarse)` matches: the primary pointer is a finger. */
  coarsePointer: boolean;
}

interface CapacitorLike {
  isNativePlatform?: () => unknown;
}

/** The environment of auto, read now. Never throws. */
export function nativeEnvironment(): NativeEnvironment {
  if (typeof window === 'undefined') {
    return { browser: false, nativePlatform: false, coarsePointer: false };
  }
  let nativePlatform = false;
  try {
    const capacitor = (window as { Capacitor?: CapacitorLike }).Capacitor;
    nativePlatform = capacitor?.isNativePlatform?.() === true;
  } catch {
    nativePlatform = false;
  }
  let coarsePointer = false;
  try {
    coarsePointer =
      typeof window.matchMedia === 'function' &&
      window.matchMedia('(pointer: coarse)').matches;
  } catch {
    coarsePointer = false;
  }
  return { browser: true, nativePlatform, coarsePointer };
}

export interface NativeChoiceOptions {
  /** `@inline`: there is no native inline picker. */
  inline?: boolean;
  /** A `<:trigger>` block (batch 6). */
  trigger?: boolean;
  /** `@native`. */
  native?: unknown;
  /** `componentDefaults.EuiDatePicker.native`. */
  config?: unknown;
  /** Arguments the OS picker cannot honour are given. */
  unsupported?: boolean;
}

/**
 * Whether the picker takes the native path (DESIGN 6.2), in this order,
 * the first that answers winning: `@inline` or a custom trigger take the
 * calendar; then `@native` when `true` or `false`; then the config default
 * when `true` or `false`; then auto: the calendar on the server and with an
 * argument the OS cannot honour, native in a Capacitor app on a device or
 * with a coarse primary pointer, else the calendar.
 */
export function choosesNative(
  options: NativeChoiceOptions,
  environment: NativeEnvironment = nativeEnvironment()
): boolean {
  if (options.inline || options.trigger) return false;
  if (typeof options.native === 'boolean') return options.native;
  if (typeof options.config === 'boolean') return options.config;
  if (!environment.browser || options.unsupported) return false;
  return environment.nativePlatform || environment.coarsePointer;
}

/* The input */

export type NativeInputType = 'date' | 'datetime-local' | 'time';

export function nativeInputType(mode: PickerMode): NativeInputType {
  return mode === 'dateTime' ? 'datetime-local' : mode;
}

/** The years the picker supports (DESIGN 5.1). Without a `max`, Chromium's year segment takes six digits. */
export const NATIVE_MIN_DATE = '0001-01-01';
export const NATIVE_MAX_DATE = '9999-12-31';

function timeText(wall: Pick<Wall, 'h' | 'mi' | 's'>, seconds: boolean) {
  return timeValueOf(
    { hour: wall.h, minute: wall.mi, second: wall.s },
    seconds
  );
}

/** A wall clock as `datetime-local` holds it: `YYYY-MM-DDTHH:mm`, with `:ss` when `seconds`. */
export function dateTimeLocalOf(wall: Wall, seconds = false): string {
  return `${pad(wall.y, 4)}-${pad(wall.m)}-${pad(wall.d)}T${timeText(wall, seconds)}`;
}

/** An instant's wall clock in the zone, as `datetime-local` holds it (the sheet's `dateTimeLocalValue`). */
export function dateTimeLocalAt(
  ms: number,
  zone: string,
  seconds = false
): string {
  return dateTimeLocalOf(wallAt(ms, zone), seconds);
}

const NATIVE_TIME = /^(\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,3}))?)?$/;
const NATIVE_DATE_TIME = /^(\d{4,})-(\d{2})-(\d{2})T(.+)$/;

/** A `time` input's value (`HH:mm`, `HH:mm:ss`, `HH:mm:ss.SSS`: engines differ), or null. */
export function parseNativeTime(
  text: string
): (TimeOfDay & { millisecond: number }) | null {
  const match = NATIVE_TIME.exec(text);
  if (!match) return null;
  const time = {
    hour: Number(match[1]),
    minute: Number(match[2]),
    second: Number(match[3] ?? 0),
    millisecond: Number((match[4] ?? '0').padEnd(3, '0'))
  };
  return time.hour > 23 || time.minute > 59 || time.second > 59 ? null : time;
}

/** A `datetime-local` input's value as a wall clock, or null. */
export function parseNativeDateTime(text: string): Wall | null {
  const match = NATIVE_DATE_TIME.exec(text);
  if (!match) return null;
  const day = validIsoDate(`${match[1]}-${match[2]}-${match[3]}`);
  const time = parseNativeTime(match[4]!);
  if (!day || !time) return null;
  const [y, m, d] = day.split('-').map(Number) as [number, number, number];
  return {
    y,
    m,
    d,
    h: time.hour,
    mi: time.minute,
    s: time.second,
    ms: time.millisecond
  };
}

/** What the native input is given: its value and its `min`, `max` and `step`. */
export interface NativeAttributes {
  type: NativeInputType;
  value: string;
  min: string | undefined;
  max: string | undefined;
  /** `1` with seconds, `60` for a time; none for a date (one day). */
  step: string | undefined;
}

export interface NativeContext {
  mode: PickerMode;
  zone: string;
  seconds: boolean;
  /** The picker's value, normalized: `YYYY-MM-DD`, or `HH:mm(:ss)`; null without one. */
  value: string | null;
  /** Date and time: the value's instant. */
  valueMs: number | null;
  /** `@minDate`, `@maxDate` as the picker reads them: days, or instants with a time. */
  minDate: string | null;
  maxDate: string | null;
  /** The day rules, resolved. */
  limits: DayLimits;
  /** Every rule an instant is checked against. */
  instantRules: InstantRules;
  /** `@minTime`, `@maxTime`, `@excludeTimes`. */
  timeLimits: TimeLimits;
}

/**
 * A limit as `datetime-local` holds it: a day is its first or last minute;
 * an instant is its wall clock in the zone, rounded inward to what the
 * input shows (so the input's own step, counted from `min`, stays on whole
 * minutes, and the browser and the picker agree on what is outside).
 */
function dateTimeLimit(
  limit: string | null,
  edge: 'min' | 'max',
  context: NativeContext
): string {
  const ms = limitInstant(limit, context.zone, edge);
  if (ms === null || !Number.isFinite(ms)) {
    return edge === 'min'
      ? `${NATIVE_MIN_DATE}T00:00`
      : `${NATIVE_MAX_DATE}T${context.seconds ? '23:59:59' : '23:59'}`;
  }
  const unit = context.seconds ? 1000 : 60_000;
  const wall = wallAt(ms, context.zone);
  const exact = wall.ms === 0 && (context.seconds || wall.s === 0);
  if (edge === 'min' && !exact) {
    // the next whole unit; through the wall clock, so a gap is not crossed
    return dateTimeLocalAt(
      Math.floor(ms / unit) * unit + unit,
      context.zone,
      context.seconds
    );
  }
  return dateTimeLocalOf(wall, context.seconds);
}

/**
 * The native input's attributes for the picker's state (DESIGN 6.1). A
 * value the input cannot hold (unreadable, or a date and time without an
 * instant) is empty. `step` is whole minutes (`60`), or seconds (`1`) with
 * `@seconds`: never `@timeIntervals`, since a time off the step is
 * `:invalid` to the browser (the invalid look, a form that will not
 * submit) while the picker accepts it, as it accepts it typed.
 */
export function nativeAttributes(context: NativeContext): NativeAttributes {
  const step = context.seconds ? '1' : '60';
  switch (context.mode) {
    case 'dateTime':
      return {
        type: 'datetime-local',
        value:
          context.valueMs === null
            ? ''
            : dateTimeLocalAt(context.valueMs, context.zone, context.seconds),
        min: dateTimeLimit(context.minDate, 'min', context),
        max: dateTimeLimit(context.maxDate, 'max', context),
        step
      };
    case 'time': {
      const time = (limit: string | null | undefined) => {
        const read = limit ? parseNativeTime(limit) : null;
        return read ? timeValueOf(read, context.seconds) : undefined;
      };
      const value = context.value ? parseNativeTime(context.value) : null;
      return {
        type: 'time',
        value: value ? timeValueOf(value, context.seconds) : '',
        min: time(context.timeLimits.minTime),
        max: time(context.timeLimits.maxTime),
        step
      };
    }
    default:
      return {
        type: 'date',
        value: context.value ?? '',
        min: context.limits.min ?? NATIVE_MIN_DATE,
        max: context.limits.max ?? NATIVE_MAX_DATE,
        step: undefined
      };
  }
}

/**
 * Mark a native input that holds nothing (`data-empty`): no value and no
 * half-filled field. CSS cannot tell an empty date input from a full one,
 * and its empty segments (`mm/dd/yyyy`) look like a value otherwise.
 */
export function markEmpty(input: HTMLInputElement): void {
  input.toggleAttribute(
    'data-empty',
    input.value === '' && !input.validity?.badInput
  );
}

/** What a native input's value means for the picker. */
export type NativeReading =
  /** Empty: no value. */
  | { kind: 'empty' }
  /** A value that can be chosen, and whether it differs from the picker's. */
  | { kind: 'value'; value: string; changes: boolean }
  /** Not a value, or one that cannot be chosen. */
  | { kind: 'problem'; problem: 'unreadable' | LimitProblem };

/**
 * Read what the native input holds (its `value` and `validity.badInput`)
 * against the picker's rules (DESIGN 6.3: post-validation; the OS is not
 * trusted to enforce `min` and `max`, nor anything else).
 *
 * - An empty value is no value, unless the input reports bad input (a
 *   half-filled field): that is unreadable.
 * - A date is checked as a typed one (`dayProblem`).
 * - A date and time is a wall clock in the zone: a gap time resolves
 *   forward, an overlap to the first (DESIGN 5.2), and the instant is
 *   checked as a typed one (`instantProblem`). It changes the value only
 *   when it is a different wall clock at the precision the input shows: a
 *   value with hidden seconds keeps them while its minute stays, and a
 *   stored second occurrence survives (9 #21).
 * - A time keeps seconds only with `@seconds`, and is checked against
 *   `@minTime`, `@maxTime` and `@excludeTimes`.
 */
export function readNative(
  text: string,
  badInput: boolean,
  context: NativeContext
): NativeReading {
  if (text === '') {
    return badInput
      ? { kind: 'problem', problem: 'unreadable' }
      : { kind: 'empty' };
  }
  switch (context.mode) {
    case 'dateTime': {
      const chosen = parseNativeDateTime(text);
      if (!chosen) return { kind: 'problem', problem: 'unreadable' };
      const current = context.valueMs;
      const wall = current === null ? null : wallAt(current, context.zone);
      // what the input does not show comes from the value while the time
      // it shows is the value's (only the day changed); else it is zero
      const sameTime =
        wall !== null &&
        chosen.h === wall.h &&
        chosen.mi === wall.mi &&
        (!context.seconds || chosen.s === wall.s);
      chosen.s = context.seconds ? chosen.s : sameTime ? wall.s : 0;
      chosen.ms = sameTime ? wall.ms : 0;
      const ms = instantOf(chosen, context.zone);
      const problem = instantProblem(ms, context.instantRules);
      if (problem) return { kind: 'problem', problem };
      // a different wall clock, and not the value's own instant (a gap time
      // that resolves to the value)
      const changes =
        ms !== current && changesValue(current, chosen, context.zone);
      return { kind: 'value', value: instantString(ms), changes };
    }
    case 'time': {
      const read = parseNativeTime(text);
      if (!read) return { kind: 'problem', problem: 'unreadable' };
      const current = context.value ? parseNativeTime(context.value) : null;
      if (
        current &&
        !context.seconds &&
        read.hour === current.hour &&
        read.minute === current.minute
      ) {
        // the minute the input shows is the value's: hidden seconds stay
        return { kind: 'value', value: context.value!, changes: false };
      }
      const time = context.seconds ? read : { ...read, second: 0 };
      const problem = timeProblem(time, context.timeLimits);
      if (problem) return { kind: 'problem', problem };
      const value = timeValueOf(time, context.seconds);
      return { kind: 'value', value, changes: value !== context.value };
    }
    default: {
      const date = validIsoDate(text);
      if (!date) return { kind: 'problem', problem: 'unreadable' };
      const problem = dayProblem(date, context.limits);
      if (problem) return { kind: 'problem', problem };
      return { kind: 'value', value: date, changes: date !== context.value };
    }
  }
}
