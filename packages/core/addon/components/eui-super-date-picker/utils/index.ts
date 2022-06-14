/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

import moment, { LocaleSpecifier } from 'moment';
import dateMath from '@elastic/datemath';
import { RelativeParts, ShortDate } from '../types/global';

/**
 * Reusable format time string util
 */
export const ISO_FORMAT = 'YYYY-MM-DDTHH:mm:ss.SSSZ';
export const INVALID_DATE = 'invalid_date';
export const ROUND_DELIMETER = '/';
export const relativeUnitsFromLargestToSmallest = [
  'y',
  'M',
  'w',
  'd',
  'h',
  'm',
  's'
];
export type AbsoluteDateMode = 'absolute';
export type RelativeDateMode = 'relative';
export type NowDateMode = 'now';
export type DateMode = AbsoluteDateMode | RelativeDateMode | NowDateMode;
export const DATE_MODES: {
  ABSOLUTE: AbsoluteDateMode;
  RELATIVE: RelativeDateMode;
  NOW: NowDateMode;
} = {
  ABSOLUTE: 'absolute',
  RELATIVE: 'relative',
  NOW: 'now'
};

export const useFormatTimeString = (
  timeString: string,
  dateFormat: string,
  roundUp = false,
  locale: LocaleSpecifier = 'en'
): string => {
  // i18n'd strings
  const nowDisplay = useEuiI18n('euiPrettyDuration.now', 'now');
  const invalidDateDisplay = useEuiI18n(
    'euiPrettyDuration.invalid',
    'Invalid date'
  );

  const timeAsMoment = moment(timeString, ISO_FORMAT, true);
  if (timeAsMoment.isValid()) {
    return timeAsMoment.locale(locale).format(dateFormat);
  }

  if (timeString === 'now') {
    return nowDisplay;
  }

  const tryParse = dateMath.parse(timeString, { roundUp: roundUp });
  if (!moment(tryParse).isValid()) {
    return invalidDateDisplay;
  }

  if (moment.isMoment(tryParse)) {
    return `~ ${tryParse.locale(locale).fromNow()}`;
  }

  return timeString;
};

export function useEuiI18n(token: string, defaultValue: string, values?: Record<string, unknown>): string {
  console.warn('useEuiI18n function is not implemented', token);
  return defaultValue;
}

export function toAbsoluteString(value: string, roundUp: boolean = false) {
  const valueAsMoment = dateMath.parse(value, { roundUp });
  if (!valueAsMoment) {
    return value;
  }
  if (!moment(valueAsMoment).isValid()) {
    return INVALID_DATE;
  }
  return valueAsMoment.toISOString();
}

export function parseRelativeParts(value: string) {
  const matches =
    typeof value === 'string' &&
    value.match(/now(([-+])([0-9]+)([smhdwMy])(\/[smhdwMy])?)?/);

  const operator = matches && matches[2];
  const count = matches && matches[3];
  const unit = matches && matches[4];
  const roundBy = matches && matches[5];

  if (count && unit) {
    const isRounded = roundBy ? true : false;
    const roundUnit =
      isRounded && roundBy ? roundBy.replace(ROUND_DELIMETER, '') : undefined;
    return {
      count: parseInt(count, 10),
      unit: operator === '+' ? `${unit}+` : unit,
      round: isRounded,
      ...(roundUnit ? { roundUnit } : {})
    };
  }

  const results = { count: 0, unit: 's', round: false };
  const duration = moment.duration(moment().diff(dateMath.parse(value)));
  let unitOp = '';
  for (let i = 0; i < relativeUnitsFromLargestToSmallest.length; i++) {
    const asRelative = duration.as(relativeUnitsFromLargestToSmallest[i]);
    if (asRelative < 0) unitOp = '+';
    if (Math.abs(asRelative) > 1) {
      results.count = Math.round(Math.abs(asRelative));
      results.unit = relativeUnitsFromLargestToSmallest[i] + unitOp;
      results.round = false;
      break;
    }
  }
  return results;
}

export function toRelativeStringFromParts(relativeParts: RelativeParts) {
  const count = relativeParts.count ?? 0;
  const isRounded = relativeParts.round ?? false;

  if (count === 0 && !isRounded) {
    return 'now';
  }

  const matches = (relativeParts.unit ?? 's').match(/([smhdwMy])(\+)?/);
  const unit = matches?.[1];
  const operator = matches && matches[2] ? matches[2] : '-';
  const round = isRounded ? `${ROUND_DELIMETER}${unit}` : '';

  return `now${operator}${count}${unit}${round}`;
}

export function isRangeInvalid(start: ShortDate, end: ShortDate) {
  if (start === 'now' && end === 'now') {
    return true;
  }

  const startMoment = dateMath.parse(start);
  const endMoment = dateMath.parse(end, { roundUp: true });

  const isInvalid =
    !startMoment ||
    !endMoment ||
    !startMoment.isValid() ||
    !endMoment.isValid() ||
    !moment(startMoment).isValid() ||
    !moment(endMoment).isValid() ||
    startMoment.isAfter(endMoment);

  return isInvalid;
}

export function getDateMode(value: ShortDate) {
  if (value === 'now') {
    return DATE_MODES.NOW;
  }

  if (value.includes('now')) {
    return DATE_MODES.RELATIVE;
  }

  return DATE_MODES.ABSOLUTE;
}
