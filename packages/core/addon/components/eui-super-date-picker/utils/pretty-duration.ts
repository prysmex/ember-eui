import { DATE_MODES, getDateMode, useEuiI18n } from '.';
import { DurationRange, ShortDate } from '../types/global';

/**
 * Pretty duration i18n strings
 * Units should not be simply concatenated because different languages
 * will have different grammar/positions for time than English
 */

export const useRelativeDurationI18n = (duration: number) => ({
  s: useEuiI18n(
    'euiPrettyDuration.lastDurationSeconds',
    ({ duration }) => `Last ${duration} second${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  's+': useEuiI18n(
    'euiPrettyDuration.nextDurationSeconds',
    ({ duration }) => `Next ${duration} second${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  m: useEuiI18n(
    'euiPrettyDuration.lastDurationMinutes',
    ({ duration }) => `Last ${duration} minute${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  'm+': useEuiI18n(
    'euiPrettyDuration.nextDurationMinutes',
    ({ duration }) => `Next ${duration} minute${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  h: useEuiI18n(
    'euiPrettyDuration.lastDurationHours',
    ({ duration }) => `Last ${duration} hour${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  'h+': useEuiI18n(
    'euiPrettyDuration.nextDurationHours',
    ({ duration }) => `Next ${duration} hour${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  d: useEuiI18n(
    'euiPrettyDuration.lastDurationDays',
    ({ duration }) => `Last ${duration} day${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  'd+': useEuiI18n(
    'euiPrettyDuration.nexttDurationDays',
    ({ duration }) => `Next ${duration} day${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  w: useEuiI18n(
    'euiPrettyDuration.lastDurationWeeks',
    ({ duration }) => `Last ${duration} week${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  'w+': useEuiI18n(
    'euiPrettyDuration.nextDurationWeeks',
    ({ duration }) => `Next ${duration} week${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  M: useEuiI18n(
    'euiPrettyDuration.lastDurationMonths',
    ({ duration }) => `Last ${duration} month${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  'M+': useEuiI18n(
    'euiPrettyDuration.nextDurationMonths',
    ({ duration }) => `Next ${duration} month${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  y: useEuiI18n(
    'euiPrettyDuration.lastDurationYears',
    ({ duration }) => `Last ${duration} year${duration === 1 ? '' : 's'}`,
    { duration }
  ),
  'y+': useEuiI18n(
    'euiPrettyDuration.nextDurationYears',
    ({ duration }) => `Next ${duration} year${duration === 1 ? '' : 's'}`,
    { duration }
  ),
});

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
