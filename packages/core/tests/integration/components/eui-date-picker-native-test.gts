import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  blur,
  click,
  fillIn,
  render,
  rerender,
  settled,
  triggerEvent
} from '@ember/test-helpers';
import { registerWarnHandler } from '@ember/debug';
import { array } from '@ember/helper';
import { tracked } from '@glimmer/tracking';

import moment from 'moment';

import EuiDatePicker from '#src/components/eui-date-picker.gts';

import type { EuiDatePickerInputError } from '#src/components/eui-date-picker.gts';
import type EuiConfigService from '#src/services/eui-config.ts';
import type Owner from '@ember/owner';

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
const isNative = (root: ParentNode = document) =>
  input(root).classList.contains('euiDatePicker--native');
const iconButton = () =>
  el<HTMLButtonElement>('.euiFormControlLayoutIcons button');

/* The environment of auto: `(pointer: coarse)` and `window.Capacitor` */

type CapacitorWindow = Window & { Capacitor?: unknown };
const realMatchMedia = window.matchMedia;

function stubPointer(coarse: boolean) {
  window.matchMedia = (query: string) => {
    if (query.replace(/\s/g, '') !== '(pointer:coarse)') {
      return realMatchMedia.call(window, query);
    }
    return {
      matches: coarse,
      media: query,
      onchange: null,
      addListener() {},
      removeListener() {},
      addEventListener() {},
      removeEventListener() {},
      dispatchEvent: () => false
    } as MediaQueryList;
  };
}

function stubCapacitor(capacitor: unknown) {
  (window as CapacitorWindow).Capacitor = capacitor;
}

/** What the OS input would report: a value (then focus leaves, as when the OS picker closes), and a half-filled field. */
async function osSets(target: HTMLInputElement, value: string) {
  await fillIn(target, value);
  await blur(target);
}

async function osHalfFills(target: HTMLInputElement) {
  target.value = '';
  Object.defineProperty(target, 'validity', {
    configurable: true,
    value: { badInput: true }
  });
  await triggerEvent(target, 'input');
  await triggerEvent(target, 'change');
}

class State {
  @tracked value: string | null = null;
  changes: (string | null)[] = [];
  errors: EuiDatePickerInputError[] = [];
  onChange = (value: string | null) => {
    this.changes.push(value);
    this.value = value;
  };
  onInputError = (error: EuiDatePickerInputError) => {
    this.errors.push(error);
  };
  onClear = () => {
    this.value = null;
  };
}

const NEW_YORK = 'America/New_York';

function last<T>(items: T[]): T | undefined {
  return items[items.length - 1];
}

module('Integration | Component | eui-date-picker | native', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    stubPointer(false);
  });

  hooks.afterEach(function () {
    window.matchMedia = realMatchMedia;
    delete (window as CapacitorWindow).Capacitor;
    warnings = null;
  });

  /* The choice (DESIGN 6.2) */

  test('auto, a fine pointer and no Capacitor: the calendar path', async function (assert) {
    await render(<template><EuiDatePicker @value="2026-11-24" /></template>);
    assert.dom(input()).hasAttribute('type', 'text');
    assert.false(isNative(), 'the text input');
    assert.dom(input()).hasAttribute('aria-haspopup', 'dialog');
  });

  test('auto, a coarse pointer: the native date input', async function (assert) {
    stubPointer(true);
    await render(<template><EuiDatePicker @value="2026-11-24" /></template>);
    assert.true(isNative());
    assert
      .dom(input())
      .hasAttribute('type', 'date')
      .hasValue('2026-11-24')
      .doesNotHaveAttribute('aria-haspopup')
      .doesNotHaveAttribute('placeholder');
  });

  test('auto, Capacitor on a device (isNativePlatform true), a fine pointer: native', async function (assert) {
    stubCapacitor({ isNativePlatform: () => true });
    await render(<template><EuiDatePicker @value="2026-11-24" /></template>);
    assert.dom(input()).hasAttribute('type', 'date');
  });

  test('9 #47: Capacitor in a web build (isNativePlatform false) falls to the pointer test', async function (assert) {
    stubCapacitor({ isNativePlatform: () => false });
    await render(
      <template>
        <div data-p="fine"><EuiDatePicker /></div>
      </template>
    );
    assert.dom(input(el('[data-p="fine"]'))).hasAttribute('type', 'text');

    stubPointer(true);
    await render(
      <template>
        <div data-p="coarse"><EuiDatePicker /></div>
      </template>
    );
    assert.dom(input(el('[data-p="coarse"]'))).hasAttribute('type', 'date');
  });

  test('a Capacitor global without isNativePlatform, or one that throws, is no Capacitor', async function (assert) {
    stubCapacitor({});
    await render(
      <template>
        <div data-p="a"><EuiDatePicker /></div>
      </template>
    );
    assert.dom(input(el('[data-p="a"]'))).hasAttribute('type', 'text');

    stubCapacitor({
      isNativePlatform: () => {
        throw new Error('no bridge');
      }
    });
    await render(
      <template>
        <div data-p="b"><EuiDatePicker /></div>
      </template>
    );
    assert.dom(input(el('[data-p="b"]'))).hasAttribute('type', 'text');
  });

  test('decision 7: auto takes the calendar with an argument the OS cannot honour', async function (assert) {
    stubPointer(true);
    stubCapacitor({ isNativePlatform: () => true });
    const workdays = (date: string) =>
      new Date(`${date}T00:00:00Z`).getUTCDay() % 6 !== 0;
    const dayClass = () => 'special';
    await render(
      <template>
        <div data-p="filterDate"><EuiDatePicker
            @filterDate={{workdays}}
          /></div>
        <div data-p="excludeDates"><EuiDatePicker
            @excludeDates={{array "2026-11-25"}}
          /></div>
        <div data-p="includeDates"><EuiDatePicker
            @includeDates={{array "2026-11-25"}}
          /></div>
        <div data-p="excludeTimes"><EuiDatePicker
            @showTimeSelect={{true}}
            @excludeTimes={{array "10:00"}}
          /></div>
        <div data-p="injectTimes"><EuiDatePicker
            @showTimeSelect={{true}}
            @injectTimes={{array "10:15"}}
          /></div>
        <div data-p="dayClassName"><EuiDatePicker
            @dayClassName={{dayClass}}
          /></div>
        <div data-p="none"><EuiDatePicker @minDate="2026-11-01" /></div>
      </template>
    );
    for (const name of [
      'filterDate',
      'excludeDates',
      'includeDates',
      'excludeTimes',
      'injectTimes',
      'dayClassName'
    ]) {
      assert.false(isNative(el(`[data-p="${name}"]`)), `@${name}: calendar`);
    }
    assert.true(
      isNative(el('[data-p="none"]')),
      'limits the OS input can show (min, max) keep native'
    );
  });

  test('@native={{true}} forces native on a desktop; @native={{false}} forces the calendar on a phone', async function (assert) {
    await render(
      <template>
        <div data-p="true"><EuiDatePicker @native={{true}} /></div>
      </template>
    );
    assert.true(isNative(el('[data-p="true"]')));

    stubPointer(true);
    stubCapacitor({ isNativePlatform: () => true });
    await render(
      <template>
        <div data-p="false"><EuiDatePicker @native={{false}} /></div>
        <div data-p="auto"><EuiDatePicker @native="auto" /></div>
      </template>
    );
    assert.false(isNative(el('[data-p="false"]')));
    assert.true(isNative(el('[data-p="auto"]')), "'auto' detects");
  });

  test('componentDefaults.EuiDatePicker.native in euiConfig: after @native, before auto', async function (assert) {
    const config = this.owner.lookup('service:eui-config') as EuiConfigService;
    config.updateConfig({
      componentDefaults: { EuiDatePicker: { native: true } }
    });
    await render(
      <template>
        <div data-p="config"><EuiDatePicker /></div>
        <div data-p="arg"><EuiDatePicker @native={{false}} /></div>
      </template>
    );
    assert.true(isNative(el('[data-p="config"]')), 'the config forces native');
    assert.false(isNative(el('[data-p="arg"]')), '@native wins');

    config.updateConfig({
      componentDefaults: { EuiDatePicker: { native: false } }
    });
    stubPointer(true);
    await render(
      <template>
        <div data-p="phone"><EuiDatePicker /></div>
        <div data-p="arg"><EuiDatePicker @native={{true}} /></div>
      </template>
    );
    assert.false(
      isNative(el('[data-p="phone"]')),
      'the config forces the calendar on a phone'
    );
    assert.true(isNative(el('[data-p="arg"]')), '@native wins');

    config.updateConfig({
      componentDefaults: { EuiDatePicker: { native: 'auto' } }
    });
    await render(
      <template>
        <div data-p="auto"><EuiDatePicker /></div>
      </template>
    );
    assert.true(
      isNative(el('[data-p="auto"]')),
      "'auto' in the config detects"
    );
  });

  test('9 #44: @inline shows the calendar whatever @native says, with a warning for @native={{true}}', async function (assert) {
    warnings = [];
    stubPointer(true);
    await render(
      <template>
        <div data-p="auto"><EuiDatePicker @inline={{true}} /></div>
        <div data-p="true"><EuiDatePicker
            @inline={{true}}
            @native={{true}}
          /></div>
      </template>
    );
    for (const p of ['auto', 'true']) {
      assert.dom(`[data-p="${p}"] .react-datepicker[role="group"]`).exists();
      assert.dom(`[data-p="${p}"] input[type="date"]`).doesNotExist();
    }
    assert.true(
      warnings.some((message) =>
        message.includes('@native={{true}} has no effect with @inline')
      ),
      warnings.join('\n')
    );
  });

  test('chosen once: it does not flip when the environment or @native changes later', async function (assert) {
    stubPointer(true);
    class Args {
      @tracked native: boolean | 'auto' = 'auto';
      @tracked value = '2026-11-24';
    }
    const args = new Args();
    await render(
      <template>
        <EuiDatePicker @value={{args.value}} @native={{args.native}} />
      </template>
    );
    assert.true(isNative());
    stubPointer(false);
    args.native = false;
    args.value = '2026-11-25';
    await settled();
    assert.true(isNative(), 'still native');
    assert.dom(input()).hasValue('2026-11-25', 'the value still follows');
  });

  /** The boot environment the picker reads (`-environment:main`), as on a server or a rehydrating client. */
  function bootAs(owner: Owner, overrides: object) {
    const environment = owner.lookup('-environment:main') as object;
    // an application instance's registry (not on the Owner type)
    (owner as unknown as { unregister(name: string): void }).unregister(
      '-environment:main'
    );
    owner.register(
      '-environment:main',
      { ...environment, ...overrides },
      { instantiate: false }
    );
  }

  test('9 #48: not interactive (server rendering): the calendar path, also on a phone', async function (assert) {
    stubPointer(true);
    stubCapacitor({ isNativePlatform: () => true });
    bootAs(this.owner, { isInteractive: false });
    await render(<template><EuiDatePicker @value="2026-11-24" /></template>);
    assert.dom(input()).hasAttribute('type', 'text');
  });

  test('a rehydrating page: the first render is the calendar path, as the server rendered it; then the native input, once', async function (assert) {
    stubPointer(true);
    bootAs(this.owner, { _renderMode: 'rehydrate' });
    const rendered: string[] = [];
    const inputRef = (element: HTMLInputElement | null) => {
      if (element) rendered.push(element.type);
    };
    await render(
      <template>
        <EuiDatePicker @value="2026-11-24" @inputRef={{inputRef}} />
      </template>
    );
    assert.deepEqual(rendered, ['text', 'date']);
    assert.dom(input()).hasAttribute('type', 'date').hasValue('2026-11-24');
  });

  /* Date */

  test("date: the native input inside EUI's field, its attributes, min and max", async function (assert) {
    stubPointer(true);
    let element: HTMLInputElement | null = null;
    const inputRef = (e: HTMLInputElement | null) => (element = e);
    await render(
      <template>
        <div data-p="default"><EuiDatePicker
            @id="due"
            @value="2026-11-24"
            @inputRef={{inputRef}}
            aria-label="Due date"
            data-test-subj="due"
          /></div>
        <div data-p="limits"><EuiDatePicker
            @value="2026-11-24"
            @minDate="2026-11-02"
            @maxDate="2026-12-20"
          /></div>
      </template>
    );
    const own = input(el('[data-p="default"]'));
    assert
      .dom(own)
      .hasClass('euiFieldText')
      .hasAttribute('id', 'due')
      .hasAttribute('aria-label', 'Due date')
      .hasAttribute('data-test-subj', 'due')
      .hasAttribute('min', '0001-01-01', 'the years the picker supports')
      .hasAttribute(
        'max',
        '9999-12-31',
        'Chromium takes six-digit years without it'
      )
      .doesNotHaveAttribute('step')
      .doesNotHaveAttribute('readonly');
    assert.strictEqual(element, own, '@inputRef gets the native input');
    assert
      .dom(
        '[data-p="default"] .euiFormControlLayout .euiFormControlLayout__childrenWrapper input'
      )
      .exists('inside the form control layout');
    assert
      .dom(input(el('[data-p="limits"]')))
      .hasAttribute('min', '2026-11-02')
      .hasAttribute('max', '2026-12-20');
  });

  test('date: the value in and out, as on the calendar path; the same value emits nothing', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
        />
      </template>
    );
    await osSets(input(), '2026-11-30');
    assert.deepEqual(state.changes, ['2026-11-30']);
    assert.dom(input()).hasValue('2026-11-30');
    await osSets(input(), '2026-11-30');
    assert.deepEqual(state.changes, ['2026-11-30'], 'unchanged: nothing');
    await osSets(input(), '');
    assert.deepEqual(state.changes, ['2026-11-30', null], 'the OS clear: null');
    assert.dom(input()).hasValue('');
    await osSets(input(), '');
    assert.deepEqual(
      state.changes,
      ['2026-11-30', null],
      'empty again: nothing'
    );
    assert.deepEqual(state.errors, []);
  });

  test('post-validation: a day outside @minDate or @maxDate is an input error, kept in the input, no @onChange', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @minDate="2026-11-02"
          @maxDate="2026-12-20"
        />
      </template>
    );
    await osSets(input(), '2026-11-01');
    assert.deepEqual(state.errors, [{ text: '2026-11-01', reason: 'min' }]);
    assert.deepEqual(state.changes, []);
    assert.strictEqual(state.value, '2026-11-24', 'the value is unchanged');
    assert
      .dom(input())
      .hasValue('2026-11-01', 'the refused day stays, as refused text does')
      .hasAttribute('aria-invalid', 'true')
      .hasClass('euiDatePicker--inputError');
    assert
      .dom('.euiFormControlLayoutIcons [data-icon-type="warning"]')
      .exists();

    await osSets(input(), '2027-01-05');
    assert.deepEqual(last(state.errors), {
      text: '2027-01-05',
      reason: 'max'
    });
    assert.deepEqual(state.changes, []);

    await osSets(input(), '2026-12-01');
    assert.deepEqual(state.changes, ['2026-12-01'], 'an allowed day');
    assert
      .dom(input())
      .doesNotHaveAttribute('aria-invalid')
      .doesNotHaveClass('euiDatePicker--inputError');
  });

  test('a value refused while the input has focus shows at once and is reported when focus leaves (keyboard entry passes years 0002, 0020…)', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @minDate="2026-11-02"
        />
      </template>
    );
    await fillIn(input(), '0002-11-27');
    await fillIn(input(), '0202-11-27');
    assert.deepEqual(state.errors, [], 'not yet reported');
    assert.dom(input()).hasAttribute('aria-invalid', 'true');
    await fillIn(input(), '2026-11-27');
    assert.deepEqual(state.changes, ['2026-11-27']);
    assert.dom(input()).doesNotHaveAttribute('aria-invalid');
    await blur(input());
    assert.deepEqual(
      state.errors,
      [],
      'what was left is allowed: nothing to report'
    );

    await fillIn(input(), '2026-10-01');
    assert.deepEqual(state.errors, []);
    await blur(input());
    assert.deepEqual(state.errors, [{ text: '2026-10-01', reason: 'min' }]);
    await triggerEvent(input(), 'focusout');
    assert.strictEqual(state.errors.length, 1, 'reported once');
  });

  test('a refused value goes when the value changes from outside', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @minDate="2026-11-02"
        />
      </template>
    );
    await osSets(input(), '2026-10-01');
    assert.dom(input()).hasAttribute('aria-invalid', 'true');
    state.value = '2026-11-10';
    await settled();
    assert
      .dom(input())
      .hasValue('2026-11-10')
      .doesNotHaveAttribute('aria-invalid');
  });

  test('9 #43: @native={{true}} with @filterDate and @excludeDates: a refused day is an input error, with a warning', async function (assert) {
    warnings = [];
    const state = new State();
    state.value = '2026-11-24';
    const workdays = (date: string) =>
      new Date(`${date}T00:00:00Z`).getUTCDay() % 6 !== 0;
    await render(
      <template>
        <EuiDatePicker
          @native={{true}}
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @filterDate={{workdays}}
          @excludeDates={{array "2026-11-26"}}
        />
      </template>
    );
    assert.true(isNative());
    assert.true(
      warnings.some(
        (message) =>
          message.includes('cannot show @filterDate, @excludeDates') &&
          message.includes('input error')
      ),
      warnings.join('\n')
    );
    await osSets(input(), '2026-11-28');
    assert.deepEqual(
      state.errors,
      [{ text: '2026-11-28', reason: 'disabled' }],
      'a Saturday'
    );
    await osSets(input(), '2026-11-26');
    assert.deepEqual(
      last(state.errors),
      { text: '2026-11-26', reason: 'disabled' },
      'excluded'
    );
    assert.dom(input()).hasAttribute('aria-invalid', 'true');
    assert.deepEqual(state.changes, []);
    await osSets(input(), '2026-11-27');
    assert.deepEqual(state.changes, ['2026-11-27']);
  });

  test('a half-filled field (bad input) emits nothing while edited, and is unreadable when focus leaves', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
        />
        <button type="button" data-p="next">next</button>
      </template>
    );
    await osHalfFills(input());
    assert.deepEqual(state.changes, [], 'not a clear: no null');
    assert.deepEqual(state.errors, []);
    assert.dom(input()).doesNotHaveAttribute('aria-invalid');
    await triggerEvent(input(), 'focusout');
    assert.deepEqual(state.errors, [{ text: '', reason: 'unreadable' }]);
    assert.dom(input()).hasAttribute('aria-invalid', 'true');
    assert.strictEqual(state.value, '2026-11-24');
  });

  test('Date and moment values and limits (DESIGN 18)', async function (assert) {
    stubPointer(true);
    const date = new Date(2026, 10, 24, 15, 30);
    const day = moment('2026-11-24', 'YYYY-MM-DD');
    const min = moment('2026-11-02', 'YYYY-MM-DD');
    await render(
      <template>
        <div data-p="date"><EuiDatePicker @value={{date}} /></div>
        <div data-p="moment"><EuiDatePicker
            @value={{day}}
            @minDate={{min}}
          /></div>
        <div data-p="instant"><EuiDatePicker
            @value={{date}}
            @showTimeSelect={{true}}
          /></div>
      </template>
    );
    assert
      .dom(input(el('[data-p="date"]')))
      .hasValue('2026-11-24', "the Date's local day");
    assert
      .dom(input(el('[data-p="moment"]')))
      .hasValue('2026-11-24')
      .hasAttribute('min', '2026-11-02');
    assert
      .dom(input(el('[data-p="instant"]')))
      .hasValue('2026-11-24T15:30', "the Date's instant, in the local zone");
  });

  test('an unreadable @value: an empty native input with the invalid look', async function (assert) {
    warnings = [];
    stubPointer(true);
    await render(<template><EuiDatePicker @value="2026-02-31" /></template>);
    assert.dom(input()).hasValue('').hasAttribute('aria-invalid', 'true');
    assert.true(
      warnings.some((message) => message.includes('"2026-02-31"')),
      warnings.join('\n')
    );
  });

  test('9 #30: without @onChange the input goes back to @value', async function (assert) {
    stubPointer(true);
    await render(<template><EuiDatePicker @value="2026-11-24" /></template>);
    await osSets(input(), '2026-11-30');
    assert.dom(input()).hasValue('2026-11-24');
  });

  /* The icon, clear, states */

  test('data-empty marks a native input that holds nothing, for the placeholder colour', async function (assert) {
    stubPointer(true);
    const state = new State();
    await render(
      <template>
        <EuiDatePicker @value={{state.value}} @onChange={{state.onChange}} />
      </template>
    );
    assert.dom(input()).hasAttribute('data-empty');
    await osSets(input(), '2026-11-24');
    assert.dom(input()).doesNotHaveAttribute('data-empty');
    state.value = null;
    await settled();
    assert
      .dom(input())
      .hasAttribute('data-empty', '', 'the value cleared from outside');
    state.value = '2026-11-25';
    await settled();
    assert.dom(input()).doesNotHaveAttribute('data-empty');
    await osHalfFills(input());
    assert
      .dom(input())
      .doesNotHaveAttribute('data-empty', 'a half-filled field is not empty');
  });

  test("EUI's icon opens the OS picker (showPicker), focusing the input; it is out of the tab order", async function (assert) {
    stubPointer(true);
    await render(<template><EuiDatePicker @value="2026-11-24" /></template>);
    const calls: string[] = [];
    input().showPicker = () => {
      calls.push('showPicker');
    };
    assert
      .dom(iconButton())
      .hasAttribute('aria-label', 'Choose date')
      .hasAttribute('tabindex', '-1');
    assert
      .dom('.euiFormControlLayoutIcons [data-icon-type="calendar"]')
      .exists();
    await click(iconButton());
    assert.deepEqual(calls, ['showPicker']);
    assert.dom(input()).isFocused();

    input().showPicker = () => {
      throw new DOMException('not allowed', 'NotAllowedError');
    };
    await click(iconButton());
    assert.dom(input()).isFocused('a refused showPicker is ignored');
  });

  test("the browser's indicator is hidden only while EUI's icon opens the picker", async function (assert) {
    stubPointer(true);
    await render(
      <template>
        <div data-p="icon"><EuiDatePicker /></div>
        <div data-p="no-icon"><EuiDatePicker @showIcon={{false}} /></div>
        <div data-p="control"><EuiDatePicker @controlOnly={{true}} /></div>
      </template>
    );
    assert.dom(input(el('[data-p="icon"]'))).hasAttribute('data-picker-icon');
    assert
      .dom(input(el('[data-p="no-icon"]')))
      .doesNotHaveAttribute('data-picker-icon');
    assert
      .dom(input(el('[data-p="control"]')))
      .doesNotHaveAttribute('data-picker-icon');
  });

  test('clear: the clear button empties the native input', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onClear={{state.onClear}}
        />
      </template>
    );
    await click('.euiFormControlLayoutClearButton');
    assert.strictEqual(state.value, null);
    assert.dom(input()).hasValue('');
    assert.dom('.euiFormControlLayoutClearButton').doesNotExist();
  });

  test('9 #46: @readOnly on the native path is a read-only text input with the formatted value', async function (assert) {
    stubPointer(true);
    await render(
      <template>
        <div data-p="date"><EuiDatePicker
            @value="2026-11-24"
            @readOnly={{true}}
            @dateOrder="dmy"
          /></div>
        <div data-p="time"><EuiDatePicker
            @value="2026-11-24T21:30:00.000Z"
            @showTimeSelect={{true}}
            @timeZone="America/Monterrey"
            @readOnly={{true}}
            @dateOrder="dmy"
            @hour12={{false}}
          /></div>
      </template>
    );
    assert
      .dom(input(el('[data-p="date"]')))
      .hasAttribute('type', 'text')
      .hasAttribute('readonly')
      .hasValue('24/11/2026');
    assert
      .dom(input(el('[data-p="time"]')))
      .hasAttribute('type', 'text')
      .hasValue('24/11/2026 15:30');
    await click(input(el('[data-p="date"]')));
    assert.dom('[data-popover-panel]').doesNotExist('nothing opens');
  });

  test('@disabled, @isInvalid, @compressed, @fullWidth on the native input', async function (assert) {
    stubPointer(true);
    const noop = () => {};
    await render(
      <template>
        <div data-p="disabled"><EuiDatePicker
            @value="2026-11-24"
            @disabled={{true}}
            @onClear={{noop}}
          /></div>
        <div data-p="invalid"><EuiDatePicker @isInvalid={{true}} /></div>
        <div data-p="sizes"><EuiDatePicker
            @compressed={{true}}
            @fullWidth={{true}}
          /></div>
      </template>
    );
    const disabled = el('[data-p="disabled"]');
    assert.dom(input(disabled)).isDisabled();
    assert.dom('button', disabled).isDisabled('the icon button too');
    assert.dom('.euiFormControlLayoutClearButton', disabled).doesNotExist();
    assert
      .dom(input(el('[data-p="invalid"]')))
      .hasAttribute('aria-invalid', 'true');
    // offset sizes: the test container is scaled
    const sizes = input(el('[data-p="sizes"]'));
    assert.strictEqual(sizes.offsetHeight, 32, 'compressed');
    assert.strictEqual(
      sizes.offsetWidth,
      el('[data-p="sizes"]').offsetWidth,
      'full width'
    );
    assert.strictEqual(
      input(el('[data-p="invalid"]')).offsetHeight,
      40,
      'the uncompressed height, as the text input'
    );
  });

  test('@controlOnly: the native input alone, no layout', async function (assert) {
    stubPointer(true);
    await render(
      <template>
        <EuiDatePicker @controlOnly={{true}} @value="2026-11-24" />
      </template>
    );
    assert.dom(input()).hasAttribute('type', 'date').hasValue('2026-11-24');
    assert.dom('.euiFormControlLayout').doesNotExist();
  });

  /* Date and time */

  test('date and time: datetime-local holds the wall clock in @timeZone; @onChange gets the instant', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-11-24T21:30:00.000Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone="America/Monterrey"
          @timeIntervals={{15}}
        />
      </template>
    );
    assert
      .dom(input())
      .hasAttribute('type', 'datetime-local')
      .hasValue('2026-11-24T15:30', 'DESIGN 4.4: the wall clock')
      .hasAttribute('step', '60', 'whole minutes; @timeIntervals is not a step')
      .hasAttribute('min', '0001-01-01T00:00')
      .hasAttribute('max', '9999-12-31T23:59');
    await osSets(input(), '2026-11-24T16:45');
    assert.deepEqual(state.changes, ['2026-11-24T22:45:00.000Z']);
    assert.dom(input()).hasValue('2026-11-24T16:45');
  });

  test('date and time: @seconds is step 1 and the value with seconds; limits as wall clocks, rounded inward', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-11-24T21:30:15.000Z';
    await render(
      <template>
        <div data-p="seconds"><EuiDatePicker
            @value={{state.value}}
            @onChange={{state.onChange}}
            @showTimeSelect={{true}}
            @seconds={{true}}
            @timeZone="utc"
          /></div>
        <div data-p="limits"><EuiDatePicker
            @showTimeSelect={{true}}
            @timeZone="utc"
            @minDate="2026-11-24T10:07:30.000Z"
            @maxDate="2026-11-30T18:45:30.000Z"
          /></div>
        <div data-p="days"><EuiDatePicker
            @showTimeSelect={{true}}
            @timeZone="America/Monterrey"
            @minDate="2026-11-02"
            @maxDate="2026-11-30"
          /></div>
      </template>
    );
    const seconds = input(el('[data-p="seconds"]'));
    assert
      .dom(seconds)
      .hasAttribute('step', '1')
      .hasValue('2026-11-24T21:30:15')
      .hasAttribute('max', '9999-12-31T23:59:59');
    await osSets(seconds, '2026-11-24T21:30:45');
    assert.deepEqual(state.changes, ['2026-11-24T21:30:45.000Z']);
    assert
      .dom(input(el('[data-p="limits"]')))
      .hasAttribute('min', '2026-11-24T10:08', 'the first whole minute inside')
      .hasAttribute('max', '2026-11-30T18:45');
    assert
      .dom(input(el('[data-p="days"]')))
      .hasAttribute('min', '2026-11-02T00:00')
      .hasAttribute('max', '2026-11-30T23:59');
  });

  test('date and time post-validation: instants outside the limits, @minTime and @maxTime', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-11-24T15:00:00.000Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @showTimeSelect={{true}}
          @timeZone="utc"
          @minDate="2026-11-24T10:07:30.000Z"
          @maxDate="2026-11-30"
          @minTime="09:00"
          @maxTime="17:00"
        />
      </template>
    );
    await osSets(input(), '2026-11-24T10:07');
    assert.deepEqual(
      last(state.errors),
      { text: '2026-11-24T10:07', reason: 'min' },
      'before the instant'
    );
    await osSets(input(), '2026-12-01T10:00');
    assert.deepEqual(last(state.errors), {
      text: '2026-12-01T10:00',
      reason: 'max'
    });
    await osSets(input(), '2026-11-25T08:30');
    assert.deepEqual(
      last(state.errors),
      { text: '2026-11-25T08:30', reason: 'min' },
      '@minTime'
    );
    await osSets(input(), '2026-11-25T17:30');
    assert.deepEqual(
      last(state.errors),
      { text: '2026-11-25T17:30', reason: 'max' },
      '@maxTime'
    );
    assert.deepEqual(state.changes, []);
    assert.dom(input()).hasAttribute('aria-invalid', 'true');
    await osSets(input(), '2026-11-24T10:08');
    assert.deepEqual(state.changes, ['2026-11-24T10:08:00.000Z']);
  });

  test('9 #45: a DST gap time from the OS resolves forward, and the input shows it', async function (assert) {
    stubPointer(true);
    const state = new State();
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone={{NEW_YORK}}
        />
      </template>
    );
    await osSets(input(), '2026-03-08T02:30');
    assert.deepEqual(state.changes, ['2026-03-08T07:30:00.000Z'], '03:30 EDT');
    assert.dom(input()).hasValue('2026-03-08T03:30');

    // the gap time again, now that it resolves to the value: no change, and
    // the input shows the value, not the time that does not exist
    await osSets(input(), '2026-03-08T02:30');
    assert.deepEqual(state.changes, ['2026-03-08T07:30:00.000Z']);
    assert.dom(input()).hasValue('2026-03-08T03:30');
  });

  test('a DST overlap: the first occurrence; a stored second occurrence survives a no-op change', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-11-01T06:30:00.000Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone={{NEW_YORK}}
        />
      </template>
    );
    assert.dom(input()).hasValue('2026-11-01T01:30', 'the second 01:30 (EST)');
    await osSets(input(), '2026-11-01T01:30');
    assert.deepEqual(
      state.changes,
      [],
      'the same wall clock: the value is intact'
    );
    await osSets(input(), '2026-11-01T01:45');
    await osSets(input(), '2026-11-01T01:30');
    assert.deepEqual(
      state.changes,
      ['2026-11-01T05:45:00.000Z', '2026-11-01T05:30:00.000Z'],
      'a new wall clock in the overlap is the first occurrence (EDT)'
    );
  });

  test('date and time without @seconds: changing the day keeps hidden seconds; changing the time zeroes them', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-11-24T15:30:45.123Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone="utc"
        />
      </template>
    );
    assert.dom(input()).hasValue('2026-11-24T15:30');
    await osSets(input(), '2026-11-24T15:30');
    assert.deepEqual(state.changes, [], 'what the input shows is the value');
    await osSets(input(), '2026-11-25T15:30');
    assert.deepEqual(state.changes, ['2026-11-25T15:30:45.123Z'], '9 #27');
    await osSets(input(), '2026-11-25T16:00');
    assert.deepEqual(last(state.changes), '2026-11-25T16:00:00.000Z', '9 #28');
  });

  test('date and time across a DST day in a zone: the wall clock on either side', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-03-07T15:00:00.000Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone={{NEW_YORK}}
        />
      </template>
    );
    assert.dom(input()).hasValue('2026-03-07T10:00', 'EST, UTC−5');
    await osSets(input(), '2026-03-08T10:00');
    assert.deepEqual(state.changes, ['2026-03-08T14:00:00.000Z'], 'EDT, UTC−4');
    assert.dom(input()).hasValue('2026-03-08T10:00');
  });

  /* Time */

  test('time: type="time", HH:mm in and out, min and max from @minTime and @maxTime', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '09:30';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @showTimeSelectOnly={{true}}
          @minTime="06:00"
          @maxTime="22:00"
        />
      </template>
    );
    assert
      .dom(input())
      .hasAttribute('type', 'time')
      .hasValue('09:30')
      .hasAttribute('min', '06:00')
      .hasAttribute('max', '22:00')
      .hasAttribute('step', '60');
    assert.dom('.euiFormControlLayoutIcons [data-icon-type="clock"]').exists();
    assert.dom(iconButton()).hasAttribute('aria-label', 'Choose time');
    await osSets(input(), '07:15');
    assert.deepEqual(state.changes, ['07:15']);
    await osSets(input(), '05:45');
    assert.deepEqual(state.errors, [{ text: '05:45', reason: 'min' }]);
    await osSets(input(), '22:30');
    assert.deepEqual(last(state.errors), { text: '22:30', reason: 'max' });
    assert.deepEqual(state.changes, ['07:15']);
    await osSets(input(), '');
    assert.deepEqual(state.changes, ['07:15', null]);
  });

  test('time: @seconds, engines that send milliseconds, hidden seconds kept', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '09:30:20';
    await render(
      <template>
        <div data-p="seconds"><EuiDatePicker
            @value={{state.value}}
            @onChange={{state.onChange}}
            @showTimeSelectOnly={{true}}
            @seconds={{true}}
          /></div>
      </template>
    );
    const seconds = input(el('[data-p="seconds"]'));
    assert.dom(seconds).hasAttribute('step', '1').hasValue('09:30:20');
    await osSets(seconds, '09:31:05.250');
    assert.deepEqual(state.changes, ['09:31:05']);
    await osSets(seconds, '09:32');
    assert.deepEqual(
      last(state.changes),
      '09:32:00',
      'an engine leaving out :00'
    );

    const other = new State();
    other.value = '09:30:45';
    await render(
      <template>
        <EuiDatePicker
          @value={{other.value}}
          @onChange={{other.onChange}}
          @showTimeSelectOnly={{true}}
        />
      </template>
    );
    assert.dom(input()).hasValue('09:30');
    await osSets(input(), '09:30');
    assert.deepEqual(other.changes, [], 'the minute shown is the value');
    await osSets(input(), '10:00');
    assert.deepEqual(other.changes, ['10:00']);
  });

  test('time with @native={{true}} and @excludeTimes: an excluded time is an input error', async function (assert) {
    const state = new State();
    state.value = '09:30';
    await render(
      <template>
        <EuiDatePicker
          @native={{true}}
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @showTimeSelectOnly={{true}}
          @excludeTimes={{array "12:00"}}
        />
      </template>
    );
    await osSets(input(), '12:00');
    assert.deepEqual(state.errors, [{ text: '12:00', reason: 'disabled' }]);
    assert.deepEqual(state.changes, []);
  });

  test('a moment for a time and for an instant on the native path', async function (assert) {
    stubPointer(true);
    const at = moment.utc('2026-11-24T21:30:00Z');
    await render(
      <template>
        <div data-p="time"><EuiDatePicker
            @value={{at}}
            @showTimeSelectOnly={{true}}
            @timeZone="utc"
          /></div>
        <div data-p="instant"><EuiDatePicker
            @value={{at}}
            @showTimeSelect={{true}}
            @timeZone="America/Monterrey"
          /></div>
      </template>
    );
    assert.dom(input(el('[data-p="time"]'))).hasValue('21:30');
    assert.dom(input(el('[data-p="instant"]'))).hasValue('2026-11-24T15:30');
  });

  test('re-rendering emits nothing', async function (assert) {
    stubPointer(true);
    const state = new State();
    state.value = '2026-11-24T15:30:45.000Z';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelect={{true}}
          @timeZone="utc"
        />
      </template>
    );
    await rerender();
    await triggerEvent(input(), 'focusout');
    assert.deepEqual(state.changes, []);
  });
});
