/*
 * Ported from @elastic/eui 123.1.0
 * `components/date_picker/react-datepicker/src/time.js`: the markup and
 * class names of the time list. That file forks react-datepicker@2.0.0,
 * MIT, Copyright (c) 2018 HackerOne Inc and individual contributors (see
 * NOTICE.md). EUI's changes: Copyright Elasticsearch B.V. and/or licensed
 * to Elasticsearch B.V. under one or more contributor license agreements.
 * Licensed under the Elastic License 2.0 or the Server Side Public License,
 * v 1; see vendor/eui-latest.
 *
 * The logic is new (DESIGN 5.2, 7.2): the entries come from
 * `utils/date/times.ts` (one day's wall times, gaps left out), and the list
 * is a listbox with `aria-activedescendant`.
 */
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import { formatTime } from '../../utils/date/format.ts';

import type { TimeOfDay } from '../../utils/date/parse.ts';
import type { TimeEntry } from '../../utils/date/times.ts';
import type EuiI18n from '../../services/eui-i18n.ts';

interface TimeOption {
  entry: TimeEntry;
  id: string;
  label: string;
  className: string;
  selected: boolean;
  disabled: boolean;
}

export interface EuiDatePickerTimeListSignature {
  Element: HTMLUListElement;
  Args: {
    /** The entries, sorted (`timeList`). */
    entries: readonly TimeEntry[];
    /** The value's time of day: the entry with its hours and minutes is selected. */
    selected?: TimeOfDay | null;
    /** Without a selected entry, the active one is the last at or before this time (upstream: now). */
    reference?: TimeOfDay | null;
    /** `h:mm am` instead of `HH:mm`. */
    hour12?: boolean;
    /** Called with an entry that can be chosen, on a click, Enter or Space. */
    onPick?: (entry: TimeEntry, event: Event) => void;
    /** Nothing can be chosen, and the list is not focusable. */
    disabled?: boolean;
  };
}

function minutesOf(time: TimeOfDay): number {
  return time.hour * 60 + time.minute;
}

/**
 * @private The time list of `EuiDatePicker` (upstream `time.js`): a
 * listbox of wall times. ArrowUp and ArrowDown move the active entry,
 * Home and End go to the first and last, Enter and Space choose it.
 * Disabled entries can be reached, not chosen.
 */
export default class EuiDatePickerTimeList extends Component<EuiDatePickerTimeListSignature> {
  @service declare euiI18n: EuiI18n;

  /** The entry moved to with the keys, while the selected time is the one it was moved from. */
  @tracked private moved: { value: string; forSelected: number | null } | null =
    null;
  @tracked focused = false;
  /** Bumped by a key: the active entry is scrolled into view. */
  @tracked private scrollRequest = 0;
  private handledScroll = 0;
  private idPrefix = `${guidFor(this)}-time`;

  get label() {
    return this.euiI18n.lookupToken('euiDatePickerCalendar.time', 'Time');
  }

  get selectedMinutes(): number | null {
    const selected = this.args.selected;
    return selected ? minutesOf(selected) : null;
  }

  get interactive(): boolean {
    return !this.args.disabled;
  }

  /** The entry the keys act on: the moved one, else the selected one, else the last at or before the reference. */
  get activeValue(): string | null {
    const entries = this.args.entries;
    if (entries.length === 0) return null;
    const moved = this.moved;
    if (
      moved &&
      moved.forSelected === this.selectedMinutes &&
      entries.some((entry) => entry.value === moved.value)
    ) {
      return moved.value;
    }
    const target =
      this.selectedMinutes ??
      minutesOf(this.args.reference ?? { hour: 0, minute: 0, second: 0 });
    let active = entries[0]!;
    for (const entry of entries) {
      if (minutesOf(entry.time) > target) break;
      active = entry;
    }
    return active.value;
  }

  @cached
  get options(): TimeOption[] {
    const selected = this.selectedMinutes;
    const active = this.activeValue;
    const hour12 = this.args.hour12;
    return this.args.entries.map((entry, i) => {
      const isSelected =
        selected !== null && minutesOf(entry.time) === selected;
      const disabled = entry.problem !== null;
      const classes = ['react-datepicker__time-list-item'];
      if (isSelected) {
        classes.push('react-datepicker__time-list-item--selected');
      } else if (entry.value === active) {
        classes.push('react-datepicker__time-list-item--preselected');
      }
      if (disabled) classes.push('react-datepicker__time-list-item--disabled');
      if (entry.injected)
        classes.push('react-datepicker__time-list-item--injected');
      return {
        entry,
        id: `${this.idPrefix}-${i}`,
        label: formatTime(entry.time, { hour12 }),
        className: classes.join(' '),
        selected: isSelected,
        disabled
      };
    });
  }

  get activeId(): string | undefined {
    if (!this.interactive) return undefined;
    const active = this.activeValue;
    return this.options.find((option) => option.entry.value === active)?.id;
  }

  /* Scrolling: the list scrolls itself (`scrollIntoView` could move the page under a popover). */

  private scrollTo(list: HTMLElement, item: HTMLElement, center: boolean) {
    const top =
      item.getBoundingClientRect().top -
      list.getBoundingClientRect().top +
      list.scrollTop;
    const bottom = top + item.offsetHeight;
    if (center) {
      list.scrollTop = Math.max(
        0,
        top - (list.clientHeight - item.offsetHeight) / 2
      );
    } else if (top < list.scrollTop) {
      list.scrollTop = top;
    } else if (bottom > list.scrollTop + list.clientHeight) {
      list.scrollTop = bottom - list.clientHeight;
    }
  }

  /** On insert and when the selected time changes: the selected (or active) entry in the middle, as upstream. */
  centerSelected = modifier(
    (list: HTMLElement, [selected]: [number | null]) => {
      void selected;
      const item =
        list.querySelector<HTMLElement>(
          '.react-datepicker__time-list-item--selected'
        ) ??
        list.querySelector<HTMLElement>(
          '.react-datepicker__time-list-item--preselected'
        );
      if (item) this.scrollTo(list, item, true);
    }
  );

  /** After a key: the active entry just into view. */
  followActive = modifier((list: HTMLElement, [request]: [number]) => {
    if (request === this.handledScroll) return;
    this.handledScroll = request;
    const id = this.activeId;
    const item = id ? list.querySelector<HTMLElement>(`#${id}`) : null;
    if (item) this.scrollTo(list, item, false);
  });

  /* Actions */

  @action
  pick(option: TimeOption, event: Event) {
    if (!this.interactive || option.disabled) return;
    this.moved = null;
    this.args.onPick?.(option.entry, event);
  }

  @action
  onKeyDown(event: KeyboardEvent) {
    if (!this.interactive || event.altKey || event.ctrlKey || event.metaKey) {
      return;
    }
    const options = this.options;
    if (options.length === 0) return;
    const index = Math.max(
      0,
      options.findIndex((option) => option.entry.value === this.activeValue)
    );
    let next: number;
    switch (event.key) {
      case 'ArrowUp':
        next = Math.max(0, index - 1);
        break;
      case 'ArrowDown':
        next = Math.min(options.length - 1, index + 1);
        break;
      case 'Home':
        next = 0;
        break;
      case 'End':
        next = options.length - 1;
        break;
      case 'Enter':
      case ' ':
        event.preventDefault();
        this.pick(options[index]!, event);
        return;
      default:
        return;
    }
    event.preventDefault();
    this.moved = {
      value: options[next]!.entry.value,
      forSelected: this.selectedMinutes
    };
    this.scrollRequest++;
  }

  @action
  onFocus() {
    this.focused = true;
  }

  @action
  onBlur() {
    this.focused = false;
  }

  <template>
    <div
      class="react-datepicker__time-container
        {{if this.focused 'react-datepicker__time-container--focus'}}"
    >
      <div class="react-datepicker__time">
        <div
          class="react-datepicker__time-box react-datepicker__time-box--accessible"
        >
          <ul
            class="react-datepicker__time-list"
            role="listbox"
            aria-label={{this.label}}
            aria-activedescendant={{this.activeId}}
            aria-disabled={{unless this.interactive "true"}}
            tabindex={{if this.interactive "0" "-1"}}
            ...attributes
            {{on "keydown" this.onKeyDown}}
            {{on "focus" this.onFocus}}
            {{on "blur" this.onBlur}}
            {{this.centerSelected this.selectedMinutes}}
            {{this.followActive this.scrollRequest}}
          >
            {{#each this.options key="id" as |option|}}
              {{! template-lint-disable require-presentational-children }}
              <li
                id={{option.id}}
                role="option"
                class={{option.className}}
                aria-selected={{if option.selected "true" "false"}}
                aria-disabled={{if option.disabled "true"}}
                data-time={{option.entry.value}}
                {{on "click" (fn this.pick option)}}
              >{{option.label}}</li>
            {{/each}}
          </ul>
        </div>
      </div>
    </div>
  </template>
}
