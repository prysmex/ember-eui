import type { DateField, FieldType } from '../types.ts';

const ISO = /^(\d{4})-(\d{2})-(\d{2})$/;
const DAY = 86_400_000;

function pad(n: number, width = 2): string {
  return String(n).padStart(width, '0');
}

/** `YYYY-MM-DD` when y/m/d is a real calendar date, else null. No `Intl`, no time zone. */
function isoOf(y: number, m: number, d: number): string | null {
  const date = new Date(Date.UTC(y, m - 1, d));
  if (
    date.getUTCFullYear() !== y ||
    date.getUTCMonth() !== m - 1 ||
    date.getUTCDate() !== d
  ) {
    return null;
  }
  return `${pad(y, 4)}-${pad(m)}-${pad(d)}`;
}

/** The value if it is a real ISO date, else null. */
export function validIsoDate(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const match = ISO.exec(value);
  if (!match) return null;
  return isoOf(Number(match[1]), Number(match[2]), Number(match[3]));
}

function parseDate(text: string, order: 'dmy' | 'mdy'): string | null {
  let match = /^(\d{4})-(\d{2})-(\d{2})(?:[T ].*)?$/.exec(text);
  if (!match) match = /^(\d{4})\/(\d{2})\/(\d{2})$/.exec(text);
  if (match) {
    return isoOf(Number(match[1]), Number(match[2]), Number(match[3]));
  }
  match = /^(\d{1,2})([/.-])(\d{1,2})\2(\d{4})$/.exec(text);
  if (match) {
    const a = Number(match[1]);
    const b = Number(match[3]);
    const y = Number(match[4]);
    return order === 'dmy' ? isoOf(y, b, a) : isoOf(y, a, b);
  }
  return null;
}

function display(iso: string, order: 'dmy' | 'mdy'): string {
  const [y, m, d] = iso.split('-');
  return order === 'dmy' ? `${d}/${m}/${y}` : `${m}/${d}/${y}`;
}

/**
 * `date`: an ISO `YYYY-MM-DD` string or `null`. Reads ISO dates (also with a
 * time part), `YYYY/MM/DD` and `D/M/YYYY` (`/`, `-` or `.`; month first with
 * `dateOrder: 'mdy'`). Shows `DD/MM/YYYY` (or `MM/DD/YYYY`), copies ISO
 * (PACKAGE-DESIGN.md 5.4).
 */
export const dateFieldType: FieldType<string | null, DateField> = {
  parse(text, field, { messages }) {
    const trimmed = text.trim();
    if (trimmed === '') return { value: null };
    const iso = parseDate(trimmed, field.dateOrder ?? 'dmy');
    return iso ? { value: iso } : { error: messages.notADate(text) };
  },
  format(value, field) {
    if (value == null || value === '') return '';
    const iso = validIsoDate(value);
    return iso ? display(iso, field.dateOrder ?? 'dmy') : String(value);
  },
  copyText: (value) => (value == null ? '' : String(value)),
  validate(value, field, { messages }) {
    const iso = validIsoDate(value);
    if (!iso) return [messages.notADate(String(value))];
    const order = field.dateOrder ?? 'dmy';
    const errors: string[] = [];
    const min = validIsoDate(field.min);
    const max = validIsoDate(field.max);
    if (min && iso < min) errors.push(messages.min(display(min, order)));
    if (max && iso > max) errors.push(messages.max(display(max, order)));
    return errors;
  },
  compare(a, b) {
    if (a == null) return b == null ? 0 : -1;
    if (b == null) return 1;
    return a < b ? -1 : a > b ? 1 : 0;
  },
  /**
   * One date continues by one day; two or more with a constant step in
   * days continue it (a weekly step stays weekly). Else `undefined`.
   */
  series(samples, count, _field, direction) {
    const days: number[] = [];
    for (const sample of samples) {
      const iso = validIsoDate(sample);
      if (!iso) return undefined;
      const [y, m, d] = iso.split('-').map(Number);
      days.push(Date.UTC(y!, m! - 1, d!) / DAY);
    }
    if (!days.length) return undefined;
    const step = days.length === 1 ? 1 : days[1]! - days[0]!;
    for (let i = 2; i < days.length; i++) {
      if (days[i]! - days[i - 1]! !== step) return undefined;
    }
    const start = direction === 1 ? days[days.length - 1]! : days[0]!;
    return Array.from({ length: count }, (_, k) => {
      const date = new Date((start + direction * step * (k + 1)) * DAY);
      return `${pad(date.getUTCFullYear(), 4)}-${pad(date.getUTCMonth() + 1)}-${pad(date.getUTCDate())}`;
    });
  }
};
