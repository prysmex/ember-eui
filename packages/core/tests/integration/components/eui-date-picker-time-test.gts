import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  blur,
  click,
  fillIn,
  focus,
  render,
  settled,
  triggerKeyEvent
} from '@ember/test-helpers';
import { registerWarnHandler } from '@ember/debug';
import { array } from '@ember/helper';
import { tracked } from '@glimmer/tracking';

import moment from 'moment';
import { tabbable } from 'tabbable';

import EuiDatePicker from '#src/components/eui-date-picker.gts';

import type { EuiDatePickerInputError } from '#src/components/eui-date-picker.gts';
import type EuiConfigService from '#src/services/eui-config.ts';

let warnings: string[] | null = null;
registerWarnHandler((message, options, next) => {
  if (
    warnings &&
    String(options?.id ?? '').startsWith('ember-eui.eui-date-picker')
  ) {
    warnings.push(message);
    return;
  }
  next(message, options);
});

function el<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

const input = (root: ParentNode = document) =>
  el<HTMLInputElement>('input.euiDatePicker', root);
const panel = () => document.querySelector<HTMLElement>('[data-popover-panel]');
const day = (date: string) =>
  el<HTMLButtonElement>(
    `[data-popover-panel] td[data-date="${date}"] > button`
  );
const list = (root: ParentNode = document) =>
  el<HTMLUListElement>('.react-datepicker__time-list', root);
const time = (value: string, root: ParentNode = document) =>
  el<HTMLLIElement>(`li[data-time="${value}"]`, list(root));
const times = (root: ParentNode = document) =>
  [...list(root).querySelectorAll<HTMLLIElement>('li')].map(
    (li) => li.dataset['time']
  );
const active = () => {
  const id = list().getAttribute('aria-activedescendant');
  return id ? document.getElementById(id)?.dataset['time'] : undefined;
};

async function press(target: Element, key: string, options = {}) {
  await triggerKeyEvent(target, 'keydown', key, options);
}

class State {
  @tracked value: unknown = null;
  @tracked zone = 'utc';
  changes: (string | null)[] = [];
  errors: EuiDatePickerInputError[] = [];
  onChange = (value: string | null) => {
    this.changes.push(value);
    this.value = value;
  };
  onInputError = (error: EuiDatePickerInputError) => {
    this.errors.push(error);
  };
}

const NEW_YORK = 'America/New_York';

module('Integration | Component | eui-date-picker | time', function (hooks) {
  setupRenderingTest(hooks);

  hooks.afterEach(function () {
    warnings = null;
  });

  test('@showTimeSelect: the time list beside the month, upstream markup, the value shown in the zone', async function (assert) {
    await render(
      <template>
        <EuiDatePicker
          @value="2026-11-24T21:30:00.000Z"
          @showTimeSelect={{true}}
          @timeZone="America/Monterrey"
          @dateOrder="dmy"
          @hour12={{false}}
          aria-label="Starts at"
        />
      </template>
    );
    assert
      .dom(input())
      .hasValue('24/11/2026 15:30', 'DESIGN 4.4: the wall clock in the zone')
      .hasAttribute('placeholder', 'DD/MM/YYYY HH:mm');
    assert
      .dom('.euiFormControlLayoutIcons [data-icon-type="calendar"]')
      .exists();
    await click(input());
    const root = el('[data-popover-panel] .react-datepicker');
    assert
      .dom(root)
      .doesNotHaveClass('react-datepicker--time-only')
      .hasAttribute('class', /react-datepicker/);
    assert
      .dom(
        '.react-datepicker > .react-datepicker__month-container + .react-datepicker__time-container',
        panel()!
      )
      .exists('the time list after the month, inside the calendar root');
    assert
      .dom(
        '.react-datepicker__time-container > .react-datepicker__time > .react-datepicker__time-box.react-datepicker__time-box--accessible > ul.react-datepicker__time-list',
        root
      )
      .exists("upstream's nesting");
    assert
      .dom(list())
      .hasAttribute('role', 'listbox')
      .hasAttribute('aria-label', 'Time')
      .hasAttribute('tabindex', '0');
    assert.strictEqual(times().length, 48, 'every 30 minutes by default');
    assert.strictEqual(times()[0], '00:00');
    assert
      .dom(time('15:30'))
      .hasClass('react-datepicker__time-list-item--selected')
      .hasAttribute('role', 'option')
      .hasAttribute('aria-selected', 'true')
      .hasText('15:30');
    assert.dom(time('15:00')).hasAttribute('aria-selected', 'false');
    assert.strictEqual(active(), '15:30', 'the active option is the selected');
    assert
      .dom('td[data-date="2026-11-24"]', panel()!)
      .hasClass('react-datepicker__day--selected', 'the day in the zone');
  });

  test('picking a time emits the instant, zeroes seconds, closes and returns focus (9 #28)', async function (assert) {
    const state = new State();
    state.value = '2026-11-24T15:30:45.123Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone="utc"
          @dateOrder="dmy"
          @hour12={{false}}
        />
      </template>
    );
    assert.dom(input()).hasValue('24/11/2026 15:30', 'no seconds shown');
    await click(input());
    await click(time('09:00'));
    assert.deepEqual(state.changes, ['2026-11-24T09:00:00.000Z']);
    assert.strictEqual(panel(), null, 'closes, as upstream');
    assert.dom(input()).isFocused().hasValue('24/11/2026 09:00');

    await click(input());
    await click(time('09:00'));
    assert.strictEqual(state.changes.length, 1, 'the same time emits nothing');
  });

  test('picking a day keeps the wall time and the seconds, and stays open (9 #27)', async function (assert) {
    const state = new State();
    state.value = '2026-11-24T15:30:45.123Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone="utc"
          @dateOrder="dmy"
          @hour12={{false}}
        />
      </template>
    );
    await click(input());
    await click(day('2026-11-10'));
    assert.deepEqual(state.changes, ['2026-11-10T15:30:45.123Z']);
    assert.ok(panel(), 'open for the time, as upstream');
    assert
      .dom(time('15:30'))
      .hasClass('react-datepicker__time-list-item--selected');
  });

  test('no value: a day is midnight; a time goes on the focused day', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone="utc"
          @openToDate="2026-11-20"
        />
      </template>
    );
    await click(input());
    assert.dom(list()).exists();
    assert
      .dom('.react-datepicker__time-list-item--selected', list())
      .doesNotExist();
    assert
      .dom('.react-datepicker__time-list-item--preselected', list())
      .exists({ count: 1 }, 'an active entry near the time now');
    await click(time('10:00'));
    assert.deepEqual(
      state.changes,
      ['2026-11-20T10:00:00.000Z'],
      '@openToDate holds the focus, so the time goes there'
    );

    state.value = null;
    state.changes = [];
    await settled();
    await click(input());
    await click(day('2026-11-03'));
    assert.deepEqual(state.changes, ['2026-11-03T00:00:00.000Z']);
  });

  test('a DST gap day leaves out the missing times; typed, a gap time resolves forward (9 #19)', async function (assert) {
    const state = new State();
    state.value = '2026-03-08T05:00:00.000Z'; // 00:00 EST
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @showTimeSelect={{true}}
          @timeZone={{NEW_YORK}}
          @dateOrder="dmy"
          @hour12={{false}}
        />
      </template>
    );
    await click(input());
    const listed = times();
    assert.false(listed.includes('02:00'), '02:00 does not exist');
    assert.false(listed.includes('02:30'), '02:30 does not exist');
    assert.true(listed.includes('01:30'));
    assert.true(listed.includes('03:00'));
    assert.strictEqual(listed.length, 46);

    await fillIn(input(), '08/03/2026 02:30');
    await press(input(), 'Enter');
    assert.deepEqual(state.changes, ['2026-03-08T07:30:00.000Z'], '03:30 EDT');
    assert.deepEqual(state.errors, []);
    assert.dom(input()).hasValue('08/03/2026 03:30', 'the input shows 03:30');
  });

  test('an overlap: 01:30 is listed once and is the first (9 #20); a stored second 01:30 survives (9 #21)', async function (assert) {
    const state = new State();
    state.value = '2026-11-01T04:00:00.000Z'; // 00:00 EDT
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone={{NEW_YORK}}
          @dateOrder="dmy"
          @hour12={{false}}
        />
      </template>
    );
    await click(input());
    assert.strictEqual(times().filter((t) => t === '01:30').length, 1, 'once');
    assert.strictEqual(times().length, 48);
    await click(time('01:30'));
    assert.deepEqual(state.changes, ['2026-11-01T05:30:00.000Z'], 'EDT');

    // the second 01:30 (EST), stored by someone else
    state.value = '2026-11-01T06:30:00.000Z';
    state.changes = [];
    await settled();
    assert.dom(input()).hasValue('01/11/2026 01:30');
    await click(input());
    assert
      .dom(time('01:30'))
      .hasClass('react-datepicker__time-list-item--selected');
    await press(input(), 'Escape');
    await click(input());
    await blur(input());
    await focus(input());
    await press(input(), 'Enter');
    assert.deepEqual(state.changes, [], 'open, close, blur, Enter: nothing');
    assert.strictEqual(state.value, '2026-11-01T06:30:00.000Z', 'intact');

    await click(input());
    await click(time('01:30'));
    assert.deepEqual(
      state.changes,
      [],
      'picking the same wall clock does not move it to the first'
    );
  });

  test('a day change keeps the wall time and resolves again (9 #22, #23)', async function (assert) {
    const state = new State();
    state.value = '2026-10-31T05:30:00.000Z'; // 01:30 EDT, 31 October
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone={{NEW_YORK}}
          @firstDayOfWeek={{1}}
        />
      </template>
    );
    await click(input());
    await click(day('2026-11-01'));
    assert.deepEqual(
      state.changes,
      ['2026-11-01T05:30:00.000Z'],
      'the first 01:30 of 1 November'
    );

    state.value = '2026-03-07T07:30:00.000Z'; // 02:30 EST, 7 March
    state.changes = [];
    await settled();
    await click(input());
    await click(day('2026-03-08'));
    assert.deepEqual(
      state.changes,
      ['2026-03-08T07:30:00.000Z'],
      '03:30 EDT on 8 March'
    );
  });

  test('typed date and time: committed on Enter, limits and errors, ISO instants', async function (assert) {
    const state = new State();
    state.value = '2026-11-24T15:30:00.000Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @showTimeSelect={{true}}
          @timeZone="utc"
          @dateOrder="dmy"
          @hour12={{false}}
          @minDate="2026-11-24T09:00:00.000Z"
          @maxTime="18:00"
        />
      </template>
    );
    await fillIn(input(), '25/11/2026 3:45 pm');
    assert.deepEqual(state.changes, [], 'nothing while typing');
    await press(input(), 'Enter');
    assert.deepEqual(state.changes, ['2026-11-25T15:45:00.000Z']);
    assert.dom(input()).hasValue('25/11/2026 15:45', 'rewritten');

    await fillIn(input(), '25/11/2026');
    await press(input(), 'Enter');
    assert.deepEqual(
      state.changes.at(-1),
      '2026-11-25T00:00:00.000Z',
      'a date alone is midnight'
    );

    await fillIn(input(), '24/11/2026 08:30');
    await press(input(), 'Enter');
    assert.deepEqual(
      state.errors.map((e) => e.reason),
      ['min'],
      'before the instant @minDate'
    );
    await fillIn(input(), '26/11/2026 19:00');
    await press(input(), 'Enter');
    assert.deepEqual(
      state.errors.map((e) => e.reason),
      ['min', 'max'],
      'after @maxTime'
    );
    await fillIn(input(), '26/11/2026 25:00');
    await press(input(), 'Enter');
    assert.strictEqual(state.errors.at(-1)!.reason, 'unreadable');
    assert.dom(input()).hasAria('invalid', 'true');
    assert.strictEqual(state.changes.length, 2, 'no change on errors');

    await fillIn(input(), '2026-11-27T12:00:00+02:00');
    await blur(input());
    assert.strictEqual(
      state.changes.at(-1),
      '2026-11-27T10:00:00.000Z',
      'an ISO instant with an offset is that instant, emitted as Z'
    );
  });

  test('time limits and instant limits disable entries; disabled entries cannot be picked', async function (assert) {
    const state = new State();
    state.value = '2026-11-24T12:00:00.000Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone="utc"
          @minDate="2026-11-24T10:15:00.000Z"
          @maxTime="20:00"
          @excludeTimes={{array "14:00"}}
          @injectTimes={{array "12:45"}}
        />
      </template>
    );
    await click(input());
    assert
      .dom(time('10:00'))
      .hasClass('react-datepicker__time-list-item--disabled')
      .hasAria('disabled', 'true');
    assert
      .dom(time('10:30'))
      .doesNotHaveClass('react-datepicker__time-list-item--disabled');
    assert
      .dom(time('20:30'))
      .hasClass('react-datepicker__time-list-item--disabled', '@maxTime');
    assert
      .dom(time('14:00'))
      .hasClass('react-datepicker__time-list-item--disabled', '@excludeTimes');
    assert
      .dom(time('12:45'))
      .hasClass('react-datepicker__time-list-item--injected', '@injectTimes');
    assert.strictEqual(times().length, 49);
    await click(time('10:00'));
    await click(time('14:00'));
    assert.deepEqual(state.changes, [], 'disabled times are refused');
    assert.ok(panel(), 'and nothing closes');
    assert
      .dom('td[data-date="2026-11-23"]', panel()!)
      .hasClass(
        'react-datepicker__day--disabled',
        'the day before the instant'
      );
  });

  test('keys in the time list: arrows, Home, End, Enter; Tab from the grid', async function (assert) {
    const state = new State();
    state.value = '2026-11-24T12:00:00.000Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone="utc"
          @maxTime="13:00"
        />
      </template>
    );
    await click(input());
    await press(input(), 'ArrowDown');
    assert.dom(day('2026-11-24')).isFocused();
    // what Tab does from the grid: native focus moves to the list (the
    // test helpers' focus() blurs the input first, which is not a Tab)
    list().focus();
    await settled();
    assert.dom(list()).isFocused();
    assert.dom('.react-datepicker__time-container--focus', panel()!).exists();
    const stops = tabbable(panel()!);
    assert.strictEqual(
      stops.at(-1),
      list(),
      'Tab goes from the grid to the list'
    );
    assert.strictEqual(active(), '12:00');
    await press(list(), 'ArrowDown');
    assert.strictEqual(active(), '12:30');
    assert
      .dom(time('12:30'))
      .hasClass('react-datepicker__time-list-item--preselected');
    await press(list(), 'ArrowUp');
    await press(list(), 'ArrowUp');
    assert.strictEqual(active(), '11:30');
    await press(list(), 'Home');
    assert.strictEqual(active(), '00:00');
    await press(list(), 'ArrowUp');
    assert.strictEqual(active(), '00:00', 'stops at the first');
    await press(list(), 'End');
    assert.strictEqual(active(), '23:30');
    await press(list(), 'Enter');
    assert.deepEqual(state.changes, [], 'a disabled entry is not chosen');
    assert.ok(panel());
    await press(list(), 'Home');
    await press(list(), 'ArrowDown');
    await press(list(), ' ');
    assert.deepEqual(state.changes, ['2026-11-24T00:30:00.000Z'], 'Space');
    assert.strictEqual(panel(), null, 'closed');
    assert.dom(input()).isFocused();
  });

  test('the selected entry is scrolled into the middle of the list', async function (assert) {
    await render(
      <template>
        <EuiDatePicker
          @value="2026-11-24T20:00:00.000Z"
          @showTimeSelect={{true}}
          @timeZone="utc"
        />
      </template>
    );
    const scrollY = window.scrollY;
    await click(input());
    const box = list().getBoundingClientRect();
    const item = time('20:00').getBoundingClientRect();
    assert.true(list().scrollTop > 0, 'scrolled');
    assert.true(
      item.top >= box.top && item.bottom <= box.bottom,
      'the selected time is visible'
    );
    assert.strictEqual(window.scrollY, scrollY, 'the page did not scroll');
  });

  test('@showTimeSelectOnly: time list only, clock icon, HH:mm values, typed times (9 #42)', async function (assert) {
    const state = new State();
    state.value = '09:30';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @showTimeSelect={{true}}
          @showTimeSelectOnly={{true}}
          @hour12={{false}}
          @minTime="06:00"
          @maxTime="22:00"
          aria-label="Opens at"
        />
      </template>
    );
    assert.dom(input()).hasValue('09:30').hasAttribute('placeholder', 'HH:mm');
    assert.dom('.euiFormControlLayoutIcons [data-icon-type="clock"]').exists();
    await click(input());
    assert.dom(panel()).hasAttribute('aria-label', 'Choose time, Opens at');
    assert
      .dom('.react-datepicker', panel()!)
      .hasClass('react-datepicker--time-only');
    assert.dom('table[role="grid"]', panel()!).doesNotExist();
    assert.dom('.react-datepicker__navigation', panel()!).doesNotExist();
    assert.dom('.react-datepicker__month-container', panel()!).doesNotExist();
    assert
      .dom(time('09:30'))
      .hasClass('react-datepicker__time-list-item--selected');
    assert
      .dom(time('05:30'))
      .hasClass('react-datepicker__time-list-item--disabled', '@minTime');
    await click(time('10:00'));
    assert.deepEqual(state.changes, ['10:00']);
    assert.strictEqual(panel(), null);

    await fillIn(input(), '3 pm');
    await press(input(), 'Enter');
    assert.deepEqual(state.changes, ['10:00', '15:00']);
    assert.dom(input()).hasValue('15:00');
    await fillIn(input(), '23:00');
    await press(input(), 'Enter');
    assert.deepEqual(
      state.errors.map((e) => e.reason),
      ['max']
    );
    await fillIn(input(), '15');
    await press(input(), 'Enter');
    assert.strictEqual(state.errors.at(-1)!.reason, 'unreadable');
    await press(input(), 'Escape');
    await press(input(), 'Escape');
    assert.dom(input()).hasValue('15:00', 'Escape restores');

    // ArrowDown moves focus into the list
    await press(input(), 'ArrowDown');
    assert.dom(list()).isFocused();
  });

  test('@seconds: typed seconds are kept and shown; time only emits HH:mm:ss', async function (assert) {
    const state = new State();
    state.value = '2026-11-24T15:30:45.000Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @seconds={{true}}
          @timeZone="utc"
          @dateOrder="dmy"
          @hour12={{false}}
        />
      </template>
    );
    assert
      .dom(input())
      .hasValue('24/11/2026 15:30:45')
      .hasAttribute('placeholder', 'DD/MM/YYYY HH:mm:ss');
    await fillIn(input(), '24/11/2026 15:31:07');
    await press(input(), 'Enter');
    assert.deepEqual(state.changes, ['2026-11-24T15:31:07.000Z']);

    const timeState = new State();
    timeState.value = '08:00:10';
    await render(
      <template>
        <EuiDatePicker
          @value={{timeState.value}}
          @onChange={{timeState.onChange}}
          @showTimeSelectOnly={{true}}
          @seconds={{true}}
          @hour12={{false}}
        />
      </template>
    );
    assert.dom(input()).hasValue('08:00:10');
    await click(input());
    await click(time('09:00:00'));
    assert.deepEqual(timeState.changes, ['09:00:00']);
  });

  test('@hour12 in the input and the list; @timeIntervals; an invalid interval warns (9 #52)', async function (assert) {
    warnings = [];
    await render(
      <template>
        <div data-p="a"><EuiDatePicker
            @value="2026-11-24T15:30:00.000Z"
            @showTimeSelect={{true}}
            @timeZone="utc"
            @dateOrder="mdy"
            @hour12={{true}}
            @timeIntervals={{15}}
          /></div>
      </template>
    );
    assert
      .dom(input())
      .hasValue('11/24/2026 3:30 pm')
      .hasAttribute('placeholder', 'MM/DD/YYYY hh:mm am');
    await click(input());
    assert.strictEqual(times().length, 96, 'every 15 minutes');
    assert.dom(time('15:30')).hasText('3:30 pm');
    assert.dom(time('00:15')).hasText('12:15 am');
    assert.deepEqual(warnings, []);

    await render(
      <template>
        <EuiDatePicker
          @value="09:00"
          @showTimeSelectOnly={{true}}
          @timeIntervals={{0}}
        />
      </template>
    );
    await click(input());
    assert.strictEqual(times().length, 48, '0 is treated as 30');
    assert.true(
      warnings.some((w) => w.includes('@timeIntervals 0')),
      warnings.join(' | ')
    );
  });

  test('a fixed offset (upstream utcOffset): shown and chosen at the offset, no DST (DESIGN 17)', async function (assert) {
    const state = new State();
    state.value = '2026-11-24T15:00:00.000Z';
    state.zone = '-02:00';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone={{state.zone}}
          @dateOrder="dmy"
          @hour12={{false}}
        />
      </template>
    );
    assert.dom(input()).hasValue('24/11/2026 13:00');
    state.zone = '-03:00';
    await settled();
    assert.dom(input()).hasValue('24/11/2026 12:00', 'another offset');
    assert.deepEqual(state.changes, [], 'changing the zone emits nothing');
    await click(input());
    await click(time('08:00'));
    assert.deepEqual(state.changes, ['2026-11-24T11:00:00.000Z']);

    // New York's spring gap day has every time at a fixed offset
    state.value = '2026-03-08T12:00:00.000Z';
    await settled();
    await click(input());
    assert.strictEqual(times().length, 48, 'no gap');
    assert.true(times().includes('02:30'));
  });

  test('a moment or a Date as the value of a date and time, and of a time (DESIGN 18, 19)', async function (assert) {
    warnings = [];
    const state = new State();
    const value = moment.utc('2026-11-24T15:30:00Z').utcOffset(330);
    const before = value.toISOString();
    state.value = value;
    const minDate = new Date(Date.UTC(2026, 10, 24, 10, 0));
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone="utc"
          @minDate={{minDate}}
          @dateOrder="dmy"
          @hour12={{false}}
        />
      </template>
    );
    assert
      .dom(input())
      .hasValue('24/11/2026 15:30', 'the instant, in the zone');
    await click(input());
    assert
      .dom(time('09:30'))
      .hasClass(
        'react-datepicker__time-list-item--disabled',
        'a Date @minDate is an instant'
      );
    await click(time('16:00'));
    assert.deepEqual(state.changes, ['2026-11-24T16:00:00.000Z'], 'a string');
    assert.strictEqual(value.toISOString(), before, 'not mutated');

    const timeValue = new Date(Date.UTC(2026, 10, 24, 7, 45));
    await render(
      <template>
        <EuiDatePicker
          @value={{timeValue}}
          @showTimeSelectOnly={{true}}
          @timeZone="+05:30"
          @hour12={{false}}
        />
      </template>
    );
    assert.dom(input()).hasValue('13:15', 'the wall time at the offset');
    assert.deepEqual(warnings, [], 'valid objects are read silently');
  });

  test('unreadable values in time modes: invalid, raw text, a warning', async function (assert) {
    warnings = [];
    await render(
      <template>
        <div data-p="a"><EuiDatePicker
            @value="2026-11-24"
            @showTimeSelect={{true}}
          /></div>
        <div data-p="b"><EuiDatePicker
            @value="9:30"
            @showTimeSelectOnly={{true}}
          /></div>
        <div data-p="c"><EuiDatePicker
            @value="12:00"
            @showTimeSelectOnly={{true}}
            @minTime="noon"
          /></div>
      </template>
    );
    assert
      .dom(input(el('[data-p="a"]')))
      .hasValue('2026-11-24')
      .hasAria('invalid', 'true');
    assert
      .dom(input(el('[data-p="b"]')))
      .hasValue('9:30')
      .hasAria('invalid', 'true');
    assert.true(
      warnings.some((w) => w.includes('"2026-11-24" is not an ISO instant')),
      warnings.join(' | ')
    );
    assert.true(
      warnings.some((w) => w.includes('"9:30" is not an HH:mm time')),
      warnings.join(' | ')
    );
    assert.true(
      warnings.some((w) => w.includes('@minTime "noon" is not an HH:mm time')),
      warnings.join(' | ')
    );
  });

  test('inline with @showTimeSelect: a time picked emits and the calendar stays', async function (assert) {
    const state = new State();
    state.value = '2026-11-24T12:00:00.000Z';
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone="utc"
        />
      </template>
    );
    assert.dom('.react-datepicker .react-datepicker__time-list').exists();
    await click(time('13:30'));
    assert.deepEqual(state.changes, ['2026-11-24T13:30:00.000Z']);
    await click(el('td[data-date="2026-11-25"] > button'));
    assert.deepEqual(state.changes, [
      '2026-11-24T13:30:00.000Z',
      '2026-11-25T13:30:00.000Z'
    ]);
    assert.dom('.react-datepicker__time-list').exists('still there');

    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value="09:00"
          @showTimeSelectOnly={{true}}
          @disabled={{true}}
        />
      </template>
    );
    assert
      .dom('.react-datepicker')
      .hasClass('react-datepicker--time-only')
      .hasClass('react-datepicker--non-interactive');
    assert
      .dom(list())
      .hasAttribute('tabindex', '-1')
      .hasAria('disabled', 'true');
  });

  test('@adjustDateOnChange: arrow keys and the selects change the value at once; off by default', async function (assert) {
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @adjustDateOnChange={{true}}
          @maxDate="2026-11-26"
          @locale="en-US"
        />
      </template>
    );
    await click(input());
    await press(input(), 'ArrowDown');
    await press(day('2026-11-24'), 'ArrowRight');
    assert.deepEqual(state.changes, ['2026-11-25']);
    assert.ok(panel(), 'still open');
    assert.dom(day('2026-11-25')).isFocused();
    await press(day('2026-11-25'), 'ArrowLeft');
    await press(day('2026-11-24'), 'ArrowUp');
    assert.deepEqual(state.changes, ['2026-11-25', '2026-11-24', '2026-11-17']);

    const plain = new State();
    plain.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{plain.value}}
          @onChange={{plain.onChange}}
          @locale="en-US"
        />
      </template>
    );
    await click(input());
    await press(input(), 'ArrowDown');
    await press(day('2026-11-24'), 'ArrowRight');
    assert.deepEqual(plain.changes, [], 'default: the value waits for a pick');
  });

  test('@adjustDateOnChange with @showTimeSelect keeps the wall time', async function (assert) {
    const state = new State();
    state.value = '2026-11-24T15:30:00.000Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @adjustDateOnChange={{true}}
          @showTimeSelect={{true}}
          @timeZone="utc"
        />
      </template>
    );
    await click(input());
    await press(input(), 'ArrowDown');
    await press(day('2026-11-24'), 'PageDown');
    assert.deepEqual(state.changes, ['2026-12-24T15:30:00.000Z']);
  });

  test('componentDefaults.EuiDatePicker.locale in euiConfig; @locale wins', async function (assert) {
    const config = this.owner.lookup('service:eui-config') as EuiConfigService;
    config.updateConfig({
      componentDefaults: { EuiDatePicker: { locale: 'en-GB' } }
    });
    await render(
      <template>
        <div data-p="a"><EuiDatePicker
            @value="2026-11-24T15:30:00.000Z"
            @showTimeSelect={{true}}
            @timeZone="utc"
          /></div>
        <div data-p="b"><EuiDatePicker
            @value="2026-11-24T15:30:00.000Z"
            @showTimeSelect={{true}}
            @timeZone="utc"
            @locale="en-US"
          /></div>
      </template>
    );
    assert
      .dom(input(el('[data-p="a"]')))
      .hasValue('24/11/2026 15:30', "en-GB's order and clock");
    assert
      .dom(input(el('[data-p="b"]')))
      .hasValue('11/24/2026 3:30 pm', '@locale wins');
  });

  test('keys that move to another month keep the popover open and the focus in the grid', async function (assert) {
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @locale="en-US"
        />
      </template>
    );
    await click(input());
    await press(input(), 'ArrowDown');
    assert.dom(day('2026-11-24')).isFocused();
    await press(day('2026-11-24'), 'PageDown');
    assert.ok(panel(), 'still open after the month changed');
    assert.dom(day('2026-12-24')).isFocused();
    await press(day('2026-12-24'), 'PageUp', { shiftKey: true });
    assert.ok(panel());
    assert.dom(day('2025-12-24')).isFocused();
    assert.deepEqual(state.changes, [], 'nothing chosen');
  });
});
