# `EuiDatePicker` for `@ember-eui/core`: design

Design only. No code exists yet. Every path is relative to the repository
root unless it starts with `UP/`.

`UP/` is upstream EUI 123.1.0 as installed for core:
`node_modules/.pnpm/@elastic+eui@123.1.0_*/node_modules/@elastic/eui/es/components/date_picker/`.
The package ships compiled JavaScript only (`es/`), so upstream line numbers
are those of the compiled files.

## 1. Goal and non-goals

### Goal

One component, `<EuiDatePicker>`, in `@ember-eui/core`:

- a port of upstream `EuiDatePicker`: text input, calendar in a popover,
  optional time list, inline mode, the upstream look;
- on phones and in Capacitor it renders the native input instead
  (`type="date"`, `datetime-local`, `time`), with the same arguments and the
  same values;
- values are plain strings, with the semantics the sheet already uses;
- it is correct about time zones, DST, typed input and keyboard use;
- a host that does not import it pays nothing, and importing it does not
  pull in `moment`.

Apps can then stop using flatpickr and pikaday for ordinary date picking.

### Non-goals

- A range picked in one calendar (flatpickr's `mode="range"`), several
  dates in one field, week numbers, several months side by side. Upstream
  excludes the last two as well (`UP/date_picker.js:37-63`).
- Relative dates and quick ranges. That is `EuiSuperDatePicker`.
- Non-Gregorian calendars.
- Free text such as "tomorrow" or "5 March 2026".
- Removing `@ember-eui/flatpickr` or `@ember-eui/pikaday` (section 11).
- A moment-typed API (section 4.6 lists it as an alternative).

## 2. What upstream `EuiDatePicker` does

### 2.1 Structure

- `UP/date_picker.js` is a thin wrapper. It renders a `span.euiDatePicker`
  with an `EuiFormControlLayout` around the fork's `ReactDatePicker`
  (`UP/date_picker.js:201-224`).
- The calendar is a fork of `react-datepicker` 2.0.0, MIT, HackerOne
  (`UP/react-datepicker/original.package.json:6-7`; every fork file carries
  the MIT header, e.g. `UP/react-datepicker/src/index.js:16-38`). Elastic
  added the accessible mode, the focus traps and the EUI popover.
- The fork renders an `EuiFieldText` (`controlOnly`) as the anchor of an
  `EuiPopover` with `ownFocus: false`, no arrow, no padding, `buffer: 0`,
  `display: "block"` (`UP/react-datepicker/src/index.js:522-524`,
  `612-631`).
- Calendar parts: `calendar.js` (header, navigation, focus trap),
  `month.js`, `week.js`, `day.js`, `time.js`, and the month and year
  dropdowns (`month_dropdown*.js`, `year_dropdown*.js`).
- Styles: `UP/date_picker.styles.js` (wrapper and inline frame) and
  `UP/react_date_picker.styles.js` (the calendar, built with vanilla
  `@emotion/css` because the fork takes a class name).
- Everything is `moment`. Parsing is
  `moment(value, dateFormat, locale, strictParsing)` with
  `strictParsing: false` (`UP/react-datepicker/src/date_utils.js:79-85`,
  `UP/react-datepicker/src/index.js:673`).

### 2.2 Props of `EuiDatePicker`

From `UP/date_picker.js:1` and `:64-116`.

| Upstream prop | Default | What it does | In the Ember design |
| --- | --- | --- | --- |
| `selected` (moment) | | the value | `@value` (string), 4.2 |
| `onChange(moment \| null)` | | new value | `@onChange(string \| null)` |
| `onClear` | | shows the clear button while there is a value (`:207`) | same |
| `dateFormat` | `MM/DD/YYYY` (`:33`) | moment format of the input | replaced by `@dateOrder`, 5.3 |
| `timeFormat` | `hh:mm A` (`:34`) | moment format of times | replaced by `@hour12` |
| `locale` | i18n context (`:166`) | moment locale | `@locale`, a BCP 47 tag for `Intl` |
| `utcOffset` | | fixed offset for "now" and "today" | replaced by `@timeZone`, 5.2 |
| `showTimeSelect` | `false` | time list beside the calendar | same; the value becomes an instant |
| `showTimeSelectOnly` | | time list only; icon `clock` (`:196-197`) | same; the value becomes `HH:mm` |
| `minDate`, `maxDate` | | days outside are disabled | same, as strings |
| `minTime`, `maxTime` | | times outside are disabled | same, `HH:mm` |
| `excludeDates`, `filterDate` | | disabled days | same, strings |
| `injectTimes` | | extra entries in the time list | same, `HH:mm[]` |
| `openToDate` | | month shown when there is no value | same |
| `adjustDateOnChange` | `true` | arrow keys and the month and year dropdowns change the value at once | kept as an argument, default `false`; open question 6 |
| `shouldCloseOnSelect` | `true` | close after picking a day | same |
| `inline`, `shadow` | `false`, `true` | calendar in the page | same |
| `popoverPlacement` | `downLeft` | `EuiPopover` anchor position | same |
| `fullWidth`, `compressed`, `isInvalid`, `isLoading`, `readOnly`, `disabled`, `placeholder` | | form states | same |
| `showIcon`, `iconType` | `true`, `calendar` | icon in the layout (`:191-200`) | same |
| `append`, `prepend` | | input group | `<:append>` / `<:prepend>` blocks, as `EuiFieldText` |
| `controlOnly` | | no layout wrapper (`:190`) | same |
| `customInput` | | another element as the trigger | `<:trigger>` block, batch 6 |
| `dayClassName(moment)` | | class per day | `@dayClassName(date: string)` |
| `calendarClassName`, `popperClassName`, `className` | | classes | `@calendarClass`, `@popoverClass`, `class` via `...attributes` |
| `inputRef` | | the fork instance | `@inputRef(element)`, as `EuiFieldText` |

`isInvalid` is also set when `selected.isValid()` is false (`:118`). When
`showTimeSelect` is on and `dateFormat` is the default, the time format is
appended (`:133-135`). The wrapper forces `showMonthDropdown`,
`showYearDropdown`, `yearDropdownItemNumber: 7` and `accessibleMode`
(`:178-185`).

Fork props that reach it through `...rest` and matter here
(`UP/react-datepicker/src/index.js:678-780`): `selectsStart`, `selectsEnd`,
`startDate`, `endDate` (range highlight, `UP/react-datepicker/src/day.js:97-105`),
`includeDates`, `excludeTimes`, `includeTimes`, `timeIntervals` (default 30,
`:666`), `highlightDates`, `onSelect`, `onBlur`, `onFocus`, `onKeyDown`,
`onMonthChange`, `onYearChange`, `onInputError`, `onChangeRaw`,
`preventOpenOnFocus`, `strictParsing`, `id`, `name`, `autoFocus`, `required`,
`title`, `tabIndex`.

Kept: the four range props, `includeDates`, `excludeTimes`, `timeIntervals`,
`onInputError`. HTML attributes (`id`, `name`, `required`, `autofocus`,
`aria-*`) go to the input through `...attributes`. Dropped:
`highlightDates`, `includeTimes`, `onChangeRaw`, `onSelect`,
`preventOpenOnFocus`, `strictParsing` (parsing is always strict, 5.3), and
everything in upstream's `unsupportedProps`.

### 2.3 Behaviour

- **Opening.** Focus or a click on the input opens the calendar
  (`index.js:155-165`, `317-322`). Focus stays in the input.
- **Typing.** Each keystroke is parsed. If it parses, `onChange` fires at
  once (`index.js:208-227`). With non-strict moment parsing, partial text
  such as `1` already parses. An empty input fires `onChange(null)`.
- **Keys in the input** (`index.js:330-421`). Closed: ArrowDown or ArrowUp
  opens and enables the focus trap. Open, trap off: ArrowDown or Tab moves
  focus into the calendar; Escape or Enter closes.
- **Keys in the calendar** (`month.js:82-121`). Arrows move a day or a
  week. PageUp and PageDown move a month. Home and End move a **year**
  (`month.js:106-111`). Space and Enter select.
- **Selecting a day** keeps the time of the previous value
  (`index.js:259-267`), refuses disabled days (`index.js:256`), and closes
  unless `showTimeSelect` or `shouldCloseOnSelect={false}`
  (`index.js:242-246`).
- **Time list.** Wall times every `timeIntervals` minutes from midnight
  (`time.js:120-137`). Picking one sets hours and minutes and zeroes
  seconds (`index.js:295-316`).
- **Disabled days** (`date_utils.js:331-343`): before `minDate`, after
  `maxDate`, in `excludeDates`, not in `includeDates`, or refused by
  `filterDate`.
- **Focus trap.** `EuiFocusTrap` around the calendar, active once focus
  enters it, never inline (`calendar.js:524-532`). A custom non-input
  trigger traps from the start (`index.js:99`).
- **ARIA.** The month is `role="listbox"` with one tab stop and a live
  paragraph of instructions (`month.js:212-214`). Days are `role="option"`
  with `aria-label="day-N"` (`day.js:197-198`). The time list is a
  `listbox` (`time.js:283`). Month and year are custom "read view" buttons
  that open a second focus trap.

### 2.4 `EuiDatePickerRange`

Layout plus prop injection. It clones `startDateControl` and
`endDateControl` with `controlOnly`, `showIcon: false`, `inline`,
`compressed`, `fullWidth`, `readOnly`, `disabled`, `isInvalid`, the classes
`euiDatePickerRange__start` / `__end`, and `popoverPlacement: 'downRight'`
for the end (`UP/date_picker_range.js:60-106`). The range highlight comes
from the fork props `selectsStart`, `selectsEnd`, `startDate`, `endDate`
that the app passes to each picker. Upstream does not check that the end is
after the start.

### 2.5 `EuiSuperDatePicker`

Its "Absolute" tab renders `EuiDatePicker inline shadow={false}` with
`showTimeSelect`. Nothing else of it matters here.

### 2.6 Upstream tests and docs

Not in the npm package. Read from GitHub at tag `v123.1.0`:
`date_picker.test.tsx` (invalid `selected`, `onClear`, `compressed`,
`data-test-subj`, append and prepend, min and max with the dropdowns,
`popoverPlacement`, locale from prop and context), `date_picker.spec.tsx`
(inline: shadow, icons below, disabled, read-only),
`date_picker_range.test.tsx`, and `UP/date_picker.a11y.js:43-76` (axe after
opening, after arrow keys, after the dropdowns). The docs page's source
(`packages/website/docs/components/forms/date-and-time/date-picker.mdx`)
has these sections: states, time selection, locale, only specific dates and
times, open to a date, custom input, UTC offsets, inline, custom classes.

## 3. What ember-eui has now

| What | Where | Reuse |
| --- | --- | --- |
| Calendar markup with upstream's class names | `packages/core/src/components/eui-super-date-picker/date-popover/datetime-picker.gts:317-450` | Markup and class names: yes. Logic: no, see below. |
| Calendar styles, hand port of `react_date_picker.styles.js` | `packages/core/src/utils/eui/date-pickers.ts:165` (`euiReactDatePickerStyles`), `:96` (`euiDatePickerVariables`) | As is. They already style range, in-range, disabled, highlighted, time list items, injected and preselected times. |
| Wrapper styles | `euiDatePickerStyles`, `euiDatePickerRangeStyles` in `styles.generated.ts`, extracted by `scripts/generate-eui-styles.mjs:253-254` | As is. |
| `EuiDatePickerRange`, layout only | `packages/core/src/components/eui-date-picker-range.gts` | Stays the layout; gains a private context (4.5). |
| `EuiFieldText` | `packages/core/src/components/eui-field-text.gts` | Input classes, layout, `validatableControl`. `type="text"` comes before `...attributes` (`:97`, `:101`, `:128`, `:132`), which is why `type="date"` works today. |
| `EuiPopover` | `packages/core/src/components/eui-popover.gts` | `@ownFocus` (`:205`), positions, panel joins outer focus traps (`:1303`). |
| Input-anchored popover precedent | `packages/core/src/components/eui-input-popover.gts:232` | Same pattern: `@ownFocus={{false}}` and its own trap. |
| Focus traps across portals | `packages/core/src/-private/focus-trap-registry.ts:5-11` | A popover opened from a modal or flyout stays usable. |
| Context precedent | `packages/core/src/-private/eui-form-control-layout-context.ts:8-15`, `:37-41` | Pattern for the range context. |
| Date-only and instant semantics | `packages/sheet/src/core/field-types/date.ts`, `date-time.ts` | The rules and the algorithms (section 5). |
| Native inputs already used | `packages/sheet/src/-private/editors/date-editor.gts`, `date-time-editor.gts:62` | Precedent for the native path. |
| Coarse pointer check | `packages/sheet/src/-private/sheet/edit.ts:20-24` | Same media query. |
| `componentDefaults` config | `packages/core/src/services/eui-config.ts:13-24`, `:54` | App-wide default for the native path. |
| `@ember-eui/flatpickr` | `packages/flatpickr/src/components/eui-flatpickr.gjs` | Untouched. |
| `@ember-eui/pikaday` | `packages/pikaday/src/components/eui-pikaday.gts` | Untouched. |

### Why the existing calendar's logic is not reused

Read in `datetime-picker.gts`:

- It aliases the caller's moment (`:90`) and then mutates it (`:288-289`,
  `:301`, `:307`, `:313`). Navigating months changes the app's value object.
- `day.month || this.month` (`:280-281`) and the `day.month &&` test
  (`:287`) are wrong for January, which is month `0`. Clicking a January day
  shown at the end of December selects the wrong month.
- `setYear` (`:295-297`) sets `this.year` only. The grid still comes from
  `monthMoment`, so the year select does not change the days shown.
- The week starts on Sunday (`:116`) and the names are English literals
  (`:368-374`). Month names come from the global moment locale (`:161`).
- The today mark is not limited to the shown month (`:398-400`).
- Days are `div role="button"` with no `tabindex` and no key handling
  (`:384-385`). There is no keyboard support at all.
- State is copied from `@selected` in the constructor only (`:86-119`), so
  a later change of `@selected` is not shown.
- The time list is fixed: 24-hour, every 30 minutes (`:181-192`).
- No `excludeDates`, `filterDate`, time limits or range highlight.

So the markup, class names and styles are kept and the logic is new. The
class names are pinned by existing tests
(`packages/core/tests/integration/components/eui-date-pickers-test.gts:570-607`,
`eui-super-date-picker-upstream-props-test.gts:770-776`), which is a reason
to keep them. Batch 7 moves the super date picker onto the new calendar and
deletes `datetime-picker.gts`, which fixes the bugs above there too.

## 4. The API

### 4.1 Recommendation in one paragraph

Strings in, strings out. Argument names follow upstream where the meaning
is the same. The three things upstream expresses in moment terms are
replaced: format strings by `@dateOrder` and `@hour12`, `utcOffset` by
`@timeZone`, moment values by ISO strings.

### 4.2 Value types

| Mode | Chosen by | `@value` and `@onChange` | Example |
| --- | --- | --- | --- |
| date | default | `YYYY-MM-DD` | `'2026-11-24'` |
| date and time | `@showTimeSelect={{true}}` | an instant, UTC ISO | `'2026-11-24T15:30:00.000Z'` |
| time | `@showTimeSelectOnly={{true}}` | `HH:mm` (with `:ss` when `@seconds`) | `'09:30'` |

`null` means no value, in every mode. `@onChange` is never called with an
invalid value.

### 4.3 Signature

```ts
export interface EuiDatePickerSignature {
  // ...attributes go to the input; with @inline, to the calendar's root div
  Element: HTMLInputElement | HTMLDivElement;
  Args: {
    /** The value: see 4.2. `null` or `undefined` for none. */
    value?: string | null;
    /** Called with the new value, or `null` when cleared. */
    onChange?: (value: string | null) => void;
    /** Shows the clear button while there is a value. */
    onClear?: () => void;
    /** The text could not be read, or names a disabled date. */
    onInputError?: (error: {
      text: string;
      reason: 'unreadable' | 'disabled' | 'min' | 'max';
    }) => void;

    // mode
    showTimeSelect?: boolean;
    showTimeSelectOnly?: boolean;
    /** Minutes between entries of the time list. Default 30. */
    timeIntervals?: number;
    /** Keep and show seconds. Default false. */
    seconds?: boolean;

    // zone and locale
    /** 'local' (default), 'utc' or an IANA name. Used with `@showTimeSelect`, and for "today". */
    timeZone?: 'local' | 'utc' | (string & {});
    /** BCP 47 tag for names and defaults. Default: the document's language, then the browser's. */
    locale?: string;
    /** Order typed and shown. Default from `@locale`. */
    dateOrder?: 'dmy' | 'mdy' | 'ymd';
    /** 12-hour clock. Default from `@locale`. */
    hour12?: boolean;
    /** 0 (Sunday) to 6. Default from `@locale`. */
    firstDayOfWeek?: 0 | 1 | 2 | 3 | 4 | 5 | 6;

    // limits (date mode: YYYY-MM-DD; with @showTimeSelect also instants)
    minDate?: string;
    maxDate?: string;
    excludeDates?: string[];
    includeDates?: string[];
    filterDate?: (date: string) => boolean;
    minTime?: string; // HH:mm
    maxTime?: string;
    excludeTimes?: string[];
    injectTimes?: string[];

    // calendar
    openToDate?: string;
    inline?: boolean;
    shadow?: boolean; // inline only, default true
    shouldCloseOnSelect?: boolean; // default true
    adjustDateOnChange?: boolean; // default false (upstream: true)
    popoverPlacement?: PopoverAnchorPosition; // default 'downLeft'
    dayClassName?: (date: string) => string | undefined;
    calendarClass?: string;
    popoverClass?: string;

    // range highlight (upstream's props)
    selectsStart?: boolean;
    selectsEnd?: boolean;
    startDate?: string | null;
    endDate?: string | null;

    // form control
    id?: string;
    placeholder?: string;
    fullWidth?: boolean;
    compressed?: boolean;
    isInvalid?: boolean;
    isLoading?: boolean;
    readOnly?: boolean;
    disabled?: boolean;
    showIcon?: boolean; // default true
    iconType?: string; // default 'calendar', or 'clock' for time only
    controlOnly?: boolean;
    inputRef?: (element: HTMLInputElement | null) => void;

    /** The OS picker: 'auto' (default), true or false. Section 6. */
    native?: 'auto' | boolean;
  };
  Blocks: {
    prepend: [className: string, inputId: string];
    append: [className: string, inputId: string];
    /** Batch 6. Replaces the text input; always traps focus, as upstream's customInput. */
    trigger: [{ open: () => void; isOpen: boolean; text: string }];
  };
}
```

### 4.4 Examples

Date:

```gts
<EuiFormRow @label="Due date">
  <EuiDatePicker @value={{this.due}} @onChange={{this.setDue}} />
</EuiFormRow>
```

Date and time, in the site's zone:

```gts
<EuiDatePicker
  @value={{this.startsAt}}
  @onChange={{this.setStartsAt}}
  @showTimeSelect={{true}}
  @timeZone="America/Monterrey"
  @timeIntervals={{15}}
/>
```

`this.startsAt` is `'2026-11-24T21:30:00.000Z'`. The input shows
`24/11/2026 15:30`.

Time only:

```gts
<EuiDatePicker
  @value={{this.opensAt}}
  @onChange={{this.setOpensAt}}
  @showTimeSelectOnly={{true}}
  @minTime="06:00"
  @maxTime="22:00"
/>
```

Inline:

```gts
<EuiDatePicker
  @value={{this.day}}
  @onChange={{this.setDay}}
  @inline={{true}}
  @shadow={{false}}
  @filterDate={{this.isWorkday}}
/>
```

A range:

```gts
<EuiDatePickerRange @isInvalid={{this.endBeforeStart}}>
  <:start as |className|>
    <EuiDatePicker
      class={{className}}
      aria-label="Start date"
      @value={{this.start}}
      @onChange={{this.setStart}}
      @selectsStart={{true}}
      @startDate={{this.start}}
      @endDate={{this.end}}
      @maxDate={{this.end}}
    />
  </:start>
  <:end as |className|>
    <EuiDatePicker
      class={{className}}
      aria-label="End date"
      @value={{this.end}}
      @onChange={{this.setEnd}}
      @selectsEnd={{true}}
      @startDate={{this.start}}
      @endDate={{this.end}}
      @minDate={{this.start}}
    />
  </:end>
</EuiDatePickerRange>
```

Native fallback. The same template. Nothing to write:

```gts
{{! a phone or a Capacitor app renders <input type="date"> here }}
<EuiDatePicker @value={{this.due}} @onChange={{this.setDue}} />

{{! force either path }}
<EuiDatePicker @value={{this.due}} @onChange={{this.setDue}} @native={{true}} />
<EuiDatePicker @value={{this.due}} @onChange={{this.setDue}} @native={{false}} />
```

App-wide default, once:

```ts
this.euiConfig.updateConfig({
  componentDefaults: { EuiDatePicker: { native: false } }
});
```

### 4.5 `EuiDatePickerRange` with the new picker

The range keeps its blocks and the class each yields. The yielded class is
the contract flatpickr and pikaday users rely on, so it does not change.

Added: a private context, `-private/eui-date-picker-range-context.ts`,
shaped like `eui-form-control-layout-context.ts`. The range provides
`{ controlOnly: true, showIcon: false, inline, compressed, fullWidth,
readOnly, disabled, isInvalid }`. An `EuiDatePicker` inside reads it and
applies those as defaults; its own arguments win for `disabled` and
`isInvalid` only by OR, as upstream (`UP/date_picker_range.js:68-69`). A
picker with `@selectsEnd` inside a range uses `popoverPlacement: 'downRight'`
(`UP/date_picker_range.js:92`). With `@isCustom` the range provides nothing,
as upstream.

The picker also reports `showTimeSelect` to the range through the context,
so the range's `@showTimeSelect` argument
(`eui-date-picker-range.gts:65-71`) becomes unnecessary for it. The
argument stays for other inputs.

Other inputs in the blocks ignore the context. Nothing changes for them.

### 4.6 Alternatives considered

| Option | For | Against | Verdict |
| --- | --- | --- | --- |
| **Strings** (`YYYY-MM-DD`, ISO instant, `HH:mm`) | The sheet's rule. JSON-ready. Works with the native inputs without conversion. No library in the picker's import graph. | Not upstream's types. Apps holding moments convert at the edge. | **Recommended.** |
| Mirror upstream (`@selected` as moment) | Upstream demos translate one to one. | Date-only as a moment is a local midnight: the off-by-one-day bug the sheet's rule exists to prevent. Mutable objects. Every host importing the picker bundles moment. moment is in maintenance mode. | No. |
| Both (strings or moments accepted) | Easy migration. | Two code paths and two sets of tests for every argument. The moment import becomes static. | No. If wanted later: a separate module, `@ember-eui/core/utils/date-picker-moment`, with `toPickerValue(moment)` and `toMoment(value, zone)`, imported only by apps that use it. |
| `Temporal` | The right model: `PlainDate`, `ZonedDateTime`. | Shipped in Chrome 144, Firefox 139, Safari 27.3 (MDN browser-compat-data). WebViews on older phones lack it. A polyfill (`temporal-polyfill` 1.0.8, 1 MB unpacked on npm; bundled size not measured) would be a new dependency for every host. | Not now. The internal modules are written so `calendar-date.ts` and `zone.ts` can be replaced by `Temporal` later without touching the API. |
| `Intl` + own date math | Already in every target. The sheet does exactly this. Small. | We own about 300 lines of date math. | **Recommended.** |

moment stays a peer dependency of core (`packages/core/package.json:229`)
because the super date picker, the search bar and others use it. The new
picker and `utils/date/*` must not import it. A test enforces that (10.1).

## 5. Value and time-zone semantics, and typed input

### 5.1 Date-only

- A date is the string `YYYY-MM-DD`. It never becomes a `Date` through
  `new Date(string)` or local-time getters.
- Validity is checked as the sheet does: build with `Date.UTC`, read back
  with the UTC getters, compare (`packages/sheet/src/core/field-types/date.ts:11-21`).
  So `2026-02-31` is not a date. It does not roll over to March.
- All calendar math works on year, month, day integers. Day arithmetic goes
  through `Date.UTC`, where no DST exists.
- Adding a month or a year clamps the day: 31 January plus one month is 28
  or 29 February.
- Comparison is string comparison.
- "Today" is the calendar day in `@timeZone`, or in the browser's zone when
  `@timeZone` is not given. It is computed when the calendar opens and when
  the month changes. It is the only place the clock is read.
- Supported years: 0001 to 9999.

### 5.2 Instants (`@showTimeSelect`)

- The value is a UTC ISO string, as `Date.prototype.toISOString` gives.
  Input is also accepted with an offset (`…+02:00`); output is always `Z`.
- `@timeZone` is a property of the field, not of the value: `'local'`,
  `'utc'` or an IANA name. This is the sheet's decision
  (`git show HEAD~1:internal/spikes/sheet/V03-DESIGN.md`, section 10.3).
- The wall clock of an instant in a zone, and the instant of a wall clock,
  use the sheet's algorithm: `wallAt` and `instantOf`
  (`packages/sheet/src/core/field-types/date-time.ts:85`, `:132`).
  `Intl.DateTimeFormat(…, { timeZone }).formatToParts` reads the wall clock;
  two probes a day either side find the offset.
- **Gap** (spring forward, the wall clock does not exist): resolves forward
  by the gap. `02:30` becomes `03:30`. The input then shows `03:30`.
- **Overlap** (autumn, the wall clock exists twice): resolves to the first.
- **A stored second occurrence survives.** The picker emits only when the
  wall clock the user chose differs from the wall clock of the current
  value. Opening, closing, blurring and re-rendering emit nothing. So a
  value at the second `01:30` stays that instant until the user picks
  something else. The second occurrence cannot be chosen in the picker; this
  is a documented limit.
- **Changing the day** keeps the wall time and resolves again in the zone.
  If the new day has no such time, it resolves forward.
- **The time list** is built per shown day. An entry whose wall time does
  not exist that day is left out. An entry that exists twice appears once.
- **Seconds and milliseconds.** Without `@seconds`, a chosen time has zero
  seconds and milliseconds. Choosing only a day keeps the value's seconds
  and milliseconds, as upstream (`UP/react-datepicker/src/index.js:259-267`).
- **Limits.** `@minDate` and `@maxDate` may be dates or instants. A day is
  disabled when none of its 24 wall hours can fall inside the limits. A
  time is disabled when its instant is outside them, or its wall time is
  outside `@minTime`..`@maxTime`.
- **An unknown zone name** makes the picker invalid, with a development
  warning. It does not throw. It behaves as `'utc'` so the value still
  shows.
- A fixed offset (upstream `utcOffset`) is not an argument. Use an IANA
  name. The `Etc/GMT±N` names cover whole-hour offsets; their sign is
  inverted (`Etc/GMT+3` is UTC−3), which the docs must say.

The sheet's `src/core` cannot import from core
(`packages/sheet/tests/unit/core-boundary-test.ts`). So the zone algorithm
exists twice. Both test suites run the same vector file (10.1) so they
cannot drift.

### 5.3 Typed input

One rule: **never guess**. Text either names exactly one value or it is an
error.

- **Order.** `@dateOrder` decides between D/M/Y and M/D/Y. The default
  comes from `@locale`: the order of `day`, `month`, `year` in
  `Intl.DateTimeFormat(locale).formatToParts`. `3/4/2026` is 3 April with
  `dmy` and 4 March with `mdy`, always.
- **Accepted for a date:** `YYYY-MM-DD`, `YYYY/MM/DD`, and
  `D/M/YYYY` in the field's order with `/`, `.` or `-`, the same separator
  twice. These are the sheet's forms (`date.ts:31-45`). Leading zeros are
  optional in the day and month.
- **Accepted for a time:** `H:mm`, `H:mm:ss`, `H.mm`, with `am`, `pm`,
  `a.m.`, `p.m.`, `a`, `p`; and `3 pm`. `15` alone is an error. With a
  meridiem the hour must be 1 to 12. The sheet's rules
  (`date-time.ts:199-231`).
- **Date and time:** a date, a space or `, `, a time. A date alone means
  midnight. An ISO string with `Z` or an offset is that instant; without
  one it is a wall clock in the field's zone.
- **Two-digit years** are accepted and resolved into the hundred years
  from this year minus 50 to this year plus 49 (in 2026: 1976 to 2075, so
  `76` is 1976 and `75` is 2075). On commit the input
  is rewritten with four digits, so the user sees what was understood.
  Three-digit years are an error. Open question 5.
- **Impossible dates** (`31/02/2026`, `29/02/2027`, month 13, hour 24) are
  errors. No rollover.
- **Partial input** (`24/11`, `24/11/20`) is not a value. While the user
  types, nothing is emitted. If the text is complete and valid, the
  calendar moves to that month as a preview.
- **Commit** happens on Enter, on blur, and on picking in the calendar. Not
  on each keystroke. This differs from upstream (2.3) on purpose: upstream
  emits intermediate values while typing.
- **On commit, readable and allowed:** `@onChange(value)`; the text is
  rewritten in the display format.
- **On commit, empty:** `@onChange(null)`.
- **On commit, unreadable or disabled:** the text stays, the input gets
  `aria-invalid="true"` and the invalid look, `@onInputError` is called,
  `@onChange` is not. The value is unchanged. Escape restores the text of
  the value. Upstream instead silently reverts the text when the popover
  closes (`UP/react-datepicker/src/index.js:142-144`); showing the error is
  the more honest choice.
- **Display format** is fixed and numeric, so it always parses back:
  `DD/MM/YYYY`, `MM/DD/YYYY` or `YYYY-MM-DD`; then `HH:mm` or `h:mm am`,
  with `:ss` when `@seconds`. Month and weekday names in the calendar come
  from `Intl`, but never appear in the input.
- **The placeholder** defaults to the display format spelled out
  (`DD/MM/YYYY`), with the letters from i18n tokens.
- **An invalid `@value` from the app** (`'2026-02-31'`, `'yesterday'`, a
  moment): the input shows the raw text, the picker is invalid, the
  calendar opens on today, a development warning names the value. Upstream
  does the same for an invalid moment (`UP/date_picker.js:118`).

### 5.4 Locale

| What | Source |
| --- | --- |
| Month names, weekday names (short in the header, long for screen readers) | `Intl.DateTimeFormat(locale, …)` formatted with `timeZone: 'UTC'` on `Date.UTC` values |
| A day's accessible name ("Tuesday, 24 November 2026") | `Intl.DateTimeFormat(locale, { dateStyle: 'full', timeZone: 'UTC' })` |
| First day of the week | `@firstDayOfWeek`; else `Intl.Locale#getWeekInfo()` or the older `weekInfo` accessor; else Monday |
| 12 or 24 hour | `@hour12`; else `Intl.DateTimeFormat(locale, { hour: 'numeric' }).resolvedOptions().hourCycle` |
| Date order | `@dateOrder`; else `formatToParts` |
| Fixed texts ("Previous month", "Month", "Year", "Time", "Clear") | `eui-i18n` tokens, as the rest of core |
| `@locale` default | `document.documentElement.lang`, then `navigator.language` |

`getWeekInfo` is in Chrome 130 (accessor since 99), Safari 17 (accessor
since 15.4) and Firefox 153 (MDN browser-compat-data). Older Firefox falls
back to Monday, so `@firstDayOfWeek` exists for apps that must be sure.

## 6. Mobile and Capacitor

### 6.1 What the native path renders

The same `EuiFormControlLayout`, icon, clear button, prepend and append,
with this inside instead of the text input and the popover:

| Mode | Element | `value` attribute |
| --- | --- | --- |
| date | `<input type="date">` | `@value` as is |
| date and time | `<input type="datetime-local">` | the wall clock of `@value` in `@timeZone`, `YYYY-MM-DDTHH:mm` (the sheet's `dateTimeLocalValue`, `date-time.ts:266`) |
| time | `<input type="time">` | `@value` as is |

`min`, `max` and `step` attributes come from `@minDate`, `@maxDate`,
`@minTime`, `@maxTime`, `@timeIntervals` and `@seconds`. The input has
`EuiFieldText`'s classes. `@onChange` gets the same strings as on the
calendar path; the instant is computed from the wall clock with the rules
of 5.2. So the app cannot tell which path ran.

### 6.2 How the path is chosen

In this order. The first that answers wins.

1. `@inline={{true}}` or a `<:trigger>` block: calendar, whatever `@native`
   says. There is no native inline picker.
2. `@native={{true}}` or `@native={{false}}`.
3. `euiConfig` `componentDefaults.EuiDatePicker.native`, when `true` or
   `false`.
4. Auto:
   - no `window` (server rendering): calendar markup, which is a plain text
     input until opened;
   - an argument the native input cannot honour is present
     (`@filterDate`, `@excludeDates`, `@includeDates`, `@excludeTimes`,
     `@injectTimes`, `@dayClassName`): calendar;
   - `window.Capacitor?.isNativePlatform?.()` is `true`: native.
     `isNativePlatform` is on Capacitor's global
     (`CapacitorGlobal` in `ionic-team/capacitor` `core/src/definitions.ts`).
     Read through `window`, so core does not depend on Capacitor;
   - `matchMedia('(pointer: coarse)').matches`: native. The same test as the
     sheet (`packages/sheet/src/-private/sheet/edit.ts:20-24`). It is about
     the primary pointer, so a laptop with a touch screen stays on the
     calendar;
   - else: calendar.

The choice is made once per component instance: when it is created in
the browser, or right after rehydration on a server-rendered page
(section 13). It does not flip while the user is in the field.

Why a mix. An argument alone makes every app repeat the detection. Media
query alone misses nothing on phones but cannot be overridden. Capacitor
detection alone misses the mobile web app. The argument and the config give
control; detection gives the default.

### 6.3 What differs on the native path

| Topic | Calendar path | Native path |
| --- | --- | --- |
| Display format | `@dateOrder`, `@hour12` | The OS decides. Those arguments are ignored. |
| `@locale`, `@firstDayOfWeek` | applied | The OS decides. |
| `@placeholder` | shown | Not shown. Native date inputs have none. |
| `@timeIntervals` | exact list | `step`. Some OS pickers ignore it. |
| `@minDate`, `@maxDate`, `@minTime`, `@maxTime` | disabled entries | `min` and `max`. Not every OS picker enforces them, so the component checks every value itself: outside the limits means `@onInputError`, the invalid look, and no `@onChange`. |
| `@filterDate`, `@excludeDates`, `@includeDates`, `@excludeTimes` | disabled entries | Auto never picks native with these. With `@native={{true}}` they are checked after the choice, as the limits are. A development warning says so. |
| `@injectTimes`, `@dayClassName`, `@openToDate`, `@popoverPlacement`, `@shouldCloseOnSelect`, `@adjustDateOnChange`, range highlight | applied | No effect. |
| Typed input | parsed (5.3) | The browser's segmented editing. Only whole values arrive. |
| When `@onChange` fires | Enter, blur, pick | The input's `change` event. |
| Clearing | clear button, or empty text | Clear button; also the OS picker's own clear or reset. Empty means `null`. |
| `@readOnly` | read-only text input | Rendered as a read-only **text** input with the formatted value. Some engines open the picker on a read-only date input. |
| `@disabled`, `@isInvalid`, `@isLoading`, `@compressed`, `@fullWidth` | same | same |
| Icon | EUI's | EUI's. The browser's own indicator is hidden. A click on the icon calls `showPicker()` where it exists. |
| Seconds | `@seconds` | `step="1"` |
| DST gap or overlap | 5.2 | Same rules, applied to the wall clock the OS returns. |

### 6.4 What must be checked on devices

This cannot be tested in the sandbox. Before batch 5 is called done, check
in WKWebView (iOS) and the Android WebView, in the Prysmex Capacitor shell:
the empty input's height and text alignment in `EuiFormControlLayout`; the
picker opening from a tap anywhere in the field; `min` and `max`; the clear
action; `datetime-local` with seconds; dark mode of the OS picker; the
input inside a flyout and inside a modal.

## 7. Accessibility

### 7.1 The grid

Recommended: the WAI-ARIA date picker pattern, not upstream's listbox.

- The month is a `<table role="grid">`. Its name comes from a visually
  hidden heading with the month and year ("November 2026"), through
  `aria-labelledby`. The visible controls for month and year are the two
  selects (7.3); the heading exists for the name and the announcement. Weekday names are `<th scope="col"
  abbr="Monday">`.
- Each day is a `<td role="gridcell">` holding a `<button>`. Class names
  stay upstream's (`react-datepicker__week`, `__day`, `__day--selected`…),
  so the ported styles apply. The styles are class-based, not tag-based;
  a small reset makes the table lay out as the current flex rows.
- Roving tabindex: exactly one day button has `tabindex="0"`. It is the
  focused day, else the selected day, else today, else the first enabled
  day of the month.
- `aria-selected="true"` on the selected day's `td` (it is not allowed on
  a `button`); `aria-current="date"` on today's button;
  `aria-disabled="true"` on the buttons of disabled days, which stay
  focusable so a screen reader user can find out why nothing happens.
- A day's accessible name is the full date from `Intl` (5.4), not
  `day-24`.
- Month changes are announced by that hidden heading, which is an
  `aria-live="polite"` region.

### 7.2 Keys

| Key | In the grid |
| --- | --- |
| ArrowLeft, ArrowRight | previous, next day. Swapped when the direction is RTL. |
| ArrowUp, ArrowDown | same weekday, previous or next week |
| Home, End | first, last day of the week |
| PageUp, PageDown | previous, next month, same day clamped |
| Shift+PageUp, Shift+PageDown | previous, next year |
| Enter, Space | select |
| Escape | close, focus back to the input |
| Tab, Shift+Tab | move between navigation, selects, grid, time list; after the last, close (popover) or leave (inline) |

Moving onto a disabled day is allowed; selecting it is not. Moving past
`@minDate` or `@maxDate` stops at the limit.

Upstream uses Home and End for years (`UP/react-datepicker/src/month.js:106-111`).
That contradicts the ARIA pattern and what screen reader users expect. Open
question 3.

| Key | In the input |
| --- | --- |
| ArrowDown, Alt+ArrowDown | open if closed; move focus to the grid |
| Enter | commit the text; close |
| Escape | close; if already closed, restore the value's text |
| Tab | commit; close; move on |

The time list is `role="listbox"` with `aria-label` "Time",
`aria-activedescendant`, ArrowUp, ArrowDown, Home, End, Enter and Space.
Disabled times have `aria-disabled`.

### 7.3 Popover, focus, modals

- `EuiPopover` with `@ownFocus={{false}}`, as upstream and as
  `EuiInputPopover` (`eui-input-popover.gts:232`). Focus stays in the input
  while typing. The input has `aria-haspopup="dialog"`, `aria-expanded`,
  `aria-controls`.
- The panel is `role="dialog"` with `aria-label` "Choose date" plus the
  field's label. It is not `aria-modal`: the input stays reachable.
- Once focus enters the calendar, a focus trap holds it there. Escape, a
  selection that closes, or a click outside release it and return focus to
  the input. Returning focus is done by the picker itself. The popover's own
  return only runs when it was stable (`eui-popover.gts:1317`), which was
  unreliable in tests (the date pickers handoff, item 6:
  `git show HEAD~1:internal/spikes/eui-latest/date-pickers-handoff.md`).
- Inside a modal or flyout, the portalled panel joins the outer trap
  (`eui-popover.gts:1303`, `-private/focus-trap-registry.ts`). A test covers
  it (10.2).
- Inline mode has no dialog and no trap. The calendar is a `role="group"`
  with a label.
- Month and year are two `EuiSelect`s, as the current Ember calendar
  (`datetime-picker.gts:345-364`), not upstream's custom read views. A
  native select needs no second focus trap and works by touch. The year
  list runs from `@minDate`'s year to `@maxDate`'s year; a missing limit is
  100 years back or 20 forward from the shown year.
- Navigation buttons are `EuiButtonIcon`s with `aria-label`s from i18n.
  They are disabled when the whole previous or next month is outside the
  limits.

### 7.4 States

- `@disabled`: the input is disabled; nothing opens. Inline: the calendar
  gets upstream's `react-datepicker--non-interactive` class and every
  control is disabled.
- `@readOnly`: the input is read-only; nothing opens; no clear button.
  Inline: as disabled, but with normal text contrast.
- `@isInvalid`, or an input error: `aria-invalid="true"` and the
  `validatableControl` modifier, as `EuiFieldText`.
- The focused day needs a visible focus ring. The ported styles have no
  rule for upstream's `--keyboard-selected` class, so a `:focus-visible`
  rule with EUI's focus ring is added. It is the one style addition.
- Motion: the day hover scale is already behind upstream's
  `euiCanAnimate`.

## 8. Architecture

### 8.1 Files

New, plain TypeScript, no Ember, no moment, own code (project license):

| File | Contents | Rough size |
| --- | --- | --- |
| `packages/core/src/utils/date/calendar-date.ts` | parse, validate, compare `YYYY-MM-DD`; add days, months, years; weekday; the weeks of a month | 180 lines |
| `packages/core/src/utils/date/zone.ts` | `wallAt`, `instantOf`, zone validity, today in a zone | 150 |
| `packages/core/src/utils/date/parse.ts` | typed text to date, time, wall clock; two-digit years | 170 |
| `packages/core/src/utils/date/format.ts` | display text; `Intl` names; locale defaults | 150 |
| `packages/core/src/utils/date/times.ts` | the time list for a day: intervals, injected, excluded, limits, gaps | 110 |
| `packages/core/src/utils/date/calendar-nav.ts` | key to next focused date; the disabled test; month navigation limits | 130 |
| `packages/core/src/-private/native-date-input.ts` | the choice of 6.2 | 50 |
| `packages/core/src/-private/eui-date-picker-range-context.ts` | the context of 4.5 | 50 |

New components:

| File | Contents | Rough size |
| --- | --- | --- |
| `packages/core/src/components/eui-date-picker.gts` | public component: arguments, value and text state, commit, layout, popover, path choice | 450 |
| `packages/core/src/components/eui-date-picker/calendar.gts` | header, selects, grid, keyboard, range highlight. Private. Also used by the super date picker. | 380 |
| `packages/core/src/components/eui-date-picker/time-list.gts` | the time list. Private. | 150 |
| `packages/core/src/components/eui-date-picker/native-input.gts` | the native input. Private. | 120 |

Changed:

- `packages/core/src/components.ts`, `packages/core/src/template-registry.ts`:
  register `EuiDatePicker`.
- `packages/core/src/components/eui-date-picker-range.gts`: provide the
  context; doc comment.
- `packages/core/src/services/eui-config.ts`: `EuiDatePicker` in
  `EuiComponentDefaults`.
- `packages/core/src/utils/eui/date-pickers.ts`: the focus ring rule and the
  table reset, outside the hand-ported function so the parity test still
  compares the port byte for byte.
- `packages/core/NOTICE.md`: see 8.4.
- Batch 7: `absolute-tab.gts` uses `calendar.gts`; `datetime-picker.gts` is
  deleted.

### 8.2 Logic: own, not `@zag-js/date-picker`

| | Own logic | `@zag-js/date-picker` 1.49.0 |
| --- | --- | --- |
| Ember binding | native | None. `@zag-js/ember` does not exist on npm. We would write and maintain an adapter from its state machine to Glimmer tracking. |
| Date model | the strings of section 5 | `@internationalized/date` objects (Apache-2.0, peer dependency, 1.2 MB unpacked). A third date model in the repository, with conversion at every argument. |
| Popover | `EuiPopover`, which already handles modals, flyouts and focus traps | Its own: depends on `@zag-js/popper` (`@floating-ui/dom`), `@zag-js/dismissable`, `@zag-js/live-region`. Two positioning and dismissal systems in one page. |
| Markup | upstream's class names, so the ported styles and the pinned tests apply | Its own parts and `data-*` attributes. The styles would be rewritten or the props remapped. |
| Time list | section 5.2 | None. It is a date picker. We write the time list either way. |
| Range in one calendar | not planned | Yes. Its real advantage, and a non-goal here. |
| Typed input | section 5.3 | Has parsing hooks; the rules would still be ours. |
| What we own | about 900 lines of pure functions with unit tests | An adapter, a model converter, a style remap, and upgrades of nine packages. |
| Size | measured in batch 3 | Not measured. |

Recommendation: own logic. The hard parts are the date semantics, which zag
does not decide for us, and the keyboard grid, which is about 130 lines.
The ARIA pattern zag implements is the same one section 7 specifies, and it
is a good reference to check against.

### 8.3 Shared with the super date picker

- Shared: `calendar.gts`, `time-list.gts`, the styles, `utils/date/*`.
- Not shared: the super date picker's values stay moment and date math
  (`@elastic/datemath`). `absolute-tab.gts` converts at its edge: a moment
  to an instant string in, an instant string to a moment out
  (`absolute-tab.gts:147-152` is the call site).
- `eui-super-date-picker/utils/date-utils.ts` (moment versions of
  `isDayDisabled` and friends) stays for the rest of the super date picker
  until nothing uses it.

### 8.4 Styles and license

- No new generated styles. `euiDatePickerStyles` and
  `euiReactDatePickerStyles` already exist and are parity-tested
  (`scripts/eui-upstream-parity.test.mjs`).
- Files that port upstream structure or behaviour (`eui-date-picker.gts`,
  `calendar.gts`, `time-list.gts`) get core's header for ported files, as in
  `packages/core/src/-private/eui-button-context.ts:1-7`, naming the
  upstream files. The fork is MIT (HackerOne) inside an ELv2/SSPL package,
  so the header also names `react-datepicker@2.0.0, MIT, Copyright (c) 2018
  HackerOne Inc and individual contributors`.
- `packages/core/NOTICE.md` does not mention react-datepicker today, though
  `datetime-picker.gts` and `utils/eui/date-pickers.ts` already derive from
  the fork. Upstream's own notice does (`NOTICE.txt:5-28` in the EUI
  package). Batch 2 adds that MIT notice to `NOTICE.md`. This is a gap that
  exists now, independent of this work.
- `utils/date/*` is original code under the project's MIT license. The zone
  algorithm comes from the sheet, which is the project's own.

### 8.5 Bundle size and tree shaking

- The component is its own module (`addon.publicEntrypoints`,
  `packages/core/rollup.config.mjs:92-97`). An app built the default way
  gets it only when a template or module imports it.
- One exception, true of every core component today: core also publishes
  app re-exports of all its components (`rollup.config.mjs:99-104`). An app
  built with `staticInvokables: false` gets all of them, used or not;
  `scripts/compat-bundle-size.mjs` has the positive control for that
  (`dynamic-core-none`). The sheet stays out of such apps because it has no
  app re-exports. The picker follows core's rule, so in those apps it is
  included like the other 300 components. Its cost there is its own code
  only, since it brings no dependency. Keeping it out would mean leaving it
  out of the app re-exports, which breaks loose-mode templates; not
  proposed.
- No new dependency. No moment, no zag, no polyfill.
- `utils/date/*` has no top-level side effects. `Intl` formatters are
  created lazily and cached per locale and zone, as the sheet does
  (`date-time.ts:46-49`).
- The calendar and time list are static imports of the picker. They are
  small, and a lazy chunk would make the first open asynchronous. If the
  measurement in batch 3 disagrees, the native path makes a clean split
  point: phones never need the calendar chunk.
- Checks added in batch 3: a size probe `site/size-probe/eui-date-picker.gjs`
  for `scripts/measure-bundle-size.mjs`, and a case in
  `scripts/compat-bundle-size.mjs` that fails when a default-build app
  that does not import the picker contains it, and when an app that imports
  only the picker contains moment.

### 8.6 Positioning and RTL

- `EuiPopover` does the positioning, flipping and scroll handling. Settings
  as upstream: no arrow, no panel padding, `buffer` 0, `display="block"`,
  anchor `downLeft`.
- The panel has the calendar's intrinsic width, not the input's.
- RTL: the ported styles use logical properties. Arrow keys swap (7.2).
  The week renders in document order, so it mirrors by itself. The
  navigation icons and the `downLeft` anchor in RTL are checked by a test,
  not assumed.

## 9. Edge cases

| # | Case | Expected |
| --- | --- | --- |
| 1 | `@value="2026-02-31"` | Invalid look, raw text shown, calendar opens on today, development warning, no throw. |
| 2 | `@value` is a `Date` or a moment | As 1. The warning says to pass a string. |
| 3 | User in UTC−6 picks 24 November in date mode | `'2026-11-24'`. The same in any zone. |
| 4 | Typed `3/4/2026`, `dmy` | `'2026-04-03'`. |
| 5 | Typed `3/4/2026`, `mdy` | `'2026-03-04'`. |
| 6 | Typed `13/13/2026` or `31/02/2026` | Input error `unreadable`. No `@onChange`. |
| 7 | Typed `24/11/26` | `'2026-11-24'`; the input becomes `24/11/2026`. |
| 8 | Typed `24/11` then blur | Input error. Text stays. Value unchanged. |
| 9 | Typed `24/11` then Escape | Text returns to the value's. No error. |
| 10 | Input emptied, then blur | `@onChange(null)`. |
| 11 | Typed a date before `@minDate` | Input error `min`. No `@onChange`. |
| 12 | Typed a date `@filterDate` refuses | Input error `disabled`. |
| 13 | Click on a disabled day | Nothing. |
| 14 | Arrow onto a disabled day, Enter | Focus moves there. Enter does nothing. |
| 15 | PageDown from 31 January | 28 or 29 February. |
| 16 | Shift+PageDown from 29 February 2028 | 28 February 2029. |
| 17 | PageDown past `@maxDate` | Focus stops on `@maxDate`. Next-month button disabled. |
| 18 | `@minDate` after `@maxDate` | Every day disabled. Development warning. |
| 19 | Zone `America/New_York`, 8 March 2026, pick `02:30` | The entry is not in the list. Typed: resolves to `03:30` EDT; the input shows `03:30`. |
| 20 | Same zone, 1 November 2026, pick `01:30` | The first `01:30` (EDT), `05:30Z`. |
| 21 | Value is the second `01:30` (`06:30Z`); open, close, blur | No `@onChange`. The value is intact. |
| 22 | Value `01:30` on 31 October; pick 1 November | First `01:30` of 1 November. |
| 23 | Value `02:30` on 7 March; pick 8 March | `03:30` on 8 March. |
| 24 | `@timeZone="Mars/Olympus"` | Invalid look, warning, shown as UTC. |
| 25 | "Today" at 23:30 in the browser, `@timeZone` a zone already in tomorrow | Today is the zone's day. |
| 26 | Calendar left open across midnight | Today updates on the next month change or reopen. |
| 27 | Value has seconds `:45`, no `@seconds`; pick another day | Seconds kept. |
| 28 | Same; pick another time | Seconds and milliseconds zero. |
| 29 | `@value` changes from outside while open | Calendar and text follow it. Text being typed is not overwritten while the input has focus and differs. |
| 30 | `@onChange` not passed | Nothing throws. The picker shows `@value`, unchanged. |
| 31 | Year select to a year where the focused day is outside the limits | Focus clamps to the nearest allowed day. No value change (unless `@adjustDateOnChange`). |
| 32 | Locale `en-US` | Week starts Sunday, `mdy`, 12-hour. |
| 33 | Locale `es-MX` | Week starts per `getWeekInfo`, `dmy`, per `hourCycle`. |
| 34 | No `getWeekInfo` in the engine | Monday. |
| 35 | `dir="rtl"` | ArrowLeft goes to the next day. Layout mirrors. |
| 36 | Picker in a modal | Tab stays within modal and calendar. Escape closes the calendar only. |
| 37 | Picker in a flyout that closes on outside click | A click in the calendar does not close the flyout. |
| 38 | Popover near the bottom of the viewport | Flips up. |
| 39 | `@disabled` | No open, no clear button. |
| 40 | `@readOnly` | No open, no clear button, text selectable. |
| 41 | `@inline` and `@disabled` | Calendar visible, nothing focusable, non-interactive class. |
| 42 | `@showTimeSelect` and `@showTimeSelectOnly` both | Time only, as upstream (`UP/date_picker.js:179`). |
| 43 | `@native={{true}}` with `@filterDate`; OS returns a refused day | Input error `disabled`, invalid look, no `@onChange`. |
| 44 | `@native={{true}}` with `@inline` | Calendar. Development warning. |
| 45 | Native, `@showTimeSelect`, zone set; OS returns a gap time | Resolved forward, as 19. |
| 46 | Native and `@readOnly` | Read-only text input with the formatted value. |
| 47 | Capacitor present, `isNativePlatform()` false (web build) | Falls to the pointer test. |
| 48 | Server rendering | Text input markup. No `window` access during render. |
| 49 | Range: end picker with `@minDate={{start}}`, start then moved after end | The app's `@isInvalid` rule shows it. The picker does not change the other value. |
| 50 | Range: `@startDate` and `@endDate` set | Days between get `--in-range`; ends get `--range-start` and `--range-end`. |
| 51 | `24/11/099` or `24/11/10000` typed | Input error. Years are two or four digits. |
| 52 | `@timeIntervals={{0}}` or negative | Treated as 30. Development warning. |
| 53 | Two pickers; the second opens while the first is open | The first closes. |
| 54 | Component destroyed while open | Popover and trap removed; no leak (leak test). |

## 10. Tests, docs and demos

### 10.1 Unit tests

In `packages/core/tests/unit/utils/`, named as the existing
`Unit | utils | eui | euiClass`:

| File | Module | Covers |
| --- | --- | --- |
| `date-calendar-date-test.ts` | `Unit | utils | date | calendar-date` | validity, leap years, month and year clamping, weeks of a month for each first day, comparison |
| `date-zone-test.ts` | `Unit | utils | date | zone` | wall clock and instant for `local`, `utc`, IANA zones; gaps, overlaps, round trips; unknown zones; today in a zone |
| `date-parse-test.ts` | `Unit | utils | date | parse` | every accepted and refused form of 5.3; orders; two-digit years with an injected "today"; times; date and time |
| `date-format-test.ts` | `Unit | utils | date | format` | display text round-trips through parse; locale defaults for a list of locales; missing `getWeekInfo` |
| `date-times-test.ts` | `Unit | utils | date | times` | intervals, injected, excluded, limits, a gap day, an overlap day |
| `date-calendar-nav-test.ts` | `Unit | utils | date | calendar-nav` | every key of 7.2, limits, disabled days, RTL |
| `date-no-moment-test.ts` | `Unit | utils | date | boundary` | the sources of `utils/date/*` and `eui-date-picker*` contain no `from 'moment'`; modelled on the sheet's `core-boundary-test.ts` |

Zone vectors live in one JSON file used by this suite and by the sheet's
`Unit | Sheet | dateTime (V03 10.3)`, so the two copies of the algorithm
stay equal.

The tests name zones explicitly. They do not depend on the machine's zone,
except a small `local` group that only asserts round trips.

### 10.2 Integration tests

In `packages/core/tests/integration/components/`:

| File | Module | Covers |
| --- | --- | --- |
| `eui-date-picker-test.gts` | `Integration | Component | eui-date-picker` | renders; opens on focus and click; pick a day; typed input and every commit rule; clear; states; prepend and append; `controlOnly`; `data-test-subj` forwarding; edge cases 1 to 18, 29 to 31, 39 to 42 |
| `eui-date-picker-keyboard-test.gts` | `… | eui-date-picker | keyboard and aria` | section 7 in full: roles, names, roving tabindex, every key, focus return, the trap, a modal, a flyout |
| `eui-date-picker-time-test.gts` | `… | eui-date-picker | time` | time list, time only, zones, edge cases 19 to 28 |
| `eui-date-picker-native-test.gts` | `… | eui-date-picker | native` | the choice of 6.2 with stubbed `matchMedia` and `window.Capacitor`; the three input types; values in and out; post-validation; read-only; edge cases 43 to 47 |
| `eui-date-picker-inline-test.gts` | `… | eui-date-picker | inline` | upstream's `date_picker.spec.tsx` cases: shadow, icons below, disabled, read-only |
| `eui-date-picker-upstream-test.gts` | `… | eui-date-picker | upstream` | upstream's `date_picker.test.tsx` cases, translated |
| `eui-date-picker-range-test.gts` (existing) | existing module | new tests: context defaults, `downRight` for the end, range highlight, edge cases 49 and 50 |
| `eui-date-pickers-test.gts` (existing) | `Borealis date pickers` | computed styles of the new picker: day size, selected, today, disabled, in-range, focus ring, time list; light and dark; RTL; high contrast |
| `leaks/` | existing leak suite | open, close, destroy while open |

The super date picker's existing tests must pass unchanged in batch 7.

### 10.3 Checks that are not tests

- `node scripts/generate-api-docs.mjs --check` after adding the page to
  `scripts/api-docs-pages.json`.
- `node --test scripts/eui-upstream-parity.test.mjs` still passes.
- `node scripts/measure-bundle-size.mjs` and `--compat` (8.5).
- Screen reader passes by hand: VoiceOver on macOS and iOS, TalkBack. Not
  automatable here.
- Device checks of 6.4.

### 10.4 Docs and demos

New page `packages/core/docs/forms/date-picker/index.md` with
`demo/dNN-*.md` files, following `docs/forms/date-picker-range`. Demos
mirror upstream's page:

1. `d01-date-picker.md`: basic, with the value shown as a string.
2. `d02-states.md`: the display toggles.
3. `d03-time-selection.md`: date and time, time only, intervals.
4. `d04-time-zones.md`: a zone select; replaces upstream's "UTC offsets".
5. `d05-locale.md`: locale, order, first day, 12 or 24 hour.
6. `d06-specific-dates-and-times.md`: limits, excluded, filtered, injected.
7. `d07-open-to-date.md`.
8. `d08-inline.md`.
9. `d09-custom-classes.md`.
10. `d10-native.md`: the three choices of `@native`, and what differs.
11. `d11-custom-trigger.md` (batch 6).

Also: a "Values" section (strings, why, how to convert from `Date` and
moment), a "Typed input" section (5.3 as a table), and an "Upstream
differences" section (values, format arguments, keys, commit on Enter and
blur).

`docs/forms/date-picker-range`: the first demo uses `EuiDatePicker`; the
sentence "core has no `EuiDatePicker`"
(`demo/d01-date-picker-range.md:11`) goes; one demo with native inputs
stays.

## 11. Migration from flatpickr and pikaday

### 11.1 Position

- Both packages stay published and working through 16.x. No code is removed
  from them.
- When batch 6 is done, their docs pages
  (`packages/flatpickr/docs/flatpickr.md`, `packages/pikaday/docs/pikaday.md`)
  get a note at the top: for ordinary date picking use `EuiDatePicker`; this
  package stays for the cases listed below.
- `@ember-eui/pikaday` is the one to retire first. It depends on
  `ember-pikaday`, works in `Date` objects, and offers nothing the new
  picker lacks. Proposal: mark it deprecated on npm at the next major, and
  stop releasing it then. Open question 8.
- `@ember-eui/flatpickr` keeps a reason to exist: range in one calendar,
  several dates, week numbers. It stays, undeprecated, described as the
  package for those cases.
- `EuiDatePickerRange` keeps working with both, unchanged (4.5).

### 11.2 From `EuiPikaday`

| Pikaday | `EuiDatePicker` |
| --- | --- |
| `@value` (`Date`) | `@value` (`YYYY-MM-DD`). From a `Date` that means a local day: `` `${y}-${mm}-${dd}` `` from the local getters, not `toISOString().slice(0, 10)`. |
| `@onSelection(date)` | `@onChange(string \| null)` |
| `@format` (moment) | `@dateOrder` |
| `@minDate`, `@maxDate` (`Date`) | same names, strings |
| `@firstDay` | `@firstDayOfWeek` |
| `@i18n` (months, weekdays) | `@locale`; names come from `Intl` |
| `@yearRange` | from `@minDate` and `@maxDate` |
| `@defaultDate` | `@openToDate` |
| `@bound={{false}}`, `@container` | `@inline` |
| `@onOpen`, `@onClose`, `@onDraw`, `@register`, `@theme`, `@moment` | none |
| EuiFieldText arguments and blocks | same |

### 11.3 From `EuiFlatpickr`

| Flatpickr | `EuiDatePicker` |
| --- | --- |
| `@date` (`Date`, string or array) | `@value` (string) |
| `@onChange(dates, str, instance)` | `@onChange(string \| null)` |
| `@enableTime` | `@showTimeSelect` (the value becomes an instant) |
| `@enableTime` + `@noCalendar` | `@showTimeSelectOnly` |
| `@time_24hr` | `@hour12={{false}}` |
| `@minuteIncrement` | `@timeIntervals` (a list, not spinners) |
| `@dateFormat`, `@altInput`, `@altFormat` | `@dateOrder`; the value is always ISO, the display always local |
| `@minDate`, `@maxDate` | same names, strings |
| `@disable` (dates or functions) | `@excludeDates`, `@filterDate` |
| `@enable` | `@includeDates` |
| `@inline` | `@inline` |
| `@locale` | `@locale` |
| `@clear` | `@onClear` |
| `@defaultDate` | `@openToDate` |
| `@mode="range"` | Two pickers in `EuiDatePickerRange`. One calendar for both ends: stay on flatpickr. |
| `@mode="multiple"`, `@weekNumbers`, `@wrap` | Stay on flatpickr. |
| free minute entry (any minute) | Type the time in the input. The list only offers the intervals. |

### 11.4 For Prysmex

- Each use is a per-field change, because the value type changes. Fields
  that hold a calendar day must send `YYYY-MM-DD`; fields that hold a moment
  must send an instant. Deciding which is which per field is the real work,
  and it is the same decision the sheet's `date` and `dateTime` types force.
- A list of the uses in the Prysmex apps was not made for this document.
  It is the first step of batch 8.

## 12. Batches

Each batch ends with code, tests, docs and a changeset in `.changeset/`,
and with the core suite green. Sizes are source lines, tests extra.

| # | Batch | Contents | Size |
| --- | --- | --- | --- |
| 0 | Decisions | The open questions of section 14 answered. | none |
| 1 | Date logic | `utils/date/*`; its six unit suites; the shared zone vectors, also wired into the sheet's suite; the no-moment boundary test. No component. | 900 src, 1,300 test |
| 2 | Calendar, inline, date only | `calendar.gts`; `eui-date-picker.gts` with `@inline` only; grid ARIA and all keys; limits, excluded, filtered; locale; `@dayClassName`; focus ring style; NOTICE fix. Not registered and no docs page yet: the tests import the module by path. | 700 src, 900 test |
| 3 | Popover and typed input | Text input, popover, commit rules, input errors, clear, states, prepend and append, `controlOnly`, focus trap, modal and flyout tests, upstream test translations, size probe and compat check. Registration in `components.ts` and `template-registry.ts`. The docs page, with demos 1, 2, 5, 6, 7, 8, 9. First public release. | 550 src, 1,100 test, docs |
| 4 | Time | `time-list.gts`; `@showTimeSelect`, `@showTimeSelectOnly`; zones and DST; `@seconds`; time limits. Demos 3, 4. | 350 src, 700 test |
| 5 | Native path | `native-input.gts`, `native-date-input.ts`, the config default, post-validation, read-only fallback. Demo 10. Device checks of 6.4, with the user. | 250 src, 450 test |
| 6 | Range and custom trigger | The range context; `@selectsStart`, `@selectsEnd`, highlight; `<:trigger>`; range docs rewritten; demo 11; legacy notes on the flatpickr and pikaday pages. | 250 src, 400 test |
| 7 | Super date picker | `absolute-tab.gts` on `calendar.gts` and `time-list.gts`; `datetime-picker.gts` deleted; its tests pass unchanged plus tests for the bugs of section 3. | 150 src (net negative), 200 test |
| 8 | Migration | The Prysmex inventory; migration guide in the docs; pikaday deprecation as decided. | docs |

The picker becomes public in batch 3. Batch 2 is merged but exports
nothing from `components.ts`, so an incomplete picker is never released.
Batch 5 can move before batch 4 if phones are the priority: it needs only
batch 3.

## 13. Risks

| Risk | Effect | Mitigation |
| --- | --- | --- |
| Native inputs behave differently per OS version and WebView (height when empty, `min` and `max`, `step`, clear) | The native path looks or acts wrong on some phones | Post-validation never trusts the OS. Device checks before batch 5 closes. `@native={{false}}` and the config default as escape hatches. |
| Not testable here: iOS, Android, screen readers | Bugs found late | Named as manual checks; the user or a device run does them. |
| Diverging from upstream (values, keys, commit timing, select dropdowns) | Upstream docs do not apply literally; future upstream changes do not port mechanically | An "Upstream differences" docs section. Class names and styles stay upstream's, which is where upstream changes most. |
| Two copies of the zone algorithm (core and sheet) | Drift | One vector file, both suites. |
| `Intl` gaps in old WebViews (`getWeekInfo`, IANA zones) | Wrong first day, or a zone treated as unknown | Fallbacks and explicit arguments. Unknown zone is visible, not silent. |
| The roving-tabindex table under class-based styles made for `div`s | Layout differences from upstream | The computed-style tests in `Borealis date pickers` compare sizes and colours. |
| Popover focus return and traps in modals | Focus lost after closing | The picker returns focus itself; tests in a modal and a flyout. |
| Batch 7 touches a working super date picker | Regression | Its tests must pass unchanged; it is a separate batch that can wait. |
| The two-digit year window | A wrong century, visibly | The input is rewritten with four digits on commit. Or refuse them (open question 5). |
| Apps pass `Date` or moment out of habit | Invalid pickers | Development warning naming the fix; the migration tables. |
| Server-rendered pages (the library is on Vite SSR): the server renders the text input, the phone then chooses the native input | A rehydration mismatch on that element | The choice is applied after the first render in the browser, so the server and first client markup agree; the input is swapped once. To be proven in batch 5 with an SSR test. |
| Scope growth toward flatpickr's features | The picker never ships | The non-goals. |

## 14. Open questions

Each with a recommendation. Batch 0 is answering them.

1. **Values: strings only?** Recommended: yes (4.6). Alternative: a
   separate moment adapter module later, if the migration shows a need.
2. **Argument name for the value: `@value` or upstream's `@selected`?**
   Recommended: `@value`. It holds a string, as `EuiFieldText`'s does, and
   `@selected` would suggest upstream's moment.
3. **Keys: the ARIA grid pattern (Home and End move within the week,
   Shift+PageUp and Shift+PageDown move a year), or upstream's (Home and End
   move a year)?** Recommended: the ARIA pattern, and a grid instead of
   upstream's listbox.
4. **Mode arguments: upstream's `@showTimeSelect` and
   `@showTimeSelectOnly`, or one `@type="date" | "datetime" | "time"`?**
   Recommended: upstream's names. `@type` is cleaner but is one more
   difference from upstream's docs.
5. **Two-digit years: accept (this year minus 50 to this year plus 49,
   rewritten with four digits) or refuse, as the sheet does?** Recommended:
   accept. If refused, the sheet and the picker agree today; if accepted,
   the sheet could adopt the same rule later.
6. **`@adjustDateOnChange` default.** Upstream is `true`: arrow keys and
   the month and year selects change the value immediately. Recommended:
   `false`. A value should change when the user selects, not while they
   look. The argument stays for parity.
7. **Auto on a phone with `@filterDate` or `@excludeDates`: calendar (the
   limits are visible, the targets are 32 px) or native with a check after
   the choice?** Recommended: calendar.
8. **Pikaday: deprecate on npm at the next major?** Recommended: yes.
   Flatpickr stays.
9. **Zone algorithm in two places (core and sheet), or the sheet's core
   allowed to import one plain module from core?** Recommended: two places
   with shared vectors. The sheet's boundary rule is worth more than 150
   lines.
10. **Date and time without a zone ("floating", `YYYY-MM-DDTHH:mm`)?**
    Recommended: not in the first version. The sheet has no such type
    either. `@timeZone="utc"` gives a fixed interpretation when needed.
11. **Default locale: the document's `lang`, then the browser's.** Or
    should an app-wide locale come from `eui-i18n` or `euiConfig`?
    Recommended: `lang`, plus `componentDefaults.EuiDatePicker.locale` in
    the config, since `eui-i18n` has no locale today.
12. **Where this document lives.** `internal/` was removed from the
    repository in commit `09d2a6f2` ("remove internal/, the finished spikes,
    audits and results"). This file recreates
    `internal/spikes/date-picker/`. Keep it there while the work is open, or
    move it? Recommended: keep it until batch 8, then delete it as the
    others were.

## 15. What was checked and what was not

### Checked, by reading

- Upstream 123.1.0 compiled sources: `date_picker.js`,
  `date_picker.styles.js`, `date_picker_range.js`, `date_picker.a11y.js`,
  and the fork's `index.js`, `date_utils.js`, `calendar.js`, `month.js`,
  `day.js`, `time.js`, the dropdowns (by search), `original.package.json`,
  and the package's `NOTICE.txt`.
- Upstream tests and the docs page's source, from GitHub at tag `v123.1.0`
  (the docs source is identical on `main`).
- ember-eui: `datetime-picker.gts` in full; `eui-date-picker-range.gts`;
  `eui-field-text.gts`; the signatures and focus paths of `eui-popover.gts`,
  `eui-input-popover.gts`, `eui-focus-trap.gts`; `focus-trap-registry.ts`;
  `eui-form-control-layout-context.ts`; `eui-config.ts`;
  `utils/eui/date-pickers.ts` (selectors); `package.json`,
  `rollup.config.mjs`, `NOTICE.md`; the generator's date picker block; the
  docs layout; test module names; the flatpickr and pikaday components and
  their docs.
- The sheet: `date.ts`, `date-time.ts`, both editors, `edit.ts`, the
  boundary test; and V03-DESIGN section 10.3 from git history.
- npm metadata: `@zag-js/date-picker` 1.49.0 and its dependencies,
  `@internationalized/date` 3.12.4, `temporal-polyfill` 1.0.8; that
  `@zag-js/ember` does not exist.
- MDN browser-compat-data for `Intl.Locale#getWeekInfo` and `Temporal`.
- Capacitor's `CapacitorGlobal` definition for `isNativePlatform`.

### Not checked, or different from the brief

- **The published docs page** (`eui.elastic.co/…/date-picker/`) could not
  be fetched: the sandbox proxy answered "Approval required for
  eui.elastic.co". Its source file was read instead. The rendered prop table
  was not seen; the props come from the compiled source.
- **The Linux EUI copy** named in the brief does not exist any more. The
  repository's own install was read. Only `es/` (compiled) is shipped, so
  the TypeScript sources and line numbers are not upstream's originals.
- **`internal/spikes/`** does not exist at HEAD. The sheet design and the
  date pickers handoff were read with `git show HEAD~1:…`. The handoff is
  partly stale: it lists `minDate`/`maxDate`, pretty durations and the time
  zone display as not ported, and they now exist. The code was trusted.
- **Core is 16.4.0**, not 16.3.0.
- **Nothing was run.** No build, no test, no prototype. Sizes in section 12
  are estimates. Bundle size of the design, and of zag, is not measured.
- **Devices and screen readers**: not available. Everything in 6.3 about OS
  pickers is to be confirmed on devices (6.4); none of it is relied on for
  correctness, because every value is validated by the component.
- **RTL behaviour of `EuiPopover`'s anchor positions** was not read; it is a
  test item.
- **What a new docs page must register** beyond the folder was not traced
  fully. Known: `site/docfy.config.mjs` picks up `packages/*/docs/**/*.md`
  by pattern, and `scripts/api-docs-pages.json` lists the pages with a
  generated API section. Not read: `site/app/demo-playgrounds.json` (it
  mentions the date picker range), `scripts/generate-llms-txt.mjs`,
  `scripts/upstream-prop-audit.mjs`.
- **The fork's dropdown files** were searched, not read line by line. They
  are replaced by `EuiSelect`s, so their details do not carry over.
- **Prysmex's uses of flatpickr and pikaday** were not inventoried.

## 16. Decided (the user, 2026-11-24)

The user said "ok go then" after the recommendations of section 14 were
summarised as reasonable, so batch 0 takes every recommendation of
section 14 as decided (1 to 12). Any can still be overruled; the
implementation report lists them again.

Also decided by the user:

- The new calendar is centralised: batch 7 moves `EuiSuperDatePicker`'s
  absolute tab onto it. `EuiSuperDatePicker`'s public API does not change
  (`@start`/`@end` strings, `@onTimeChange` strings, `@minDate`/`@maxDate`
  moments); moment and `@elastic/datemath` stay inside it. Its existing
  tests must pass unchanged, and it is checked in Prysmex before release.
- `@ember-eui/flatpickr` stays published and unchanged (Prysmex uses it).
- Work happens on the branch `feat/date-picker` (from `master`). This
  document stays untracked (the user removed `internal/` from the
  repository on 2026-11-23).

## 17. Demo parity with upstream (the user, 2026-11-24)

"Support all of the date-and-time demos from upstream Elastic UI."
Upstream's category `docs/components/forms/date-and-time` at `v123.1.0`
has four pages; every demo on them must have an ember-eui counterpart that
does the same thing, with the same title where the page has a section:

- **Date picker** (new page, batches 3 to 6): basic; Date picker states;
  Time selection; Locale; Only allow specific dates and times; Open to a
  specific date; Custom input (the custom trigger, batch 6); UTC offsets;
  Inline display; Custom classes. Section 10.4's list covers these, with
  one change: **"UTC offsets" stays a demo of its own**, as upstream
  shows it (a select of fixed offsets, GMT -01:00 to -03:00, applied to a
  date and time). So `@timeZone` also accepts a **fixed offset** string
  (`"+05:30"`, `"-02:00"`, no DST) besides `'local'`, `'utc'` and an IANA
  name. That is added to batch 4 (zones), with unit tests in the zone
  vectors (a fixed offset has no gap or overlap). The time-zone demo
  (10.4 item 4) stays as an extra. The native demo and the custom-trigger
  demo are extras too.
- **Date picker range** (batch 6): upstream's three demos, basic,
  "Inline display" and "Dynamic `minDate` and `maxDate`", all with
  `EuiDatePicker` (today they use flatpickr, pikaday or native inputs).
  The existing extras (form-row validation, prepend and append) stay; one
  demo with native inputs stays.
- **Super date picker** (batch 7): ember-eui's page already has 20 demos
  covering every upstream one. All 20 must work unchanged after the
  absolute tab moves onto the new calendar: they are batch 7's acceptance,
  checked with real input in a browser, besides the unchanged tests.
- **Auto refresh** (batch 8, docs only): upstream has a page of its own
  (basic, "Auto refresh button", "Refresh interval"). ember-eui has the
  components and shows these demos on the super date picker page
  (d13 to d17). Add an "Auto refresh" page mirroring upstream's three
  demos; the super date picker page keeps its demos.

Each batch that adds or changes a demo checks it in a real browser on a
production build of the docs site.

## 18. Moment and Date as input values (the user, 2026-11-24)

The internals stay moment-free (batch 1), and `@onChange` always emits
strings, as decided. As a convenience for upstream-style code and for the
super date picker (batch 7), `@value` (and `@minDate`, `@maxDate`,
`@openToDate`, `@excludeDates`, `@includeDates`, `@startDate`,
`@endDate`) also **accept a moment or a `Date`** and convert it on the
way in, in batch 3:

- **No import of moment.** A moment is recognised by duck typing
  (`moment.isMoment`-like check: an object with `isValid`, `toISOString`,
  `format` and `utcOffset` functions, or the `_isAMomentObject` flag), so
  the no-moment boundary test still holds.
- **Conversion.** A date-only picker takes the moment's or the `Date`'s
  calendar day in the picker's zone (`@timeZone`, default local); with
  `@showTimeSelect` it takes the instant (`toISOString()`); with
  `@showTimeSelectOnly` the wall-clock time in the zone. An invalid moment
  or `Date` is treated as no value, with a development warning.
- **Never mutated.** The picker only reads from the object.
- **Output unchanged.** `@onChange` gets the string, never a moment. The
  docs show converting back (`moment(value)`) where an app wants one.
- Tests: moment input (a real moment in the tests only, as a
  devDependency already present), `Date` input, an invalid one, a moment
  with a UTC offset, and the boundary test still passing.

## 19. Decided after batch 3 (the user, 2026-11-24)

- A **valid** moment or `Date` passed as a value is accepted silently: no
  development notice. Only an invalid one warns. Batch 2's test that pins
  the notice for a valid `Date` belongs to this unreleased feature and is
  updated to the decision (batch 4).
- The **shared** `outside-click-detector` / focus-trap change of batch 3
  (`inAttachedSurface`: a press inside a portalled panel attached to an
  active focus trap counts as inside that trap's element) stays, as a
  fix for every popover in core. It is in the changeset; check it in
  Prysmex before the release.

## 20. Decided after batch 7 (the user, 2026-11-24)

- **`@utcOffset` and `@timeFormat` reach the Absolute tab, as upstream
  does** ("do what's supposed to be correct"). Upstream's
  `EuiDatePopoverContent` passes `utcOffset` (minutes) and `timeFormat`
  (a moment format) to the Absolute tab's date picker. Here: `@utcOffset`
  becomes the calendar's fixed-offset zone (`"±HH:MM"`), and
  `@timeFormat` decides the time list's clock (12-hour when it has `h`
  or `a`, seconds when it has `s`), on `EuiSuperDatePicker` and on
  `EuiDatePopoverButton`. Without them, nothing changes. Prysmex's
  relative-date field forwards both but no caller sets them, so Prysmex
  sees no change today.
- **`eui-super-date-picker/utils/date-utils.ts` stays** (unused by core,
  still published) until the next major.
- **Pikaday:** its docs page keeps the neutral "EuiDatePicker is
  available" note; no deprecation is announced.

## 21. Decided after batch 8 (the user, 2026-11-25)

- `@utcOffset` on `EuiSuperDatePicker` and `EuiDatePopoverButton` keeps
  upstream 123.1.0's meaning: it only decides which day the calendar
  marks as today; dates are shown and picked in the browser's zone
  (`096e2fed`, pinned by batch 7's test). Apps that need picking in
  another zone use `EuiDatePicker`'s `@timeZone`.
- The user pushes `feat/date-picker`; then the Prysmex checks and the
  device checks; then merge and release (alignment changeset, npm
  version check first).
