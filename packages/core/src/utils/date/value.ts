/**
 * `Date` and moment values accepted on the way in (DESIGN 18). The picker
 * works in strings; a `Date` or a moment given to `@value` or a date
 * argument is read once, at the edge, and never mutated. Output stays
 * strings.
 *
 * A moment is recognised by its shape, so this module (and the picker)
 * never imports the library.
 */
import { instantString, timeValueOf } from './parse.ts';
import { dayAt, wallAt } from './zone.ts';

/** What the picker's value is (DESIGN 4.2): a day, an instant (`@showTimeSelect`) or a time of day (`@showTimeSelectOnly`). */
export type PickerMode = 'date' | 'dateTime' | 'time';

/** What the picker reads from a moment: never more. */
export interface MomentLike {
  isValid(): boolean;
  toISOString(): string;
  format(): string;
  utcOffset(): number;
  valueOf(): number;
}

/** A value the date arguments accept: a string, a `Date` or a moment. */
export type DateInput = string | Date | MomentLike;

/** Whether a value is a moment: its flag, or the four functions moment objects have. */
export function isMomentLike(value: unknown): value is MomentLike {
  if (typeof value !== 'object' || value === null) return false;
  const candidate = value as Record<string, unknown>;
  if (candidate['_isAMomentObject'] === true) return true;
  return ['isValid', 'toISOString', 'format', 'utcOffset'].every(
    (name) => typeof candidate[name] === 'function'
  );
}

/** Whether a value is a `Date`, also one from another frame. */
export function isDateInstance(value: unknown): value is Date {
  return (
    value instanceof Date ||
    Object.prototype.toString.call(value) === '[object Date]'
  );
}

/** Whether a value is a `Date` or a moment rather than a string. */
export function isDateObject(value: unknown): value is Date | MomentLike {
  return isDateInstance(value) || isMomentLike(value);
}

/**
 * The instant of a `Date` or a moment in ms; NaN when it is invalid; null
 * when the value is neither.
 */
export function instantOfObject(value: unknown): number | null {
  if (isDateInstance(value)) return value.getTime();
  if (isMomentLike(value)) {
    try {
      return value.isValid() ? Number(value.valueOf()) : NaN;
    } catch {
      return NaN;
    }
  }
  return null;
}

/**
 * A value or a date argument as the picker reads it (DESIGN 18): a `Date`
 * or a moment becomes, by `mode`,
 *
 * - `'date'` (the default): its calendar day in `zone`, `YYYY-MM-DD`;
 * - `'dateTime'`: its instant, as a UTC ISO string (`toISOString`);
 * - `'time'`: its wall-clock time in `zone`, `HH:mm`, or `HH:mm:ss` with
 *   `seconds`.
 *
 * `zone` is normalized, `'local'` by default. An invalid object becomes
 * null. Anything else is returned as is, for the string rules to judge.
 */
export function toDateValue(
  value: unknown,
  zone = 'local',
  mode: PickerMode = 'date',
  seconds = false
): unknown {
  const ms = instantOfObject(value);
  if (ms === null) return value;
  if (!Number.isFinite(ms)) return null;
  if (mode === 'dateTime') return instantString(ms);
  if (mode === 'time') {
    const wall = wallAt(ms, zone);
    return timeValueOf(
      { hour: wall.h, minute: wall.mi, second: wall.s },
      seconds
    );
  }
  return dayAt(ms, zone);
}

/** Whether a value is a `Date` or a moment that names no instant. */
export function isInvalidDateObject(value: unknown): boolean {
  const ms = instantOfObject(value);
  return ms !== null && !Number.isFinite(ms);
}
