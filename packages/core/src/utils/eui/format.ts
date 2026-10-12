/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

// Kept verbatim from upstream.
/* eslint-disable @typescript-eslint/no-base-to-string, @typescript-eslint/restrict-template-expressions */

// Port of upstream EUI 123.1.0 `services/format`. `formatNumber` without a
// `format` matches upstream; upstream formats `format` strings with
// `numeral`, which Ember EUI does not depend on, so here the decimal/integer
// aliases use `Intl.NumberFormat` (other numeral patterns are not supported).

import moment from 'moment';

import {
  isArray,
  isBoolean,
  isDate,
  isFunction,
  isNaN,
  isNil,
  isNumber,
  isString
} from './search-bar/predicate.ts';

type CalendarOptions = moment.CalendarSpec & {
  refTime?: moment.MomentInput;
};

const calendar = (value: moment.MomentInput, options: CalendarOptions = {}) => {
  const refTime = options.refTime;
  return moment(value).calendar(refTime, options);
};

export const dateFormatAliases = {
  date: 'D MMM YYYY',
  longDate: 'DD MMMM YYYY',
  shortDate: 'D MMM YY',
  dateTime: 'D MMM YYYY HH:mm',
  longDateTime: 'DD MMMM YYYY HH:mm:ss',
  shortDateTime: 'D MMM YY HH:mm',
  dobShort: 'Do MMM YY',
  dobLong: 'Do MMMM YYYY',
  iso8601: 'YYYY-MM-DDTHH:mm:ss.SSSZ',
  calendar,
  calendarDateTime: (
    value: moment.MomentInput,
    options: moment.CalendarSpec
  ) => {
    return calendar(value, {
      sameDay: '[Today at] H:mmA',
      nextDay: '[Tomorrow at] H:mmA',
      nextWeek: 'dddd [at] H:mmA',
      lastDay: '[Yesterday at] H:mmA',
      lastWeek: '[Last] dddd [at] H:mmA',
      sameElse: 'Do MMM YYYY [at] H:mmA',
      ...options,
    });
  },
  calendarDate: (value: moment.MomentInput, options: moment.CalendarSpec) => {
    return calendar(value, {
      sameDay: '[Today]',
      nextDay: '[Tomorrow]',
      nextWeek: 'dddd',
      lastDay: '[Yesterday]',
      lastWeek: '[Last] dddd',
      sameElse: 'Do MMM YYYY',
      ...options,
    });
  },
};

type DateFormat = keyof typeof dateFormatAliases;

interface FormatDateConfig {
  format: DateFormat;
  nil: string;
  options: any;
}

function isStringADateFormat(x: string): x is DateFormat {
  return dateFormatAliases.hasOwnProperty(x);
}

function instanceOfFormatDateConfig(x: any): x is Partial<FormatDateConfig> {
  return (
    typeof x === 'object' &&
    (x.hasOwnProperty('format') ||
      x.hasOwnProperty('nil') ||
      x.hasOwnProperty('options'))
  );
}

export const formatDate: (
  value?: moment.MomentInput,
  dateFormatKeyOrConfig?: DateFormat | string | Partial<FormatDateConfig>
) => string = (value, dateFormatKeyOrConfig = 'dateTime') => {
  if (isString(dateFormatKeyOrConfig)) {
    if (isNil(value)) {
      return '';
    }

    const dateFormatStrOrFunc = isStringADateFormat(dateFormatKeyOrConfig)
      ? dateFormatAliases[dateFormatKeyOrConfig]
      : dateFormatKeyOrConfig;

    if (isFunction(dateFormatStrOrFunc)) {
      return dateFormatStrOrFunc(value, {});
    }

    if (isString(dateFormatStrOrFunc)) {
      return moment(value).format(dateFormatStrOrFunc);
    }
  }

  if (instanceOfFormatDateConfig(dateFormatKeyOrConfig)) {
    const { format = 'dateTime', nil = '', options } = dateFormatKeyOrConfig;

    const dateFormat = dateFormatAliases[format] || format;

    if (isNil(value)) {
      return nil;
    }

    if (isFunction(dateFormat)) {
      return dateFormat(value, options);
    }

    if (isString(dateFormat)) {
      return moment(value).format(dateFormat);
    }
  }

  throw new Error(
    `Failed to format value using dateFormatKeyOrConfig: ${dateFormatKeyOrConfig}`
  );
};
export const formatBoolean = (
  value: boolean,
  { yes = 'Yes', no = 'No', nil = '' } = {}
): string => {
  if (isNil(value)) {
    return nil;
  }

  return value ? yes : no;
};
interface FormatTextOptions {
  nil: string;
}

export const formatText = (
  value?: any,
  options: Partial<FormatTextOptions> = { nil: '' }
) => {
  return isNil(value) ? options.nil : value.toString();
};

const numberFormatAliases: { [alias: string]: Intl.NumberFormatOptions } = {
  decimal1: { minimumFractionDigits: 1, maximumFractionDigits: 1 },
  decimal2: { minimumFractionDigits: 2, maximumFractionDigits: 2 },
  decimal3: { minimumFractionDigits: 3, maximumFractionDigits: 3 },
  integer: { maximumFractionDigits: 0 }
};

interface FormatNumberConfig {
  format: string;
  nil: string;
  round: boolean;
}

export const formatNumber = (
  value?: number | null,
  numberFormatOrConfig: string | Partial<FormatNumberConfig> = {}
) => {
  let format;
  let nil = '';
  let round;

  if (isString(numberFormatOrConfig)) {
    format = numberFormatOrConfig;
  } else {
    format = numberFormatOrConfig.format;
    nil = numberFormatOrConfig.nil || '';
    round = numberFormatOrConfig.round;
  }

  if (!format) {
    return isNil(value) ? nil : value!.toString();
  }

  if (isNil(value)) return nil;
  // Ember: `Intl` stands in for upstream's numeral aliases (en-US grouping)
  const options = numberFormatAliases[format] ?? {};
  const digits = options.maximumFractionDigits ?? 0;
  const factor = 10 ** digits;
  const rounded = (round ? Math.round : Math.floor)(value! * factor) / factor;
  return new Intl.NumberFormat('en-US', options).format(rounded);
};

export const formatAuto = (value: any): string => {
  if (isNil(value) || isNaN(value)) {
    return '';
  }

  if (isString(value)) {
    return formatText(value);
  }

  if (isDate(value)) {
    return formatDate(value);
  }

  if (isBoolean(value)) {
    return formatBoolean(value);
  }

  if (isNumber(value)) {
    return formatNumber(value);
  }

  if (isArray(value)) {
    return Array.isArray(value)
      ? value.map((item) => formatAuto(item)).join(', ')
      : formatAuto(value);
  }

  // TODO not sure if we want that.. the (+) is that we show something, the (-) is that it's very technical
  return JSON.stringify(value);
};
