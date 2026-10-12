/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

import type EuiI18n from '../../../services/eui-i18n';

export type PrettyIntervalUnit = 's' | 'm' | 'h' | 'd';

const MS_INTERVALS: Record<PrettyIntervalUnit, number> = {
  s: 1000,
  m: 60 * 1000,
  h: 60 * 60 * 1000,
  d: 24 * 60 * 60 * 1000
};

export interface PrettyIntervalOptions {
  /** Reduces the unit to a single letter, e.g. `5 m`. */
  shortHand?: boolean;
  /** Forces the unit instead of rounding to the largest one that fits. */
  unit?: PrettyIntervalUnit;
}

/**
 * Port of upstream `usePrettyInterval`: the label of an auto refresh
 * interval, e.g. `5 minutes`, or `Off` while paused (or for `0`).
 */
export function prettyInterval(
  euiI18n: EuiI18n,
  isPaused: boolean,
  intervalInMs: number,
  options: PrettyIntervalOptions = {}
): string {
  const { shortHand = false, unit } = options;
  let interval: number;
  let unitId: PrettyIntervalUnit;

  if (unit) {
    unitId = unit;
    interval = Math.round(intervalInMs / MS_INTERVALS[unit]);
  } else if (intervalInMs < MS_INTERVALS.m) {
    interval = Math.round(intervalInMs / MS_INTERVALS.s);
    unitId = 's';
  } else if (intervalInMs < MS_INTERVALS.h) {
    interval = Math.round(intervalInMs / MS_INTERVALS.m);
    unitId = 'm';
  } else if (intervalInMs < MS_INTERVALS.d) {
    interval = Math.round(intervalInMs / MS_INTERVALS.h);
    unitId = 'h';
  } else {
    interval = Math.round(intervalInMs / MS_INTERVALS.d);
    unitId = 'd';
  }

  if (isPaused || intervalInMs === 0) {
    return euiI18n.lookupToken('euiPrettyInterval.off', 'Off');
  }

  const names = { s: 'second', m: 'minute', h: 'hour', d: 'day' };
  const tokens = {
    s: ['seconds', 'secondsShorthand'],
    m: ['minutes', 'minutesShorthand'],
    h: ['hours', 'hoursShorthand'],
    d: ['days', 'daysShorthand']
  };

  if (shortHand) {
    return euiI18n.lookupToken(
      `euiPrettyInterval.${tokens[unitId][1]}`,
      `{interval} ${unitId}`,
      { interval }
    );
  }

  return euiI18n.lookupToken(
    `euiPrettyInterval.${tokens[unitId][0]}`,
    (values) => {
      const count = values['interval'] as number;

      return `${count} ${names[unitId]}${count > 1 ? 's' : ''}`;
    },
    { interval }
  );
}
