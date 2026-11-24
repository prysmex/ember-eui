import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, settled, triggerKeyEvent } from '@ember/test-helpers';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';

import EuiButton from '#src/components/eui-button.gts';
import EuiDatePicker from '#src/components/eui-date-picker.gts';

function el<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

const trigger = () => el<HTMLButtonElement>('button.my-trigger');
const panel = () => document.querySelector<HTMLElement>('[data-popover-panel]');
const day = (date: string) =>
  el<HTMLButtonElement>(
    `[data-popover-panel] td[data-date="${date}"] > button`
  );

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

class State {
  @tracked value: string | null = '2026-11-24';
  changes: (string | null)[] = [];
  onChange = (value: string | null) => {
    this.changes.push(value);
    this.value = value;
  };
}

module('Integration | Component | eui-date-picker | trigger', function (hooks) {
  setupRenderingTest(hooks);

  hooks.afterEach(function () {
    window.matchMedia = realMatchMedia;
  });

  test('the block replaces the text input; it yields open, isOpen and the text (upstream customInput)', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiDatePicker
          data-test-subj="picker"
          @value={{state.value}}
          @onChange={{state.onChange}}
        >
          <:trigger as |t|>
            <button
              type="button"
              class="my-trigger"
              data-open={{if t.isOpen "yes" "no"}}
              {{on "click" t.open}}
            >{{t.text}}</button>
          </:trigger>
        </EuiDatePicker>
      </template>
    );

    assert.dom('input').doesNotExist('no text input');
    assert.dom(trigger()).hasText('11/24/2026').hasAttribute('data-open', 'no');
    assert
      .dom('.euiFormControlLayoutIcons [data-icon-type="calendar"]')
      .doesNotExist('no icon');
    assert
      .dom('[data-test-subj="picker"]')
      .hasClass(
        'react-datepicker__input-container',
        'attributes go to the element around the trigger'
      );
    assert.notOk(panel());

    await click(trigger());
    assert.ok(panel(), 'open');
    assert.dom(trigger()).hasAttribute('data-open', 'yes');
    assert.strictEqual(
      document.activeElement,
      day('2026-11-24'),
      'focus moves into the calendar (upstream traps for a custom input)'
    );

    await click(day('2026-11-20'));
    assert.deepEqual(state.changes, ['2026-11-20']);
    assert.notOk(panel(), 'a pick closes');
    await settled();
    assert.strictEqual(
      document.activeElement,
      trigger(),
      'focus back to the trigger'
    );
    assert.dom(trigger()).hasText('11/20/2026');
  });

  test('keyboard: Enter on the trigger opens; arrows move, Escape closes and returns focus; Tab off the end too', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiDatePicker @value={{state.value}} @onChange={{state.onChange}}>
          <:trigger as |t|>
            <EuiButton
              class="my-trigger"
              {{on "click" t.open}}
            >{{t.text}}</EuiButton>
          </:trigger>
        </EuiDatePicker>
      </template>
    );

    trigger().focus();
    await click(trigger());
    await triggerKeyEvent(document.activeElement!, 'keydown', 'ArrowRight');
    assert.strictEqual(document.activeElement, day('2026-11-25'));
    await triggerKeyEvent(document.activeElement!, 'keydown', 'Escape');

    assert.notOk(panel(), 'Escape closes');
    assert.strictEqual(
      document.activeElement,
      trigger(),
      'focus back to the trigger'
    );
    assert.deepEqual(state.changes, [], 'nothing chosen');

    await click(trigger());
    // Enter on a day: the button's native activation
    await click(document.activeElement!);
    assert.deepEqual(
      state.changes,
      [],
      'the selected day again changes nothing'
    );
    assert.notOk(panel());
    await settled();
    assert.strictEqual(document.activeElement, trigger());

    await click(trigger());
    // the grid's tab stop is the panel's last
    const lastDay = el<HTMLButtonElement>(
      '[data-popover-panel] td button[tabindex="0"]'
    );
    lastDay.focus();
    await triggerKeyEvent(lastDay, 'keydown', 'Tab');

    assert.notOk(panel(), 'Tab after the last control closes');
    assert.strictEqual(document.activeElement, trigger());
  });

  test('a second open while open keeps it open; a press outside closes', async function (assert) {
    const state = new State();
    await render(
      <template>
        <button type="button" class="outside">outside</button>
        <EuiDatePicker @value={{state.value}} @onChange={{state.onChange}}>
          <:trigger as |t|>
            <button
              type="button"
              class="my-trigger"
              {{on "click" t.open}}
            >{{t.text}}</button>
          </:trigger>
        </EuiDatePicker>
      </template>
    );
    await click(trigger());
    await click(trigger());
    assert.ok(panel(), 'still open');
    await click('.outside');
    assert.notOk(panel(), 'closed by a press outside');
  });

  test('disabled and read-only: open does nothing', async function (assert) {
    await render(
      <template>
        <div data-p="disabled">
          <EuiDatePicker @value="2026-11-24" @disabled={{true}}>
            <:trigger as |t|><button
                type="button"
                class="my-trigger"
                {{on "click" t.open}}
              >{{t.text}}</button></:trigger>
          </EuiDatePicker>
        </div>
        <div data-p="readonly">
          <EuiDatePicker @value="2026-11-24" @readOnly={{true}}>
            <:trigger as |t|><button
                type="button"
                class="read-only-trigger"
                {{on "click" t.open}}
              >{{t.text}}</button></:trigger>
          </EuiDatePicker>
        </div>
      </template>
    );
    await click(trigger());
    assert.notOk(panel());
    await click('.read-only-trigger');
    assert.notOk(panel());
  });

  test('always the calendar: a coarse pointer, and @native={{true}}, keep the trigger (DESIGN 6.2, rule 1)', async function (assert) {
    stubPointer(true);
    await render(
      <template>
        <div data-p="auto">
          <EuiDatePicker @value="2026-11-24">
            <:trigger as |t|><button
                type="button"
                class="my-trigger"
                {{on "click" t.open}}
              >{{t.text}}</button></:trigger>
          </EuiDatePicker>
        </div>
        <div data-p="forced">
          <EuiDatePicker
            @value="2026-11-24"
            @native={{true}}
            @controlOnly={{true}}
          >
            <:trigger as |t|><button
                type="button"
                class="forced-trigger"
                {{on "click" t.open}}
              >{{t.text}}</button></:trigger>
          </EuiDatePicker>
        </div>
        <div data-p="plain"><EuiDatePicker @value="2026-11-24" /></div>
      </template>
    );
    assert
      .dom('[data-p="plain"] input')
      .hasAttribute(
        'type',
        'date',
        'the stub works: a plain picker goes native'
      );
    assert.dom('[data-p="auto"] input').doesNotExist();
    assert.dom('[data-p="forced"] input').doesNotExist();
    await click('.forced-trigger');
    assert.ok(panel(), 'the calendar opens');
  });

  test('time only: the trigger opens the time list, focus on it', async function (assert) {
    const state = new State();
    state.value = '09:30';
    await render(
      <template>
        <EuiDatePicker
          @value={{state.value}}
          @onChange={{state.onChange}}
          @showTimeSelectOnly={{true}}
          @hour12={{false}}
        >
          <:trigger as |t|><button
              type="button"
              class="my-trigger"
              {{on "click" t.open}}
            >{{t.text}}</button></:trigger>
        </EuiDatePicker>
      </template>
    );
    assert.dom(trigger()).hasText('09:30');
    await click(trigger());

    assert.dom(document.activeElement).hasClass('react-datepicker__time-list');
  });
});
