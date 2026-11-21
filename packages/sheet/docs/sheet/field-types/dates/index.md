---
title: Dates and times
order: 33
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: dates and times"/>
<EuiSpacer @size="l" />

<EuiText>

`date` stores an ISO date (`2026-11-19`), `dateTime` an instant as a UTC
ISO string, shown and typed in the field's zone. Both read day-first or
month-first text (`dateOrder`) and take a `min` and a `max`.

- **Date and time**: one stored format, an instant in UTC, so it orders
  as text and any backend reads it; the zone is the field's, not the
  value's. Shown as `DD/MM/YYYY HH:mm` (or the field's order, a 12-hour
  clock, seconds) in `timeZone`, and copied as the ISO string, so a copy
  pasted into another zone's column is the same instant. Typed text is
  never read with `Date` (it depends on the browser's locale). A wall
  clock that does not exist in the zone (the hour skipped when DST
  starts) moves forward by the gap; one that happens twice (when DST
  ends) is the first. An unknown zone name shows the values in UTC and
  makes every value invalid. Typing a digit opens a text input; Enter,
  F2, a double-click or the calendar icon the browser's date-and-time
  picker, in the field's zone. A fill continues one value by a day (the
  same time in the zone), two or more by their step. `date` is unchanged.

## Related

- [All field types](/docs/sheet/docs/sheet/field-types)
- [Custom field types and editors](/docs/sheet/docs/sheet/field-types/custom-types): another date picker
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
