/*
 * Ported from @elastic/eui 123.1.0 `components/date_picker/date_picker.js`
 * (the wrapper, its inline styles and form states) and its fork of
 * react-datepicker@2.0.0 (`react-datepicker/src/index.js`: the input in an
 * `EuiPopover`), MIT, Copyright (c) 2018 HackerOne Inc and individual
 * contributors (see NOTICE.md). EUI's code: Copyright Elasticsearch B.V.
 * and/or licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. Licensed under the Elastic License 2.0 or the Server
 * Side Public License, v 1; see vendor/eui-latest.
 *
 * The values are strings (DESIGN 4, 5), the logic is new: typed text is
 * committed on Enter, blur and pick, never per keystroke (DESIGN 5.3).
 * Times follow DESIGN 5.2: an instant is shown and chosen as a wall clock
 * in `@timeZone`, and only a different wall clock changes the value.
 * On phones and in Capacitor apps the OS input takes the place of the text
 * input and the popover (DESIGN 6), with the same arguments and values.
 */
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { warn } from '@ember/debug';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { getOwner } from '@ember/owner';
import { later, next as next_, schedule } from '@ember/runloop';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';
import { or } from 'ember-truth-helpers';
import { tabbable } from 'tabbable';

import { datePickerRangeContext } from '../-private/eui-date-picker-range-context.ts';
import {
  choosesNative,
  markEmpty,
  nativeAttributes,
  nativeEnvironment,
  readNative,
  unsupportedByNative
} from '../-private/native-date-input.ts';
import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiDatePickerInputErrorStyles,
  euiDatePickerNativeStyles,
  euiDatePickerRangeInputStyles
} from '../utils/eui/date-pickers.ts';
import { euiDatePickerStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { validIsoDate } from '../utils/date/calendar-date.ts';
import {
  dayLimits,
  dayProblem,
  isUnreadableLimit,
  limitsConflict
} from '../utils/date/calendar-nav.ts';
import {
  datePlaceholder,
  formatDate,
  formatDateTime,
  formatTime,
  localeDefaults,
  timePlaceholder
} from '../utils/date/format.ts';
import {
  instantString,
  parseDateText,
  parseDateTimeText,
  parseInstant,
  parseTimeText,
  parseTimeValue,
  timeValueOf
} from '../utils/date/parse.ts';
import {
  changesValue,
  instantAt,
  instantProblem,
  timeInterval,
  timeList,
  timeProblem
} from '../utils/date/times.ts';
import { isInvalidDateObject, toDateValue } from '../utils/date/value.ts';
import {
  dayAt,
  normalizeTimeZone,
  startOfDayIn,
  todayIn,
  validTimeZone,
  wallAt,
  wallOf,
  withDay
} from '../utils/date/zone.ts';
import EuiDatePickerCalendar from './eui-date-picker/calendar.gts';
import EuiDatePickerNativeInput from './eui-date-picker/native-input.gts';
import EuiFieldText from './eui-field-text.gts';
import EuiFormControlLayout from './eui-form-control-layout.gts';
import EuiPopover from './eui-popover.gts';

import type {
  EuiDatePickerNative,
  NativeAttributes,
  NativeContext,
  NativeReading
} from '../-private/native-date-input.ts';
import type { Weekday } from '../utils/date/calendar-date.ts';
import type { DayLimits, LimitProblem } from '../utils/date/calendar-nav.ts';
import type { DateOrder, TimeOfDay } from '../utils/date/parse.ts';
import type { InstantRules, TimeEntry } from '../utils/date/times.ts';
import type { DateInput, PickerMode } from '../utils/date/value.ts';
import type { CalendarTimeOptions } from './eui-date-picker/calendar.gts';
import type EuiConfigService from '../services/eui-config.ts';
import type EuiI18n from '../services/eui-i18n.ts';
import type {
  EuiPopoverPanelProps,
  PopoverAnchorPosition
} from './eui-popover.gts';
import type { TOC } from '@ember/component/template-only';
import type Owner from '@ember/owner';

/** Why typed text was refused (`@onInputError`). */
export type EuiDatePickerInputErrorReason = 'unreadable' | LimitProblem;

export interface EuiDatePickerInputError {
  /** The text as typed. */
  text: string;
  /** `'unreadable'`: not a date (or a date and time, or a time) in the field's order; `'min'`, `'max'`: outside the limits (`@minDate`, `@maxDate`, `@minTime`, `@maxTime`); `'disabled'`: excluded, not included or filtered out. */
  reason: EuiDatePickerInputErrorReason;
}

/**
 * A date picker (upstream `EuiDatePicker`): a text input that opens a
 * calendar in a popover, or the calendar alone with `@inline`; with
 * `@showTimeSelect` a time list too, with `@showTimeSelectOnly` the time
 * list alone. Values are strings: `YYYY-MM-DD`, a UTC ISO instant, or
 * `HH:mm`; a `Date` or a moment is read too. Typed text is committed on
 * Enter, on blur and on a pick. Attributes go to the input, or to the
 * calendar with `@inline`.
 */
export interface EuiDatePickerSignature {
  /** `...attributes` go to the text input; with `@inline`, to the calendar's root (`div.react-datepicker`, `role="group"`). */
  Element: HTMLInputElement | HTMLDivElement;
  Args: {
    /**
     * The value: `YYYY-MM-DD`; with `@showTimeSelect` an instant, a UTC ISO
     * string (`2026-11-24T15:30:00.000Z`, or with an offset); with
     * `@showTimeSelectOnly` a time, `HH:mm` (or `HH:mm:ss`). Also a `Date`
     * or a moment: its day, its instant or its time in `@timeZone` is read.
     * `null` or `undefined` for none.
     */
    value?: DateInput | null;
    /** Called with the new value (`YYYY-MM-DD`, a UTC ISO instant ending in `Z`, or `HH:mm`), or `null` when the text is emptied. Never with a day or time that cannot be chosen, never per keystroke. */
    onChange?: (value: string | null) => void;
    /** Shows the clear button while there is a value; empty the value there. */
    onClear?: () => void;
    /** Called when committed text cannot be read, or names a day or time that cannot be chosen. `@onChange` is not called then. */
    onInputError?: (error: EuiDatePickerInputError) => void;

    /** A time list beside the calendar: the value becomes an instant, shown in `@timeZone`. */
    showTimeSelect?: boolean;
    /** Only a time list, no calendar: the value becomes a time of day, `HH:mm`. Wins over `@showTimeSelect`. */
    showTimeSelectOnly?: boolean;
    /** Minutes between the entries of the time list, from midnight. Defaults to `30`. */
    timeIntervals?: number;
    /** Keep and show seconds: typed seconds are kept, and a time value is `HH:mm:ss`. Defaults to `false`. */
    seconds?: boolean;
    /** A 12-hour clock (`3:30 pm`) in the input and the time list. Defaults to `@locale`'s. */
    hour12?: boolean;
    /** Times before it are disabled, `HH:mm`. */
    minTime?: string | null;
    /** Times after it are disabled, `HH:mm`. */
    maxTime?: string | null;
    /** These times are disabled, `HH:mm`. */
    excludeTimes?: readonly string[] | null;
    /** Extra entries in the time list, `HH:mm`, marked as injected. */
    injectTimes?: readonly string[] | null;

    /** Shows the calendar in the page instead of the text input and the popover. */
    inline?: boolean;
    /** With `@inline`: the raised frame. Defaults to `true`. */
    shadow?: boolean;
    /** Closes the popover after a day is picked (with `@showTimeSelect`, after a time is). Defaults to `true`. */
    shouldCloseOnSelect?: boolean;
    /** Arrow keys and the month and year selects change the value at once, not only show another day (upstream's default is `true`). Defaults to `false`. */
    adjustDateOnChange?: boolean;
    /** Where the popover opens, any `EuiPopover` `@anchorPosition`. Defaults to `'downLeft'`; `'downRight'` in the `<:end>` block of an `EuiDatePickerRange`. */
    popoverPlacement?: PopoverAnchorPosition;

    /** `'local'`, `'utc'`, an IANA name (`'America/New_York'`) or a fixed offset (`'-03:00'`, upstream's `utcOffset`): the zone instants are shown and chosen in, the zone of "today", and of a `Date` or a moment. Defaults to `'local'`. */
    timeZone?: 'local' | 'utc' | (string & {});
    /** BCP 47 tag for names and defaults. Defaults to `componentDefaults.EuiDatePicker.locale` in `euiConfig`, then the document's language, then the browser's. */
    locale?: string;
    /** The order typed and shown: `'dmy'` (`24/11/2026`), `'mdy'` (`11/24/2026`) or `'ymd'` (`2026-11-24`). Defaults to the order of `@locale`. */
    dateOrder?: DateOrder;
    /** The first day of the week, 0 (Sunday) to 6. Defaults to `@locale`'s. */
    firstDayOfWeek?: Weekday;

    /** Days before are disabled (`YYYY-MM-DD`, a `Date` or a moment). With `@showTimeSelect` also an instant (a `Date` or a moment counts as one): earlier times are disabled. */
    minDate?: DateInput | null;
    /** Days after are disabled (`YYYY-MM-DD`, a `Date` or a moment). With `@showTimeSelect` also an instant (a `Date` or a moment counts as one): later times are disabled. */
    maxDate?: DateInput | null;
    /** These days are disabled. */
    excludeDates?: readonly DateInput[] | null;
    /** When given, only these days are enabled. */
    includeDates?: readonly DateInput[] | null;
    /** Called with `YYYY-MM-DD`; `false` disables the day. */
    filterDate?: ((date: string) => boolean) | null;

    /** The month shown when there is no value. */
    openToDate?: DateInput | null;
    /** Extra classes for a day, called with `YYYY-MM-DD` (upstream `dayClassName`). */
    dayClassName?: (date: string) => string | null | undefined;
    /** Extra classes on the calendar (upstream `calendarClassName`). */
    calendarClass?: string;
    /** Extra classes on the popover panel (upstream `popperClassName`). */
    popoverClass?: string;

    /** This picker chooses the start of a range: hovering a day previews the range from it to `@endDate` (upstream `selectsStart`). */
    selectsStart?: boolean;
    /** This picker chooses the end of a range: hovering a day previews the range from `@startDate` to it (upstream `selectsEnd`). */
    selectsEnd?: boolean;
    /** The range's start, for the highlight: `YYYY-MM-DD`, an instant (its day in `@timeZone`), a `Date` or a moment. The days from `@startDate` to `@endDate` are highlighted when both are given. */
    startDate?: DateInput | null;
    /** The range's end, for the highlight; as `@startDate`. */
    endDate?: DateInput | null;

    /** Id of the input, e.g. to match an `EuiFormRow`'s `@id`. Defaults to a random id. */
    id?: string;
    /** Placeholder text. Defaults to the display format spelled out (`DD/MM/YYYY`). */
    placeholder?: string;
    /** Stretches the input to its container's width. */
    fullWidth?: boolean;
    /** Shorter input (32px instead of 40px). */
    compressed?: boolean;
    /** The invalid look; also shown for typed text that was refused and for a value that cannot be read. */
    isInvalid?: boolean;
    /** Shows a spinner. */
    isLoading?: boolean;
    /** Disables the input; nothing opens. */
    disabled?: boolean;
    /** Read-only input; nothing opens. */
    readOnly?: boolean;
    /** The icon in the input. Defaults to `true`. */
    showIcon?: boolean;
    /** The icon's type, anything `EuiIcon`'s `@type` accepts. Defaults to `'calendar'`, or `'clock'` with `@showTimeSelectOnly`. */
    iconType?: string;
    /** Renders the input and its popover without the form control layout (no icon, clear button, prepend or append); with `@inline`, the calendar without its frame. Set for you inside `EuiDatePickerRange`, which also passes its `@inline`, `@compressed`, `@fullWidth`, `@readOnly`, `@disabled` and `@isInvalid` (the picker's own `@disabled` and `@isInvalid` add to the range's; its other own arguments win). */
    controlOnly?: boolean;
    /** Called with the `<input>` element once rendered. */
    inputRef?: (element: HTMLInputElement | null) => void;

    /**
     * The OS picker instead of the calendar: `<input type="date">`,
     * `datetime-local` (the wall clock in `@timeZone`) or `time`, with the
     * same values. `'auto'` takes it in a Capacitor app on a device and when
     * the primary pointer is coarse (a phone, a tablet), unless an argument
     * the OS cannot honour is given (`@filterDate`, `@excludeDates`,
     * `@includeDates`, `@excludeTimes`, `@injectTimes`, `@dayClassName`).
     * `true` and `false` force a path; `@inline` and a `<:trigger>` block
     * always show the calendar.
     * Chosen once, when the picker is created. Every value the OS returns is
     * checked as typed text is. Defaults to
     * `componentDefaults.EuiDatePicker.native` in `euiConfig`, then `'auto'`.
     */
    native?: EuiDatePickerNative;
  };
  Blocks: {
    /** Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. */
    prepend: [className: string, inputId: string];
    /** Content after the input; yields the class to put on it and the input id. */
    append: [className: string, inputId: string];
    /**
     * A trigger of your own instead of the text input (upstream
     * `customInput`), e.g. an `EuiButton`: call `open` on its click. It
     * yields `open`, `isOpen` and `text`, the value in the display format.
     * The calendar takes focus when it opens and gives it back to the
     * trigger when it closes; there is no typed input, icon or native path.
     * `...attributes` go to the element around the trigger.
     */
    trigger: [EuiDatePickerTrigger];
  };
}

/** What `<:trigger>` yields. */
export interface EuiDatePickerTrigger {
  /** Opens the calendar and moves focus into it. */
  open: () => void;
  /** The calendar is open. */
  isOpen: boolean;
  /** The value in the display format (`24/11/2026`), or `''`. */
  text: string;
}

/** The input (or `<:trigger>`) and its popover: the control, with or without the layout (`@controlOnly`). */
const DatePickerControl: TOC<{
  Element: HTMLInputElement | HTMLDivElement;
  Args: { picker: EuiDatePicker; hasTrigger?: boolean };
  Blocks: { trigger: [EuiDatePickerTrigger] };
}> = <template>
  <EuiPopover
    @isOpen={{@picker.isOpen}}
    @closePopover={{@picker.onClickOutside}}
    @ownFocus={{false}}
    @initialFocus={{false}}
    @hasArrow={{false}}
    @buffer={{0}}
    @display="block"
    @panelPaddingSize="none"
    @anchorPosition={{@picker.anchorPosition}}
    @panelClassName={{@picker.args.popoverClass}}
    @panelProps={{@picker.panelProps}}
    @panelRef={{@picker.registerPanel}}
    @ariaLabel={{@picker.dialogLabel}}
    @focusTrapProps={{@picker.focusTrapProps}}
    @focusTrapOptions={{@picker.focusTrapOptions}}
    @onTrapDeactivation={{@picker.onTrapDeactivation}}
  >
    <:button>
      {{#if @hasTrigger}}
        <div
          class="react-datepicker__input-container euiDatePicker__trigger"
          ...attributes
          {{@picker.registerAnchor}}
          {{on "focusout" @picker.onFocusOut}}
        >
          {{yield @picker.triggerApi to="trigger"}}
        </div>
      {{else}}
        <div class="react-datepicker__input-container">
          <EuiFieldText
            @controlOnly={{true}}
            @id={{@picker.inputId}}
            @value={{@picker.text}}
            @placeholder={{@picker.placeholder}}
            @compressed={{@picker.compressed}}
            @fullWidth={{@picker.fullWidth}}
            @isInvalid={{@picker.isInvalid}}
            @disabled={{@picker.disabled}}
            @readOnly={{@picker.readOnly}}
            @inputRef={{@picker.registerInput}}
            class="euiDatePicker
              {{@picker.rangeInputClass}}
              {{@picker.inputErrorClass}}"
            autocomplete="off"
            aria-haspopup="dialog"
            aria-expanded={{if @picker.isOpen "true" "false"}}
            aria-controls={{if @picker.isOpen @picker.panelId}}
            ...attributes
            {{on "input" @picker.onInput}}
            {{on "focus" @picker.onInputFocus}}
            {{on "click" @picker.onInputClick}}
            {{on "keydown" @picker.onInputKeyDown}}
            {{on "focusout" @picker.onFocusOut}}
          />
        </div>
      {{/if}}
    </:button>
    <:content>
      {{! template-lint-disable no-pointer-down-event-binding }}
      <div
        class="euiDatePicker__popoverContent"
        {{@picker.focusGrid @picker.gridFocusRequest}}
        {{on "focusin" @picker.onPanelFocusIn}}
        {{on "focusout" @picker.onFocusOut}}
        {{on "pointerdown" @picker.onPanelPointerDown}}
        {{on "keydown" @picker.onPanelKeyDown}}
      >
        <EuiDatePickerCalendar
          @selected={{@picker.selectedDay}}
          @preview={{@picker.preview}}
          @selectsStart={{@picker.args.selectsStart}}
          @selectsEnd={{@picker.args.selectsEnd}}
          @rangeStart={{@picker.rangeStart}}
          @rangeEnd={{@picker.rangeEnd}}
          @onPick={{@picker.onPick}}
          @openToDate={{@picker.openToDate}}
          @minDate={{@picker.minDate}}
          @maxDate={{@picker.maxDate}}
          @excludeDates={{@picker.excludeDates}}
          @includeDates={{@picker.includeDates}}
          @filterDate={{@picker.args.filterDate}}
          @timeZone={{@picker.zone}}
          @locale={{@picker.localeDefaults.locale}}
          @firstDayOfWeek={{@picker.firstDayOfWeek}}
          @dayClassName={{@picker.args.dayClassName}}
          @calendarClass={{@picker.args.calendarClass}}
          @showTimeSelect={{@picker.showTimeSelect}}
          @showTimeSelectOnly={{@picker.timeOnly}}
          @timeOptions={{@picker.timeOptions}}
          @selectedTime={{@picker.selectedTime}}
          @hour12={{@picker.hour12}}
          @onPickTime={{@picker.onPickTime}}
          @onMove={{@picker.onMove}}
        />
      </div>
    </:content>
  </EuiPopover>
</template>;

/** The inline calendar: in its frame (`@inline`), or bare (`@inline` and `@controlOnly`, e.g. in an inline `EuiDatePickerRange`). */
const DatePickerInlineCalendar: TOC<{
  Element: HTMLDivElement;
  Args: { picker: EuiDatePicker };
}> = <template>
  <EuiDatePickerCalendar
    role="group"
    aria-label={{@picker.calendarLabel}}
    @selected={{@picker.selectedDay}}
    @onSelect={{@picker.onSelect}}
    @openToDate={{@picker.openToDate}}
    @minDate={{@picker.minDate}}
    @maxDate={{@picker.maxDate}}
    @excludeDates={{@picker.excludeDates}}
    @includeDates={{@picker.includeDates}}
    @filterDate={{@picker.args.filterDate}}
    @timeZone={{@picker.zone}}
    @locale={{@picker.localeDefaults.locale}}
    @firstDayOfWeek={{@picker.firstDayOfWeek}}
    @dayClassName={{@picker.args.dayClassName}}
    @calendarClass={{@picker.args.calendarClass}}
    @disabled={{@picker.disabled}}
    @readOnly={{@picker.readOnly}}
    @showTimeSelect={{@picker.showTimeSelect}}
    @showTimeSelectOnly={{@picker.timeOnly}}
    @timeOptions={{@picker.timeOptions}}
    @selectedTime={{@picker.selectedTime}}
    @hour12={{@picker.hour12}}
    @onPickTime={{@picker.onPickTime}}
    @onMove={{@picker.onMove}}
    @selectsStart={{@picker.args.selectsStart}}
    @selectsEnd={{@picker.args.selectsEnd}}
    @rangeStart={{@picker.rangeStart}}
    @rangeEnd={{@picker.rangeEnd}}
    ...attributes
  />
</template>;

/**
 * A date picker (upstream `EuiDatePicker`): a text input that opens a
 * calendar in a popover, or the calendar alone with `@inline`. Values are
 * `YYYY-MM-DD` strings; a `Date` or a moment is also read. Typed text is
 * committed on Enter, on blur and on a pick, never while typing.
 */
export default class EuiDatePicker extends Component<EuiDatePickerSignature> {
  @service declare euiI18n: EuiI18n;

  /** Text typed and not committed yet, with the value it was typed over; null shows the value's text. */
  @tracked private typed: { text: string; over: string | null } | null = null;
  /** The reason committed text was refused, while that text is shown. */
  @tracked private inputError: EuiDatePickerInputErrorReason | null = null;
  @tracked isOpen = false;
  /** Focus is in the calendar: its focus trap holds it (DESIGN 7.3). */
  @tracked private trapActive = false;
  @tracked private hasFocus = false;
  @tracked panelId: string | undefined;
  /** Bumped when focus must go to the calendar's tab stop once it is rendered. */
  @tracked gridFocusRequest = 0;
  private handledGridFocus = 0;

  private input: HTMLInputElement | null = null;
  private panel: HTMLElement | null = null;
  /** With `<:trigger>`: the element around the trigger, and the element that had focus when it opened the calendar. */
  private anchor: HTMLElement | null = null;
  private triggerFocus: HTMLElement | null = null;
  /** The next focus event is the picker's own (returning focus): it does not open the popover. */
  private ownFocus = false;
  /** A press in the panel is under way: the input's blur is not a commit (Safari does not focus buttons on click). */
  private pressInPanel = false;
  fallbackId = randomId();
  /** The native path is taken (DESIGN 6.2), chosen once; see the constructor. */
  @tracked private nativeChosen = false;

  constructor(owner: Owner, args: EuiDatePickerSignature['Args']) {
    super(owner, args);
    const environment = owner.lookup('-environment:main') as
      { isInteractive?: boolean; _renderMode?: string } | undefined;
    if (environment?._renderMode === 'rehydrate') {
      // the server rendered the calendar path's markup: the first render
      // here matches it, and the native input takes its place once after
      // (DESIGN 6.2, 13)
      schedule('afterRender', () => {
        if (this.isDestroying || this.isDestroyed) return;
        this.nativeChosen = this.chooseNative(true);
      });
    } else {
      this.nativeChosen = this.chooseNative(
        environment?.isInteractive !== false
      );
    }
  }

  /** DESIGN 6.2: `@inline`, then `@native`, then the config, then auto. Server rendering takes the calendar. */
  private chooseNative(interactive: boolean): boolean {
    // on the server nothing of the browser is read (9 #48)
    const environment = interactive
      ? nativeEnvironment()
      : { browser: false, nativePlatform: false, coarsePointer: false };
    return choosesNative(
      {
        inline: this.inline,
        // a `<:trigger>` block takes the calendar too (rule 1), but
        // has-block is only known to the template, which applies it
        trigger: false,
        native: this.args.native,
        config: this.configDefaults?.native,
        unsupported: unsupportedByNative(this.args).length > 0
      },
      environment
    );
  }

  /** The OS input renders: native was chosen, and the picker is neither inline nor read-only (read-only shows the text input, DESIGN 6.3). */
  get nativeInput(): boolean {
    return this.nativeChosen && !this.inline && !this.readOnly;
  }

  get context() {
    return getEuiThemeContext(this);
  }

  /* The range (DESIGN 4.5) */

  /** The `EuiDatePickerRange` block this picker is in, or null. */
  get range() {
    return datePickerRangeContext(this);
  }

  /** `@inline`, else the range's. */
  get inline(): boolean {
    return this.args.inline ?? this.range?.inline ?? false;
  }

  /** `@controlOnly`, else true in a range: the range draws the frame. */
  get controlOnly(): boolean {
    return this.args.controlOnly ?? this.range?.controlOnly ?? false;
  }

  get compressed(): boolean {
    return this.args.compressed ?? this.range?.compressed ?? false;
  }

  get fullWidth(): boolean {
    return this.args.fullWidth ?? this.range?.fullWidth ?? false;
  }

  get readOnly(): boolean {
    return this.args.readOnly ?? this.range?.readOnly ?? false;
  }

  /** `@disabled`, or the range's (upstream ORs them). */
  get disabled(): boolean {
    return Boolean(this.args.disabled || this.range?.disabled);
  }

  /** Tells the range whether this picker shows a time list; read by the template. */
  get rangeReport(): null {
    this.reportToRange(this.range, this.showTimeSelect);
    return null;
  }

  private reportToRange(
    range: ReturnType<typeof datePickerRangeContext>,
    showTimeSelect: boolean
  ) {
    range?.reportTimeSelect(this, showTimeSelect);
    this.reportedRange = range;
  }

  /** The range told last, told again when the picker goes. */
  private reportedRange: ReturnType<typeof datePickerRangeContext> = null;

  /** A range argument as a day: `YYYY-MM-DD`, or the day of an instant in the zone. */
  private rangeDay(value: unknown): string | null {
    if (value == null || value === '') return null;
    const read = toDateValue(value, this.zone, this.limitMode);
    const day = validIsoDate(read);
    if (day !== null) return day;
    const ms = parseInstant(read);
    return ms === null ? null : dayAt(ms, this.zone);
  }

  /** `@startDate` as a day, for the range highlight. */
  get rangeStart(): string | null {
    return this.rangeDay(this.args.startDate);
  }

  /** `@endDate` as a day, for the range highlight. */
  get rangeEnd(): string | null {
    return this.rangeDay(this.args.endDate);
  }

  /* Values (DESIGN 4.2, 18) */

  /** What the value is: a day, an instant (`@showTimeSelect`) or a time (`@showTimeSelectOnly`, which wins, 9 #42). */
  get mode(): PickerMode {
    if (this.args.showTimeSelectOnly) return 'time';
    return this.args.showTimeSelect ? 'dateTime' : 'date';
  }

  get timeOnly(): boolean {
    return this.mode === 'time';
  }

  /** The time list beside the calendar. */
  get showTimeSelect(): boolean {
    return this.mode === 'dateTime';
  }

  get seconds(): boolean {
    return Boolean(this.args.seconds);
  }

  get zone(): string {
    return normalizeTimeZone(this.args.timeZone);
  }

  get hasUnknownZone(): boolean {
    return !validTimeZone(this.args.timeZone);
  }

  /** `@value` as the picker reads it: a `Date` or a moment as its day, instant or time in the zone. */
  get rawValue(): unknown {
    return toDateValue(this.args.value, this.zone, this.mode, this.seconds);
  }

  /** Date and time: the value's instant in ms, else null. */
  get valueMs(): number | null {
    return this.mode === 'dateTime' ? parseInstant(this.rawValue) : null;
  }

  /** Time only: the value's time of day, else null. */
  get valueTime(): TimeOfDay | null {
    return this.mode === 'time' ? parseTimeValue(this.rawValue) : null;
  }

  /** The value when it can be read, normalized (`YYYY-MM-DD`, `…Z`, `HH:mm`), else null. */
  get value(): string | null {
    switch (this.mode) {
      case 'dateTime': {
        const ms = this.valueMs;
        return ms === null ? null : instantString(ms);
      }
      case 'time': {
        const time = this.valueTime;
        return time === null
          ? null
          : timeValueOf(time, this.seconds || time.second !== 0);
      }
      default:
        return validIsoDate(this.rawValue);
    }
  }

  /** The calendar's selected day: the value, or the day of its instant in the zone. */
  get selectedDay(): string | null {
    const ms = this.valueMs;
    if (ms !== null) return dayAt(ms, this.zone);
    return this.mode === 'date' ? this.value : null;
  }

  /** The time list's selected time: the value's, or its instant's wall clock in the zone. */
  get selectedTime(): TimeOfDay | null {
    const ms = this.valueMs;
    if (ms !== null) {
      const wall = wallAt(ms, this.zone);
      return { hour: wall.h, minute: wall.mi, second: wall.s };
    }
    return this.valueTime;
  }

  /** A value is present but cannot be read (9 #1), or an invalid `Date` or moment (18). */
  get hasUnreadableValue(): boolean {
    const raw = this.rawValue;
    if (isInvalidDateObject(this.args.value)) return true;
    return raw != null && raw !== '' && this.value === null;
  }

  /** A date argument: a day, or (`@minDate`, `@maxDate` with `@showTimeSelect`) a day or an instant. */
  private dateArg(value: unknown, mode: PickerMode = 'date'): string | null {
    const read = toDateValue(value, this.zone, mode);
    return typeof read === 'string' ? read : null;
  }

  /** The mode limits are read in: an instant with `@showTimeSelect`, else a day. */
  private get limitMode(): PickerMode {
    return this.mode === 'dateTime' ? 'dateTime' : 'date';
  }

  get minDate(): string | null {
    return this.dateArg(this.args.minDate, this.limitMode);
  }

  get maxDate(): string | null {
    return this.dateArg(this.args.maxDate, this.limitMode);
  }

  get openToDate(): string | null {
    return this.dateArg(this.args.openToDate);
  }

  @cached
  get excludeDates(): string[] | null {
    const dates = this.args.excludeDates;
    return dates ? this.dateList(dates) : null;
  }

  @cached
  get includeDates(): string[] | null {
    const dates = this.args.includeDates;
    return dates ? this.dateList(dates) : null;
  }

  private dateList(dates: readonly unknown[]): string[] {
    return dates
      .map((date) => this.dateArg(date))
      .filter((date): date is string => date !== null);
  }

  @cached
  get limits(): DayLimits {
    return dayLimits(
      {
        minDate: this.minDate,
        maxDate: this.maxDate,
        excludeDates: this.excludeDates,
        includeDates: this.includeDates,
        filterDate: this.args.filterDate
      },
      this.zone
    );
  }

  /** The time list's rules, for the calendar. */
  @cached
  get timeOptions(): CalendarTimeOptions {
    const { timeIntervals, injectTimes, excludeTimes, minTime, maxTime } =
      this.args;
    return {
      interval: timeInterval(timeIntervals).interval,
      injectTimes,
      excludeTimes,
      minTime,
      maxTime,
      seconds: this.seconds
    };
  }

  /** Every rule a typed instant is checked against (DESIGN 5.2, limits). */
  @cached
  get instantRules(): InstantRules {
    return {
      minDate: this.minDate,
      maxDate: this.maxDate,
      excludeDates: this.excludeDates,
      includeDates: this.includeDates,
      filterDate: this.args.filterDate,
      minTime: this.args.minTime,
      maxTime: this.args.maxTime,
      excludeTimes: this.args.excludeTimes,
      zone: this.zone
    };
  }

  /* Locale */

  /** `componentDefaults.EuiDatePicker` in `euiConfig` (DESIGN decision 11). */
  get configDefaults() {
    const config = getOwner(this)?.lookup('service:eui-config') as
      EuiConfigService | undefined;
    return config?.getConfig('componentDefaults')?.EuiDatePicker;
  }

  @cached
  get localeDefaults(): {
    locale: string;
    dateOrder: DateOrder;
    hour12: boolean;
    firstDayOfWeek: Weekday;
  } {
    return localeDefaults(this.args.locale ?? this.configDefaults?.locale);
  }

  get hour12(): boolean {
    const hour12 = this.args.hour12;
    return typeof hour12 === 'boolean' ? hour12 : this.localeDefaults.hour12;
  }

  get firstDayOfWeek(): Weekday {
    const day = this.args.firstDayOfWeek;
    return typeof day === 'number' &&
      Number.isInteger(day) &&
      day >= 0 &&
      day <= 6
      ? day
      : this.localeDefaults.firstDayOfWeek;
  }

  get dateOrder(): DateOrder {
    const order = this.args.dateOrder;
    return order === 'dmy' || order === 'mdy' || order === 'ymd'
      ? order
      : this.localeDefaults.dateOrder;
  }

  get placeholder(): string {
    if (this.args.placeholder !== undefined) return this.args.placeholder;
    const t = (token: string, fallback: string) =>
      this.euiI18n.lookupToken(`euiDatePicker.placeholder${token}`, fallback);
    const time = () =>
      timePlaceholder(
        { hour12: this.hour12, seconds: this.seconds },
        {
          hour: t('Hour', 'H'),
          minute: t('Minute', 'm'),
          second: t('Second', 's'),
          meridiem: t('Meridiem', 'am')
        }
      );
    if (this.mode === 'time') return time();
    const date = datePlaceholder(this.dateOrder, {
      day: t('Day', 'D'),
      month: t('Month', 'M'),
      year: t('Year', 'Y')
    });
    return this.mode === 'dateTime' ? `${date} ${time()}` : date;
  }

  /* Text (DESIGN 5.3) */

  /** The text typed, while it is shown: while focused, or while the value is the one it was typed over (9 #29). */
  private get shownTyped(): string | null {
    const typed = this.typed;
    if (!typed) return null;
    return this.hasFocus || typed.over === this.value ? typed.text : null;
  }

  /** What the input shows: the typed text, else the value's display text, else an unreadable value as is (9 #1). */
  get text(): string {
    const typed = this.shownTyped;
    if (typed !== null) return typed;
    const shown = this.displayText();
    if (shown !== null) return shown;
    const raw = this.rawValue;
    return typeof raw === 'string' ? raw : '';
  }

  /** The value in the display format, or null when there is none. */
  private displayText(): string | null {
    const ms = this.valueMs;
    if (ms !== null) {
      return formatDateTime(ms, {
        order: this.dateOrder,
        zone: this.zone,
        hour12: this.hour12,
        seconds: this.seconds
      });
    }
    const time = this.valueTime;
    if (time !== null) {
      return formatTime(time, { hour12: this.hour12, seconds: this.seconds });
    }
    const value = this.mode === 'date' ? this.value : null;
    return value === null ? null : formatDate(value, this.dateOrder);
  }

  /** The typed text read as a day, for the calendar to show its month (DESIGN 5.3, partial input). */
  get preview(): string | null {
    const typed = this.shownTyped;
    if (typed === null) return null;
    if (this.mode === 'dateTime') {
      const ms = this.parseInstantText(typed);
      return ms === null ? null : dayAt(ms, this.zone);
    }
    return this.mode === 'date' ? this.parse(typed) : null;
  }

  private get thisYear(): number {
    return Number(todayIn(this.zone, Date.now()).slice(0, 4));
  }

  private parse(text: string): string | null {
    return parseDateText(text, { order: this.dateOrder, year: this.thisYear });
  }

  private parseInstantText(text: string): number | null {
    return parseDateTimeText(text, {
      order: this.dateOrder,
      year: this.thisYear,
      zone: this.zone,
      seconds: this.seconds
    });
  }

  get isInvalid(): boolean {
    return Boolean(
      this.args.isInvalid ||
      this.range?.isInvalid ||
      this.hasUnreadableValue ||
      this.hasUnknownZone ||
      (this.inputError !== null && this.shownTyped !== null)
    );
  }

  /** Typed text was refused and is shown: the invalid border, also while focused. */
  get inputErrorClass(): string | undefined {
    if (this.inputError === null || this.shownTyped === null) return undefined;
    return `euiDatePicker--inputError ${euiClass(
      this.context,
      useEuiBorealisStyles(this.context, euiDatePickerInputErrorStyles)
    )}`;
  }

  /** In a range: the input stays without a frame of its own, whatever `EuiFieldText`'s class says. */
  get rangeInputClass(): string | undefined {
    if (!this.range || this.inline) return undefined;
    return euiClass(
      this.context,
      useEuiBorealisStyles(this.context, euiDatePickerRangeInputStyles)
    );
  }

  get interactive(): boolean {
    return !this.disabled && !this.readOnly;
  }

  /** What a readable value looks like, for the warnings. */
  private get expected(): string {
    switch (this.mode) {
      case 'dateTime':
        return 'an ISO instant with Z or an offset (2026-11-24T15:30:00.000Z)';
      case 'time':
        return 'an HH:mm time';
      default:
        return 'a YYYY-MM-DD date';
    }
  }

  /**
   * Development warnings for what the picker cannot read (9 #1, #2, #18,
   * #24, #52; DESIGN 18). A valid `Date` or moment is read silently
   * (decision 19); an invalid one warns.
   */
  @cached
  get warnings(): null {
    const { value, timeZone, minDate, maxDate, minTime, maxTime } = this.args;
    warn(
      isInvalidDateObject(value)
        ? 'EuiDatePicker: @value is an invalid Date or moment; it is treated as no value.'
        : `EuiDatePicker: @value ${JSON.stringify(value)} is not ${this.expected}.`,
      !this.hasUnreadableValue,
      { id: 'ember-eui.eui-date-picker.unreadable-value' }
    );
    warn(
      `EuiDatePicker: @timeZone ${JSON.stringify(timeZone)} is not a time zone this browser knows; it is shown as UTC.`,
      !this.hasUnknownZone,
      { id: 'ember-eui.eui-date-picker.unknown-time-zone' }
    );
    for (const [name, limit] of [
      ['@minDate', minDate],
      ['@maxDate', maxDate]
    ] as const) {
      warn(
        isInvalidDateObject(limit)
          ? `EuiDatePicker: ${name} is an invalid Date or moment; it is ignored.`
          : `EuiDatePicker: ${name} ${JSON.stringify(limit)} is not a YYYY-MM-DD date${this.mode === 'dateTime' ? ' or an instant' : ''}; it is ignored.`,
        isInvalidDateObject(limit)
          ? false
          : !isUnreadableLimit(toDateValue(limit, this.zone, this.limitMode)),
        { id: 'ember-eui.eui-date-picker.unreadable-limit' }
      );
    }
    for (const [name, limit] of [
      ['@minTime', minTime],
      ['@maxTime', maxTime]
    ] as const) {
      warn(
        `EuiDatePicker: ${name} ${JSON.stringify(limit)} is not an HH:mm time; it is ignored.`,
        limit == null || limit === '' || parseTimeValue(limit) !== null,
        { id: 'ember-eui.eui-date-picker.unreadable-limit' }
      );
    }
    warn(
      `EuiDatePicker: @timeIntervals ${JSON.stringify(this.args.timeIntervals)} is not a positive whole number of minutes; 30 is used.`,
      timeInterval(this.args.timeIntervals).valid,
      { id: 'ember-eui.eui-date-picker.time-intervals' }
    );
    warn(
      'EuiDatePicker: @native={{true}} has no effect with @inline: there is no native inline calendar; the calendar is shown.',
      !(this.args.native === true && this.inline),
      { id: 'ember-eui.eui-date-picker.native-inline' }
    );
    const unsupported = this.nativeInput ? unsupportedByNative(this.args) : [];
    warn(
      `EuiDatePicker: the OS picker cannot show ${unsupported.map((name) => `@${name}`).join(', ')}. A value @filterDate, @excludeDates, @includeDates or @excludeTimes refuses is an input error; @injectTimes and @dayClassName have no effect. Leave @native to 'auto' for the calendar.`,
      unsupported.length === 0,
      { id: 'ember-eui.eui-date-picker.native-unsupported' }
    );
    warn(
      'EuiDatePicker: @minDate is after @maxDate; every day is disabled.',
      !limitsConflict(this.limits),
      { id: 'ember-eui.eui-date-picker.limits-conflict' }
    );
    return null;
  }

  /* Layout */

  /** Upstream's wrapper: `display: block`; inline, its frame, then invalid (when interactive), shadow, disabled, read-only. */
  @cached
  get rootClass() {
    const styles = useEuiBorealisStyles(this.context, euiDatePickerStyles);
    const { disabled, readOnly, inline } = this;
    return euiClass(
      this.context,
      { boxSizing: 'border-box' },
      styles.euiDatePicker,
      ...(inline
        ? [
            styles.inline.inline,
            this.isInvalid && !(disabled || readOnly) && styles.inline.invalid,
            this.args.shadow !== false
              ? styles.inline.shadow
              : styles.inline.noShadow,
            disabled && styles.inline.disabled,
            readOnly && styles.inline.readOnly
          ]
        : [])
    );
  }

  /** Upstream `inGroup`: the popover anchor fills the group's height. */
  get inGroupCss() {
    return useEuiBorealisStyles(this.context, euiDatePickerStyles).inGroup;
  }

  get icon(): string | undefined {
    if ((this.args.showIcon ?? this.range?.showIcon) === false) {
      return undefined;
    }
    return this.args.iconType ?? (this.timeOnly ? 'clock' : 'calendar');
  }

  /** The layout's icon: on the native path a button that opens the OS picker (the browser's own indicator is hidden). */
  @cached
  get layoutIcon() {
    const type = this.icon;
    if (!type || !this.nativeInput) return type;
    return {
      type,
      side: 'left' as const,
      onClick: this.showNativePicker,
      disabled: this.disabled,
      'aria-label': this.calendarLabel,
      // the input itself is the keyboard's way in
      tabIndex: -1
    };
  }

  get inputId(): string {
    return this.args.id ?? this.fallbackId;
  }

  get anchorPosition(): PopoverAnchorPosition {
    return (
      this.args.popoverPlacement ??
      (this.range?.side === 'end' ? 'downRight' : 'downLeft')
    );
  }

  /** The inline calendar's name, and the popover dialog's (DESIGN 7.3); `aria-label` or `aria-labelledby` on the picker win inline. */
  get calendarLabel() {
    return this.timeOnly
      ? this.euiI18n.lookupToken('euiDatePicker.timeLabel', 'Choose time')
      : this.euiI18n.lookupToken('euiDatePicker.calendarLabel', 'Choose date');
  }

  /** The dialog's name: "Choose date" and the field's label, when it has one. */
  get dialogLabel(): string {
    const label = this.panelId ? this.fieldLabel() : '';
    return label ? `${this.calendarLabel}, ${label}` : this.calendarLabel;
  }

  private fieldLabel(): string {
    const input = this.input ?? this.triggerTarget();
    if (!input) return '';
    const own = input.getAttribute('aria-label');
    if (own) return own;
    const labelledBy = input.getAttribute('aria-labelledby');
    const ids = labelledBy ? labelledBy.split(/\s+/) : [];
    const texts = ids.map(
      (id) => document.getElementById(id)?.textContent?.trim() ?? ''
    );
    if (texts.some(Boolean)) return texts.filter(Boolean).join(' ');
    const labels = (input as HTMLInputElement).labels;
    return [...(labels ?? [])]
      .map((label) => label.textContent?.trim() ?? '')
      .filter(Boolean)
      .join(' ');
  }

  /** A dialog, not modal (the input stays reachable), out of the tab order itself (DESIGN 7.3). */
  panelProps: EuiPopoverPanelProps = {
    role: 'dialog',
    'aria-modal': null as unknown as undefined,
    tabIndex: -1
  };

  /** The panel's trap, active once focus is in the calendar; the picker returns focus itself (DESIGN 7.3). */
  get focusTrapProps() {
    return {
      disabled: !this.trapActive,
      returnFocus: false,
      onEscapeKey: this.onEscapeKey
    };
  }

  focusTrapOptions = { escapeDeactivates: false };

  get clear() {
    const { onClear } = this.args;
    return this.value !== null && onClear && this.interactive
      ? this.onClear
      : undefined;
  }

  /* The native path (DESIGN 6) */

  /** EUI's icon is rendered and opens the OS picker: the browser's own indicator can go. */
  get nativeIconOpens(): boolean {
    return !this.controlOnly && typeof this.layoutIcon === 'object';
  }

  /** What the native input is checked and converted with. */
  get nativeContext(): NativeContext {
    return {
      mode: this.mode,
      zone: this.zone,
      seconds: this.seconds,
      value: this.value,
      valueMs: this.valueMs,
      minDate: this.minDate,
      maxDate: this.maxDate,
      limits: this.limits,
      instantRules: this.instantRules,
      timeLimits: {
        minTime: this.args.minTime,
        maxTime: this.args.maxTime,
        excludeTimes: this.args.excludeTimes
      }
    };
  }

  /** The native input's type, value, `min`, `max` and `step`. */
  @cached
  get nativeAttributes(): NativeAttributes {
    return nativeAttributes(this.nativeContext);
  }

  get nativeClass(): string {
    return euiClass(
      this.context,
      useEuiBorealisStyles(this.context, euiDatePickerNativeStyles)
    );
  }

  /** The icon: focus the input and open the OS picker where the engine can (`showPicker`). */
  @action
  showNativePicker() {
    const input = this.input;
    if (!input || !this.interactive) return;
    input.focus({ preventScroll: true });
    try {
      input.showPicker();
    } catch {
      // no showPicker, or not allowed here (a cross-origin frame)
    }
  }

  /** `data-empty` follows what the native input holds: after each render of its value, and on each edit. */
  markNativeEmpty = modifier(
    // reads the value, so that it runs again when the value changes
    (input: HTMLInputElement, [value]: [value: string]) => {
      if (value !== undefined) markEmpty(input);
    }
  );

  @action
  onNativeInput(event: Event) {
    markEmpty(event.target as HTMLInputElement);
  }

  /**
   * The native input's `change`: its value is read and checked as typed
   * text is (DESIGN 6.3). A half-filled field (bad input) is still being
   * edited: it is judged when focus leaves.
   */
  @action
  onNativeChange(event: Event) {
    const input = event.target as HTMLInputElement;
    markEmpty(input);
    const badInput = Boolean(input.validity?.badInput);
    const reading = readNative(input.value, badInput, this.nativeContext);
    if (reading.kind === 'problem' && badInput) return;
    this.settleNative(input, reading);
  }

  /**
   * Focus leaves the native input: a half-filled field is unreadable; a
   * value refused while it had focus is reported now.
   */
  @action
  onNativeFocusOut(event: FocusEvent) {
    const input = event.target as HTMLInputElement;
    if (input.validity?.badInput) {
      this.settleNative(input, { kind: 'problem', problem: 'unreadable' });
    }
    const pending = this.pendingNativeError;
    this.pendingNativeError = null;
    // still refused and shown (not replaced by a value from outside)
    if (pending && this.inputError !== null && this.shownTyped !== null) {
      this.args.onInputError?.(pending);
    }
  }

  /**
   * A value refused while the input has focus, reported to `@onInputError`
   * when focus leaves: keyboard entry changes the value per segment
   * (typing a year passes 0002, 0020, 0202), so only what is left counts,
   * as typed text is committed on blur. The invalid look shows at once.
   */
  private pendingNativeError: EuiDatePickerInputError | null = null;

  private settleNative(input: HTMLInputElement, reading: NativeReading) {
    if (reading.kind === 'problem') {
      // the value stays in the input, with the invalid look, as refused
      // typed text does; the value does not change
      this.typed = { text: input.value, over: this.value };
      this.inputError = reading.problem;
      const error = { text: input.value, reason: reading.problem };
      if (document.activeElement === input) {
        this.pendingNativeError = error;
      } else {
        this.pendingNativeError = null;
        this.args.onInputError?.(error);
      }
      return;
    }
    this.typed = null;
    this.inputError = null;
    this.pendingNativeError = null;
    if (reading.kind === 'empty') {
      if (this.value !== null || this.args.value != null) {
        this.args.onChange?.(null);
      }
    } else if (reading.changes) {
      this.args.onChange?.(reading.value);
    }
    // the input shows the value, also when it did not change (a gap time
    // resolved to the value) or the app kept its own (9 #30)
    schedule('afterRender', () => {
      if (this.isDestroying || this.isDestroyed || this.input !== input) {
        return;
      }
      if (this.inputError !== null) return;
      const { value } = this.nativeAttributes;
      if (input.value !== value) input.value = value;
      markEmpty(input);
    });
  }

  /* Opening and closing */

  private open() {
    if (!this.interactive || this.inline) return;
    this.isOpen = true;
  }

  /** Close; with `returnFocus`, focus goes back to the input when it was in the calendar or nowhere (DESIGN 7.3). */
  private close(returnFocus = false) {
    const focusInPanel = Boolean(this.panel?.contains(document.activeElement));
    this.isOpen = false;
    this.trapActive = false;
    if (returnFocus || focusInPanel) this.focusInputAfterRender();
  }

  /**
   * Focus back to the input once the calendar's trap is off. Again a tick
   * later when an outer trap (a modal, a flyout) took it for its own
   * container on resuming: focus-trap delays that focus.
   */
  private focusInputAfterRender() {
    const refocus = (onlyIfTaken: boolean) => {
      const input = this.input ?? this.triggerTarget();
      if (!input || this.isDestroying || this.isDestroyed) return;
      const active = document.activeElement;
      if (active === input) return;
      const taken =
        !active ||
        active === document.body ||
        !active.isConnected ||
        Boolean(this.panel?.contains(active)) ||
        active.contains(input);
      if (onlyIfTaken && !taken) return;
      this.ownFocus = true;
      input.focus({ preventScroll: true });
      // a focus event that did not come (the input was focused already)
      this.ownFocus = false;
    };
    schedule('afterRender', () => {
      refocus(false);
      later(() => refocus(true), 0);
    });
  }

  /* Commit (DESIGN 5.3) */

  /** Commit typed text: an empty text clears, readable and allowed text emits, anything else is an input error. */
  private commit() {
    const typed = this.shownTyped;
    if (typed === null) return;
    const text = typed.trim();
    if (text === '') {
      this.typed = null;
      this.inputError = null;
      if (this.value !== null || this.args.value != null) {
        this.args.onChange?.(null);
      }
      return;
    }
    if (text === this.displayText()) {
      // the value's own text, typed again: hidden seconds and milliseconds
      // (no @seconds) must not be dropped by reading it back
      this.typed = null;
      this.inputError = null;
      return;
    }
    const read = this.read(text);
    if (read.problem !== null) {
      this.inputError = read.problem;
      this.args.onInputError?.({ text: typed, reason: read.problem });
      return;
    }
    this.typed = null;
    this.inputError = null;
    if (read.changes) this.args.onChange?.(read.value);
  }

  /**
   * Typed text as a value: the value, whether it changes the current one,
   * or why it cannot be chosen. A typed date and time is a wall clock in
   * the zone, and changes the value only when the wall clock differs
   * (DESIGN 5.2), unless it is an ISO instant with `Z` or an offset.
   */
  private read(
    text: string
  ):
    | { problem: null; value: string; changes: boolean }
    | { problem: EuiDatePickerInputErrorReason } {
    switch (this.mode) {
      case 'dateTime': {
        const ms = this.parseInstantText(text);
        if (ms === null) return { problem: 'unreadable' };
        const problem = instantProblem(ms, this.instantRules);
        if (problem) return { problem };
        const current = this.valueMs;
        const changes =
          parseInstant(text) !== null
            ? ms !== current
            : changesValue(current, wallAt(ms, this.zone), this.zone);
        return { problem: null, value: instantString(ms), changes };
      }
      case 'time': {
        const typed = parseTimeText(text);
        if (typed === null) return { problem: 'unreadable' };
        const time = this.seconds ? typed : { ...typed, second: 0 };
        const problem = timeProblem(time, this.args);
        if (problem) return { problem };
        const value = timeValueOf(time, this.seconds);
        return { problem: null, value, changes: value !== this.value };
      }
      default: {
        const date = this.parse(text);
        if (date === null) return { problem: 'unreadable' };
        const problem = dayProblem(date, this.limits);
        if (problem) return { problem };
        return { problem: null, value: date, changes: date !== this.value };
      }
    }
  }

  /** Back to the value's text, without an error (Escape when closed, 9 #9). */
  private restore(): boolean {
    const dirty = this.typed !== null || this.inputError !== null;
    this.typed = null;
    this.inputError = null;
    return dirty;
  }

  /* Input events */

  @action
  registerInput(element: HTMLInputElement | null) {
    this.input = element;
    this.args.inputRef?.(element);
  }

  /** With `<:trigger>`: the element around the trigger. */
  registerAnchor = modifier((element: HTMLElement) => {
    this.anchor = element;
    return () => {
      if (this.anchor === element) this.anchor = null;
    };
  });

  /** Where focus goes back to with `<:trigger>`: what opened the calendar, else the first focusable element of the trigger. */
  private triggerTarget(): HTMLElement | null {
    const anchor = this.anchor;
    if (!anchor) return null;
    const opener = this.triggerFocus;
    if (opener?.isConnected && anchor.contains(opener)) return opener;
    const first = tabbable(anchor)[0];
    return first instanceof HTMLElement ? first : null;
  }

  /** What `<:trigger>` yields. */
  get triggerApi(): EuiDatePickerTrigger {
    return { open: this.openFromTrigger, isOpen: this.isOpen, text: this.text };
  }

  /**
   * `<:trigger>`'s `open`: the calendar opens with focus in it, held by its
   * trap, as upstream does for a custom input that is not an `<input>`.
   */
  @action
  openFromTrigger() {
    if (!this.interactive) return;
    const active = document.activeElement;
    this.triggerFocus =
      active instanceof HTMLElement && this.anchor?.contains(active)
        ? active
        : null;
    this.open();
    this.gridFocusRequest++;
  }

  @action
  registerPanel(panel: HTMLElement | null) {
    this.panel = panel;
    this.panelId = panel?.id || undefined;
  }

  @action
  onInput(event: Event) {
    const text = (event.target as HTMLInputElement).value;
    this.typed = { text, over: this.value };
    this.inputError = null;
    this.open();
  }

  @action
  onInputFocus() {
    this.hasFocus = true;
    if (this.ownFocus) {
      this.ownFocus = false;
      return;
    }
    this.open();
  }

  @action
  onInputClick() {
    if (!this.isOpen) this.open();
  }

  @action
  onInputKeyDown(event: KeyboardEvent) {
    if (!this.interactive) return;
    switch (event.key) {
      case 'ArrowDown':
        if (event.ctrlKey || event.metaKey || event.shiftKey) return;
        event.preventDefault();
        this.open();
        this.gridFocusRequest++;
        return;
      case 'Enter': {
        const pending = this.isOpen || this.shownTyped !== null;
        this.commit();
        if (pending) event.preventDefault();
        this.isOpen = false;
        this.trapActive = false;
        return;
      }
      case 'Escape':
        // open: close, and keep the Escape from an outer modal or flyout
        // (they listen on their own element, above the input)
        if (this.isOpen) {
          event.preventDefault();
          event.stopPropagation();
          this.close();
          return;
        }
        if (this.restore()) event.stopPropagation();
        return;
    }
  }

  /** Focus left the input or the panel: a blur commits and closes, unless focus stays in the picker. */
  @action
  onFocusOut(event: FocusEvent) {
    const next = event.relatedTarget as Node | null;
    const inPicker = (node: Node | null) =>
      Boolean(
        node &&
        (this.input?.contains(node) ||
          this.anchor?.contains(node) ||
          this.panel?.contains(node))
      );
    if (inPicker(next) || this.pressInPanel) return;
    if (
      next === null &&
      this.isOpen &&
      this.panel?.contains(event.target as Node)
    ) {
      // focus was lost from the calendar: a press outside on nothing
      // focusable, or the focused day re-rendered away (a key moved to
      // another month; Chrome fires focusout on a removed element, during
      // the render). Decided after the render: if the calendar or the input
      // has focus again, nothing happened; else back to the input, nothing
      // committed (DESIGN 7.3).
      next_(() => {
        if (this.isDestroying || this.isDestroyed || !this.isOpen) return;
        const active = document.activeElement;
        if (active === this.input || this.panel?.contains(active)) return;
        if (active && this.anchor?.contains(active)) return;
        this.close(true);
      });
      return;
    }
    this.hasFocus = false;
    this.commit();
    if (this.isOpen) {
      this.isOpen = false;
      this.trapActive = false;
    }
  }

  @action
  onPanelFocusIn() {
    this.trapActive = true;
  }

  @action
  onPanelPointerDown() {
    this.pressInPanel = true;
    // the input's blur comes with the press (mousedown), before this
    document.addEventListener('pointerup', this.releasePress, {
      once: true,
      capture: true
    });
  }

  releasePress = () => {
    this.pressInPanel = false;
    document.removeEventListener('pointerup', this.releasePress, {
      capture: true
    });
  };

  willDestroy() {
    super.willDestroy();
    // a picker with a time list leaves the range: it stops widening it
    this.reportedRange?.reportTimeSelect(this, false);
    // a press under way when the picker goes
    document.removeEventListener('pointerup', this.releasePress, {
      capture: true
    });
  }

  /** Tab after the calendar's last control, or Shift+Tab before its first, closes and returns to the input (DESIGN 7.2). */
  @action
  onPanelKeyDown(event: KeyboardEvent) {
    if (event.key !== 'Tab' || !this.panel) return;
    const stops = tabbable(this.panel);
    const target = event.target as HTMLElement;
    const edge = event.shiftKey ? stops[0] : stops[stops.length - 1];
    if (target !== edge) return;
    event.preventDefault();
    this.close(true);
  }

  /** Escape in the input or the calendar while open: close, focus back to the input; the typed text stays. */
  @action
  onEscapeKey() {
    this.close();
  }

  /** The popover's outside press: commit what was typed, close. */
  @action
  onClickOutside() {
    if (document.activeElement !== this.input) this.commit();
    this.close();
  }

  /** The trap let go by itself (a press outside); when the picker turned it off, there is nothing to do. */
  @action
  onTrapDeactivation() {
    if (!this.trapActive) return;
    schedule('actions', () => {
      if (!this.isDestroying) this.trapActive = false;
    });
  }

  /**
   * Every pick of an enabled day: emits when it differs, drops the typed
   * text, closes (`@shouldCloseOnSelect`). With `@showTimeSelect` the
   * popover stays open for the time, as upstream.
   */
  @action
  onPick(date: string) {
    this.typed = null;
    this.inputError = null;
    this.chooseDay(date);
    if (this.args.shouldCloseOnSelect !== false && !this.showTimeSelect) {
      this.close(true);
    }
  }

  /** Inline: the calendar's chosen day. */
  @action
  onSelect(date: string) {
    this.chooseDay(date);
  }

  /**
   * Emit a chosen day. With `@showTimeSelect`: the value's wall time on
   * that day, seconds kept (DESIGN 5.2; a gap resolves forward); without a
   * value, midnight. When that instant is outside the limits, the day's
   * first time that can be chosen; none, nothing.
   */
  private chooseDay(date: string) {
    if (this.mode !== 'dateTime') {
      if (date !== this.value) this.args.onChange?.(date);
      return;
    }
    const current = this.valueMs;
    let ms =
      current === null
        ? startOfDayIn(date, this.zone)
        : withDay(current, date, this.zone);
    if (instantProblem(ms, this.instantRules) !== null) {
      const first = this.firstTimeOf(date);
      if (first === null) return;
      ms = first;
    }
    if (changesValue(current, wallAt(ms, this.zone), this.zone)) {
      this.args.onChange?.(instantString(ms));
    }
  }

  /** The first instant of a day's time list that can be chosen, or null. */
  private firstTimeOf(date: string): number | null {
    const entry = timeList({
      ...this.timeOptions,
      day: date,
      zone: this.zone,
      minDate: this.minDate,
      maxDate: this.maxDate
    }).find(
      (candidate) =>
        candidate.problem === null &&
        candidate.instant !== null &&
        instantProblem(candidate.instant, this.instantRules) === null
    );
    return entry?.instant ?? null;
  }

  /**
   * A time picked in the list: time only emits `HH:mm`; with a day, its
   * instant on that day in the zone, seconds zero (DESIGN 5.2), and only
   * when the wall clock differs from the value's (a stored second
   * occurrence survives, 9 #21). Closes (`@shouldCloseOnSelect`).
   */
  @action
  onPickTime(day: string | null, entry: TimeEntry) {
    this.typed = null;
    this.inputError = null;
    if (day === null) {
      const value = timeValueOf(entry.time, this.seconds);
      if (value !== this.value) this.args.onChange?.(value);
    } else {
      const { hour, minute } = entry.time;
      const wall = wallOf(day, hour, minute);
      if (changesValue(this.valueMs, wall, this.zone)) {
        this.args.onChange?.(
          instantString(instantAt(day, entry.time, this.zone))
        );
      }
    }
    if (this.args.shouldCloseOnSelect !== false && !this.inline) {
      this.close(true);
    }
  }

  /** `@adjustDateOnChange`: a day moved to with the keys or the selects is chosen at once, if it can be. */
  @action
  onMove(date: string) {
    if (!this.args.adjustDateOnChange || !this.interactive) return;
    if (dayProblem(date, this.limits) !== null) return;
    this.typed = null;
    this.inputError = null;
    this.chooseDay(date);
  }

  @action
  onClear() {
    this.typed = null;
    this.inputError = null;
    this.args.onClear?.();
  }

  /** Focus moves to the calendar's tab stop once it is rendered (ArrowDown in the input). */
  focusGrid = modifier((content: HTMLElement, [request]: [number]) => {
    if (request === this.handledGridFocus) return;
    this.handledGridFocus = request;
    // after the panel is registered, so the input's blur sees it
    schedule('afterRender', () => {
      content
        .querySelector<HTMLElement>(
          this.timeOnly
            ? '.react-datepicker__time-list'
            : 'td[data-date] > button[tabindex="0"]'
        )
        // before the popover is placed the panel can sit at the end of the
        // page: focusing it there scrolled the page down and back (a jump)
        ?.focus({ preventScroll: true });
    });
  });

  <template>
    {{this.warnings}}
    {{this.rangeReport}}
    {{#if this.inline}}
      {{#if this.controlOnly}}
        <DatePickerInlineCalendar @picker={{this}} ...attributes />
      {{else}}
        <div class="euiDatePicker {{this.rootClass}}">
          <EuiFormControlLayout
            @isDelimited={{true}}
            @iconsPosition="static"
            @clear={{this.clear}}
            @isLoading={{@isLoading}}
            @isInvalid={{this.isInvalid}}
            @isDisabled={{this.disabled}}
            @readOnly={{this.readOnly}}
          >
            <DatePickerInlineCalendar @picker={{this}} ...attributes />
          </EuiFormControlLayout>
        </div>
      {{/if}}
    {{else if this.controlOnly}}
      {{#if (has-block "trigger")}}
        <DatePickerControl @picker={{this}} @hasTrigger={{true}} ...attributes>
          <:trigger as |trigger|>{{yield trigger to="trigger"}}</:trigger>
        </DatePickerControl>
      {{else if this.nativeInput}}
        <EuiDatePickerNativeInput @picker={{this}} ...attributes />
      {{else}}
        <DatePickerControl @picker={{this}} ...attributes />
      {{/if}}
    {{else}}
      {{#let
        (has-block "prepend") (has-block "append") (has-block "trigger")
        as |hasPrepend hasAppend hasTrigger|
      }}
        <div class="euiDatePicker {{this.rootClass}}">
          <EuiFormControlLayout
            @inputId={{unless hasTrigger this.inputId}}
            @icon={{unless hasTrigger this.layoutIcon}}
            @clear={{this.clear}}
            @isLoading={{@isLoading}}
            @isInvalid={{this.isInvalid}}
            @isDisabled={{this.disabled}}
            @readOnly={{this.readOnly}}
            @fullWidth={{this.fullWidth}}
            @compressed={{this.compressed}}
            @isPrependProvided={{hasPrepend}}
            @isAppendProvided={{hasAppend}}
            @css={{if (or hasPrepend hasAppend) this.inGroupCss}}
          >
            <:prepend as |className|>
              {{yield className this.inputId to="prepend"}}
            </:prepend>
            <:field>
              {{#if hasTrigger}}
                <DatePickerControl
                  @picker={{this}}
                  @hasTrigger={{true}}
                  ...attributes
                >
                  <:trigger as |trigger|>{{yield
                      trigger
                      to="trigger"
                    }}</:trigger>
                </DatePickerControl>
              {{else if this.nativeInput}}
                <EuiDatePickerNativeInput @picker={{this}} ...attributes />
              {{else}}
                <DatePickerControl @picker={{this}} ...attributes />
              {{/if}}
            </:field>
            <:append as |className|>
              {{yield className this.inputId to="append"}}
            </:append>
          </EuiFormControlLayout>
        </div>
      {{/let}}
    {{/if}}
  </template>
}
