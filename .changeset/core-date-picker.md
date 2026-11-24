---
'@ember-eui/core': minor
---

New `EuiDatePicker`, a port of upstream's date picker, without moment.

- **Values are strings:** `YYYY-MM-DD` for a date, a UTC ISO instant with `@showTimeSelect`, `HH:mm` with `@showTimeSelectOnly`. A `Date` or a moment is read too; `@onChange` always gets a string.
- **Calendar:** a text input opens it in a popover, or `@inline={{true}}` shows it in the page. It's a keyboard-accessible grid with month and year selects. Names, the first day of the week and the date order come from `@locale`, through the browser's `Intl` (or `componentDefaults.EuiDatePicker.locale`).
- **Typed input** is committed on Enter, on blur or on a pick, never while typing. Text that isn't a date, or names a day that can't be chosen, stays in the input with the invalid look and calls `@onInputError`.
- **Limits:** `@minDate`, `@maxDate`, `@excludeDates`, `@includeDates`, `@filterDate`, `@openToDate`, `@dayClassName`, plus `@onClear`, the form states, `<:prepend>`, `<:append>` and `@controlOnly`. It works inside modals and flyouts.
- **Time:** `@showTimeSelect` adds a time list, shown and chosen as a wall clock in `@timeZone`. That can be `'local'`, `'utc'`, an IANA name, or a fixed offset such as `'-03:00'` (upstream's `utcOffset`). A time missing on a DST change day moves forward, and a repeated one means its first occurrence. Also `@timeIntervals`, `@injectTimes`, `@minTime`, `@maxTime`, `@excludeTimes`, `@seconds`, `@hour12`, and `@adjustDateOnChange` (default `false`).
- **Phones and Capacitor:** on a coarse pointer, or when `window.Capacitor.isNativePlatform()` is true, it renders the OS input (`date`, `datetime-local` or `time`) with the same arguments and value strings. Every value the OS returns is checked. Choose the path with `@native` (`'auto'`, `true` or `false`) or `componentDefaults.EuiDatePicker.native`. Auto keeps the calendar when an argument the OS picker can't honour is given.
- **Ranges:** inside `EuiDatePickerRange` it takes the range's states, as upstream's `startDateControl` and `endDateControl` do. `@selectsStart`, `@selectsEnd`, `@startDate` and `@endDate` highlight the range and preview it from the hovered or focused day.
- **`<:trigger>`** (upstream `customInput`) opens the calendar from an element of your own.

`EuiSuperDatePicker`'s Absolute tab now uses this calendar and time list. Its arguments and values are unchanged. The tab's calendar:

- picks January days shown in December's or February's grid in January;
- changes the days shown when the year select changes, and no longer moves the selected day when you change month;
- follows a typed date;
- names months and weekdays in `@locale`'s language (else moment's global locale) and starts the week on its first day;
- keeps the time of day when a day is picked;
- works with the keyboard.

`@utcOffset` and `@timeFormat` now reach the tab, as upstream passes them, on `EuiSuperDatePicker` and on `EuiDatePopoverButton`. The offset marks today's date; `@timeFormat` with `h` or `a` gives a 12-hour list, and with `s`, seconds.

Also: a press inside a popover opened from a flyout that closes on outside clicks no longer closes the flyout.
