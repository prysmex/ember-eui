import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  clearRender,
  click,
  fillIn,
  focus,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';

import { tabbable } from 'tabbable';

import EuiButton from '#src/components/eui-button.gts';
import EuiDatePicker from '#src/components/eui-date-picker.gts';
import EuiFlyout from '#src/components/eui-flyout.gts';
import EuiModal from '#src/components/eui-modal.gts';
import EuiPopover from '#src/components/eui-popover.gts';

function el<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

const input = () => el<HTMLInputElement>('input.euiDatePicker');
const panel = () => document.querySelector<HTMLElement>('[data-popover-panel]');
const day = (date: string) =>
  el<HTMLButtonElement>(
    `[data-popover-panel] td[data-date="${date}"] > button`
  );
const active = () => document.activeElement as HTMLElement | null;
const inPanel = () => Boolean(panel()?.contains(document.activeElement));

class State {
  @tracked value: string | null = '2026-11-24';
  changes: (string | null)[] = [];
  onChange = (value: string | null) => {
    this.changes.push(value);
    this.value = value;
  };
}

/**
 * Tab as a browser does: the keydown first (the picker and focus traps may
 * take it), then, unless prevented, focus moves to the next tabbable
 * element in document order. (`tab()` from test-helpers only walks the test
 * root, not the portalled panel.)
 */
async function tab({ backwards = false } = {}) {
  const target = document.activeElement as HTMLElement;
  let prevented = false;
  const listener = (event: Event) => (prevented = event.defaultPrevented);
  document.addEventListener('keydown', listener);
  await triggerKeyEvent(target, 'keydown', 'Tab', { shiftKey: backwards });
  document.removeEventListener('keydown', listener);
  if (prevented) return;
  const stops = tabbable(document.body);
  const next = stops[stops.indexOf(target) + (backwards ? -1 : 1)];
  if (next) await focus(next);
}

/** Wait for the popover to finish closing (it keeps the panel during its animation). */
async function closed() {
  await waitUntil(() => input().getAttribute('aria-expanded') === 'false', {
    timeout: 2000
  });
  await settled();
}

module(
  'Integration | Component | eui-date-picker | popover focus',
  function (hooks) {
    setupRenderingTest(hooks);

    test('Tab moves through the calendar; after the last control, and before the first, it closes and returns to the input (DESIGN 7.2)', async function (assert) {
      const state = new State();
      await render(
        <template>
          <EuiDatePicker
            @value={{state.value}}
            @onChange={{state.onChange}}
            @locale="en-US"
          />
        </template>
      );
      await focus(input());
      await triggerKeyEvent(input(), 'keydown', 'ArrowDown');
      assert.dom(day('2026-11-24')).isFocused();
      // the grid's day is the last control: Shift+Tab walks back
      await tab({ backwards: true });
      assert.dom(active()!).hasAttribute('aria-label', 'Year');
      await tab({ backwards: true });
      assert.dom(active()!).hasAttribute('aria-label', 'Month');
      await tab({ backwards: true });
      assert.dom(active()!).hasAttribute('aria-label', 'Next month');
      await tab({ backwards: true });
      assert.dom(active()!).hasAttribute('aria-label', 'Previous month');
      await tab({ backwards: true });
      assert.dom(input()).isFocused('before the first: back to the input');
      await closed();
      assert.strictEqual(panel(), null, 'and closed');

      await triggerKeyEvent(input(), 'keydown', 'ArrowDown');
      assert.dom(day('2026-11-24')).isFocused();
      await tab();
      assert.dom(input()).isFocused('after the last: back to the input');
      await closed();
      assert.deepEqual(state.changes, [], 'nothing chosen');
    });

    test('focus moved elsewhere by the app: the input is never trapped; from the calendar, the popover closes instead of fighting', async function (assert) {
      await render(
        <template>
          <EuiDatePicker @value="2026-11-24" @locale="en-US" />
          <button type="button" data-outside>outside</button>
        </template>
      );
      await focus(input());
      assert.ok(panel());
      // typing: focus may leave freely
      await focus('[data-outside]');
      assert.dom('[data-outside]').isFocused('the input is not trapped');
      await closed();

      await focus(input());
      await triggerKeyEvent(input(), 'keydown', 'ArrowDown');
      assert.true(inPanel());
      el<HTMLButtonElement>('[data-outside]').focus();
      await closed();
      assert.dom('[data-outside]').isFocused('focus stays where it was put');
      assert.strictEqual(panel(), null, 'the popover closed');
    });

    test('focus lost from the calendar (a press on nothing focusable) returns to the input; nothing is committed', async function (assert) {
      const state = new State();
      await render(
        <template>
          <EuiDatePicker
            @value={{state.value}}
            @onChange={{state.onChange}}
            @dateOrder="dmy"
          />
        </template>
      );
      await fillIn(input(), '01/12/2026');
      await triggerKeyEvent(input(), 'keydown', 'ArrowDown');
      assert
        .dom(day('2026-12-01'))
        .isFocused('the typed day holds the tab stop');
      (document.activeElement as HTMLElement).blur();
      await settled();
      assert.dom(input()).isFocused('focus is back in the input');
      assert.dom(input()).hasValue('01/12/2026', 'the text is kept');
      assert.deepEqual(state.changes, []);
    });

    test('a press in the panel is not a blur (Safari: buttons take no focus on click)', async function (assert) {
      const state = new State();
      await render(
        <template>
          <EuiDatePicker
            @value={{state.value}}
            @onChange={{state.onChange}}
            @dateOrder="dmy"
          />
        </template>
      );
      await fillIn(input(), '24/1');
      // what Safari does: pointerdown, then the input blurs to nothing
      await triggerEvent(day('2026-11-05'), 'pointerdown');
      input().blur();
      await settled();
      assert.ok(panel(), 'still open');
      assert.dom(input()).doesNotHaveAttribute('aria-invalid', 'not committed');
      await triggerEvent(day('2026-11-05'), 'pointerup');
      await click(day('2026-11-05'));
      assert.deepEqual(state.changes, ['2026-11-05']);
    });

    test('in a modal: the calendar works, Tab stays in modal and calendar, Escape closes the calendar only (9 #36)', async function (assert) {
      const state = new State();
      let modalClosed = 0;
      const onClose = () => modalClosed++;
      await render(
        <template>
          <EuiModal @onClose={{onClose}}>
            <button type="button" data-first>first</button>
            <EuiDatePicker
              @value={{state.value}}
              @onChange={{state.onChange}}
              @locale="en-US"
            />
            <button type="button" data-last>last</button>
          </EuiModal>
        </template>
      );
      await focus(input());
      assert.ok(panel(), 'opens in the modal');
      await triggerKeyEvent(input(), 'keydown', 'ArrowDown');
      assert
        .dom(day('2026-11-24'))
        .isFocused('the portalled calendar takes focus');
      await triggerKeyEvent(active()!, 'keydown', 'ArrowRight');
      assert.dom(day('2026-11-25')).isFocused('and keys');
      await focus(el('[aria-label="Month"]', panel()!));
      assert.true(
        inPanel(),
        'the modal does not pull focus back from the calendar'
      );

      await triggerKeyEvent(active()!, 'keydown', 'Escape');
      await closed();
      assert.strictEqual(modalClosed, 0, 'Escape closed the calendar only');
      assert.dom(input()).isFocused('focus is back in the input, in the modal');
      assert.dom('.euiModal', document.body).exists();

      await click(input());
      assert.ok(panel(), 'open again');
      await triggerKeyEvent(input(), 'keydown', 'Escape');
      await closed();
      assert.strictEqual(
        modalClosed,
        0,
        'Escape in the open input closes the calendar only'
      );

      await click(input());
      await click(day('2026-11-03'));
      await closed();
      assert.deepEqual(state.changes, ['2026-11-03'], 'a pick in the modal');
      assert.dom(input()).isFocused();
      assert.strictEqual(modalClosed, 0);

      await triggerKeyEvent(input(), 'keydown', 'Escape');
      assert.strictEqual(
        modalClosed,
        1,
        'with the calendar closed and nothing typed, Escape reaches the modal'
      );
    });

    test('in a flyout that closes on outside clicks: a click in the calendar does not close it (9 #37)', async function (assert) {
      const state = new State();
      let flyoutClosed = 0;
      const onClose = () => flyoutClosed++;
      await render(
        <template>
          <button type="button" data-outside>outside</button>
          <EuiFlyout
            @onClose={{onClose}}
            @ownFocus={{false}}
            @outsideClickCloses={{true}}
            aria-label="Flyout"
          >
            <EuiDatePicker
              @value={{state.value}}
              @onChange={{state.onChange}}
              @locale="en-US"
            />
          </EuiFlyout>
        </template>
      );
      await click(input());
      assert.ok(panel(), 'opens in the flyout');
      await click(el('[aria-label="Next month"]', panel()!));
      assert.strictEqual(
        flyoutClosed,
        0,
        'navigating does not close the flyout'
      );
      await click(day('2026-12-08'));
      assert.deepEqual(state.changes, ['2026-12-08']);
      assert.strictEqual(flyoutClosed, 0, 'a pick does not close the flyout');
      await closed();
      assert.dom(input()).isFocused();

      await triggerEvent(el('[data-outside]'), 'mousedown');
      await triggerEvent(el('[data-outside]'), 'mouseup');
      assert.strictEqual(flyoutClosed, 1, 'a real outside click still does');
    });

    test('any portalled popover opened in such a flyout: presses in its panel are inside the flyout', async function (assert) {
      class Open {
        @tracked isOpen = false;
        open = () => (this.isOpen = true);
        close = () => (this.isOpen = false);
      }
      const state = new Open();
      let flyoutClosed = 0;
      const onClose = () => flyoutClosed++;
      await render(
        <template>
          <button type="button" data-outside>outside</button>
          <EuiFlyout
            @onClose={{onClose}}
            @ownFocus={{false}}
            @outsideClickCloses={{true}}
            aria-label="Flyout"
          >
            <EuiPopover @isOpen={{state.isOpen}} @closePopover={{state.close}}>
              <:button><EuiButton
                  class="trigger"
                  {{on "click" state.open}}
                >Open</EuiButton></:button>
              <:content><button type="button" data-in-panel>in the panel</button></:content>
            </EuiPopover>
          </EuiFlyout>
        </template>
      );
      await click(el('.trigger'));
      await waitUntil(() => document.querySelector('[data-in-panel]'));
      await triggerEvent(el('[data-in-panel]'), 'mousedown');
      await triggerEvent(el('[data-in-panel]'), 'mouseup');
      assert.strictEqual(flyoutClosed, 0, 'a press in the panel');
      assert.true(state.isOpen, 'nor did the popover close');
      await triggerEvent(el('[data-outside]'), 'mousedown');
      await triggerEvent(el('[data-outside]'), 'mouseup');
      assert.strictEqual(flyoutClosed, 1, 'a press outside both');
    });

    test('destroyed while open: the panel and the trap go (9 #54)', async function (assert) {
      class Shown {
        @tracked shown = true;
      }
      const shown = new Shown();
      await render(
        <template>
          {{#if shown.shown}}
            <EuiDatePicker @value="2026-11-24" />
          {{/if}}
          <button type="button" data-outside>outside</button>
        </template>
      );
      await focus(input());
      await triggerKeyEvent(input(), 'keydown', 'ArrowDown');
      assert.true(inPanel());
      shown.shown = false;
      await settled();
      assert.strictEqual(panel(), null, 'no panel left');
      await focus('[data-outside]');
      assert.dom('[data-outside]').isFocused('no trap left holding focus');
      await clearRender();
    });
  }
);
