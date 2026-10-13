/**
 * EuiComboBox's last interaction differences with upstream EUI 123.1.0:
 * the toggle list button takes focus when pressed (`combo_box.tsx`
 * `onContainerBlur` / `onKeyDown` / `onOpenListClick`), and pills get the
 * option's other keys (`combo_box_input.tsx` `renderPills`,
 * `combo_box_pill.tsx`).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  blur,
  click,
  fillIn,
  focus,
  render,
  settled,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiComboBox from '#src/components/eui-combo-box.gts';

const INPUT = 'input.euiComboBox__input:not(.fake-input-for-html-form-validity)';
const ROW = '.euiComboBoxOptionsList .euiComboBoxOption[role="option"]';
const TOGGLE = '[data-test-subj="comboBoxToggleListButton"]';
const PILL = '.euiComboBoxPill';
const panel = () => document.querySelector('.ember-basic-dropdown-content');
const rows = () => [...document.querySelectorAll<HTMLElement>(ROW)];
const isOpen = () => Boolean(panel());
const q = <T extends Element = HTMLElement>(selector: string) => document.querySelector<T>(selector)!;
const active = () => q(INPUT).getAttribute('aria-activedescendant');
const noop = () => {};

const MOONS = [{ label: 'Titan' }, { label: 'Enceladus' }, { label: 'Mimas' }];

class State {
  @tracked selected: any[];
  changes: any[][] = [];
  created: string[] = [];
  focuses = 0;
  blurs = 0;

  constructor(selected: any[] = []) {
    this.selected = selected;
  }

  onChange = (selected: any[]) => {
    this.changes.push(selected);
    this.selected = selected;
  };
  onCreateOption = (value: string) => {
    this.created.push(value);
    this.selected = [...this.selected, { label: value }];
  };
  onFocus = () => this.focuses++;
  onBlur = () => this.blurs++;
}

module('Integration | Component | eui-combo-box last interactions', function (hooks) {
  setupRenderingTest(hooks);

  module('toggle list button focus (upstream)', function () {
    test('closing with the button moves focus to it; the combo box keeps focus', async function (assert) {
      const state = new State();
      await render(
        <template>
          <EuiComboBox @options={{MOONS}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} @onFocus={{state.onFocus}} @onBlur={{state.onBlur}} />
        </template>
      );

      await click(TOGGLE);
      await waitUntil(isOpen);
      assert.strictEqual(document.activeElement, q(INPUT), 'opening focuses the input (onOpenListClick)');
      assert.strictEqual(state.focuses, 1);

      await click(TOGGLE);
      await waitUntil(() => !isOpen());
      assert.strictEqual(document.activeElement, q(TOGGLE), 'focus stays on the button (upstream mousedown)');
      assert.strictEqual(state.blurs, 0, 'focus inside the combo box: no @onBlur (onContainerBlur)');
      assert.dom(TOGGLE).hasAttribute('aria-label', 'Open list of options');
      assert.dom('.euiComboBox').doesNotHaveClass('euiComboBox-isInvalid');

      await click(TOGGLE);
      await waitUntil(isOpen);
      assert.strictEqual(document.activeElement, q(INPUT), 'reopening focuses the input again');
      assert.strictEqual(state.focuses, 2, 'the input focus runs onComboBoxFocus again');
      assert.deepEqual(state.changes, []);
    });

    test('moving focus from the input to the button clears the active option, keeps the list', async function (assert) {
      await render(<template><EuiComboBox @options={{MOONS}} @onChange={{noop}} /></template>);

      await focus(INPUT);
      await waitUntil(isOpen);
      await triggerKeyEvent(INPUT, 'keydown', 'ArrowDown');
      assert.strictEqual(active(), rows()[0]!.id);

      await focus(TOGGLE);
      assert.true(isOpen(), 'the list stays open');
      assert.false(q(INPUT).hasAttribute('aria-activedescendant'), 'clearActiveOption');
    });

    test('keys on the focused button: arrows open and move, Escape closes, others do nothing', async function (assert) {
      const state = new State();
      await render(
        <template>
          <EuiComboBox @options={{MOONS}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} />
        </template>
      );

      await click(TOGGLE);
      await waitUntil(isOpen);
      await click(TOGGLE);
      await waitUntil(() => !isOpen());
      assert.strictEqual(document.activeElement, q(TOGGLE));

      await triggerKeyEvent(TOGGLE, 'keydown', 'ArrowDown');
      await waitUntil(isOpen);
      assert.true(isOpen(), 'ArrowDown opens the list');
      assert.false(q(INPUT).hasAttribute('aria-activedescendant'), 'nothing active yet');
      assert.strictEqual(document.activeElement, q(TOGGLE), 'focus stays on the button');

      await triggerKeyEvent(TOGGLE, 'keydown', 'ArrowDown');
      assert.strictEqual(active(), rows()[0]!.id, 'ArrowDown moves to the first option');
      await triggerKeyEvent(TOGGLE, 'keydown', 'ArrowUp');
      assert.strictEqual(active(), rows()[2]!.id, 'ArrowUp wraps');

      await triggerKeyEvent(TOGGLE, 'keydown', 'Enter');
      q(TOGGLE).dispatchEvent(new KeyboardEvent('keydown', { key: 't', bubbles: true, cancelable: true }));
      await triggerKeyEvent(TOGGLE, 'keydown', ' ');
      await settled();
      assert.deepEqual(state.changes, [], 'Enter does not choose, letters do not type ahead');
      assert.true(isOpen(), 'the keydowns themselves do not toggle (the button click does)');

      await triggerKeyEvent(TOGGLE, 'keydown', 'Escape');
      await waitUntil(() => !isOpen());
      assert.false(isOpen(), 'Escape closes');
      assert.strictEqual(document.activeElement, q(TOGGLE));
    });

    test('Tab is held on the button while an option is active', async function (assert) {
      await render(<template><EuiComboBox @options={{MOONS}} @onChange={{noop}} /></template>);

      await focus(TOGGLE);
      await triggerKeyEvent(TOGGLE, 'keydown', 'ArrowDown');
      await waitUntil(isOpen);
      await triggerKeyEvent(TOGGLE, 'keydown', 'ArrowDown');
      const event = new KeyboardEvent('keydown', { key: 'Tab', bubbles: true, cancelable: true });
      q(TOGGLE).dispatchEvent(event);
      assert.true(event.defaultPrevented, 'tabbing away is prevented');
    });

    test('leaving from the button: @onBlur, the list closes and typed text is added', async function (assert) {
      const state = new State();
      await render(
        <template>
          <EuiComboBox @options={{MOONS}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} @onCreateOption={{state.onCreateOption}} @onBlur={{state.onBlur}} />
          <button type="button" class="outside">Outside</button>
        </template>
      );

      await fillIn(INPUT, 'Rhea');
      await waitUntil(isOpen);
      await focus(TOGGLE);
      assert.strictEqual(state.blurs, 0);
      assert.deepEqual(state.created, [], 'nothing added while focus is in the combo box');

      await focus('.outside');
      await settled();
      assert.strictEqual(state.blurs, 1, '@onBlur once');
      assert.false(isOpen(), 'the list closes');
      assert.deepEqual(state.created, ['Rhea'], 'setCustomOptions(true)');
    });

    test('leaving from the button with a closed list and no text', async function (assert) {
      const state = new State();
      await render(
        <template>
          <EuiComboBox @options={{MOONS}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} @onBlur={{state.onBlur}} />
          <button type="button" class="outside">Outside</button>
        </template>
      );

      await focus(TOGGLE);
      await blur(TOGGLE);
      assert.strictEqual(state.blurs, 1);
      assert.false(isOpen());
      assert.deepEqual(state.changes, []);
    });
  });

  module('pills (upstream renderPills / EuiComboBoxPill)', function () {
    test("the option's other keys are attributes of the pill; title is the label", async function (assert) {
      const selected = [
        { label: 'Titan', 'data-test-subj': 'titanPill', 'aria-describedby': 'moon-help', className: 'is-moon', value: 't', id: 'pill-titan' },
        { label: 'Mimas', key: 'm', truncationProps: { truncation: 'end' }, toolTipContent: 'tip' }
      ];
      await render(<template><EuiComboBox @options={{MOONS}} @selectedOptions={{selected}} @onChange={{noop}} /></template>);

      const [titan, mimas] = [...document.querySelectorAll<HTMLElement>(PILL)];
      assert.dom(titan).hasAttribute('data-test-subj', 'titanPill', 'the option wins over the default test subject');
      assert.dom(titan).hasAttribute('aria-describedby', 'moon-help');
      assert.dom(titan).hasAttribute('value', 't');
      assert.dom(titan).hasAttribute('id', 'pill-titan');
      assert.dom(titan).hasClass('is-moon').hasClass('euiComboBoxPill');
      assert.dom(titan).hasAttribute('title', 'Titan');
      assert.dom(mimas).hasAttribute('data-test-subj', 'euiComboBoxPill');
      for (const name of ['key', 'label', 'truncationProps', 'toolTipContent', 'truncationprops', 'tooltipcontent']) {
        assert.dom(mimas).doesNotHaveAttribute(name, `${name} is not forwarded`);
      }
    });

    test('an option with onClick is a clickable "Change" pill without a remove button', async function (assert) {
      const clicks: string[] = [];
      const state = new State([
        { label: 'Titan', onClick: () => clicks.push('titan') },
        { label: 'Mimas' }
      ]);
      await render(<template><EuiComboBox @options={{MOONS}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} /></template>);

      const titan = q(PILL);
      assert.strictEqual(titan.tagName, 'BUTTON');
      assert.dom(titan).hasAttribute('aria-label', 'Change').hasAttribute('title', 'Titan');
      assert.dom('.euiBadge__iconButton', titan).doesNotExist('no remove button (pillOnClose undefined)');
      const mimas = [...document.querySelectorAll<HTMLElement>(PILL)][1]!;
      assert.dom('.euiBadge__iconButton', mimas).exists('the other pill keeps its remove button');
      await click(titan);
      assert.deepEqual(clicks, ['titan']);
      assert.deepEqual(state.changes, [], 'the click does not remove it');
    });

    test('object options with @searchField are data: no attributes', async function (assert) {
      class Moon {
        name: string;
        id: string;
        constructor(name: string) {
          this.name = name;
          this.id = `moon-${name}`;
        }
      }
      const moons = [new Moon('Titan')];
      const plain = [{ name: 'Rhea', id: 'rhea' }];
      await render(
        <template>
          <div data-c="class"><EuiComboBox @options={{moons}} @selectedOptions={{moons}} @searchField="name" @onChange={{noop}} as |m|>{{m.name}}</EuiComboBox></div>
          <div data-c="field"><EuiComboBox @options={{plain}} @selectedOptions={{plain}} @searchField="name" @onChange={{noop}} as |m|>{{m.name}}</EuiComboBox></div>
        </template>
      );

      assert.dom(`[data-c="class"] ${PILL}`).doesNotHaveAttribute('id');
      assert.dom(`[data-c="class"] ${PILL}`).hasAttribute('title', 'Titan');
      assert.dom(`[data-c="field"] ${PILL}`).doesNotHaveAttribute('id');
    });
  });
});
