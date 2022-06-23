import { Moment } from 'moment';

export function isSameDay(moment1: Moment, moment2: Moment) {
  if (moment1 && moment2) {
    return moment1.isSame(moment2, 'day');
  } else {
    return !moment1 && !moment2;
  }
}

export function isSameTime(moment1: Moment, moment2: Moment) {
  if (moment1 && moment2) {
    return moment1.isSame(moment2, 'second');
  } else {
    return !moment1 && !moment2;
  }
}

export function isDayDisabled(
  day,
  { minDate, maxDate, excludeDates, includeDates, filterDate } = {}
) {
  return (
    (minDate && day.isBefore(minDate, 'day')) ||
    (maxDate && day.isAfter(maxDate, 'day')) ||
    (excludeDates &&
      excludeDates.some((excludeDate) => isSameDay(day, excludeDate))) ||
    (includeDates &&
      !includeDates.some((includeDate) => isSameDay(day, includeDate))) ||
    (filterDate && !filterDate(day.clone())) ||
    false
  );
}

export function isOutOfBounds(day, { minDate, maxDate } = {}) {
  return (
    (minDate && day.isBefore(minDate, 'day')) ||
    (maxDate && day.isAfter(maxDate, 'day'))
  );
}
