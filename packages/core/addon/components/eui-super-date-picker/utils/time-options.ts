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
      text: lookupToken('euiTimeOptions.secondsAgo', 'Seconds ago'),
      value: 's'
    },
    {
      text: lookupToken('euiTimeOptions.minutesAgo', 'Minutes ago'),
      value: 'm'
    },
    {
      text: lookupToken('euiTimeOptions.hoursAgo', 'Hours ago'),
      value: 'h'
    },
    {
      text: lookupToken('euiTimeOptions.daysAgo', 'Days ago'),
      value: 'd'
    },
    {
      text: lookupToken('euiTimeOptions.weeksAgo', 'Weeks ago'),
      value: 'w'
    },
    {
      text: lookupToken('euiTimeOptions.monthsAgo', 'Months ago'),
      value: 'M'
    },
    {
      text: lookupToken('euiTimeOptions.yearsAgo', 'Years ago'),
      value: 'y'
    },
    {
      text: lookupToken('euiTimeOptions.secondsFromNow', 'Seconds from now'),
      value: 's+'
    },
    {
      text: lookupToken('euiTimeOptions.minutesFromNow', 'Minutes from now'),
      value: 'm+'
    },
    {
      text: lookupToken('euiTimeOptions.hoursFromNow', 'Hours from now'),
      value: 'h+'
    },
    {
      text: lookupToken('euiTimeOptions.daysFromNow', 'Days from now'),
      value: 'd+'
    },
    {
      text: lookupToken('euiTimeOptions.weeksFromNow', 'Weeks from now'),
      value: 'w+'
    },
    {
      text: lookupToken('euiTimeOptions.monthsFromNow', 'Months from now'),
      value: 'M+'
    },
    {
      text: lookupToken('euiTimeOptions.yearsFromNow', 'Years from now'),
      value: 'y+'
    }
  ];

  const relativeRoundingLabels = {
    s: lookupToken('euiTimeOptions.roundToSecond', 'Round to the second'),
    m: lookupToken('euiTimeOptions.roundToMinute', 'Round to the minute'),
    h: lookupToken('euiTimeOptions.roundToHour', 'Round to the hour'),
    d: lookupToken('euiTimeOptions.roundToDay', 'Round to the day'),
    w: lookupToken('euiTimeOptions.roundToWeek', 'Round to the week'),
    M: lookupToken('euiTimeOptions.roundToMonth', 'Round to the month'),
    y: lookupToken('euiTimeOptions.roundToYear', 'Round to the year')
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
      label: lookupToken('euiTimeOptions.today', 'Today')
    },
    {
      start: 'now/w',
      end: 'now/w',
      label: lookupToken('euiTimeOptions.thisWeek', 'This week')
    },
    {
      start: 'now/M',
      end: 'now/M',
      label: lookupToken('euiTimeOptions.thisMonth', 'This month')
    },
    {
      start: 'now/y',
      end: 'now/y',
      label: lookupToken('euiTimeOptions.thisYear', 'This year')
    },
    {
      start: 'now-1d/d',
      end: 'now-1d/d',
      label: lookupToken('euiTimeOptions.yesterday', 'Yesterday')
    },
    {
      start: 'now/w',
      end: 'now',
      label: lookupToken('euiTimeOptions.weekToDate', 'Week to date')
    },
    {
      start: 'now/M',
      end: 'now',
      label: lookupToken('euiTimeOptions.monthToDate', 'Month to date')
    },
    {
      start: 'now/y',
      end: 'now',
      label: lookupToken('euiTimeOptions.yearToDate', 'Year to date')
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
