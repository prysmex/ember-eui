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
  day: Moment,
  {
    minDate,
    maxDate,
    excludeDates,
    includeDates,
    filterDate
  }: {
    minDate?: Moment;
    maxDate?: Moment;
    excludeDates?: Moment[];
    includeDates?: Moment[];
    filterDate?: (day: Moment) => boolean;
  } = {}
) {
  return (
    (minDate && day.isBefore(minDate, 'day')) ||
    (maxDate && day.isAfter(maxDate, 'day')) ||
    (excludeDates &&
      excludeDates.some((excludeDate: Moment) =>
        isSameDay(day, excludeDate)
      )) ||
    (includeDates &&
      !includeDates.some((includeDate: Moment) =>
        isSameDay(day, includeDate)
      )) ||
    (filterDate && !filterDate(day.clone())) ||
    false
  );
}

export function isOutOfBounds(
  day: Moment,
  { minDate, maxDate }: { minDate?: Moment; maxDate?: Moment } = {}
) {
  return (
    (minDate && day.isBefore(minDate, 'day')) ||
    (maxDate && day.isAfter(maxDate, 'day'))
  );
}
