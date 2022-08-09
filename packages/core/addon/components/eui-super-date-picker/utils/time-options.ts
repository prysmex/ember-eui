/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */
import { EuiSelectOption } from '@elastic/eui';
import type EuiI18n from '../../../services/eui-i18n';

import { TimeUnitId, RelativeOption, DurationRange } from '../types/global';

export const LAST = 'last';
export const NEXT = 'next';

export type TimeOptions = {
  timeTenseOptions: EuiSelectOption[];
  timeUnitsOptions: EuiSelectOption[];
  relativeOptions: RelativeOption[];
  relativeRoundingLabels: { [id in TimeUnitId]: string };
  refreshUnitsOptions: EuiSelectOption[];
  commonDurationRanges: DurationRange[];
};

/**
 * i18n'd time options, mostly used in EuiSelects (except for a few cases)
 * used in EuiSuperDatePicker child sub-components
 */
export const useI18nTimeOptions = (euiI18nService: EuiI18n): TimeOptions => {
  let lookupToken = euiI18nService.lookupToken;

  /**
   * Quick select panel
   */
  const timeTenseOptions = [
    { value: LAST, text: lookupToken('euiTimeOptions.last', 'Last') },
    { value: NEXT, text: lookupToken('euiTimeOptions.next', 'Next') }
  ];

  const timeUnitsOptions = [
    { value: 's', text: lookupToken('euiTimeOptions.seconds', 'Seconds') },
    { value: 'm', text: lookupToken('euiTimeOptions.minutes', 'Minutes') },
    { value: 'h', text: lookupToken('euiTimeOptions.hours', 'Hours') },
    { value: 'd', text: lookupToken('euiTimeOptions.days', 'Days') },
    { value: 'w', text: lookupToken('euiTimeOptions.weeks', 'Weeks') },
    { value: 'M', text: lookupToken('euiTimeOptions.months', 'Months') },
    { value: 'y', text: lookupToken('euiTimeOptions.years', 'Years') }
  ];

  /**
   * Relative tab
   */
  const relativeOptions: RelativeOption[] = [
    {
      text: lookupToken('euiTimeOptions.secondsAgo', 'Seconds ago') as string,
      value: 's'
    },
    {
      text: lookupToken('euiTimeOptions.minutesAgo', 'Minutes ago') as string,
      value: 'm'
    },
    {
      text: lookupToken('euiTimeOptions.hoursAgo', 'Hours ago') as string,
      value: 'h'
    },
    {
      text: lookupToken('euiTimeOptions.daysAgo', 'Days ago') as string,
      value: 'd'
    },
    {
      text: lookupToken('euiTimeOptions.weeksAgo', 'Weeks ago') as string,
      value: 'w'
    },
    {
      text: lookupToken('euiTimeOptions.monthsAgo', 'Months ago') as string,
      value: 'M'
    },
    {
      text: lookupToken('euiTimeOptions.yearsAgo', 'Years ago') as string,
      value: 'y'
    },
    {
      text: lookupToken(
        'euiTimeOptions.secondsFromNow',
        'Seconds from now'
      ) as string,
      value: 's+'
    },
    {
      text: lookupToken(
        'euiTimeOptions.minutesFromNow',
        'Minutes from now'
      ) as string,
      value: 'm+'
    },
    {
      text: lookupToken(
        'euiTimeOptions.hoursFromNow',
        'Hours from now'
      ) as string,
      value: 'h+'
    },
    {
      text: lookupToken(
        'euiTimeOptions.daysFromNow',
        'Days from now'
      ) as string,
      value: 'd+'
    },
    {
      text: lookupToken(
        'euiTimeOptions.weeksFromNow',
        'Weeks from now'
      ) as string,
      value: 'w+'
    },
    {
      text: lookupToken(
        'euiTimeOptions.monthsFromNow',
        'Months from now'
      ) as string,
      value: 'M+'
    },
    {
      text: lookupToken(
        'euiTimeOptions.yearsFromNow',
        'Years from now'
      ) as string,
      value: 'y+'
    }
  ];

  const relativeRoundingLabels = {
    s: lookupToken(
      'euiTimeOptions.roundToSecond',
      'Round to the second'
    ) as string,
    m: lookupToken(
      'euiTimeOptions.roundToMinute',
      'Round to the minute'
    ) as string,
    h: lookupToken('euiTimeOptions.roundToHour', 'Round to the hour') as string,
    d: lookupToken('euiTimeOptions.roundToDay', 'Round to the day') as string,
    w: lookupToken('euiTimeOptions.roundToWeek', 'Round to the week') as string,
    M: lookupToken(
      'euiTimeOptions.roundToMonth',
      'Round to the month'
    ) as string,
    y: lookupToken('euiTimeOptions.roundToYear', 'Round to the year') as string
  };

  /**
   * Auto Refresh
   */
  const refreshUnitsOptions = timeUnitsOptions.filter(
    ({ value }) => value === 'h' || value === 'm' || value === 's'
  );

  /**
   * Used by both Quick Select ('Commonly used') and by PrettyDuration
   */
  const commonDurationRanges = [
    {
      start: 'now/d',
      end: 'now/d',
      label: lookupToken('euiTimeOptions.today', 'Today') as string
    },
    {
      start: 'now/w',
      end: 'now/w',
      label: lookupToken('euiTimeOptions.thisWeek', 'This week') as string
    },
    {
      start: 'now/M',
      end: 'now/M',
      label: lookupToken('euiTimeOptions.thisMonth', 'This month') as string
    },
    {
      start: 'now/y',
      end: 'now/y',
      label: lookupToken('euiTimeOptions.thisYear', 'This year') as string
    },
    {
      start: 'now-1d/d',
      end: 'now-1d/d',
      label: lookupToken('euiTimeOptions.yesterday', 'Yesterday') as string
    },
    {
      start: 'now/w',
      end: 'now',
      label: lookupToken('euiTimeOptions.weekToDate', 'Week to date') as string
    },
    {
      start: 'now/M',
      end: 'now',
      label: lookupToken(
        'euiTimeOptions.monthToDate',
        'Month to date'
      ) as string
    },
    {
      start: 'now/y',
      end: 'now',
      label: lookupToken('euiTimeOptions.yearToDate', 'Year to date') as string
    }
  ];

  return {
    timeTenseOptions,
    timeUnitsOptions,
    relativeOptions,
    relativeRoundingLabels,
    refreshUnitsOptions,
    commonDurationRanges
  };
};
