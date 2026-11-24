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

Time selection (`@showTimeSelect`, `@showTimeSelectOnly`) is not available
yet; this version picks days.

</EuiText>

<EuiHorizontalRule />

<EuiText>

## Values

`@value` and `@onChange` use `YYYY-MM-DD` strings, such as `'2026-11-24'`.
`null` means no value. `@onChange` is never called with a day that cannot be
chosen, and never while the user types.

A day is a calendar date, not an instant. A string keeps it the same in every
time zone, it is ready for JSON, and it is what `<input type="date">` uses.
A `Date` or a moment for a day is a midnight in some zone, which is how dates
shift by one day between a browser and a server.

`@minDate`, `@maxDate`, `@openToDate`, `@excludeDates` and `@includeDates`
take the same strings. `@filterDate` and `@dayClassName` are called with
them.

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
`@maxDate`, `@openToDate`, `@excludeDates` and `@includeDates`, and reads
its calendar day in `@timeZone` (the browser's zone by default). The picker
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

A UTC moment (`moment.utc(…)`) names a day in UTC: pass
`@timeZone="utc"` so the picker reads that day. An invalid `Date` or moment
is treated as no value, and the picker shows the invalid look. In
development, the picker logs a notice saying which day it read.

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
  returns to the input.

## Upstream differences

| | Upstream | Ember EUI |
| --- | --- | --- |
| Value | `selected`, a moment; `onChange(moment)` | `@value`, `YYYY-MM-DD` (a `Date` or a moment is read too); `@onChange(string)` |
| Format | `dateFormat`, a moment format | `@dateOrder`; the text is always numeric, so it reads back |
| Typing | `onChange` on each keystroke that parses (not strict) | Committed on Enter, blur or pick; strict; errors are shown, not silently reverted |
| Locale | moment locales | `@locale`, a BCP 47 tag for `Intl`; `@firstDayOfWeek` |
| `utcOffset` | a fixed offset for "today" | `@timeZone`: `'local'`, `'utc'` or an IANA name |
| Home, End | previous, next year | start, end of the week (WAI-ARIA); Shift+PageUp and Shift+PageDown move a year |
| Month and year | custom dropdowns | two native selects |
| Calendar markup | a listbox of options | a WAI-ARIA grid; each day is named by its full date |
| Classes | `className`, `calendarClassName`, `popperClassName` | `class` (on the input), `@calendarClass`, `@popoverClass` (on the popover panel) |
| `append`, `prepend` | props | `<:append>` and `<:prepend>` blocks |
| `data-test-subj` | on the wrapper; `-input`, `-clear`, `-popover` on the parts | on the input, like every attribute |
| Not yet | `showTimeSelect`, `showTimeSelectOnly`, time limits, `customInput`, `adjustDateOnChange` | later versions |

</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiDatePicker

A date picker (upstream `EuiDatePicker`): a text input that opens a
calendar in a popover, or the calendar alone with `@inline`. Values are
`YYYY-MM-DD` strings; a `Date` or a moment is read too. Typed text is
committed on Enter, on blur and on a pick. Attributes go to the input, or
to the calendar with `@inline`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@value` | `DateInput \| null` |  | The value, `YYYY-MM-DD`. Also a `Date` or a moment: its day in `@timeZone` is read. `null` or `undefined` for none. |
| `@onChange` | `(value: string \| null) => void` |  | Called with the new value, `YYYY-MM-DD`, or `null` when the text is emptied. Never with a disabled day, never per keystroke. |
| `@onClear` | `() => void` |  | Shows the clear button while there is a value; empty the value there. |
| `@onInputError` | `(error: EuiDatePickerInputError) => void` |  | Called when committed text cannot be read, or names a day that cannot be chosen. `@onChange` is not called then. |
| `@inline` | `boolean` |  | Shows the calendar in the page instead of the text input and the popover. |
| `@shadow` | `boolean` | `true` | With `@inline`: the raised frame. |
| `@shouldCloseOnSelect` | `boolean` | `true` | Closes the popover after a day is picked. |
| `@popoverPlacement` | `PopoverAnchorPosition` | `'downLeft'` | Where the popover opens, any `EuiPopover` `@anchorPosition`. |
| `@timeZone` | `'local' \| 'utc' \| (string & {})` | `'local'` | `'local'`, `'utc'` or an IANA name: the zone of "today", and the day of a `Date` or a moment. |
| `@locale` | `string` | the document's language, then the browser's | BCP 47 tag for names and defaults. |
| `@dateOrder` | `DateOrder` | the order of `@locale` | The order typed and shown: `'dmy'` (`24/11/2026`), `'mdy'` (`11/24/2026`) or `'ymd'` (`2026-11-24`). |
| `@firstDayOfWeek` | `Weekday` | `@locale`'s | The first day of the week, 0 (Sunday) to 6. |
| `@minDate` | `DateInput \| null` |  | Days before are disabled (`YYYY-MM-DD`, a `Date` or a moment). |
| `@maxDate` | `DateInput \| null` |  | Days after are disabled (`YYYY-MM-DD`, a `Date` or a moment). |
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
| `@iconType` | `string` | `'calendar'` | The icon's type, anything `EuiIcon`'s `@type` accepts. |
| `@controlOnly` | `boolean` |  | Renders the input and its popover without the form control layout (no icon, clear button, prepend or append), e.g. inside `EuiDatePickerRange`. |
| `@inputRef` | `(element: HTMLInputElement \| null) => void` |  | Called with the `<input>` element once rendered. |

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. |
| `<:append>` | Content after the input; yields the class to put on it and the input id. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>` / `<div>`.

</EuiText>
<!-- api:end -->
