/**
 * Two fixes found by real use of the docs (2026-11-25):
 * - the calendar header's month and year selects cut "2026" and long
 *   month names in the popover's narrow header;
 * - opening the calendar from a custom trigger scrolled the page down to
 *   the not-yet-placed popover and back: every focus move of the picker
 *   passes `preventScroll`.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerKeyEvent } from '@ember/test-helpers';
import { on } from '@ember/modifier';

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

const panel = () => document.querySelector<HTMLElement>('[data-popover-panel]');

/** The selected option's text width at the select's own font. */
function textWidth(select: HTMLSelectElement): number {
  const style = getComputedStyle(select);
  const context = document.createElement('canvas').getContext('2d')!;
  context.font = `${style.fontWeight} ${style.fontSize} ${style.fontFamily}`;
  return context.measureText(select.options[select.selectedIndex]?.text ?? '')
    .width;
}

/** The width the select's text has between its padding (its chevron is in the end padding). */
function textRoom(select: HTMLSelectElement): number {
  const style = getComputedStyle(select);
  return (
    select.clientWidth -
    parseFloat(style.paddingLeft) -
    parseFloat(style.paddingRight)
  );
}

module(
  'Integration | Component | eui-date-picker | header and focus',
  function (hooks) {
    setupRenderingTest(hooks);

    const realFocus = HTMLElement.prototype.focus;
    let calls: { element: HTMLElement; options?: FocusOptions }[] = [];

    hooks.beforeEach(function () {
      calls = [];
      HTMLElement.prototype.focus = function (
        this: HTMLElement,
        options?: FocusOptions
      ) {
        calls.push({ element: this, options });
        return realFocus.call(this, options);
      };
    });

    hooks.afterEach(function () {
      HTMLElement.prototype.focus = realFocus;
    });

    for (const [locale, value] of [
      ['en-US', '2026-09-15'],
      ['es', '2026-09-15'],
      ['en-US', '2026-11-24']
    ] as const) {
      test(`the month and year selects show their text whole in the popover (${locale}, ${value})`, async function (assert) {
        await render(
          <template>
            <EuiDatePicker @value={{value}} @locale={{locale}} />
          </template>
        );
        await click(el('input.euiDatePicker'));
        const selects = [
          ...panel()!.querySelectorAll<HTMLSelectElement>(
            '.react-datepicker__header__dropdown select'
          )
        ];
        assert.strictEqual(selects.length, 2, 'month and year');
        for (const select of selects) {
          const need = textWidth(select);
          const room = textRoom(select);
          assert.true(
            need <= room + 0.5,
            `${select.getAttribute('aria-label')} "${select.options[select.selectedIndex]?.text}": ${need.toFixed(1)}px of text, ${room.toFixed(1)}px of room`
          );
        }
      });
    }

    test('opening from a trigger, moving with a key and closing never scroll the page', async function (assert) {
      await render(
        <template>
          <EuiDatePicker @value="2026-11-24">
            <:trigger as |t|>
              <EuiButton
                class="my-trigger"
                {{on "click" t.open}}
              >{{t.text}}</EuiButton>
            </:trigger>
          </EuiDatePicker>
        </template>
      );
      const trigger = el<HTMLButtonElement>('button.my-trigger');
      trigger.focus();
      await click(trigger);
      await triggerKeyEvent(document.activeElement!, 'keydown', 'ArrowRight');
      await triggerKeyEvent(document.activeElement!, 'keydown', 'Escape');

      assert.notOk(panel(), 'closed');
      assert.strictEqual(document.activeElement, trigger, 'focus back');

      const days = calls.filter((call) =>
        call.element.matches('td[data-date] > button')
      );
      assert.true(
        days.length >= 2,
        'the opening and the key moved focus to days'
      );
      assert.true(
        days.every((call) => call.options?.preventScroll === true),
        'every move to a day passes preventScroll'
      );
      const toTrigger = calls.filter((call) => call.element === trigger);
      const back = toTrigger[toTrigger.length - 1];
      assert.true(
        back?.options?.preventScroll === true,
        'focus goes back to the trigger with preventScroll'
      );
    });

    test('ArrowDown from the text input into the calendar does not scroll', async function (assert) {
      await render(<template><EuiDatePicker @value="2026-11-24" /></template>);
      const input = el<HTMLInputElement>('input.euiDatePicker');
      await click(input);
      await triggerKeyEvent(input, 'keydown', 'ArrowDown');
      const days = calls.filter((call) =>
        call.element.matches('td[data-date] > button')
      );
      assert.true(days.length >= 1, 'focus moved into the grid');
      assert.true(
        days.every((call) => call.options?.preventScroll === true),
        'with preventScroll'
      );
    });
  }
);
