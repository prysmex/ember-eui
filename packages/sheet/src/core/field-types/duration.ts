import { compareNumbers, finiteOrNull } from './numeric.ts';

import type { DurationField, FieldType } from '../types.ts';

const UNITS: Record<string, number> = { h: 3600, m: 60, s: 1 };

function pad(n: number): string {
  return String(n).padStart(2, '0');
}

/** Seconds of `text`, or `undefined`. */
function readDuration(
  text: string,
  format: 'h:mm' | 'h:mm:ss'
): number | undefined {
  const t = text.trim().toLowerCase();
  // 1:30 (hours and minutes), 1:30:15
  let match = /^(\d+):([0-5]?\d)(?::([0-5]?\d(?:\.\d+)?))?$/.exec(t);
  if (match) {
    return (
      Number(match[1]) * 3600 + Number(match[2]) * 60 + Number(match[3] ?? 0)
    );
  }
  // 90: minutes with 'h:mm', seconds with 'h:mm:ss'
  if (/^\d+(\.\d+)?$/.test(t)) {
    return Number(t) * (format === 'h:mm' ? 60 : 1);
  }
  // 1h 30m, 1.5h, 45s, 1h30m15s
  const unit = /(\d+(?:\.\d+)?)\s*([hms])/g;
  let total = 0;
  let rest = t;
  let found = false;
  while ((match = unit.exec(t))) {
    total += Number(match[1]) * UNITS[match[2]!]!;
    found = true;
    rest = rest.replace(match[0], '');
  }
  if (found && rest.trim() === '') return total;
  return undefined;
}

/**
 * `duration`: seconds or `null`, shown as `1:30` (`'h:mm'`, the default)
 * or `1:30:00` (`'h:mm:ss'`). Reads `1:30`, `1:30:00`, `1h 30m`, `1.5h`,
 * and a bare number (minutes with `'h:mm'`, seconds with `'h:mm:ss'`).
 * `'h:mm'` shows whole minutes.
 */
export const durationFieldType: FieldType<number | null, DurationField> = {
  parse(text, field, { messages }) {
    if (text.trim() === '') return { value: null };
    const seconds = readDuration(text, field.durationFormat ?? 'h:mm');
    if (seconds === undefined || !Number.isFinite(seconds)) {
      return { error: messages.notADuration(text) };
    }
    return { value: Math.round(seconds) };
  },
  format(value, field) {
    if (value == null || !Number.isFinite(value)) return '';
    const sign = value < 0 ? '-' : '';
    const total = Math.abs(value);
    if ((field.durationFormat ?? 'h:mm') === 'h:mm') {
      const minutes = Math.round(total / 60);
      return `${sign}${Math.floor(minutes / 60)}:${pad(minutes % 60)}`;
    }
    const seconds = Math.round(total);
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return `${sign}${h}:${pad(m)}:${pad(seconds % 60)}`;
  },
  validate(value, _field, { messages }) {
    return typeof value === 'number' && Number.isFinite(value) && value >= 0
      ? []
      : [messages.notADuration(String(value))];
  },
  compare: compareNumbers,
  toNumber: finiteOrNull
};
