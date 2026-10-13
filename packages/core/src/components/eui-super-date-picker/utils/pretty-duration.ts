import {
  DATE_MODES,
  getDateMode,
  parseRelativeParts,
  useFormatTimeString
} from './index.ts';
import { useI18nTimeOptions } from './time-options.ts';

import type EuiI18n from '../../../services/eui-i18n';
import type { DurationRange, ShortDate } from '../types/global';

/**
 * Pretty duration i18n strings
 * Units should not be simply concatenated because different languages
 * will have different grammar/positions for time than English
 */

export const useRelativeDurationI18n = <T extends number = number>(
  duration: T,
  euiI18n: EuiI18n
) => {
  const lookupToken = euiI18n.lookupToken;

  return {
    s: lookupToken(
      'euiPrettyDuration.lastDurationSeconds',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Last ${duration} second${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    's+': lookupToken(
      'euiPrettyDuration.nextDurationSeconds',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Next ${duration} second${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    m: lookupToken(
      'euiPrettyDuration.lastDurationMinutes',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Last ${duration} minute${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    'm+': lookupToken(
      'euiPrettyDuration.nextDurationMinutes',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Next ${duration} minute${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    h: lookupToken(
      'euiPrettyDuration.lastDurationHours',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Last ${duration} hour${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    'h+': lookupToken(
      'euiPrettyDuration.nextDurationHours',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Next ${duration} hour${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    d: lookupToken(
      'euiPrettyDuration.lastDurationDays',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Last ${duration} day${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    'd+': lookupToken(
      'euiPrettyDuration.nexttDurationDays',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Next ${duration} day${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    w: lookupToken(
      'euiPrettyDuration.lastDurationWeeks',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Last ${duration} week${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    'w+': lookupToken(
      'euiPrettyDuration.nextDurationWeeks',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Next ${duration} week${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    M: lookupToken(
      'euiPrettyDuration.lastDurationMonths',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Last ${duration} month${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    'M+': lookupToken(
      'euiPrettyDuration.nextDurationMonths',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Next ${duration} month${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    y: lookupToken(
      'euiPrettyDuration.lastDurationYears',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Last ${duration} year${duration === 1 ? '' : 's'}`,
      { duration }
    ),
    'y+': lookupToken(
      'euiPrettyDuration.nextDurationYears',
      //@ts-expect-error
      ({ duration }: { duration: T }) =>
        `Next ${duration} year${duration === 1 ? '' : 's'}`,
      { duration }
    )
  };
};

const hasRangeMatch = (
  timeFrom: ShortDate,
  timeTo: ShortDate,
  ranges: DurationRange[]
) => {
  return ranges.find(({ start, end }) => timeFrom === start && timeTo === end);
};

const isRelativeToNow = (timeFrom: ShortDate, timeTo: ShortDate): boolean => {
  const fromDateMode = getDateMode(timeFrom);
  const toDateMode = getDateMode(timeTo);
  const isLast =
    fromDateMode === DATE_MODES.RELATIVE && toDateMode === DATE_MODES.NOW;
  const isNext =
    fromDateMode === DATE_MODES.NOW && toDateMode === DATE_MODES.RELATIVE;

  return isLast || isNext;
};

export const showPrettyDuration = (
  timeFrom: ShortDate,
  timeTo: ShortDate,
  quickRanges: DurationRange[]
): boolean => {
  if (hasRangeMatch(timeFrom, timeTo, quickRanges)) {
    return true;
  }

  return isRelativeToNow(timeFrom, timeTo);
};

/**
 * Upstream `useRelativeDurationRoundedI18n`: "{prettyDuration} rounded to
 * the hour" and so on, by rounding unit.
 */
const ROUNDED_DURATION_TOKENS: Record<string, [token: string, text: string]> =
  {
    s: [
      'euiPrettyDuration.durationRoundedToSecond',
      '{prettyDuration} rounded to the second'
    ],
    m: [
      'euiPrettyDuration.durationRoundedToMinute',
      '{prettyDuration} rounded to the minute'
    ],
    h: [
      'euiPrettyDuration.durationRoundedToHour',
      '{prettyDuration} rounded to the hour'
    ],
    d: [
      'euiPrettyDuration.durationRoundedToDay',
      '{prettyDuration} rounded to the day'
    ],
    w: [
      'euiPrettyDuration.durationRoundedToWeek',
      '{prettyDuration} rounded to the week'
    ],
    M: [
      'euiPrettyDuration.durationRoundedToMonth',
      '{prettyDuration} rounded to the month'
    ],
    y: [
      'euiPrettyDuration.durationRoundedToYear',
      '{prettyDuration} rounded to the year'
    ]
  };

/**
 * Upstream `usePrettyDuration`: a quick range's label ("Today"), else a
 * relative duration ("Last 15 minutes", "Next 2 days rounded to the day"),
 * else "{displayFrom} to {displayTo}".
 */
export function prettyDuration(
  euiI18n: EuiI18n,
  {
    timeFrom,
    timeTo,
    quickRanges,
    dateFormat
  }: {
    timeFrom: ShortDate;
    timeTo: ShortDate;
    quickRanges?: DurationRange[];
    dateFormat: string;
  }
): string {
  const ranges = quickRanges || useI18nTimeOptions(euiI18n).commonDurationRanges;
  const matchingQuickRange = hasRangeMatch(timeFrom, timeTo, ranges);

  if (matchingQuickRange && matchingQuickRange.label) {
    return matchingQuickRange.label;
  }

  if (isRelativeToNow(timeFrom, timeTo)) {
    const relativeParts =
      getDateMode(timeTo) === DATE_MODES.NOW
        ? parseRelativeParts(timeFrom)
        : parseRelativeParts(timeTo);
    const durations = useRelativeDurationI18n(relativeParts.count, euiI18n);
    const relative = relativeParts.unit
      ? ((durations as Record<string, unknown>)[relativeParts.unit] as
          | string
          | undefined) ?? ''
      : '';
    const rounded =
      relativeParts.round && relativeParts.roundUnit
        ? ROUNDED_DURATION_TOKENS[relativeParts.roundUnit]
        : undefined;
    const roundedString = rounded
      ? (euiI18n.lookupToken(rounded[0], rounded[1], {
          prettyDuration: relative
        }) as string)
      : '';
    const pretty = roundedString || relative;

    if (pretty) return pretty;
  }

  const displayFrom = useFormatTimeString(
    timeFrom,
    dateFormat,
    false,
    'en',
    euiI18n
  );
  const displayTo = useFormatTimeString(
    timeTo,
    dateFormat,
    true,
    'en',
    euiI18n
  );

  return euiI18n.lookupToken(
    'euiPrettyDuration.fallbackDuration',
    '{displayFrom} to {displayTo}',
    { displayFrom, displayTo }
  ) as string;
}

export default useRelativeDurationI18n;
