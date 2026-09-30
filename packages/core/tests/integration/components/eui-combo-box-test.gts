import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  render,
  rerender,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiComboBox from '#src/components/eui-combo-box.gts';
import EuiText from '#src/components/eui-text.gts';
// what apps load with `import '@ember-eui/core/styles/ember-eui.css'`
import emberEuiCss from '#src/styles/ember-eui.css?raw';

import type { TOC } from '@ember/component/template-only';

const OPTIONS = ['Apple', 'Banana', 'Cherry'];

const MySelectedItem: TOC<{ Args: { option: string } }> = <template>
  <span class="my-selected-item">{{@option}}</span>
</template>;

class State {
  @tracked selected: unknown[] = [];
  changes: unknown[][] = [];
  created: string[] = [];

  onChange = (selected: unknown[]) => {
    this.changes.push(selected);
    this.selected = selected;
  };

  onCreateOption = (search: string) => {
    this.created.push(search);
    this.selected = [...this.selected, search];
  };
}

const TRIGGER = '.ember-power-select-trigger';
const INPUT = 'input.euiComboBox__input:not(.fake-input-for-html-form-validity)';
const OPTION = '.euiComboBoxOptionsList button.euiFilterSelectItem';

// the dropdown renders into #ember-basic-dropdown-wormhole, outside of the
// test root element, so query the whole document
const inDocument = (selector: string) => () => document.querySelector(selector);

async function open() {
  await click(INPUT);
  await waitUntil(inDocument(OPTION));
}

function optionTexts() {
  return [...document.querySelectorAll(OPTION)].map((el) =>
    el.textContent!.trim()
  );
}

async function choose(text: string) {
  const option = [...document.querySelectorAll(OPTION)].find(
    (el) => el.textContent!.trim() === text
  );

  if (!option) throw new Error(`option "${text}" not found`);

  await triggerEvent(option, 'mouseup');
}

module('Integration | Component | eui-combo-box', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders selected options as pills by default', async function (assert) {
    const state = new State();
    state.selected = ['Apple', 'Cherry'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    assert.dom(TRIGGER).hasClass('euiComboBox');
    assert.dom('.euiComboBoxPill').exists({ count: 2 });
    assert.dom('.euiComboBoxPill').hasText('Apple');
  });

  test('it renders a custom @selectedItemComponent', async function (assert) {
    const state = new State();
    state.selected = ['Apple', 'Cherry'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          @selectedItemComponent={{MySelectedItem}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    assert.dom('.euiComboBoxPill').doesNotExist();
    assert.dom('.my-selected-item').exists({ count: 2 });
    assert.dom('.my-selected-item').hasText('Apple');
  });

  test('it opens the options list and selects an option', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();

    assert.deepEqual(optionTexts(), OPTIONS);

    await choose('Banana');

    assert.deepEqual(state.changes, [['Banana']]);
    assert.dom('.euiComboBoxPill').hasText('Banana');
  });

  test('typing filters the options', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();
    await fillIn(INPUT, 'an');

    assert.deepEqual(optionTexts(), ['Banana']);
  });

  test('selecting an already selected option removes it', async function (assert) {
    const state = new State();
    state.selected = ['Apple', 'Banana'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();
    await choose('Apple');

    assert.deepEqual(state.changes, [['Banana']]);
  });

  test('the pill close button removes that option', async function (assert) {
    const state = new State();
    state.selected = ['Apple', 'Banana'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await triggerEvent('[data-selected-index="0"]', 'mousedown');

    assert.deepEqual(state.changes, [['Banana']]);
    assert.dom('.euiComboBoxPill').exists({ count: 1 });
  });

  test('backspace in an empty search removes the last selected option', async function (assert) {
    const state = new State();
    state.selected = ['Apple', 'Banana'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await click(INPUT);
    await triggerKeyEvent(INPUT, 'keydown', 'Backspace');

    assert.deepEqual(state.changes, [['Apple']]);
  });

  test('the clear button empties the selection', async function (assert) {
    const state = new State();
    state.selected = ['Apple', 'Banana'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await click('.euiFormControlLayoutClearButton');

    assert.deepEqual(state.changes, [[]]);
  });

  test('with @onCreateOption, a search without matches can be created', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          @onCreateOption={{state.onCreateOption}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();
    await fillIn(INPUT, 'Durian');
    await waitUntil(inDocument('.euiComboBoxOption__emptyStateText'));
    await triggerKeyEvent(INPUT, 'keydown', 'Enter');

    assert.deepEqual(state.created, ['Durian']);
    await rerender();
    assert.dom('.euiComboBoxPill').hasText('Durian');
  });

  test('the create option shows the typed text as text, not HTML', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          @onCreateOption={{state.onCreateOption}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();
    await fillIn(INPUT, '<img src=x>');
    await waitUntil(inDocument('.euiComboBoxOption__emptyStateText'));

    // the options list renders in the dropdown's wormhole, outside the test container
    assert.dom('.euiComboBoxOption__emptyStateText img', document.body).doesNotExist();
    assert.dom('.euiComboBoxOption__emptyStateText', document.body).includesText('<img src=x>');
  });

  test('@singleSelection keeps only the last chosen option', async function (assert) {
    const state = new State();
    state.selected = ['Apple'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          @singleSelection={{true}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();
    await choose('Cherry');

    assert.deepEqual(state.changes, [['Cherry']]);
    assert.deepEqual(state.selected, ['Cherry']);
  });

  test('it renders groups', async function (assert) {
    const state = new State();
    const grouped = [
      { groupName: 'Fruits', options: ['Apple', 'Banana'] },
      { groupName: 'Veggies', options: ['Carrot'] }
    ];

    await render(
      <template>
        <EuiComboBox
          @options={{grouped}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    await open();

    // the list is virtualized: only the first rows fit in the test viewport
    const rows = [
      ...document.querySelectorAll(
        '.euiComboBoxOptionsList__rowWrap > .ember-power-select-group, ' + OPTION
      )
    ].map((el) => el.textContent!.trim());

    assert.deepEqual(rows.slice(0, 3), ['Fruits', 'Apple', 'Banana']);
    assert.dom('.euiComboBoxTitle', document.body).hasText('Fruits');
  });

  test('choosing an option in a group selects that option', async function (assert) {
    const state = new State();
    const grouped = [
      'Loose',
      { groupName: 'Fruits', options: [{ label: 'Apple' }, { label: 'Banana' }] },
      { groupName: 'Veggies', options: [{ label: 'Carrot' }] }
    ];

    await render(
      <template>
        <EuiComboBox
          @options={{grouped}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          as |option|
        >
          {{option.label}}
        </EuiComboBox>
      </template>
    );

    await open();
    await choose('Apple');

    assert.deepEqual(state.changes, [[{ label: 'Apple' }]], 'the option, not its group');
    // the old cache lost the flattening, so this chose the "Veggies" group
    assert.dom('.euiComboBoxPill').hasText('Apple');
  });

  test('@isDisabled disables the input and hides the clear button', async function (assert) {
    const state = new State();
    state.selected = ['Apple'];

    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{state.selected}}
          @onChange={{state.onChange}}
          @isDisabled={{true}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    assert.dom(TRIGGER).hasClass('euiComboBox-isDisabled');
    assert.dom(INPUT).isDisabled();
    assert.dom('.euiFormControlLayoutClearButton').doesNotExist();
  });

  module('styles', function (hooks) {
    let style: HTMLStyleElement;

    hooks.beforeEach(function () {
      style = document.createElement('style');
      // EUI's prose styles, which also reach lists inside components
      style.textContent = `${emberEuiCss}
        .euiText ul { list-style: disc; margin-left: 24px; }`;
      document.head.append(style);
    });

    hooks.afterEach(function () {
      style.remove();
    });

    test('prose list styles leave the input alone', async function (assert) {
      const selected = ['Apple', 'Banana'];

      await render(
        <template>
          <div id="plain">
            <EuiComboBox @options={{OPTIONS}} @selectedOptions={{selected}} as |o|>{{o}}</EuiComboBox>
          </div>
          <EuiText id="prose">
            <EuiComboBox @options={{OPTIONS}} @selectedOptions={{selected}} as |o|>{{o}}</EuiComboBox>
          </EuiText>
        </template>
      );

      // ember-power-select renders the input wrap as a <ul>
      const offsets = (id: string) => {
        const combo = document.querySelector(`#${id} .euiComboBox`)!.getBoundingClientRect();
        const wrap = document.querySelector(`#${id} .euiComboBox__inputWrap`)!;

        return {
          wrap: wrap.getBoundingClientRect().left - combo.left,
          listStyle: getComputedStyle(wrap).listStyleType,
          pills: [...wrap.querySelectorAll('.euiComboBoxPill')].map(
            (pill) => pill.getBoundingClientRect().left - combo.left
          )
        };
      };

      assert.deepEqual(offsets('prose'), offsets('plain'));
      assert.strictEqual(offsets('prose').listStyle, 'none');
    });

    test('the announcement of the results is for screen readers only', async function (assert) {
      await render(<template><EuiComboBox @options={{OPTIONS}} as |o|>{{o}}</EuiComboBox></template>);
      await open();

      const status = document.querySelector('.ember-power-select-visually-hidden[role="status"]')!;
      const rect = status.getBoundingClientRect();

      assert.dom(status).hasText('3 results');
      assert.true(rect.width <= 1 && rect.height <= 1, 'takes no space');
    });
  });
});
