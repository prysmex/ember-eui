---
title: Date picker
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Date picker"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiDatePicker` is a text input that opens a calendar in a popover, or the
calendar alone with `@inline={{true}}`. It is a port of upstream's
`EuiDatePicker`: the same look, the same class names, a keyboard-accessible
calendar grid. Unlike upstream, it does not use moment: the value is a
plain `YYYY-MM-DD` string, and names come from the browser's `Intl`.

At minimum, pass `@value` and `@onChange`.

```hbs
<EuiFormRow @label="Due date" @id="due">
  <EuiDatePicker @id="due" @value={{this.due}} @onChange={{this.setDue}} />
</EuiFormRow>
```

With `@showTimeSelect={{true}}` a time list sits beside the calendar and
the value is an instant; with `@showTimeSelectOnly={{true}}` the picker
chooses a time of day only.

</EuiText>

<EuiHorizontalRule />

<EuiText>

## Values

| Mode | Chosen by | `@value` and `@onChange` | Example |
| --- | --- | --- | --- |
| date | the default | `YYYY-MM-DD` | `'2026-11-24'` |
| date and time | `@showTimeSelect={{true}}` | an instant, a UTC ISO string | `'2026-11-24T15:30:00.000Z'` |
| time | `@showTimeSelectOnly={{true}}` | `HH:mm` (`HH:mm:ss` with `@seconds`) | `'09:30'` |

`null` means no value, in every mode. `@onChange` is never called with a day
or a time that cannot be chosen, and never while the user types. An instant
may also come in with an offset (`'2026-11-24T17:30:00+02:00'`); it always
goes out as `Z`.

A day is a calendar date, not an instant. A string keeps it the same in every
time zone, it is ready for JSON, and it is what `<input type="date">` uses.
A `Date` or a moment for a day is a midnight in some zone, which is how dates
shift by one day between a browser and a server.

`@minDate`, `@maxDate`, `@openToDate`, `@excludeDates` and `@includeDates`
take the same `YYYY-MM-DD` strings. `@filterDate` and `@dayClassName` are
called with them. With `@showTimeSelect`, `@minDate` and `@maxDate` may also
be instants: the times before or after them are disabled. `@minTime`,
`@maxTime`, `@excludeTimes` and `@injectTimes` take `HH:mm`.

To convert yourself:

```js
// from a Date, its local day (not toISOString(), which is the UTC day)
const pad = (n) => String(n).padStart(2, '0');
const value = `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;

// to a moment, local midnight of that day
const day = moment(value, 'YYYY-MM-DD');
```

## Using moment or Date

The picker also accepts a `Date` or a moment for `@value`, `@minDate`,
`@maxDate`, `@openToDate`, `@excludeDates` and `@includeDates`. In date mode
it reads the calendar day in `@timeZone` (the browser's zone by default);
with `@showTimeSelect`, the instant (also for `@minDate` and `@maxDate`);
with `@showTimeSelectOnly`, the wall-clock time in `@timeZone`. The picker
recognises a moment by its shape and never imports moment, and it never
changes the object. `@onChange` still gets a string:

```gjs
import moment from 'moment';

class Due extends Component {
  @tracked due = moment();

  setDue = (value) => {
    this.due = value === null ? null : moment(value, 'YYYY-MM-DD');
  };

  <template>
    <EuiDatePicker @value={{this.due}} @onChange={{this.setDue}} />
  </template>
}
```

For a date and time, convert back with `moment(value)`; for a time,
`moment(value, 'HH:mm')`.

A UTC moment (`moment.utc(…)`) names a day in UTC: pass
`@timeZone="utc"` so the picker reads that day. An invalid `Date` or moment
is treated as no value: the picker shows the invalid look and, in
development, logs a warning. A valid one is read silently.

## Time zones and DST

`@timeZone` is a property of the field, not of the value: `'local'` (the
default), `'utc'`, an IANA name (`'America/New_York'`), or a fixed offset
from UTC (`'-03:00'`, `'+05:30'`; also written `'+0530'` or `'+05'`). An
instant is shown, typed and chosen as a wall clock in that zone; the value
stays the instant.

- **A time that does not exist** (the spring change, a gap) is left out of
  the time list; typed, it moves forward by the gap: `02:30` on the New York
  spring day becomes `03:30`, and the input then shows `03:30`.
- **A time that exists twice** (the autumn change, an overlap) is listed
  once and means its first occurrence. A value at the second occurrence
  stays as it is until the user picks another wall clock: opening, closing
  and leaving the input emit nothing. The second occurrence cannot be
  picked.
- **Picking a day** keeps the wall time of the value, its seconds too; a
  day that lacks that time moves it forward. Without a value, a day is its
  midnight, or its first time that can be chosen.
- **Picking a time** sets hours and minutes, and zeroes seconds and
  milliseconds.
- **A fixed offset** has neither gaps nor overlaps. The `Etc/GMT±N` IANA
  names are fixed offsets too, with the sign inverted: `Etc/GMT+3` is
  UTC−03:00.
- **An unknown zone** gives the invalid look and a development warning; the
  value is shown as UTC.

## Typed input

The text in the input is committed when the user presses Enter, leaves the
input, or picks a day; never on each keystroke. One rule: the picker never
guesses. Text names exactly one day, or it is an error.

| Typed | Result |
| --- | --- |
| `2026-11-24`, `2026/11/24` | Always accepted, whatever the order. |
| `3/4/2026`, `3.4.2026`, `3-4-2026` | 3 April with `@dateOrder="dmy"`, 4 March with `"mdy"`. The same separator twice; leading zeros are optional. |
| `24/11/26` | A two-digit year is the one within 50 years of this year (in 2026: 1976 to 2075). The input then shows `24/11/2026`. |
| `31/02/2026`, `13/13/2026` | Not a date: no rollover into March, no month 13. |
| `24/11`, `24/11/202` | Incomplete: an error when committed. While typing, nothing happens. |
| (empty) | `@onChange(null)`. |
| `24/11/2026 15:30`, `24/11/2026, 3:30 pm` | With `@showTimeSelect`: a date, a space or `, `, then a time; a wall clock in `@timeZone`. A date alone is midnight. |
| `2026-11-24T15:30:00Z`, `…T17:30+02:00` | With `@showTimeSelect`: that instant. |
| `15:30`, `15:30:45`, `15.30`, `3:30 pm`, `3 pm`, `3p` | A time. `15` alone is not one; with `am` or `pm` the hour is 1 to 12. Seconds are kept only with `@seconds`. |

- **Order.** `@dateOrder` (`'dmy'`, `'mdy'` or `'ymd'`) decides how
  `3/4/2026` reads and how the value is shown. It defaults to the order of
  `@locale`, which defaults to the page's `lang`, then the browser's
  language.
- **While typing**, nothing is emitted. Once the text is a whole date, the
  calendar shows its month.
- **On commit**, a readable day that can be chosen calls `@onChange`, and
  the text is rewritten in the display format (`24/11/2026`, `11/24/2026` or
  `2026-11-24`).
- **On an error**, the text stays, the input gets the invalid look and
  `aria-invalid`, and `@onInputError({ text, reason })` is called: `reason`
  is `'unreadable'`, `'min'`, `'max'` or `'disabled'`. The value does not
  change. Escape (with the calendar closed) brings back the value's text.
- **Keys in the input:** ArrowDown opens the calendar and moves focus into
  it; Enter commits and closes; Escape closes, then restores the text; Tab
  commits and moves on. In the calendar, arrows move by day and week, Home
  and End to the start and end of the week, PageUp and PageDown by month,
  Shift+PageUp and Shift+PageDown by year, Enter and Space pick, Escape
  returns to the input. Tab goes from the days to the time list, where
  ArrowUp and ArrowDown move, Home and End go to the first and last time,
  and Enter and Space pick.
- **Display format:** the date as above, then the time as `15:30` or
  `3:30 pm` (`@hour12`, by default from `@locale`), with seconds when
  `@seconds`. The default placeholder spells it: `DD/MM/YYYY HH:mm`.

## Phones and Capacitor

On a phone the calendar's 32 px days are small targets, and the operating
system's own picker is the one people know. So the picker renders the OS
input there: `<input type="date">`, `datetime-local` with
`@showTimeSelect`, `time` with `@showTimeSelectOnly`, inside the same form
control layout. The template does not change.

The path is chosen once, when the picker is created, in this order:

1. `@inline={{true}}` shows the calendar: there is no native inline picker.
2. `@native={{true}}` or `@native={{false}}`.
3. `componentDefaults.EuiDatePicker.native` in `euiConfig`, when `true` or
   `false`.
4. Auto: the OS input in a Capacitor app on a device
   (`window.Capacitor.isNativePlatform()`; core does not import Capacitor)
   and when the primary pointer is coarse (`(pointer: coarse)`: a phone or
   a tablet, not a laptop with a touch screen); the calendar otherwise, and
   always when `@filterDate`, `@excludeDates`, `@includeDates`,
   `@excludeTimes`, `@injectTimes` or `@dayClassName` is given, since the
   OS picker cannot show them. A server-rendered page renders the calendar
   path's text input, and the OS input takes its place once the page is
   running in the browser.

```js
// every picker of the app on the calendar, phones included
this.euiConfig.updateConfig({
  componentDefaults: { EuiDatePicker: { native: false } }
});
```

What differs on the native path:

| | Calendar | Native |
| --- | --- | --- |
| Values | strings | the same strings; a date and time is the wall clock in `@timeZone`, converted with the same DST rules |
| Display | `@dateOrder`, `@hour12`, `@locale`, `@placeholder` | the OS decides; no placeholder |
| `@minDate`, `@maxDate`, `@minTime`, `@maxTime` | disabled days and times | `min` and `max` on the input; the picker checks every value itself, since not every OS enforces them |
| `@filterDate`, `@excludeDates`, `@includeDates`, `@excludeTimes` | disabled days and times | only with `@native={{true}}`, with a development warning: a value they refuse is an input error |
| `@timeIntervals` | the list's entries | no effect: `step` is a minute (a second with `@seconds`). A time off the step would be invalid to the browser (the invalid look, a form that does not submit) while the picker accepts it, as it accepts it typed |
| `@injectTimes`, `@dayClassName`, `@openToDate`, `@popoverPlacement`, `@shouldCloseOnSelect`, `@adjustDateOnChange` | applied | no effect |
| `@onChange` | on Enter, blur or a pick | on the input's `change`. Keyboard entry in a desktop browser changes the value per segment: typing a year emits `0002`, `0020`, `0202`, then `2026` |
| `@onInputError` | on commit | when focus leaves the input, for the value left in it; the invalid look shows at once |
| A half-filled field | an input error on commit | an input error (`'unreadable'`) when focus leaves; nothing while editing |
| `@readOnly` | a read-only text input | the same read-only text input, with the value formatted, since some engines open the OS picker on a read-only date input |
| Icon | EUI's | EUI's, a button that opens the OS picker (`showPicker()`), and the browser's own indicator is hidden; without EUI's icon (`@showIcon={{false}}`, `@controlOnly`) the browser's indicator stays |

### Checking on devices

The OS pickers differ by system and version, and none of them runs in a
desktop browser's test run. Before relying on the native path, check it on
a real iPhone (WKWebView) and a real Android phone (Android System WebView),
in the Capacitor app and in the mobile browser:

- **The picker opens** from a tap anywhere in the field, and from EUI's icon
  (`showPicker()`); in a flyout and in a modal too.
- **Looks:** the empty field has the height of a text field, its
  `mm/dd/yyyy` (or the OS's empty text) sits at the start in the placeholder
  colour, the value is aligned like a text field's, and the disabled and
  invalid states read clearly; in light and dark mode, and the OS picker
  follows the dark mode.
- **A value round-trips:** pick a date, a date and time, a time; `@onChange`
  gets the same strings as on a desktop, and the field shows the value after
  a re-render. With `@seconds`, the picker offers seconds.
- **Clear:** EUI's clear button empties the field; the OS picker's own clear
  or reset gives `@onChange(null)`.
- **`min` and `max`:** the OS picker greys out or refuses days outside the
  limits (the default range is the years 0001 to 9999); a value outside them
  that the OS lets through shows the invalid look and does not change the
  value.
- **When `@onInputError` fires:** it is called when focus leaves the input.
  Check that closing the OS picker (Done, or a tap outside) moves focus away;
  if it does not, the error comes only when the user leaves the field.
- **Time zones:** with `@showTimeSelect` and a `@timeZone` other than the
  phone's, the field shows the wall clock in that zone, and a chosen time is
  stored as the instant in that zone; also on a DST change day.
- **A screen reader** (VoiceOver, TalkBack) announces the field's label, its
  value, the invalid state, and EUI's icon button as "Choose date".

## Upstream differences

| | Upstream | Ember EUI |
| --- | --- | --- |
| Value | `selected`, a moment; `onChange(moment)` | `@value`, `YYYY-MM-DD` (a `Date` or a moment is read too); `@onChange(string)` |
| Format | `dateFormat`, a moment format | `@dateOrder`; the text is always numeric, so it reads back |
| Typing | `onChange` on each keystroke that parses (not strict) | Committed on Enter, blur or pick; strict; errors are shown, not silently reverted |
| Locale | moment locales | `@locale`, a BCP 47 tag for `Intl`; `@firstDayOfWeek` |
| `utcOffset` | a fixed offset in minutes | `@timeZone`: `'local'`, `'utc'`, an IANA name, or a fixed offset such as `'-03:00'` |
| `timeFormat` | a moment format | `@hour12` and `@seconds`; the text is always numeric |
| Time values | moments | `@showTimeSelect`: a UTC ISO instant; `@showTimeSelectOnly`: `HH:mm`; `@minTime`, `@maxTime`, `@excludeTimes`, `@injectTimes`: `HH:mm` |
| DST | moment's rules | a missing time moves forward, a repeated time is its first; a stored second occurrence is kept |
| Home, End | previous, next year | start, end of the week (WAI-ARIA); Shift+PageUp and Shift+PageDown move a year |
| Month and year | custom dropdowns | two native selects |
| Calendar markup | a listbox of options | a WAI-ARIA grid; each day is named by its full date |
| Classes | `className`, `calendarClassName`, `popperClassName` | `class` (on the input), `@calendarClass`, `@popoverClass` (on the popover panel) |
| `append`, `prepend` | props | `<:append>` and `<:prepend>` blocks |
| `data-test-subj` | on the wrapper; `-input`, `-clear`, `-popover` on the parts | on the input, like every attribute |
| `adjustDateOnChange` | `true` by default | `false` by default: the value changes when the user picks, not while they look |
| Not yet | `customInput` | a later version |

</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiDatePicker

A date picker (upstream `EuiDatePicker`): a text input that opens a
calendar in a popover, or the calendar alone with `@inline`; with
`@showTimeSelect` a time list too, with `@showTimeSelectOnly` the time
list alone. Values are strings: `YYYY-MM-DD`, a UTC ISO instant, or
`HH:mm`; a `Date` or a moment is read too. Typed text is committed on
Enter, on blur and on a pick. Attributes go to the input, or to the
calendar with `@inline`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@value` | `DateInput \| null` |  | The value: `YYYY-MM-DD`; with `@showTimeSelect` an instant, a UTC ISO string (`2026-11-24T15:30:00.000Z`, or with an offset); with `@showTimeSelectOnly` a time, `HH:mm` (or `HH:mm:ss`). Also a `Date` or a moment: its day, its instant or its time in `@timeZone` is read. `null` or `undefined` for none. |
| `@onChange` | `(value: string \| null) => void` |  | Called with the new value (`YYYY-MM-DD`, a UTC ISO instant ending in `Z`, or `HH:mm`), or `null` when the text is emptied. Never with a day or time that cannot be chosen, never per keystroke. |
| `@onClear` | `() => void` |  | Shows the clear button while there is a value; empty the value there. |
| `@onInputError` | `(error: EuiDatePickerInputError) => void` |  | Called when committed text cannot be read, or names a day or time that cannot be chosen. `@onChange` is not called then. |
| `@showTimeSelect` | `boolean` |  | A time list beside the calendar: the value becomes an instant, shown in `@timeZone`. |
| `@showTimeSelectOnly` | `boolean` |  | Only a time list, no calendar: the value becomes a time of day, `HH:mm`. Wins over `@showTimeSelect`. |
| `@timeIntervals` | `number` | `30` | Minutes between the entries of the time list, from midnight. |
| `@seconds` | `boolean` | `false` | Keep and show seconds: typed seconds are kept, and a time value is `HH:mm:ss`. |
| `@hour12` | `boolean` | `@locale`'s | A 12-hour clock (`3:30 pm`) in the input and the time list. |
| `@minTime` | `string \| null` |  | Times before it are disabled, `HH:mm`. |
| `@maxTime` | `string \| null` |  | Times after it are disabled, `HH:mm`. |
| `@excludeTimes` | `readonly string[] \| null` |  | These times are disabled, `HH:mm`. |
| `@injectTimes` | `readonly string[] \| null` |  | Extra entries in the time list, `HH:mm`, marked as injected. |
| `@inline` | `boolean` |  | Shows the calendar in the page instead of the text input and the popover. |
| `@shadow` | `boolean` | `true` | With `@inline`: the raised frame. |
| `@shouldCloseOnSelect` | `boolean` | `true` | Closes the popover after a day is picked (with `@showTimeSelect`, after a time is). |
| `@adjustDateOnChange` | `boolean` | `false` | Arrow keys and the month and year selects change the value at once, not only show another day (upstream's default is `true`). |
| `@popoverPlacement` | `PopoverAnchorPosition` | `'downLeft'` | Where the popover opens, any `EuiPopover` `@anchorPosition`. |
| `@timeZone` | `'local' \| 'utc' \| (string & {})` | `'local'` | `'local'`, `'utc'`, an IANA name (`'America/New_York'`) or a fixed offset (`'-03:00'`, upstream's `utcOffset`): the zone instants are shown and chosen in, the zone of "today", and of a `Date` or a moment. |
| `@locale` | `string` | `componentDefaults.EuiDatePicker.locale` in `euiConfig`, then the document's language, then the browser's | BCP 47 tag for names and defaults. |
| `@dateOrder` | `DateOrder` | the order of `@locale` | The order typed and shown: `'dmy'` (`24/11/2026`), `'mdy'` (`11/24/2026`) or `'ymd'` (`2026-11-24`). |
| `@firstDayOfWeek` | `Weekday` | `@locale`'s | The first day of the week, 0 (Sunday) to 6. |
| `@minDate` | `DateInput \| null` |  | Days before are disabled (`YYYY-MM-DD`, a `Date` or a moment). With `@showTimeSelect` also an instant (a `Date` or a moment counts as one): earlier times are disabled. |
| `@maxDate` | `DateInput \| null` |  | Days after are disabled (`YYYY-MM-DD`, a `Date` or a moment). With `@showTimeSelect` also an instant (a `Date` or a moment counts as one): later times are disabled. |
| `@excludeDates` | `readonly DateInput[] \| null` |  | These days are disabled. |
| `@includeDates` | `readonly DateInput[] \| null` |  | When given, only these days are enabled. |
| `@filterDate` | `((date: string) => boolean) \| null` |  | Called with `YYYY-MM-DD`; `false` disables the day. |
| `@openToDate` | `DateInput \| null` |  | The month shown when there is no value. |
| `@dayClassName` | `(date: string) => string \| null \| undefined` |  | Extra classes for a day, called with `YYYY-MM-DD` (upstream `dayClassName`). |
| `@calendarClass` | `string` |  | Extra classes on the calendar (upstream `calendarClassName`). |
| `@popoverClass` | `string` |  | Extra classes on the popover panel (upstream `popperClassName`). |
| `@id` | `string` | a random id | Id of the input, e.g. to match an `EuiFormRow`'s `@id`. |
| `@placeholder` | `string` | the display format spelled out (`DD/MM/YYYY`) | Placeholder text. |
| `@fullWidth` | `boolean` |  | Stretches the input to its container's width. |
| `@compressed` | `boolean` |  | Shorter input (32px instead of 40px). |
| `@isInvalid` | `boolean` |  | The invalid look; also shown for typed text that was refused and for a value that cannot be read. |
| `@isLoading` | `boolean` |  | Shows a spinner. |
| `@disabled` | `boolean` |  | Disables the input; nothing opens. |
| `@readOnly` | `boolean` |  | Read-only input; nothing opens. |
| `@showIcon` | `boolean` | `true` | The icon in the input. |
| `@iconType` | `string` | `'calendar'`, or `'clock'` with `@showTimeSelectOnly` | The icon's type, anything `EuiIcon`'s `@type` accepts. |
| `@controlOnly` | `boolean` |  | Renders the input and its popover without the form control layout (no icon, clear button, prepend or append), e.g. inside `EuiDatePickerRange`. |
| `@inputRef` | `(element: HTMLInputElement \| null) => void` |  | Called with the `<input>` element once rendered. |
| `@native` | `EuiDatePickerNative` | `componentDefaults.EuiDatePicker.native` in `euiConfig`, then `'auto'` | The OS picker instead of the calendar: `<input type="date">`, `datetime-local` (the wall clock in `@timeZone`) or `time`, with the same values. `'auto'` takes it in a Capacitor app on a device and when the primary pointer is coarse (a phone, a tablet), unless an argument the OS cannot honour is given (`@filterDate`, `@excludeDates`, `@includeDates`, `@excludeTimes`, `@injectTimes`, `@dayClassName`). `true` and `false` force a path; `@inline` always shows the calendar. Chosen once, when the picker is created. Every value the OS returns is checked as typed text is. |

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. |
| `<:append>` | Content after the input; yields the class to put on it and the input id. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>` / `<div>`.

</EuiText>
<!-- api:end -->
