/**
 * `Date` and moment values accepted on the way in (DESIGN 18). The picker
 * works in strings; a `Date` or a moment given to `@value` or a date
 * argument is read once, at the edge, and never mutated. Output stays
 * strings.
 *
 * A moment is recognised by its shape, so this module (and the picker)
 * never imports the library.
 */
import { dayAt } from './zone.ts';

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
 * A date argument as the picker reads it in date mode: a `Date` or a
 * moment becomes its calendar day in `zone` (normalized, `'local'` by
 * default), `YYYY-MM-DD`; an invalid one becomes null. Anything else is
 * returned as is, for the string rules to judge.
 */
export function toDateValue(value: unknown, zone = 'local'): unknown {
  const ms = instantOfObject(value);
  if (ms === null) return value;
  return Number.isFinite(ms) ? dayAt(ms, zone) : null;
}

/** Whether a value is a `Date` or a moment that names no instant. */
export function isInvalidDateObject(value: unknown): boolean {
  const ms = instantOfObject(value);
  return ms !== null && !Number.isFinite(ms);
}
