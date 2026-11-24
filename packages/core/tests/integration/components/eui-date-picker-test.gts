import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  blur,
  click,
  fillIn,
  focus,
  render,
  rerender,
  settled,
  triggerKeyEvent
} from '@ember/test-helpers';
import { registerWarnHandler } from '@ember/debug';
import { array } from '@ember/helper';
import { tracked } from '@glimmer/tracking';

import moment from 'moment';

import EuiDatePicker from '#src/components/eui-date-picker.gts';
import EuiFormRow from '#src/components/eui-form-row.gts';
import { resolveTwoDigitYear } from '#src/utils/date/parse.ts';
import { todayIn } from '#src/utils/date/zone.ts';

import type { EuiDatePickerInputError } from '#src/components/eui-date-picker.gts';

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
const heading = () =>
  el('[data-popover-panel] .react-datepicker h2').textContent!.trim();

async function press(target: Element, key: string, options = {}) {
  await triggerKeyEvent(target, 'keydown', key, options);
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
  clear = () => this.onChange(null);
}

module('Integration | Component | eui-date-picker', function (hooks) {
  setupRenderingTest(hooks);

  hooks.afterEach(function () {
    warnings = null;
  });

  test('renders upstream markup: wrapper, layout, calendar icon, popover anchor, input', async function (assert) {
    await render(
      <template>
        <EuiDatePicker
          @value="2026-11-24"
          @locale="en-US"
          data-test-subj="picker"
          class="custom"
        />
      </template>
    );
    assert.dom('.euiDatePicker > .euiFormControlLayout').exists();
    assert
      .dom(
        '.euiFormControlLayout__childrenWrapper .euiPopover .react-datepicker__input-container > input'
      )
      .exists('the input is the popover anchor (upstream)');
    assert
      .dom('.euiFormControlLayoutIcons [data-icon-type="calendar"]')
      .exists('the calendar icon');
    const field = input();
    assert
      .dom(field)
      .hasClass('euiFieldText')
      .hasClass('custom', '...attributes reach the input')
      .hasAttribute('data-test-subj', 'picker')
      .hasAttribute('type', 'text')
      .hasAttribute('autocomplete', 'off')
      .hasAttribute('aria-haspopup', 'dialog')
      .hasAttribute('aria-expanded', 'false')
      .doesNotHaveAttribute('aria-controls')
      .hasValue('11/24/2026', 'the display format of en-US');
    assert.strictEqual(panel(), null, 'closed until focused');
    assert
      .dom('.euiFormControlLayout')
      .hasAttribute('class', /euiFormControlLayout/);
  });

  test('opens on focus and on click; the panel is a dialog that is not modal', async function (assert) {
    await render(
      <template>
        <EuiDatePicker
          @value="2026-11-24"
          @locale="en-US"
          @firstDayOfWeek={{0}}
          aria-label="Due date"
        />
      </template>
    );
    await focus(input());
    const opened = panel();
    assert.ok(opened, 'focus opens the popover');
    assert.dom(input()).isFocused('focus stays in the input');
    assert
      .dom(opened)
      .hasAttribute('role', 'dialog')
      .doesNotHaveAttribute('aria-modal')
      .hasAttribute('aria-label', 'Choose date, Due date')
      .hasAttribute('tabindex', '-1');
    assert
      .dom(input())
      .hasAttribute('aria-expanded', 'true')
      .hasAttribute('aria-controls', opened!.id);
    assert
      .dom('td[data-date="2026-11-24"]', opened!)
      .hasClass('react-datepicker__day--selected');
    assert.strictEqual(heading(), 'November 2026');

    await press(input(), 'Escape');
    assert.strictEqual(panel(), null, 'Escape closes');
    assert.dom(input()).isFocused();
    await click(input());
    assert.ok(panel(), 'a click on the focused input opens again');
  });

  test('picking a day emits YYYY-MM-DD, closes and returns focus to the input; the text follows', async function (assert) {
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
    await click(day('2026-11-03'));
    assert.deepEqual(state.changes, ['2026-11-03']);
    assert.strictEqual(panel(), null, 'closed after the pick');
    assert.dom(input()).isFocused('focus is back in the input');
    assert.dom(input()).hasValue('11/03/2026');

    await click(input());
    assert.ok(panel(), 'opens again on click');
    await click(day('2026-11-03'));
    assert.deepEqual(
      state.changes,
      ['2026-11-03'],
      'the same day emits nothing'
    );
    assert.strictEqual(panel(), null, 'but closes');
  });

  test('@shouldCloseOnSelect={{false}} keeps the popover open after a pick', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @openToDate="2026-11-01"
          @shouldCloseOnSelect={{false}}
          @locale="en-US"
        />
      </template>
    );
    await click(input());
    await click(day('2026-11-10'));
    assert.deepEqual(state.changes, ['2026-11-10']);
    assert.ok(panel(), 'still open');
    assert.dom(input()).hasValue('11/10/2026');
  });

  test('typed text: nothing while typing, commit on Enter, rewritten in the display format (9 #4, #5, #7)', async function (assert) {
    const state = new State();
    await render(
      <template>
        <div data-p="dmy"><EuiDatePicker
            @value={{state.value}}
            @onChange={{state.onChange}}
            @dateOrder="dmy"
            @locale="en-US"
          /></div>
      </template>
    );
    const field = input();
    await fillIn(field, '3/4');
    await fillIn(field, '3/4/2026');
    assert.deepEqual(state.changes, [], 'nothing is emitted per keystroke');
    assert.strictEqual(
      heading(),
      'April 2026',
      'complete text previews its month'
    );

    assert
      .dom(
        '[data-popover-panel] td[data-date="2026-04-03"] > button',
        document.body
      )
      .hasAttribute('tabindex', '0', 'the typed day holds the tab stop');
    assert
      .dom(
        '[data-popover-panel] .react-datepicker__day--selected',
        document.body
      )
      .doesNotExist('a preview selects nothing');

    await press(field, 'Enter');
    assert.deepEqual(state.changes, ['2026-04-03'], 'dmy: 3 April');
    assert.dom(field).hasValue('03/04/2026', 'rewritten');
    assert.strictEqual(panel(), null, 'Enter closes');

    const year = Number(todayIn('local', Date.now()).slice(0, 4));
    const yy = String(year).slice(2);
    await fillIn(field, `24/11/${yy}`);
    await press(field, 'Enter');
    assert.strictEqual(
      state.value,
      `${resolveTwoDigitYear(Number(yy), year)}-11-24`,
      'a two-digit year reads in this century'
    );
    assert.dom(field).hasValue(`24/11/${year}`, 'shown with four digits');

    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @dateOrder="mdy"
        />
      </template>
    );
    await fillIn(input(), '3/4/2026');
    await press(input(), 'Enter');
    assert.strictEqual(state.value, '2026-03-04', 'mdy: 4 March');
    assert.dom(input()).hasValue('03/04/2026');

    await fillIn(input(), '2026-12-01');
    await press(input(), 'Enter');
    assert.strictEqual(state.value, '2026-12-01', 'ISO is always accepted');
    assert.dom(input()).hasValue('12/01/2026');
  });

  test('blur commits; Tab commits and moves on (DESIGN 7.2)', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @dateOrder="ymd"
        />
        <button type="button" data-next>next</button>
      </template>
    );
    await fillIn(input(), '2026-11-24');
    await blur(input());
    assert.deepEqual(state.changes, ['2026-11-24'], 'blur commits');
    assert.strictEqual(panel(), null, 'and closes');
    assert.dom(input()).hasValue('2026-11-24');

    await fillIn(input(), '2026/11/25');
    await focus('[data-next]');
    assert.deepEqual(
      state.changes,
      ['2026-11-24', '2026-11-25'],
      'leaving commits'
    );
    assert.dom(input()).hasValue('2026-11-25', 'rewritten');
  });

  test('unreadable text: an input error, the text stays, invalid, no @onChange (9 #6, #8)', async function (assert) {
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @dateOrder="dmy"
        />
      </template>
    );
    for (const text of [
      '13/13/2026',
      '31/02/2026',
      '24/11/099',
      '24/11/10000'
    ]) {
      await fillIn(input(), text);
      await press(input(), 'Enter');
      assert.dom(input()).hasValue(text, `${text}: stays`);
      assert.dom(input()).hasAttribute('aria-invalid', 'true');
      assert.false(input().validity.valid, 'marked invalid for forms');
      assert
        .dom('.euiFormControlLayoutIcons [data-icon-type="warning"]')
        .exists('the invalid icon');
    }
    assert.deepEqual(state.changes, [], 'never emitted');
    assert.deepEqual(
      state.errors.map((e) => e.reason),
      ['unreadable', 'unreadable', 'unreadable', 'unreadable']
    );
    assert.strictEqual(state.errors[0]!.text, '13/13/2026');

    await fillIn(input(), '24/11');
    await blur(input());
    assert.dom(input()).hasValue('24/11', 'partial text stays after blur');
    assert.dom(input()).hasAttribute('aria-invalid', 'true');
    assert.deepEqual(state.errors[state.errors.length - 1], {
      text: '24/11',
      reason: 'unreadable'
    });
    assert.strictEqual(state.value, '2026-11-24', 'the value is unchanged');

    await fillIn(input(), '25/11/2026');
    assert
      .dom(input())
      .doesNotHaveAttribute('aria-invalid', 'typing again clears the error');
    await press(input(), 'Enter');
    assert.deepEqual(state.changes, ['2026-11-25']);
    assert.dom(input()).hasValue('25/11/2026');
  });

  test("Escape: closes when open; when closed, restores the value's text without an error (9 #9)", async function (assert) {
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @dateOrder="dmy"
        />
      </template>
    );
    await fillIn(input(), '24/11');
    assert.ok(panel(), 'typing opens');
    await press(input(), 'Escape');
    assert.strictEqual(panel(), null, 'the first Escape closes');
    assert.dom(input()).hasValue('24/11', 'the text stays');
    await press(input(), 'Escape');
    assert.dom(input()).hasValue('24/11/2026', 'the second restores');
    assert.dom(input()).doesNotHaveAttribute('aria-invalid');

    await fillIn(input(), 'nope');
    await press(input(), 'Enter');
    assert.dom(input()).hasAttribute('aria-invalid', 'true');
    await press(input(), 'Escape');
    assert
      .dom(input())
      .hasValue('24/11/2026', 'Escape restores after an error');
    assert.dom(input()).doesNotHaveAttribute('aria-invalid');
    assert.deepEqual(state.changes, []);
  });

  test('emptied text commits null (9 #10); empty text over no value emits nothing', async function (assert) {
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @dateOrder="dmy"
        />
      </template>
    );
    await fillIn(input(), '');
    await blur(input());
    assert.deepEqual(state.changes, [null]);
    assert.dom(input()).hasValue('');
    await fillIn(input(), '   ');
    await press(input(), 'Enter');
    assert.deepEqual(state.changes, [null], 'nothing more');
  });

  test('typed days outside the limits or disabled: min, max, disabled (9 #11, #12)', async function (assert) {
    const state = new State();
    const weekdays = (date: string) =>
      ![0, 6].includes(new Date(`${date}T00:00:00Z`).getUTCDay());
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @dateOrder="ymd"
          @minDate="2026-11-02"
          @maxDate="2026-11-27"
          @excludeDates={{array "2026-11-10"}}
          @filterDate={{weekdays}}
        />
      </template>
    );
    for (const text of [
      '2026-11-01',
      '2026-11-28',
      '2026-11-10',
      '2026-11-14'
    ]) {
      await fillIn(input(), text);
      await press(input(), 'Enter');
    }
    assert.deepEqual(
      state.errors.map((e) => e.reason),
      ['min', 'max', 'disabled', 'disabled']
    );
    assert.deepEqual(state.changes, []);
    await fillIn(input(), '2026-11-13');
    await press(input(), 'Enter');
    assert.deepEqual(state.changes, ['2026-11-13']);
  });

  test('a click on a disabled day does nothing (9 #13)', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @openToDate="2026-11-15"
          @minDate="2026-11-10"
        />
      </template>
    );
    await click(input());
    await click(day('2026-11-05'));
    assert.deepEqual(state.changes, []);
    assert.ok(panel(), 'still open');
  });

  test('a pick while text is typed drops the text, also an error (a blur into the calendar commits nothing)', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onInputError={{state.onInputError}}
          @dateOrder="dmy"
          @openToDate="2026-11-01"
        />
      </template>
    );
    await fillIn(input(), '24/1');
    await click(day('2026-11-05'));
    assert.deepEqual(
      state.errors,
      [],
      'moving into the calendar is not a blur'
    );
    assert.deepEqual(state.changes, ['2026-11-05']);
    assert.dom(input()).hasValue('05/11/2026');
  });

  test('@onClear: the clear button while there is a value; not when disabled or read-only (upstream onClear)', async function (assert) {
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onClear={{state.clear}}
        />
      </template>
    );
    assert.dom('[aria-label="Clear input"]').exists();
    await click('[aria-label="Clear input"]');
    assert.deepEqual(state.changes, [null]);
    assert
      .dom('[aria-label="Clear input"]')
      .doesNotExist('no value, no button');

    await render(
      <template>
        <EuiDatePicker
          @value="2026-11-24"
          @onClear={{state.clear}}
          @disabled={{true}}
        />
        <EuiDatePicker
          @value="2026-11-24"
          @onClear={{state.clear}}
          @readOnly={{true}}
        />
      </template>
    );
    assert.dom('[aria-label="Clear input"]').doesNotExist();
  });

  test('@disabled and @readOnly: nothing opens, no clear button; read-only text stays selectable (9 #39, #40)', async function (assert) {
    await render(
      <template>
        <div data-p="disabled"><EuiDatePicker
            @value="2026-11-24"
            @disabled={{true}}
          /></div>
        <div data-p="readonly"><EuiDatePicker
            @value="2026-11-24"
            @readOnly={{true}}
          /></div>
      </template>
    );
    const disabled = input(el('[data-p="disabled"]'));
    const readOnly = input(el('[data-p="readonly"]'));
    assert.dom(disabled).isDisabled();
    assert
      .dom('[data-p="disabled"] .euiFormControlLayout')
      .hasClass('euiFormControlLayout-isDisabled');
    assert.dom(readOnly).hasAttribute('readonly');
    assert
      .dom('[data-p="readonly"] .euiFormControlLayout')
      .hasClass('euiFormControlLayout-readOnly');
    await click(readOnly);
    assert.dom(readOnly).isFocused();
    assert.strictEqual(panel(), null, 'read-only does not open');
    await press(readOnly, 'ArrowDown');
    assert.strictEqual(panel(), null, 'nor by key');
    readOnly.setSelectionRange(0, 3);
    assert.strictEqual(readOnly.selectionEnd, 3, 'its text can be selected');
  });

  test('states: compressed, fullWidth, isInvalid, isLoading, placeholder, showIcon, iconType', async function (assert) {
    await render(
      <template>
        <div data-p="a"><EuiDatePicker
            @compressed={{true}}
            @fullWidth={{true}}
            @isInvalid={{true}}
            @isLoading={{true}}
            @placeholder="Pick one"
          /></div>
        <div data-p="b"><EuiDatePicker
            @showIcon={{false}}
            @dateOrder="dmy"
          /></div>
        <div data-p="c"><EuiDatePicker
            @iconType="clock"
            @dateOrder="mdy"
          /></div>
        <div data-p="d"><EuiDatePicker @dateOrder="ymd" /></div>
      </template>
    );
    const a = input(el('[data-p="a"]'));
    assert.dom(a).hasAttribute('placeholder', 'Pick one');
    assert.dom(a).hasAttribute('aria-invalid', 'true');
    assert.ok(
      el('[data-p="a"]').innerHTML.includes('-compressed'),
      'compressed classes (upstream "compressed")'
    );
    assert.strictEqual(
      getComputedStyle(el('[data-p="a"] .euiFormControlLayout')).blockSize,
      '32px'
    );
    assert
      .dom('[data-p="a"] .euiFormControlLayoutIcons .euiBorealisLoadingSpinner')
      .exists();
    assert
      .dom('[data-p="a"] .euiFormControlLayoutIcons [data-icon-type="warning"]')
      .exists();
    assert.strictEqual(
      getComputedStyle(el('[data-p="a"] .euiFormControlLayout')).maxInlineSize,
      '100%',
      'full width'
    );
    assert.dom('[data-p="b"] [data-icon-type="calendar"]').doesNotExist();
    assert.dom('[data-p="c"] [data-icon-type="clock"]').exists();
    assert
      .dom(input(el('[data-p="b"]')))
      .hasAttribute('placeholder', 'DD/MM/YYYY');
    assert
      .dom(input(el('[data-p="c"]')))
      .hasAttribute('placeholder', 'MM/DD/YYYY');
    assert
      .dom(input(el('[data-p="d"]')))
      .hasAttribute('placeholder', 'YYYY-MM-DD');
  });

  test('prepend and append blocks, with the class and the input id; controlOnly drops the layout (upstream append/prepend)', async function (assert) {
    await render(
      <template>
        <div data-p="group"><EuiDatePicker @id="due">
            <:prepend as |className inputId|><label
                class={{className}}
                for={{inputId}}
              >world</label></:prepend>
            <:append as |className|><span
                class={{className}}
              >hello</span></:append>
          </EuiDatePicker></div>
        <div data-p="only"><EuiDatePicker @controlOnly={{true}}>
            <:prepend>world</:prepend>
            <:append>hello</:append>
          </EuiDatePicker></div>
      </template>
    );
    assert
      .dom('[data-p="group"] .euiFormControlLayout__append')
      .hasText('hello');
    assert
      .dom('[data-p="group"] .euiFormControlLayout__prepend')
      .hasText('world');
    assert
      .dom('[data-p="group"] .euiFormControlLayout')
      .hasClass('euiFormControlLayout--group');
    assert.dom('[data-p="group"] label').hasAttribute('for', 'due');
    assert.dom(input(el('[data-p="group"]'))).hasAttribute('id', 'due');
    assert.strictEqual(
      getComputedStyle(el('[data-p="group"] .euiPopover')).blockSize,
      getComputedStyle(
        el('[data-p="group"] .euiFormControlLayout__childrenWrapper')
      ).blockSize,
      'upstream inGroup: the anchor fills the group'
    );

    assert.dom('[data-p="only"] .euiFormControlLayout').doesNotExist();
    assert
      .dom('[data-p="only"] .euiDatePicker')
      .exists({ count: 1 }, 'only the input');
    assert.dom('[data-p="only"] .euiFormControlLayout__append').doesNotExist();
    assert.dom('[data-p="only"] .euiFormControlLayout__prepend').doesNotExist();
    await focus(input(el('[data-p="only"]')));
    assert.ok(panel(), 'the control still opens its calendar');
  });

  test('in an EuiFormRow: the label names the input and the dialog', async function (assert) {
    await render(
      <template>
        <EuiFormRow @label="Due date" @id="due">
          <EuiDatePicker @id="due" />
        </EuiFormRow>
      </template>
    );
    assert.dom(input()).hasAttribute('id', 'due');
    await focus(input());
    assert.dom(panel()).hasAttribute('aria-label', 'Choose date, Due date');
  });

  test('ArrowDown opens and moves focus to the grid; Escape there closes and returns focus', async function (assert) {
    await render(
      <template><EuiDatePicker @value="2026-11-24" @locale="en-US" /></template>
    );
    await focus(input());
    await press(input(), 'Escape');
    assert.strictEqual(panel(), null);
    await press(input(), 'ArrowDown');
    assert.ok(panel(), 'ArrowDown opens');
    assert.dom(day('2026-11-24')).isFocused('focus is on the selected day');
    await press(day('2026-11-24'), 'ArrowRight');
    assert.dom(day('2026-11-25')).isFocused('the grid takes its keys');
    await press(document.activeElement!, 'Escape');
    await settled();
    assert.strictEqual(panel(), null, 'Escape closes');
    assert.dom(input()).isFocused('focus is back in the input');
    assert
      .dom(input())
      .hasAttribute('aria-expanded', 'false', 'and it did not reopen');
  });

  test('an unreadable @value shows its raw text, invalid, opens on today (9 #1)', async function (assert) {
    warnings = [];
    const today = todayIn('local', Date.now());
    await render(
      <template><EuiDatePicker @value="2026-02-31" @locale="en-US" /></template>
    );
    assert.dom(input()).hasValue('2026-02-31');
    assert.dom(input()).hasAttribute('aria-invalid', 'true');
    await focus(input());
    assert
      .dom(`[data-popover-panel] td[data-date="${today}"]`, document.body)
      .exists();
    assert
      .dom(
        '[data-popover-panel] .react-datepicker__day--selected',
        document.body
      )
      .doesNotExist();
    assert.true(
      warnings.some((w) => w.includes('"2026-02-31"')),
      warnings.join(' | ')
    );
  });

  test('@value changed from outside: text and calendar follow; text being typed is kept (9 #29)', async function (assert) {
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @dateOrder="dmy"
          @locale="en-GB"
        />
      </template>
    );
    state.value = '2026-12-25';
    await rerender();
    assert.dom(input()).hasValue('25/12/2026');
    await focus(input());
    assert.strictEqual(heading(), 'December 2026');
    state.value = '2027-01-02';
    await rerender();
    assert.strictEqual(heading(), 'January 2027', 'the open calendar follows');
    await fillIn(input(), '1/');
    state.value = '2027-03-04';
    await rerender();
    assert
      .dom(input())
      .hasValue('1/', 'typing is not overwritten while focused');
    await press(input(), 'Escape');
    await press(input(), 'Escape');
    assert.dom(input()).hasValue('04/03/2027', 'Escape shows the new value');
  });

  test('without @onChange nothing throws and the value stays (9 #30)', async function (assert) {
    await render(
      <template>
        <EuiDatePicker @value="2026-11-24" @dateOrder="dmy" />
      </template>
    );
    await click(input());
    await click(day('2026-11-02'));
    assert.dom(input()).hasValue('24/11/2026');
    await fillIn(input(), '01/11/2026');
    await press(input(), 'Enter');
    assert.dom(input()).hasValue('24/11/2026');
  });

  test('two pickers: opening the second closes the first (9 #53)', async function (assert) {
    await render(
      <template>
        <div data-p="1"><EuiDatePicker /></div>
        <div data-p="2"><EuiDatePicker /></div>
      </template>
    );
    await focus(input(el('[data-p="1"]')));
    assert.dom('[data-popover-panel]', document.body).exists({ count: 1 });
    await focus(input(el('[data-p="2"]')));
    assert.dom('[data-popover-panel]', document.body).exists({ count: 1 });
    assert
      .dom(input(el('[data-p="1"]')))
      .hasAttribute('aria-expanded', 'false');
    assert.dom(input(el('[data-p="2"]'))).hasAttribute('aria-expanded', 'true');
  });

  test('@popoverPlacement, @popoverClass and @calendarClass (upstream custom classes)', async function (assert) {
    await render(
      <template>
        <EuiDatePicker
          @popoverPlacement="upRight"
          @popoverClass="my-popover"
          @calendarClass="my-calendar"
          @value="2026-11-24"
        />
      </template>
    );
    await focus(input());
    assert.dom(panel()).hasClass('my-popover');
    assert
      .dom('[data-popover-panel] .react-datepicker', document.body)
      .hasClass('my-calendar');
    assert.dom(panel()).hasAttribute('data-popover-open', 'true');
  });

  test('@inputRef gets the input', async function (assert) {
    let ref: HTMLInputElement | null = null;
    const setRef = (element: HTMLInputElement | null) => (ref = element);
    await render(<template><EuiDatePicker @inputRef={{setRef}} /></template>);
    assert.strictEqual(ref, input());
  });

  test('a moment or a Date as @value and as date arguments; @onChange emits strings (DESIGN 18)', async function (assert) {
    warnings = [];
    const state = new State();
    const value = moment.utc('2026-11-24T03:00:00Z');
    const before = value.toISOString();
    const min = new Date(Date.UTC(2026, 10, 2, 12));
    const max = moment.utc('2026-11-27T12:00:00Z');
    const excluded = [
      moment.utc('2026-11-10T12:00:00Z'),
      new Date(Date.UTC(2026, 10, 11, 12))
    ];
    const onChange = (next: string | null) => state.changes.push(next);
    await render(
      <template>
        <EuiDatePicker
          @value={{value}}
          @onChange={{onChange}}
          @timeZone="utc"
          @minDate={{min}}
          @maxDate={{max}}
          @excludeDates={{excluded}}
          @dateOrder="ymd"
        />
      </template>
    );
    assert.dom(input()).hasValue('2026-11-24', "the moment's day in the zone");
    assert.dom(input()).doesNotHaveAttribute('aria-invalid');
    await click(input());
    assert
      .dom(day('2026-11-24').parentElement!)
      .hasClass('react-datepicker__day--selected');
    assert
      .dom(day('2026-11-01').parentElement!)
      .hasClass('react-datepicker__day--disabled', 'before @minDate (a Date)');
    assert
      .dom(day('2026-11-28').parentElement!)
      .hasClass('react-datepicker__day--disabled', 'after @maxDate (a moment)');
    assert
      .dom(day('2026-11-10').parentElement!)
      .hasClass('react-datepicker__day--disabled', 'excluded moment');
    assert
      .dom(day('2026-11-11').parentElement!)
      .hasClass('react-datepicker__day--disabled', 'excluded Date');
    await click(day('2026-11-12'));
    assert.deepEqual(state.changes, ['2026-11-12'], 'a string, never a moment');
    assert.strictEqual(
      value.toISOString(),
      before,
      'the moment is not mutated'
    );
    assert.strictEqual(value.utcOffset(), 0);
    // decision 19: a valid Date or moment is read silently
    assert.deepEqual(warnings, [], 'no notice: ' + warnings.join(' | '));

    const tokyo = moment.utc('2026-11-24T20:00:00Z');
    await render(
      <template>
        <EuiDatePicker
          @value={{tokyo}}
          @timeZone="Asia/Tokyo"
          @dateOrder="ymd"
        />
      </template>
    );
    assert
      .dom(input())
      .hasValue('2026-11-25', 'the day in @timeZone, not in UTC');

    const local = new Date(2026, 10, 24, 23, 30);
    const openTo = new Date(2026, 0, 15);
    await render(
      <template>
        <EuiDatePicker @value={{local}} @dateOrder="ymd" />
        <div data-p="open"><EuiDatePicker
            @openToDate={{openTo}}
            @locale="en-US"
          /></div>
      </template>
    );
    assert.dom(input()).hasValue('2026-11-24', 'a local Date: its local day');
    await focus(input(el('[data-p="open"]')));
    assert.strictEqual(heading(), 'January 2026', '@openToDate as a Date');
  });

  test('an invalid moment or Date: no value, invalid, a development warning (DESIGN 18)', async function (assert) {
    warnings = [];
    const bad = moment.invalid();
    const badDate = new Date(NaN);
    await render(
      <template>
        <div data-p="m"><EuiDatePicker @value={{bad}} /></div>
        <div data-p="d"><EuiDatePicker
            @value={{badDate}}
            @minDate={{badDate}}
          /></div>
      </template>
    );
    assert.dom(input(el('[data-p="m"]'))).hasValue('', 'treated as no value');
    assert.dom(input(el('[data-p="m"]'))).hasAttribute('aria-invalid', 'true');
    assert.dom(input(el('[data-p="d"]'))).hasValue('');
    await focus(input(el('[data-p="m"]')));
    assert
      .dom(
        '[data-popover-panel] .react-datepicker__day--selected',
        document.body
      )
      .doesNotExist();
    assert.strictEqual(
      warnings.filter((w) => w.includes('@value is an invalid Date or moment'))
        .length,
      2,
      warnings.join(' | ')
    );
    assert.true(
      warnings.some((w) =>
        w.includes('@minDate is an invalid Date or moment; it is ignored')
      ),
      warnings.join(' | ')
    );
  });
});
