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
 */
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { warn } from '@ember/debug';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { later, schedule } from '@ember/runloop';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';
import { or } from 'ember-truth-helpers';
import { tabbable } from 'tabbable';

import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
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
  localeDefaults
} from '../utils/date/format.ts';
import { parseDateText } from '../utils/date/parse.ts';
import {
  isDateObject,
  isInvalidDateObject,
  toDateValue
} from '../utils/date/value.ts';
import {
  normalizeTimeZone,
  todayIn,
  validTimeZone
} from '../utils/date/zone.ts';
import EuiDatePickerCalendar from './eui-date-picker/calendar.gts';
import EuiFieldText from './eui-field-text.gts';
import EuiFormControlLayout from './eui-form-control-layout.gts';
import EuiPopover from './eui-popover.gts';

import type { Weekday } from '../utils/date/calendar-date.ts';
import type { DayLimits, LimitProblem } from '../utils/date/calendar-nav.ts';
import type { DateOrder } from '../utils/date/parse.ts';
import type { DateInput } from '../utils/date/value.ts';
import type EuiI18n from '../services/eui-i18n.ts';
import type {
  EuiPopoverPanelProps,
  PopoverAnchorPosition
} from './eui-popover.gts';
import type { TOC } from '@ember/component/template-only';

/** Why typed text was refused (`@onInputError`). */
export type EuiDatePickerInputErrorReason = 'unreadable' | LimitProblem;

export interface EuiDatePickerInputError {
  /** The text as typed. */
  text: string;
  /** `'unreadable'`: not a date in the field's order; `'min'`, `'max'`: outside the limits; `'disabled'`: excluded, not included or filtered out. */
  reason: EuiDatePickerInputErrorReason;
}

/**
 * A date picker (upstream `EuiDatePicker`): a text input that opens a
 * calendar in a popover, or the calendar alone with `@inline`. Values are
 * `YYYY-MM-DD` strings; a `Date` or a moment is read too. Typed text is
 * committed on Enter, on blur and on a pick. Attributes go to the input, or
 * to the calendar with `@inline`.
 */
export interface EuiDatePickerSignature {
  /** `...attributes` go to the text input; with `@inline`, to the calendar's root (`div.react-datepicker`, `role="group"`). */
  Element: HTMLInputElement | HTMLDivElement;
  Args: {
    /** The value, `YYYY-MM-DD`. Also a `Date` or a moment: its day in `@timeZone` is read. `null` or `undefined` for none. */
    value?: DateInput | null;
    /** Called with the new value, `YYYY-MM-DD`, or `null` when the text is emptied. Never with a disabled day, never per keystroke. */
    onChange?: (value: string | null) => void;
    /** Shows the clear button while there is a value; empty the value there. */
    onClear?: () => void;
    /** Called when committed text cannot be read, or names a day that cannot be chosen. `@onChange` is not called then. */
    onInputError?: (error: EuiDatePickerInputError) => void;

    /** Shows the calendar in the page instead of the text input and the popover. */
    inline?: boolean;
    /** With `@inline`: the raised frame. Defaults to `true`. */
    shadow?: boolean;
    /** Closes the popover after a day is picked. Defaults to `true`. */
    shouldCloseOnSelect?: boolean;
    /** Where the popover opens, any `EuiPopover` `@anchorPosition`. Defaults to `'downLeft'`. */
    popoverPlacement?: PopoverAnchorPosition;

    /** `'local'`, `'utc'` or an IANA name: the zone of "today", and the day of a `Date` or a moment. Defaults to `'local'`. */
    timeZone?: 'local' | 'utc' | (string & {});
    /** BCP 47 tag for names and defaults. Defaults to the document's language, then the browser's. */
    locale?: string;
    /** The order typed and shown: `'dmy'` (`24/11/2026`), `'mdy'` (`11/24/2026`) or `'ymd'` (`2026-11-24`). Defaults to the order of `@locale`. */
    dateOrder?: DateOrder;
    /** The first day of the week, 0 (Sunday) to 6. Defaults to `@locale`'s. */
    firstDayOfWeek?: Weekday;

    /** Days before are disabled (`YYYY-MM-DD`, a `Date` or a moment). */
    minDate?: DateInput | null;
    /** Days after are disabled (`YYYY-MM-DD`, a `Date` or a moment). */
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
    /** The icon's type, anything `EuiIcon`'s `@type` accepts. Defaults to `'calendar'`. */
    iconType?: string;
    /** Renders the input and its popover without the form control layout (no icon, clear button, prepend or append), e.g. inside `EuiDatePickerRange`. */
    controlOnly?: boolean;
    /** Called with the `<input>` element once rendered. */
    inputRef?: (element: HTMLInputElement | null) => void;
  };
  Blocks: {
    /** Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. */
    prepend: [className: string, inputId: string];
    /** Content after the input; yields the class to put on it and the input id. */
    append: [className: string, inputId: string];
  };
}

/** The input and its popover: the control, with or without the layout (`@controlOnly`). */
const DatePickerControl: TOC<{
  Element: HTMLInputElement;
  Args: { picker: EuiDatePicker };
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
      <div class="react-datepicker__input-container">
        <EuiFieldText
          @controlOnly={{true}}
          @id={{@picker.inputId}}
          @value={{@picker.text}}
          @placeholder={{@picker.placeholder}}
          @compressed={{@picker.args.compressed}}
          @fullWidth={{@picker.args.fullWidth}}
          @isInvalid={{@picker.isInvalid}}
          @disabled={{@picker.args.disabled}}
          @readOnly={{@picker.args.readOnly}}
          @inputRef={{@picker.registerInput}}
          class="euiDatePicker"
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
          @selected={{@picker.value}}
          @preview={{@picker.preview}}
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
        />
      </div>
    </:content>
  </EuiPopover>
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
  /** The next focus event is the picker's own (returning focus): it does not open the popover. */
  private ownFocus = false;
  /** A press in the panel is under way: the input's blur is not a commit (Safari does not focus buttons on click). */
  private pressInPanel = false;
  /** The `@value` objects already reported (one notice per value). */
  private reportedObjects = new WeakSet<object>();
  fallbackId = randomId();

  get context() {
    return getEuiThemeContext(this);
  }

  /* Values (DESIGN 4.2, 18) */

  get zone(): string {
    return normalizeTimeZone(this.args.timeZone);
  }

  get hasUnknownZone(): boolean {
    return !validTimeZone(this.args.timeZone);
  }

  /** `@value` as the picker reads it: a `Date` or a moment as its day in the zone. */
  get rawValue(): unknown {
    return toDateValue(this.args.value, this.zone);
  }

  /** The value when it is a real `YYYY-MM-DD` date, else null. */
  get value(): string | null {
    return validIsoDate(this.rawValue);
  }

  /** A value is present but not a date (9 #1), or an invalid `Date` or moment (18). */
  get hasUnreadableValue(): boolean {
    const raw = this.rawValue;
    if (isInvalidDateObject(this.args.value)) return true;
    return raw != null && raw !== '' && this.value === null;
  }

  private dateArg(value: unknown): string | null {
    const read = toDateValue(value, this.zone);
    return typeof read === 'string' ? read : null;
  }

  get minDate(): string | null {
    return this.dateArg(this.args.minDate);
  }

  get maxDate(): string | null {
    return this.dateArg(this.args.maxDate);
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

  /* Locale */

  @cached
  get localeDefaults(): {
    locale: string;
    dateOrder: DateOrder;
    hour12: boolean;
    firstDayOfWeek: Weekday;
  } {
    return localeDefaults(this.args.locale);
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
    return datePlaceholder(this.dateOrder, {
      day: t('Day', 'D'),
      month: t('Month', 'M'),
      year: t('Year', 'Y')
    });
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
    const value = this.value;
    if (value !== null) return formatDate(value, this.dateOrder);
    const raw = this.rawValue;
    return typeof raw === 'string' ? raw : '';
  }

  /** The typed text read as a date, for the calendar to show its month (DESIGN 5.3, partial input). */
  get preview(): string | null {
    const typed = this.shownTyped;
    return typed === null ? null : this.parse(typed);
  }

  private parse(text: string): string | null {
    const year = Number(todayIn(this.zone, Date.now()).slice(0, 4));
    return parseDateText(text, { order: this.dateOrder, year });
  }

  get isInvalid(): boolean {
    return Boolean(
      this.args.isInvalid ||
      this.hasUnreadableValue ||
      this.hasUnknownZone ||
      (this.inputError !== null && this.shownTyped !== null)
    );
  }

  get interactive(): boolean {
    return !this.args.disabled && !this.args.readOnly;
  }

  /** Development warnings for what the picker cannot read (9 #1, #2, #18, #24; DESIGN 18). */
  @cached
  get warnings(): null {
    const { value, timeZone, minDate, maxDate } = this.args;
    if (isDateObject(value) && !isInvalidDateObject(value)) {
      if (!this.reportedObjects.has(value)) {
        this.reportedObjects.add(value);
        warn(
          `EuiDatePicker: @value is a Date or a moment; it is read as ${JSON.stringify(this.value)}, its day in the ${this.zone} zone. @onChange emits strings: for a value that round-trips unchanged, @value must be a YYYY-MM-DD string, not a Date or a moment.`,
          false,
          { id: 'ember-eui.eui-date-picker.object-value' }
        );
      }
    } else {
      warn(
        isInvalidDateObject(value)
          ? 'EuiDatePicker: @value is an invalid Date or moment; it is treated as no value.'
          : `EuiDatePicker: @value ${JSON.stringify(value)} is not a YYYY-MM-DD date.`,
        !this.hasUnreadableValue,
        { id: 'ember-eui.eui-date-picker.unreadable-value' }
      );
    }
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
          : `EuiDatePicker: ${name} ${JSON.stringify(limit)} is not a YYYY-MM-DD date; it is ignored.`,
        isInvalidDateObject(limit)
          ? false
          : !isUnreadableLimit(toDateValue(limit, this.zone)),
        { id: 'ember-eui.eui-date-picker.unreadable-limit' }
      );
    }
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
    const { disabled, readOnly, inline } = this.args;
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
    if (this.args.showIcon === false) return undefined;
    return this.args.iconType ?? 'calendar';
  }

  get inputId(): string {
    return this.args.id ?? this.fallbackId;
  }

  get anchorPosition(): PopoverAnchorPosition {
    return this.args.popoverPlacement ?? 'downLeft';
  }

  /** The inline calendar's name, and the popover dialog's (DESIGN 7.3); `aria-label` or `aria-labelledby` on the picker win inline. */
  get calendarLabel() {
    return this.euiI18n.lookupToken(
      'euiDatePicker.calendarLabel',
      'Choose date'
    );
  }

  /** The dialog's name: "Choose date" and the field's label, when it has one. */
  get dialogLabel(): string {
    const label = this.panelId ? this.fieldLabel() : '';
    return label ? `${this.calendarLabel}, ${label}` : this.calendarLabel;
  }

  private fieldLabel(): string {
    const input = this.input;
    if (!input) return '';
    const own = input.getAttribute('aria-label');
    if (own) return own;
    const labelledBy = input.getAttribute('aria-labelledby');
    const ids = labelledBy ? labelledBy.split(/\s+/) : [];
    const texts = ids.map(
      (id) => document.getElementById(id)?.textContent?.trim() ?? ''
    );
    if (texts.some(Boolean)) return texts.filter(Boolean).join(' ');
    return [...(input.labels ?? [])]
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
    const { onClear, disabled, readOnly } = this.args;
    return this.value !== null && onClear && !disabled && !readOnly
      ? this.onClear
      : undefined;
  }

  /* Opening and closing */

  private open() {
    if (!this.interactive || this.args.inline) return;
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
      const input = this.input;
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
      input.focus();
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
    const date = this.parse(text);
    const problem: EuiDatePickerInputErrorReason | null =
      date === null ? 'unreadable' : dayProblem(date, this.limits);
    if (date === null || problem !== null) {
      this.inputError = problem;
      this.args.onInputError?.({ text: typed, reason: problem! });
      return;
    }
    this.typed = null;
    this.inputError = null;
    if (date !== this.value) this.args.onChange?.(date);
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
        node && (this.input?.contains(node) || this.panel?.contains(node))
      );
    if (inPicker(next) || this.pressInPanel) return;
    if (
      next === null &&
      this.isOpen &&
      this.panel?.contains(event.target as Node)
    ) {
      // focus was lost from the calendar (a press outside on nothing
      // focusable): back to the input, nothing committed (DESIGN 7.3)
      this.close(true);
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
  };

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

  /** Every pick of an enabled day: emits when it differs, drops the typed text, closes (`@shouldCloseOnSelect`). */
  @action
  onPick(date: string) {
    this.typed = null;
    this.inputError = null;
    if (date !== this.value) this.args.onChange?.(date);
    if (this.args.shouldCloseOnSelect !== false) this.close(true);
  }

  /** Inline: the calendar emits the chosen day. */
  @action
  onSelect(date: string) {
    this.args.onChange?.(date);
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
        .querySelector<HTMLButtonElement>(
          'td[data-date] > button[tabindex="0"]'
        )
        ?.focus();
    });
  });

  <template>
    {{this.warnings}}
    {{#if @inline}}
      <div class="euiDatePicker {{this.rootClass}}">
        <EuiFormControlLayout
          @isDelimited={{true}}
          @iconsPosition="static"
          @clear={{this.clear}}
          @isLoading={{@isLoading}}
          @isInvalid={{this.isInvalid}}
          @isDisabled={{@disabled}}
          @readOnly={{@readOnly}}
        >
          <EuiDatePickerCalendar
            role="group"
            aria-label={{this.calendarLabel}}
            @selected={{this.value}}
            @onSelect={{this.onSelect}}
            @openToDate={{this.openToDate}}
            @minDate={{this.minDate}}
            @maxDate={{this.maxDate}}
            @excludeDates={{this.excludeDates}}
            @includeDates={{this.includeDates}}
            @filterDate={{@filterDate}}
            @timeZone={{this.zone}}
            @locale={{this.localeDefaults.locale}}
            @firstDayOfWeek={{this.firstDayOfWeek}}
            @dayClassName={{@dayClassName}}
            @calendarClass={{@calendarClass}}
            @disabled={{@disabled}}
            @readOnly={{@readOnly}}
            ...attributes
          />
        </EuiFormControlLayout>
      </div>
    {{else if @controlOnly}}
      <DatePickerControl @picker={{this}} ...attributes />
    {{else}}
      {{#let
        (has-block "prepend") (has-block "append")
        as |hasPrepend hasAppend|
      }}
        <div class="euiDatePicker {{this.rootClass}}">
          <EuiFormControlLayout
            @inputId={{this.inputId}}
            @icon={{this.icon}}
            @clear={{this.clear}}
            @isLoading={{@isLoading}}
            @isInvalid={{this.isInvalid}}
            @isDisabled={{@disabled}}
            @readOnly={{@readOnly}}
            @fullWidth={{@fullWidth}}
            @compressed={{@compressed}}
            @isPrependProvided={{hasPrepend}}
            @isAppendProvided={{hasAppend}}
            @css={{if (or hasPrepend hasAppend) this.inGroupCss}}
          >
            <:prepend as |className|>
              {{yield className this.inputId to="prepend"}}
            </:prepend>
            <:field>
              <DatePickerControl @picker={{this}} ...attributes />
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
