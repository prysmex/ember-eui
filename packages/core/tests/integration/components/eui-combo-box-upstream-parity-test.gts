/**
 * EuiComboBox parity with upstream EUI 123.1.0 (`combo_box.test.tsx`,
 * `combo_box.spec.tsx`, `combo_box_input.tsx`): plain text single selection
 * as the input's value, the toggle list button and the clear button test
 * subjects. Also EuiFormControlLayout's upstream `icon` shape and `clear`
 * props, which the combo box uses.
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
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';

import EuiComboBox from '#src/components/eui-combo-box.gts';
import EuiFormControlLayout from '#src/components/eui-form-control-layout.gts';

const INPUT =
  'input.euiComboBox__input:not(.fake-input-for-html-form-validity)';
const ROW = '.euiComboBoxOptionsList .euiComboBoxOption[role="option"]';
const TOGGLE = '[data-test-subj="comboBoxToggleListButton"]';
const CLEAR = '[data-test-subj="comboBoxClearButton"]';
const panel = () => document.querySelector('.ember-basic-dropdown-content');
const rows = () => [...document.querySelectorAll<HTMLElement>(ROW)];
const isOpen = () => Boolean(panel());
const noop = () => {};
const q = <T extends Element = HTMLElement>(selector: string, root: ParentNode = document) =>
  root.querySelector<T>(selector)!;

// upstream's spec options
const ITEMS = [
  { label: 'Item 1' },
  { label: 'Item 2' },
  { label: 'Item 3' }
];

const MOONS = [{ label: 'Titan' }, { label: 'Enceladus' }, { label: 'Mimas' }];

class State {
  @tracked selected: any[];
  changes: any[][] = [];

  constructor(selected: any[] = []) {
    this.selected = selected;
  }

  onChange = (selected: any[]) => {
    this.changes.push(selected);
    this.selected = selected;
  };
}

module('Integration | Component | eui-combo-box upstream parity', function (hooks) {
  setupRenderingTest(hooks);

  module('asPlainText', function () {
    test('renders the selection in the search input, not as a pill (upstream)', async function (assert) {
      const selected = [MOONS[2]];

      await render(
        <template>
          <EuiComboBox @options={{MOONS}} @selectedOptions={{selected}} @singleSelection={{hash asPlainText=true}} @onChange={{noop}} />
        </template>
      );
      const input = q<HTMLInputElement>(INPUT);
      assert.dom(input).hasValue('Mimas');
      assert.dom(input).hasAttribute('data-test-subj', 'comboBoxSearchInput');
      assert.strictEqual(
        getComputedStyle(input).inlineSize,
        getComputedStyle(input.parentElement!).inlineSize,
        'inline-size: 100%'
      );
      assert.dom('[data-test-subj="euiComboBoxPill"]').doesNotExist();
      assert.dom('.euiComboBoxPill').doesNotExist();
    });

    test('deletes the selection and only a single character (upstream spec)', async function (assert) {
      const state = new State();

      await render(
        <template>
          <EuiComboBox @options={{ITEMS}} @selectedOptions={{state.selected}} @singleSelection={{hash asPlainText=true}} @onChange={{state.onChange}} />
        </template>
      );
      await click(INPUT);
      await triggerKeyEvent(INPUT, 'keydown', 'ArrowDown');
      await triggerKeyEvent(INPUT, 'keydown', 'Enter');
      assert.dom(INPUT).hasValue('Item 1');
      assert.dom(CLEAR).exists('indicates selection');

      await triggerKeyEvent(INPUT, 'keydown', 'Backspace');
      assert.dom(CLEAR).doesNotExist('selection removed');
      assert.deepEqual(state.selected, []);
      // the browser's own deletion of one character
      await fillIn(INPUT, 'Item ');
      assert.dom(INPUT).hasValue('Item ');
      assert.deepEqual(state.changes, [[ITEMS[0]], []], 'no other change');
    });

    test('choosing closes the list, keeps focus; clicking the input opens it again (upstream spec)', async function (assert) {
      const state = new State();

      await render(
        <template>
          <EuiComboBox @options={{ITEMS}} @selectedOptions={{state.selected}} @singleSelection={{hash asPlainText=true}} @onChange={{state.onChange}} />
        </template>
      );
      await click(INPUT);
      await waitUntil(isOpen);
      await click(rows()[0]!);
      await waitUntil(() => !isOpen());
      assert.strictEqual(document.activeElement, q(INPUT), 'focus stays in the input');
      assert.dom(INPUT).hasValue('Item 1');

      await click(INPUT);
      await waitUntil(isOpen);
      assert.true(isOpen(), 'the list opens again');
    });

    test('typing edits the text; leaving with unmatched text keeps it and marks it invalid', async function (assert) {
      const state = new State([MOONS[0]]);

      await render(
        <template>
          <EuiComboBox @options={{MOONS}} @selectedOptions={{state.selected}} @singleSelection={{hash asPlainText=true}} @onChange={{state.onChange}} />
        </template>
      );
      await focus(INPUT);
      await fillIn(INPUT, 'Titanx');
      assert.dom(INPUT).hasValue('Titanx');
      assert.deepEqual(state.changes, [], 'typing does not change the selection');
      assert.strictEqual(rows().length, 0, 'the list follows the text');

      await blur(INPUT);
      assert.dom(INPUT).hasValue('Titanx', 'the text stays');
      assert.dom('.euiComboBox').hasClass('euiComboBox-isInvalid');
      assert.dom(INPUT).hasAttribute('aria-invalid', 'true');
    });

    test('leaving with the text of one option selects it', async function (assert) {
      const state = new State();

      await render(
        <template>
          <EuiComboBox @options={{MOONS}} @selectedOptions={{state.selected}} @singleSelection={{hash asPlainText=true}} @onChange={{state.onChange}} />
        </template>
      );
      await focus(INPUT);
      await fillIn(INPUT, 'mimas');
      await blur(INPUT);
      assert.deepEqual(state.selected, [MOONS[2]]);
      assert.dom(INPUT).hasValue('Mimas', 'the selection is the value');
      assert.dom('.euiComboBox').doesNotHaveClass('euiComboBox-isInvalid');
    });

    test('focusing opens the list; clearing empties the value, focuses and opens', async function (assert) {
      const state = new State([MOONS[0]]);
      const focused: unknown[] = [];
      const onFocus = (...args: unknown[]) => focused.push(args);

      await render(
        <template>
          <EuiComboBox @options={{MOONS}} @selectedOptions={{state.selected}} @singleSelection={{hash asPlainText=true}} @onChange={{state.onChange}} @onFocus={{onFocus}} />
        </template>
      );
      await focus(INPUT);
      await waitUntil(isOpen);
      assert.true(isOpen(), 'focus opens the list');
      await triggerKeyEvent(INPUT, 'keydown', 'Escape');
      assert.false(isOpen());

      await click(CLEAR);
      assert.deepEqual(state.changes, [[]]);
      assert.dom(INPUT).hasValue('');
      assert.strictEqual(document.activeElement, q(INPUT));
      assert.true(isOpen());
      assert.true(focused.length >= 1, '@onFocus');
    });

    test('the option prepend/append stay around the input with a block', async function (assert) {
      const options = [{ label: 'Titan', prepend: 'P', append: 'A' }];

      await render(
        <template>
          <EuiComboBox @options={{options}} @selectedOptions={{options}} @searchField="label" @singleSelection={{hash asPlainText=true}} @onChange={{noop}} as |option|>
            <b class="custom">{{option.label}}</b>
          </EuiComboBox>
        </template>
      );
      assert.dom(INPUT).hasValue('Titan', 'the label, not the block');
      // the block renders the selection over the input (not upstream)
      assert.dom('.euiComboBoxPlainTextSelection__block .custom').hasText('Titan');
      assert.dom('.euiComboBoxPlainTextSelection__prepend').hasText('P');
      assert.dom('.euiComboBoxPlainTextSelection__append').hasText('A');
    });
  });

  module('toggle list button', function () {
    test('is a button with upstream aria-label that toggles the list', async function (assert) {
      const state = new State();

      await render(
        <template>
          <EuiComboBox @options={{MOONS}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} />
        </template>
      );
      const toggle = q<HTMLButtonElement>(TOGGLE);
      assert.strictEqual(toggle.tagName, 'BUTTON');
      assert.dom(toggle).hasAttribute('type', 'button');
      assert.dom(toggle).hasAttribute('tabindex', '-1');
      assert.dom(toggle).hasAttribute('aria-label', 'Open list of options');
      assert.dom('[data-icon-type="chevronSingleDown"]', toggle).exists();

      await click(TOGGLE);
      await waitUntil(isOpen);
      assert.true(isOpen(), 'opens');
      assert.strictEqual(document.activeElement, q(INPUT), 'focuses the input');
      assert.dom(TOGGLE).hasAttribute('aria-label', 'Close list of options');

      await click(TOGGLE);
      await waitUntil(() => !isOpen());
      assert.false(isOpen(), 'closes');
      assert.dom(TOGGLE).hasAttribute('aria-label', 'Open list of options');

      await click(TOGGLE);
      await waitUntil(isOpen);
      assert.true(isOpen(), 'opens again');
      assert.deepEqual(state.changes, [], 'no selection change');
    });

    test('opens the list while the input already has focus', async function (assert) {
      await render(<template><EuiComboBox @options={{MOONS}} @onChange={{noop}} /></template>);
      await focus(INPUT);
      await triggerKeyEvent(INPUT, 'keydown', 'Escape');
      assert.false(isOpen());
      await click(TOGGLE);
      await waitUntil(isOpen);
      assert.true(isOpen());
    });

    test('not rendered while disabled or with noSuggestions; @triggerIcon sets its icon', async function (assert) {
      await render(
        <template>
          <div data-c="disabled"><EuiComboBox @options={{MOONS}} @isDisabled={{true}} @onChange={{noop}} /></div>
          <div data-c="none"><EuiComboBox @noSuggestions={{true}} @onChange={{noop}} /></div>
          <div data-c="icon"><EuiComboBox @options={{MOONS}} @triggerIcon="search" @onChange={{noop}} /></div>
        </template>
      );
      assert.dom(`[data-c="disabled"] ${TOGGLE}`).doesNotExist();
      assert.dom(`[data-c="none"] ${TOGGLE}`).doesNotExist();
      assert.dom(`[data-c="icon"] ${TOGGLE} [data-icon-type="search"]`).exists();
    });

    test('touch presses toggle once', async function (assert) {
      await render(<template><EuiComboBox @options={{MOONS}} @onChange={{noop}} /></template>);
      await triggerEvent(TOGGLE, 'touchstart');
      await triggerEvent(TOGGLE, 'touchend');
      assert.false(isOpen(), 'the dropdown trigger does not toggle on touch');
      await click(TOGGLE);
      await waitUntil(isOpen);
      assert.true(isOpen());
    });
  });

  module('clear button', function () {
    test('comboBoxClearButton: with a selection, empties it and focuses the input (upstream)', async function (assert) {
      const state = new State([MOONS[2]]);

      await render(
        <template>
          <div data-c="clear"><EuiComboBox @options={{MOONS}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} /></div>
          <div data-c="none"><EuiComboBox @options={{MOONS}} @onChange={{noop}} /></div>
          <div data-c="off"><EuiComboBox @options={{MOONS}} @selectedOptions={{state.selected}} @isClearable={{false}} @onChange={{noop}} /></div>
        </template>
      );
      assert.dom(`[data-c="clear"] ${CLEAR}`).hasClass('euiFormControlLayoutClearButton');
      assert.dom(`[data-c="clear"] ${CLEAR}`).hasAttribute('aria-label', 'Clear input');
      assert.dom(`[data-c="none"] ${CLEAR}`).doesNotExist();
      assert.dom(`[data-c="off"] ${CLEAR}`).doesNotExist();

      await click(`[data-c="clear"] ${CLEAR}`);
      assert.deepEqual(state.changes, [[]]);
      assert.strictEqual(document.activeElement, q(`[data-c="clear"] ${INPUT}`));
      assert.dom(`[data-c="clear"] ${CLEAR}`).doesNotExist();
      await settled();
      assert.true(isOpen());
    });
  });
});

module('Integration | Component | eui-form-control-layout upstream icon and clear props', function (hooks) {
  setupRenderingTest(hooks);

  test('an icon shape: a button with its props, on its side', async function (assert) {
    const clicks: unknown[] = [];
    const icon = {
      type: 'calendar',
      side: 'right',
      color: 'primary',
      'aria-label': 'Pick',
      'data-test-subj': 'pick',
      tabIndex: -1,
      onClick: (e: MouseEvent) => clicks.push(e.type)
    };
    const plain = { type: 'search', 'data-test-subj': 'plain' };

    await render(
      <template>
        <div data-c="button"><EuiFormControlLayout @icon={{icon}}><input /></EuiFormControlLayout></div>
        <div data-c="span"><EuiFormControlLayout @icon={{plain}}><input /></EuiFormControlLayout></div>
      </template>
    );
    const button = q<HTMLButtonElement>('[data-c="button"] [data-test-subj="pick"]');
    assert.strictEqual(button.tagName, 'BUTTON');
    assert.dom(button).hasClass('euiFormControlLayoutCustomIcon');
    assert.dom(button).hasAttribute('aria-label', 'Pick');
    assert.dom(button).hasAttribute('tabindex', '-1');
    assert.dom(button).hasAttribute('type', 'button', '`type` is the icon, not an attribute');
    assert.dom(button).doesNotHaveAttribute('side');
    assert.dom('[data-icon-type="calendar"]', button).exists();
    assert.strictEqual(getComputedStyle(button).pointerEvents, 'all');
    assert.dom(button.closest('.euiFormControlLayoutIcons')!).exists();
    const wrapper = q('[data-c="button"] .euiFormControlLayout__childrenWrapper');
    assert.strictEqual(wrapper.style.getPropertyValue('--euiFormControlRightIconsCount').trim(), '1', 'the shape side counts');
    assert.strictEqual(wrapper.style.getPropertyValue('--euiFormControlLeftIconsCount'), '');
    await click(button);
    assert.deepEqual(clicks, ['click']);

    const span = q('[data-c="span"] [data-test-subj="plain"]');
    assert.strictEqual(span.tagName, 'SPAN', 'no onClick: decorative');
    assert.strictEqual(getComputedStyle(span).pointerEvents, 'none');
    const spanWrapper = q('[data-c="span"] .euiFormControlLayout__childrenWrapper');
    assert.strictEqual(spanWrapper.style.getPropertyValue('--euiFormControlLeftIconsCount').trim(), '1', 'left by default');
  });

  test('clear props: onClick and attributes on the clear button; a function still works', async function (assert) {
    const calls: string[] = [];
    const clear = { onClick: () => calls.push('props'), 'data-test-subj': 'clearMe' };
    const clearFn = () => calls.push('fn');
    const disabled = { onClick: () => calls.push('disabled'), disabled: true };

    await render(
      <template>
        <div data-c="props"><EuiFormControlLayout @clear={{clear}}><input /></EuiFormControlLayout></div>
        <div data-c="fn"><EuiFormControlLayout @clear={{clearFn}} @clearLabel="Reset"><input /></EuiFormControlLayout></div>
        <div data-c="disabled"><EuiFormControlLayout @clear={{disabled}}><input /></EuiFormControlLayout></div>
      </template>
    );
    assert.dom('[data-c="props"] .euiFormControlLayoutClearButton').hasAttribute('data-test-subj', 'clearMe');
    assert.dom('[data-c="props"] .euiFormControlLayoutClearButton').hasAttribute('aria-label', 'Clear input');
    assert.dom('[data-c="fn"] .euiFormControlLayoutClearButton').hasAttribute('aria-label', 'Reset');
    assert.dom('[data-c="fn"] .euiFormControlLayoutClearButton').doesNotHaveAttribute('data-test-subj');
    assert.dom('[data-c="disabled"] .euiFormControlLayoutClearButton').isDisabled();

    await click('[data-c="props"] .euiFormControlLayoutClearButton');
    await click('[data-c="fn"] .euiFormControlLayoutClearButton');
    assert.deepEqual(calls, ['props', 'fn']);
  });

  test('string icons and function clears render as before', async function (assert) {
    const clearFn = noop;

    await render(
      <template>
        <EuiFormControlLayout @icon="search" @iconSide="right" @clear={{clearFn}} @isDisabled={{true}}><input /></EuiFormControlLayout>
      </template>
    );
    const icon = q('.euiFormControlLayoutCustomIcon');
    assert.strictEqual(icon.tagName, 'SPAN');
    assert.strictEqual(icon.attributes.length, 1, 'only its class');
    assert.dom('[data-icon-type="search"]', icon).exists();
    assert.dom('.euiFormControlLayoutClearButton').isDisabled();
    const wrapper = q('.euiFormControlLayout__childrenWrapper');
    assert.strictEqual(wrapper.style.getPropertyValue('--euiFormControlRightIconsCount').trim(), '2');
  });
});
